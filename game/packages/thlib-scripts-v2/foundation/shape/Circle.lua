local ffi = require("ffi")

local math = math
local type = type
local tostring = tostring
local string = string
local rawset = rawset
local setmetatable = setmetatable

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
Circle.__type = "foundation.shape.Circle"

---@param self foundation.shape.Circle
---@param key any
---@return any
function Circle.__index(self, key)
    if key == "center" then
        return self.__data.center
    elseif key == "radius" then
        return self.__data.radius
    end
    return Circle[key]
end

---@param self foundation.shape.Circle
---@param key any
---@param value any
function Circle.__newindex(self, key, value)
    if key == "center" then
        self.__data.center = value
    elseif key == "radius" then
        self.__data.radius = value
    else
        rawset(self, key, value)
    end
end

---创建一个新的圆
---@param center foundation.math.Vector2 圆心位置
---@param radius number 半径
---@return foundation.shape.Circle
function Circle.create(center, radius)
    local circle = ffi.new("foundation_shape_Circle", center, radius)
    local result = {
        __data = circle,
    }
    ---@diagnostic disable-next-line: return-type-mismatch, missing-return-value
    return setmetatable(result, Circle)
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

---旋转圆（修改当前圆）
---@param rad number 旋转弧度
---@param center foundation.math.Vector2|nil 旋转中心点，默认为圆心
---@return foundation.shape.Circle 自身引用
function Circle:rotate(rad, center)
    if center then
        local dx = self.center.x - center.x
        local dy = self.center.y - center.y
        local cosA, sinA = math.cos(rad), math.sin(rad)
        self.center.x = center.x + dx * cosA - dy * sinA
        self.center.y = center.y + dx * sinA + dy * cosA
    end
    return self
end

---旋转圆（修改当前圆）
---@param angle number 旋转角度
---@param center foundation.math.Vector2|nil 旋转中心点，默认为圆心
---@return foundation.shape.Circle 自身引用
function Circle:degreeRotate(angle, center)
    return self:rotate(math.rad(angle), center)
end

---获取旋转后的圆副本
---@param rad number 旋转弧度
---@param center foundation.math.Vector2|nil 旋转中心点，默认为圆心
---@return foundation.shape.Circle
function Circle:rotated(rad, center)
    local result = Circle.create(self.center:clone(), self.radius)
    return result:rotate(rad, center)
end

---获取旋转后的圆副本
---@param angle number 旋转角度
---@param center foundation.math.Vector2|nil 旋转中心点，默认为圆心
---@return foundation.shape.Circle
function Circle:degreeRotated(angle, center)
    return self:rotated(math.rad(angle), center)
end

---缩放圆（修改当前圆）
---@param scale number|foundation.math.Vector2 缩放比例
---@param center foundation.math.Vector2|nil 缩放中心点，默认为圆心
---@return foundation.shape.Circle 自身引用
function Circle:scale(scale, center)
    local scaleX, scaleY
    if type(scale) == "number" then
        scaleX, scaleY = scale, scale
    else
        scaleX, scaleY = scale.x, scale.y
    end
    center = center or self.center

    self.radius = self.radius * math.sqrt(scaleX * scaleY)
    local dx = self.center.x - center.x
    local dy = self.center.y - center.y
    self.center.x = center.x + dx * scaleX
    self.center.y = center.y + dy * scaleY
    return self
end

---获取缩放后的圆副本
---@param scale number|foundation.math.Vector2 缩放比例
---@param center foundation.math.Vector2|nil 缩放中心点，默认为圆心
---@return foundation.shape.Circle
function Circle:scaled(scale, center)
    local result = Circle.create(self.center:clone(), self.radius)
    return result:scale(scale, center)
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

---计算圆的周长
---@return number 圆的周长
function Circle:getPerimeter()
    return 2 * math.pi * self.radius
end

---计算圆的中心
---@return foundation.math.Vector2 圆心位置
function Circle:getCenter()
    return self.center:clone()
end

---获取圆的AABB包围盒
---@return number, number, number, number
function Circle:AABB()
    local cx, cy = self.center.x, self.center.y
    local r = self.radius
    return cx - r, cx + r, cy - r, cy + r
end

---计算圆的包围盒宽高
---@return number, number
function Circle:getBoundingBoxSize()
    return self.radius * 2, self.radius * 2
end

---计算圆的重心
---@return foundation.math.Vector2 圆心位置
function Circle:centroid()
    return self.center:clone()
end

---计算点到圆的最近点
---@param point foundation.math.Vector2 要检查的点
---@param boundary boolean 是否限制在边界内，默认为false
---@return foundation.math.Vector2 圆上最近的点
---@overload fun(self:foundation.shape.Circle, point:foundation.math.Vector2): foundation.math.Vector2
function Circle:closestPoint(point, boundary)
    local dir = point - self.center
    local dist = dir:length()
    if boundary then
        if dist <= 1e-10 then
            return Vector2.create(self.center.x + self.radius, self.center.y)
        end
    elseif dist <= self.radius then
        return point:clone()
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
    return self:closestPoint(point, true)
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

---复制圆
---@return foundation.shape.Circle 圆的副本
function Circle:clone()
    return Circle.create(self.center:clone(), self.radius)
end

ffi.metatype("foundation_shape_Circle", Circle)

return Circle