local ffi = require("ffi")

local type = type
local string = string
local math = math
local require = require

local Vector2, Vector3

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

---通过特定结构的对象创建一个新的四维向量
---@param tbl table|foundation.math.Vector4 表或向量
---@return foundation.math.Vector4 新创建的向量
function Vector4.createFromTable(tbl)
    if tbl.x and tbl.y and tbl.z and tbl.w then
        return Vector4.create(tbl.x, tbl.y, tbl.z, tbl.w)
    end
    if tbl[1] and tbl[2] and tbl[3] and tbl[4] then
        return Vector4.create(tbl[1], tbl[2], tbl[3], tbl[4])
    end
    error("Invalid table format for Vector4 creation")
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
    return math.abs(a.x - b.x) <= 1e-10 and
            math.abs(a.y - b.y) <= 1e-10 and
            math.abs(a.z - b.z) <= 1e-10 and
            math.abs(a.w - b.w) <= 1e-10
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

---将Vector4转换为Vector2
---@return foundation.math.Vector2 转换后的Vector2
function Vector4:toVector2()
    Vector2 = Vector2 or require("foundation.math.Vector2")
    return Vector2.create(self.x, self.y)
end

---将Vector4转换为Vector3
---@return foundation.math.Vector3 转换后的Vector3
function Vector4:toVector3()
    Vector3 = Vector3 or require("foundation.math.Vector3")
    return Vector3.create(self.x, self.y, self.z)
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
    if len > 1e-10 then
        self.x = self.x / len
        self.y = self.y / len
        self.z = self.z / len
        self.w = self.w / len
    else
        self.x, self.y, self.z, self.w = 0, 0, 0, 0
    end
    return self
end

---获取向量的归一化副本
---@return foundation.math.Vector4 归一化后的向量副本
function Vector4:normalized()
    local len = self:length()
    if len <= 1e-10 then
        return Vector4.zero()
    end
    return Vector4.create(self.x / len, self.y / len, self.z / len, self.w / len)
end

---获取向量的齐次坐标（将w分量归一化为1）
---@return foundation.math.Vector4 归一化后的齐次坐标向量
function Vector4:homogeneous()
    if math.abs(self.w) <= 1e-10 then
        return self:clone()
    end
    return Vector4.create(self.x / self.w, self.y / self.w, self.z / self.w, 1)
end

---获取向量的投影坐标（将w分量归一化为1后返回一个Vector3）
---@return foundation.math.Vector3 投影后的三维向量
function Vector4:projectTo3D()
    Vector3 = Vector3 or require("foundation.math.Vector3")
    if math.abs(self.w) <= 1e-10 then
        return Vector3.create(self.x, self.y, self.z)
    end
    return Vector3.create(self.x / self.w, self.y / self.w, self.z / self.w)
end

---将当前向量的三维部分围绕任意轴旋转指定弧度（更改当前向量）
---@param axis foundation.math.Vector3 旋转轴（应为单位向量）
---@param rad number 旋转弧度
---@return foundation.math.Vector4 旋转后的向量（自身引用）
function Vector4:rotate(axis, rad)
    local vec3 = self:toVector3()
    vec3:rotate(axis, rad)
    self.x, self.y, self.z = vec3.x, vec3.y, vec3.z
    return self
end

---获取向量的三维部分围绕任意轴旋转指定弧度后的副本
---@param axis foundation.math.Vector3 旋转轴（应为单位向量）
---@param rad number 旋转弧度
---@return foundation.math.Vector4 旋转后的向量副本
function Vector4:rotated(axis, rad)
    local result = self:clone()
    return result:rotate(axis, rad)
end

---将向量的三维部分围绕任意轴旋转指定角度（更改当前向量）
---@param axis foundation.math.Vector3 旋转轴（应为单位向量）
---@param angle number 旋转角度（度）
---@return foundation.math.Vector4 旋转后的向量（自身引用）
function Vector4:degreeRotate(axis, angle)
    return self:rotate(axis, math.rad(angle))
end

---获取向量的三维部分围绕任意轴旋转指定角度后的副本
---@param axis foundation.math.Vector3 旋转轴（应为单位向量）
---@param angle number 旋转角度（度）
---@return foundation.math.Vector4 旋转后的向量副本
function Vector4:degreeRotated(axis, angle)
    return self:rotated(axis, math.rad(angle))
end

---将向量的三维部分围绕X轴旋转指定弧度（更改当前向量）
---@param rad number 旋转弧度
---@return foundation.math.Vector4 旋转后的向量（自身引用）
function Vector4:rotateX(rad)
    local c = math.cos(rad)
    local s = math.sin(rad)
    local y = self.y * c - self.z * s
    local z = self.y * s + self.z * c
    self.y, self.z = y, z
    return self
end

---获取向量的三维部分围绕X轴旋转指定弧度后的副本
---@param rad number 旋转弧度
---@return foundation.math.Vector4 旋转后的向量副本
function Vector4:rotatedX(rad)
    local result = self:clone()
    return result:rotateX(rad)
end

---将向量的三维部分围绕Y轴旋转指定弧度（更改当前向量）
---@param rad number 旋转弧度
---@return foundation.math.Vector4 旋转后的向量（自身引用）
function Vector4:rotateY(rad)
    local c = math.cos(rad)
    local s = math.sin(rad)
    local x = self.x * c + self.z * s
    local z = -self.x * s + self.z * c
    self.x, self.z = x, z
    return self
end

---获取向量的三维部分围绕Y轴旋转指定弧度后的副本
---@param rad number 旋转弧度
---@return foundation.math.Vector4 旋转后的向量副本
function Vector4:rotatedY(rad)
    local result = self:clone()
    return result:rotateY(rad)
end

---将向量的三维部分围绕Z轴旋转指定弧度（更改当前向量）
---@param rad number 旋转弧度
---@return foundation.math.Vector4 旋转后的向量（自身引用）
function Vector4:rotateZ(rad)
    local c = math.cos(rad)
    local s = math.sin(rad)
    local x = self.x * c - self.y * s
    local y = self.x * s + self.y * c
    self.x, self.y = x, y
    return self
end

---获取向量的三维部分围绕Z轴旋转指定弧度后的副本
---@param rad number 旋转弧度
---@return foundation.math.Vector4 旋转后的向量副本
function Vector4:rotatedZ(rad)
    local result = self:clone()
    return result:rotateZ(rad)
end

---将向量的三维部分围绕X轴旋转指定角度（更改当前向量）
---@param angle number 旋转角度（度）
---@return foundation.math.Vector4 旋转后的向量（自身引用）
function Vector4:degreeRotateX(angle)
    return self:rotateX(math.rad(angle))
end

---获取向量的三维部分围绕X轴旋转指定角度后的副本
---@param angle number 旋转角度（度）
---@return foundation.math.Vector4 旋转后的向量副本
function Vector4:degreeRotatedX(angle)
    return self:rotatedX(math.rad(angle))
end

---将向量的三维部分围绕Y轴旋转指定角度（更改当前向量）
---@param angle number 旋转角度（度）
---@return foundation.math.Vector4 旋转后的向量（自身引用）
function Vector4:degreeRotateY(angle)
    return self:rotateY(math.rad(angle))
end

---获取向量的三维部分围绕Y轴旋转指定角度后的副本
---@param angle number 旋转角度（度）
---@return foundation.math.Vector4 旋转后的向量副本
function Vector4:degreeRotatedY(angle)
    return self:rotatedY(math.rad(angle))
end

---将向量的三维部分围绕Z轴旋转指定角度（更改当前向量）
---@param angle number 旋转角度（度）
---@return foundation.math.Vector4 旋转后的向量（自身引用）
function Vector4:degreeRotateZ(angle)
    return self:rotateZ(math.rad(angle))
end

---获取向量的三维部分围绕Z轴旋转指定角度后的副本
---@param angle number 旋转角度（度）
---@return foundation.math.Vector4 旋转后的向量副本
function Vector4:degreeRotatedZ(angle)
    return self:rotatedZ(math.rad(angle))
end

ffi.metatype("foundation_math_Vector4", Vector4)

return Vector4