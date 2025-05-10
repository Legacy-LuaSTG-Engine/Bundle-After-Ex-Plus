local ffi = require("ffi")

local type = type
local ipairs = ipairs
local tostring = tostring
local string = string
local math = math
local rawset = rawset
local setmetatable = setmetatable

local Vector2 = require("foundation.math.Vector2")
local Segment = require("foundation.shape.Segment")
local ShapeIntersector = require("foundation.shape.ShapeIntersector")

ffi.cdef [[
typedef struct {
    foundation_math_Vector2 point1, point2, point3;
} foundation_shape_Triangle;
]]

---@class foundation.shape.Triangle
---@field point1 foundation.math.Vector2 三角形的第一个顶点
---@field point2 foundation.math.Vector2 三角形的第二个顶点
---@field point3 foundation.math.Vector2 三角形的第三个顶点
local Triangle = {}
Triangle.__type = "foundation.shape.Triangle"

---@param self foundation.shape.Triangle
---@param key string
---@return any
function Triangle.__index(self, key)
    if key == "point1" then
        return self.__data.point1
    elseif key == "point2" then
        return self.__data.point2
    elseif key == "point3" then
        return self.__data.point3
    end
    return Triangle[key]
end

---@param self foundation.shape.Triangle
---@param key string
---@param value any
function Triangle.__newindex(self, key, value)
    if key == "point1" then
        self.__data.point1 = value
    elseif key == "point2" then
        self.__data.point2 = value
    elseif key == "point3" then
        self.__data.point3 = value
    else
        rawset(self, key, value)
    end
end

---创建一个新的三角形
---@param v1 foundation.math.Vector2 三角形的第一个顶点
---@param v2 foundation.math.Vector2 三角形的第二个顶点
---@param v3 foundation.math.Vector2 三角形的第三个顶点
---@return foundation.shape.Triangle 新创建的三角形
function Triangle.create(v1, v2, v3)
    local triangle = ffi.new("foundation_shape_Triangle", v1, v2, v3)
    local result = {
        __data = triangle,
    }
    ---@diagnostic disable-next-line: return-type-mismatch, missing-return-value
    return setmetatable(result, Triangle)
end

---三角形相等比较
---@param a foundation.shape.Triangle 第一个三角形
---@param b foundation.shape.Triangle 第二个三角形
---@return boolean 如果两个三角形的所有顶点都相等则返回true，否则返回false
function Triangle.__eq(a, b)
    return a.point1 == b.point1 and a.point2 == b.point2 and a.point3 == b.point3
end

---三角形转字符串表示
---@param t foundation.shape.Triangle 要转换的三角形
---@return string 三角形的字符串表示
function Triangle.__tostring(t)
    return string.format("Triangle(%s, %s, %s)", tostring(t.point1), tostring(t.point2), tostring(t.point3))
end

---计算三角形的面积
---@return number 三角形的面积
function Triangle:area()
    local v2v1 = self.point2 - self.point1
    local v3v1 = self.point3 - self.point1
    return 0.5 * math.abs(v2v1:cross(v3v1))
end

---计算三角形的重心
---@return foundation.math.Vector2 三角形的重心
function Triangle:centroid()
    return (self.point1 + self.point2 + self.point3) / 3
end

---获取三角形的AABB包围盒
---@return number, number, number, number
function Triangle:AABB()
    local minX = math.min(self.point1.x, self.point2.x, self.point3.x)
    local maxX = math.max(self.point1.x, self.point2.x, self.point3.x)
    local minY = math.min(self.point1.y, self.point2.y, self.point3.y)
    local maxY = math.max(self.point1.y, self.point2.y, self.point3.y)
    return minX, maxX, minY, maxY
end

---计算三角形的中心
---@return foundation.math.Vector2 三角形的中心
function Triangle:getCenter()
    local minX, maxX, minY, maxY = self:AABB()
    return Vector2.create((minX + maxX) / 2, (minY + maxY) / 2)
end

---计算三角形的包围盒宽高
---@return number, number
function Triangle:getBoundingBoxSize()
    local minX, maxX, minY, maxY = self:AABB()
    return maxX - minX, maxY - minY
end

---计算三角形的外接圆半径
---@return number 三角形的外接圆半径
function Triangle:circumradius()
    local center = self:circumcenter()
    if center then
        return (center - self.point1):length()
    end
    return 0
end

---计算三角形的内切圆半径
---@return number 三角形的内切圆半径
function Triangle:inradius()
    local a = (self.point2 - self.point3):length()
    local b = (self.point1 - self.point3):length()
    local c = (self.point1 - self.point2):length()
    return self:area() / ((a + b + c) / 2)
end

---计算三角形的外心
---@return foundation.math.Vector2 | nil 三角形的外心
function Triangle:circumcenter()
    local x1, y1 = self.point1.x, self.point1.y
    local x2, y2 = self.point2.x, self.point2.y
    local x3, y3 = self.point3.x, self.point3.y

    local D = x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2)
    if math.abs(D) <= 1e-10 then
        return nil
    end

    local x0_num = (x1 * x1 + y1 * y1) * (y2 - y3) + (x2 * x2 + y2 * y2) * (y3 - y1) + (x3 * x3 + y3 * y3) * (y1 - y2)
    local x0 = x0_num / (2 * D)

    local y0_num = (x1 * x1 + y1 * y1) * (x3 - x2) + (x2 * x2 + y2 * y2) * (x1 - x3) + (x3 * x3 + y3 * y3) * (x2 - x1)
    local y0 = y0_num / (2 * D)

    return Vector2.create(x0, y0)
end

---计算三角形的内心
---@return foundation.math.Vector2 三角形的内心
function Triangle:incenter()
    local a = (self.point2 - self.point3):length()
    local b = (self.point1 - self.point3):length()
    local c = (self.point1 - self.point2):length()

    local p = (a * self.point1 + b * self.point2 + c * self.point3) / (a + b + c)
    return p
end

---将当前三角形平移指定距离（更改当前三角形）
---@param v foundation.math.Vector2 | number 移动距离
---@return foundation.shape.Triangle 移动后的三角形（自身引用）
function Triangle:move(v)
    local moveX, moveY
    if type(v) == "number" then
        moveX, moveY = v, v
    else
        moveX, moveY = v.x, v.y
    end
    self.point1.x = self.point1.x + moveX
    self.point1.y = self.point1.y + moveY
    self.point2.x = self.point2.x + moveX
    self.point2.y = self.point2.y + moveY
    self.point3.x = self.point3.x + moveX
    self.point3.y = self.point3.y + moveY
    return self
end

---获取三角形平移指定距离的副本
---@param v foundation.math.Vector2 | number 移动距离
---@return foundation.shape.Triangle 移动后的三角形副本
function Triangle:moved(v)
    local moveX, moveY
    if type(v) == "number" then
        moveX, moveY = v, v
    else
        moveX, moveY = v.x, v.y
    end
    return Triangle.create(
            Vector2.create(self.point1.x + moveX, self.point1.y + moveY),
            Vector2.create(self.point2.x + moveX, self.point2.y + moveY),
            Vector2.create(self.point3.x + moveX, self.point3.y + moveY)
    )
end

---将当前三角形旋转指定弧度（更改当前三角形）
---@param rad number 旋转弧度
---@param center foundation.math.Vector2 旋转中心
---@return foundation.shape.Triangle 旋转后的三角形（自身引用）
---@overload fun(self: foundation.shape.Triangle, rad: number): foundation.shape.Triangle 绕三角形重心旋转指定弧度
function Triangle:rotate(rad, center)
    center = center or self:centroid()
    local cosAngle = math.cos(rad)
    local sinAngle = math.sin(rad)
    local v1 = self.point1 - center
    local v2 = self.point2 - center
    local v3 = self.point3 - center
    self.point1.x = v1.x * cosAngle - v1.y * sinAngle + center.x
    self.point1.y = v1.x * sinAngle + v1.y * cosAngle + center.y
    self.point2.x = v2.x * cosAngle - v2.y * sinAngle + center.x
    self.point2.y = v2.x * sinAngle + v2.y * cosAngle + center.y
    self.point3.x = v3.x * cosAngle - v3.y * sinAngle + center.x
    self.point3.y = v3.x * sinAngle + v3.y * cosAngle + center.y
    return self
end

---将当前三角形旋转指定角度（更改当前三角形）
---@param angle number 旋转角度
---@param center foundation.math.Vector2 旋转中心
---@return foundation.shape.Triangle 旋转后的三角形（自身引用）
---@overload fun(self: foundation.shape.Triangle, angle: number): foundation.shape.Triangle 绕三角形重心旋转指定角度
function Triangle:degreeRotate(angle, center)
    angle = math.rad(angle)
    return self:rotate(angle, center)
end

---获取三角形的旋转指定弧度的副本
---@param rad number 旋转弧度
---@param center foundation.math.Vector2 旋转中心
---@return foundation.shape.Triangle 旋转后的三角形副本
---@overload fun(self: foundation.shape.Triangle, rad: number): foundation.shape.Triangle 绕三角形重心旋转指定弧度
function Triangle:rotated(rad, center)
    center = center or self:centroid()
    local cosAngle = math.cos(rad)
    local sinAngle = math.sin(rad)
    local v1 = self.point1 - center
    local v2 = self.point2 - center
    local v3 = self.point3 - center
    return Triangle.create(
            Vector2.create(v1.x * cosAngle - v1.y * sinAngle + center.x, v1.x * sinAngle + v1.y * cosAngle + center.y),
            Vector2.create(v2.x * cosAngle - v2.y * sinAngle + center.x, v2.x * sinAngle + v2.y * cosAngle + center.y),
            Vector2.create(v3.x * cosAngle - v3.y * sinAngle + center.x, v3.x * sinAngle + v3.y * cosAngle + center.y)
    )
end

---获取三角形的旋转指定角度的副本
---@param angle number 旋转角度
---@param center foundation.math.Vector2 旋转中心
---@return foundation.shape.Triangle 旋转后的三角形副本
---@overload fun(self: foundation.shape.Triangle, angle: number): foundation.shape.Triangle 绕三角形重心旋转指定角度
function Triangle:degreeRotated(angle, center)
    angle = math.rad(angle)
    return self:rotated(angle, center)
end

---将当前三角形缩放指定倍数（更改当前三角形）
---@param scale number|foundation.math.Vector2 缩放倍数
---@param center foundation.math.Vector2 缩放中心
---@return foundation.shape.Triangle 缩放后的三角形（自身引用）
---@overload fun(self: foundation.shape.Triangle, scale: number): foundation.shape.Triangle 相对三角形重心缩放指定倍数
function Triangle:scale(scale, center)
    local scaleX, scaleY
    if type(scale) == "number" then
        scaleX, scaleY = scale, scale
    else
        scaleX, scaleY = scale.x, scale.y
    end
    center = center or self:centroid()
    self.point1.x = (self.point1.x - center.x) * scaleX + center.x
    self.point1.y = (self.point1.y - center.y) * scaleY + center.y
    self.point2.x = (self.point2.x - center.x) * scaleX + center.x
    self.point2.y = (self.point2.y - center.y) * scaleY + center.y
    self.point3.x = (self.point3.x - center.x) * scaleX + center.x
    self.point3.y = (self.point3.y - center.y) * scaleY + center.y
    return self
end

---获取三角形的缩放指定倍数的副本
---@param scale number|foundation.math.Vector2 缩放倍数
---@param center foundation.math.Vector2 缩放中心
---@return foundation.shape.Triangle 缩放后的三角形副本
---@overload fun(self: foundation.shape.Triangle, scale: number): foundation.shape.Triangle 相对三角形重心缩放指定倍数
function Triangle:scaled(scale, center)
    local scaleX, scaleY
    if type(scale) == "number" then
        scaleX, scaleY = scale, scale
    else
        scaleX, scaleY = scale.x, scale.y
    end
    center = center or self:centroid()
    return Triangle.create(
            Vector2.create((self.point1.x - center.x) * scaleX + center.x, (self.point1.y - center.y) * scaleY + center.y),
            Vector2.create((self.point2.x - center.x) * scaleX + center.x, (self.point2.y - center.y) * scaleY + center.y),
            Vector2.create((self.point3.x - center.x) * scaleX + center.x, (self.point3.y - center.y) * scaleY + center.y)
    )
end

function Triangle:contains(point)
    return ShapeIntersector.triangleContainsPoint(self, point)
end

---检查三角形是否与其他形状相交
---@param other any 其他的形状
---@return boolean, foundation.math.Vector2[] | nil
function Triangle:intersects(other)
    return ShapeIntersector.intersect(self, other)
end

---仅检查三角形是否与其他形状相交，不返回相交点
---@param other any 其他的形状
---@return boolean
function Triangle:hasIntersection(other)
    return ShapeIntersector.hasIntersection(self, other)
end

---获取三角形的顶点
---@return foundation.math.Vector2[]
function Triangle:getVertices()
    return {
        self.point1:clone(),
        self.point2:clone(),
        self.point3:clone()
    }
end

---获取三角形的边（线段）
---@return foundation.shape.Segment[]
function Triangle:getEdges()
    return {
        Segment.create(self.point1, self.point2),
        Segment.create(self.point2, self.point3),
        Segment.create(self.point3, self.point1)
    }
end

---计算三角形的周长
---@return number 三角形的周长
function Triangle:getPerimeter()
    local a = (self.point2 - self.point3):length()
    local b = (self.point1 - self.point3):length()
    local c = (self.point1 - self.point2):length()
    return a + b + c
end

---计算点到三角形的最近点
---@param point foundation.math.Vector2 要检查的点
---@param boundary boolean 是否限制在边界内，默认为false
---@return foundation.math.Vector2 三角形上最近的点
---@overload fun(self: foundation.shape.Triangle, point: foundation.math.Vector2): foundation.math.Vector2
function Triangle:closestPoint(point, boundary)
    if not boundary and self:contains(point) then
        return point:clone()
    end

    local edges = self:getEdges()
    local minDistance = math.huge
    local closestPoint

    for _, edge in ipairs(edges) do
        local edgeClosest = edge:closestPoint(point)
        local distance = (point - edgeClosest):length()

        if distance < minDistance then
            minDistance = distance
            closestPoint = edgeClosest
        end
    end

    return closestPoint
end

---计算点到三角形的距离
---@param point foundation.math.Vector2 要检查的点
---@return number 点到三角形的距离
function Triangle:distanceToPoint(point)
    if self:contains(point) then
        return 0
    end

    local edges = {
        Segment.create(self.point1, self.point2),
        Segment.create(self.point2, self.point3),
        Segment.create(self.point3, self.point1)
    }

    local minDistance = math.huge

    for i = 1, #edges do
        local distance = edges[i]:distanceToPoint(point)
        if distance < minDistance then
            minDistance = distance
        end
    end

    return minDistance
end

---将点投影到三角形平面上（2D中与closest相同）
---@param point foundation.math.Vector2 要投影的点
---@return foundation.math.Vector2 投影点
function Triangle:projectPoint(point)
    return self:closestPoint(point, true)
end

---检查点是否在三角形上
---@param point foundation.math.Vector2 要检查的点
---@param tolerance number|nil 容差，默认为1e-10
---@return boolean 点是否在三角形上
---@overload fun(self:foundation.shape.Triangle, point:foundation.math.Vector2): boolean
function Triangle:containsPoint(point, tolerance)
    tolerance = tolerance or 1e-10
    local edges = self:getEdges()
    for _, edge in ipairs(edges) do
        if edge:containsPoint(point, tolerance) then
            return true
        end
    end
    return false
end

---复制三角形
---@return foundation.shape.Triangle 三角形的副本
function Triangle:clone()
    return Triangle.create(self.point1:clone(), self.point2:clone(), self.point3:clone())
end

ffi.metatype("foundation_shape_Triangle", Triangle)

return Triangle
