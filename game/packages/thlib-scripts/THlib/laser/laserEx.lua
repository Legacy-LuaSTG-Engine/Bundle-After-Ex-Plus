--region Imports
local math = math
local table = table
local coroutine = coroutine
local lstg = lstg
local task = task
local AttributeProxy = require("foundation.AttributeProxy")
local Easing = require("foundation.Easing")
local QuickSort = require("foundation.QuickSort")
local laserCollider = require("THlib.laser.laserCollider")
--endregion

--region Class Definition
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

function class.create(x, y, rot, l1, l2, l3, w, node, head, index)
    local self = lstg.New(class)
    if not self then
        return
    end
    self.group = GROUP_INDES
    self.layer = LAYER_ENEMY_BULLET
    self.rect = true
    ---@diagnostic disable
    self.node = node
    self.head = head
    self.graze_countdown = 0
    self.shooting_speed = 0
    self.___shooting_offset = 0
    self.alpha = 0
    self._blend = "mul+add"
    self._a = 255
    self._r = 255
    self._g = 255
    self._b = 255
    self.task = {}
    self.___killed = false
    self.___colliders = {}
    self.___offset_colliders = {}
    self.___recovery_colliders = {}
    self.___changing_task = {}
    --
    self.onDelCollider = class.onDelCollider
    self.onKillCollider = class.onKillCollider
    ---@diagnostic enable
    class.applyDefaultLaserStyle(self, 1, index)
    AttributeProxy.applyProxies(self, class.___attribute_proxies)
    class.setPositionAndRotation(self, x, y, rot)
    class.setRectByPart(self, l1, l2, l3, w)
    class.updateColliders(self)
    self.colli = false
    return self
end

function class:frame()
    if self.___killed then
        class.updateChangingTask(self)
        if self.shooting_speed ~= 0 then
            self.___shooting_offset = self.___shooting_offset - self.shooting_speed
            class.updateColliders(self)
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
        class.updateColliders(self)
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
        local alpha = self.alpha
        local d = self.w
        task.Clear(self)
        task.New(self, function()
            for _ = 1, 30 do
                self.alpha = self.alpha - alpha / 30
                self.w = self.w - d / 30
                task.Wait()
            end
            lstg.Del(self)
        end)
    else
        for i = 1, #self.___colliders do
            local c = self.___colliders[i]
            if lstg.IsValid(c) then
                lstg.Del(c)
            end
        end
        for i = 1, #self.___recovery_colliders do
            local c = self.___recovery_colliders[i]
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
            if lstg.IsValid(c) then
                lstg.Del(c)
            end
        end
        for i = 1, #self.___recovery_colliders do
            local c = self.___recovery_colliders[i]
            if lstg.IsValid(c) then
                lstg.Del(c)
            end
        end
    end
end

--endregion

--region Main Methods
function class:onDelCollider(collider, offset)
    if not ((self.___colliders[collider] or self.___recovery_colliders[collider]) and lstg.IsValid(collider)) then
        return
    end
    if not self.___killed then
        PreserveObject(collider)
    end
    if collider.___killed then
        return
    end
    collider.___killed = true
    if self.style_index then
        lstg.New(BulletBreak, collider.x, collider.y, self.style_index)
    end
end

function class:onKillCollider(collider, offset)
    if not ((self.___colliders[collider] or self.___recovery_colliders[collider]) and lstg.IsValid(collider)) then
        return
    end
    if not self.___killed then
        PreserveObject(collider)
    end
    if collider.___killed then
        return
    end
    collider.___killed = true
    lstg.New(item_faith_minor, collider.x, collider.y)
    if self.style_index then
        lstg.New(BulletBreak, collider.x, collider.y, self.style_index)
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
    local rot = self.rot
    local rot_cos = lstg.cos(rot)
    local rot_sin = lstg.sin(rot)
    local half_width = self.w / 2
    local colli = self.colli
    local fix_tail_offset = math.floor(total_offset / 16) * 16
    local fix_head_offset = math.ceil((total_offset + length) / 16) * 16
    local have_changed = false
    for part_offset = fix_tail_offset, fix_head_offset, 16 do
        local collider = self.___offset_colliders[part_offset]
        if not collider then
            collider = class.generateCollider(self, part_offset)
            colliders[#colliders + 1] = collider
            have_changed = true
        end
    end
    if have_changed then
        QuickSort(colliders, function(a, b)
            return a.___collider_offset > b.___collider_offset
        end)
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

function class:generateCollider(offset)
    local collider = table.remove(self.___recovery_colliders)
    if collider then
        collider.___killed = false
        collider.___collider_offset = offset
        self.___recovery_colliders[collider] = nil
    else
        collider = laserCollider.create(self, offset)
    end
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
    class.updateColliders(self)
end

function class:setRectByPart(l1, l2, l3, width)
    AttributeProxy.setStorageValue(self, "l1", l1)
    AttributeProxy.setStorageValue(self, "l2", l2)
    AttributeProxy.setStorageValue(self, "l3", l3)
    if width then
        AttributeProxy.setStorageValue(self, "w", width)
    end
    class.updateColliders(self)
end

--endregion

--region Attribute Proxies
local attribute_proxies = {}
class.___attribute_proxies = attribute_proxies

--region x
local proxy_x = AttributeProxy.createProxy("x")
attribute_proxies["x"] = proxy_x
function proxy_x:init(key)
    AttributeProxy.setStorageValue(self, key, lstg.GetAttr(self, key))
end

function proxy_x:setter(key, value)
    AttributeProxy.setStorageValue(self, key, value)
    lstg.SetAttr(self, key, value)
    class.updateColliders(self)
end

--endregion

--region y
local proxy_y = AttributeProxy.createProxy("y")
attribute_proxies["y"] = proxy_y
function proxy_y:init(key)
    AttributeProxy.setStorageValue(self, key, lstg.GetAttr(self, key))
end

function proxy_y:setter(key, value)
    AttributeProxy.setStorageValue(self, key, value)
    lstg.SetAttr(self, key, value)
    class.updateColliders(self)
end

--endregion

--region rot
local proxy_rot = AttributeProxy.createProxy("rot")
attribute_proxies["rot"] = proxy_rot
function proxy_rot:init(key)
    AttributeProxy.setStorageValue(self, key, lstg.GetAttr(self, key))
end

function proxy_rot:setter(key, value)
    AttributeProxy.setStorageValue(self, key, value)
    lstg.SetAttr(self, key, value)
    class.updateColliders(self)
end

--endregion

--region l1
local proxy_l1 = AttributeProxy.createProxy("l1")
attribute_proxies["l1"] = proxy_l1
function proxy_l1:init(key)
    AttributeProxy.setStorageValue(self, key, 0)
end

function proxy_l1:setter(key, value)
    value = math.max(value, 0)
    AttributeProxy.setStorageValue(self, key, value)
    class.updateColliders(self)
end

--endregion

--region l2
local proxy_l2 = AttributeProxy.createProxy("l2")
attribute_proxies["l2"] = proxy_l2
function proxy_l2:init(key)
    AttributeProxy.setStorageValue(self, key, 0)
end

function proxy_l2:setter(key, value)
    value = math.max(value, 0)
    AttributeProxy.setStorageValue(self, key, value)
    class.updateColliders(self)
end

--endregion

--region l3
local proxy_l3 = AttributeProxy.createProxy("l3")
attribute_proxies["l3"] = proxy_l3
function proxy_l3:init(key)
    AttributeProxy.setStorageValue(self, key, 0)
end

function proxy_l3:setter(key, value)
    value = math.max(value, 0)
    AttributeProxy.setStorageValue(self, key, value)
    class.updateColliders(self)
end

--endregion

--region length
local proxy_length = AttributeProxy.createProxy("length")
attribute_proxies["length"] = proxy_length
function proxy_length:getter(key)
    return AttributeProxy.getStorageValue(self, "l1")
            + AttributeProxy.getStorageValue(self, "l2")
            + AttributeProxy.getStorageValue(self, "l3")
end

function proxy_length:setter(key, value)
    value = math.max(value, 0)
    if value == 0 then
        AttributeProxy.setStorageValue(self, "l1", 0)
        AttributeProxy.setStorageValue(self, "l2", 0)
        AttributeProxy.setStorageValue(self, "l3", 0)
        class.updateColliders(self)
        return
    end
    local l1 = AttributeProxy.getStorageValue(self, "l1")
    local l2 = AttributeProxy.getStorageValue(self, "l2")
    local l3 = AttributeProxy.getStorageValue(self, "l3")
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
    AttributeProxy.setStorageValue(self, "l1", l1)
    AttributeProxy.setStorageValue(self, "l2", l2)
    AttributeProxy.setStorageValue(self, "l3", l3)
    class.updateColliders(self)
end

--endregion

--region w
local proxy_w = AttributeProxy.createProxy("w")
attribute_proxies["w"] = proxy_w
function proxy_w:init(key)
    AttributeProxy.setStorageValue(self, key, 0)
end

function proxy_w:setter(key, value)
    value = math.max(value, 0)
    AttributeProxy.setStorageValue(self, key, value)
    class.updateColliders(self)
end

--endregion

--region colli
local proxy_colli = AttributeProxy.createProxy("colli")
attribute_proxies["colli"] = proxy_colli

function proxy_colli:init(key)
    AttributeProxy.setStorageValue(self, key, true)
    lstg.SetAttr(self, key, false)
end

function proxy_colli:setter(key, value)
    local old_value = AttributeProxy.getStorageValue(self, key)
    if value == old_value then
        return
    end
    AttributeProxy.setStorageValue(self, key, value)
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
function proxy_bound:init(key)
    AttributeProxy.setStorageValue(self, key, true)
    lstg.SetAttr(self, key, false)
end

--endregion

--region anchor
local proxy_anchor = AttributeProxy.createProxy("anchor")
attribute_proxies["anchor"] = proxy_anchor
function proxy_anchor:init(key)
    AttributeProxy.setStorageValue(self, key, EnumAnchor.Tail)
end

function proxy_anchor:setter(key, value)
    local old_value = AttributeProxy.getStorageValue(self, key)
    if value == old_value then
        return
    end
    AttributeProxy.setStorageValue(self, key, value)
    class.updateColliders(self)
end

--endregion

--region _graze
local proxy_graze = AttributeProxy.createProxy("_graze")
attribute_proxies["_graze"] = proxy_graze
function proxy_graze:init(key)
    AttributeProxy.setStorageValue(self, key, false)
end

function proxy_graze:setter(key, value)
    AttributeProxy.setStorageValue(self, key, value)
    if value then
        self.graze_countdown = 3
    end
end

--endregion
--endregion

return class
