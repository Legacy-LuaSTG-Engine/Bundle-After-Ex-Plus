local ffi = require("ffi")

local math = math
local type = type
local tostring = tostring
local string = string

local Vector2 = require("foundation.math.Vector2")
local ShapeIntersector = require("foundation.shape.ShapeIntersector")

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
    ---@diagnostic disable-next-line: return-type-mismatch, missing-return-value
    return ffi.new("foundation_shape_Circle", center, radius)
end

---圆相等比较
---@param a foundation.shape.Circle
---@param b foundation.shape.Circle
---@return boolean
function Circle.__eq(a, b)
    return a.center == b.center and math.abs(a.radius - b.radius) <= 1e-10
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
    return ShapeIntersector.circleContainsPoint(self, point)
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
---@return boolean, foundation.math.Vector2[] | nil
function Circle:intersects(other)
    return ShapeIntersector.intersect(self, other)
end

---只检查是否与其他形状相交，不计算交点
---@param other any
---@return boolean
function Circle:hasIntersection(other)
    return ShapeIntersector.hasIntersection(self, other)
end

---计算圆的面积
---@return number 圆的面积
function Circle:area()
    return math.pi * self.radius * self.radius
end

---计算点到圆的最近点
---@param point foundation.math.Vector2 要检查的点
---@return foundation.math.Vector2 圆上最近的点
function Circle:closestPoint(point)
    local dir = point - self.center
    local dist = dir:length()
    if dist <= 1e-10 then
        return Vector2.create(self.center.x + self.radius, self.center.y)
    end
    local normalized_dir = dir / dist
    return self.center + normalized_dir * self.radius
end

---计算点到圆的距离
---@param point foundation.math.Vector2 要检查的点
---@return number 点到圆的距离
function Circle:distanceToPoint(point)
    local dist = (point - self.center):length()
    return math.abs(dist - self.radius)
end

---将点投影到圆上
---@param point foundation.math.Vector2 要投影的点
---@return foundation.math.Vector2 投影点
function Circle:projectPoint(point)
    return self:closestPoint(point)
end

---检查点是否在圆上
---@param point foundation.math.Vector2 要检查的点
---@param tolerance number|nil 容差，默认为1e-10
---@return boolean 点是否在圆上
---@overload fun(self:foundation.shape.Circle, point:foundation.math.Vector2): boolean
function Circle:containsPoint(point, tolerance)
    tolerance = tolerance or 1e-10
    local dist = (point - self.center):length()
    return math.abs(dist - self.radius) <= tolerance
end

ffi.metatype("foundation_shape_Circle", Circle)

return Circle