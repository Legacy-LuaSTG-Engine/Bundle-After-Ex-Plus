local ffi = require("ffi")

local math = math
local ipairs = ipairs
local tostring = tostring
local string = string

local Vector2 = require("foundation.math.Vector2")
local Segment = require("foundation.shape.Segment")

ffi.cdef [[
typedef struct {
    foundation_math_Vector2 point;
    foundation_math_Vector2 direction;
} foundation_shape_Ray;
]]

---@class foundation.shape.Ray
---@field point foundation.math.Vector2 射线的起始点
---@field direction foundation.math.Vector2 射线的方向向量
local Ray = {}
Ray.__index = Ray
Ray.__type = "foundation.shape.Ray"

---创建一条新的射线，由起始点和方向向量确定
---@param point foundation.math.Vector2 起始点
---@param direction foundation.math.Vector2 方向向量
---@return foundation.shape.Ray
function Ray.create(point, direction)
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
    return ffi.new("foundation_shape_Ray", point, direction)
end

---根据起始点、弧度创建射线
---@param point foundation.math.Vector2 起始点
---@param radian number 弧度
---@return foundation.shape.Ray
function Ray.createFromRad(point, radian)
    local direction = Vector2.createFromRad(radian)
    return Ray.create(point, direction)
end

---根据起始点、角度创建射线
---@param point foundation.math.Vector2 起始点
---@param angle number 角度
---@return foundation.shape.Ray
function Ray.createFromAngle(point, angle)
    local direction = Vector2.createFromAngle(angle)
    return Ray.create(point, direction)
end

---射线相等比较
---@param a foundation.shape.Ray
---@param b foundation.shape.Ray
---@return boolean
function Ray.__eq(a, b)
    return a.point == b.point and a.direction == b.direction
end

---射线的字符串表示
---@param self foundation.shape.Ray
---@return string
function Ray.__tostring(self)
    return string.format("Ray(point=%s, direction=%s)", tostring(self.point), tostring(self.direction))
end

---获取射线上相对起始点指定距离的点
---@param length number 距离
---@return foundation.math.Vector2
function Ray:getPoint(length)
    return self.point + self.direction * length
end

---检查与其他形状的相交
---@param other any
---@return boolean, foundation.math.Vector2[] | nil
function Ray:intersects(other)
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
function Ray:hasIntersection(other)
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
function Ray:__intersectToSegment(other)
    local points = {}
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

    if t >= 0 and u >= 0 and u <= 1 then
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
function Ray:__hasIntersectionWithSegment(other)
    local a = self.point
    local b = self.point + self.direction
    local c = other.point1
    local d = other.point2

    local denom = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
    if math.abs(denom) < 1e-10 then
        return false
    end

    local t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denom
    local u = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denom

    return t >= 0 and u >= 0 and u <= 1
end

---检查与直线的相交
---@param other foundation.shape.Line
---@return boolean, foundation.math.Vector2[] | nil
function Ray:__intersectToLine(other)
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
    --local u = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denom

    if t >= 0 then
        local x = a.x + t * (b.x - a.x)
        local y = a.y + t * (b.y - a.y)
        points[#points + 1] = Vector2.create(x, y)
    end

    if #points == 0 then
        return false, nil
    end
    return true, points
end

---检查是否与直线相交
---@param other foundation.shape.Line
---@return boolean
function Ray:__hasIntersectionWithLine(other)
    local a = self.point
    local b = self.point + self.direction
    local c = other.point
    local d = other.point + other.direction

    local denom = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
    if math.abs(denom) < 1e-10 then
        return false
    end

    local t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denom
    return t >= 0
end

---检查与另一条射线的相交
---@param other foundation.shape.Ray
---@return boolean, foundation.math.Vector2[] | nil
function Ray:__intersectToRay(other)
    local points = {}
    local a = self.point
    local b = self.point + self.direction
    local c = other.point
    local d = other.point + other.direction

    local denom = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
    if math.abs(denom) < 1e-10 then
        local dir_cross = self.direction:cross(other.direction)
        if math.abs(dir_cross) < 1e-10 then
            local point_diff = other.point - self.point
            local t = point_diff:dot(self.direction)
            if t >= 0 then
                points[#points + 1] = self.point + self.direction * t
            end
        end

        if #points == 0 then
            return false, nil
        end
        return true, points
    end

    local t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denom
    local u = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denom

    if t >= 0 and u >= 0 then
        local x = a.x + t * (b.x - a.x)
        local y = a.y + t * (b.y - a.y)
        points[#points + 1] = Vector2.create(x, y)
    end

    if #points == 0 then
        return false, nil
    end
    return true, points
end

---检查是否与另一条射线相交
---@param other foundation.shape.Ray
---@return boolean
function Ray:__hasIntersectionWithRay(other)
    local a = self.point
    local b = self.point + self.direction
    local c = other.point
    local d = other.point + other.direction

    local denom = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
    if math.abs(denom) < 1e-10 then
        local dir_cross = self.direction:cross(other.direction)
        if math.abs(dir_cross) < 1e-10 then
            local point_diff = other.point - self.point
            local t = point_diff:dot(self.direction)
            return t >= 0
        end
        return false
    end

    local t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denom
    local u = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denom

    return t >= 0 and u >= 0
end

---检查与三角形的相交
---@param other foundation.shape.Triangle
---@return boolean, foundation.math.Vector2[] | nil
function Ray:__intersectToTriangle(other)
    return other:__intersectToRay(self)
end

---检查是否与三角形相交
---@param other foundation.shape.Triangle
---@return boolean
function Ray:__hasIntersectionWithTriangle(other)
    return other:__hasIntersectionWithRay(self)
end

---检查与圆的相交
---@param other foundation.shape.Circle
---@return boolean, foundation.math.Vector2[] | nil
function Ray:__intersectToCircle(other)
    return other:__intersectToRay(self)
end

---检查是否与圆相交
---@param other foundation.shape.Circle
---@return boolean
function Ray:__hasIntersectionWithCircle(other)
    return other:__hasIntersectionWithRay(self)
end

---检查与矩形的相交
---@param other foundation.shape.Rectangle
---@return boolean, foundation.math.Vector2[] | nil
function Ray:__intersectToRectangle(other)
    return other:__intersectToRay(self)
end

---仅检查是否与矩形相交
---@param other foundation.shape.Rectangle
---@return boolean
function Ray:__hasIntersectionWithRectangle(other)
    return other:__hasIntersectionWithRay(self)
end

---检查与扇形的相交
---@param other foundation.shape.Sector
---@return boolean, foundation.math.Vector2[] | nil
function Ray:__intersectToSector(other)
    return other:__intersectToRay(self)
end

---仅检查是否与扇形相交
---@param other foundation.shape.Sector
---@return boolean
function Ray:__hasIntersectionWithSector(other)
    return other:__hasIntersectionWithRay(self)
end

---计算点到射线的距离
---@param point foundation.math.Vector2 点
---@return number 距离
function Ray:distanceToPoint(point)
    local point_vec = point - self.point
    local proj_length = point_vec:dot(self.direction)

    if proj_length < 0 then
        return (point - self.point):length()
    else
        local proj_point = self.point + self.direction * proj_length
        return (point - proj_point):length()
    end
end

---检查点是否在射线上
---@param point foundation.math.Vector2 点
---@param tolerance number 误差容忍度，默认为1e-10
---@return boolean
function Ray:containsPoint(point, tolerance)
    tolerance = tolerance or 1e-10
    local point_vec = point - self.point

    local proj_length = point_vec:dot(self.direction)
    if proj_length < 0 then
        return false
    end

    local cross = point_vec:cross(self.direction)
    return math.abs(cross) < tolerance
end

---获取点在射线上的投影
---@param point foundation.math.Vector2 点
---@return foundation.math.Vector2 投影点
function Ray:projectPoint(point)
    local point_vec = point - self.point
    local proj_length = point_vec:dot(self.direction)

    if proj_length < 0 then
        return self.point:clone()
    else
        return self.point + self.direction * proj_length
    end
end

ffi.metatype("foundation_shape_Ray", Ray)

return Ray
