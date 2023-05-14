--------------------------------------------------------------------------------
--- SPDX-License-Identifier: MIT
--- description: 核心输入系统
--- version: 0.3.0
--- author: 璀境石
--- detail: 提供基本且统一的用户输入，将用户输入抽象为“动作”
--------------------------------------------------------------------------------

local keyboard = lstg.Input.Keyboard
local mouse = lstg.Input.Mouse
local xinput = require("xinput")
local dinput = require("dinput")
local xinput_ex = require("foundation.input.adapter.Xinput")
local dinput_ex = require("foundation.input.adapter.DirectInput")

---@class foundation.input.core
local M = {}

--------------------------------------------------------------------------------
--- 状态集

---@class foundation.input.core.Vector2
local _ = {
    x = 0.0,
    y = 0.0,
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
---@type table<string, foundation.input.core.Vector2>
local last_vector2_action_state = {}

---@type table<string, foundation.input.core.Vector2>
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
end

function M.clear()
    validate_state_type()
    clear_last_state()
    clear_current_state()
end

--------------------------------------------------------------------------------
--- 默认映射

local keyboard_map = {
    boolean = {
        -- 基本单元
        up = { keyboard.Up },
        down = { keyboard.Down },
        left = { keyboard.Left },
        right = { keyboard.Right },
        shoot = { keyboard.Z },
        spell = { keyboard.X },
        -- 自机
        slow = { keyboard.LeftShift },
        special = { keyboard.C },
        -- replay
        repfast = { keyboard.LeftControl },
        repslow = { keyboard.LeftShift },
        -- 菜单
        menu = { keyboard.Escape },
        snapshot = { keyboard.Home },
        retry = { keyboard.R },
    },
    scalar = {},
    vector2 = {},
}

local mouse_map = {
    boolean = {
        -- 基本单元
        up = { mouse.None },
        down = { mouse.None },
        left = { mouse.None },
        right = { mouse.None },
        shoot = { mouse.Left },
        spell = { mouse.Right },
        -- 自机
        slow = { mouse.None },
        special = { mouse.None },
        -- replay
        repfast = { mouse.None },
        repslow = { mouse.None },
        -- 菜单
        menu = { mouse.Middle },
        snapshot = { mouse.None },
        retry = { mouse.None },
    },
    scalar = {},
    vector2 = {},
}

local controller_map = {
    device_index = 0, -- 填 0 代表自动选择，在 xinput 中，最多支持 4 个设备，也就是 1 到 4
    boolean = {
        -- 基本单元
        up = {
            xinput_ex.Key.Up,
            --xinput_ex.Key.LeftThumbPositiveY,
            --xinput_ex.Key.RightThumbPositiveY,
        },
        down = {
            xinput_ex.Key.Down,
            --xinput_ex.Key.LeftThumbNegativeY,
            --xinput_ex.Key.RightThumbNegativeY,
        },
        left = {
            xinput_ex.Key.Left,
            --xinput_ex.Key.LeftThumbNegativeX,
            --xinput_ex.Key.RightThumbNegativeX,
        },
        right = {
            xinput_ex.Key.Right,
            --xinput_ex.Key.LeftThumbPositiveX,
            --xinput_ex.Key.RightThumbPositiveX,
        },
        shoot = { xinput_ex.Key.A },
        spell = { xinput_ex.Key.B },
        -- 自机
        slow = { xinput_ex.Key.LeftShoulder },
        special = { xinput_ex.Key.X },
        -- replay
        repfast = { xinput_ex.Key.A },
        repslow = { xinput_ex.Key.B },
        -- 菜单
        menu = { xinput_ex.Key.Start },
        snapshot = { xinput_ex.Key.RightTrigger },
        retry = { xinput_ex.Key.Back },
    },
    scalar = {},
    vector2 = {
        move = { 1 }, -- 1 代表左摇杆，2代表右摇杆
    },
}

local hid_map = {
    device_index = 0, -- 填 0 代表自动选择
    boolean = {
        -- 基本单元
        up = { dinput_ex.Key.NegativeAxisY },
        down = { dinput_ex.Key.PositiveAxisY },
        left = { dinput_ex.Key.NegativeAxisX },
        right = { dinput_ex.Key.PositiveAxisX },
        shoot = { dinput_ex.Key.Button2 },
        spell = { dinput_ex.Key.Button3 },
        -- 自机
        slow = { dinput_ex.Key.Button5 },
        special = { dinput_ex.Key.Button1 },
        -- replay
        repfast = { dinput_ex.Key.Null },
        repslow = { dinput_ex.Key.Null },
        -- 菜单
        menu = { dinput_ex.Key.Button4 },
        snapshot = { dinput_ex.Key.Null },
        retry = { dinput_ex.Key.Null },
    },
    scalar = {},
    vector2 = {},
}

-- TODO: 支持将多个布尔类型映射为标量或二维向量类型

---@param raw_index number
---@return number
local function get_controller_device_index(raw_index)
    assert(raw_index == 0 or raw_index == 1 or raw_index == 2 or raw_index == 3 or raw_index == 4)
    if raw_index == 0 then
        for i = 1, 4 do
            if xinput.isConnected(i) then
                return i
            end
        end
        return 0
    elseif xinput.isConnected(raw_index) then
        return raw_index
    else
        return 0
    end
end

---@param raw_index number
---@return number
local function get_hid_device_index(raw_index)
    assert(raw_index >= 0)
    if raw_index <= dinput.count() then
        return raw_index
    else
        return 0
    end
end

--------------------------------------------------------------------------------
--- 更新

local update_timer = -1

-- TODO: DirectInput 刷新设备的成本非常高，应当交给玩家手动刷新
dinput.refresh()

--- 更新所有输入，每帧应当只调用一次  
--- 一般放在 FrameFunc 最开始  
function M.update()
    update_timer = update_timer + 1

    if (update_timer % 60) == 0 then
        xinput.refresh()
    else
        xinput.update()
    end
    -- TODO: DirectInput 刷新设备的成本非常高，应当交给玩家手动刷新
    -- TODO: 可能需要在设置界面增加一个刷新设备的功能
    dinput.update()

    copy_state_to_last()
    clear_current_state()

    -- TODO: 可变键位映射
    for k, v in pairs(keyboard_map.boolean) do
        for _, code in ipairs(v) do
            if code ~= keyboard.None then
                boolean_action_state[k] = boolean_action_state[k] or keyboard.GetKeyState(code)
            end
        end
    end

    -- TODO: 可变键位映射
    for k, v in pairs(mouse_map.boolean) do
        for _, code in ipairs(v) do
            if code ~= mouse.None then
                boolean_action_state[k] = boolean_action_state[k] or mouse.GetKeyState(code)
            end
        end
    end

    -- TODO: 可变键位映射
    local device_index = get_controller_device_index(controller_map.device_index)
    if device_index > 0 then
        local state = xinput_ex.mapKeyStateFromIndex(device_index)
        for k, v in pairs(controller_map.boolean) do
            for _, code in ipairs(v) do
                if code ~= xinput_ex.Key.Null then
                    boolean_action_state[k] = boolean_action_state[k] or xinput_ex.getKeyState(state, code)
                end
            end
        end

        -- TODO: 支持标量类型

        -- TODO: 这种向量合成的方式真的没问题吗（
        for k, v in pairs(controller_map.vector2) do
            local x, y = 0, 0
            for _, component in ipairs(v) do
                if component == 1 then
                    x = x + xinput.getLeftThumbX(device_index)
                    y = y + xinput.getLeftThumbY(device_index)
                elseif component == 2 then
                    x = x + xinput.getRightThumbX(device_index)
                    y = y + xinput.getRightThumbY(device_index)
                end
            end
            local a = math.atan2(y, x)
            local r = math.min(math.sqrt(x * x + y * y), 1)
            vector2_action_state[k] = vector2_action_state[k] or {}
            vector2_action_state[k].x = r * math.cos(a)
            vector2_action_state[k].y = r * math.sin(a)
        end
    end

    -- TODO: 可变键位映射
    local device_index = get_hid_device_index(hid_map.device_index)
    if device_index > 0 then
        local state = dinput_ex.mapKeyStateFromIndex(device_index)
        for k, v in pairs(hid_map.boolean) do
            for _, code in ipairs(v) do
                if code ~= dinput_ex.Key.Null then
                    boolean_action_state[k] = boolean_action_state[k] or dinput_ex.getKeyState(state, code)
                end
            end
        end
        -- TODO: 支持标量类型
        -- TODO: 支持二维向量类型
    end
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
        return scalar_action_state[name]
    else
        return 0.0
    end
end

--- 获取二维矢量动作值，模长为 0.0 到 1.0 的实数  
---@param name string
---@return number, number
function M.getVector2ActionValue(name)
    if vector2_action_state[name] then
        return vector2_action_state[name].x, vector2_action_state[name].y
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
