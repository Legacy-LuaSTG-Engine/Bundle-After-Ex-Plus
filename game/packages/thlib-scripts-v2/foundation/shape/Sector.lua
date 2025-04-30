local ffi = require("ffi")

local math = math
local type = type
local ipairs = ipairs
local tostring = tostring
local string = string

local Vector2 = require("foundation.math.Vector2")
local Segment = require("foundation.shape.Segment")
local Circle = require("foundation.shape.Circle")
local ShapeIntersector = require("foundation.shape.ShapeIntersector")

ffi.cdef [[
typedef struct {
    foundation_math_Vector2 center;
    double radius;
    foundation_math_Vector2 direction;
    double range;
} foundation_shape_Sector;
]]

---@class foundation.shape.Sector
---@field center foundation.math.Vector2 扇形的中心点
---@field radius number 扇形的半径
---@field direction foundation.math.Vector2 方向（归一化向量）
---@field range number 扇形范围（-1到1，1或-1为整圆，0.5或-0.5为半圆）
local Sector = {}
Sector.__index = Sector
Sector.__type = "foundation.shape.Sector"

---创建一个新的扇形
---@param center foundation.math.Vector2 中心点
---@param radius number 半径
---@param direction foundation.math.Vector2 方向（将归一化）
---@param range number 范围（-1到1）
---@return foundation.shape.Sector
function Sector.create(center, radius, direction, range)
    local dir = direction:normalized()
    range = math.max(-1, math.min(1, range)) -- 限制范围在-1到1
    ---@diagnostic disable-next-line: return-type-mismatch, missing-return-value
    return ffi.new("foundation_shape_Sector", center, radius, dir, range)
end

---使用弧度创建扇形
---@param center foundation.math.Vector2 中心点
---@param radius number 半径
---@param rad number 方向弧度
---@param range number 范围（-1到1）
---@return foundation.shape.Sector
function Sector.createFromRad(center, radius, rad, range)
    local dir = Vector2.createFromRad(rad)
    return Sector.create(center, radius, dir, range)
end

---使用角度创建扇形
---@param center foundation.math.Vector2 中心点
---@param radius number 半径
---@param angle number 方向角度
---@param range number 范围（-1到1）
---@return foundation.shape.Sector
function Sector.createFromAngle(center, radius, angle, range)
    local rad = math.rad(angle)
    return Sector.createFromRad(center, radius, rad, range)
end

---扇形相等比较
---@param a foundation.shape.Sector
---@param b foundation.shape.Sector
---@return boolean
function Sector.__eq(a, b)
    return a.center == b.center and
            math.abs(a.radius - b.radius) < 1e-10 and
            a.direction == b.direction and
            math.abs(a.range - b.range) < 1e-10
end

---扇形的字符串表示
---@param self foundation.shape.Sector
---@return string
function Sector.__tostring(self)
    return string.format("Sector(center=%s, radius=%f, direction=%s, range=%f)",
            tostring(self.center), self.radius, tostring(self.direction), self.range)
end

---转为圆形
---@return foundation.shape.Circle
function Sector:toCircle()
    return Circle.create(self.center, self.radius)
end

---计算扇形角度（弧度）
---@return number
function Sector:getAngle()
    return math.abs(self.range) * 2 * math.pi
end

---计算扇形角度（角度）
---@return number
function Sector:getDegreeAngle()
    return math.deg(self:getAngle())
end

---计算扇形的面积
---@return number
function Sector:area()
    return 0.5 * self.radius * self.radius * self:getAngle()
end

---检查点是否在扇形内（包括边界）
---@param point foundation.math.Vector2
---@return boolean
function Sector:contains(point)
    if math.abs(self.range) >= 1 then
        return Circle.create(self.center, self.radius):contains(point)
    end
    local vec = point - self.center
    if vec:length() > self.radius then
        return false
    end
    local dir = vec:normalized()
    local angle = math.acos(self.direction:dot(dir))
    local maxAngle = math.abs(self.range) * math.pi
    local cross = self.direction.x * dir.y - self.direction.y * dir.x
    if self.range < 0 then
        cross = -cross
    end
    return angle <= maxAngle and cross >= 0
end

---移动扇形（修改当前扇形）
---@param v foundation.math.Vector2 | number
---@return foundation.shape.Sector
function Sector:move(v)
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

---获取移动后的扇形副本
---@param v foundation.math.Vector2 | number
---@return foundation.shape.Sector
function Sector:moved(v)
    local moveX, moveY
    if type(v) == "number" then
        moveX, moveY = v, v
    else
        moveX, moveY = v.x, v.y
    end
    return Sector.create(
            Vector2.create(self.center.x + moveX, self.center.y + moveY),
            self.radius, self.direction, self.range
    )
end

---旋转扇形（修改当前扇形）
---@param rad number 旋转弧度
---@return foundation.shape.Sector
function Sector:rotate(rad)
    self.direction:rotate(rad)
    return self
end

---旋转扇形（修改当前扇形）
---@param angle number 旋转角度
---@return foundation.shape.Sector
function Sector:degreeRotate(angle)
    return self:rotate(math.rad(angle))
end

---获取旋转后的扇形副本
---@param rad number 旋转弧度
---@return foundation.shape.Sector
function Sector:rotated(rad)
    return Sector.create(
            self.center, self.radius,
            self.direction:rotated(rad),
            self.range
    )
end

---获取旋转后的扇形副本
---@param angle number 旋转角度
---@return foundation.shape.Sector
function Sector:degreeRotated(angle)
    return self:rotated(math.rad(angle))
end

---缩放扇形（修改当前扇形）
---@param scale number
---@return foundation.shape.Sector
function Sector:scale(scale)
    self.radius = self.radius * scale
    return self
end

---获取缩放后的扇形副本
---@param scale number
---@return foundation.shape.Sector
function Sector:scaled(scale)
    return Sector.create(self.center, self.radius * scale, self.direction, self.range)
end

---检查与其他形状的相交
---@param other any
---@return boolean, foundation.math.Vector2[] | nil
function Sector:intersects(other)
    return ShapeIntersector.intersect(self, other)
end

---仅检查是否与其他形状相交
---@param other any
---@return boolean
function Sector:hasIntersection(other)
    return ShapeIntersector.hasIntersection(self, other)
end

---计算点到扇形的最近点
---@param point foundation.math.Vector2
---@return foundation.math.Vector2
function Sector:closestPoint(point)
    if math.abs(self.range) >= 1 then
        return Circle.create(self.center, self.radius):closestPoint(point)
    end
    if self:contains(point) then
        return point:clone()
    end
    local circle = Circle.create(self.center, self.radius)
    local circle_closest = circle:closestPoint(point)
    if self:contains(circle_closest) then
        return circle_closest
    end
    local startDir = self.direction
    local endDir = self.direction:rotated(self.range * 2 * math.pi)
    local start_point = self.center + startDir * self.radius
    local end_point = self.center + endDir * self.radius
    local start_segment = Segment.create(self.center, start_point)
    local end_segment = Segment.create(self.center, end_point)
    local candidates = {
        start_segment:closestPoint(point),
        end_segment:closestPoint(point)
    }
    local min_distance = math.huge
    local closest_point = candidates[1]
    for _, candidate in ipairs(candidates) do
        local distance = (point - candidate):length()
        if distance < min_distance then
            min_distance = distance
            closest_point = candidate
        end
    end
    return closest_point
end

---计算点到扇形的距离
---@param point foundation.math.Vector2
---@return number
function Sector:distanceToPoint(point)
    if self:contains(point) then
        return 0
    end
    return (point - self:closestPoint(point)):length()
end

---将点投影到扇形上
---@param point foundation.math.Vector2
---@return foundation.math.Vector2
function Sector:projectPoint(point)
    return self:closestPoint(point)
end

---检查点是否在扇形边界上
---@param point foundation.math.Vector2
---@param tolerance number|nil
---@return boolean
function Sector:containsPoint(point, tolerance)
    tolerance = tolerance or 1e-10
    if math.abs(self.range) >= 1 then
        return Circle.create(self.center, self.radius):containsPoint(point, tolerance)
    end
    local circle = Circle.create(self.center, self.radius)
    if not circle:containsPoint(point, tolerance) then
        return false
    end
    local vec = point - self.center
    local dir = vec:normalized()
    local centerAngle = math.atan2(self.direction.y, self.direction.x) % (2 * math.pi)
    local pointAngle = math.atan2(dir.y, dir.x) % (2 * math.pi)
    local maxAngle = math.abs(self.range) * math.pi
    local startAngle = centerAngle
    local endAngle = (centerAngle + self.range * 2 * math.pi) % (2 * math.pi)
    if startAngle < 0 then
        startAngle = startAngle + 2 * math.pi
    end
    if endAngle < 0 then
        endAngle = endAngle + 2 * math.pi
    end
    if pointAngle < 0 then
        pointAngle = pointAngle + 2 * math.pi
    end
    local angleDiff = math.abs(pointAngle - centerAngle)
    if angleDiff > math.pi then
        angleDiff = 2 * math.pi - angleDiff
    end
    return angleDiff <= maxAngle + tolerance
end

ffi.metatype("foundation_shape_Sector", Sector)

return Sector