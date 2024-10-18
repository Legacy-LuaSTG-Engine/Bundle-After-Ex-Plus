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
if false then
    ---@class THlib.v2.bullet.laser.laser.colliderChain
    local chain = {
        ---@type THlib.v2.bullet.laser.laserCollider[] @Child colliders
        colliders = {},
        count = 0,               -- Number of colliders
        length = 0,              -- Length of the chain
        head = { x = 0, y = 0 }, -- Head position
        tail = { x = 0, y = 0 }, -- Tail position
        full_offset_tail = 0,    -- Offset begin
        full_offset_head = 0,    -- Offset end
    }
end

---@class THlib.v2.bullet.laser.laser : lstg.GameObject, lstg.Class
local class = lstg.CreateGameObjectClass()

--region Enums
---@enum THlib.v2.bullet.laser.EnumAnchor
local EnumAnchor = {
    Head = 1,
    Center = 2,
    Tail = 3,
}
class.EnumAnchor = EnumAnchor

---@enum THlib.v2.bullet.laser.EnumChangeIndex
local EnumChangeIndex = {
    Alpha = 1,
    Width = 2,
    Length = 3,
    Total = 3,
}
class.EnumChangeIndex = EnumChangeIndex
--endregion

---@param x number @Anchor position x
---@param y number @Anchor position y
---@param rot number @Rotation
---@param l1 number @Length of the first part
---@param l2 number @Length of the second part
---@param l3 number @Length of the third part
---@param w number @Width
---@param node number @Node size
---@param head number @Head size
---@param index number @Style index
---@return THlib.v2.bullet.laser.laser
function class.create(x, y, rot, l1, l2, l3, w, node, head, index)
    ---@type THlib.v2.bullet.laser.laser
    ---@diagnostic disable-next-line: assign-type-mismatch
    local self = lstg.New(class)
    -- Basic attributes
    self.group = GROUP_ENEMY_BULLET            -- Child colliders group
    self.layer = LAYER_ENEMY_BULLET            -- Render layer
    self.x = x or 0                            -- Anchor position x
    self.y = y or 0                            -- Anchor position y
    self.rot = rot or 0                        -- Rotation
    self.colli = false                         -- Current collision status (for child colliders)
    -- Laser attributes
    self.l1 = l1 or 0                          -- Length of the first part
    self.l2 = l2 or 0                          -- Length of the second part
    self.l3 = l3 or 0                          -- Length of the third part
    self.w = w or 0                            -- Width
    self.node = node or 0                      -- Node size
    self.head = head or 0                      -- Head size
    self.anchor = EnumAnchor.Tail              -- Anchor position
    self.graze_countdown = 0                   -- Graze countdown
    self.shooting_speed = 0                    -- Shooting speed ( -offset per frame )
    self.killed_at_spawn = false               -- Child colliders are killed at spawn
    self.offset_at_head = true                 -- Offset at head
    self.alpha = 0                             -- Render Alpha
    self.enable_valid_check = false            -- Enable valid check
    -- Color attributes
    self._blend = "mul+add"                    -- Blend mode
    self._a = 255                              -- Color alpha
    self._r = 255                              -- Color red
    self._g = 255                              -- Color green
    self._b = 255                              -- Color blue
    -- Internal attributes
    self.___killed = false                     -- Killed flag
    self.___shooting_offset = 0                -- Shooting offset
    self.___colliders = {}                     -- Child colliders
    self.___offset_colliders = {}              -- Child colliders by offset
    self.___recovery_colliders = {}            -- Recovery child colliders
    self.___changing_task = {}                 -- Changing task
    self.___attribute_dirty = false            -- Attribute dirty
    -- Callbacks
    self.onRender = class.renderDefaultLaserStyle                         -- On render callback
    self.onDelCollider = class.defaultOnDelCollider                       -- On delete collider callback
    self.onKillCollider = class.defaultOnKillCollider                     -- On kill collider callback
    self.onCheckColliderChainValid = class.defaultCheckColliderChainValid -- On check collider chain valid callback
    -- Finalize
    class.applyDefaultLaserStyle(self, 1, index or 1)
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
    if not self.onRender then
        return
    end
    local parts = class.getLaserColliderParts(self)
    self.onRender(self, parts)
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
---Preserve a collider if it is child of this laser
---@param collider THlib.v2.bullet.laser.laserCollider
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

---Called when a collider is deleted
---@param collider THlib.v2.bullet.laser.laserCollider
---@param args table<string, any>
function class:dispatchColliderOnDelete(collider, args)
    if not class.checkPreserveCollider(self, collider) then
        return
    end
    if self.onDelCollider then
        self.onDelCollider(self, collider, args)
    end
end

---Default value of user defined callback when a collider is deleted
---@param collider THlib.v2.bullet.laser.laserCollider
---@param args table<string, any>
function class:defaultOnDelCollider(collider, args)
    local w = lstg.world
    if self.style_index and lstg.BoxCheck(collider, w.boundl, w.boundr, w.boundb, w.boundt) then
        lstg.New(BulletBreak, collider.x, collider.y, self.style_index)
    end
end

---Called when a collider is killed
---@param collider THlib.v2.bullet.laser.laserCollider
---@param args table<string, any>
function class:dispatchColliderOnKill(collider, args)
    if not class.checkPreserveCollider(self, collider) then
        return
    end
    if self.onKillCollider then
        self.onKillCollider(self, collider, args)
    end
end

---Default value of user defined callback when a collider is killed
---@param collider THlib.v2.bullet.laser.laserCollider
---@param args table<string, any>
function class:defaultOnKillCollider(collider, args)
    local w = lstg.world
    if lstg.BoxCheck(collider, w.boundl, w.boundr, w.boundb, w.boundt) then
        lstg.New(item_faith_minor, collider.x, collider.y)
        if self.style_index then
            lstg.New(BulletBreak, collider.x, collider.y, self.style_index)
        end
    end
end

---Check collider chain valid
---@param chains THlib.v2.bullet.laser.laser.colliderChain[]
function class:dispatchCheckColliderChainValid(chains)
    if self.enable_valid_check and self.onCheckColliderChainValid then
        for i = 1, #chains do
            if not self.onCheckColliderChainValid(self, chains[i]) then
                for j = 1, chains[i].count do
                    chains[i].colliders[j].___killed = true
                end
            end
        end
    end
end

---Default value of user defined callback when checking collider chain valid
---@param chain THlib.v2.bullet.laser.laser.colliderChain
function class:defaultCheckColliderChainValid(chain)
    return self.shooting_speed ~= 0 or chain.length >= 16
end

---Check if the laser is out of bound
---@return boolean
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

---Update laser colliders immediately
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
                return a.args.offset > b.args.offset
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

---Recovery a collider
---@param collider THlib.v2.bullet.laser.laserCollider
function class:recoveryCollider(collider)
    if not (self.___colliders[collider] and lstg.IsValid(collider)) then
        return
    end
    collider.___killed = true
    self.___colliders[collider] = nil
    self.___offset_colliders[collider.args.offset] = nil
    self.___recovery_colliders[#self.___recovery_colliders + 1] = collider
    self.___recovery_colliders[collider] = true
end

---Generate a collider
---@param offset number @Offset
---@param killed boolean @Killed flag
---@return THlib.v2.bullet.laser.laserCollider
function class:generateCollider(offset, killed)
    local collider = table.remove(self.___recovery_colliders)
    if lstg.IsValid(collider) then
        collider.group = self.group
        collider.master = self
        collider.args = { offset = offset }
        collider.on_del = class.dispatchColliderOnDelete
        collider.on_kill = class.dispatchColliderOnKill
        self.___recovery_colliders[collider] = nil
    else
        collider = laserCollider.create(self, self.group, { offset = offset },
            class.dispatchColliderOnDelete, class.dispatchColliderOnKill)
    end
    collider.___killed = killed == nil or killed
    self.___colliders[collider] = true
    self.___offset_colliders[offset] = collider
    return collider
end

---Update a collider
---@param collider THlib.v2.bullet.laser.laserCollider
---@param tail_x number @Tail position x
---@param tail_y number @Tail position y
---@param total_length number @Total length
---@param total_offset number @Total offset
---@param half_width number @Half width
---@param colli boolean @Collision flag
---@param rot number @Rotation
---@param rot_cos number @Rotation cos (pre-calculated)
---@param rot_sin number @Rotation sin (pre-calculated)
---@return boolean
function class:updateCollider(collider, tail_x, tail_y, total_length, total_offset,
                              half_width, colli, rot, rot_cos, rot_sin)
    local collider_offset = collider.args.offset
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

---Get all laser collider parts
---@return table<number, THlib.v2.bullet.laser.laser.colliderChain>
function class:getLaserColliderParts()
    local colliders = self.___colliders
    local parts = {}
    local part = {}
    for i = 1, #colliders do
        local c = colliders[i]
        if not c.___killed then
            part[#part + 1] = c
        elseif #part > 0 then
            parts[#parts + 1] = part
            part = {}
        end
    end
    if #part > 0 then
        parts[#parts + 1] = part
    end
    local chains = {}
    for i = 1, #parts do
        part = parts[i]
        ---@type THlib.v2.bullet.laser.laser.colliderChain
        local chain = {}
        chain.colliders = part
        chain.count = #part
        local head_node = part[1]
        local tail_node = part[#part]
        if head_node == tail_node then
            chain.length = head_node.a * 2
        else
            chain.length = (head_node.a + tail_node.a) * 2 + math.max(0, #part - 2) * 16
        end
        chain.head = {
            x = head_node.x + head_node.a * lstg.cos(self.rot),
            y = head_node.y + head_node.a * lstg.sin(self.rot),
        }
        chain.tail = {
            x = tail_node.x - tail_node.a * lstg.cos(self.rot),
            y = tail_node.y - tail_node.a * lstg.sin(self.rot),
        }
        chain.full_offset_tail = tail_node.args.offset + 8 - tail_node.a * 2
        chain.full_offset_head = chain.full_offset_tail + chain.length
        chains[#chains + 1] = chain
    end
    return chains
end

---Render a laser collider part (default style)
---@param chains THlib.v2.bullet.laser.laser.colliderChain[]
function class:renderDefaultLaserStyle(chains)
    if self.node > 0 then
        local x, y = class.getAnchorPosition(self, EnumAnchor.Tail)
        local color = lstg.Color(self._a, self._r, self._g, self._b)
        lstg.SetImageState(self.img4, self._blend, color)
        lstg.Render(self.img4, x, y, 18 * self.timer, self.node / 8)
        lstg.Render(self.img4, x, y, -18 * self.timer, self.node / 8)
    end
    if not chains or #chains == 0 then
        return
    end
    local width = self.w
    local rot = self.rot
    local rot_cos = lstg.cos(rot)
    local rot_sin = lstg.sin(rot)
    local blend = self._blend
    local color = lstg.Color(self._a * self.alpha, self._r, self._g, self._b)
    local color_head = lstg.Color(self._a, self._r, self._g, self._b)
    local w = width / 2 / self.img_wm * self.img_w / self.img_wm
    local total_length = self.length
    local l1_r = self.l1 / total_length
    local l2_r = self.l2 / total_length
    local l3_r = self.l3 / total_length
    for i = 1, #chains do
        local chain = chains[i]
        if chain.length > 0 then
            local length = chain.length
            local x = chain.tail.x
            local y = chain.tail.y
            if width > 0 then
                local l1 = l1_r * length
                local l2 = l2_r * length
                local l3 = l3_r * length
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
                x = x + l3 * rot_cos
                y = y + l3 * rot_sin
            else
                x = x + length * rot_cos
                y = y + length * rot_sin
            end
            if self.head > 0 then
                lstg.SetImageState(self.img5, self._blend, color_head)
                lstg.Render(self.img5, x, y, 0, self.head / 8)
                lstg.Render(self.img5, x, y, 0, 0.75 * self.head / 8)
            end
        end
    end
end

---Update changing task
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

---Get anchor position
---@param anchor THlib.v2.bullet.laser.EnumAnchor
---@return number, number
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

---Apply default laser style
---@param id number
---@param index number
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
---Apply laser changing task about width
---@param width number @Width
---@param time number @Time (0 for immediate)
---@param easing_func function @Easing function
---@overload fun(width: number) @Immediate change width
---@overload fun(width: number, time: number) @Change width with time
function class:toWidth(width, time, easing_func)
    if not time or time <= 0 then
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

---Apply laser changing task about alpha
---@param alpha number @Alpha
---@param time number @Time (0 for immediate)
---@param easing_func function @Easing function
---@overload fun(alpha: number) @Immediate change alpha
---@overload fun(alpha: number, time: number) @Change alpha with time
function class:toAlpha(alpha, time, easing_func)
    if not time or time <= 0 then
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

---Apply laser changing task about length
---@param l1 number @Length of the first part
---@param l2 number @Length of the second part
---@param l3 number @Length of the third part
---@param time number @Time (0 for immediate)
---@param easing_func function @Easing function
---@overload fun(l1: number, l2: number, l3: number) @Immediate change length
---@overload fun(l1: number, l2: number, l3: number, time: number) @Change length with time
function class:toLength(l1, l2, l3, time, easing_func)
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

---Turn on the laser
---@param width number @Width
---@param time number @Time
---@param open_collider boolean @Open colliders
---@overload fun(width: number, time: number) @Turn on the laser
function class:turnOn(width, time, open_collider)
    class.toAlpha(self, 1, time)
    class.toWidth(self, width, time)
    if open_collider then
        task.New(self, function()
            task.Wait(time)
            self.colli = true
        end)
    end
end

---Turn on the laser with half alpha
---@param width number @Width
---@param time number @Time
function class:turnHalfOn(width, time)
    class.toAlpha(self, 0.5, time)
    class.toWidth(self, width, time)
end

---Turn off the laser
---@param time number @Time
---@param close_colliders boolean @Close colliders
---@overload fun(time: number) @Turn off the laser
function class:turnOff(time, close_colliders)
    if close_colliders then
        self.colli = false
    end
    class.toAlpha(self, 0, time)
    class.toWidth(self, 0, time)
end

---Turn off the laser with half alpha
---@param width number @Width
---@param time number @Time
---@param close_colliders boolean @Close colliders
---@overload fun(width: number, time: number) @Turn off the laser with half alpha
function class:turnHalfOff(width, time, close_colliders)
    if close_colliders then
        self.colli = false
    end
    class.toAlpha(self, 0.5, time)
    class.toWidth(self, width, time)
end

---Set position and rotation
---@param x number @Position x
---@param y number @Position y
---@param rot number @Rotation
function class:setPositionAndRotation(x, y, rot)
    AttributeProxy.setStorageValue(self, "x", x)
    AttributeProxy.setStorageValue(self, "y", y)
    AttributeProxy.setStorageValue(self, "rot", rot)
    self.___attribute_dirty = true
end

---Set length and width
---@param l1 number @Length of the first part
---@param l2 number @Length of the second part
---@param l3 number @Length of the third part
---@param width number @Width
---@overload fun(l1: number, l2: number, l3: number) @Set length
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
    gameEventDispatcher:RegisterEvent("GameState.AfterCollisionCheck",
        "THlib-v2:Laser.Updater.on_GameState_AfterCollisionCheck", 0, self.on_GameState_AfterCollisionCheck)
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

function updater.on_GameState_AfterCollisionCheck()
    local list = updater.list
    for i = 1, #list do
        local obj = list[i]
        if lstg.IsValid(obj) and obj.enable_valid_check then
            local chains = class.getLaserColliderParts(obj)
            class.dispatchCheckColliderChainValid(obj, chains)
        end
    end
end

updater:init()
--endregion

return class
