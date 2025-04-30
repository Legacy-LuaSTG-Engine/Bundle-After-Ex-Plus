local ffi = require("ffi")

local type = type
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
    if dist <= 1e-10 then
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

---获取射线的角度（弧度）
---@return number 射线的角度，单位为弧度
function Ray:angle()
    return math.atan2(self.direction.y, self.direction.x)
end

---获取射线的角度（度）
---@return number 射线的角度，单位为度
function Ray:degreeAngle()
    return math.deg(self:angle())
end

---平移射线（更改当前射线）
---@param v foundation.math.Vector2 | number 移动距离
---@return foundation.shape.Ray 平移后的射线（自身引用）
function Ray:move(v)
    local moveX, moveY
    if type(v) == "number" then
        moveX = v
        moveY = v
    else
        moveX = v.x
        moveY = v.y
    end
    self.point.x = self.point.x + moveX
    self.point.y = self.point.y + moveY
    return self
end

---获取当前射线平移指定距离的副本
---@param v foundation.math.Vector2 | number 移动距离
---@return foundation.shape.Ray 移动后的射线副本
function Ray:moved(v)
    local moveX, moveY
    if type(v) == "number" then
        moveX = v
        moveY = v
    else
        moveX = v.x
        moveY = v.y
    end
    return Ray.create(
            Vector2.create(self.point.x + moveX, self.point.y + moveY),
            self.direction:clone()
    )
end

---将当前射线旋转指定弧度（更改当前射线）
---@param rad number 旋转弧度
---@param center foundation.math.Vector2 旋转中心
---@return foundation.shape.Ray 旋转后的射线（自身引用）
---@overload fun(self:foundation.shape.Ray, rad:number): foundation.shape.Ray 将射线绕起始点旋转指定弧度
function Ray:rotate(rad, center)
    center = center or self.point
    local cosRad = math.cos(rad)
    local sinRad = math.sin(rad)
    local v = self.direction
    local x = v.x * cosRad - v.y * sinRad
    local y = v.x * sinRad + v.y * cosRad
    self.direction.x = x
    self.direction.y = y
    return self
end

---将当前射线旋转指定角度（更改当前射线）
---@param angle number 旋转角度
---@param center foundation.math.Vector2 旋转中心
---@return foundation.shape.Ray 旋转后的射线（自身引用）
---@overload fun(self:foundation.shape.Ray, angle:number): foundation.shape.Ray 将射线绕起始点旋转指定角度
function Ray:degreeRotate(angle, center)
    angle = math.rad(angle)
    return self:rotate(angle, center)
end

---获取当前射线旋转指定弧度的副本
---@param rad number 旋转弧度
---@param center foundation.math.Vector2 旋转中心
---@return foundation.shape.Ray 旋转后的射线副本
---@overload fun(self:foundation.shape.Ray, rad:number): foundation.shape.Ray 将射线绕起始点旋转指定弧度
function Ray:rotated(rad, center)
    center = center or self.point
    local cosRad = math.cos(rad)
    local sinRad = math.sin(rad)
    local v = self.direction
    return Ray.create(
            Vector2.create(v.x * cosRad - v.y * sinRad + center.x, v.x * sinRad + v.y * cosRad + center.y),
            Vector2.create(v.x * cosRad - v.y * sinRad, v.x * sinRad + v.y * cosRad)
    )
end

---获取当前射线旋转指定角度的副本
---@param angle number 旋转角度
---@param center foundation.math.Vector2 旋转中心
---@return foundation.shape.Ray 旋转后的射线副本
---@overload fun(self:foundation.shape.Ray, angle:number): foundation.shape.Ray 将射线绕起始点旋转指定角度
function Ray:degreeRotated(angle, center)
    angle = math.rad(angle)
    return self:rotated(angle, center)
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

---计算点到射线的最近点
---@param point foundation.math.Vector2 点
---@return foundation.math.Vector2 最近点
function Ray:closestPoint(point)
    local dir = self.direction:normalized()
    local point_vec = point - self.point
    local proj_length = point_vec:dot(dir)

    if proj_length <= 0 then
        return self.point:clone()
    else
        return self.point + dir * proj_length
    end
end

---计算点到射线的距离
---@param point foundation.math.Vector2 点
---@return number 距离
function Ray:distanceToPoint(point)
    local point_vec = point - self.point
    local proj_length = point_vec:dot(self.direction)

    if proj_length <= 1e-10 then
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
    if proj_length <= 1e-10 then
        return false
    end

    local cross = point_vec:cross(self.direction)
    return math.abs(cross) <= tolerance
end

---获取点在射线所在直线上的投影
---@param point foundation.math.Vector2 点
---@return foundation.math.Vector2 投影点
function Ray:projectPoint(point)
    local dir = self.direction
    local t = ((point.x - self.point.x) * dir.x + (point.y - self.point.y) * dir.y)
    return Vector2.create(self.point.x + t * dir.x, self.point.y + t * dir.y)
end

ffi.metatype("foundation_shape_Ray", Ray)

return Ray
