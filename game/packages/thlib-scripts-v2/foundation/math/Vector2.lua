local ffi = require("ffi")

local type = type
local string = string
local math = math

local Vector3 = require("foundation.math.Vector3")
local Vector4 = require("foundation.math.Vector4")

ffi.cdef [[
typedef struct {
    double x;
    double y;
} foundation_math_Vector2;
]]

---@class foundation.math.Vector2
---@field x number X坐标分量
---@field y number Y坐标分量
local Vector2 = {}
Vector2.__index = Vector2
Vector2.__type = "foundation.math.Vector2"

---创建一个零向量
---@return foundation.math.Vector2 零向量
function Vector2.zero()
    return Vector2.create(0, 0)
end

---创建一个新的二维向量
---@param x number|nil X坐标分量，默认为0
---@param y number|nil Y坐标分量，默认为0
---@return foundation.math.Vector2 新创建的向量
function Vector2.create(x, y)
    ---@diagnostic disable-next-line: return-type-mismatch
    return ffi.new("foundation_math_Vector2", x or 0, y or 0)
end

---通过给定的弧度和长度创建一个新的二维向量
---@param rad number 弧度
---@param length number 向量长度
---@return foundation.math.Vector2 新创建的向量
function Vector2.createFromRad(rad, length)
    local x = length * math.cos(rad)
    local y = length * math.sin(rad)
    return Vector2.create(x, y)
end

---通过给定的角度和长度创建一个新的二维向量
---@param angle number 角度
---@param length number 向量长度
---@return foundation.math.Vector2 新创建的向量
function Vector2.createFromAngle(angle, length)
    local rad = math.rad(angle)
    return Vector2.createFromRad(rad, length)
end

---向量加法运算符重载
---@param a foundation.math.Vector2|number 第一个操作数
---@param b foundation.math.Vector2|number 第二个操作数
---@return foundation.math.Vector2 相加后的结果
function Vector2.__add(a, b)
    if type(a) == "number" then
        return Vector2.create(a + b.x, a + b.y)
    elseif type(b) == "number" then
        return Vector2.create(a.x + b, a.y + b)
    else
        return Vector2.create(a.x + b.x, a.y + b.y)
    end
end

---向量减法运算符重载
---@param a foundation.math.Vector2|number 第一个操作数
---@param b foundation.math.Vector2|number 第二个操作数
---@return foundation.math.Vector2 相减后的结果
function Vector2.__sub(a, b)
    if type(a) == "number" then
        return Vector2.create(a - b.x, a - b.y)
    elseif type(b) == "number" then
        return Vector2.create(a.x - b, a.y - b)
    else
        return Vector2.create(a.x - b.x, a.y - b.y)
    end
end

---向量乘法运算符重载
---@param a foundation.math.Vector2|number 第一个操作数
---@param b foundation.math.Vector2|number 第二个操作数
---@return foundation.math.Vector2 相乘后的结果
function Vector2.__mul(a, b)
    if type(a) == "number" then
        return Vector2.create(a * b.x, a * b.y)
    elseif type(b) == "number" then
        return Vector2.create(a.x * b, a.y * b)
    else
        return Vector2.create(a.x * b.x, a.y * b.y)
    end
end

---向量除法运算符重载
---@param a foundation.math.Vector2|number 第一个操作数
---@param b foundation.math.Vector2|number 第二个操作数
---@return foundation.math.Vector2 相除后的结果
function Vector2.__div(a, b)
    if type(a) == "number" then
        return Vector2.create(a / b.x, a / b.y)
    elseif type(b) == "number" then
        return Vector2.create(a.x / b, a.y / b)
    else
        return Vector2.create(a.x / b.x, a.y / b.y)
    end
end

---向量取负运算符重载
---@param v foundation.math.Vector2 操作数
---@return foundation.math.Vector2 取反后的向量
function Vector2.__unm(v)
    return Vector2.create(-v.x, -v.y)
end

---向量相等性比较运算符重载
---@param a foundation.math.Vector2 第一个操作数
---@param b foundation.math.Vector2 第二个操作数
---@return boolean 两个向量是否相等
function Vector2.__eq(a, b)
    return math.abs(a.x - b.x) < 1e-10 and math.abs(a.y - b.y) < 1e-10
end

---向量字符串表示
---@param v foundation.math.Vector2 操作数
---@return string 向量的字符串表示
function Vector2.__tostring(v)
    return string.format("Vector2(%f, %f)", v.x, v.y)
end

---获取向量长度
---@param v foundation.math.Vector2 操作数
---@return number 向量的长度
function Vector2.__len(v)
    return math.sqrt(v.x * v.x + v.y * v.y)
end

Vector2.length = Vector2.__len

---获取向量的副本
---@return foundation.math.Vector2 向量的副本
function Vector2:clone()
    return Vector2.create(self.x, self.y)
end

---获取向量的角度（弧度）
---@return number 向量的角度，单位为弧度
function Vector2:angle()
    return math.atan2(self.y, self.x)
end

---获取向量的角度（度）
---@return number 向量的角度，单位为度
function Vector2:degreeAngle()
    return math.deg(self:angle())
end

---计算两个向量的点积
---@param other foundation.math.Vector2 另一个向量
---@return number 两个向量的点积
function Vector2:dot(other)
    return self.x * other.x + self.y * other.y
end

---计算两个向量的叉积
---@param other foundation.math.Vector2 另一个向量
---@return number 两个向量的叉积
function Vector2:cross(other)
    return self.x * other.y - self.y * other.x
end

---将当前向量归一化（更改当前向量）
---@return foundation.math.Vector2 归一化后的向量（自身引用）
function Vector2:normalize()
    local len = self:length()
    if len > 0 then
        self.x = self.x / len
        self.y = self.y / len
    end
    return self
end

---获取向量的归一化副本
---@return foundation.math.Vector2 归一化后的向量副本
function Vector2:normalized()
    local len = self:length()
    if len == 0 then
        return Vector2.zero()
    end
    return Vector2.create(self.x / len, self.y / len)
end

---将当前向量旋转指定弧度（更改当前向量）
---@param rad number 旋转弧度
---@return foundation.math.Vector2 旋转后的向量（自身引用）
function Vector2:rotate(rad)
    local cos = math.cos(rad)
    local sin = math.sin(rad)
    local x = self.x * cos - self.y * sin
    local y = self.x * sin + self.y * cos
    self.x = x
    self.y = y
    return self
end

---将向量旋转指定角度（更改当前向量）
---@param angle number 旋转角度
---@return foundation.math.Vector2 旋转后的向量（自身引用）
function Vector2:degreeRotate(angle)
    angle = math.rad(angle)
    return self:rotate(angle)
end

---获取向量的旋转指定弧度的副本
---@param rad number 旋转弧度
---@return foundation.math.Vector2 旋转后的向量副本
function Vector2:rotated(rad)
    local cos = math.cos(rad)
    local sin = math.sin(rad)
    local x = self.x * cos - self.y * sin
    local y = self.x * sin + self.y * cos
    return Vector2.create(x, y)
end

---获取向量的旋转指定角度的副本
---@param angle number 旋转角度
---@return foundation.math.Vector2 旋转后的向量副本
function Vector2:degreeRotated(angle)
    angle = math.rad(angle)
    return self:rotated(angle)
end

---将Vector2转换为Vector3
---@param z number|nil Z坐标分量，默认为0
---@return foundation.math.Vector3 转换后的Vector3
function Vector2:toVector3(z)
    return Vector3.create(self.x, self.y, z or 0)
end

---将Vector2转换为Vector4
---@param z number|nil Z坐标分量，默认为0
---@param w number|nil W坐标分量，默认为0
---@return foundation.math.Vector4 转换后的Vector4
function Vector2:toVector4(z, w)
    return Vector4.create(self.x, self.y, z or 0, w or 0)
end

--region LuaSTG Evo API
do
    Vector2.LuaSTG = Vector2.length
    Vector2.Angle = Vector2.degreeAngle

    ---归一化向量（LuaSTG Evo 兼容）
    ---@return foundation.math.Vector2 归一化后的向量副本
    function Vector2:Normalize()
        self:normalize()
        return Vector2.create(self.x, self.y)
    end

    Vector2.Normalized = Vector2.normalized
    Vector2.Dot = Vector2.dot

    local lstg = require("lstg")
    lstg.Vector2 = Vector2.create
end
--endregion

ffi.metatype("foundation_math_Vector2", Vector2)

return Vector2