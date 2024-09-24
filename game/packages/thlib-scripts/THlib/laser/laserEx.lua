--region Imports
local math = math
local coroutine = coroutine
local rawget = rawget
local rawset = rawset
local lstg = lstg
local task = task
local AttributeProxy = require("foundation.AttributeProxy")
local Easing = require("foundation.Easing")
--endregion

--region Local Functions
local function InScope(var, minvar, maxvar)
    return var >= minvar and var <= maxvar
end

local function GetIntersction(x1, y1, rot1, x2)
    local t = (x2 - x1) / lstg.cos(rot1)
    local y = y1 + t * lstg.sin(rot1)
    return x2, y
end

local function IsInRect(x, y, l, r, b, t)
    return x >= l and x <= r and y >= b and y <= t
end

local function CCW(x1, y1, x2, y2, x3, y3)
    return (y3 - y1) * (x2 - x1) > (y2 - y1) * (x3 - x1)
end

local function CheckIntersect(x1, y1, x2, y2, x3, y3, x4, y4)
    return CCW(x1, y1, x3, y3, x4, y4) ~= CCW(x2, y2, x3, y3, x4, y4) and
        CCW(x1, y1, x2, y2, x3, y3) ~= CCW(x1, y1, x2, y2, x4, y4)
end

local function CheckLineIntersectRect(x1, y1, x2, y2, l, r, b, t) -- will miss the line that only passes through the vertex
    if IsInRect(x1, y1, l, r, b, t) then
        return true
    end
    if IsInRect(x2, y2, l, r, b, t) then
        return true
    end
    return CheckIntersect(x1, y1, x2, y2, l, b, r, t) or
        CheckIntersect(x1, y1, x2, y2, l, t, r, b)
end

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
    self.colli = false
    rawset(self, "node", node)
    rawset(self, "head", head)
    rawset(self, "graze_countdown", 0)
    rawset(self, "alpha", 0)
    rawset(self, "_blend", "mul+add")
    rawset(self, "_a", 255)
    rawset(self, "_r", 255)
    rawset(self, "_g", 255)
    rawset(self, "_b", 255)
    rawset(self, "___killed", false)
    rawset(self, "task", {})
    rawset(self, "___changing_task", {})
    class.applyDefaultLaserStyle(self, 1, index)
    AttributeProxy.applyProxies(self, class.___attribute_proxies)
    class.setPositionAndRotation(self, x, y, rot)
    class.setRectByPart(self, l1, l2, l3, w)
    return self
end

function class:frame()
    if rawget(self, "___killed") then
        class.applyChanging(self)
        return
    end
    task.Do(self)
    class.applyChanging(self)
    if self.graze_countdown > 0 then
        self.graze_countdown = self.graze_countdown - 1
    elseif self._graze then
        self._graze = false
    end
    local open_bound = self.bound
    local bound_status = lstg.GetAttr(self, "bound")
    local is_out_of_bound = class.checkIsOutOfBound(self)
    if open_bound and is_out_of_bound then
        if not bound_status then
            lstg.SetAttr(self, "bound", true)
        end
    elseif bound_status then
        lstg.SetAttr(self, "bound", false)
    end
end

function class:render()
    local width = self.w
    local length = self.length
    if width > 0 and length > 0 then
        local blend = self._blend
        local rot = self.rot
        local color = lstg.Color(self._a * self.alpha, self._r, self._g, self._b)
        local w = width / 2 / self.img_wm * self.img_w / self.img_wm
        --
        local proxy_x, proxy_y = class.calculationPositionProxy(self)
        local head_x = proxy_x - length / 2 * lstg.cos(rot)
        local head_y = proxy_y - length / 2 * lstg.sin(rot)
        local x, y = head_x, head_y
        --
        local dx = self.l1 * lstg.cos(rot)
        local dy = self.l1 * lstg.sin(rot)
        lstg.SetImageState(self.img1, blend, color)
        lstg.Render(self.img1, x, y, rot, self.l1 / self.img1_l, w)
        x = x + dx
        y = y + dy
        --
        dx = self.l2 * lstg.cos(rot)
        dy = self.l2 * lstg.sin(rot)
        lstg.SetImageState(self.img2, blend, color)
        lstg.Render(self.img2, x, y, rot, self.l2 / self.img2_l, w)
        x = x + dx
        y = y + dy
        --
        dx = self.l3 * lstg.cos(rot)
        dy = self.l3 * lstg.sin(rot)
        lstg.SetImageState(self.img3, blend, color)
        lstg.Render(self.img3, x, y, rot, self.l3 / self.img3_l, w)
        x = x + dx
        y = y + dy
        if self.node > 0 and self.head > 0 then
            color = lstg.Color(self._a, self._r, self._g, self._b)
            if self.node > 0 then
                lstg.SetImageState(self.img4, blend, color)
                lstg.Render(self.img4, head_x, head_y, 18 * self.timer, self.node / 8)
                lstg.Render(self.img4, head_x, head_y, -18 * self.timer, self.node / 8)
            end
            if self.head > 0 then
                lstg.SetImageState(self.img5, blend, color)
                lstg.Render(self.img5, x, y, 0, self.head / 8)
                lstg.Render(self.img5, x, y, 0, 0.75 * self.head / 8)
            end
        end
    end
end

function class:del()
    if not rawget(self, "___killed") then
        PreserveObject(self)
        rawset(self, "___killed", true)
        self.colli = false
        local alpha = self.alpha
        local d = self.w
        task.Clear(self)
        task.New(self, function()
            for i = 1, 30 do
                self.alpha = self.alpha - alpha / 30
                self.w = self.w - d / 30
                task.Wait()
            end
            lstg.Del(self)
        end)
    end
end

function class:kill()
    if not rawget(self, "___killed") then
        PreserveObject(self)
        rawset(self, "___killed", true)
        local x1, y1, x2, y2, x, y
        local w = lstg.world
        local x0, y0, rot = self.x, self.y, self.rot
        local len = self.l1 + self.l2 + self.l3
        local tx0, ty0 = x0 + len * lstg.cos(rot), y0 + len * lstg.sin(rot)
        if x0 > tx0 then
            x0, tx0, y0, ty0 = tx0, x0, ty0, y0
        end
        --
        local bx, by = GetIntersction(x0, y0, rot, w.boundl)
        local lx, ly = GetIntersction(x0, y0, rot, w.boundl)
        local tx, ty = GetIntersction(x0, y0, rot, w.boundr)
        local rx, ry = GetIntersction(x0, y0, rot, w.boundr)
        --
        local flag = InScope(x0, w.boundl, w.boundr)
        flag = flag or InScope(tx0, w.boundl, w.boundr)
        flag = flag or InScope(y0, w.boundb, w.boundt)
        flag = flag or InScope(ty0, w.boundb, w.boundt)
        flag = flag or InScope(bx, w.boundl, w.boundr)
        flag = flag or InScope(tx, w.boundl, w.boundr)
        flag = flag or InScope(ly, w.boundb, w.boundt)
        flag = flag or InScope(ry, w.boundb, w.boundt)
        if flag then
            if by < ly then
                if x0 < bx then
                    x1, y1 = bx, by
                else
                    x1, y1 = x0, y0
                end
            else
                if x0 < lx then
                    x1, y1 = lx, ly
                else
                    x1, y1 = x0, y0
                end
            end
            if ry < ty then
                if tx0 < rx then
                    x2, y2 = tx0, ty0
                else
                    x2, y2 = rx, ry
                end
            else
                if tx0 < tx then
                    x2, y2 = tx0, ty0
                else
                    x2, y2 = tx, ty
                end
            end
            len = lstg.Dist(x1, y1, x2, y2)
            if self.x <= x1 then
                x, y = x1, y1
            else
                x, y, rot = x2, y2, rot + 180
            end
            local cx, cy = lstg.cos(rot), lstg.sin(rot)
            for l = 0, len, 12 do
                lstg.New(item_faith_minor, x + l * cx, y + l * cy)
                if l % 2 == 0 and self.index then
                    lstg.New(BulletBreak, x + l * cx, y + l * cy, self.index)
                end
            end
        end
        self.colli = false
        local alpha = self.alpha
        local d = self.w
        local tasks = rawget(self, "___changing_task")
        tasks[EnumChangeIndex.Alpha] = coroutine.create(function()
            for i = 1, 30 do
                self.alpha = self.alpha - i / 30
                coroutine.yield()
            end
            Del(self)
        end)
        tasks[EnumChangeIndex.Width] = coroutine.create(function()
            for i = 1, 30 do
                self.w = self.w - d / 30
                coroutine.yield()
            end
        end)
    end
end

--endregion

--region Methods
function class:toWidth(time, width, easing_func)
    easing_func = easing_func or Easing.linear
    local begin = self.w
    local dp = width - begin
    local tasks = rawget(self, "___changing_task")
    tasks[EnumChangeIndex.Width] = coroutine.create(function()
        for i = 1, time do
            self.w = begin + dp * easing_func(i / time)
            coroutine.yield()
        end
    end)
end

function class:toAlpha(time, alpha, easing_func)
    easing_func = easing_func or Easing.linear
    local begin = self.alpha
    local dp = alpha - begin
    local tasks = rawget(self, "___changing_task")
    tasks[EnumChangeIndex.Alpha] = coroutine.create(function()
        for i = 1, time do
            self.alpha = begin + dp * easing_func(i / time)
            coroutine.yield()
        end
    end)
end

function class:toLength(time, l1, l2, l3, easing_func)
    easing_func = easing_func or Easing.linear
    local begin_l1 = self.l1
    local begin_l2 = self.l2
    local begin_l3 = self.l3
    local dp1 = l1 - begin_l1
    local dp2 = l2 - begin_l2
    local dp3 = l3 - begin_l3
    local tasks = rawget(self, "___changing_task")
    tasks[EnumChangeIndex.Length] = coroutine.create(function()
        for i = 1, time do
            self.l1 = begin_l1 + dp1 * easing_func(i / time)
            self.l2 = begin_l2 + dp2 * easing_func(i / time)
            self.l3 = begin_l3 + dp3 * easing_func(i / time)
            coroutine.yield()
        end
    end)
end

function class:applyChanging()
    local tasks = rawget(self, "___changing_task")
    if not tasks then
        return
    end
    for i = 1, EnumChangeIndex.Total do
        local task = tasks[i] -- coroutine
        if task then
            local success, result = coroutine.resume(task)
            if not success then
                error(result)
            end
            if coroutine.status(task) == "dead" then
                tasks[i] = nil
            end
        end
    end
end

function class:applyDefaultLaserStyle(id, index)
    id = math.max(math.min(math.floor(id), laser_texture_num - 1), 1)
    index = math.max(math.min(math.floor(index), 16), 1)
    local data = laser_data[id]
    rawset(self, "img1_l", data[1])
    rawset(self, "img2_l", data[2])
    rawset(self, "img3_l", data[3])
    rawset(self, "img_w", data[4])
    rawset(self, "img_wm", data[6])
    rawset(self, "img1", "laser" .. id .. "1" .. index)
    rawset(self, "img2", "laser" .. id .. "2" .. index)
    rawset(self, "img3", "laser" .. id .. "3" .. index)
    rawset(self, "img4", "laser_node" .. math.ceil(index / 2))
    rawset(self, "img5", "ball_mid_b" .. math.ceil(index / 2))
end

function class:checkIsOutOfBound()
    local w = lstg.world
    local rot = self.rot
    local length = self.length
    local proxy_x, proxy_y = class.calculationPositionProxy(self)
    local head_x = proxy_x - length / 2 * lstg.cos(rot)
    local head_y = proxy_y - length / 2 * lstg.sin(rot)
    local tail_x = proxy_x + length / 2 * lstg.cos(rot)
    local tail_y = proxy_y + length / 2 * lstg.sin(rot)
    return not CheckLineIntersectRect(head_x, head_y, tail_x, tail_y, w.boundl, w.boundr, w.boundb, w.boundt)
end

function class:calculationPositionProxy()
    local x = self.x
    local y = self.y
    local anchor = self.anchor
    local length = self.length
    local rot = self.rot
    if anchor == EnumAnchor.Head then
        x = x - length * lstg.cos(rot) / 2
        y = y - length * lstg.sin(rot) / 2
    elseif anchor == EnumAnchor.Tail then
        x = x + length * lstg.cos(rot) / 2
        y = y + length * lstg.sin(rot) / 2
    end
    return x, y
end

function class:setPositionAndRotation(x, y, rot)
    AttributeProxy.setStorageValue(self, "x", x)
    AttributeProxy.setStorageValue(self, "y", y)
    AttributeProxy.setStorageValue(self, "rot", rot)
    class.applyPosition(self)
end

function class:setRectByPart(l1, l2, l3, width)
    AttributeProxy.setStorageValue(self, "l1", l1)
    AttributeProxy.setStorageValue(self, "l2", l2)
    AttributeProxy.setStorageValue(self, "l3", l3)
    if width then
        AttributeProxy.setStorageValue(self, "w", width)
    end
    class.applyPosition(self)
    class.applyCollision(self)
end

function class:applyPosition()
    local x, y = class.calculationPositionProxy(self)
    lstg.SetAttr(self, "x", x)
    lstg.SetAttr(self, "y", y)
end

function class:applyCollision()
    lstg.SetAttr(self, "a", self.length / 2)
    lstg.SetAttr(self, "b", self.w / 2)
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
    local x, _ = class.calculationPositionProxy(self)
    lstg.SetAttr(self, key, x)
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
    local _, y = class.calculationPositionProxy(self)
    lstg.SetAttr(self, key, y)
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
    local x, y = class.calculationPositionProxy(self)
    lstg.SetAttr(self, key, value)
    lstg.SetAttr(self, "x", x)
    lstg.SetAttr(self, "y", y)
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
    local x, y = class.calculationPositionProxy(self)
    lstg.SetAttr(self, "x", x)
    lstg.SetAttr(self, "y", y)
    lstg.SetAttr(self, "a", self.length / 2)
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
    local x, y = class.calculationPositionProxy(self)
    lstg.SetAttr(self, "x", x)
    lstg.SetAttr(self, "y", y)
    lstg.SetAttr(self, "a", self.length / 2)
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
    local x, y = class.calculationPositionProxy(self)
    lstg.SetAttr(self, "x", x)
    lstg.SetAttr(self, "y", y)
    lstg.SetAttr(self, "a", self.length / 2)
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
        local x, y = class.calculationPositionProxy(self)
        lstg.SetAttr(self, "x", x)
        lstg.SetAttr(self, "y", y)
        lstg.SetAttr(self, "a", 0)
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
    local x, y = class.calculationPositionProxy(self)
    lstg.SetAttr(self, "x", x)
    lstg.SetAttr(self, "y", y)
    lstg.SetAttr(self, "a", value / 2)
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
    lstg.SetAttr(self, "b", value / 2)
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
    AttributeProxy.setStorageValue(self, key, value)
    local x, y = class.calculationPositionProxy(self)
    lstg.SetAttr(self, "x", x)
    lstg.SetAttr(self, "y", y)
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
