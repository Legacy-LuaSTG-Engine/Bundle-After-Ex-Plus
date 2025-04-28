local ffi = require("ffi")

local type = type
local error = error
local tostring = tostring
local setmetatable = setmetatable
local table = table

---@class foundation.struct.array.DoubleArray
---@field size number 数组大小
---@field data userdata FFI双精度浮点数数组
local DoubleArray = {}

---创建一个新的双精度浮点数数组
---@param size number 数组大小(必须为正整数)
---@return foundation.struct.array.DoubleArray 新创建的双精度浮点数数组
function DoubleArray.create(size)
    if type(size) ~= "number" or size <= 0 then
        error("Invalid size: " .. tostring(size))
    end
    local self = setmetatable({
        size = size,
        data = ffi.new("double[?]", size)
    }, DoubleArray)
    return self
end

---索引元方法，获取数组元素
---@param self foundation.struct.array.DoubleArray
---@param key number|string 索引或方法名
---@return number|function 数组元素值或方法
function DoubleArray.__index(self, key)
    if type(key) == "number" then
        if key < 0 or key >= self.size then
            error("Index out of bounds: " .. key)
        end
        return self.data[key]
    end
    return DoubleArray[key]
end

---赋值元方法，设置数组元素
---@param self foundation.struct.array.DoubleArray
---@param key number 数组索引
---@param value number 浮点数值
function DoubleArray.__newindex(self, key, value)
    if type(key) ~= "number" then
        error("Invalid index type: " .. type(key))
    end
    if key < 0 or key >= self.size then
        error("Index out of bounds: " .. key)
    end
    if type(value) ~= "number" then
        error("Invalid value type: " .. type(value))
    end
    self.data[key] = value
end

---加法元方法
---@param a foundation.struct.array.DoubleArray|number 左操作数
---@param b foundation.struct.array.DoubleArray|number 右操作数
---@return foundation.struct.array.DoubleArray 结果数组
function DoubleArray.__add(a, b)
    if type(a) == "number" then
        local result = DoubleArray.create(b.size)
        for i = 0, b.size - 1 do
            result.data[i] = a + b.data[i]
        end
        return result
    end
    if type(b) == "number" then
        local result = DoubleArray.create(a.size)
        for i = 0, a.size - 1 do
            result.data[i] = a.data[i] + b
        end
        return result
    end
    if a.size ~= b.size then
        error("Cannot add arrays of different sizes")
    end
    local result = DoubleArray.create(a.size)
    for i = 0, a.size - 1 do
        result.data[i] = a.data[i] + b.data[i]
    end
    return result
end

---减法元方法
---@param a foundation.struct.array.DoubleArray|number 左操作数
---@param b foundation.struct.array.DoubleArray|number 右操作数
---@return foundation.struct.array.DoubleArray 结果数组
function DoubleArray.__sub(a, b)
    if type(a) == "number" then
        local result = DoubleArray.create(b.size)
        for i = 0, b.size - 1 do
            result.data[i] = a - b.data[i]
        end
        return result
    end
    if type(b) == "number" then
        local result = DoubleArray.create(a.size)
        for i = 0, a.size - 1 do
            result.data[i] = a.data[i] - b
        end
        return result
    end
    if a.size ~= b.size then
        error("Cannot subtract arrays of different sizes")
    end
    local result = DoubleArray.create(a.size)
    for i = 0, a.size - 1 do
        result.data[i] = a.data[i] - b.data[i]
    end
    return result
end

---乘法元方法
---@param a foundation.struct.array.DoubleArray|number 左操作数
---@param b foundation.struct.array.DoubleArray|number 右操作数
---@return foundation.struct.array.DoubleArray 结果数组
function DoubleArray.__mul(a, b)
    if type(a) == "number" then
        local result = DoubleArray.create(b.size)
        for i = 0, b.size - 1 do
            result.data[i] = a * b.data[i]
        end
        return result
    end
    if type(b) == "number" then
        local result = DoubleArray.create(a.size)
        for i = 0, a.size - 1 do
            result.data[i] = a.data[i] * b
        end
        return result
    end
    if a.size ~= b.size then
        error("Cannot multiply arrays of different sizes")
    end
    local result = DoubleArray.create(a.size)
    for i = 0, a.size - 1 do
        result.data[i] = a.data[i] * b.data[i]
    end
    return result
end

---除法元方法
---@param a foundation.struct.array.DoubleArray|number 左操作数
---@param b foundation.struct.array.DoubleArray|number 右操作数
---@return foundation.struct.array.DoubleArray 结果数组
function DoubleArray.__div(a, b)
    if type(a) == "number" then
        local result = DoubleArray.create(b.size)
        for i = 0, b.size - 1 do
            result.data[i] = a / b.data[i]
        end
        return result
    end
    if type(b) == "number" then
        local result = DoubleArray.create(a.size)
        for i = 0, a.size - 1 do
            result.data[i] = a.data[i] / b
        end
        return result
    end
    if a.size ~= b.size then
        error("Cannot divide arrays of different sizes")
    end
    local result = DoubleArray.create(a.size)
    for i = 0, a.size - 1 do
        if b.data[i] == 0 then
            error("Division by zero at index: " .. i)
        end
        result.data[i] = a.data[i] / b.data[i]
    end
    return result
end

---一元减法元方法
---@param self foundation.struct.array.DoubleArray
---@return foundation.struct.array.DoubleArray 取反后的数组
function DoubleArray.__unm(self)
    local result = DoubleArray.create(self.size)
    for i = 0, self.size - 1 do
        result.data[i] = -self.data[i]
    end
    return result
end

---连接元方法
---@param a foundation.struct.array.DoubleArray 左操作数
---@param b foundation.struct.array.DoubleArray 右操作数
---@return foundation.struct.array.DoubleArray 连接后的数组
function DoubleArray.__concat(a, b)
    local result = DoubleArray.create(a.size + b.size)
    for i = 0, a.size - 1 do
        result.data[i] = a.data[i]
    end
    for i = 0, b.size - 1 do
        result.data[a.size + i] = b.data[i]
    end
    return result
end

---相等比较元方法
---@param a foundation.struct.array.DoubleArray 左操作数
---@param b foundation.struct.array.DoubleArray 右操作数
---@return boolean 数组是否相等
function DoubleArray.__eq(a, b)
    if a.size ~= b.size then
        return false
    end
    for i = 0, a.size - 1 do
        if a.data[i] ~= b.data[i] then
            return false
        end
    end
    return true
end

---获取数组长度的元方法
---@param self foundation.struct.array.DoubleArray
---@return number 数组长度
function DoubleArray.__len(self)
    return self.size
end
DoubleArray.length = DoubleArray.__len

---转为字符串的元方法
---@param self foundation.struct.array.DoubleArray
---@return string 数组的字符串表示
function DoubleArray.__tostring(self)
    local result = {}
    for i = 0, self.size - 1 do
        result[i + 1] = tostring(self.data[i])
    end
    return "DoubleArray: [" .. table.concat(result, ", ") .. "]"
end

---用指定的值填充整个数组
---@param self foundation.struct.array.DoubleArray
---@param value number 填充值
function DoubleArray:fill(value)
    for i = 0, self.size - 1 do
        self.data[i] = value
    end
end

---获取数组的迭代器
---@param self foundation.struct.array.DoubleArray
---@return function,foundation.struct.array.DoubleArray,number 迭代器函数、数组对象和初始索引
function DoubleArray:ipairs()
    return function(t, i)
        i = i + 1
        if i < t.size then
            return i, t.data[i]
        end
    end, self, -1
end

---克隆数组
---@param self foundation.struct.array.DoubleArray
---@return foundation.struct.array.DoubleArray 数组副本
function DoubleArray:clone()
    local clone = DoubleArray.create(self.size)
    for i = 0, self.size - 1 do
        clone.data[i] = self.data[i]
    end
    return clone
end

return DoubleArray