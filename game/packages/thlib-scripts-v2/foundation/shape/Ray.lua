local ffi = require("ffi")

local type = type
local math = math
local tostring = tostring
local string = string
local rawset = rawset
local setmetatable = setmetatable

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
Ray.__type = "foundation.shape.Ray"

---@param self foundation.shape.Ray
---@param key any
---@return any
function Ray.__index(self, key)
    if key == "point" then
        return self.__data.point
    elseif key == "direction" then
        return self.__data.direction
    end
    return Ray[key]
end

---@param self foundation.shape.Ray
---@param key any
---@param value any
function Ray.__newindex(self, key, value)
    if key == "point" then
        self.__data.point = value
    elseif key == "direction" then
        self.__data.direction = value
    else
        rawset(self, key, value)
    end
end

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

    local ray = ffi.new("foundation_shape_Ray", point, direction)
    local result = {
        __data = ray,
    }
    ---@diagnostic disable-next-line: return-type-mismatch, missing-return-value
    return setmetatable(result, Ray)
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

---计算射线的中心
---@return foundation.math.Vector2
function Ray:getCenter()
    if math.abs(self.direction.x) < 1e-10 then
        return Vector2.create(0, math.huge)
    elseif math.abs(self.direction.y) < 1e-10 then
        return Vector2.create(math.huge, 0)
    end
    if self.direction.x > 0 and self.direction.y > 0 then
        return Vector2.create(math.huge, math.huge)
    elseif self.direction.x > 0 and self.direction.y < 0 then
        return Vector2.create(math.huge, -math.huge)
    elseif self.direction.x < 0 and self.direction.y > 0 then
        return Vector2.create(-math.huge, math.huge)
    else
        return Vector2.create(-math.huge, -math.huge)
    end
end

---获取射线的AABB包围盒
---@return number, number, number, number
function Ray:AABB()
    if math.abs(self.direction.x) < 1e-10 then
        -- 垂直线
        if self.direction.y > 0 then
            return self.point.x, self.point.x, self.point.y, math.huge
        else
            return self.point.x, self.point.x, -math.huge, self.point.y
        end
    elseif math.abs(self.direction.y) < 1e-10 then
        -- 水平线
        if self.direction.x > 0 then
            return self.point.x, math.huge, self.point.y, self.point.y
        else
            return -math.huge, self.point.x, self.point.y, self.point.y
        end
    else
        -- 斜线
        if self.direction.x > 0 and self.direction.y > 0 then
            return self.point.x, math.huge, self.point.y, math.huge
        elseif self.direction.x > 0 and self.direction.y < 0 then
            return self.point.x, math.huge, -math.huge, self.point.y
        elseif self.direction.x < 0 and self.direction.y > 0 then
            return -math.huge, self.point.x, self.point.y, math.huge
        else
            return -math.huge, self.point.x, -math.huge, self.point.y
        end
    end
end

---计算射线的包围盒宽高
---@return number, number
function Ray:getBoundingBoxSize()
    if math.abs(self.direction.x) < 1e-10 then
        return 0, math.huge
    elseif math.abs(self.direction.y) < 1e-10 then
        return math.huge, 0
    end
    return math.huge, math.huge
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

---缩放射线（更改当前射线）
---@param scale number|foundation.math.Vector2 缩放倍数
---@param center foundation.math.Vector2|nil 缩放中心点，默认为射线的起始点
---@return foundation.shape.Ray 自身引用
function Ray:scale(scale, center)
    local scaleX, scaleY
    if type(scale) == "number" then
        scaleX, scaleY = scale, scale
    else
        scaleX, scaleY = scale.x, scale.y
    end
    center = center or self.point

    local dx = self.point.x - center.x
    local dy = self.point.y - center.y
    self.point.x = center.x + dx * scaleX
    self.point.y = center.y + dy * scaleY
    return self
end

---获取缩放后的射线副本
---@param scale number|foundation.math.Vector2 缩放倍数
---@param center foundation.math.Vector2|nil 缩放中心点，默认为射线的起始点
---@return foundation.shape.Ray
function Ray:scaled(scale, center)
    local result = Ray.create(self.point:clone(), self.direction:clone())
    return result:scale(scale, center)
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

---复制射线
---@return foundation.shape.Ray 射线副本
function Ray:clone()
    return Ray.create(self.point:clone(), self.direction:clone())
end

ffi.metatype("foundation_shape_Ray", Ray)

return Ray
