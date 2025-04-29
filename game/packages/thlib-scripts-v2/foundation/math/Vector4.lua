local ffi = require("ffi")

local type = type
local string = string
local math = math

ffi.cdef [[
typedef struct {
    double x;
    double y;
    double z;
    double w;
} foundation_math_Vector4;
]]

---@class foundation.math.Vector4
---@field x number X坐标分量
---@field y number Y坐标分量
---@field z number Z坐标分量
---@field w number W坐标分量
local Vector4 = {}
Vector4.__index = Vector4
Vector4.__type = "foundation.math.Vector4"

---创建一个零向量
---@return foundation.math.Vector4 零向量
function Vector4.zero()
    return Vector4.create(0, 0, 0, 0)
end

---创建一个新的四维向量
---@param x number|nil X坐标分量，默认为0
---@param y number|nil Y坐标分量，默认为0
---@param z number|nil Z坐标分量，默认为0
---@param w number|nil W坐标分量，默认为0
---@return foundation.math.Vector4 新创建的向量
function Vector4.create(x, y, z, w)
    ---@diagnostic disable-next-line: return-type-mismatch
    return ffi.new("foundation_math_Vector4", x or 0, y or 0, z or 0, w or 0)
end

---向量加法运算符重载
---@param a foundation.math.Vector4|number 第一个操作数
---@param b foundation.math.Vector4|number 第二个操作数
---@return foundation.math.Vector4 相加后的结果
function Vector4.__add(a, b)
    if type(a) == "number" then
        return Vector4.create(a + b.x, a + b.y, a + b.z, a + b.w)
    elseif type(b) == "number" then
        return Vector4.create(a.x + b, a.y + b, a.z + b, a.w + b)
    else
        return Vector4.create(a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w)
    end
end

---向量减法运算符重载
---@param a foundation.math.Vector4|number 第一个操作数
---@param b foundation.math.Vector4|number 第二个操作数
---@return foundation.math.Vector4 相减后的结果
function Vector4.__sub(a, b)
    if type(a) == "number" then
        return Vector4.create(a - b.x, a - b.y, a - b.z, a - b.w)
    elseif type(b) == "number" then
        return Vector4.create(a.x - b, a.y - b, a.z - b, a.w - b)
    else
        return Vector4.create(a.x - b.x, a.y - b.y, a.z - b.z, a.w - b.w)
    end
end

---向量乘法运算符重载
---@param a foundation.math.Vector4|number 第一个操作数
---@param b foundation.math.Vector4|number 第二个操作数
---@return foundation.math.Vector4 相乘后的结果
function Vector4.__mul(a, b)
    if type(a) == "number" then
        return Vector4.create(a * b.x, a * b.y, a * b.z, a * b.w)
    elseif type(b) == "number" then
        return Vector4.create(a.x * b, a.y * b, a.z * b, a.w * b)
    else
        return Vector4.create(a.x * b.x, a.y * b.y, a.z * b.z, a.w * b.w)
    end
end

---向量除法运算符重载
---@param a foundation.math.Vector4|number 第一个操作数
---@param b foundation.math.Vector4|number 第二个操作数
---@return foundation.math.Vector4 相除后的结果
function Vector4.__div(a, b)
    if type(a) == "number" then
        return Vector4.create(a / b.x, a / b.y, a / b.z, a / b.w)
    elseif type(b) == "number" then
        return Vector4.create(a.x / b, a.y / b, a.z / b, a.w / b)
    else
        return Vector4.create(a.x / b.x, a.y / b.y, a.z / b.z, a.w / b.w)
    end
end

---向量取负运算符重载
---@param v foundation.math.Vector4 操作数
---@return foundation.math.Vector4 取反后的向量
function Vector4.__unm(v)
    return Vector4.create(-v.x, -v.y, -v.z, -v.w)
end

---向量相等性比较运算符重载
---@param a foundation.math.Vector4 第一个操作数
---@param b foundation.math.Vector4 第二个操作数
---@return boolean 两个向量是否相等
function Vector4.__eq(a, b)
    return a.x == b.x and a.y == b.y and a.z == b.z and a.w == b.w
end

---向量字符串表示
---@param v foundation.math.Vector4 操作数
---@return string 向量的字符串表示
function Vector4.__tostring(v)
    return string.format("Vector4(%f, %f, %f, %f)", v.x, v.y, v.z, v.w)
end

---获取向量长度
---@param v foundation.math.Vector4 操作数
---@return number 向量的长度
function Vector4.__len(v)
    return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z + v.w * v.w)
end
Vector4.length = Vector4.__len

---获取向量的副本
---@return foundation.math.Vector4 向量的副本
function Vector4:clone()
    return Vector4.create(self.x, self.y, self.z, self.w)
end

---计算两个向量的点积
---@param other foundation.math.Vector4 另一个向量
---@return number 两个向量的点积
function Vector4:dot(other)
    return self.x * other.x + self.y * other.y + self.z * other.z + self.w * other.w
end

---将当前向量归一化（更改当前向量）
---@return foundation.math.Vector4 归一化后的向量（自身引用）
function Vector4:normalize()
    local len = self:length()
    if len > 0 then
        self.x = self.x / len
        self.y = self.y / len
        self.z = self.z / len
        self.w = self.w / len
    end
    return self
end

---获取向量的归一化副本
---@return foundation.math.Vector4 归一化后的向量副本
function Vector4:normalized()
    local len = self:length()
    if len == 0 then
        return Vector4.zero()
    end
    return Vector4.create(self.x / len, self.y / len, self.z / len, self.w / len)
end

ffi.metatype("foundation_math_Vector4", Vector4)

return Vector4