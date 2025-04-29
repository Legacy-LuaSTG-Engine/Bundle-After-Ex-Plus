local ffi = require("ffi")

local type = type
local tostring = tostring
local string = string
local math = math

local Vector2 = require("foundation.math.Vector2")

ffi.cdef [[
typedef struct {
    Vector2 v1, v2, v3;
} Triangle;
]]

---@class foundation.shape.Triangle
---@field v1 foundation.math.Vector2 三角形的第一个顶点
---@field v2 foundation.math.Vector2 三角形的第二个顶点
---@field v3 foundation.math.Vector2 三角形的第三个顶点
local Triangle = {}
Triangle.__index = Triangle

---创建一个新的三角形
---@param v1 foundation.math.Vector2 三角形的第一个顶点
---@param v2 foundation.math.Vector2 三角形的第二个顶点
---@param v3 foundation.math.Vector2 三角形的第三个顶点
---@return foundation.shape.Triangle 新创建的三角形
function Triangle.create(v1, v2, v3)
    ---@diagnostic disable-next-line: return-type-mismatch
    return ffi.new("Triangle", v1, v2, v3)
end

---三角形加法运算，可以是三角形与三角形相加，或者三角形与标量相加
---@param a foundation.shape.Triangle|number 第一个操作数
---@param b foundation.shape.Triangle|number 第二个操作数
---@return foundation.shape.Triangle 相加后的三角形
function Triangle.__add(a, b)
    if type(a) == "number" then
        return Triangle.create(a + b.v1, a + b.v2, a + b.v3)
    elseif type(b) == "number" then
        return Triangle.create(a.v1 + b, a.v2 + b, a.v3 + b)
    else
        return Triangle.create(a.v1 + b.v1, a.v2 + b.v2, a.v3 + b.v3)
    end
end

---三角形减法运算，可以是三角形与三角形相减，或者三角形与标量相减
---@param a foundation.shape.Triangle|number 第一个操作数
---@param b foundation.shape.Triangle|number 第二个操作数
---@return foundation.shape.Triangle 相减后的三角形
function Triangle.__sub(a, b)
    if type(a) == "number" then
        return Triangle.create(a - b.v1, a - b.v2, a - b.v3)
    elseif type(b) == "number" then
        return Triangle.create(a.v1 - b, a.v2 - b, a.v3 - b)
    else
        return Triangle.create(a.v1 - b.v1, a.v2 - b.v2, a.v3 - b.v3)
    end
end

---三角形乘法运算，可以是三角形与三角形相乘，或者三角形与标量相乘
---@param a foundation.shape.Triangle|number 第一个操作数
---@param b foundation.shape.Triangle|number 第二个操作数
---@return foundation.shape.Triangle 相乘后的三角形
function Triangle.__mul(a, b)
    if type(a) == "number" then
        return Triangle.create(a * b.v1, a * b.v2, a * b.v3)
    elseif type(b) == "number" then
        return Triangle.create(a.v1 * b, a.v2 * b, a.v3 * b)
    else
        return Triangle.create(a.v1 * b.v1, a.v2 * b.v2, a.v3 * b.v3)
    end
end

---三角形除法运算，可以是三角形与三角形相除，或者三角形与标量相除
---@param a foundation.shape.Triangle|number 第一个操作数
---@param b foundation.shape.Triangle|number 第二个操作数
---@return foundation.shape.Triangle 相除后的三角形
function Triangle.__div(a, b)
    if type(a) == "number" then
        return Triangle.create(a / b.v1, a / b.v2, a / b.v3)
    elseif type(b) == "number" then
        return Triangle.create(a.v1 / b, a.v2 / b, a.v3 / b)
    else
        return Triangle.create(a.v1 / b.v1, a.v2 / b.v2, a.v3 / b.v3)
    end
end

---三角形取反运算
---@param t foundation.shape.Triangle 要取反的三角形
---@return foundation.shape.Triangle 取反后的三角形
function Triangle.__unm(t)
    return Triangle.create(-t.v1, -t.v2, -t.v3)
end

---三角形相等比较
---@param a foundation.shape.Triangle 第一个三角形
---@param b foundation.shape.Triangle 第二个三角形
---@return boolean 如果两个三角形的所有顶点都相等则返回true，否则返回false
function Triangle.__eq(a, b)
    return a.v1 == b.v1 and a.v2 == b.v2 and a.v3 == b.v3
end

---三角形转字符串表示
---@param t foundation.shape.Triangle 要转换的三角形
---@return string 三角形的字符串表示
function Triangle.__tostring(t)
    return string.format("Triangle(%s, %s, %s)", tostring(t.v1), tostring(t.v2), tostring(t.v3))
end

---计算三角形的面积
---@return number 三角形的面积
function Triangle:area()
    local v2v1 = self.v2 - self.v1
    local v3v1 = self.v3 - self.v1
    return 0.5 * math.abs(v2v1:cross(v3v1))
end

---计算三角形的重心
---@return foundation.math.Vector2 三角形的重心
function Triangle:centroid()
    return (self.v1 + self.v2 + self.v3) / 3
end

---计算三角形的外接圆半径
---@return number 三角形的外接圆半径
function Triangle:circumradius()
    local center = self:circumcenter()
    if center then
        return (center - self.v1):length()
    end
    return 0
end

---计算三角形的内切圆半径
---@return number 三角形的内切圆半径
function Triangle:inradius()
    local a = (self.v2 - self.v3):length()
    local b = (self.v1 - self.v3):length()
    local c = (self.v1 - self.v2):length()
    return self:area() / ((a + b + c) / 2)
end

---计算三角形的外心
---@return foundation.math.Vector2 | nil 三角形的外心
function Triangle:circumcenter()
    local x1, y1 = self.v1.x, self.v1.y
    local x2, y2 = self.v2.x, self.v2.y
    local x3, y3 = self.v3.x, self.v3.y

    local D = x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2)
    if math.abs(D) < 1e-10 then
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
    local a = (self.v2 - self.v3):length()
    local b = (self.v1 - self.v3):length()
    local c = (self.v1 - self.v2):length()

    local p = (a * self.v1 + b * self.v2 + c * self.v3) / (a + b + c)
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
    self.v1.x = self.v1.x + moveX
    self.v1.y = self.v1.y + moveY
    self.v2.x = self.v2.x + moveX
    self.v2.y = self.v2.y + moveY
    self.v3.x = self.v3.x + moveX
    self.v3.y = self.v3.y + moveY
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
            Vector2.create(self.v1.x + moveX, self.v1.y + moveY),
            Vector2.create(self.v2.x + moveX, self.v2.y + moveY),
            Vector2.create(self.v3.x + moveX, self.v3.y + moveY)
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
    local v1 = self.v1 - center
    local v2 = self.v2 - center
    local v3 = self.v3 - center
    self.v1.x = v1.x * cosAngle - v1.y * sinAngle + center.x
    self.v1.y = v1.x * sinAngle + v1.y * cosAngle + center.y
    self.v2.x = v2.x * cosAngle - v2.y * sinAngle + center.x
    self.v2.y = v2.x * sinAngle + v2.y * cosAngle + center.y
    self.v3.x = v3.x * cosAngle - v3.y * sinAngle + center.x
    self.v3.y = v3.x * sinAngle + v3.y * cosAngle + center.y
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
    local v1 = self.v1 - center
    local v2 = self.v2 - center
    local v3 = self.v3 - center
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
    self.v1.x = (self.v1.x - center.x) * scaleX + center.x
    self.v1.y = (self.v1.y - center.y) * scaleY + center.y
    self.v2.x = (self.v2.x - center.x) * scaleX + center.x
    self.v2.y = (self.v2.y - center.y) * scaleY + center.y
    self.v3.x = (self.v3.x - center.x) * scaleX + center.x
    self.v3.y = (self.v3.y - center.y) * scaleY + center.y
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
            Vector2.create((self.v1.x - center.x) * scaleX + center.x, (self.v1.y - center.y) * scaleY + center.y),
            Vector2.create((self.v2.x - center.x) * scaleX + center.x, (self.v2.y - center.y) * scaleY + center.y),
            Vector2.create((self.v3.x - center.x) * scaleX + center.x, (self.v3.y - center.y) * scaleY + center.y)
    )
end

---判断点是否在三角形内（包括边界）
---@param point foundation.math.Vector2 要检查的点
---@return boolean 如果点在三角形内（包括边界）返回true，否则返回false
function Triangle:contains(point)
    local v3v1 = self.v3 - self.v1
    local v2v1 = self.v2 - self.v1
    local pv1 = point - self.v1

    local dot00 = v3v1:dot(v3v1)
    local dot01 = v3v1:dot(v2v1)
    local dot02 = v3v1:dot(pv1)
    local dot11 = v2v1:dot(v2v1)
    local dot12 = v2v1:dot(pv1)

    local invDenom = 1 / (dot00 * dot11 - dot01 * dot01)
    local u = (dot11 * dot02 - dot01 * dot12) * invDenom
    local v = (dot00 * dot12 - dot01 * dot02) * invDenom

    return (u >= 0) and (v >= 0) and (u + v <= 1)
end

ffi.metatype("Triangle", Triangle)

return Triangle