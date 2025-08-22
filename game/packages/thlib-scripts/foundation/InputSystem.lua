local cjson = require("cjson")
local cjson_util = require("cjson.util")
local lstg = require("lstg")
local Keyboard = lstg.Input.Keyboard
local Mouse = lstg.Input.Mouse
local XInput = require("xinput")
local XInputAdaptor = require("foundation.input.adapter.Xinput")
local DirectInput = require("dinput")
local DirectInputAdaptor = require("foundation.input.adapter.DirectInput")
local LocalFileStorage = require("foundation.LocalFileStorage")
local Files = require("foundation.Files")

--- 输入系统
---@class foundation.InputSystem
local InputSystem = {}

--------------------------------------------------------------------------------
--- 辅助函数
--#region

---@generic T
---@param array T[]
---@param value T
---@return boolean
local function isArrayContains(array, value)
    for i = 1, #array do
        if array[i] == value then
            return true
        end
    end
    return false
end

---@generic T
---@param array T[]
---@param comparator fun(value: T):boolean
---@return boolean
local function isArrayContainsIf(array, comparator)
    for i = 1, #array do
        if comparator(array[i]) then
            return true
        end
    end
    return false
end

---@generic T
---@param array T[]
---@param value T
local function removeArrayValue(array, value)
    for i = #array, 1, -1 do
        if array[i] == value then
            table.remove(array, i)
        end
    end
end

---@generic T
---@param array T[]
---@param comparator fun(value: T):boolean
local function removeArrayValueIf(array, comparator)
    for i = #array, 1, -1 do
        if comparator(array[i]) then
            table.remove(array, i)
        end
    end
end

---@generic T
---@param array T[]
local function clearArray(array)
    for i = #array, 1, -1 do
        array[i] = nil
    end
    for k, _ in pairs(array) do
        array[k] = nil
    end
end

---@generic T
---@param array T[]
---@param elements T[]
local function appendToArray(array, elements)
    local n = #array
    for i = 1, #elements do
        array[n + i] = elements[i]
    end
end

---@generic T
---@param value T
---@return T
local function copyTable(value)
    local value_type = type(value)
    if value_type == "boolean" or value_type == "number" or value_type == "string" then
        return value
    elseif value_type == "table" then
        local result = {}
        for key, v in pairs(value) do
            local key_type = type(key)
            if not (key_type == "number" or key_type == "string") then
                error(("unsupported key type '%s'"):format(key_type))
            end
            result[key] = copyTable(v)
        end
        return result
    else
        error(("unsupported value type '%s'"):format(value_type))
    end
end

--#endregion
--------------------------------------------------------------------------------
--- 动作
--#region

---@alias foundation.InputSystem.ActionType '"boolean"' | '"scalar"' | '"vector2"'

---@class foundation.InputSystem.Action
---@field name string
---@field type foundation.InputSystem.ActionType

---@alias foundation.InputSystem.PhysicalBindingType '"key"' | '"axis"' | '"joystick"'

---@class foundation.InputSystem.Binding
---@field type foundation.InputSystem.PhysicalBindingType

--#endregion
--------------------------------------------------------------------------------
--- 布尔动作，用于按键组件，比如键盘按键
--#region

---@class foundation.InputSystem.BooleanBinding : foundation.InputSystem.Binding
---@field key integer

---@class foundation.InputSystem.BooleanAction : foundation.InputSystem.Action
---@field keyboard_bindings   foundation.InputSystem.BooleanBinding[]
---@field mouse_bindings      foundation.InputSystem.BooleanBinding[]
---@field controller_bindings foundation.InputSystem.BooleanBinding[]
---@field hid_bindings        foundation.InputSystem.BooleanBinding[]
local BooleanAction = {}

function BooleanAction:keyboardBindings()
    return ipairs(self.keyboard_bindings)
end

---@param key integer
function BooleanAction:addKeyboardKeyBinding(key)
    local exists = isArrayContainsIf(self.keyboard_bindings, function(value)
        return value.type == "key" and value.key == key
    end)
    if exists then
        return self
    end
    table.insert(self.keyboard_bindings, {
        type = "key",
        key = key,
    })
    return self
end

---@param key integer
function BooleanAction:removeKeyboardKeyBinding(key)
    removeArrayValueIf(self.keyboard_bindings, function(value)
        return value.type == "key" and value.key == key
    end)
end

function BooleanAction:mouseBindings()
    return ipairs(self.mouse_bindings)
end

---@param key integer
function BooleanAction:addMouseKeyBinding(key)
    local exists = isArrayContainsIf(self.mouse_bindings, function(value)
        return value.key == key
    end)
    if exists then
        return self
    end
    table.insert(self.mouse_bindings, {
        type = "key",
        key = key,
    })
    return self
end

---@param key integer
function BooleanAction:removeMouseKeyBinding(key)
    removeArrayValueIf(self.mouse_bindings, function(value)
        return value.type == "key" and value.key == key
    end)
end

function BooleanAction:controllerBindings()
    return ipairs(self.controller_bindings)
end

---@param key integer
function BooleanAction:addControllerKeyBinding(key)
    local exists = isArrayContainsIf(self.controller_bindings, function(value)
        return value.type == "key" and value.key == key
    end)
    if exists then
        return self
    end
    table.insert(self.controller_bindings, {
        type = "key",
        key = key,
    })
    return self
end

---@param key integer
function BooleanAction:removeControllerKeyBinding(key)
    removeArrayValueIf(self.controller_bindings, function(value)
        return value.type == "key" and value.key == key
    end)
end

function BooleanAction:hidBindings()
    return ipairs(self.hid_bindings)
end

---@param key integer
function BooleanAction:addHidKeyBinding(key)
    local exists = isArrayContainsIf(self.hid_bindings, function(value)
        return value.type == "key" and value.key == key
    end)
    if exists then
        return self
    end
    table.insert(self.hid_bindings, {
        type = "key",
        key = key,
    })
    return self
end

---@param key integer
function BooleanAction:removeHidKeyBinding(key)
    removeArrayValueIf(self.hid_bindings, function(value)
        return value.type == "key" and value.key == key
    end)
end

---@param name string
---@return foundation.InputSystem.BooleanAction
function BooleanAction.create(name)
    local instance = {
        name = name,
        type = "boolean",
        keyboard_bindings = {},
        mouse_bindings = {},
        controller_bindings = {},
        hid_bindings = {},
    }
    setmetatable(instance, { __index = BooleanAction })
    return instance
end

--#endregion
--------------------------------------------------------------------------------
--- 标量动作，用于单轴组件，比如手柄扳机
--#region

---@class foundation.InputSystem.ScalarBinding : foundation.InputSystem.Binding
---@field key  integer
---@field axis integer

---@class foundation.InputSystem.ScalarAction : foundation.InputSystem.Action
---@field keyboard_bindings   foundation.InputSystem.ScalarBinding[]
---@field mouse_bindings      foundation.InputSystem.ScalarBinding[]
---@field controller_bindings foundation.InputSystem.ScalarBinding[]
---@field hid_bindings        foundation.InputSystem.ScalarBinding[]
local ScalarAction = {}

function ScalarAction:keyboardBindings()
    return ipairs(self.keyboard_bindings)
end

---@param key integer
function ScalarAction:addKeyboardKeyBinding(key)
    local exists = isArrayContainsIf(self.keyboard_bindings, function(value)
        return value.type == "key" and value.key == key
    end)
    if exists then
        return
    end
    table.insert(self.keyboard_bindings, {
        type = "key",
        key = key,
        axis = 0,
    })
end

---@param key integer
function ScalarAction:removeKeyboardKeyBinding(key)
    removeArrayValueIf(self.keyboard_bindings, function(value)
        return value.type == "key" and value.key == key
    end)
end

function ScalarAction:mouseBindings()
    return ipairs(self.mouse_bindings)
end

---@param key integer
function ScalarAction:addMouseKeyBinding(key)
    local exists = isArrayContainsIf(self.mouse_bindings, function(value)
        return value.type == "key" and value.key == key
    end)
    if exists then
        return
    end
    table.insert(self.mouse_bindings, {
        type = "key",
        key = key,
        axis = 0,
    })
end

---@param key integer
function ScalarAction:removeMouseKeyBinding(key)
    removeArrayValueIf(self.mouse_bindings, function(value)
        return value.type == "key" and value.key == key
    end)
end

function ScalarAction:controllerBindings()
    return ipairs(self.controller_bindings)
end

---@param key integer
function ScalarAction:addControllerKeyBinding(key)
    local exists = isArrayContainsIf(self.controller_bindings, function(value)
        return value.type == "key" and value.key == key
    end)
    if exists then
        return
    end
    table.insert(self.controller_bindings, {
        type = "key",
        key = key,
        axis = 0,
    })
end

---@param key integer
function ScalarAction:removeControllerKeyBinding(key)
    removeArrayValueIf(self.controller_bindings, function(value)
        return value.type == "key" and value.key == key
    end)
end

---@param axis integer
function ScalarAction:addControllerAxisBinding(axis)
    local exists = isArrayContainsIf(self.controller_bindings, function(value)
        return value.type == "axis" and value.axis == axis
    end)
    if exists then
        return
    end
    table.insert(self.controller_bindings, {
        type = "axis",
        key = axis,
        axis = 0,
    })
end

---@param axis integer
function ScalarAction:removeControllerAxisBinding(axis)
    removeArrayValueIf(self.controller_bindings, function(value)
        return value.type == "axis" and value.axis == axis
    end)
end

function ScalarAction:hidBindings()
    return ipairs(self.hid_bindings)
end

---@param key integer
function ScalarAction:addHidKeyBinding(key)
    local exists = isArrayContainsIf(self.hid_bindings, function(value)
        return value.type == "key" and value.key == key
    end)
    if exists then
        return
    end
    table.insert(self.hid_bindings, {
        type = "key",
        key = key,
        axis = 0,
    })
end

---@param key integer
function ScalarAction:removeHidKeyBinding(key)
    removeArrayValueIf(self.hid_bindings, function(value)
        return value.type == "key" and value.key == key
    end)
end

---@param axis integer
function ScalarAction:addHidAxisBinding(axis)
    local exists = isArrayContainsIf(self.hid_bindings, function(value)
        return value.type == "axis" and value.axis == axis
    end)
    if exists then
        return
    end
    table.insert(self.hid_bindings, {
        type = "axis",
        key = axis,
        axis = 0,
    })
end

---@param axis integer
function ScalarAction:removeHidAxisBinding(axis)
    removeArrayValueIf(self.hid_bindings, function(value)
        return value.type == "axis" and value.axis == axis
    end)
end

---@param name string
---@return foundation.InputSystem.ScalarAction
function ScalarAction.create(name)
    local instance = {
        name = name,
        type = "scalar",
        keyboard_bindings = {},
        mouse_bindings = {},
        controller_bindings = {},
        hid_bindings = {},
    }
    setmetatable(instance, { __index = ScalarAction })
    return instance
end

--#endregion
--------------------------------------------------------------------------------
--- 二维矢量动作，用于双轴组件，比如手柄摇杆
--#region

---@class foundation.InputSystem.Vector2Binding : foundation.InputSystem.Binding
---@field joystick       integer
---@field x_axis         integer
---@field y_axis         integer
---@field positive_x_key integer
---@field negative_x_key integer
---@field positive_y_key integer
---@field negative_y_key integer

---@param joystick integer
---@return foundation.InputSystem.Vector2Binding
local function createJoystickVector2Binding(joystick)
    ---@type foundation.InputSystem.Vector2Binding
    local result = {
        type = "joystick",
        joystick = joystick,
        x_axis = 0,
        y_axis = 0,
        positive_x_key = 0,
        negative_x_key = 0,
        positive_y_key = 0,
        negative_y_key = 0,
    }
    return result
end

---@class foundation.InputSystem.Vector2Action : foundation.InputSystem.Action
---@field keyboard_bindings   foundation.InputSystem.Vector2Binding[]
---@field mouse_bindings      foundation.InputSystem.Vector2Binding[]
---@field controller_bindings foundation.InputSystem.Vector2Binding[]
---@field hid_bindings        foundation.InputSystem.Vector2Binding[]
local Vector2Action = {}

---@param joystick integer
function Vector2Action:addControllerJoystickBinding(joystick)
    local exists = isArrayContainsIf(self.controller_bindings, function(value)
        return value.type == "joystick" and value.joystick == joystick
    end)
    if exists then
        return
    end
    table.insert(self.controller_bindings, createJoystickVector2Binding(joystick))
end

---@param joystick integer
function Vector2Action:removeControllerJoystickBinding(joystick)
    removeArrayValueIf(self.controller_bindings, function(value)
        return value.type == "joystick" and value.joystick == joystick
    end)
end

---@param name string
---@return foundation.InputSystem.Vector2Action
function Vector2Action.create(name)
    local instance = {
        name = name,
        type = "vector2",
        keyboard_bindings = {},
        mouse_bindings = {},
        controller_bindings = {},
        hid_bindings = {},
    }
    setmetatable(instance, { __index = Vector2Action })
    return instance
end

--#endregion
--------------------------------------------------------------------------------
--- 动作集
--#region

---@class foundation.InputSystem.ActionSet
---@field name            string
---@field boolean_actions table<string, foundation.InputSystem.BooleanAction>
---@field scalar_actions  table<string, foundation.InputSystem.ScalarAction>
---@field vector2_actions table<string, foundation.InputSystem.Vector2Action>
local ActionSet = {}

function ActionSet:booleanActions()
    return pairs(self.boolean_actions)
end

---@param name string
---@return foundation.InputSystem.BooleanAction
function ActionSet:addBooleanAction(name)
    assert(type(name) == "string", "name must be a string")
    if self.boolean_actions[name] then
        return self.boolean_actions[name]
    end
    local action = BooleanAction.create(name)
    self.boolean_actions[name] = action
    return action
end

---@param name string
function ActionSet:removeBooleanAction(name)
    assert(type(name) == "string", "name must be a string")
    self.boolean_actions[name] = nil
end

---@param name string
---@return foundation.InputSystem.BooleanAction
function ActionSet:getBooleanAction(name)
    assert(type(name) == "string", "name must be a string")
    return assert(self.boolean_actions[name], ("BooleanAction '%s' does not exists"):format(name))
end

function ActionSet:scalarActions()
    return pairs(self.scalar_actions)
end

---@param name string
---@return foundation.InputSystem.ScalarAction
function ActionSet:addScalarAction(name)
    assert(type(name) == "string", "name must be a string")
    if self.scalar_actions[name] then
        return self.scalar_actions[name]
    end
    local action = ScalarAction.create(name)
    self.scalar_actions[name] = action
    return action
end

---@param name string
function ActionSet:removeScalarAction(name)
    assert(type(name) == "string", "name must be a string")
    self.scalar_actions[name] = nil
end

---@param name string
---@return foundation.InputSystem.ScalarAction
function ActionSet:getScalarAction(name)
    assert(type(name) == "string", "name must be a string")
    return assert(self.scalar_actions[name], ("ScalarAction '%s' does not exists"):format(name))
end

---@param name string
---@return foundation.InputSystem.Vector2Action
function ActionSet:addVector2Action(name)
    assert(type(name) == "string", "name must be a string")
    if self.vector2_actions[name] then
        return self.vector2_actions[name]
    end
    local action = Vector2Action.create(name)
    self.vector2_actions[name] = action
    return action
end

---@param name string
function ActionSet:removeVector2Action(name)
    assert(type(name) == "string", "name must be a string")
    self.vector2_actions[name] = nil
end

---@param name string
---@return foundation.InputSystem.Vector2Action
function ActionSet:getVector2Action(name)
    assert(type(name) == "string", "name must be a string")
    return assert(self.vector2_actions[name], ("Vector2Action '%s' does not exists"):format(name))
end

---@param name string
---@return foundation.InputSystem.ActionSet
function ActionSet.create(name)
    ---@type foundation.InputSystem.ActionSet
    local instance = {
        name = name,
        boolean_actions = {},
        scalar_actions = {},
        vector2_actions = {},
    }
    setmetatable(instance, { __index = ActionSet })
    return instance
end

--#endregion
--------------------------------------------------------------------------------
--- 动作集管理
--#region

---@type table<string, foundation.InputSystem.ActionSet>
local action_sets = {}

---@type fun(action_set:foundation.InputSystem.ActionSet)[]
local on_action_set_added = {} -- internal hook

---@type fun(action_set:foundation.InputSystem.ActionSet)[]
local on_action_set_removed = {} -- internal hook

---@param name string
---@return foundation.InputSystem.ActionSet
function InputSystem.addActionSet(name)
    assert(type(name) == "string", "name must be a string")
    if action_sets[name] then
        return action_sets[name]
    end
    local action_set = ActionSet.create(name)
    action_sets[name] = action_set
    for _, callback in ipairs(on_action_set_added) do
        callback(action_set)
    end
    return action_set
end

---@param name string
function InputSystem.removeActionSet(name)
    assert(type(name) == "string", "name must be a string")
    if action_sets[name] then
        for _, callback in ipairs(on_action_set_removed) do
            callback(action_sets[name])
        end
    end
    action_sets[name] = nil
end

---@param name string
---@return foundation.InputSystem.ActionSet
function InputSystem.getActionSet(name)
    assert(type(name) == "string", "name must be a string")
    return assert(action_sets[name], ("ActionSet '%s' does not exists"):format(name))
end

--#endregion
--------------------------------------------------------------------------------
--- 动作集切换
--#region

--- 当前的动作集栈，栈为空时表示不指定动作集并从所有动作集读取值
---@type string[]
local action_set_name_stack = {}

---@param name string
function InputSystem.pushActionSet(name)
    assert(type(name) == "string", "name must be a string")
    assert(action_sets[name], ("ActionSet '%s' does not exists"):format(name))
    table.insert(action_set_name_stack, name)
end

function InputSystem.popActionSet()
    assert(#action_set_name_stack > 0, "ActionSet stack is empty")
    table.remove(action_set_name_stack)
end

--#endregion
--------------------------------------------------------------------------------
--- 输入系统内部状态
--#region

---@class foundation.InputSystem.Vector2
---@field x number
---@field y number

---@class foundation.InputSystem.PolarVector2
---@field m number magnitude
---@field a number angle

---@class foundation.InputSystem.ActionSetValues
---@field last_boolean_action_values table<string, boolean>
---@field boolean_action_values      table<string, boolean>
---@field boolean_action_frames      table<string, integer>
---@field last_scalar_action_values  table<string, number>
---@field scalar_action_values       table<string, number>
---@field last_vector2_action_values table<string, foundation.InputSystem.Vector2>
---@field vector2_action_values      table<string, foundation.InputSystem.Vector2>

---@return foundation.InputSystem.ActionSetValues
local function createActionSetValues()
    return {
        last_boolean_action_values = {},
        boolean_action_values = {},
        boolean_action_frames = {},
        last_scalar_action_values = {},
        scalar_action_values = {},
        last_vector2_action_values = {},
        vector2_action_values = {},
    }
end

---@type table<string, foundation.InputSystem.ActionSetValues>
local raw_action_set_values = {}

table.insert(on_action_set_added, function(action_set)
    raw_action_set_values[action_set.name] = createActionSetValues()
end)
table.insert(on_action_set_removed, function(action_set)
    raw_action_set_values[action_set.name] = nil
end)

---@type foundation.InputSystem.ActionSetValues
local merged_action_set_values = createActionSetValues()

---@return foundation.InputSystem.ActionSetValues
local function getCurrentActionSetValues()
    if #action_set_name_stack > 0 then
        local action_set_values = raw_action_set_values[action_set_name_stack[#action_set_name_stack]]
        if action_set_values then
            return action_set_values
        end
    end
    return merged_action_set_values
end

--#endregion
--------------------------------------------------------------------------------
--- 输入系统设置
--#region

---@class foundation.InputSystem.Setting
local setting = {
    --- 0: Auto  
    --- 1-4: Xinput controllers 1 to 4  
    controller_index = 0,
    --- 0: Auto  
    --- 1-?: DirectInput devices  
    hid_index = 0,
}

function InputSystem.getSetting()
    return setting
end

--#endregion
--------------------------------------------------------------------------------
--- 状态更新
--#region

---@param action_set_values foundation.InputSystem.ActionSetValues
local function clearActionSetValues(action_set_values)
    for k, _ in pairs(action_set_values.last_boolean_action_values) do
        action_set_values.last_boolean_action_values[k] = false
    end
    for k, _ in pairs(action_set_values.boolean_action_values) do
        action_set_values.boolean_action_values[k] = false
    end
    for k, _ in pairs(action_set_values.boolean_action_frames) do
        action_set_values.boolean_action_frames[k] = 0
    end
    for k, _ in pairs(action_set_values.last_scalar_action_values) do
        action_set_values.last_scalar_action_values[k] = 0
    end
    for k, _ in pairs(action_set_values.scalar_action_values) do
        action_set_values.scalar_action_values[k] = 0
    end
    for k, _ in pairs(action_set_values.last_vector2_action_values) do
        action_set_values.last_vector2_action_values[k] = { x = 0, y = 0 }
    end
    for k, _ in pairs(action_set_values.vector2_action_values) do
        action_set_values.vector2_action_values[k] = { x = 0, y = 0 }
    end
end

---@param action_set_values foundation.InputSystem.ActionSetValues
local function copyLastActionSetValues(action_set_values)
    for k, v in pairs(action_set_values.boolean_action_values) do
        action_set_values.last_boolean_action_values[k] = v
    end
    for k, v in pairs(action_set_values.scalar_action_values) do
        action_set_values.last_scalar_action_values[k] = v
    end
    for k, v in pairs(action_set_values.vector2_action_values) do
        action_set_values.last_vector2_action_values[k] = { x = v.x, y = v.y }
    end
end

function InputSystem.clear()
    for _, v in pairs(raw_action_set_values) do
        clearActionSetValues(v)
    end
    clearActionSetValues(merged_action_set_values)
end

---@type foundation.input.adapter.XInput.KeyState[]
local xinput_adaptor_map = {}

local function updateXInput()
    XInput.update()
    for i = 1, 4 do
        if XInput.isConnected(i) then
            xinput_adaptor_map[i] = XInputAdaptor.mapKeyStateFromIndex(i, 0.5)
        else
            xinput_adaptor_map[i] = {}
        end
    end
end

---@type foundation.input.adapter.DirectInput.KeyState[]
local dinput_adaptor_map = {}

local function updateDirectInput()
    DirectInput.update()
    local count = DirectInput.count()
    for i = 1, count do
        dinput_adaptor_map[i] = DirectInputAdaptor.mapKeyStateFromIndex(i, 0.5)
    end
    for i = #dinput_adaptor_map, count + 1, -1 do
        dinput_adaptor_map[i] = nil
    end
end

---@param values table<string, boolean>
---@param name string
---@param value boolean
local function orBooleanActionValue(values, name, value)
    if type(values[name]) ~= "boolean" then
        values[name] = false
    end
    values[name] = values[name] or value
end

---@param action_set foundation.InputSystem.ActionSet
---@param action_set_values foundation.InputSystem.ActionSetValues
local function updateBooleanActions(action_set, action_set_values)
    local values = action_set_values.boolean_action_values
    for name, action in action_set:booleanActions() do
        for _, binding in action:keyboardBindings() do
            orBooleanActionValue(values, name, Keyboard.GetKeyState(binding.key))
        end
        for _, binding in action:mouseBindings() do
            orBooleanActionValue(values, name, Mouse.GetKeyState(binding.key))
        end
        for _, binding in action:controllerBindings() do
            for i, map in ipairs(xinput_adaptor_map) do
                if XInput.isConnected(i) then
                    orBooleanActionValue(values, name, XInputAdaptor.getKeyState(map, binding.key))
                end
            end
        end
        for _, binding in action:hidBindings() do
            for _, map in ipairs(dinput_adaptor_map) do
                orBooleanActionValue(values, name, DirectInputAdaptor.getKeyState(map, binding.key))
            end
        end
    end
end

---@param values table<string, number>
---@param name string
---@param value number
local function addScalarActionValue(values, name, value)
    if type(values[name]) ~= "number" then
        values[name] = 0
    end
    values[name] = math.max(0, math.min(values[name] + value, 1))
end

---@param action_set foundation.InputSystem.ActionSet
---@param action_set_values foundation.InputSystem.ActionSetValues
local function updateScalarActions(action_set, action_set_values)
    -- 键盘没有标量输入组件，跳过（虽然市面上确实存在压感键盘……但应该没有什么软件会专门适配一款支持“轻推W向前”的键盘🤣）
    -- 鼠标没有标量输入组件，跳过

    for name, action in action_set:scalarActions() do
        for _, binding in action:controllerBindings() do
            for i = 1, 4 do
                if XInput.isConnected(i) then
                    if binding.type == "axis" then
                        if binding.axis == XInputAdaptor.Axis.LeftTrigger then
                            addScalarActionValue(action_set_values.scalar_action_values, name, XInput.getLeftTrigger(i))
                        elseif binding.axis == XInputAdaptor.Axis.RightTrigger then
                            addScalarActionValue(action_set_values.scalar_action_values, name, XInput.getRightTrigger(i))
                        end
                    elseif binding.type == "key" then
                        if XInputAdaptor.getKeyState(xinput_adaptor_map[i], binding.key) then
                            addScalarActionValue(action_set_values.scalar_action_values, name, 1) -- 按键按下映射为 1
                        end
                    end
                end
            end
        end
    end
end

---@param action_set foundation.InputSystem.ActionSet
---@param action_set_values foundation.InputSystem.ActionSetValues
local function updateActionSet(action_set, action_set_values)
    updateBooleanActions(action_set, action_set_values)
    updateScalarActions(action_set, action_set_values)
    -- TODO: vector2 actions
end

function InputSystem.update()
    for _, v in pairs(raw_action_set_values) do
        copyLastActionSetValues(v)
        clearActionSetValues(v)
    end
    copyLastActionSetValues(merged_action_set_values)
    clearActionSetValues(merged_action_set_values)
    updateXInput()
    updateDirectInput()
    for name, action_set in pairs(action_sets) do
        updateActionSet(action_set, raw_action_set_values[name])
    end
end

--#endregion
--------------------------------------------------------------------------------
--- 读取动作值辅助函数
--#region

---@param value boolean?
---@return boolean
local function toBoolean(value)
    return not (not value)
end

---@param value number?
---@return number
local function toScalar(value)
    if type(value) == "number" then
        return value
    end
    return 0.0
end

---@param value foundation.InputSystem.Vector2?
---@return foundation.InputSystem.Vector2
local function toVector2(value)
    if type(value) == "table" then
        if type(value.x) == "number" and type(value.y) == "number" then
            return value
        end
    end
    return { x = 0.0, y = 0.0 }
end

--#endregion
--------------------------------------------------------------------------------
--- 读取动作值
--#region

--- 读取布尔类型的动作值  
--- 可能值有：  
--- * `true`：激活  
--- * `false`：未激活  
---@param name string
---@return boolean
function InputSystem.getBooleanAction(name)
    assert(type(name) == "string", "name must be a string")
    return toBoolean(getCurrentActionSetValues().boolean_action_values[name])
end

--- 读取标量动作值  
--- 标量值被映射到 0.0 到 1.0 的归一化实数  
---@param name string
---@return number
function InputSystem.getScalarAction(name)
    assert(type(name) == "string", "name must be a string")
    return toScalar(getCurrentActionSetValues().scalar_action_values[name])
end

--- 读取二维矢量动作值  
--- 二维矢量动作值被映射归一化矢量（长度范围 0.0 到 1.0）  
---@param name string
---@return number, number
function InputSystem.getVector2Action(name)
    assert(type(name) == "string", "name must be a string")
    local value = toVector2(getCurrentActionSetValues().vector2_action_values[name])
    return value.x, value.y
end

--#endregion
--------------------------------------------------------------------------------
--- 追踪动作值变化
--#region

---@param name string
---@return boolean, boolean, integer
local function getLastAndCurrentBooleanAction(name)
    local action_set_values = getCurrentActionSetValues()
    local last = toBoolean(action_set_values.last_boolean_action_values[name])
    local current = toBoolean(action_set_values.boolean_action_values[name])
    return last, current, action_set_values.boolean_action_frames[name] or 0
end

--- 布尔动作是否在当前帧激活  
--- 填写后面两个参数后会启用重复触发器，
--- repeat_delay 参数用于指定多少帧后开始执行，
--- repeat_interval 参数用于指定执行间隔
---@param name string
---@param repeat_delay integer?
---@param repeat_interval integer?
---@return boolean
function InputSystem.isBooleanActionActivated(name, repeat_delay, repeat_interval)
    assert(type(name) == "string", "name must be a string")
    if repeat_delay or repeat_interval then
        assert(type(repeat_delay) == "number", "repeat_delay must be a number (integer)")
        assert(type(repeat_interval) == "number", "repeat_interval must be a number (integer)")
        assert(repeat_delay >= 0, "repeat_delay must be greater than or equal to 0")
        assert(repeat_interval >= 0, "repeat_interval must be greater than or equal to 0")
    end
    local last, current = getLastAndCurrentBooleanAction(name)
    return (not last) and current
end

--- 布尔动作是否在当前帧释放  
---@param name string
---@return boolean
function InputSystem.isBooleanActionDeactivated(name)
    assert(type(name) == "string", "name must be a string")
    local last, current = getLastAndCurrentBooleanAction(name)
    return last and (not current)
end

--- 读取标量动作值的增量  
--- 映射规则：  
--- * `false` -> `false`: 0  
--- * `false` -> `true`: 1  
--- * `true` -> `true`: 0  
--- * `true` -> `false`: -1  
---@param name string
---@return number
function InputSystem.getBooleanActionIncrement(name)
    assert(type(name) == "string", "name must be a string")
    local last, current = getLastAndCurrentBooleanAction(name)
    if (not last) and current then
        return 1
    elseif last and (not current) then
        return -1
    else
        return 0
    end
end

--- 读取标量动作值的增量，负值代表减少  
---@param name string
---@return number
function InputSystem.getScalarActionIncrement(name)
    assert(type(name) == "string", "name must be a string")
    local action_set_values = getCurrentActionSetValues()
    local last = toScalar(action_set_values.last_scalar_action_values[name])
    local current = toScalar(action_set_values.scalar_action_values[name])
    return current - last
end

--- 读取二维矢量动作值的增量，负值代表减少  
---@param name string
---@return number, number
function InputSystem.getVector2ActionIncrement(name)
    assert(type(name) == "string", "name must be a string")
    local action_set_values = getCurrentActionSetValues()
    local last = toVector2(action_set_values.last_vector2_action_values[name])
    local current = toVector2(action_set_values.vector2_action_values[name])
    return current.x - last.x, current.y - last.y
end

--#endregion
--------------------------------------------------------------------------------
--- 设置持久化
--#region

local function getDefaultSettingPath()
    return LocalFileStorage.getRootDirectory() .. "/input.json"
end

--- 不提供路径参数时，保存到默认位置
---@param path string?
function InputSystem.saveSetting(path)
    path = path or getDefaultSettingPath()
    local data = {}
    data.action_sets = copyTable(action_sets)
    data.setting = copyTable(setting)
    Files.writeStringWithBackup(path, cjson_util.format_json(cjson.encode(data)))
end

---@param source_action foundation.InputSystem.BooleanAction
---@param target_action foundation.InputSystem.BooleanAction
local function mergeBooleanAction(source_action, target_action)
    ---@param binding foundation.InputSystem.BooleanBinding
    local function isValidBinding(binding)
        return type(binding) == "table"
            and type(binding.type) == "string"
            and binding.type == "key"
            and type(binding.key) == "number"
    end
    ---@param source_bindings foundation.InputSystem.BooleanBinding[]
    ---@param target_bindings foundation.InputSystem.BooleanBinding[]
    local function mergeBindings(source_bindings, target_bindings)
        ---@type foundation.InputSystem.BooleanBinding[]
        local bindings = {}
        for _, source_binding in ipairs(source_bindings) do
            if isValidBinding(source_binding) then
                table.insert(bindings, source_binding)
            end
        end
        if #bindings > 0 then
            clearArray(target_bindings)
            appendToArray(target_bindings, bindings)
        end
    end
    if type(source_action.keyboard_bindings) == "table" then
        mergeBindings(source_action.keyboard_bindings, target_action.keyboard_bindings)
    end
    if type(source_action.mouse_bindings) == "table" then
        mergeBindings(source_action.mouse_bindings, target_action.mouse_bindings)
    end
    if type(source_action.controller_bindings) == "table" then
        mergeBindings(source_action.controller_bindings, target_action.controller_bindings)
    end
    if type(source_action.hid_bindings) == "table" then
        mergeBindings(source_action.hid_bindings, target_action.hid_bindings)
    end
end

---@param source_actions table<string, foundation.InputSystem.BooleanAction>
---@param target_actions table<string, foundation.InputSystem.BooleanAction>
local function mergeBooleanActions(source_actions, target_actions)
    for _, source_action in pairs(source_actions) do
        if type(source_action) == "table" then
            if type(source_action.name) == "string" then
                local target_action = target_actions[source_action.name]
                if target_action then
                    mergeBooleanAction(source_action, target_action)
                end
            end
        end
    end
end

---@param source_action foundation.InputSystem.ScalarAction
---@param target_action foundation.InputSystem.ScalarAction
local function mergeScalarAction(source_action, target_action)
    ---@param binding foundation.InputSystem.ScalarBinding
    local function isValidBinding(binding)
        return type(binding) == "table"
            and type(binding.type) == "string"
            and (binding.type == "key" or binding.type == "axis")
            and type(binding.key) == "number"
            and type(binding.axis) == "number"
    end
    ---@param source_bindings foundation.InputSystem.ScalarBinding[]
    ---@param target_bindings foundation.InputSystem.ScalarBinding[]
    local function mergeBindings(source_bindings, target_bindings)
        ---@type foundation.InputSystem.ScalarBinding[]
        local bindings = {}
        for _, source_binding in ipairs(source_bindings) do
            if isValidBinding(source_binding) then
                table.insert(bindings, source_binding)
            end
        end
        if #bindings > 0 then
            clearArray(target_bindings)
            appendToArray(target_bindings, bindings)
        end
    end
    if type(source_action.keyboard_bindings) == "table" then
        mergeBindings(source_action.keyboard_bindings, target_action.keyboard_bindings)
    end
    if type(source_action.mouse_bindings) == "table" then
        mergeBindings(source_action.mouse_bindings, target_action.mouse_bindings)
    end
    if type(source_action.controller_bindings) == "table" then
        mergeBindings(source_action.controller_bindings, target_action.controller_bindings)
    end
    if type(source_action.hid_bindings) == "table" then
        mergeBindings(source_action.hid_bindings, target_action.hid_bindings)
    end
end

---@param source_actions table<string, foundation.InputSystem.ScalarAction>
---@param target_actions table<string, foundation.InputSystem.ScalarAction>
local function mergeScalarActions(source_actions, target_actions)
    for _, source_action in pairs(source_actions) do
        if type(source_action) == "table" then
            if type(source_action.name) == "string" then
                local target_action = target_actions[source_action.name]
                if target_action then
                    mergeScalarAction(source_action, target_action)
                end
            end
        end
    end
end

---@param source_action foundation.InputSystem.Vector2Action
---@param target_action foundation.InputSystem.Vector2Action
local function mergeVector2Action(source_action, target_action)
    ---@param binding foundation.InputSystem.Vector2Binding
    local function isValidBinding(binding)
        return type(binding) == "table"
            and type(binding.type) == "string"
            and (binding.type == "key" or binding.type == "axis" or binding.type == "joystick")
            and type(binding.joystick) == "number"
            and type(binding.x_axis) == "number"
            and type(binding.y_axis) == "number"
            and type(binding.positive_x_key) == "number"
            and type(binding.negative_x_key) == "number"
            and type(binding.positive_y_key) == "number"
            and type(binding.negative_y_key) == "number"
    end
    ---@param source_bindings foundation.InputSystem.Vector2Binding[]
    ---@param target_bindings foundation.InputSystem.Vector2Binding[]
    local function mergeBindings(source_bindings, target_bindings)
        ---@type foundation.InputSystem.Vector2Binding[]
        local bindings = {}
        for _, source_binding in ipairs(source_bindings) do
            if isValidBinding(source_binding) then
                table.insert(bindings, source_binding)
            end
        end
        if #bindings > 0 then
            clearArray(target_bindings)
            appendToArray(target_bindings, bindings)
        end
    end
    if type(source_action.keyboard_bindings) == "table" then
        mergeBindings(source_action.keyboard_bindings, target_action.keyboard_bindings)
    end
    if type(source_action.mouse_bindings) == "table" then
        mergeBindings(source_action.mouse_bindings, target_action.mouse_bindings)
    end
    if type(source_action.controller_bindings) == "table" then
        mergeBindings(source_action.controller_bindings, target_action.controller_bindings)
    end
    if type(source_action.hid_bindings) == "table" then
        mergeBindings(source_action.hid_bindings, target_action.hid_bindings)
    end
end

---@param source_actions table<string, foundation.InputSystem.Vector2Action>
---@param target_actions table<string, foundation.InputSystem.Vector2Action>
local function mergeVector2Actions(source_actions, target_actions)
    for _, source_action in pairs(source_actions) do
        if type(source_action) == "table" then
            if type(source_action.name) == "string" then
                local target_action = target_actions[source_action.name]
                if target_action then
                    mergeVector2Action(source_action, target_action)
                end
            end
        end
    end
end

---@param input_action_set foundation.InputSystem.ActionSet
local function mergeActionSet(input_action_set)
    if type(input_action_set) ~= "table" then
        return
    end
    if type(input_action_set.name) ~= "string" then
        return
    end
    local target_action_set = action_sets[input_action_set.name]
    if not target_action_set then
        return
    end
    if type(input_action_set.boolean_actions) == "table" then
        mergeBooleanActions(input_action_set.boolean_actions, target_action_set.boolean_actions)
        mergeScalarActions(input_action_set.scalar_actions, target_action_set.scalar_actions)
        mergeVector2Actions(input_action_set.vector2_actions, target_action_set.vector2_actions)
    end
end

--- 不提供路径参数时，从默认位置读取
---@param path string?
function InputSystem.loadSetting(path)
    path = path or getDefaultSettingPath()
    local content = Files.readString(path)
    local r, data = pcall(cjson.decode, content)
    if not r then
        return
    end

    ---@type table<string, foundation.InputSystem.ActionSet>?
    local data_action_sets = data.action_sets
    ---@type foundation.InputSystem.Setting?
    local data_setting = data.setting

    if type(data_action_sets) == "table" then
        for _, data_action_set in pairs(data_action_sets) do
            mergeActionSet(data_action_set)
        end
    end
    if type(data_setting) == "table" then
        for k, v in pairs(setting) do
            if type(v) == type(data_setting[k]) then
                setting[k] = data_setting[k]
            end
        end
    end
end

--#endregion
--------------------------------------------------------------------------------

return InputSystem
