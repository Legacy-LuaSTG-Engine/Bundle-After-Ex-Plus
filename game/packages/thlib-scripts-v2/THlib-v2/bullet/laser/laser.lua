--region Imports
local math = math
local table = table
local coroutine = coroutine
local lstg = lstg
local task = task
local AttributeProxy = require("foundation.AttributeProxy")
local Easing = require("foundation.Easing")
local QuickSort = require("foundation.QuickSort")
local laserCollider = require("THlib-v2.bullet.laser.laserCollider")
---@type lstg.GlobalEventDispatcher
local gameEventDispatcher = lstg.globalEventDispatcher
--endregion

--region Class Definition
---@class THlib-v2.Bullet.Laser.StraightLaser
local class = lstg.CreateGameObjectClass()

--region Enums
local EnumAnchor = {
    Head = 1,
    Center = 2,
    Tail = 3,
}
class.EnumAnchor = EnumAnchor

local EnumChangeIndex = {
    Alpha = 1,
    Width = 2,
    Length = 3,
    Total = 3,
}
class.EnumChangeIndex = EnumChangeIndex
--endregion

---@class THlib-v2.Bullet.Laser.StraightLaser.CreateArgs
local LaserCreateArgs = {
    x = 0,
    y = 0,
    rot = 0,
    l1 = 0,
    l2 = 0,
    l3 = 0,
    w = 0,
    node = 0,
    head = 0,
    index = 0,
}

function class.create(...)
    local x, y, rot, l1, l2, l3, w, node, head, index = ...
    local self = lstg.New(class)
    self.group = GROUP_ENEMY_BULLET             -- Child colliders group
    self.layer = LAYER_ENEMY_BULLET             -- Render layer
    self.x = x                                  -- Anchor position x
    self.y = y                                  -- Anchor position y
    self.rot = rot                              -- Rotation
    self.colli = false                          -- Main laser do not have collision
    ---@diagnostic disable
    self.l1 = l1                                -- Length of the first part
    self.l2 = l2                                -- Length of the second part
    self.l3 = l3                                -- Length of the third part
    self.w = w                                  -- Width
    self.node = node                            -- Node size
    self.head = head                            -- Head size
    self.anchor = EnumAnchor.Tail               -- Anchor position
    self.graze_countdown = 0                    -- Graze countdown
    self.shooting_speed = 0                     -- Shooting speed ( -offset per frame )
    self.killed_at_spawn = false                -- Child colliders are killed at spawn
    self.offset_at_head = true                  -- Offset at head
    self.alpha = 0                              -- Render Alpha
    --
    self._blend = "mul+add"                     -- Blend mode
    self._a = 255                               -- Color alpha
    self._r = 255                               -- Color red
    self._g = 255                               -- Color green
    self._b = 255                               -- Color blue
    self.task = {}                              -- Task list
    --
    self.___killed = false                      -- Killed flag
    self.___shooting_offset = 0                 -- Shooting offset
    self.___colliders = {}                      -- Child colliders
    self.___offset_colliders = {}               -- Child colliders by offset
    self.___recovery_colliders = {}             -- Recovery child colliders
    self.___changing_task = {}                  -- Changing task
    self.___attribute_dirty = false             -- Attribute dirty
    --
    self.onDelCollider = class.onDelCollider    -- On delete collider callback
    self.onKillCollider = class.onKillCollider  -- On kill collider callback
    ---@diagnostic enable
    class.applyDefaultLaserStyle(self, 1, index)
    AttributeProxy.applyProxies(self, class.___attribute_proxies)
    class.updateColliders(self)
    class.laserUpdater:addLaser(self)
    return self
end

function class:frame()
    if self.___killed then
        class.updateChangingTask(self)
        if self.shooting_speed ~= 0 then
            self.___shooting_offset = self.___shooting_offset - self.shooting_speed
        end
        return
    end
    if self.graze_countdown > 0 then
        self.graze_countdown = self.graze_countdown - 1
    elseif self._graze then
        self._graze = false
    end
    task.Do(self)
    class.updateChangingTask(self)
    if self.shooting_speed ~= 0 then
        self.___shooting_offset = self.___shooting_offset - self.shooting_speed
    end
    local open_bound = self.bound
    local bound_status = lstg.GetAttr(self, "bound")
    local is_out_of_bound = class.checkIsOutOfBound(self)
    if open_bound and is_out_of_bound then
        if not bound_status then
            lstg.SetAttr(self, "bound", true)
            for i = 1, #self.___colliders do
                local c = self.___colliders[i]
                if lstg.IsValid(c) then
                    lstg.SetAttr(c, "bound", true)
                end
            end
        end
    elseif bound_status then
        lstg.SetAttr(self, "bound", false)
        for i = 1, #self.___colliders do
            local c = self.___colliders[i]
            if lstg.IsValid(c) then
                lstg.SetAttr(c, "bound", false)
            end
        end
    end
end

function class:render()
    local parts = class.getLaserColliderParts(self)
    for i = 1, #parts do
        class.renderLaserColliderPart(self, parts[i])
    end
    if self.node > 0 then
        local x, y = class.getAnchorPosition(self, EnumAnchor.Tail)
        local color = lstg.Color(self._a, self._r, self._g, self._b)
        lstg.SetImageState(self.img4, self._blend, color)
        lstg.Render(self.img4, x, y, 18 * self.timer, self.node / 8)
        lstg.Render(self.img4, x, y, -18 * self.timer, self.node / 8)
    end
end

function class:del()
    if not self.___killed then
        PreserveObject(self)
        self.___killed = true
        self.colli = false
        task.Clear(self)
        local alpha = self.alpha
        local d = self.w
        local tasks = self.___changing_task
        tasks[EnumChangeIndex.Alpha] = coroutine.create(function()
            for i = 30, 1, -1 do
                self.alpha = alpha * i / 30
                coroutine.yield()
            end
            self.alpha = 0
            lstg.Del(self)
        end)
        tasks[EnumChangeIndex.Width] = coroutine.create(function()
            for i = 30, 1, -1 do
                self.w = d * i / 30
                coroutine.yield()
            end
            self.w = 0
        end)
    else
        for i = 1, #self.___colliders do
            local c = self.___colliders[i]
            self.___colliders[i] = nil
            if lstg.IsValid(c) then
                lstg.Del(c)
            end
        end
        for i = 1, #self.___recovery_colliders do
            local c = self.___recovery_colliders[i]
            self.___recovery_colliders[i] = nil
            if lstg.IsValid(c) then
                lstg.Del(c)
            end
        end
    end
end

function class:kill()
    if not self.___killed then
        PreserveObject(self)
        self.___killed = true
        self.colli = false
        task.Clear(self)
        local alpha = self.alpha
        local d = self.w
        local tasks = self.___changing_task
        tasks[EnumChangeIndex.Alpha] = coroutine.create(function()
            for i = 30, 1, -1 do
                self.alpha = alpha * i / 30
                coroutine.yield()
            end
            self.alpha = 0
            lstg.Del(self)
        end)
        tasks[EnumChangeIndex.Width] = coroutine.create(function()
            for i = 30, 1, -1 do
                self.w = d * i / 30
                coroutine.yield()
            end
            self.w = 0
        end)
    else
        for i = 1, #self.___colliders do
            local c = self.___colliders[i]
            self.___colliders[i] = nil
            if lstg.IsValid(c) then
                lstg.Del(c)
            end
        end
        for i = 1, #self.___recovery_colliders do
            local c = self.___recovery_colliders[i]
            self.___recovery_colliders[i] = nil
            if lstg.IsValid(c) then
                lstg.Del(c)
            end
        end
    end
end

--endregion

--region Main Methods
function class:checkPreserveCollider(collider)
    if not ((self.___colliders[collider] or self.___recovery_colliders[collider]) and lstg.IsValid(collider)) then
        return false
    end
    if self.___killed then
        return false
    end
    PreserveObject(collider)
    collider.___killed = true
    return true
end

function class:onDelCollider(collider, offset)
    if not class.checkPreserveCollider(self, collider) then
        return
    end
    local w = lstg.world
    if self.style_index and lstg.BoxCheck(collider, w.boundl, w.boundr, w.boundb, w.boundt) then
        lstg.New(BulletBreak, collider.x, collider.y, self.style_index)
    end
end

function class:onKillCollider(collider, offset)
    if not class.checkPreserveCollider(self, collider) then
        return
    end
    local w = lstg.world
    if lstg.BoxCheck(collider, w.boundl, w.boundr, w.boundb, w.boundt) then
        lstg.New(item_faith_minor, collider.x, collider.y)
        if self.style_index then
            lstg.New(BulletBreak, collider.x, collider.y, self.style_index)
        end
    end
end

function class:checkIsOutOfBound()
    local w = lstg.world
    local is_out_of_bound = true
    for i = 1, #self.___colliders do
        local c = self.___colliders[i]
        if lstg.IsValid(c) and lstg.BoxCheck(c, w.boundl, w.boundr, w.boundb, w.boundt) then
            is_out_of_bound = false
            break
        end
    end
    return is_out_of_bound
end

function class:updateColliders()
    local colliders = self.___colliders
    local length = self.length
    if length <= 0 then
        for i = 1, #colliders do
            local c = colliders[i]
            colliders[i] = nil
            colliders[c] = nil
            if lstg.IsValid(c) then
                lstg.Del(c)
            end
        end
        return
    end
    --
    local tail_x, tail_y = class.getAnchorPosition(self, EnumAnchor.Tail)
    local total_offset = self.___shooting_offset
    if self.offset_at_head then
        total_offset = total_offset - length
    end
    local rot = self.rot
    local rot_cos = lstg.cos(rot)
    local rot_sin = lstg.sin(rot)
    local half_width = self.w / 2
    local colli = self.colli
    if not self.___killed then
        local fix_tail_offset = math.floor(total_offset / 16) * 16
        local fix_head_offset = math.ceil((total_offset + length) / 16) * 16
        local have_changed = false
        for part_offset = fix_tail_offset, fix_head_offset, 16 do
            local collider = self.___offset_colliders[part_offset]
            if not collider then
                collider = class.generateCollider(self, part_offset, self.killed_at_spawn)
                colliders[#colliders + 1] = collider
                have_changed = true
            end
        end
        if have_changed then
            QuickSort(colliders, function(a, b)
                return a.___collider_offset > b.___collider_offset
            end)
        end
    end
    for i = #colliders, 1, -1 do
        local collider = colliders[i]
        if not (lstg.IsValid(collider) and class.updateCollider(self, collider,
                tail_x, tail_y, length, total_offset, half_width, colli, rot, rot_cos, rot_sin)) then
            class.recoveryCollider(self, collider)
            table.remove(colliders, i)
        end
    end
end

function class:recoveryCollider(collider)
    if not (self.___colliders[collider] and lstg.IsValid(collider)) then
        return
    end
    collider.___killed = true
    self.___colliders[collider] = nil
    self.___offset_colliders[collider.___collider_offset] = nil
    self.___recovery_colliders[#self.___recovery_colliders + 1] = collider
    self.___recovery_colliders[collider] = true
end

function class:generateCollider(offset, killed)
    local collider = table.remove(self.___recovery_colliders)
    if lstg.IsValid(collider) then
        collider.group = self.group
        collider.___collider_offset = offset
        self.___recovery_colliders[collider] = nil
    else
        collider = laserCollider.create(self, self.group, offset)
    end
    collider.___killed = killed == nil or killed
    self.___colliders[collider] = true
    self.___offset_colliders[offset] = collider
    return collider
end

function class:updateCollider(collider, tail_x, tail_y, total_length, total_offset, half_width, colli, rot, rot_cos, rot_sin)
    local collider_offset = collider.___collider_offset
    local offset = collider_offset - total_offset
    local offset_begin = offset - 8
    local offset_end = offset + 8
    if offset_begin > total_length or offset_end < 0 then
        return false
    end
    offset_begin = math.max(0, offset_begin)
    offset_end = math.min(total_length, offset_end)
    offset = (offset_begin + offset_end) / 2
    local length = offset_end - offset_begin
    collider.x = tail_x + offset * rot_cos
    collider.y = tail_y + offset * rot_sin
    collider.rot = rot
    collider.a = length / 2
    collider.b = half_width
    collider.colli = colli and length > 0 and not self.___killed
    return true
end

function class:getLaserColliderParts()
    local colliders = self.___colliders
    local parts = {}
    local part = {}
    for i = 1, #colliders do
        local c = colliders[i]
        if not c.___killed then
            part[#part + 1] = c
        else
            if #part > 0 then
                parts[#parts + 1] = part
                part = {}
            end
        end
    end
    if #part > 0 then
        parts[#parts + 1] = part
    end
    return parts
end

function class:renderLaserColliderPart(part)
    if not part or #part == 0 then
        return
    end
    local width = self.w
    local head_node = part[1]
    local tail_node = part[#part]
    local length
    if head_node == tail_node then
        length = head_node.a * 2
    else
        length = (head_node.a + tail_node.a) * 2 + math.max(0, #part - 2) * 16
    end
    if width > 0 and length > 0 then
        local blend = self._blend
        local rot = self.rot
        local rot_cos = lstg.cos(rot)
        local rot_sin = lstg.sin(rot)
        local color = lstg.Color(self._a * self.alpha, self._r, self._g, self._b)
        local w = width / 2 / self.img_wm * self.img_w / self.img_wm
        local total_length = self.length
        local l1 = self.l1 / total_length * length
        local l2 = self.l2 / total_length * length
        local l3 = self.l3 / total_length * length
        local x = tail_node.x - tail_node.a * rot_cos
        local y = tail_node.y - tail_node.a * rot_sin
        lstg.SetImageState(self.img1, blend, color)
        lstg.Render(self.img1, x, y, rot, l1 / self.img1_l, w)
        x = x + l1 * rot_cos
        y = y + l1 * rot_sin
        lstg.SetImageState(self.img2, blend, color)
        lstg.Render(self.img2, x, y, rot, l2 / self.img2_l, w)
        x = x + l2 * rot_cos
        y = y + l2 * rot_sin
        lstg.SetImageState(self.img3, blend, color)
        lstg.Render(self.img3, x, y, rot, l3 / self.img3_l, w)
        if self.head > 0 then
            x = x + l3 * rot_cos
            y = y + l3 * rot_sin
            color = lstg.Color(self._a, self._r, self._g, self._b)
            lstg.SetImageState(self.img5, self._blend, color)
            lstg.Render(self.img5, x, y, 0, self.head / 8)
            lstg.Render(self.img5, x, y, 0, 0.75 * self.head / 8)
        end
    end
end

function class:updateChangingTask()
    local tasks = self.___changing_task
    if not tasks then
        return
    end
    for i = 1, EnumChangeIndex.Total do
        local co = tasks[i]
        if co then
            local success, result = coroutine.resume(co)
            if not success then
                error(result)
            end
            if coroutine.status(co) == "dead" then
                tasks[i] = nil
            end
        end
    end
end

function class:getAnchorPosition(anchor)
    local self_anchor = self.anchor
    if self_anchor == anchor then
        return self.x, self.y
    end
    local x = self.x
    local y = self.y
    local length = self.length
    local rot = self.rot
    local rot_cos = length / 2 * lstg.cos(rot)
    local rot_sin = length / 2 * lstg.sin(rot)
    if self_anchor == EnumAnchor.Tail then
        if anchor == EnumAnchor.Head then
            x = x + 2 * rot_cos
            y = y + 2 * rot_sin
        elseif anchor == EnumAnchor.Center then
            x = x + rot_cos
            y = y + rot_sin
        end
    elseif self_anchor == EnumAnchor.Center then
        if anchor == EnumAnchor.Head then
            x = x + rot_cos
            y = y + rot_sin
        elseif anchor == EnumAnchor.Tail then
            x = x - rot_cos
            y = y - rot_sin
        end
    elseif self_anchor == EnumAnchor.Head then
        if anchor == EnumAnchor.Center then
            x = x - rot_cos
            y = y - rot_sin
        elseif anchor == EnumAnchor.Tail then
            x = x - 2 * rot_cos
            y = y - 2 * rot_sin
        end
    end
    return x, y
end

function class:applyDefaultLaserStyle(id, index)
    id = math.max(math.min(math.floor(id), laser_texture_num - 1), 1)
    index = math.max(math.min(math.floor(index), 16), 1)
    local data = laser_data[id]
    self.style_id = id
    self.style_index = index
    self.img1_l = data[1]
    self.img2_l = data[2]
    self.img3_l = data[3]
    self.img_w = data[4]
    self.img_wm = data[6]
    self.img1 = "laser" .. id .. "1" .. index
    self.img2 = "laser" .. id .. "2" .. index
    self.img3 = "laser" .. id .. "3" .. index
    self.img4 = "laser_node" .. math.ceil(index / 2)
    self.img5 = "ball_mid_b" .. math.ceil(index / 2)
end

--endregion

--region Extension Methods
function class:toWidth(time, width, easing_func)
    if time <= 0 then
        self.w = width
        self.___changing_task[EnumChangeIndex.Width] = nil
        return
    end
    easing_func = easing_func or Easing.linear
    local begin = self.w
    local dp = width - begin
    local tasks = self.___changing_task
    tasks[EnumChangeIndex.Width] = coroutine.create(function()
        for i = 1, time do
            self.w = begin + dp * easing_func(i / time)
            coroutine.yield()
        end
    end)
end

function class:toAlpha(time, alpha, easing_func)
    if time <= 0 then
        self.alpha = alpha
        self.___changing_task[EnumChangeIndex.Alpha] = nil
        return
    end
    easing_func = easing_func or Easing.linear
    local begin = self.alpha
    local dp = alpha - begin
    local tasks = self.___changing_task
    tasks[EnumChangeIndex.Alpha] = coroutine.create(function()
        for i = 1, time do
            self.alpha = begin + dp * easing_func(i / time)
            coroutine.yield()
        end
    end)
end

function class:toLength(time, l1, l2, l3, easing_func)
    if time <= 0 then
        self.l1 = l1
        self.l2 = l2
        self.l3 = l3
        self.___changing_task[EnumChangeIndex.Length] = nil
        return
    end
    easing_func = easing_func or Easing.linear
    local begin_l1 = self.l1
    local begin_l2 = self.l2
    local begin_l3 = self.l3
    local dp1 = l1 - begin_l1
    local dp2 = l2 - begin_l2
    local dp3 = l3 - begin_l3
    local tasks = self.___changing_task
    tasks[EnumChangeIndex.Length] = coroutine.create(function()
        for i = 1, time do
            self.l1 = begin_l1 + dp1 * easing_func(i / time)
            self.l2 = begin_l2 + dp2 * easing_func(i / time)
            self.l3 = begin_l3 + dp3 * easing_func(i / time)
            coroutine.yield()
        end
    end)
end

function class:setPositionAndRotation(x, y, rot)
    AttributeProxy.setStorageValue(self, "x", x)
    AttributeProxy.setStorageValue(self, "y", y)
    AttributeProxy.setStorageValue(self, "rot", rot)
    self.___attribute_dirty = true
end

function class:setRectByPart(l1, l2, l3, width)
    AttributeProxy.setStorageValue(self, "l1", l1)
    AttributeProxy.setStorageValue(self, "l2", l2)
    AttributeProxy.setStorageValue(self, "l3", l3)
    if width then
        AttributeProxy.setStorageValue(self, "w", width)
    end
    self.___attribute_dirty = true
end

--endregion

--region Attribute Proxies
local attribute_proxies = {}
class.___attribute_proxies = attribute_proxies

--region x
local proxy_x = AttributeProxy.createProxy("x")
attribute_proxies["x"] = proxy_x
function proxy_x:init(key, value, storage)
    storage[key] = value or 0
end

function proxy_x:setter(key, value, storage)
    local old_value = storage[key]
    if value == old_value then
        return
    end
    storage[key] = value
    lstg.SetAttr(self, key, value)
    self.___attribute_dirty = true
end

--endregion

--region y
local proxy_y = AttributeProxy.createProxy("y")
attribute_proxies["y"] = proxy_y
function proxy_y:init(key, value, storage)
    storage[key] = value or 0
end

function proxy_y:setter(key, value, storage)
    local old_value = storage[key]
    if value == old_value then
        return
    end
    storage[key] = value
    lstg.SetAttr(self, key, value)
    self.___attribute_dirty = true
end

--endregion

--region rot
local proxy_rot = AttributeProxy.createProxy("rot")
attribute_proxies["rot"] = proxy_rot
function proxy_rot:init(key, value, storage)
    storage[key] = value or 0
end

function proxy_rot:setter(key, value, storage)
    local old_value = storage[key]
    if value == old_value then
        return
    end
    storage[key] = value
    lstg.SetAttr(self, key, value)
    self.___attribute_dirty = true
end

--endregion

--region l1
local proxy_l1 = AttributeProxy.createProxy("l1")
attribute_proxies["l1"] = proxy_l1
function proxy_l1:init(key, value, storage)
    storage[key] = value or 0
end

function proxy_l1:setter(key, value, storage)
    value = math.max(value, 0)
    local old_value = storage[key]
    if value == old_value then
        return
    end
    storage[key] = value
    self.___attribute_dirty = true
end

--endregion

--region l2
local proxy_l2 = AttributeProxy.createProxy("l2")
attribute_proxies["l2"] = proxy_l2
function proxy_l2:init(key, value, storage)
    storage[key] = value or 0
end

function proxy_l2:setter(key, value, storage)
    value = math.max(value, 0)
    local old_value = storage[key]
    if value == old_value then
        return
    end
    storage[key] = value
    self.___attribute_dirty = true
end

--endregion

--region l3
local proxy_l3 = AttributeProxy.createProxy("l3")
attribute_proxies["l3"] = proxy_l3
function proxy_l3:init(key, value, storage)
    storage[key] = value or 0
end

function proxy_l3:setter(key, value, storage)
    value = math.max(value, 0)
    local old_value = storage[key]
    if value == old_value then
        return
    end
    storage[key] = value
    self.___attribute_dirty = true
end

--endregion

--region length
local proxy_length = AttributeProxy.createProxy("length")
attribute_proxies["length"] = proxy_length
function proxy_length:getter(key, storage)
    return storage["l1"] + storage["l2"] + storage["l3"]
end

function proxy_length:setter(key, value, storage)
    value = math.max(value, 0)
    if value == 0 then
        storage["l1"] = 0
        storage["l2"] = 0
        storage["l3"] = 0
        self.___attribute_dirty = true
        return
    end
    local l1 = storage["l1"]
    local l2 = storage["l2"]
    local l3 = storage["l3"]
    local sum = l1 + l2 + l3
    if sum ~= 0 then
        l1 = l1 / sum * value
        l2 = l2 / sum * value
        l3 = l3 / sum * value
    else
        l1 = value / 3
        l2 = value / 3
        l3 = value / 3
    end
    storage["l1"] = l1
    storage["l2"] = l2
    storage["l3"] = l3
    self.___attribute_dirty = true
end

--endregion

--region w
local proxy_w = AttributeProxy.createProxy("w")
attribute_proxies["w"] = proxy_w
function proxy_w:init(key, value, storage)
    storage[key] = value or 0
end

function proxy_w:setter(key, value, storage)
    local old_value = storage[key]
    if value == old_value then
        return
    end
    value = math.max(value, 0)
    storage[key] = value
    self.___attribute_dirty = true
end

--endregion

--region offset_at_head
local proxy_offset_at_head = AttributeProxy.createProxy("offset_at_head")
attribute_proxies["offset_at_head"] = proxy_offset_at_head
function proxy_offset_at_head:init(key, value, storage)
    storage[key] = value == nil or value
end

function proxy_offset_at_head:setter(key, value, storage)
    local old_value = storage[key]
    if value == old_value then
        return
    end
    storage[key] = value
    self.___attribute_dirty = true
end

--endregion

--region ___shooting_offset
local proxy_shooting_offset = AttributeProxy.createProxy("___shooting_offset")
attribute_proxies["___shooting_offset"] = proxy_shooting_offset
function proxy_shooting_offset:init(key, value, storage)
    storage[key] = value or 0
end

function proxy_shooting_offset:setter(key, value, storage)
    local old_value = storage[key]
    if value == old_value then
        return
    end
    storage[key] = value
    self.___attribute_dirty = true
end

--endregion

--region colli
local proxy_colli = AttributeProxy.createProxy("colli")
attribute_proxies["colli"] = proxy_colli

function proxy_colli:init(key, value, storage)
    storage[key] = value
    lstg.SetAttr(self, key, false)
end

function proxy_colli:setter(key, value, storage)
    local old_value = storage[key]
    if value == old_value then
        return
    end
    storage[key] = value
    self.___attribute_dirty = true
end

--endregion

--region group
local proxy_group = AttributeProxy.createProxy("group")
attribute_proxies["group"] = proxy_group
function proxy_group:init(key, value, storage)
    storage[key] = value or GROUP_ENEMY_BULLET
    lstg.SetAttr(self, key, GROUP_INDES)
end

function proxy_group:setter(key, value, storage)
    local old_value = storage[key]
    if value == old_value then
        return
    end
    storage[key] = value
    for i = 1, #self.___colliders do
        local c = self.___colliders[i]
        if lstg.IsValid(c) then
            lstg.SetAttr(c, key, value)
        end
    end
end

--endregion

--region bound
local proxy_bound = AttributeProxy.createProxy("bound")
attribute_proxies["bound"] = proxy_bound
function proxy_bound:init(key, value, storage)
    storage[key] = value == nil or value
    lstg.SetAttr(self, key, false)
end

--endregion

--region anchor
local proxy_anchor = AttributeProxy.createProxy("anchor")
attribute_proxies["anchor"] = proxy_anchor
function proxy_anchor:init(key, value, storage)
    storage[key] = value or EnumAnchor.Tail
end

function proxy_anchor:setter(key, value, storage)
    local old_value = storage[key]
    if value == old_value then
        return
    end
    storage[key] = value
    self.___attribute_dirty = true
end

--endregion

--region _graze
local proxy_graze = AttributeProxy.createProxy("_graze")
attribute_proxies["_graze"] = proxy_graze

function proxy_graze:setter(key, value, storage)
    storage[key] = value
    if value then
        self.graze_countdown = 3
    end
end

--endregion
--endregion

--region Game State Updater
local updater = {}
class.laserUpdater = updater

function updater:init()
    self.list = {}
    gameEventDispatcher:RegisterEvent("GameState.BeforeGameStageChange",
            "THlib-v2:Laser.Updater.on_GameState_BeforeGameStageChange", 0, self.on_GameState_BeforeGameStageChange)
    gameEventDispatcher:RegisterEvent("GameState.AfterObjFrame",
            "THlib-v2:Laser.Updater.on_GameState_AfterObjFrame", 0, self.on_GameState_AfterObjFrame)
end

function updater:addLaser(laser)
    self.list[#self.list + 1] = laser
end

function updater.on_GameState_BeforeGameStageChange()
    updater.list = {}
end

function updater.on_GameState_AfterObjFrame()
    local list = updater.list
    local i = 0
    while i < #list do
        i = i + 1
        local obj = list[i]
        if lstg.IsValid(obj) then
            local x = lstg.GetAttr(obj, "x")
            if obj.x ~= x then
                obj.x = x
            end
            local y = lstg.GetAttr(obj, "y")
            if obj.y ~= y then
                obj.y = y
            end
            local rot = lstg.GetAttr(obj, "rot")
            if obj.rot ~= rot then
                obj.rot = rot
            end
            if obj.___attribute_dirty then
                class.updateColliders(obj)
                obj.___attribute_dirty = false
            end
        else
            table.remove(list, i)
            i = i - 1
        end
    end
end

updater:init()
--endregion

return class
