local ffi = require("ffi")
local math = math
local tostring = tostring
local string = string

local Vector2 = require("foundation.math.Vector2")
local Segment = require("foundation.shape.Segment")

ffi.cdef [[
typedef struct {
    foundation_math_Vector2 point;
    foundation_math_Vector2 direction;
} foundation_shape_Line;
]]

---@class foundation.shape.Line
---@field point foundation.math.Vector2 直线上的一点
---@field direction foundation.math.Vector2 直线的方向向量
local Line = {}
Line.__index = Line
Line.__type = "foundation.shape.Line"

---创建一条新的直线，由一个点和方向向量确定
---@param point foundation.math.Vector2 直线上的点
---@param direction foundation.math.Vector2 方向向量
---@return foundation.shape.Line
function Line.create(point, direction)
    ---@diagnostic disable-next-line: return-type-mismatch
    return ffi.new("foundation_shape_Line", point, direction:normalized())
end

---根据两个点创建一条直线
---@param p1 foundation.math.Vector2 第一个点
---@param p2 foundation.math.Vector2 第二个点
---@return foundation.shape.Line
function Line.createFromPoints(p1, p2)
    local direction = p2 - p1
    return Line.create(p1, direction)
end

---根据一个点、角度创建一条直线
---@param point foundation.math.Vector2 起始点
---@param angle number 角度（度）
---@return foundation.shape.Line
function Line.createFromPointAndAngle(point, angle)
    local direction = Vector2.createFromAngle(angle, 1)
    return Line.create(point, direction)
end

---直线相等比较
---@param a foundation.shape.Line
---@param b foundation.shape.Line
---@return boolean
function Line.__eq(a, b)
    local dir_cross = a.direction:cross(b.direction)
    if math.abs(dir_cross) > 1e-10 then
        return false
    end
    local point_diff = b.point - a.point
    return math.abs(point_diff:cross(a.direction)) < 1e-10
end

---直线的字符串表示
---@param self foundation.shape.Line
---@return string
function Line.__tostring(self)
    return string.format("Line(%s, dir=%s)", tostring(self.point), tostring(self.direction))
end

---获取直线上相对 point 指定距离的点
---@param length number 距离
---@return foundation.math.Vector2
function Line:getPoint(length)
    return self.point + self.direction * length
end

---检查与其他形状的相交
---@param other any
---@return boolean, foundation.math.Vector2|nil
function Line:intersects(other)
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
function Line:__intersectToSegment(other)
    local a = self.point
    local b = self.point + self.direction
    local c = other.point1
    local d = other.point2

    local denom = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
    if math.abs(denom) < 1e-10 then
        return false, nil
    end

    local t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denom
    local u = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denom

    if u >= 0 and u <= 1 then
        local x = a.x + t * (b.x - a.x)
        local y = a.y + t * (b.y - a.y)
        return true, Vector2.create(x, y)
    end

    return false, nil
end

---检查与三角形的相交
---@param other foundation.shape.Triangle
---@return boolean, foundation.math.Vector2|nil
function Line:__intersectToTriangle(other)
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
    return false, nil
end

---检查与另一条直线的相交
---@param other foundation.shape.Line
---@return boolean, foundation.math.Vector2|nil
function Line:__intersectToLine(other)
    local a = self.point
    local b = self.point + self.direction
    local c = other.point
    local d = other.point + other.direction

    local denom = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
    if math.abs(denom) < 1e-10 then
        return false, nil
    end

    local t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denom
    local x = a.x + t * (b.x - a.x)
    local y = a.y + t * (b.y - a.y)
    return true, Vector2.create(x, y)
end

---检查与射线的相交
---@param other foundation.shape.Ray
---@return boolean, foundation.math.Vector2|nil
function Line:__intersectToRay(other)
    local a = self.point
    local b = self.point + self.direction
    local c = other.point
    local d = other.point + other.direction

    local denom = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
    if math.abs(denom) < 1e-10 then
        return false, nil
    end

    local t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denom
    local u = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denom

    if u >= 0 then
        local x = a.x + t * (b.x - a.x)
        local y = a.y + t * (b.y - a.y)
        return true, Vector2.create(x, y)
    end

    return false, nil
end

---检查与圆的相交
---@param other foundation.shape.Circle
---@return boolean, foundation.math.Vector2|nil
function Line:__intersectToCircle(other)
    local dir = self.direction
    local len = dir:length()
    if len == 0 then
        return false, nil
    end
    dir = dir / len
    local L = self.point - other.center
    local a = dir:dot(dir)
    local b = 2 * L:dot(dir)
    local c = L:dot(L) - other.radius * other.radius
    local discriminant = b * b - 4 * a * c
    if discriminant < 0 then
        return false, nil
    end
    local t = (-b - math.sqrt(discriminant)) / (2 * a)
    local p1 = self.point + dir * t
    --[[ -- 因为只求一个交点，所以不用判断其他解
    if discriminant == 0 then
        return true, p1
    end
    local t2 = (-b + math.sqrt(discriminant)) / (2 * a)
    local p2 = self.point + dir * t2
    --]]
    return true, p1
end

ffi.metatype("foundation_shape_Line", Line)

return Line