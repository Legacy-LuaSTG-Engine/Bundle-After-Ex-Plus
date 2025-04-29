local ffi = require("ffi")
local math = math
local type = type
local tostring = tostring
local string = string

local Vector2 = require("foundation.math.Vector2")
local Segment = require("foundation.shape.Segment")

ffi.cdef [[
typedef struct {
    foundation_math_Vector2 center;
    double radius;
} foundation_shape_Circle;
]]

---@class foundation.shape.Circle
---@field center foundation.math.Vector2 圆心位置
---@field radius number 圆的半径
local Circle = {}
Circle.__index = Circle
Circle.__type = "foundation.shape.Circle"

---创建一个新的圆
---@param center foundation.math.Vector2 圆心位置
---@param radius number 半径
---@return foundation.shape.Circle
function Circle.create(center, radius)
    ---@diagnostic disable-next-line: return-type-mismatch
    return ffi.new("foundation_shape_Circle", center, radius)
end

---圆相等比较
---@param a foundation.shape.Circle
---@param b foundation.shape.Circle
---@return boolean
function Circle.__eq(a, b)
    return a.center == b.center and math.abs(a.radius - b.radius) < 1e-10
end

---圆的字符串表示
---@param self foundation.shape.Circle
---@return string
function Circle.__tostring(self)
    return string.format("Circle(center=%s, radius=%f)", tostring(self.center), self.radius)
end

---检查点是否在圆内或圆上
---@param point foundation.math.Vector2
---@return boolean
function Circle:contains(point)
    return (point - self.center):length() <= self.radius
end

---移动圆（修改当前圆）
---@param v foundation.math.Vector2 | number
---@return foundation.shape.Circle 自身引用
function Circle:move(v)
    local moveX, moveY
    if type(v) == "number" then
        moveX, moveY = v, v
    else
        moveX, moveY = v.x, v.y
    end
    self.center.x = self.center.x + moveX
    self.center.y = self.center.y + moveY
    return self
end

---获取移动后的圆副本
---@param v foundation.math.Vector2 | number
---@return foundation.shape.Circle
function Circle:moved(v)
    local moveX, moveY
    if type(v) == "number" then
        moveX, moveY = v, v
    else
        moveX, moveY = v.x, v.y
    end
    return Circle.create(Vector2.create(self.center.x + moveX, self.center.y + moveY), self.radius)
end

---缩放圆（修改当前圆）
---@param scale number 缩放比例
---@return foundation.shape.Circle 自身引用
function Circle:scale(scale)
    self.radius = self.radius * scale
    return self
end

---获取缩放后的圆副本
---@param scale number 缩放比例
---@return foundation.shape.Circle
function Circle:scaled(scale)
    return Circle.create(self.center, self.radius * scale)
end

---检查与其他形状的相交
---@param other any
---@return boolean, foundation.math.Vector2|nil
function Circle:intersects(other)
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

---检查与线段的相交
---@param other foundation.shape.Segment
---@return boolean, foundation.math.Vector2|nil
function Circle:__intersectToSegment(other)
    local closest = other:closestPoint(self.center)
    if (closest - self.center):length() <= self.radius then
        return true, closest
    end
    return false, nil
end

---检查与三角形的相交
---@param other foundation.shape.Triangle
---@return boolean, foundation.math.Vector2|nil
function Circle:__intersectToTriangle(other)
    local edges = {
        Segment.create(other.point1, other.point2),
        Segment.create(other.point2, other.point3),
        Segment.create(other.point3, other.point1)
    }
    for i = 1, #edges do
        local isIntersect, intersectPoint = self:__intersectToSegment(edges[i])
        if isIntersect then
            return true, intersectPoint
        end
    end
    if other:contains(self.center) then
        return true, self.center:clone()
    end
    if self:contains(other.point1) then
        return true, other.point1:clone()
    end
    if self:contains(other.point2) then
        return true, other.point2:clone()
    end
    if self:contains(other.point3) then
        return true, other.point3:clone()
    end
    return false, nil
end

---检查与直线的相交
---@param other foundation.shape.Line
---@return boolean, foundation.math.Vector2|nil
function Circle:__intersectToLine(other)
    local dir = other.direction
    local len = dir:length()
    if len == 0 then
        return false, nil
    end
    dir = dir / len
    local L = other.point - self.center
    local a = dir:dot(dir)
    local b = 2 * L:dot(dir)
    local c = L:dot(L) - self.radius * self.radius
    local discriminant = b * b - 4 * a * c
    if discriminant < 0 then
        return false, nil
    end
    local t = (-b - math.sqrt(discriminant)) / (2 * a)
    local p1 = other.point + dir * t
    return true, p1
end

---检查与射线的相交
---@param other foundation.shape.Ray
---@return boolean, foundation.math.Vector2|nil
function Circle:__intersectToRay(other)
    local dir = other.direction
    local len = dir:length()
    if len == 0 then
        return false, nil
    end
    dir = dir / len
    local L = other.point - self.center
    local a = dir:dot(dir)
    local b = 2 * L:dot(dir)
    local c = L:dot(L) - self.radius * self.radius
    local discriminant = b * b - 4 * a * c
    if discriminant < 0 then
        return false, nil
    end
    local t = (-b - math.sqrt(discriminant)) / (2 * a)
    if t >= 0 then
        local p1 = other.point + dir * t
        return true, p1
    end
    local t2 = (-b + math.sqrt(discriminant)) / (2 * a)
    if t2 >= 0 then
        local p2 = other.point + dir * t2
        return true, p2
    end
    return false, nil
end

---检查与另一个圆的相交
---@param other foundation.shape.Circle
---@return boolean, foundation.math.Vector2|nil
function Circle:__intersectToCircle(other)
    local d = (self.center - other.center):length()
    if d <= self.radius + other.radius and d >= math.abs(self.radius - other.radius) then
        local dir = (other.center - self.center):normalized()
        local point = self.center + dir * self.radius
        return true, point
    end
    return false, nil
end

ffi.metatype("foundation_shape_Circle", Circle)

return Circle