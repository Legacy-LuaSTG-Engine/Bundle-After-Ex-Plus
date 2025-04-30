local ffi = require("ffi")

local type = type
local string = string
local math = math
local require = require

local Vector2, Vector4

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

---将Vector3转换为Vector2
---@return foundation.math.Vector2 转换后的Vector2
function Vector3:toVector2()
    Vector2 = Vector2 or require("foundation.math.Vector2")
    return Vector2.create(self.x, self.y)
end

---将Vector3转换为Vector4
---@param w number|nil W坐标分量，默认为0
---@return foundation.math.Vector4 转换后的Vector4
function Vector3:toVector4(w)
    Vector4 = Vector4 or require("foundation.math.Vector4")
    return Vector4.create(self.x, self.y, self.z, w or 0)
end

---计算两个向量的点积
---@param other foundation.math.Vector3 另一个向量
---@return number 两个向量的点积
function Vector3:dot(other)
    return self.x * other.x + self.y * other.y + self.z * other.z
end

---计算两个向量的叉积
---@param other foundation.math.Vector3 另一个向量
---@return foundation.math.Vector3 两个向量的叉积
function Vector3:cross(other)
    return Vector3.create(
            self.y * other.z - self.z * other.y,
            self.z * other.x - self.x * other.z,
            self.x * other.y - self.y * other.x
    )
end

---获取向量的球坐标角度（弧度）
---@return number,number 向量的极角和方位角，单位为弧度
function Vector3:sphericalAngle()
    local len = self:length()
    if len < 1e-10 then
        return 0, 0
    end
    local theta = math.acos(self.z / len)
    local phi = math.atan2(self.y, self.x)
    return theta, phi
end

---获取向量的球坐标角度（度）
---@return number,number 向量的极角和方位角，单位为度
function Vector3:sphericalDegreeAngle()
    local theta, phi = self:sphericalAngle()
    return math.deg(theta), math.deg(phi)
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

---将当前向量围绕任意轴旋转指定弧度（更改当前向量）
---@param axis foundation.math.Vector3 旋转轴（应为单位向量）
---@param rad number 旋转弧度
---@return foundation.math.Vector3 旋转后的向量（自身引用）
function Vector3:rotate(axis, rad)
    axis = axis:normalized()
    local c = math.cos(rad)
    local s = math.sin(rad)
    local k = 1 - c

    local nx = self.x * (c + axis.x * axis.x * k) +
            self.y * (axis.x * axis.y * k - axis.z * s) +
            self.z * (axis.x * axis.z * k + axis.y * s)

    local ny = self.x * (axis.y * axis.x * k + axis.z * s) +
            self.y * (c + axis.y * axis.y * k) +
            self.z * (axis.y * axis.z * k - axis.x * s)

    local nz = self.x * (axis.z * axis.x * k - axis.y * s) +
            self.y * (axis.z * axis.y * k + axis.x * s) +
            self.z * (c + axis.z * axis.z * k)

    self.x, self.y, self.z = nx, ny, nz
    return self
end

---获取向量围绕任意轴旋转指定弧度后的副本
---@param axis foundation.math.Vector3 旋转轴（应为单位向量）
---@param rad number 旋转弧度
---@return foundation.math.Vector3 旋转后的向量副本
function Vector3:rotated(axis, rad)
    local result = self:clone()
    return result:rotate(axis, rad)
end

---将向量围绕任意轴旋转指定角度（更改当前向量）
---@param axis foundation.math.Vector3 旋转轴（应为单位向量）
---@param angle number 旋转角度（度）
---@return foundation.math.Vector3 旋转后的向量（自身引用）
function Vector3:degreeRotate(axis, angle)
    return self:rotate(axis, math.rad(angle))
end

---获取向量围绕任意轴旋转指定角度后的副本
---@param axis foundation.math.Vector3 旋转轴（应为单位向量）
---@param angle number 旋转角度（度）
---@return foundation.math.Vector3 旋转后的向量副本
function Vector3:degreeRotated(axis, angle)
    return self:rotated(axis, math.rad(angle))
end

---将向量围绕X轴旋转指定弧度（更改当前向量）
---@param rad number 旋转弧度
---@return foundation.math.Vector3 旋转后的向量（自身引用）
function Vector3:rotateX(rad)
    local c = math.cos(rad)
    local s = math.sin(rad)
    local y = self.y * c - self.z * s
    local z = self.y * s + self.z * c
    self.y, self.z = y, z
    return self
end

---获取向量围绕X轴旋转指定弧度后的副本
---@param rad number 旋转弧度
---@return foundation.math.Vector3 旋转后的向量副本
function Vector3:rotatedX(rad)
    local result = self:clone()
    return result:rotateX(rad)
end

---将向量围绕Y轴旋转指定弧度（更改当前向量）
---@param rad number 旋转弧度
---@return foundation.math.Vector3 旋转后的向量（自身引用）
function Vector3:rotateY(rad)
    local c = math.cos(rad)
    local s = math.sin(rad)
    local x = self.x * c + self.z * s
    local z = -self.x * s + self.z * c
    self.x, self.z = x, z
    return self
end

---获取向量围绕Y轴旋转指定弧度后的副本
---@param rad number 旋转弧度
---@return foundation.math.Vector3 旋转后的向量副本
function Vector3:rotatedY(rad)
    local result = self:clone()
    return result:rotateY(rad)
end

---将向量围绕Z轴旋转指定弧度（更改当前向量）
---@param rad number 旋转弧度
---@return foundation.math.Vector3 旋转后的向量（自身引用）
function Vector3:rotateZ(rad)
    local c = math.cos(rad)
    local s = math.sin(rad)
    local x = self.x * c - self.y * s
    local y = self.x * s + self.y * c
    self.x, self.y = x, y
    return self
end

---获取向量围绕Z轴旋转指定弧度后的副本
---@param rad number 旋转弧度
---@return foundation.math.Vector3 旋转后的向量副本
function Vector3:rotatedZ(rad)
    local result = self:clone()
    return result:rotateZ(rad)
end

---将向量围绕X轴旋转指定角度（更改当前向量）
---@param angle number 旋转角度（度）
---@return foundation.math.Vector3 旋转后的向量（自身引用）
function Vector3:degreeRotateX(angle)
    return self:rotateX(math.rad(angle))
end

---获取向量围绕X轴旋转指定角度后的副本
---@param angle number 旋转角度（度）
---@return foundation.math.Vector3 旋转后的向量副本
function Vector3:degreeRotatedX(angle)
    return self:rotatedX(math.rad(angle))
end

---将向量围绕Y轴旋转指定角度（更改当前向量）
---@param angle number 旋转角度（度）
---@return foundation.math.Vector3 旋转后的向量（自身引用）
function Vector3:degreeRotateY(angle)
    return self:rotateY(math.rad(angle))
end

---获取向量围绕Y轴旋转指定角度后的副本
---@param angle number 旋转角度（度）
---@return foundation.math.Vector3 旋转后的向量副本
function Vector3:degreeRotatedY(angle)
    return self:rotatedY(math.rad(angle))
end

---将向量围绕Z轴旋转指定角度（更改当前向量）
---@param angle number 旋转角度（度）
---@return foundation.math.Vector3 旋转后的向量（自身引用）
function Vector3:degreeRotateZ(angle)
    return self:rotateZ(math.rad(angle))
end

---获取向量围绕Z轴旋转指定角度后的副本
---@param angle number 旋转角度（度）
---@return foundation.math.Vector3 旋转后的向量副本
function Vector3:degreeRotatedZ(angle)
    return self:rotatedZ(math.rad(angle))
end

ffi.metatype("foundation_math_Vector3", Vector3)

return Vector3