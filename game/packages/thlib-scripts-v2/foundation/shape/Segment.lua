local ffi = require("ffi")

local type = type
local tostring = tostring
local string = string
local math = math
local rawset = rawset
local setmetatable = setmetatable

local Vector2 = require("foundation.math.Vector2")
local ShapeIntersector = require("foundation.shape.ShapeIntersector")

ffi.cdef [[
typedef struct {
    foundation_math_Vector2 point1, point2;
} foundation_shape_Segment;
]]

---@class foundation.shape.Segment
---@field point1 foundation.math.Vector2
---@field point2 foundation.math.Vector2
local Segment = {}
Segment.__type = "foundation.shape.Segment"

---@param self foundation.shape.Segment
---@param key any
---@return any
function Segment.__index(self, key)
    if key == "point1" then
        return self.__data.point1
    elseif key == "point2" then
        return self.__data.point2
    end
    return Segment[key]
end

---@param self foundation.shape.Segment
---@param key any
---@param value any
function Segment.__newindex(self, key, value)
    if key == "point1" then
        self.__data.point1 = value
    elseif key == "point2" then
        self.__data.point2 = value
    else
        rawset(self, key, value)
    end
end

---创建一个线段
---@param point1 foundation.math.Vector2 线段的起点
---@param point2 foundation.math.Vector2 线段的终点
---@return foundation.shape.Segment
function Segment.create(point1, point2)
    local segment = ffi.new("foundation_shape_Segment", point1, point2)
    local result = {
        __data = segment,
    }
    ---@diagnostic disable-next-line: return-type-mismatch, missing-return-value
    return setmetatable(result, Segment)
end

---根据给定点和弧度与长度创建线段
---@param point foundation.math.Vector2 线段的起点
---@param rad number 线段的弧度
---@param length number 线段的长度
---@return foundation.shape.Segment
function Segment.createFromRad(point, rad, length)
    local v2 = Vector2.create(point.x + math.cos(rad) * length, point.y + math.sin(rad) * length)
    return Segment.create(point, v2)
end

---根据给定点和角度与长度创建线段
---@param point foundation.math.Vector2 线段的起点
---@param angle number 线段的角度
---@param length number 线段的长度
---@return foundation.shape.Segment
function Segment.createFromAngle(point, angle, length)
    local rad = math.rad(angle)
    return Segment.createFromRad(point, rad, length)
end

---线段相等比较
---@param a foundation.shape.Segment 第一个线段
---@param b foundation.shape.Segment 第二个线段
---@return boolean 如果两个线段的所有顶点都相等则返回true，否则返回false
function Segment.__eq(a, b)
    return a.point1 == b.point1 and a.point2 == b.point2
end

---线段转字符串表示
---@param self foundation.shape.Segment
---@return string 线段的字符串表示
function Segment.__tostring(self)
    return string.format("Line(%s, %s)", tostring(self.point1), tostring(self.point2))
end

---将线段转换为向量
---@return foundation.math.Vector2 从起点到终点的向量
function Segment:toVector2()
    return self.point2 - self.point1
end

---获取线段的法向量
---@return foundation.math.Vector2 线段的单位法向量
function Segment:normal()
    local dir = self.point2 - self.point1
    local len = dir:length()
    if len <= 1e-10 then
        return Vector2.zero()
    end
    return Vector2.create(-dir.y / len, dir.x / len)
end

---获取线段的长度
---@return number 线段的长度
function Segment:length()
    return self:toVector2():length()
end

---获取线段的中点
---@return foundation.math.Vector2 线段的中点
function Segment:midpoint()
    return Vector2.create((self.point1.x + self.point2.x) / 2, (self.point1.y + self.point2.y) / 2)
end

---获取线段的角度（弧度）
---@return number 线段的角度，单位为弧度
function Segment:angle()
    return math.atan2(self.point2.y - self.point1.y, self.point2.x - self.point1.x)
end

---计算线段的中心
---@return foundation.math.Vector2 线段的中心
function Segment:getCenter()
    return self:midpoint()
end

---计算线段的包围盒宽高
---@return number, number 线段的宽度和高度
function Segment:getBoundingBoxSize()
    local minX = math.min(self.point1.x, self.point2.x)
    local maxX = math.max(self.point1.x, self.point2.x)
    local minY = math.min(self.point1.y, self.point2.y)
    local maxY = math.max(self.point1.y, self.point2.y)
    return maxX - minX, maxY - minY
end

---获取线段的角度（度）
---@return number 线段的角度，单位为度
function Segment:degreeAngle()
    return math.deg(self:angle())
end

---平移线段（更改当前线段）
---@param v foundation.math.Vector2 | number 移动距离
---@return foundation.shape.Segment 平移后的线段（自身引用）
function Segment:move(v)
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
    return self
end

---获取当前线段平移指定距离的副本
---@param v foundation.math.Vector2 | number 移动距离
---@return foundation.shape.Segment 移动后的线段副本
function Segment:moved(v)
    local moveX, moveY
    if type(v) == "number" then
        moveX, moveY = v, v
    else
        moveX, moveY = v.x, v.y
    end
    return Segment.create(
            Vector2.create(self.point1.x + moveX, self.point1.y + moveY),
            Vector2.create(self.point2.x + moveX, self.point2.y + moveY)
    )
end

---将当前线段旋转指定弧度（更改当前线段）
---@param rad number 旋转弧度
---@param center foundation.math.Vector2 旋转中心
---@return foundation.shape.Segment 旋转后的线段（自身引用）
---@overload fun(self:foundation.shape.Segment, rad:number): foundation.shape.Segment 将线段绕中点旋转指定弧度
function Segment:rotate(rad, center)
    center = center or self:midpoint()
    local cosRad = math.cos(rad)
    local sinRad = math.sin(rad)
    local v1 = self.point1 - center
    local v2 = self.point2 - center
    self.point1.x = v1.x * cosRad - v1.y * sinRad + center.x
    self.point1.y = v1.x * sinRad + v1.y * cosRad + center.y
    self.point2.x = v2.x * cosRad - v2.y * sinRad + center.x
    self.point2.y = v2.x * sinRad + v2.y * cosRad + center.y
    return self
end

---将当前线段旋转指定角度（更改当前线段）
---@param angle number 旋转角度
---@param center foundation.math.Vector2 旋转中心
---@return foundation.shape.Segment 旋转后的线段（自身引用）
---@overload fun(self:foundation.shape.Segment, angle:number): foundation.shape.Segment 将线段绕中点旋转指定角度
function Segment:degreeRotate(angle, center)
    angle = math.rad(angle)
    return self:rotate(angle, center)
end

---获取当前线段旋转指定弧度的副本
---@param rad number 旋转弧度
---@param center foundation.math.Vector2 旋转中心
---@return foundation.shape.Segment 旋转后的线段副本
---@overload fun(self:foundation.shape.Segment, rad:number): foundation.shape.Segment 将线段绕中点旋转指定弧度
function Segment:rotated(rad, center)
    center = center or self:midpoint()
    local cosRad = math.cos(rad)
    local sinRad = math.sin(rad)
    local v1 = self.point1 - center
    local v2 = self.point2 - center
    return Segment.create(
            Vector2.create(v1.x * cosRad - v1.y * sinRad + center.x, v1.x * sinRad + v1.y * cosRad + center.y),
            Vector2.create(v2.x * cosRad - v2.y * sinRad + center.x, v2.x * sinRad + v2.y * cosRad + center.y)
    )
end

---获取当前线段旋转指定角度的副本
---@param angle number 旋转角度
---@param center foundation.math.Vector2 旋转中心
---@return foundation.shape.Segment 旋转后的线段副本
---@overload fun(self:foundation.shape.Segment, angle:number): foundation.shape.Segment 将线段绕中点旋转指定角度
function Segment:degreeRotated(angle, center)
    angle = math.rad(angle)
    return self:rotated(angle, center)
end

---将当前线段缩放指定倍数（更改当前线段）
---@param scale number|foundation.math.Vector2 缩放倍数
---@param center foundation.math.Vector2 缩放中心
---@return foundation.shape.Segment 缩放后的线段（自身引用）
---@overload fun(self: foundation.shape.Segment, scale: number): foundation.shape.Segment 相对线段中点缩放指定倍数
function Segment:scale(scale, center)
    local scaleX, scaleY
    if type(scale) == "number" then
        scaleX, scaleY = scale, scale
    else
        scaleX, scaleY = scale.x, scale.y
    end
    center = center or self:midpoint()
    self.point1.x = (self.point1.x - center.x) * scaleX + center.x
    self.point1.y = (self.point1.y - center.y) * scaleY + center.y
    self.point2.x = (self.point2.x - center.x) * scaleX + center.x
    self.point2.y = (self.point2.y - center.y) * scaleY + center.y
    return self
end

---获取线段的缩放指定倍数的副本
---@param scale number|foundation.math.Vector2 缩放倍数
---@param center foundation.math.Vector2 缩放中心
---@return foundation.shape.Segment 缩放后的线段副本
---@overload fun(self: foundation.shape.Segment, scale: number): foundation.shape.Segment 相对线段中点缩放指定倍数
function Segment:scaled(scale, center)
    local scaleX, scaleY
    if type(scale) == "number" then
        scaleX, scaleY = scale, scale
    else
        scaleX, scaleY = scale.x, scale.y
    end
    center = center or self:midpoint()
    return Segment.create(
            Vector2.create((self.point1.x - center.x) * scaleX + center.x, (self.point1.y - center.y) * scaleY + center.y),
            Vector2.create((self.point2.x - center.x) * scaleX + center.x, (self.point2.y - center.y) * scaleY + center.y)
    )
end

---检查与其他形状的相交
---@param other any
---@return boolean, foundation.math.Vector2[] | nil
function Segment:intersects(other)
    return ShapeIntersector.intersect(self, other)
end

---仅检查线段是否与其他形状相交，不返回相交点
---@param other any 其他的形状
---@return boolean
function Segment:hasIntersection(other)
    return ShapeIntersector.hasIntersection(self, other)
end

---计算点到线段的最近点
---@param point foundation.math.Vector2 要检查的点
---@return foundation.math.Vector2 线段上最近的点
function Segment:closestPoint(point)
    local dir = self.point2 - self.point1
    local len = dir:length()
    if len <= 1e-10 then
        return self.point1:clone()
    end

    local t = ((point.x - self.point1.x) * dir.x + (point.y - self.point1.y) * dir.y) / (len * len)
    t = math.max(0, math.min(1, t))

    return Vector2.create(self.point1.x + t * dir.x, self.point1.y + t * dir.y)
end

---计算点到线段的距离
---@param point foundation.math.Vector2 要检查的点
---@return number 点到线段的距离
function Segment:distanceToPoint(point)
    local closest = self:closestPoint(point)
    return (point - closest):length()
end

---将点投影到线段所在的直线上
---@param point foundation.math.Vector2 要投影的点
---@return foundation.math.Vector2 投影点
function Segment:projectPoint(point)
    local dir = self.point2 - self.point1
    local len = dir:length()
    if len <= 1e-10 then
        return self.point1:clone()
    end

    local t = ((point.x - self.point1.x) * dir.x + (point.y - self.point1.y) * dir.y) / (len * len)
    return Vector2.create(self.point1.x + t * dir.x, self.point1.y + t * dir.y)
end

---检查点是否在线段上
---@param point foundation.math.Vector2 要检查的点
---@param tolerance number|nil 容差，默认为1e-10
---@return boolean 点是否在线段上
---@overload fun(self:foundation.shape.Segment, point:foundation.math.Vector2): boolean
function Segment:containsPoint(point, tolerance)
    tolerance = tolerance or 1e-10
    local dist = self:distanceToPoint(point)
    if dist > tolerance then
        return false
    end

    local dir = self.point2 - self.point1
    local len = dir:length()
    if len <= 1e-10 then
        return point == self.point1
    end

    local t = ((point.x - self.point1.x) * dir.x + (point.y - self.point1.y) * dir.y) / (len * len)
    return t >= 0 and t <= 1
end

ffi.metatype("foundation_shape_Segment", Segment)

return Segment
