local ffi = require("ffi")

local type = type
local tostring = tostring
local string = string
local math = math

local Vector2 = require("foundation.math.Vector2")

ffi.cdef [[
typedef struct {
    foundation_math_Vector2 v1, v2;
} foundation_shape_Segment;
]]

---@class foundation.shape.Segment
---@field v1 foundation.math.Vector2
---@field v2 foundation.math.Vector2
local Segment = {}
Segment.__index = Segment

---创建一个线段
---@param v1 foundation.math.Vector2 线段的起点
---@param v2 foundation.math.Vector2 线段的终点
---@return foundation.shape.Segment
function Segment.create(v1, v2)
    ---@diagnostic disable-next-line: return-type-mismatch
    return ffi.new("foundation_shape_Segment", v1, v2)
end

---根据给定点和弧度与长度创建线段
---@param point foundation.math.Vector2 线段的起点
---@param rad number 线段的弧度
---@param length number 线段的长度
---@return foundation.shape.Segment
function Segment.createFromPointAndRad(point, rad, length)
    local v2 = Vector2.create(point.x + math.cos(rad) * length, point.y + math.sin(rad) * length)
    return Segment.create(point, v2)
end

---根据给定点和角度与长度创建线段
---@param point foundation.math.Vector2 线段的起点
---@param angle number 线段的角度
---@param length number 线段的长度
---@return foundation.shape.Segment
function Segment.createFromPointAndAngle(point, angle, length)
    local rad = math.rad(angle)
    return Segment.createFromPointAndRad(point, rad, length)
end

---线段相等比较
---@param a foundation.shape.Segment 第一个线段
---@param b foundation.shape.Segment 第二个线段
---@return boolean 如果两个线段的所有顶点都相等则返回true，否则返回false
function Segment.__eq(a, b)
    return a.v1 == b.v1 and a.v2 == b.v2
end

---线段转字符串表示
---@param self foundation.shape.Segment
---@return string 线段的字符串表示
function Segment.__tostring(self)
    return string.format("Line(%s, %s)", tostring(self.v1), tostring(self.v2))
end

---将线段转换为向量
---@return foundation.math.Vector2 从起点到终点的向量
function Segment:toVector2()
    return self.v2 - self.v1
end

---获取线段的法向量
---@return foundation.math.Vector2 线段的单位法向量
function Segment:normal()
    local dir = self.v2 - self.v1
    local len = dir:length()
    if len == 0 then
        return Vector2.create(0, 0)
    end
    return Vector2.create(-dir.y / len, dir.x / len)
end

---获取线段的长度
---@return number 线段的长度
function Segment:length()
    return self:toVector2():length()
end

---获取线段的中点
---@return foundation.math.Vector2 线段的中点
function Segment:midpoint()
    return Vector2.create((self.v1.x + self.v2.x) / 2, (self.v1.y + self.v2.y) / 2)
end

---获取线段的角度（弧度）
---@return number 线段的角度，单位为弧度
function Segment:angle()
    return math.atan2(self.v2.y - self.v1.y, self.v2.x - self.v1.x)
end

---获取线段的角度（度）
---@return number 线段的角度，单位为度
function Segment:degreeAngle()
    return math.deg(self:angle())
end

---平移线段（更改当前线段）
---@param v foundation.math.Vector2 | number 移动距离
---@return foundation.shape.Segment 平移后的线段（自身引用）
function Segment:move(v)
    local moveX, moveY
    if type(v) == "number" then
        moveX, moveY = v, v
    else
        moveX, moveY = v.x, v.y
    end
    self.v1.x = self.v1.x + moveX
    self.v1.y = self.v1.y + moveY
    self.v2.x = self.v2.x + moveX
    self.v2.y = self.v2.y + moveY
    return self
end

---获取当前线段平移指定距离的副本
---@param v foundation.math.Vector2 | number 移动距离
---@return foundation.shape.Segment 移动后的线段副本
function Segment:moved(v)
    local moveX, moveY
    if type(v) == "number" then
        moveX, moveY = v, v
    else
        moveX, moveY = v.x, v.y
    end
    return Segment.create(
            Vector2.create(self.v1.x + moveX, self.v1.y + moveY),
            Vector2.create(self.v2.x + moveX, self.v2.y + moveY)
    )
end

---将当前线段旋转指定弧度（更改当前线段）
---@param rad number 旋转弧度
---@param center foundation.math.Vector2 旋转中心
---@return foundation.shape.Segment 旋转后的线段（自身引用）
---@overload fun(self:foundation.shape.Segment, rad:number): foundation.shape.Segment 将线段绕中点旋转指定弧度
function Segment:rotate(rad, center)
    center = center or self:midpoint()
    local cosRad = math.cos(rad)
    local sinRad = math.sin(rad)
    local v1 = self.v1 - center
    local v2 = self.v2 - center
    self.v1.x = v1.x * cosRad - v1.y * sinRad + center.x
    self.v1.y = v1.x * sinRad + v1.y * cosRad + center.y
    self.v2.x = v2.x * cosRad - v2.y * sinRad + center.x
    self.v2.y = v2.x * sinRad + v2.y * cosRad + center.y
    return self
end

---将当前线段旋转指定角度（更改当前线段）
---@param angle number 旋转角度
---@param center foundation.math.Vector2 旋转中心
---@return foundation.shape.Segment 旋转后的线段（自身引用）
---@overload fun(self:foundation.shape.Segment, angle:number): foundation.shape.Segment 将线段绕中点旋转指定角度
function Segment:degreeRotate(angle, center)
    angle = math.rad(angle)
    return self:rotate(angle, center)
end

---获取当前线段旋转指定弧度的副本
---@param rad number 旋转弧度
---@param center foundation.math.Vector2 旋转中心
---@return foundation.shape.Segment 旋转后的线段副本
---@overload fun(self:foundation.shape.Segment, rad:number): foundation.shape.Segment 将线段绕中点旋转指定弧度
function Segment:rotated(rad, center)
    center = center or self:midpoint()
    local cosRad = math.cos(rad)
    local sinRad = math.sin(rad)
    local v1 = self.v1 - center
    local v2 = self.v2 - center
    return Segment.create(
            Vector2.create(v1.x * cosRad - v1.y * sinRad + center.x, v1.x * sinRad + v1.y * cosRad + center.y),
            Vector2.create(v2.x * cosRad - v2.y * sinRad + center.x, v2.x * sinRad + v2.y * cosRad + center.y)
    )
end

---获取当前线段旋转指定角度的副本
---@param angle number 旋转角度
---@param center foundation.math.Vector2 旋转中心
---@return foundation.shape.Segment 旋转后的线段副本
---@overload fun(self:foundation.shape.Segment, angle:number): foundation.shape.Segment 将线段绕中点旋转指定角度
function Segment:degreeRotated(angle, center)
    angle = math.rad(angle)
    return self:rotated(angle, center)
end

---将当前线段缩放指定倍数（更改当前线段）
---@param scale number|foundation.math.Vector2 缩放倍数
---@param center foundation.math.Vector2 缩放中心
---@return foundation.shape.Segment 缩放后的线段（自身引用）
---@overload fun(self: foundation.shape.Segment, scale: number): foundation.shape.Segment 相对线段中点缩放指定倍数
function Segment:scale(scale, center)
    local scaleX, scaleY
    if type(scale) == "number" then
        scaleX, scaleY = scale, scale
    else
        scaleX, scaleY = scale.x, scale.y
    end
    center = center or self:midpoint()
    self.v1.x = (self.v1.x - center.x) * scaleX + center.x
    self.v1.y = (self.v1.y - center.y) * scaleY + center.y
    self.v2.x = (self.v2.x - center.x) * scaleX + center.x
    self.v2.y = (self.v2.y - center.y) * scaleY + center.y
    return self
end

---获取线段的缩放指定倍数的副本
---@param scale number|foundation.math.Vector2 缩放倍数
---@param center foundation.math.Vector2 缩放中心
---@return foundation.shape.Segment 缩放后的线段副本
---@overload fun(self: foundation.shape.Segment, scale: number): foundation.shape.Segment 相对线段中点缩放指定倍数
function Segment:scaled(scale, center)
    local scaleX, scaleY
    if type(scale) == "number" then
        scaleX, scaleY = scale, scale
    else
        scaleX, scaleY = scale.x, scale.y
    end
    center = center or self:midpoint()
    return Segment.create(
            Vector2.create((self.v1.x - center.x) * scaleX + center.x, (self.v1.y - center.y) * scaleY + center.y),
            Vector2.create((self.v2.x - center.x) * scaleX + center.x, (self.v2.y - center.y) * scaleY + center.y)
    )
end

---检查线段是否与其他形状相交
---@param other any 其他的形状
---@return boolean, foundation.math.Vector2|nil
function Segment:intersects(other)
    if ffi.istype("foundation_shape_Segment", other) then
        return self:__intersectToSegment(other)
    elseif ffi.istype("foundation_shape_Triangle", other) then
        return self:__intersectToTriangle(other)
    end
    return false, nil
end

---检查线段是否与另一个线段相交
---@param other foundation.shape.Segment 要检查的线段
---@return boolean, foundation.math.Vector2|nil
function Segment:__intersectToSegment(other)
    local a = self.v1
    local b = self.v2
    local c = other.v1
    local d = other.v2

    local denom = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
    if math.abs(denom) < 1e-10 then
        return false, nil
    end

    local t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denom
    local u = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denom

    if t >= 0 and t <= 1 and u >= 0 and u <= 1 then
        local x = a.x + t * (b.x - a.x)
        local y = a.y + t * (b.y - a.y)
        return true, Vector2.create(x, y)
    end

    return false, nil
end

---检查线段是否与三角形相交
---@param other foundation.shape.Triangle 要检查的三角形
---@return boolean, foundation.math.Vector2|nil
function Segment:__intersectToTriangle(other)
    local edges = {
        Segment.create(other.v1, other.v2),
        Segment.create(other.v2, other.v3),
        Segment.create(other.v3, other.v1)
    }
    for i = 1, #edges do
        local edge = edges[i]
        local isIntersect, intersectPoint = self:intersects(edge)
        if isIntersect then
            return true, intersectPoint
        end
    end

    if other:contains(self.v1) then
        return true, Vector2.create(self.v1.x, self.v1.y)
    end
    if other:contains(self.v2) then
        return true, Vector2.create(self.v2.x, self.v2.y)
    end

    return false, nil
end

---计算点到线段的最近点
---@param point foundation.math.Vector2 要检查的点
---@return foundation.math.Vector2 线段上最近的点
function Segment:closestPoint(point)
    local dir = self.v2 - self.v1
    local len = dir:length()
    if len == 0 then
        return Vector2.create(self.v1.x, self.v1.y)
    end

    local t = ((point.x - self.v1.x) * dir.x + (point.y - self.v1.y) * dir.y) / (len * len)
    t = math.max(0, math.min(1, t))

    return Vector2.create(self.v1.x + t * dir.x, self.v1.y + t * dir.y)
end

---计算点到线段的距离
---@param point foundation.math.Vector2 要检查的点
---@return number 点到线段的距离
function Segment:distanceToPoint(point)
    local closest = self:closestPoint(point)
    return (point - closest):length()
end

---将点投影到线段所在的直线上
---@param point foundation.math.Vector2 要投影的点
---@return foundation.math.Vector2 投影点
function Segment:projectPoint(point)
    local dir = self.v2 - self.v1
    local len = dir:length()
    if len == 0 then
        return Vector2.create(self.v1.x, self.v1.y)
    end

    local t = ((point.x - self.v1.x) * dir.x + (point.y - self.v1.y) * dir.y) / (len * len)
    return Vector2.create(self.v1.x + t * dir.x, self.v1.y + t * dir.y)
end

---检查点是否在线段上
---@param point foundation.math.Vector2 要检查的点
---@param tolerance number|nil 容差，默认为1e-10
---@return boolean 点是否在线段上
---@overload fun(self:foundation.shape.Segment, point:foundation.math.Vector2): boolean
function Segment:isPointOnLine(point, tolerance)
    tolerance = tolerance or 1e-10
    local dist = self:distanceToPoint(point)
    if dist > tolerance then
        return false
    end

    local dir = self.v2 - self.v1
    local len = dir:length()
    if len == 0 then
        return point.x == self.v1.x and point.y == self.v1.y
    end

    local t = ((point.x - self.v1.x) * dir.x + (point.y - self.v1.y) * dir.y) / (len * len)
    return t >= 0 and t <= 1
end

ffi.metatype("foundation_shape_Segment", Segment)

return Segment