local ffi = require("ffi")

local math = math
local tostring = tostring
local string = string

local Vector2 = require("foundation.math.Vector2")

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
    local dist = direction and direction:length() or 0
    if dist == 0 then
        direction = Vector2.create(1, 0)
    elseif dist ~= 1 then
        ---@diagnostic disable-next-line: need-check-nil
        direction = direction:normalized()
    else
        ---@diagnostic disable-next-line: need-check-nil
        direction = direction:clone()
    end
    ---@diagnostic disable-next-line: return-type-mismatch, missing-return-value
    return ffi.new("foundation_shape_Line", point, direction)
end

---根据两个点创建一条直线
---@param p1 foundation.math.Vector2 第一个点
---@param p2 foundation.math.Vector2 第二个点
---@return foundation.shape.Line
function Line.createFromPoints(p1, p2)
    local direction = p2 - p1
    return Line.create(p1, direction)
end

---根据一个点、弧度创建一条直线
---@param point foundation.math.Vector2 起始点
---@param rad number 弧度
---@return foundation.shape.Line
function Line.createFromPointAndRad(point, rad)
    local direction = Vector2.createFromRad(rad)
    return Line.create(point, direction)
end

---根据一个点、角度创建一条直线
---@param point foundation.math.Vector2 起始点
---@param angle number 角度
---@return foundation.shape.Line
function Line.createFromPointAndAngle(point, angle)
    local direction = Vector2.createFromAngle(angle)
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
---@return boolean, foundation.math.Vector2[] | nil
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
    elseif other.__type == "foundation.shape.Rectangle" then
        return self:__intersectToRectangle(other)
    elseif other.__type == "foundation.shape.Sector" then
        return self:__intersectToSector(other)
    end
    return false, nil
end

---检查是否与其他形状相交，只返回是否相交的布尔值
---@param other any
---@return boolean
function Line:hasIntersection(other)
    if other.__type == "foundation.shape.Segment" then
        return self:__hasIntersectionWithSegment(other)
    elseif other.__type == "foundation.shape.Triangle" then
        return self:__hasIntersectionWithTriangle(other)
    elseif other.__type == "foundation.shape.Line" then
        return self:__hasIntersectionWithLine(other)
    elseif other.__type == "foundation.shape.Ray" then
        return self:__hasIntersectionWithRay(other)
    elseif other.__type == "foundation.shape.Circle" then
        return self:__hasIntersectionWithCircle(other)
    elseif other.__type == "foundation.shape.Rectangle" then
        return self:__hasIntersectionWithRectangle(other)
    elseif other.__type == "foundation.shape.Sector" then
        return self:__hasIntersectionWithSector(other)
    end
    return false
end

---检查与线段的相交
---@param other foundation.shape.Segment
---@return boolean, foundation.math.Vector2[] | nil
function Line:__intersectToSegment(other)
    local points = {}
    local a = self.point
    local b = self.point + self.direction
    local c = other.point1
    local d = other.point2

    local denom = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
    if math.abs(denom) < 1e-10 then
        return false, points
    end

    local t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denom
    local u = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denom

    if u >= 0 and u <= 1 then
        local x = a.x + t * (b.x - a.x)
        local y = a.y + t * (b.y - a.y)
        points[#points + 1] = Vector2.create(x, y)
    end

    if #points == 0 then
        return false, nil
    end
    return true, points
end

---检查是否与线段相交
---@param other foundation.shape.Segment
---@return boolean
function Line:__hasIntersectionWithSegment(other)
    local a = self.point
    local b = self.point + self.direction
    local c = other.point1
    local d = other.point2

    local denom = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
    if math.abs(denom) < 1e-10 then
        return false
    end

    --local t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denom
    local u = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denom

    return u >= 0 and u <= 1
end

---检查与另一条直线的相交
---@param other foundation.shape.Line
---@return boolean, foundation.math.Vector2[] | nil
function Line:__intersectToLine(other)
    local points = {}
    local a = self.point
    local b = self.point + self.direction
    local c = other.point
    local d = other.point + other.direction

    local dir_cross = self.direction:cross(other.direction)
    if math.abs(dir_cross) < 1e-10 then
        local point_diff = other.point - self.point
        if math.abs(point_diff:cross(self.direction)) < 1e-10 then
            points[#points + 1] = self.point:clone()
            points[#points + 1] = self:getPoint(1)
            return true, points
        else
            return false, nil
        end
    end

    local denom = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
    local t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denom
    local x = a.x + t * (b.x - a.x)
    local y = a.y + t * (b.y - a.y)
    points[#points + 1] = Vector2.create(x, y)

    return true, points
end

---检查是否与另一条直线相交
---@param other foundation.shape.Line
---@return boolean
function Line:__hasIntersectionWithLine(other)
    local dir_cross = self.direction:cross(other.direction)
    if math.abs(dir_cross) < 1e-10 then
        local point_diff = other.point - self.point
        return math.abs(point_diff:cross(self.direction)) < 1e-10
    end
    return true
end

---检查与射线的相交
---@param other foundation.shape.Ray
---@return boolean, foundation.math.Vector2[] | nil
function Line:__intersectToRay(other)
    local points = {}
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
        points[#points + 1] = Vector2.create(x, y)
    end

    if #points == 0 then
        return false, nil
    end
    return true, points
end

---检查是否与射线相交
---@param other foundation.shape.Ray
---@return boolean
function Line:__hasIntersectionWithRay(other)
    local a = self.point
    local b = self.point + self.direction
    local c = other.point
    local d = other.point + other.direction

    local denom = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
    if math.abs(denom) < 1e-10 then
        return false
    end

    local u = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denom

    return u >= 0
end

---检查与三角形的相交
---@param other foundation.shape.Triangle
---@return boolean, foundation.math.Vector2[] | nil
function Line:__intersectToTriangle(other)
    return other:__intersectToLine(self)
end

---检查是否与三角形相交
---@param other foundation.shape.Triangle
---@return boolean
function Line:__hasIntersectionWithTriangle(other)
    return other:__hasIntersectionWithLine(self)
end

---检查与圆的相交
---@param other foundation.shape.Circle
---@return boolean, foundation.math.Vector2[] | nil
function Line:__intersectToCircle(other)
    return other:__intersectToLine(self)
end

---检查是否与圆相交
---@param other foundation.shape.Circle
---@return boolean
function Line:__hasIntersectionWithCircle(other)
    return other:__hasIntersectionWithLine(self)
end

---检查与矩形的相交
---@param other foundation.shape.Rectangle
---@return boolean, foundation.math.Vector2[] | nil
function Line:__intersectToRectangle(other)
    return other:__intersectToLine(self)
end

---仅检查是否与矩形相交
---@param other foundation.shape.Rectangle
---@return boolean
function Line:__hasIntersectionWithRectangle(other)
    return other:__hasIntersectionWithLine(self)
end

---检查与扇形的相交
---@param other foundation.shape.Sector
---@return boolean, foundation.math.Vector2[] | nil
function Line:__intersectToSector(other)
    return other:__intersectToLine(self)
end

---仅检查是否与扇形相交
---@param other foundation.shape.Sector
---@return boolean
function Line:__hasIntersectionWithSector(other)
    return other:__hasIntersectionWithLine(self)
end

---计算点到直线的距离
---@param point foundation.math.Vector2 点
---@return number 距离
function Line:distanceToPoint(point)
    local point_vec = point - self.point
    local proj_length = point_vec:dot(self.direction)
    local proj_point = self.point + self.direction * proj_length
    return (point - proj_point):length()
end

---检查点是否在直线上
---@param point foundation.math.Vector2 点
---@param tolerance number 误差容忍度，默认为1e-10
---@return boolean
function Line:containsPoint(point, tolerance)
    tolerance = tolerance or 1e-10
    local point_vec = point - self.point
    local cross = point_vec:cross(self.direction)
    return math.abs(cross) < tolerance
end

---获取点在直线上的投影
---@param point foundation.math.Vector2 点
---@return foundation.math.Vector2 投影点
function Line:projectPoint(point)
    local point_vec = point - self.point
    local proj_length = point_vec:dot(self.direction)
    return self.point + self.direction * proj_length
end

ffi.metatype("foundation_shape_Line", Line)

return Line
