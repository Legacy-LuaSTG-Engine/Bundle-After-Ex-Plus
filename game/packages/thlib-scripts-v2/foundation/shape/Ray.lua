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
    ---@diagnostic disable-next-line: return-type-mismatch
    return ffi.new("foundation_shape_Ray", point, direction:normalized())
end

---根据起始点、角度创建射线
---@param point foundation.math.Vector2 起始点
---@param angle number 角度（度）
---@return foundation.shape.Ray
function Ray.createFromAngle(point, angle)
    local direction = Vector2.createFromAngle(angle, 1)
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
    end
    return false, nil
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

---检查与三角形的相交
---@param other foundation.shape.Triangle
---@return boolean, foundation.math.Vector2[] | nil
function Ray:__intersectToTriangle(other)
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

---检查与圆的相交
---@param other foundation.shape.Circle
---@return boolean, foundation.math.Vector2[] | nil
function Ray:__intersectToCircle(other)
    local points = {}
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
    if discriminant >= 0 then
        local sqrt_d = math.sqrt(discriminant)
        local t1 = (-b - sqrt_d) / (2 * a)
        local t2 = (-b + sqrt_d) / (2 * a)
        if t1 >= 0 then
            points[#points + 1] = self.point + dir * t1
        end
        if t2 >= 0 and math.abs(t2 - t1) > 1e-10 then
            points[#points + 1] = self.point + dir * t2
        end
    end

    if #points == 0 then
        return false, nil
    end
    return true, points
end

ffi.metatype("foundation_shape_Ray", Ray)

return Ray