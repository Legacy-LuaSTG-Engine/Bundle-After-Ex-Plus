--------------------------------------------------------------------------------
--- SPDX-License-Identifier: MIT
--- description: 用于 replay 的输入系统
--- version: 0.3.0
--- author: 璀境石
--- detail: 与核心输入系统分离，录制时从核心输入系统获取输入并编码，播放时解码为输入
--------------------------------------------------------------------------------

local core = require("foundation.input.core")

---@class foundation.input.replay
local M = {}

---@param v number
---@param a number
---@param b number
---@return number
local function clamp(v, a, b)
    assert(a <= b)
    return math.max(a, math.min(v, b))
end

---@param v number
---@return number
local function round(v)
    local a, b = math.floor(v), math.ceil(v)
    if (v - a) < (b - v) then
        return a
    else
        return b
    end
end

---@param y number
---@param x number
---@return number
local function atan(y, x)
    if math.atan2 then
        return math.atan2(y, x)
    else
        ---@diagnostic disable-next-line: redundant-parameter
        return math.atan(y, x)
    end
end

--------------------------------------------------------------------------------
--- 状态集

---@class foundation.input.replay.Vector2
local _ = {
    r = 0,
    a = 0,
}

---@type table<string, boolean>
local last_boolean_action_state = {}

---@type table<string, boolean>
local boolean_action_state = {}

-- TODO: 这个可能用不上，应该去除
---@type table<string, number>
local last_scalar_action_state = {}

---@type table<string, number>
local scalar_action_state = {}

-- TODO: 这个可能用不上，应该去除
---@type table<string, foundation.input.replay.Vector2>
local last_vector2_action_state = {}

---@type table<string, foundation.input.replay.Vector2>
local vector2_action_state = {}

local function validate_state_type()
    for k, v in pairs(last_boolean_action_state) do
        assert(type(k) == "string" and type(v) == "boolean")
    end
    for k, v in pairs(boolean_action_state) do
        assert(type(k) == "string" and type(v) == "boolean")
    end

    for k, v in pairs(last_scalar_action_state) do
        assert(type(k) == "string" and type(v) == "number")
    end
    for k, v in pairs(scalar_action_state) do
        assert(type(k) == "string" and type(v) == "number")
    end

    for k, v in pairs(last_vector2_action_state) do
        assert(type(k) == "string" and type(v) == "table")
        assert(type(v.r) == "number" and type(v.a) == "number")
    end
    for k, v in pairs(vector2_action_state) do
        assert(type(k) == "string" and type(v) == "table")
        assert(type(v.r) == "number" and type(v.a) == "number")
    end
end

local function copy_state_to_last()
    for k, v in pairs(boolean_action_state) do
        last_boolean_action_state[k] = v
    end

    for k, v in pairs(scalar_action_state) do
        last_scalar_action_state[k] = v
    end

    for k, v in pairs(vector2_action_state) do
        last_vector2_action_state[k] = last_vector2_action_state[k] or {}
        last_vector2_action_state[k].r = v.r
        last_vector2_action_state[k].a = v.a
    end
end

local function clear_last_state()
    for k, _ in pairs(last_boolean_action_state) do
        last_boolean_action_state[k] = false
    end

    for k, _ in pairs(last_scalar_action_state) do
        last_scalar_action_state[k] = 0.0
    end

    for _, v in pairs(last_vector2_action_state) do
        v.r = 0.0
        v.a = 0.0
    end
end

local function clear_current_state()
    for k, _ in pairs(boolean_action_state) do
        boolean_action_state[k] = false
    end

    for k, _ in pairs(scalar_action_state) do
        scalar_action_state[k] = 0.0
    end

    for _, v in pairs(vector2_action_state) do
        v.r = 0.0
        v.a = 0.0
    end
end

function M.clear()
    validate_state_type()
    clear_last_state()
    clear_current_state()
end

--------------------------------------------------------------------------------
--- 默认映射，这些是每逻辑帧更新时需要从核心输入系统获取的输入

---@type string[]
local boolean_action_list = {
    -- 基本单元
    "up",
    "down",
    "left",
    "right",
    "shoot",
    "spell",
    -- 自机
    "slow",
    "special",
}

---@type string[]
local scalar_action_list = {}

---@type string[]
local vector2_action_list = {
    -- 基本单元
    "move",
}

--------------------------------------------------------------------------------
--- 更新

--- 获取所有输入，每逻辑帧应当只调用一次  
--- 一般放在 DoFrame 最开始  
function M.update()
    copy_state_to_last()
    clear_current_state()

    -- TODO: 自定义
    for _, k in ipairs(boolean_action_list) do
        boolean_action_state[k] = core.getBooleanActionValue(k)
    end
    for _, k in ipairs(scalar_action_list) do
        local v = core.getScalarActionValue(k)
        local v_norm = clamp(v, 0.0, 1.0) -- 限制区间 0.0 到 1.0
        local v_uint = round(v_norm * 255) -- 编码为 0 到 255 的整数
        scalar_action_state[k] = v_uint
    end
    for _, k in ipairs(vector2_action_list) do
        local x, y = core.getVector2ActionValue(k)
        local r = math.sqrt(x * x + y * y)
        local a = math.deg(atan(y, x))
        local r_norm = clamp(r, 0.0, 1.0) -- 限制区间 0.0 到 1.0
        local r_uint = round(r_norm * 100) -- 编码为 0 到 100 的整数
        local a_uint = round(a) % 360 -- 编码为 0 到 360 的整数
        vector2_action_state[k] = vector2_action_state[k] or {}
        vector2_action_state[k].r = r_uint
        vector2_action_state[k].a = a_uint
    end
end

--------------------------------------------------------------------------------
--- 编码与解码

local byte_mask = {
    1,
    2,
    4,
    8,
    16,
    32,
    64,
    128
}

---@param byte_array number[]
---@return fun():number
local function ByteArrayReader(byte_array)
    local length = #byte_array
    local index = 0
    local function read()
        index = index + 1
        assert(index <= length)
        return byte_array[index]
    end
    return read
end

---@return number[]
function M.encodeToByteArray()
    ---@type number[]
    local byte_array = {}
    -- 计算布尔动作需要编码为多少个字节
    local byte_count = math.ceil((#boolean_action_list) / 8)
    -- 编码布尔动作
    for j = 1, byte_count do
        local byte = 0
        for i = 1, 8 do
            local k = (j - 1) * 8 + i
            local key = boolean_action_list[k]
            if boolean_action_state[key] then
                byte = byte + byte_mask[i] -- 激活第 i 位
            end
        end
        table.insert(byte_array, byte)
    end
    -- 编码标量动作
    for _, k in ipairs(scalar_action_list) do
        local byte = scalar_action_state[k] or 0
        table.insert(byte_array, byte)
    end
    -- 编码二维矢量动作
    for _, k in ipairs(vector2_action_list) do
        if vector2_action_state[k] then
            local value = vector2_action_state[k] or 0
            local byte1 = value.r
            local byte2 = value.a
            if byte2 > 255 then
                -- byte1 存的是 0 到 100 的长度，不会用到第 8 位
                -- byte2 存的是 0 到 359 的角度，超过了 255，会用到第 9 位
                -- 所以要把 byte2 第 9 位挪到 byte1 第 8 位储存
                byte1 = byte1 + 128
                byte2 = byte2 - 256
            end
            table.insert(byte_array, byte1)
            table.insert(byte_array, byte2)
        else
            table.insert(byte_array, 0)
            table.insert(byte_array, 0)
        end
    end
    -- 验证所有的值范围
    for _, v in ipairs(byte_array) do
        assert(v >= 0 and v <= 255)
    end
    assert(#byte_array == M.getEncodeSize()) -- 交叉验证
    return byte_array
end

---@return string
function M.encodeToString()
    local byte_array = M.encodeToByteArray()
    ---@type string[]
    local char_array = {}
    for i, v in ipairs(byte_array) do
        char_array[i] = string.char(v)
    end
    return table.concat(char_array)
end

---@param byte_array number[]
function M.decodeFromByteArray(byte_array)
    -- 验证所有的值范围
    for _, v in ipairs(byte_array) do
        assert(v >= 0 and v <= 255)
    end
    assert(#byte_array == M.getEncodeSize()) -- 交叉验证
    -- 创建单向读取迭代器
    local read = ByteArrayReader(byte_array)
    -- 计算布尔动作编码为多少个字节
    local byte_count = math.ceil((#boolean_action_list) / 8)
    -- 解码布尔动作
    for j = 1, byte_count do
        local byte = read()
        for i = 8, 1, -1 do -- 这里要反过来迭代，从高位到低位
            local k = (j - 1) * 8 + i
            local key = boolean_action_list[k]
            if byte >= byte_mask[i] then
                byte = byte - byte_mask[i]
                boolean_action_state[key] = true -- 第 i 位是激活的
            else
                boolean_action_state[key] = false -- 需要修改为未激活
            end
        end
    end
    -- 解码标量动作
    for _, k in ipairs(scalar_action_list) do
        local byte = read()
        scalar_action_state[k] = byte
    end
    -- 解码二维矢量动作
    for _, k in ipairs(vector2_action_list) do
        local byte1 = read()
        local byte2 = read()
        if byte1 > 127 then
            -- byte1 存的是 0 到 100 的长度，不会用到第 8 位
            -- byte2 存的是 0 到 359 的角度，超过了 255，会用到第 9 位
            -- 之前把 byte2 第 9 位挪到 byte1 第 8 位储存
            -- 现在如果 byte1 超过了 127，则需要恢复回来
            byte1 = byte1 - 128
            byte2 = byte2 + 256
        end
        local value = vector2_action_state[k] or {}
        value.r = byte1
        value.a = byte2
    end
end

---@param str string
function M.decodeFromString(str)
    ---@type number[]
    local byte_array = {}
    local len = string.len(str)
    for i = 1, len do
        byte_array[i] = string.byte(str, i, i)
    end
    M.decodeFromByteArray(byte_array)
end

---@return number
function M.getEncodeSize()
    -- 计算布尔动作需要编码为多少个字节
    local byte_count = math.ceil((#boolean_action_list) / 8)
    return byte_count + (#scalar_action_list) + (2 * (#vector2_action_list))
end

--------------------------------------------------------------------------------
--- 获取动作值

--- 获取布尔动作值，只有 true 或者 false 两种状态  
---@param name string
---@return boolean
function M.getBooleanActionValue(name)
    return boolean_action_state[name]
end

--- 获取标量动作值，被映射到 0.0 到 1.0 的归一化实数  
---@param name string
---@return number
function M.getScalarActionValue(name)
    if scalar_action_state[name] then
        -- 解码为归一化浮点数
        local v_uint = scalar_action_state[name]
        local v_norm = v_uint / 255.0
        return v_norm
    else
        return 0.0
    end
end

--- 获取二维矢量动作值，模长为 0.0 到 1.0 的实数  
---@param name string
---@return number, number
function M.getVector2ActionValue(name)
    if vector2_action_state[name] then
        -- 解码为归一化二维向量
        local r_uint = vector2_action_state[name].r
        local a_uint = vector2_action_state[name].a
        local r_norm = r_uint / 100.0
        local x = r_norm * math.cos(math.rad(a_uint))
        local y = r_norm * math.sin(math.rad(a_uint))
        return x, y
    else
        return 0.0, 0.0
    end
end

--------------------------------------------------------------------------------
--- 追踪动作变化

--- 布尔动作是否在当前帧激活  
---@param name string
---@return boolean
function M.isBooleanActionActivate(name)
    return (not last_boolean_action_state[name]) and boolean_action_state[name]
end

--- 布尔动作是否在当前帧释放  
---@param name string
---@return boolean
function M.isBooleanActionDeactivate(name)
    return last_boolean_action_state[name] and (not boolean_action_state[name])
end

return M
