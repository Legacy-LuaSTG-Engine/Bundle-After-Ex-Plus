local ffi = require("ffi")

local type = type
local error = error
local tostring = tostring
local setmetatable = setmetatable
local table = table

---@class foundation.struct.array.BooleanArray
---@field size number 数组大小
---@field data userdata FFI布尔数组
local BooleanArray = {}

---创建一个新的布尔数组
---@param size number 数组大小(必须为正整数)
---@return foundation.struct.array.BooleanArray 新创建的布尔数组
function BooleanArray.create(size)
    if type(size) ~= "number" or size <= 0 then
        error("Invalid size: " .. tostring(size))
    end
    local self = setmetatable({
        size = size,
        data = ffi.new("bool[?]", size)
    }, BooleanArray)
    return self
end

---索引元方法，获取数组元素
---@param self foundation.struct.array.BooleanArray
---@param key number|string 索引或方法名
---@return boolean|function 数组元素值或方法
function BooleanArray.__index(self, key)
    if type(key) == "number" then
        if key < 0 or key >= self.size then
            error("Index out of bounds: " .. key)
        end
        return self.data[key]
    end
    return BooleanArray[key]
end

---赋值元方法，设置数组元素
---@param self foundation.struct.array.BooleanArray
---@param key number 数组索引
---@param value boolean 布尔值
function BooleanArray.__newindex(self, key, value)
    if type(key) ~= "number" then
        error("Invalid index type: " .. type(key))
    end
    if key < 0 or key >= self.size then
        error("Index out of bounds: " .. key)
    end
    if type(value) ~= "boolean" then
        error("Invalid value type: " .. type(value))
    end
    self.data[key] = value
end

---加法元方法 (逻辑OR操作)
---@param a foundation.struct.array.BooleanArray 左操作数
---@param b foundation.struct.array.BooleanArray 右操作数
---@return foundation.struct.array.BooleanArray 结果数组
function BooleanArray.__add(a, b)
    if a.size ~= b.size then
        error("Cannot add arrays of different sizes")
    end
    local result = BooleanArray.create(a.size)
    for i = 0, a.size - 1 do
        result.data[i] = a.data[i] or b.data[i]
    end
    return result
end

---减法元方法 (a且非b)
---@param a foundation.struct.array.BooleanArray 左操作数
---@param b foundation.struct.array.BooleanArray 右操作数
---@return foundation.struct.array.BooleanArray 结果数组
function BooleanArray.__sub(a, b)
    if a.size ~= b.size then
        error("Cannot subtract arrays of different sizes")
    end
    local result = BooleanArray.create(a.size)
    for i = 0, a.size - 1 do
        result.data[i] = a.data[i] and not b.data[i]
    end
    return result
end

---乘法元方法 (逻辑AND操作)
---@param a foundation.struct.array.BooleanArray 左操作数
---@param b foundation.struct.array.BooleanArray 右操作数
---@return foundation.struct.array.BooleanArray 结果数组
function BooleanArray.__mul(a, b)
    if a.size ~= b.size then
        error("Cannot multiply arrays of different sizes")
    end
    local result = BooleanArray.create(a.size)
    for i = 0, a.size - 1 do
        result.data[i] = a.data[i] and b.data[i]
    end
    return result
end

---除法元方法 (逻辑相等操作)
---@param a foundation.struct.array.BooleanArray 左操作数
---@param b foundation.struct.array.BooleanArray 右操作数
---@return foundation.struct.array.BooleanArray 结果数组
function BooleanArray.__div(a, b)
    if a.size ~= b.size then
        error("Cannot divide arrays of different sizes")
    end
    local result = BooleanArray.create(a.size)
    for i = 0, a.size - 1 do
        result.data[i] = a.data[i] == b.data[i]
    end
    return result
end

---一元减法元方法 (逻辑NOT操作)
---@param self foundation.struct.array.BooleanArray
---@return foundation.struct.array.BooleanArray 取反后的数组
function BooleanArray.__unm(self)
    local result = BooleanArray.create(self.size)
    for i = 0, self.size - 1 do
        result.data[i] = not self.data[i]
    end
    return result
end

---连接元方法
---@param a foundation.struct.array.BooleanArray 左操作数
---@param b foundation.struct.array.BooleanArray 右操作数
---@return foundation.struct.array.BooleanArray 连接后的数组
function BooleanArray.__concat(a, b)
    local result = BooleanArray.create(a.size + b.size)
    for i = 0, a.size - 1 do
        result.data[i] = a.data[i]
    end
    for i = 0, b.size - 1 do
        result.data[a.size + i] = b.data[i]
    end
    return result
end

---相等比较元方法
---@param a foundation.struct.array.BooleanArray 左操作数
---@param b foundation.struct.array.BooleanArray 右操作数
---@return boolean 数组是否相等
function BooleanArray.__eq(a, b)
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
---@param self foundation.struct.array.BooleanArray
---@return number 数组长度
function BooleanArray.__len(self)
    return self.size
end
BooleanArray.length = BooleanArray.__len

---转为字符串的元方法
---@param self foundation.struct.array.BooleanArray
---@return string 数组的字符串表示
function BooleanArray.__tostring(self)
    local result = {}
    for i = 0, self.size - 1 do
        result[i + 1] = tostring(self.data[i])
    end
    return "BooleanArray: [" .. table.concat(result, ", ") .. "]"
end

---用指定的值填充整个数组
---@param self foundation.struct.array.BooleanArray
---@param value boolean 填充值
function BooleanArray:fill(value)
    for i = 0, self.size - 1 do
        self.data[i] = value
    end
end

---获取数组的迭代器
---@param self foundation.struct.array.BooleanArray
---@return function,foundation.struct.array.BooleanArray,number 迭代器函数、数组对象和初始索引
function BooleanArray:ipairs()
    return function(t, i)
        i = i + 1
        if i < t.size then
            return i, t.data[i]
        end
    end, self, -1
end

---克隆数组
---@param self foundation.struct.array.BooleanArray
---@return foundation.struct.array.BooleanArray 数组副本
function BooleanArray:clone()
    local clone = BooleanArray.create(self.size)
    for i = 0, self.size - 1 do
        clone.data[i] = self.data[i]
    end
    return clone
end

return BooleanArray