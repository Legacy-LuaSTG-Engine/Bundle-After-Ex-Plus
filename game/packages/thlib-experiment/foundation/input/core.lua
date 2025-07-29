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
local config = require("foundation.input.config.Manager")

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
--- Notice:默认映射已移动至 config 里

-- TODO: 支持将多个布尔类型映射为标量

local vector2_normalize_list = {"move"} --需要归一化的向量

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

    local current_config = config.get_current_config()
    for k, v in pairs(current_config.keyboard_map.boolean) do
        for _, code in ipairs(v) do
            if code ~= keyboard.None then
                boolean_action_state[k] = boolean_action_state[k] or keyboard.GetKeyState(code)
            end
        end
    end
    -- 修改：向量直接相加，最后归一化
    for k, v in pairs(current_config.keyboard_map.vector2) do
        local x, y = 0, 0
        if vector2_action_state[k] then
            x, y = vector2_action_state[k].x, vector2_action_state[k].y
        else
            vector2_action_state[k] = {x = 0.0, y = 0.0}
        end
        local component_scalar = v.component_scalar or 1
        for _, code in ipairs(v.x_positive) do
            if code ~= keyboard.None then
                if keyboard.GetKeyState(code) then
                    x = x + component_scalar
                    break
                end
            end
        end
        for _, code in ipairs(v.x_negative) do
            if code ~= keyboard.None then
                if keyboard.GetKeyState(code) then
                    x = x - component_scalar
                    break
                end
            end
        end
        for _, code in ipairs(v.y_positive) do
            if code ~= keyboard.None then
                if keyboard.GetKeyState(code) then
                    y = y + component_scalar
                    break
                end
            end
        end
        for _, code in ipairs(v.y_negative) do
            if code ~= keyboard.None then
                if keyboard.GetKeyState(code) then
                    y = y - component_scalar
                    break
                end
            end
        end
        vector2_action_state[k].x = x
        vector2_action_state[k].y = y
    end

    for k, v in pairs(current_config.mouse_map.boolean) do
        for _, code in ipairs(v) do
            if code ~= mouse.None then
                boolean_action_state[k] = boolean_action_state[k] or mouse.GetKeyState(code)
            end
        end
    end
    for k, v in pairs(current_config.mouse_map.vector2) do
        local x, y = 0, 0
        if vector2_action_state[k] then
            x, y = vector2_action_state[k].x, vector2_action_state[k].y
        else
            vector2_action_state[k] = {x = 0.0, y = 0.0}
        end
        --参见 lib/ui.lua
        local mx, my = lstg.GetMousePosition() -- 左下角为原点，y 轴向上
        -- 转换到 UI 视口
        x = x + (mx - screen.dx) / (screen.width * screen.scale)
        y = y + (my - screen.dy) / (screen.height * screen.scale)
        vector2_action_state[k].x = x
        vector2_action_state[k].y = y
    end

    local device_index = get_controller_device_index(current_config.controller_map.device_index)
    if device_index > 0 then
        local state = xinput_ex.mapKeyStateFromIndex(device_index)
        for k, v in pairs(current_config.controller_map.boolean) do
            for _, code in ipairs(v) do
                if code ~= xinput_ex.Key.Null then
                    boolean_action_state[k] = boolean_action_state[k] or xinput_ex.getKeyState(state, code)
                end
            end
        end

        -- TODO: 支持标量类型

        for k, v in pairs(current_config.controller_map.vector2) do
            local x, y = 0, 0
            if vector2_action_state[k] then
                x, y = vector2_action_state[k].x, vector2_action_state[k].y
            else
                vector2_action_state[k] = {x = 0.0, y = 0.0}
            end
            for _, component in ipairs(v) do
                if component == 1 then
                    x = x + xinput.getLeftThumbX(device_index)
                    y = y + xinput.getLeftThumbY(device_index)
                elseif component == 2 then
                    x = x + xinput.getRightThumbX(device_index)
                    y = y + xinput.getRightThumbY(device_index)
                end
            end
            vector2_action_state[k].x = x
            vector2_action_state[k].y = y
        end
    end

    local device_index = get_hid_device_index(current_config.hid_map.device_index)
    if device_index > 0 then
        local state = dinput_ex.mapKeyStateFromIndex(device_index)
        for k, v in pairs(current_config.hid_map.boolean) do
            for _, code in ipairs(v) do
                if code ~= dinput_ex.Key.Null then
                    boolean_action_state[k] = boolean_action_state[k] or dinput_ex.getKeyState(state, code)
                end
            end
        end
        -- TODO: 支持标量类型
        -- TODO: 支持二维向量类型
    end

    -- 向量归一化
    for _, k in ipairs(vector2_normalize_list) do
        if vector2_action_state[k] then
            local x, y = vector2_action_state[k].x, vector2_action_state[k].y
            local r = math.sqrt(x * x + y * y)
            if r > 1 then
                vector2_action_state[k].x = x / r
                vector2_action_state[k].y = y / r
            end
        end
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
