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

---@class foundation.input.replay.PolarVector2
local _ = {
    r = 0,
    a = 0,
}

---@class foundation.input.replay.Vector2
local _ = {
    x = 0,
    y = 0,
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
---@type table<string, foundation.input.replay.PolarVector2>
local last_polar_vector2_action_state = {}

---@type table<string, foundation.input.replay.PolarVector2>
local polar_vector2_action_state = {}

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
        assert(type(v.x) == "number" and type(v.y) == "number")
    end
    for k, v in pairs(vector2_action_state) do
        assert(type(k) == "string" and type(v) == "table")
        assert(type(v.x) == "number" and type(v.y) == "number")
    end
    
    for k, v in pairs(last_polar_vector2_action_state) do
        assert(type(k) == "string" and type(v) == "table")
        assert(type(v.a) == "number" and type(v.r) == "number")
    end
    for k, v in pairs(polar_vector2_action_state) do
        assert(type(k) == "string" and type(v) == "table")
        assert(type(v.a) == "number" and type(v.r) == "number")
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
        last_vector2_action_state[k].x = v.x
        last_vector2_action_state[k].y = v.y
    end

    for k, v in pairs(polar_vector2_action_state) do
        last_polar_vector2_action_state[k] = last_polar_vector2_action_state[k] or {}
        last_polar_vector2_action_state[k].a = v.a
        last_polar_vector2_action_state[k].r = v.r
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
        v.x = 0.0
        v.y = 0.0
    end

    for _, v in pairs(last_polar_vector2_action_state) do
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
        v.x = 0.0
        v.y = 0.0
    end

    for _, v in pairs(polar_vector2_action_state) do
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
    "skip"
}

---@type table[]
local scalar_action_list = {
    -- { name = "test", byte = 1, unsigned = true }
}

---@type table[]
local vector2_action_list = {
    -- 基本单元
    { name = "move", polar = true },
    { name = "cursor", byte = 2, unsigned = true}
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
        local v = core.getScalarActionValue(k.name)
        local v_norm
        if k.unsigned then
            v_norm = clamp(v, 0.0, 1.0)
        else
            v_norm = (clamp(v, -1.0, 1.0) + 1) / 2
        end
        local v_uint = round(v_norm * (256 ^ (k.byte or 1) - 1)) -- 编码为 0 到 256 ^ k.byte - 1 的整数
        scalar_action_state[k] = v_uint
    end
    for _, k in ipairs(vector2_action_list) do
        local x, y = core.getVector2ActionValue(k.name)
        if k.polar then
            local r = math.sqrt(x * x + y * y)
            local a = math.deg(atan(y, x))
            local r_norm = clamp(r, 0.0, 1.0) -- 限制区间 0.0 到 1.0
            local r_uint = round(r_norm * 100) -- 编码为 0 到 100 的整数
            local a_uint = round(a) % 360 -- 编码为 0 到 360 的整数
            polar_vector2_action_state[k.name] = polar_vector2_action_state[k.name] or {}
            polar_vector2_action_state[k.name].r = r_uint
            polar_vector2_action_state[k.name].a = a_uint
        else
            local x_norm, y_norm
            if k.unsigned then
                x_norm = clamp(x, 0.0, 1.0)
                y_norm = clamp(x, 0.0, 1.0)
            else
                x_norm = (clamp(x, -1.0, 1.0) + 1) / 2
                y_norm = (clamp(y, -1.0, 1.0) + 1) / 2
            end
            local x_uint = round(x_norm * (256 ^ (k.byte or 1) - 1))
            local y_uint = round(y_norm * (256 ^ (k.byte or 1) - 1))
            vector2_action_state[k.name] = vector2_action_state[k.name] or {}
            vector2_action_state[k.name].x = x_uint
            vector2_action_state[k.name].y = y_uint
        end
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
        assert(index <= length, "End of array")
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
        local num = scalar_action_state[k.name] or 0
        --按照小端序储存数据
        for _ = 1, k.byte do
            local byte = num % 256
            table.insert(byte_array, byte)
            num = math.floor(num / 256)
        end
    end
    -- 编码二维矢量动作
    for _, k in ipairs(vector2_action_list) do
        if k.polar then
            if polar_vector2_action_state[k.name] then
                local value = polar_vector2_action_state[k.name] or { r = 0.0, a = 0.0 }
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
        else
            local vec = vector2_action_state[k.name] or { x = 0.0, y = 0.0}
            local x = vec.x
            local y = vec.y
            --按照小端序储存数据
            for _ = 1, k.byte do
                local byte = x % 256
                table.insert(byte_array, byte)
                x = math.floor(x / 256)
            end
            for _ = 1, k.byte do
                local byte = y % 256
                table.insert(byte_array, byte)
                y = math.floor(y / 256)
            end
        end
    end
    -- 验证所有的值范围
    for _, v in ipairs(byte_array) do
        assert(v >= 0 and v <= 255, "Some byte(s) in the encoded array exceeded the range, check 'foundation.input.replay' for more information.")
    end
    assert(#byte_array == M.getEncodeSize(), "Byte array size does not match the estimated size, check 'foundation.input.replay' for more information.") -- 交叉验证
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
        assert(v >= 0 and v <= 255, "Some byte(s) in the encoded array exceeded the range, check 'foundation.input.replay' for more information.")
    end
    assert(#byte_array == M.getEncodeSize(), "Byte array size does not match the estimated size, check 'foundation.input.replay' for more information.") -- 交叉验证
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
            if key then
                if byte >= byte_mask[i] then
                    byte = byte - byte_mask[i]
                    boolean_action_state[key] = true -- 第 i 位是激活的
                else
                    boolean_action_state[key] = false -- 需要修改为未激活
                end
            end
        end
    end
    -- 解码标量动作
    for _, k in ipairs(scalar_action_list) do
        local num = 0
        local multiply = 1
        for _ = 1, k.byte do
            local byte = read()
            num = num + multiply * byte
            multiply = multiply * 256
        end
        scalar_action_state[k.name] = num
    end
    -- 解码二维矢量动作
    for _, k in ipairs(vector2_action_list) do
        if k.polar then
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
            local value = polar_vector2_action_state[k.name] or {}
            value.r = byte1
            value.a = byte2
        else
            local x, y = 0, 0
            local multiply = 1
            for _ = 1, k.byte do
                local byte = read()
                x = x + multiply * byte
                multiply = multiply * 256
            end
            multiply = 1
            for _ = 1, k.byte do
                local byte = read()
                y = y + multiply * byte
                multiply = multiply * 256
            end
            local value = vector2_action_state[k.name] or {}
            value.x = x
            value.y = y
        end
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

    for _, v in ipairs(scalar_action_list) do
        byte_count = byte_count + (v.byte or 1)
    end

    for _, v in ipairs(vector2_action_list) do
        if v.polar then
            byte_count = byte_count + 2
        else
            byte_count = byte_count + v.byte * 2
        end
    end
    return byte_count
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
        local byte = 1
        local unsigned = true
        for _, v in ipairs(scalar_action_list) do
            if v.name == name then
                byte = v.byte
                unsigned = v.unsigned
                break
            end
        end
        local v_uint = scalar_action_state[name]
        local v_norm
        if unsigned then
            v_norm = v_uint / (256 ^ byte - 1)
        else
            v_norm = v_uint / (256 ^ byte - 1) * 2 - 1
        end
        return v_norm
    else
        return 0.0
    end
end

--- 获取二维矢量动作值，模长为 0.0 到 1.0 的实数  
---@param name string
---@return number, number
function M.getVector2ActionValue(name)
    if polar_vector2_action_state[name] then
        -- 解码为归一化二维向量
        local r_uint = polar_vector2_action_state[name].r
        local a_uint = polar_vector2_action_state[name].a
        local r_norm = r_uint / 100.0
        local x = r_norm * math.cos(math.rad(a_uint))
        local y = r_norm * math.sin(math.rad(a_uint))
        return x, y
    elseif vector2_action_state[name] then
        local byte = 1
        local unsigned = true
        for _, v in ipairs(vector2_action_list) do
            if v.name == name then
                byte = v.byte
                unsigned = v.unsigned
                break
            end
        end
        local x_uint, y_uint = vector2_action_state[name].x, vector2_action_state[name].y
        local x_component, y_component
        if unsigned then
            x_component = x_uint / (256 ^ byte - 1)
            y_component = y_uint / (256 ^ byte - 1)
        else
            x_component = x_uint / (256 ^ byte - 1) * 2 - 1
            y_component = y_uint / (256 ^ byte - 1) * 2 - 1
        end
        return x_component, y_component
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
