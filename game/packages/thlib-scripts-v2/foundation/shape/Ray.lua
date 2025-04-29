local ffi = require("ffi")

local math = math
local tostring = tostring
local string = string

local Vector2 = require("foundation.math.Vector2")
local ShapeIntersector = require("foundation.shape.ShapeIntersector")

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
    return ShapeIntersector.intersect(self, other)
end

---检查是否与其他形状相交，只返回是否相交的布尔值
---@param other any
---@return boolean
function Ray:hasIntersection(other)
    return ShapeIntersector.hasIntersection(self, other)
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
