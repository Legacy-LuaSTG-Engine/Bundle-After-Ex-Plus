local ffi = require("ffi")

local type = type
local string = string
local math = math

ffi.cdef [[
typedef struct {
    double x;
    double y;
    double z;
} foundation_math_Vector3;
]]

---@class foundation.math.Vector3
---@field x number X坐标分量
---@field y number Y坐标分量
---@field z number Z坐标分量
local Vector3 = {}
Vector3.__index = Vector3
Vector3.__type = "foundation.math.Vector3"

---创建一个零向量
---@return foundation.math.Vector3 零向量
function Vector3.zero()
    return Vector3.create(0, 0, 0)
end

---创建一个新的三维向量
---@param x number|nil X坐标分量，默认为0
---@param y number|nil Y坐标分量，默认为0
---@param z number|nil Z坐标分量，默认为0
---@return foundation.math.Vector3 新创建的向量
function Vector3.create(x, y, z)
    ---@diagnostic disable-next-line: return-type-mismatch
    return ffi.new("foundation_math_Vector3", x or 0, y or 0, z or 0)
end

---向量加法运算符重载
---@param a foundation.math.Vector3|number 第一个操作数
---@param b foundation.math.Vector3|number 第二个操作数
---@return foundation.math.Vector3 相加后的结果
function Vector3.__add(a, b)
    if type(a) == "number" then
        return Vector3.create(a + b.x, a + b.y, a + b.z)
    elseif type(b) == "number" then
        return Vector3.create(a.x + b, a.y + b, a.z + b)
    else
        return Vector3.create(a.x + b.x, a.y + b.y, a.z + b.z)
    end
end

---向量减法运算符重载
---@param a foundation.math.Vector3|number 第一个操作数
---@param b foundation.math.Vector3|number 第二个操作数
---@return foundation.math.Vector3 相减后的结果
function Vector3.__sub(a, b)
    if type(a) == "number" then
        return Vector3.create(a - b.x, a - b.y, a - b.z)
    elseif type(b) == "number" then
        return Vector3.create(a.x - b, a.y - b, a.z - b)
    else
        return Vector3.create(a.x - b.x, a.y - b.y, a.z - b.z)
    end
end

---向量乘法运算符重载
---@param a foundation.math.Vector3|number 第一个操作数
---@param b foundation.math.Vector3|number 第二个操作数
---@return foundation.math.Vector3 相乘后的结果
function Vector3.__mul(a, b)
    if type(a) == "number" then
        return Vector3.create(a * b.x, a * b.y, a * b.z)
    elseif type(b) == "number" then
        return Vector3.create(a.x * b, a.y * b, a.z * b)
    else
        return Vector3.create(a.x * b.x, a.y * b.y, a.z * b.z)
    end
end

---向量除法运算符重载
---@param a foundation.math.Vector3|number 第一个操作数
---@param b foundation.math.Vector3|number 第二个操作数
---@return foundation.math.Vector3 相除后的结果
function Vector3.__div(a, b)
    if type(a) == "number" then
        return Vector3.create(a / b.x, a / b.y, a / b.z)
    elseif type(b) == "number" then
        return Vector3.create(a.x / b, a.y / b, a.z / b)
    else
        return Vector3.create(a.x / b.x, a.y / b.y, a.z / b.z)
    end
end

---向量取负运算符重载
---@param v foundation.math.Vector3 操作数
---@return foundation.math.Vector3 取反后的向量
function Vector3.__unm(v)
    return Vector3.create(-v.x, -v.y, -v.z)
end

---向量相等性比较运算符重载
---@param a foundation.math.Vector3 第一个操作数
---@param b foundation.math.Vector3 第二个操作数
---@return boolean 两个向量是否相等
function Vector3.__eq(a, b)
    return math.abs(a.x - b.x) < 1e-10 and
            math.abs(a.y - b.y) < 1e-10 and
            math.abs(a.z - b.z) < 1e-10
end

---向量字符串表示
---@param v foundation.math.Vector3 操作数
---@return string 向量的字符串表示
function Vector3.__tostring(v)
    return string.format("Vector3(%f, %f, %f)", v.x, v.y, v.z)
end

---获取向量长度
---@param v foundation.math.Vector3 操作数
---@return number 向量的长度
function Vector3.__len(v)
    return math.sqrt(v.x * v.x + v.y * v.y + v.z * v.z)
end
Vector3.length = Vector3.__len

---获取向量的副本
---@return foundation.math.Vector3 向量的副本
function Vector3:clone()
    return Vector3.create(self.x, self.y, self.z)
end

---计算两个向量的点积
---@param other foundation.math.Vector3 另一个向量
---@return number 两个向量的点积
function Vector3:dot(other)
    return self.x * other.x + self.y * other.y + self.z * other.z
end

---将当前向量归一化（更改当前向量）
---@return foundation.math.Vector3 归一化后的向量（自身引用）
function Vector3:normalize()
    local len = self:length()
    if len > 0 then
        self.x = self.x / len
        self.y = self.y / len
        self.z = self.z / len
    end
    return self
end

---获取向量的归一化副本
---@return foundation.math.Vector3 归一化后的向量副本
function Vector3:normalized()
    local len = self:length()
    if len == 0 then
        return Vector3.zero()
    end
    return Vector3.create(self.x / len, self.y / len, self.z / len)
end

ffi.metatype("foundation_math_Vector3", Vector3)

return Vector3