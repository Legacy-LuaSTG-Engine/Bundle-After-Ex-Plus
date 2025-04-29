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
    foundation_math_Vector2 startDirection;
    foundation_math_Vector2 endDirection;
} foundation_shape_Sector;
]]

---@class foundation.shape.Sector
---@field center foundation.math.Vector2 扇形的中心点
---@field radius number 扇形的半径
---@field startDirection foundation.math.Vector2 起始方向（归一化向量）
---@field endDirection foundation.math.Vector2 终止方向（归一化向量）
local Sector = {}
Sector.__index = Sector
Sector.__type = "foundation.shape.Sector"

---创建一个新的扇形
---@param center foundation.math.Vector2 中心点
---@param radius number 半径
---@param startDirection foundation.math.Vector2 起始方向（将归一化）
---@param endDirection foundation.math.Vector2 终止方向（将归一化）
---@return foundation.shape.Sector
function Sector.create(center, radius, startDirection, endDirection)
    local startDir = startDirection:normalized()
    local endDir = endDirection:normalized()
    ---@diagnostic disable-next-line: return-type-mismatch, missing-return-value
    return ffi.new("foundation_shape_Sector", center, radius, startDir, endDir)
end

---使用弧度创建扇形
---@param center foundation.math.Vector2 中心点
---@param radius number 半径
---@param startRad number 起始弧度
---@param endRad number 终止弧度
---@return foundation.shape.Sector
function Sector.createFromRad(center, radius, startRad, endRad)
    local startDir = Vector2.createFromRad(startRad)
    local endDir = Vector2.createFromRad(endRad)
    return Sector.create(center, radius, startDir, endDir)
end

---使用角度创建扇形
---@param center foundation.math.Vector2 中心点
---@param radius number 半径
---@param startAngle number 起始角度
---@param endAngle number 终止角度
---@return foundation.shape.Sector
function Sector.createFromAngle(center, radius, startAngle, endAngle)
    local startRad = math.rad(startAngle)
    local endRad = math.rad(endAngle)
    return Sector.createFromRad(center, radius, startRad, endRad)
end

---扇形相等比较
---@param a foundation.shape.Sector
---@param b foundation.shape.Sector
---@return boolean
function Sector.__eq(a, b)
    return a.center == b.center and
            math.abs(a.radius - b.radius) < 1e-10 and
            a.startDirection == b.startDirection and
            a.endDirection == b.endDirection
end

---扇形的字符串表示
---@param self foundation.shape.Sector
---@return string
function Sector.__tostring(self)
    return string.format("Sector(center=%s, radius=%f, startDirection=%s, endDirection=%s)",
            tostring(self.center), self.radius, tostring(self.startDirection), tostring(self.endDirection))
end

---计算扇形角度（弧度）
---@return number
function Sector:getAngle()
    local dot = self.startDirection:dot(self.endDirection)
    dot = math.max(-1, math.min(1, dot)) -- 防止浮点误差
    local angle = math.acos(dot)
    local cross = self.startDirection.x * self.endDirection.y - self.startDirection.y * self.endDirection.x
    if cross < 0 then
        angle = 2 * math.pi - angle
    end
    return angle
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
            self.radius, self.startDirection, self.endDirection
    )
end

---旋转扇形（修改当前扇形）
---@param rad number 旋转弧度
---@return foundation.shape.Sector
function Sector:rotate(rad)
    self.startDirection:rotate(rad)
    self.endDirection:rotate(rad)
    return self
end

---获取旋转后的扇形副本
---@param rad number 旋转弧度
---@return foundation.shape.Sector
function Sector:rotated(rad)
    return Sector.create(
            self.center, self.radius,
            self.startDirection:rotated(rad),
            self.endDirection:rotated(rad)
    )
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
    return Sector.create(self.center, self.radius * scale, self.startDirection, self.endDirection)
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
    if self:contains(point) then
        return point:clone()
    end
    local circle = Circle.create(self.center, self.radius)
    local circle_closest = circle:closestPoint(point)
    if self:contains(circle_closest) then
        return circle_closest
    end
    local start_point = self.center + self.startDirection * self.radius
    local end_point = self.center + self.endDirection * self.radius
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
    local circle = Circle.create(self.center, self.radius)
    if not circle:containsPoint(point, tolerance) then
        return false
    end
    local vec = point - self.center
    local dir = vec:normalized()
    local startAngle = math.atan2(self.startDirection.y, self.startDirection.x) % (2 * math.pi)
    local endAngle = math.atan2(self.endDirection.y, self.endDirection.x) % (2 * math.pi)
    local pointAngle = math.atan2(dir.y, dir.x) % (2 * math.pi)
    if startAngle < 0 then
        startAngle = startAngle + 2 * math.pi
    end
    if endAngle < 0 then
        endAngle = endAngle + 2 * math.pi
    end
    if pointAngle < 0 then
        pointAngle = pointAngle + 2 * math.pi
    end
    if startAngle <= endAngle then
        return math.abs(pointAngle - startAngle) < tolerance or math.abs(pointAngle - endAngle) < tolerance
    else
        return math.abs(pointAngle - startAngle) < tolerance or math.abs(pointAngle - endAngle) < tolerance or
                (pointAngle >= startAngle or pointAngle <= endAngle)
    end
end

ffi.metatype("foundation_shape_Sector", Sector)

return Sector