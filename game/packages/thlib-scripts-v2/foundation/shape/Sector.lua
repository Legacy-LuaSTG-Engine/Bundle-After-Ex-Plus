local ffi = require("ffi")

local math = math
local type = type
local ipairs = ipairs
local tostring = tostring
local string = string
local rawset = rawset
local setmetatable = setmetatable

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
Sector.__type = "foundation.shape.Sector"

---@param self foundation.shape.Sector
---@param key any
---@return any
function Sector.__index(self, key)
    if key == "center" then
        return self.__data.center
    elseif key == "radius" then
        return self.__data.radius
    elseif key == "direction" then
        return self.__data.direction
    elseif key == "range" then
        return self.__data.range
    end
    return Sector[key]
end

---@param self foundation.shape.Sector
---@param key any
---@param value any
function Sector.__newindex(self, key, value)
    if key == "center" then
        self.__data.center = value
    elseif key == "radius" then
        self.__data.radius = value
    elseif key == "direction" then
        self.__data.direction = value
    elseif key == "range" then
        self.__data.range = value
    else
        rawset(self, key, value)
    end
end

---创建一个新的扇形
---@param center foundation.math.Vector2 中心点
---@param radius number 半径
---@param direction foundation.math.Vector2 方向（将归一化）
---@param range number 范围（-1到1）
---@return foundation.shape.Sector
function Sector.create(center, radius, direction, range)
    local dist = direction and direction:length() or 0
    if dist <= 1e-10 then
        direction = Vector2.create(1, 0)
    elseif dist ~= 1 then
        ---@diagnostic disable-next-line: need-check-nil
        direction = direction:normalized()
    else
        ---@diagnostic disable-next-line: need-check-nil
        direction = direction:clone()
    end
    range = math.max(-1, math.min(1, range))
    local sector = ffi.new("foundation_shape_Sector", center, radius, direction, range)
    local result = {
        __data = sector,
    }
    ---@diagnostic disable-next-line: return-type-mismatch, missing-return-value
    return setmetatable(result, Sector)
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
            math.abs(a.radius - b.radius) <= 1e-10 and
            a.direction == b.direction and
            math.abs(a.range - b.range) <= 1e-10
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

---计算扇形的周长
---@return number 扇形的周长（弧长+两条半径）
function Sector:getPerimeter()
    if math.abs(self.range) >= 1 then
        return 2 * math.pi * self.radius
    end

    local arcLength = self.radius * self:getAngle()
    return arcLength + 2 * self.radius
end

---计算扇形的中心点
---@return foundation.math.Vector2
function Sector:getCenter()
    if math.abs(self.range) >= 1 then
        return self.center:clone()
    end

    local points = { self.center:clone() }
    local start_dir = self.direction
    local end_dir = self.direction:rotated(self.range * 2 * math.pi)
    local start_point = self.center + start_dir * self.radius
    local end_point = self.center + end_dir * self.radius
    points[#points + 1] = start_point
    points[#points + 1] = end_point

    local start_angle = self.direction:angle()
    local end_angle = start_angle + self.range * 2 * math.pi
    local min_angle = math.min(start_angle, end_angle)
    local max_angle = math.max(start_angle, end_angle)

    local critical_points = {
        { angle = 0, point = Vector2.create(self.center.x + self.radius, self.center.y) },
        { angle = math.pi, point = Vector2.create(self.center.x - self.radius, self.center.y) },
        { angle = math.pi / 2, point = Vector2.create(self.center.x, self.center.y + self.radius) },
        { angle = 3 * math.pi / 2, point = Vector2.create(self.center.x, self.center.y - self.radius) }
    }

    for _, cp in ipairs(critical_points) do
        local angle = cp.angle
        angle = angle - 2 * math.pi * math.floor((angle - min_angle) / (2 * math.pi))
        if min_angle <= angle and angle <= max_angle then
            points[#points + 1] = cp.point
        end
    end

    local x_min, x_max = points[1].x, points[1].x
    local y_min, y_max = points[1].y, points[1].y
    for _, p in ipairs(points) do
        x_min = math.min(x_min, p.x)
        x_max = math.max(x_max, p.x)
        y_min = math.min(y_min, p.y)
        y_max = math.max(y_max, p.y)
    end

    return Vector2.create((x_min + x_max) / 2, (y_min + y_max) / 2)
end

---计算扇形的包围盒宽高
---@return number, number
function Sector:getBoundingBoxSize()
    if math.abs(self.range) >= 1 then
        return 2 * self.radius, 2 * self.radius
    end

    local points = { self.center:clone() }
    local start_dir = self.direction
    local end_dir = self.direction:rotated(self.range * 2 * math.pi)
    local start_point = self.center + start_dir * self.radius
    local end_point = self.center + end_dir * self.radius
    points[#points + 1] = start_point
    points[#points + 1] = end_point

    local start_angle = self.direction:angle()
    local end_angle = start_angle + self.range * 2 * math.pi
    local min_angle = math.min(start_angle, end_angle)
    local max_angle = math.max(start_angle, end_angle)

    local critical_points = {
        { angle = 0, point = Vector2.create(self.center.x + self.radius, self.center.y) },
        { angle = math.pi, point = Vector2.create(self.center.x - self.radius, self.center.y) },
        { angle = math.pi / 2, point = Vector2.create(self.center.x, self.center.y + self.radius) },
        { angle = 3 * math.pi / 2, point = Vector2.create(self.center.x, self.center.y - self.radius) }
    }

    for _, cp in ipairs(critical_points) do
        local angle = cp.angle
        angle = angle - 2 * math.pi * math.floor((angle - min_angle) / (2 * math.pi))
        if min_angle <= angle and angle <= max_angle then
            points[#points + 1] = cp.point
        end
    end

    local x_min, x_max = points[1].x, points[1].x
    local y_min, y_max = points[1].y, points[1].y
    for _, p in ipairs(points) do
        x_min = math.min(x_min, p.x)
        x_max = math.max(x_max, p.x)
        y_min = math.min(y_min, p.y)
        y_max = math.max(y_max, p.y)
    end

    return x_max - x_min, y_max - y_min
end

---获取扇形的重心
---@return foundation.math.Vector2
function Sector:centroid()
    if math.abs(self.range) >= 1 then
        return self.center:clone()
    end
    if self.range <= 1e-10 then
        return self.center + self.direction * (self.radius / 2)
    end
    local theta = self:getAngle()
    local half_theta = theta / 2
    local mid_angle = self.direction:angle() + self.range * math.pi
    local factor = (2 * self.radius / 3) * (math.sin(half_theta) / half_theta)
    local x_c = self.center.x + factor * math.cos(mid_angle)
    local y_c = self.center.y + factor * math.sin(mid_angle)
    return Vector2.create(x_c, y_c)
end

---检查点是否在扇形内（包括边界）
---@param point foundation.math.Vector2
---@return boolean
function Sector:contains(point)
    return ShapeIntersector.sectorContainsPoint(self, point)
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
---@param boundary boolean 是否限制在边界内，默认为false
---@return foundation.math.Vector2
---@overload fun(self: foundation.shape.Sector, point: foundation.math.Vector2): foundation.math.Vector2
function Sector:closestPoint(point, boundary)
    if math.abs(self.range) >= 1 then
        return Circle.closestPoint(self, point, boundary)
    end
    if not boundary and self:contains(point) then
        return point:clone()
    end
    local circle_closest = Circle.closestPoint(self, point, boundary)
    local contains = self:contains(circle_closest)
    if not boundary and contains then
        return circle_closest
    end
    local startDir = self.direction
    local endDir = self.direction:rotated(self.range * 2 * math.pi)
    local start_point = self.center + startDir * self.radius
    local end_point = self.center + endDir * self.radius
    local start_segment = Segment.create(self.center, start_point)
    local end_segment = Segment.create(self.center, end_point)
    local candidates = {
        start_segment:closestPoint(point, boundary),
        end_segment:closestPoint(point, boundary),
        boundary and contains and circle_closest or nil,
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
    return self:closestPoint(point, true)
end

---检查点是否在扇形边界上
---@param point foundation.math.Vector2
---@param tolerance number|nil
---@return boolean
function Sector:containsPoint(point, tolerance)
    tolerance = tolerance or 1e-10

    local vec = point - self.center
    local range = self.range * 2 * math.pi
    if math.abs(self.range) >= 1 then
        local dist = (point - self.center):length()
        return math.abs(dist - self.radius) <= tolerance
    end

    local segment1 = Segment.create(self.center, self.center + self.direction * self.radius)
    if segment1:containsPoint(point, tolerance) then
        return true
    end

    local segment2 = Segment.create(self.center, self.center + self.direction:rotated(range) * self.radius)
    if segment2:containsPoint(point, tolerance) then
        return true
    end

    local distance = vec:length()
    if math.abs(distance - self.radius) > tolerance then
        return false
    end
    if distance <= tolerance then
        return true
    end

    local angle_begin
    if range > 0 then
        angle_begin = self.direction:angle()
    else
        range = -range
        angle_begin = self.direction:angle() - range
    end

    local vec_angle = vec:angle()
    vec_angle = vec_angle - 2 * math.pi * math.floor((vec_angle - angle_begin) / (2 * math.pi))
    return angle_begin <= vec_angle and vec_angle <= angle_begin + range
end

---复制扇形
---@return foundation.shape.Sector
function Sector:clone()
    return Sector.create(self.center:clone(), self.radius, self.direction:clone(), self.range)
end

ffi.metatype("foundation_shape_Sector", Sector)

return Sector