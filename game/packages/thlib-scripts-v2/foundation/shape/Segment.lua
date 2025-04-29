local ffi = require("ffi")

local type = type
local ipairs = ipairs
local tostring = tostring
local string = string
local math = math

local Vector2 = require("foundation.math.Vector2")

ffi.cdef [[
typedef struct {
    foundation_math_Vector2 point1, point2;
} foundation_shape_Segment;
]]

---@class foundation.shape.Segment
---@field point1 foundation.math.Vector2
---@field point2 foundation.math.Vector2
local Segment = {}
Segment.__index = Segment
Segment.__type = "foundation.shape.Segment"

---创建一个线段
---@param point1 foundation.math.Vector2 线段的起点
---@param point2 foundation.math.Vector2 线段的终点
---@return foundation.shape.Segment
function Segment.create(point1, point2)
    ---@diagnostic disable-next-line: return-type-mismatch
    return ffi.new("foundation_shape_Segment", point1, point2)
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
    return a.point1 == b.point1 and a.point2 == b.point2
end

---线段转字符串表示
---@param self foundation.shape.Segment
---@return string 线段的字符串表示
function Segment.__tostring(self)
    return string.format("Line(%s, %s)", tostring(self.point1), tostring(self.point2))
end

---将线段转换为向量
---@return foundation.math.Vector2 从起点到终点的向量
function Segment:toVector2()
    return self.point2 - self.point1
end

---获取线段的法向量
---@return foundation.math.Vector2 线段的单位法向量
function Segment:normal()
    local dir = self.point2 - self.point1
    local len = dir:length()
    if len == 0 then
        return Vector2.zero()
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
    return Vector2.create((self.point1.x + self.point2.x) / 2, (self.point1.y + self.point2.y) / 2)
end

---获取线段的角度（弧度）
---@return number 线段的角度，单位为弧度
function Segment:angle()
    return math.atan2(self.point2.y - self.point1.y, self.point2.x - self.point1.x)
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
    self.point1.x = self.point1.x + moveX
    self.point1.y = self.point1.y + moveY
    self.point2.x = self.point2.x + moveX
    self.point2.y = self.point2.y + moveY
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
            Vector2.create(self.point1.x + moveX, self.point1.y + moveY),
            Vector2.create(self.point2.x + moveX, self.point2.y + moveY)
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
    local v1 = self.point1 - center
    local v2 = self.point2 - center
    self.point1.x = v1.x * cosRad - v1.y * sinRad + center.x
    self.point1.y = v1.x * sinRad + v1.y * cosRad + center.y
    self.point2.x = v2.x * cosRad - v2.y * sinRad + center.x
    self.point2.y = v2.x * sinRad + v2.y * cosRad + center.y
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
    local v1 = self.point1 - center
    local v2 = self.point2 - center
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
    self.point1.x = (self.point1.x - center.x) * scaleX + center.x
    self.point1.y = (self.point1.y - center.y) * scaleY + center.y
    self.point2.x = (self.point2.x - center.x) * scaleX + center.x
    self.point2.y = (self.point2.y - center.y) * scaleY + center.y
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
            Vector2.create((self.point1.x - center.x) * scaleX + center.x, (self.point1.y - center.y) * scaleY + center.y),
            Vector2.create((self.point2.x - center.x) * scaleX + center.x, (self.point2.y - center.y) * scaleY + center.y)
    )
end

---检查线段是否与其他形状相交
---@param other any 其他的形状
---@return boolean, foundation.math.Vector2[] | nil
function Segment:intersects(other)
    if other.__type == "foundation.shape.Segment" then
        return self:__intersectToSegment(other)
    elseif other.__type == "foundation.shape.Triangle" then
        return self:__intersectToTriangle(other)
    elseif other.__type == "foundation.shape.Line" then
        return self:__intersectToLine(other)
    elseif other.__type == "foundation.shape.Ray" then
        return self:__intersectToRay(other)
    elseif other.__type == "foundation.shape.Circle" then
        return self:__intersectToCircle(other)
    end
    return false, nil
end

---检查线段是否与另一个线段相交
---@param other foundation.shape.Segment 要检查的线段
---@return boolean, foundation.math.Vector2[] | nil
function Segment:__intersectToSegment(other)
    local points = {}
    local a = self.point1
    local b = self.point2
    local c = other.point1
    local d = other.point2

    local denom = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
    if math.abs(denom) < 1e-10 then
        local dir = self.point2 - self.point1
        local len = dir:length()
        if len == 0 then
            if other:isPointOnLine(self.point1) then
                points[#points + 1] = self.point1:clone()
            end

            if #points == 0 then
                return false, nil
            end
            return true, points
        end
        dir = dir / len
        local t1 = ((c.x - a.x) * dir.x + (c.y - a.y) * dir.y) / len
        local t2 = ((d.x - a.x) * dir.x + (d.y - a.y) * dir.y) / len
        if t1 > 1 or t2 < 0 or (t1 < 0 and t2 < 0) or (t1 > 1 and t2 > 1) then
            return false, nil
        end
        local start_t = math.max(0, math.min(t1, t2))
        local end_t = math.min(1, math.max(t1, t2))
        if start_t <= end_t then
            points[#points + 1] = self.point1 + dir * start_t * len
            if math.abs(end_t - start_t) > 1e-10 then
                points[#points + 1] = self.point1 + dir * end_t * len
            end
        end

        if #points == 0 then
            return false, nil
        end
        return true, points
    end

    local t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denom
    local u = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denom

    if t >= 0 and t <= 1 and u >= 0 and u <= 1 then
        local x = a.x + t * (b.x - a.x)
        local y = a.y + t * (b.y - a.y)
        points[#points + 1] = Vector2.create(x, y)
    end

    if #points == 0 then
        return false, nil
    end
    return true, points
end

---检查线段是否与三角形相交
---@param other foundation.shape.Triangle 要检查的三角形
---@return boolean, foundation.math.Vector2[] | nil
function Segment:__intersectToTriangle(other)
    local points = {}
    local edges = {
        Segment.create(other.point1, other.point2),
        Segment.create(other.point2, other.point3),
        Segment.create(other.point3, other.point1)
    }
    for i = 1, #edges do
        local success, edge_points = self:__intersectToSegment(edges[i])
        if success then
            for _, p in ipairs(edge_points) do
                points[#points + 1] = p
            end
        end
    end
    if other:contains(self.point1) then
        points[#points + 1] = self.point1:clone()
    end
    if self.point1 ~= self.point2 and other:contains(self.point2) then
        points[#points + 1] = self.point2:clone()
    end
    local unique_points = {}
    local seen = {}
    for _, p in ipairs(points) do
        local key = tostring(p.x) .. "," .. tostring(p.y)
        if not seen[key] then
            seen[key] = true
            unique_points[#unique_points + 1] = p
        end
    end

    if #unique_points == 0 then
        return false, nil
    end
    return true, unique_points
end

---检查线段是否与直线相交
---@param other foundation.shape.Line 要检查的直线
---@return boolean, foundation.math.Vector2[] | nil
function Segment:__intersectToLine(other)
    local points = {}
    local a = self.point1
    local b = self.point2
    local c = other.point
    local d = other.point + other.direction

    local denom = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
    if math.abs(denom) < 1e-10 then
        return false, nil
    end

    local t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denom
    if t >= 0 and t <= 1 then
        local x = a.x + t * (b.x - a.x)
        local y = a.y + t * (b.y - a.y)
        points[#points + 1] = Vector2.create(x, y)
    end

    if #points == 0 then
        return false, nil
    end
    return true, points
end

---检查线段是否与射线相交
---@param other foundation.shape.Ray 要检查的射线
---@return boolean, foundation.math.Vector2[] | nil
function Segment:__intersectToRay(other)
    local points = {}
    local a = self.point1
    local b = self.point2
    local c = other.point
    local d = other.point + other.direction

    local denom = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
    if math.abs(denom) < 1e-10 then
        return false, nil
    end

    local t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denom
    local u = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denom

    if t >= 0 and t <= 1 and u >= 0 then
        local x = a.x + t * (b.x - a.x)
        local y = a.y + t * (b.y - a.y)
        points[#points + 1] = Vector2.create(x, y)
    end

    if #points == 0 then
        return false, nil
    end
    return true, points
end

---检查线段是否与圆相交
---@param other foundation.shape.Circle 要检查的圆
---@return boolean, foundation.math.Vector2[] | nil
function Segment:__intersectToCircle(other)
    local points = {}
    local dir = self.point2 - self.point1
    local len = dir:length()
    if len == 0 then
        if (self.point1 - other.center):length() <= other.radius then
            points[#points + 1] = self.point1:clone()
        end

        if #points == 0 then
            return false, nil
        end
        return true, points
    end
    dir = dir / len
    local L = self.point1 - other.center
    local a = dir:dot(dir)
    local b = 2 * L:dot(dir)
    local c = L:dot(L) - other.radius * other.radius
    local discriminant = b * b - 4 * a * c
    if discriminant >= 0 then
        local sqrt_d = math.sqrt(discriminant)
        local t1 = (-b - sqrt_d) / (2 * a)
        local t2 = (-b + sqrt_d) / (2 * a)
        if t1 >= 0 and t1 <= len then
            points[#points + 1] = self.point1 + dir * t1
        end
        if t2 >= 0 and t2 <= len and math.abs(t2 - t1) > 1e-10 then
            points[#points + 1] = self.point1 + dir * t2
        end
    end

    if #points == 0 then
        return false, nil
    end
    return true, points
end

---计算点到线段的最近点
---@param point foundation.math.Vector2 要检查的点
---@return foundation.math.Vector2 线段上最近的点
function Segment:closestPoint(point)
    local dir = self.point2 - self.point1
    local len = dir:length()
    if len == 0 then
        return self.point1:clone()
    end

    local t = ((point.x - self.point1.x) * dir.x + (point.y - self.point1.y) * dir.y) / (len * len)
    t = math.max(0, math.min(1, t))

    return Vector2.create(self.point1.x + t * dir.x, self.point1.y + t * dir.y)
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
    local dir = self.point2 - self.point1
    local len = dir:length()
    if len == 0 then
        return self.point1:clone()
    end

    local t = ((point.x - self.point1.x) * dir.x + (point.y - self.point1.y) * dir.y) / (len * len)
    return Vector2.create(self.point1.x + t * dir.x, self.point1.y + t * dir.y)
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

    local dir = self.point2 - self.point1
    local len = dir:length()
    if len == 0 then
        return point.x == self.point1.x and point.y == self.point1.y
    end

    local t = ((point.x - self.point1.x) * dir.x + (point.y - self.point1.y) * dir.y) / (len * len)
    return t >= 0 and t <= 1
end

ffi.metatype("foundation_shape_Segment", Segment)

return Segment