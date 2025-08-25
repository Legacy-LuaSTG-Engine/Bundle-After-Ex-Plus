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

local SQRT2_2 = 0.7071067811865476

--- 输入系统
---@class foundation.InputSystem
local InputSystem = {}

--------------------------------------------------------------------------------
--- 辅助函数：日志
--#region

local LOG_HEADER = "[foundation.InputSystem] "

local function logInfo(fmt, ...)
    lstg.Log(2, LOG_HEADER .. string.format(fmt, ...))
end

local function logWarn(fmt, ...)
    lstg.Log(3, LOG_HEADER .. string.format(fmt, ...))
end

local function logError(fmt, ...)
    lstg.Log(4, LOG_HEADER .. string.format(fmt, ...))
end

--#endregion
--------------------------------------------------------------------------------
--- 辅助函数：数学、数组和表操作
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
---@param index integer
local function safeRemoveArrayValueAt(array, index)
    assert(type(index) == "number", "index must be a number")
    assert(math.floor(index) == index, "index must be a integral number")
    assert(index >= 1 and index <= #array, "index out of bound")
    table.remove(array, index)
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
---@param element T
local function appendOneToArray(array, element)
    array[#array + 1] = element
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

---@param v number
---@param min number
---@param max number
---@return number
local function clamp(v, min, max)
    return math.max(min, math.min(v, max))
end

---@param v number
---@return number
local function round(v)
    local l, h = math.floor(v), math.ceil(v)
    if v - l < h - v then
        return l
    else
        return h
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

local NAME_ERROR_MESSAGE = "name can only contain uppercase letters A to Z, lowercase letters a to z, numbers 0 to 9, underscores _, and hyphens -, but got '%s'"

---@param name string
local function checkActionSetNameOrActionName(name)
    if name:len() == 0 then
        error("name cannot be empty")
    end
    if name:len() > 255 then
        error(("length of name '%s' greater than 255"):format(name))
    end
    if not string.match(name, "^([0-9A-Za-z_%-]+)$") then
        error(NAME_ERROR_MESSAGE:format(name))
    end
end

--#endregion
--------------------------------------------------------------------------------
--- 布尔动作：用于按键组件，比如键盘按键
--#region

---@class foundation.InputSystem.BooleanBinding : foundation.InputSystem.Binding
---@field key integer

---@class foundation.InputSystem.BooleanAction : foundation.InputSystem.Action
---@field package keyboard_bindings   foundation.InputSystem.BooleanBinding[]
---@field package mouse_bindings      foundation.InputSystem.BooleanBinding[]
---@field package controller_bindings foundation.InputSystem.BooleanBinding[]
---@field package hid_bindings        foundation.InputSystem.BooleanBinding[]
local BooleanAction = {}

--#region Keyboard

function BooleanAction:keyboardBindings()
    return ipairs(self.keyboard_bindings)
end

---@param key integer
---@return foundation.InputSystem.BooleanAction
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

---@param index integer
function BooleanAction:removeKeyboardBinding(index)
    safeRemoveArrayValueAt(self.keyboard_bindings, index)
end

function BooleanAction:clearKeyboardBindings()
    clearArray(self.keyboard_bindings)
end

--#endregion

--#region Mouse

function BooleanAction:mouseBindings()
    return ipairs(self.mouse_bindings)
end

---@param key integer
---@return foundation.InputSystem.BooleanAction
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

---@param index integer
function BooleanAction:removeMouseBinding(index)
    safeRemoveArrayValueAt(self.mouse_bindings, index)
end

function BooleanAction:clearMouseBindings()
    clearArray(self.mouse_bindings)
end

--#endregion

--#region Controller

function BooleanAction:controllerBindings()
    return ipairs(self.controller_bindings)
end

---@param key integer
---@return foundation.InputSystem.BooleanAction
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

---@param index integer
function BooleanAction:removeControllerBinding(index)
    safeRemoveArrayValueAt(self.controller_bindings, index)
end

function BooleanAction:clearControllerBindings()
    clearArray(self.controller_bindings)
end

--#endregion

--#region HID

function BooleanAction:hidBindings()
    return ipairs(self.hid_bindings)
end

---@param key integer
---@return foundation.InputSystem.BooleanAction
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

---@param index integer
function BooleanAction:removeHidBinding(index)
    safeRemoveArrayValueAt(self.hid_bindings, index)
end

function BooleanAction:clearHidBindings()
    clearArray(self.hid_bindings)
end

--#endregion

function BooleanAction:clearBindings()
    self:clearKeyboardBindings()
    self:clearMouseBindings()
    self:clearControllerBindings()
    self:clearHidBindings()
end

---@param name string
---@return foundation.InputSystem.BooleanAction
function BooleanAction.create(name)
    ---@type foundation.InputSystem.BooleanAction
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
--- 标量动作：用于单轴组件，比如手柄扳机
--#region

---@class foundation.InputSystem.ScalarBinding : foundation.InputSystem.Binding
---@field key  integer
---@field axis integer

---@class foundation.InputSystem.ScalarAction : foundation.InputSystem.Action
---@field package normalized          boolean default to true
---@field package keyboard_bindings   foundation.InputSystem.ScalarBinding[]
---@field package mouse_bindings      foundation.InputSystem.ScalarBinding[]
---@field package controller_bindings foundation.InputSystem.ScalarBinding[]
---@field package hid_bindings        foundation.InputSystem.ScalarBinding[]
local ScalarAction = {}

function ScalarAction:isNormalized()
    return self.normalized
end

--#region Keyboard

function ScalarAction:keyboardBindings()
    return ipairs(self.keyboard_bindings)
end

---@param key integer
---@return foundation.InputSystem.ScalarAction
function ScalarAction:addKeyboardKeyBinding(key)
    local exists = isArrayContainsIf(self.keyboard_bindings, function(value)
        return value.type == "key" and value.key == key
    end)
    if exists then
        return self
    end
    table.insert(self.keyboard_bindings, {
        type = "key",
        key = key,
        axis = 0,
    })
    return self
end

---@param index integer
function ScalarAction:removeKeyboardBinding(index)
    safeRemoveArrayValueAt(self.keyboard_bindings, index)
end

function ScalarAction:clearKeyboardBindings()
    clearArray(self.keyboard_bindings)
end

--#endregion

--#region Mouse

function ScalarAction:mouseBindings()
    return ipairs(self.mouse_bindings)
end

---@param key integer
---@return foundation.InputSystem.ScalarAction
function ScalarAction:addMouseKeyBinding(key)
    local exists = isArrayContainsIf(self.mouse_bindings, function(value)
        return value.type == "key" and value.key == key
    end)
    if exists then
        return self
    end
    table.insert(self.mouse_bindings, {
        type = "key",
        key = key,
        axis = 0,
    })
    return self
end

---@param index integer
function ScalarAction:removeMouseBinding(index)
    safeRemoveArrayValueAt(self.mouse_bindings, index)
end

function ScalarAction:clearMouseBindings()
    clearArray(self.mouse_bindings)
end

--#endregion

--#region Controller

function ScalarAction:controllerBindings()
    return ipairs(self.controller_bindings)
end

---@param key integer
---@return foundation.InputSystem.ScalarAction
function ScalarAction:addControllerKeyBinding(key)
    local exists = isArrayContainsIf(self.controller_bindings, function(value)
        return value.type == "key" and value.key == key
    end)
    if exists then
        return self
    end
    table.insert(self.controller_bindings, {
        type = "key",
        key = key,
        axis = 0,
    })
    return self
end

---@param axis integer
---@return foundation.InputSystem.ScalarAction
function ScalarAction:addControllerAxisBinding(axis)
    local exists = isArrayContainsIf(self.controller_bindings, function(value)
        return value.type == "axis" and value.axis == axis
    end)
    if exists then
        return self
    end
    table.insert(self.controller_bindings, {
        type = "axis",
        key = axis,
        axis = 0,
    })
    return self
end

---@param index integer
function ScalarAction:removeControllerBinding(index)
    safeRemoveArrayValueAt(self.controller_bindings, index)
end

function ScalarAction:clearControllerBindings()
    clearArray(self.controller_bindings)
end

--#endregion

--#region HID

function ScalarAction:hidBindings()
    return ipairs(self.hid_bindings)
end

---@param key integer
---@return foundation.InputSystem.ScalarAction
function ScalarAction:addHidKeyBinding(key)
    local exists = isArrayContainsIf(self.hid_bindings, function(value)
        return value.type == "key" and value.key == key
    end)
    if exists then
        return self
    end
    table.insert(self.hid_bindings, {
        type = "key",
        key = key,
        axis = 0,
    })
    return self
end

---@param axis integer
---@return foundation.InputSystem.ScalarAction
function ScalarAction:addHidAxisBinding(axis)
    local exists = isArrayContainsIf(self.hid_bindings, function(value)
        return value.type == "axis" and value.axis == axis
    end)
    if exists then
        return self
    end
    table.insert(self.hid_bindings, {
        type = "axis",
        key = axis,
        axis = 0,
    })
    return self
end

---@param index integer
function ScalarAction:removeHidBinding(index)
    safeRemoveArrayValueAt(self.hid_bindings, index)
end

function ScalarAction:clearHidBindings()
    clearArray(self.hid_bindings)
end

--#endregion

function ScalarAction:clearBindings()
    self:clearKeyboardBindings()
    self:clearMouseBindings()
    self:clearControllerBindings()
    self:clearHidBindings()
end

---@param name string
---@param non_normalized boolean?
---@return foundation.InputSystem.ScalarAction
function ScalarAction.create(name, non_normalized)
    ---@type foundation.InputSystem.ScalarAction
    local instance = {
        name = name,
        type = "scalar",
        normalized = not non_normalized,
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
--- 二维矢量动作：用于双轴组件，比如手柄摇杆
--#region

---@class foundation.InputSystem.Vector2Binding : foundation.InputSystem.Binding
---@field joystick       integer
---@field x_axis         integer
---@field y_axis         integer
---@field positive_x_key integer
---@field negative_x_key integer
---@field positive_y_key integer
---@field negative_y_key integer

---@param positive_x_key integer
---@param negative_x_key integer
---@param positive_y_key integer
---@param negative_y_key integer
---@return foundation.InputSystem.Vector2Binding
local function createKeyVector2Binding(positive_x_key, negative_x_key, positive_y_key, negative_y_key)
    ---@type foundation.InputSystem.Vector2Binding
    local result = {
        type = "key",
        joystick = 0,
        x_axis = 0,
        y_axis = 0,
        positive_x_key = positive_x_key,
        negative_x_key = negative_x_key,
        positive_y_key = positive_y_key,
        negative_y_key = negative_y_key,
    }
    return result
end

---@param x_axis integer
---@param y_axis integer
---@return foundation.InputSystem.Vector2Binding
local function createAxisVector2Binding(x_axis, y_axis)
    ---@type foundation.InputSystem.Vector2Binding
    local result = {
        type = "axis",
        joystick = 0,
        x_axis = x_axis,
        y_axis = y_axis,
        positive_x_key = 0,
        negative_x_key = 0,
        positive_y_key = 0,
        negative_y_key = 0,
    }
    return result
end

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
---@field package normalized          boolean default to true
---@field package keyboard_bindings   foundation.InputSystem.Vector2Binding[]
---@field package mouse_bindings      foundation.InputSystem.Vector2Binding[]
---@field package controller_bindings foundation.InputSystem.Vector2Binding[]
---@field package hid_bindings        foundation.InputSystem.Vector2Binding[]
local Vector2Action = {}

function Vector2Action:isNormalized()
    return self.normalized
end

--#region Keyboard

function Vector2Action:keyboardBindings()
    return ipairs(self.keyboard_bindings)
end

---@param positive_x_key integer
---@param negative_x_key integer
---@param positive_y_key integer
---@param negative_y_key integer
---@return foundation.InputSystem.Vector2Action
function Vector2Action:addKeyboardKeyBinding(positive_x_key, negative_x_key, positive_y_key, negative_y_key)
    local exists = isArrayContainsIf(self.keyboard_bindings, function(value)
        return value.type == "key"
            and value.positive_x_key == positive_x_key
            and value.negative_x_key == negative_x_key
            and value.positive_y_key == positive_y_key
            and value.negative_y_key == negative_y_key
    end)
    if exists then
        return self
    end
    local binding = createKeyVector2Binding(positive_x_key, negative_x_key, positive_y_key, negative_y_key)
    table.insert(self.keyboard_bindings, binding)
    return self
end

---@param index integer
function Vector2Action:removeKeyboardBinding(index)
    safeRemoveArrayValueAt(self.keyboard_bindings, index)
end

function Vector2Action:clearKeyboardBindings()
    clearArray(self.keyboard_bindings)
end

--#endregion

--#region Mouse

function Vector2Action:mouseBindings()
    return ipairs(self.mouse_bindings)
end

---@param positive_x_key integer
---@param negative_x_key integer
---@param positive_y_key integer
---@param negative_y_key integer
---@return foundation.InputSystem.Vector2Action
function Vector2Action:addMouseKeyBinding(positive_x_key, negative_x_key, positive_y_key, negative_y_key)
    local exists = isArrayContainsIf(self.mouse_bindings, function(value)
        return value.type == "key"
            and value.positive_x_key == positive_x_key
            and value.negative_x_key == negative_x_key
            and value.positive_y_key == positive_y_key
            and value.negative_y_key == negative_y_key
    end)
    if exists then
        return self
    end
    local binding = createKeyVector2Binding(positive_x_key, negative_x_key, positive_y_key, negative_y_key)
    table.insert(self.mouse_bindings, binding)
    return self
end

---@param index integer
function Vector2Action:removeMouseBinding(index)
    safeRemoveArrayValueAt(self.mouse_bindings, index)
end

function Vector2Action:clearMouseBindings()
    clearArray(self.mouse_bindings)
end

--#endregion

--#region Controller

function Vector2Action:controllerBindings()
    return ipairs(self.controller_bindings)
end

---@param positive_x_key integer
---@param negative_x_key integer
---@param positive_y_key integer
---@param negative_y_key integer
---@return foundation.InputSystem.Vector2Action
function Vector2Action:addControllerKeyBinding(positive_x_key, negative_x_key, positive_y_key, negative_y_key)
    local exists = isArrayContainsIf(self.controller_bindings, function(value)
        return value.type == "key"
            and value.positive_x_key == positive_x_key
            and value.negative_x_key == negative_x_key
            and value.positive_y_key == positive_y_key
            and value.negative_y_key == negative_y_key
    end)
    if exists then
        return self
    end
    local binding = createKeyVector2Binding(positive_x_key, negative_x_key, positive_y_key, negative_y_key)
    table.insert(self.controller_bindings, binding)
    return self
end

---@param x_axis integer
---@param y_axis integer
---@return foundation.InputSystem.Vector2Action
function Vector2Action:addControllerAxisBinding(x_axis, y_axis)
    local exists = isArrayContainsIf(self.controller_bindings, function(value)
        return value.type == "axis" and value.x_axis == x_axis and value.y_axis == y_axis
    end)
    if exists then
        return self
    end
    table.insert(self.controller_bindings, createAxisVector2Binding(x_axis, y_axis))
    return self
end

---@param joystick integer
---@return foundation.InputSystem.Vector2Action
function Vector2Action:addControllerJoystickBinding(joystick)
    local exists = isArrayContainsIf(self.controller_bindings, function(value)
        return value.type == "joystick" and value.joystick == joystick
    end)
    if exists then
        return self
    end
    table.insert(self.controller_bindings, createJoystickVector2Binding(joystick))
    return self
end

---@param index integer
function Vector2Action:removeControllerBinding(index)
    safeRemoveArrayValueAt(self.controller_bindings, index)
end

function Vector2Action:clearControllerBindings()
    clearArray(self.controller_bindings)
end

--#endregion

--#region HID

function Vector2Action:hidBindings()
    return ipairs(self.hid_bindings)
end

---@param positive_x_key integer
---@param negative_x_key integer
---@param positive_y_key integer
---@param negative_y_key integer
---@return foundation.InputSystem.Vector2Action
function Vector2Action:addHidKeyBinding(positive_x_key, negative_x_key, positive_y_key, negative_y_key)
    local exists = isArrayContainsIf(self.hid_bindings, function(value)
        return value.type == "key"
            and value.positive_x_key == positive_x_key
            and value.negative_x_key == negative_x_key
            and value.positive_y_key == positive_y_key
            and value.negative_y_key == negative_y_key
    end)
    if exists then
        return self
    end
    local binding = createKeyVector2Binding(positive_x_key, negative_x_key, positive_y_key, negative_y_key)
    table.insert(self.hid_bindings, binding)
    return self
end

---@param x_axis integer
---@param y_axis integer
---@return foundation.InputSystem.Vector2Action
function Vector2Action:addHidAxisBinding(x_axis, y_axis)
    local exists = isArrayContainsIf(self.hid_bindings, function(value)
        return value.type == "axis" and value.x_axis == x_axis and value.y_axis == y_axis
    end)
    if exists then
        return self
    end
    table.insert(self.hid_bindings, createAxisVector2Binding(x_axis, y_axis))
    return self
end

---@param joystick integer
---@return foundation.InputSystem.Vector2Action
function Vector2Action:addHidJoystickBinding(joystick)
    local exists = isArrayContainsIf(self.hid_bindings, function(value)
        return value.type == "joystick" and value.joystick == joystick
    end)
    if exists then
        return self
    end
    table.insert(self.hid_bindings, createJoystickVector2Binding(joystick))
    return self
end

---@param index integer
function Vector2Action:removeHidBinding(index)
    safeRemoveArrayValueAt(self.hid_bindings, index)
end

function Vector2Action:clearHidBindings()
    clearArray(self.hid_bindings)
end

--#endregion

function Vector2Action:clearBindings()
    self:clearKeyboardBindings()
    self:clearMouseBindings()
    self:clearControllerBindings()
    self:clearHidBindings()
end

---@param name string
---@param non_normalized boolean?
---@return foundation.InputSystem.Vector2Action
function Vector2Action.create(name, non_normalized)
    ---@type foundation.InputSystem.Vector2Action
    local instance = {
        name = name,
        type = "vector2",
        normalized = not non_normalized,
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

---@type fun(action_set:foundation.InputSystem.ActionSet, action:foundation.InputSystem.Action)[]
local on_action_added = {} -- internal hook

---@type fun(action_set:foundation.InputSystem.ActionSet, action:foundation.InputSystem.Action)[]
local on_action_removed = {} -- internal hook

---@class foundation.InputSystem.ActionSet
---@field         name            string
---@field private action_names    table<string, foundation.InputSystem.ActionType>
---@field package boolean_actions table<string, foundation.InputSystem.BooleanAction>
---@field package scalar_actions  table<string, foundation.InputSystem.ScalarAction>
---@field package vector2_actions table<string, foundation.InputSystem.Vector2Action>
local ActionSet = {}

function ActionSet:booleanActions()
    return pairs(self.boolean_actions)
end

---@param name string
---@return foundation.InputSystem.BooleanAction
function ActionSet:addBooleanAction(name)
    assert(type(name) == "string", "name must be a string")
    checkActionSetNameOrActionName(name)
    if self.boolean_actions[name] then
        return self.boolean_actions[name]
    end
    if self.action_names[name] then
        error(("Action name '%s' already exists (type: %s)"):format(name, self.action_names[name]))
    end
    local action = BooleanAction.create(name)
    self.action_names[name] = "boolean"
    self.boolean_actions[name] = action
    for _, callback in ipairs(on_action_added) do
        callback(self, action)
    end
    return action
end

---@param name string
function ActionSet:removeBooleanAction(name)
    assert(type(name) == "string", "name must be a string")
    if self.action_names[name] == "boolean" then
        self.action_names[name] = nil
    end
    if self.boolean_actions[name] then
        for _, callback in ipairs(on_action_removed) do
            callback(self, self.boolean_actions[name])
        end
        self.boolean_actions[name] = nil
    end
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
---@param non_normalized boolean?
---@return foundation.InputSystem.ScalarAction
function ActionSet:addScalarAction(name, non_normalized)
    assert(type(name) == "string", "name must be a string")
    checkActionSetNameOrActionName(name)
    if self.scalar_actions[name] then
        return self.scalar_actions[name]
    end
    if self.action_names[name] then
        error(("Action name '%s' already exists (type: %s)"):format(name, self.action_names[name]))
    end
    local action = ScalarAction.create(name, non_normalized)
    self.action_names[name] = "scalar"
    self.scalar_actions[name] = action
    for _, callback in ipairs(on_action_added) do
        callback(self, action)
    end
    return action
end

---@param name string
function ActionSet:removeScalarAction(name)
    assert(type(name) == "string", "name must be a string")
    if self.action_names[name] == "scalar" then
        self.action_names[name] = nil
    end
    if self.scalar_actions[name] then
        for _, callback in ipairs(on_action_removed) do
            callback(self, self.scalar_actions[name])
        end
        self.scalar_actions[name] = nil
    end
end

---@param name string
---@return foundation.InputSystem.ScalarAction
function ActionSet:getScalarAction(name)
    assert(type(name) == "string", "name must be a string")
    return assert(self.scalar_actions[name], ("ScalarAction '%s' does not exists"):format(name))
end

function ActionSet:vector2Actions()
    return pairs(self.vector2_actions)
end

---@param name string
---@param non_normalized boolean?
---@return foundation.InputSystem.Vector2Action
function ActionSet:addVector2Action(name, non_normalized)
    assert(type(name) == "string", "name must be a string")
    checkActionSetNameOrActionName(name)
    if self.vector2_actions[name] then
        return self.vector2_actions[name]
    end
    if self.action_names[name] then
        error(("Action name '%s' already exists (type: %s)"):format(name, self.action_names[name]))
    end
    local action = Vector2Action.create(name, non_normalized)
    self.action_names[name] = "vector2"
    self.vector2_actions[name] = action
    for _, callback in ipairs(on_action_added) do
        callback(self, action)
    end
    return action
end

---@param name string
function ActionSet:removeVector2Action(name)
    assert(type(name) == "string", "name must be a string")
    if self.action_names[name] == "vector2" then
        self.action_names[name] = nil
    end
    if self.vector2_actions[name] then
        for _, callback in ipairs(on_action_removed) do
            callback(self, self.vector2_actions[name])
        end
        self.vector2_actions[name] = nil
    end
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
        action_names = {},
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
    checkActionSetNameOrActionName(name)
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
        action_sets[name] = nil
    end
end

---@param name string
---@return foundation.InputSystem.ActionSet
function InputSystem.getActionSet(name)
    assert(type(name) == "string", "name must be a string")
    return assert(action_sets[name], ("ActionSet '%s' does not exists"):format(name))
end

--- 第一个参数是可选的过滤器，如果不传该参数，表示不进行过滤  
---@see foundation.InputSystem.update
---@see foundation.InputSystem.quantize
---@see foundation.InputSystem.SerializeContext.initialize
---@param include_action_set_names string[]?
---@param action_set_name string
---@return boolean 
local function isActionSetIncluded(include_action_set_names, action_set_name)
    if include_action_set_names then
        return isArrayContains(include_action_set_names, action_set_name)
    else
        return true
    end
end

--#endregion
--------------------------------------------------------------------------------
--- 输入系统内部状态
--#region

---@class foundation.InputSystem.Vector2
---@field x number
---@field y number

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

--- internal HOOK
---@param action_set foundation.InputSystem.ActionSet
---@param action foundation.InputSystem.Action
local function initializeActionSetActionValues(action_set, action)
    local action_set_values = assert(raw_action_set_values[action_set.name], ("ActionSetValues '%s' does not exists"):format(action_set.name))
    if action.type == "boolean" then
        action_set_values.last_boolean_action_values[action.name] = false
        action_set_values.boolean_action_values[action.name] = false
        action_set_values.boolean_action_frames[action.name] = -1
    elseif action.type == "scalar" then
        ---@cast action foundation.InputSystem.ScalarAction
        action_set_values.last_scalar_action_values[action.name] = 0
        action_set_values.scalar_action_values[action.name] = 0
    elseif action.type == "vector2" then
        ---@cast action foundation.InputSystem.Vector2Action
        action_set_values.last_vector2_action_values[action.name] = { x = 0, y = 0 }
        action_set_values.vector2_action_values[action.name] = { x = 0, y = 0 }
    else
        error(("unknown Action type '%s'"):format(action.type))
    end
end

--- internal HOOK
---@param action_set foundation.InputSystem.ActionSet
---@param action foundation.InputSystem.Action
local function uninitializeActionSetActionValues(action_set, action)
    local action_set_values = assert(raw_action_set_values[action_set.name], ("ActionSetValues '%s' does not exists"):format(action_set.name))
    if action.type == "boolean" then
        action_set_values.last_boolean_action_values[action.name] = nil
        action_set_values.boolean_action_values[action.name] = nil
        action_set_values.boolean_action_frames[action.name] = nil
    elseif action.type == "scalar" then
        action_set_values.last_scalar_action_values[action.name] = nil
        action_set_values.scalar_action_values[action.name] = nil
    elseif action.type == "vector2" then
        action_set_values.last_vector2_action_values[action.name] = nil
        action_set_values.vector2_action_values[action.name] = nil
    else
        error(("unknown Action type '%s'"):format(action.type))
    end
end

table.insert(on_action_added, initializeActionSetActionValues) -- internal HOOK
table.insert(on_action_removed, uninitializeActionSetActionValues) -- internal HOOK

--- internal HOOK
---@param action_set foundation.InputSystem.ActionSet
local function initializeActionSetValues(action_set)
    raw_action_set_values[action_set.name] = createActionSetValues()
end

--- internal HOOK
---@param action_set foundation.InputSystem.ActionSet
local function uninitializeActionSetValues(action_set)
    raw_action_set_values[action_set.name] = nil
end

table.insert(on_action_set_added, initializeActionSetValues) -- internal HOOK
table.insert(on_action_set_removed, uninitializeActionSetValues) -- internal HOOK

--#endregion
--------------------------------------------------------------------------------
--- 量化标量
--#region

---@alias foundation.InputSystem.QuantizedScalar.Mode
---| '"fixed_s1_7_24"'
---| '"fixed_s1_15_16"'
---| '"fixed_s1_23_8"'
---| '"fixed_s1_7_8"'
---| '"fixed_u8_24"'
---| '"fixed_u16_16"'
---| '"fixed_u24_8"'
---| '"fixed_u8_8"'
---| '"normalized_u8"'

local QUANTIZED_SCALAR_MODES = {
    fixed_s1_7_24 = {
        size = 4,
        mul = 16777216,
        min = -2147483647,
        max = 2147483647,
        v_min = -2147483647 / 16777216, -- -127.9999999
        v_max = 2147483647 / 16777216, -- 127.9999999
    },
    fixed_s1_15_16 = {
        size = 4,
        mul = 65536,
        min = -2147483647,
        max = 2147483647,
        v_min = -2147483647 / 65536, -- -32767.9999
        v_max = 2147483647 / 65536, -- 32767.9999
    },
    fixed_s1_23_8 = {
        size = 4,
        mul = 256,
        min = -2147483647,
        max = 2147483647,
        v_min = -2147483647 / 256, -- -8388607.99
        v_max = 2147483647 / 256, -- 8388607.99
    },
    fixed_s1_7_8 = {
        size = 2,
        mul = 256,
        min = -32767,
        max = 32767,
        v_min = -32767 / 256, -- -127.99
        v_max = 32767 / 256, -- 127.99
    },
    fixed_u8_24 = {
        size = 4,
        mul = 16777216,
        min = 0,
        max = 4294967295,
        v_min = 0,
        v_max = 4294967295 / 16777216, -- 255.9999999
    },
    fixed_u16_16 = {
        size = 4,
        mul = 65536,
        min = 0,
        max = 4294967295,
        v_min = 0,
        v_max = 4294967295 / 65536, -- 65535.9999
    },
    fixed_u24_8 = {
        size = 4,
        mul = 256,
        min = 0,
        max = 4294967295,
        v_min = 0,
        v_max = 4294967295 / 256, -- 16777215.99
    },
    fixed_u8_8 = {
        size = 2,
        mul = 256,
        min = 0,
        max = 65535,
        v_min = 0,
        v_max = 65535 / 256, -- 255.99
    },
    normalized_u8 = {
        size = 1,
        mul = 255,
        min = 0,
        max = 255,
        v_min = 0.0,
        v_max = 1.0
    },
}

---@class foundation.InputSystem.QuantizedScalar
---@field mode foundation.InputSystem.QuantizedScalar.Mode
---@field size integer
---@field mul  integer
---@field min  integer
---@field max  integer
---@field v    integer
local QuantizedScalar = {}

---@param v number
function QuantizedScalar:set(v)
    assert(type(v) == "number", "v must be a number")
    self.v = clamp(round(v * self.mul), self.min, self.max)
end

---@return number
function QuantizedScalar:get()
    return self.v / self.mul
end

---@param write fun(byte:integer)
function QuantizedScalar:toBytes(write)
    if self.size == 1 then
        assert(self.v >= 0 and self.v <= 255)
        write(self.v)
    elseif self.size == 2 then
        local v = math.abs(self.v)
        local l = v % 256
        local h = math.floor(v / 256) % 256
        if self.v < 0 then
            h = h + 128
        end
        assert(l >= 0 and h <= 255)
        assert(l >= 0 and h <= 255)
        write(l)
        write(h)
    elseif self.size == 4 then
        local v = math.abs(self.v)
        local lb = v % 256
        local lw = math.floor(v / 256) % 256
        local hb = math.floor(v / 65536) % 256
        local hw = math.floor(v / 16777216) % 256
        if self.v < 0 then
            hw = hw + 128
        end
        assert(lb >= 0 and lb <= 255)
        assert(lw >= 0 and lw <= 255)
        assert(hb >= 0 and hb <= 255)
        assert(hw >= 0 and hw <= 255)
        write(lb)
        write(lw)
        write(hb)
        write(hw)
    else
        error("internal error")
    end
end

---@param read fun():integer?, string?
---@return boolean result
---@return string? message
function QuantizedScalar:fromBytes(read)
    if self.size == 1 then
        local b, e = read()
        if not b then
            return false, e
        end
        self.v = b
        return true, nil
    elseif self.size == 2 then
        local l, el = read()
        if not l then
            return false, el
        end
        local h, eh = read()
        if not h then
            return false, eh
        end
        local sign = 1
        if h >= 128 then
            h = h - 128
            sign = -1
        end
        self.v = sign * (l + h * 256)
        return true, nil
    elseif self.size == 4 then
        local lb, elb = read()
        if not lb then
            return false, elb
        end
        local lw, elw = read()
        if not lw then
            return false, elw
        end
        local hb, ehb = read()
        if not hb then
            return false, ehb
        end
        local hw, ehw = read()
        if not hw then
            return false, ehw
        end
        local sign = 1
        if hw >= 128 then
            hw = hw - 128
            sign = -1
        end
        self.v = sign * (lb + lw * 256 + hb * 65536 + hw * 16777216)
        return true, nil
    else
        error("internal error")
        ---@diagnostic disable-next-line: missing-return
    end
end

---@param other foundation.InputSystem.QuantizedScalar
function QuantizedScalar:assign(other)
    assert(self.mode == other.mode, "mode not matched")
    self.v = other.v
end

---@param mode foundation.InputSystem.QuantizedScalar.Mode
---@return foundation.InputSystem.QuantizedScalar
function QuantizedScalar.create(mode)
    local m = assert(QUANTIZED_SCALAR_MODES[mode], "unknown QuantizedScalar mode " .. mode)
    ---@type foundation.InputSystem.QuantizedScalar
    return {
        mode = mode,
        size = m.size,
        mul = m.mul,
        min = m.min,
        max = m.max,
        v = 0,
        set = QuantizedScalar.set,
        get = QuantizedScalar.get,
        toBytes = QuantizedScalar.toBytes,
        fromBytes = QuantizedScalar.fromBytes,
        assign = QuantizedScalar.assign,
    }
end

---@return foundation.InputSystem.QuantizedScalar
local function createQuantizedScalar()
    return QuantizedScalar.create("fixed_s1_15_16")
end

---@return foundation.InputSystem.QuantizedScalar
local function createNormalizedQuantizedScalar()
    return QuantizedScalar.create("normalized_u8")
end

--#endregion
--------------------------------------------------------------------------------
--- 量化向量
--#region

---@alias foundation.InputSystem.QuantizedVector2.Mode
---| foundation.InputSystem.QuantizedScalar.Mode
---| '"normalized_polar_m7_a9"'

---@class foundation.InputSystem.QuantizedVector2
---@field mode foundation.InputSystem.QuantizedVector2.Mode
---@field size integer
---@field x    foundation.InputSystem.QuantizedScalar
---@field y    foundation.InputSystem.QuantizedScalar
---@field m    integer magnitude
---@field a    integer angle
local QuantizedVector2 = {}

---@param x number
---@param y number
function QuantizedVector2:set(x, y)
    assert(type(x) == "number", "x must be a number")
    assert(type(y) == "number", "y must be a number")
    if self.mode == "normalized_polar_m7_a9" then
        local m = math.sqrt(x * x + y * y)
        local a = math.deg(math.atan2(y, x))
        self.m = clamp(round(m * 100), 0, 100)
        self.a = clamp(round(a) % 360, 0, 360)
    else
        self.x:set(x)
        self.y:set(y)
    end
end

---@return number x 
---@return number y
function QuantizedVector2:get()
    if self.mode == "normalized_polar_m7_a9" then
        local m = self.m / 100.0
        local a = math.rad(self.a)
        return m * math.cos(a), m * math.sin(a)
    else
        return self.x:get(), self.y:get()
    end
end

---@param write fun(byte:integer)
function QuantizedVector2:toBytes(write)
    if self.mode == "normalized_polar_m7_a9" then
        local b1 = self.m
        local b2 = self.a
        if b2 > 255 then
            b1 = b1 + 128
            b2 = b2 - 128
        end
        assert(b1 >= 0 and b1 <= 255)
        assert(b2 >= 0 and b2 <= 255)
        write(b1)
        write(b2)
    else
        self.x:toBytes(write)
        self.y:toBytes(write)
    end
end

---@param read fun():integer?, string?
---@return boolean result
---@return string? message
function QuantizedVector2:fromBytes(read)
    if self.mode == "normalized_polar_m7_a9" then
        local b1, eb1 = read()
        if not b1 then
            return false, eb1
        end
        local b2, eb2 = read()
        if not b2 then
            return false, eb2
        end
        if b1 >= 128 then
            b1 = b1 - 128
            b2 = b2 + 128
        end
        self.m = b1
        self.a = b2
        return true, nil
    else
        local xr, xe = self.x:fromBytes(read)
        if not xr then
            return false, xe
        end
        return self.y:fromBytes(read)
    end
end

---@param other foundation.InputSystem.QuantizedVector2
function QuantizedVector2:assign(other)
    assert(self.mode == other.mode, "mode not matched")
    if self.mode == "normalized_polar_m7_a9" then
        self.m = other.m
        self.a = other.a
    else
        self.x:assign(other.x)
        self.y:assign(other.y)
    end
end

---@param mode foundation.InputSystem.QuantizedVector2.Mode
---@return foundation.InputSystem.QuantizedVector2
function QuantizedVector2.create(mode)
    if mode == "normalized_polar_m7_a9" then
        ---@type foundation.InputSystem.QuantizedVector2
        return {
            mode = mode,
            size = 2,
            x = QuantizedScalar.create("normalized_u8"), -- 未使用
            y = QuantizedScalar.create("normalized_u8"), -- 未使用
            m = 0,
            a = 0,
            set = QuantizedVector2.set,
            get = QuantizedVector2.get,
            toBytes = QuantizedVector2.toBytes,
            fromBytes = QuantizedVector2.fromBytes,
            assign = QuantizedVector2.assign,
        }
    else
        ---@cast mode foundation.InputSystem.QuantizedScalar.Mode
        local x = QuantizedScalar.create(mode)
        local y = QuantizedScalar.create(mode)
        ---@type foundation.InputSystem.QuantizedVector2
        return {
            mode = mode,
            size = x.size + y.size,
            x = x,
            y = y,
            m = 0, -- 未使用
            a = 0, -- 未使用
            set = QuantizedVector2.set,
            get = QuantizedVector2.get,
            toBytes = QuantizedVector2.toBytes,
            fromBytes = QuantizedVector2.fromBytes,
            assign = QuantizedVector2.assign,
        }
    end
end

---@return foundation.InputSystem.QuantizedVector2
local function createQuantizedVector2()
    return QuantizedVector2.create("fixed_s1_15_16")
end

---@return foundation.InputSystem.QuantizedVector2
local function createNormalizedQuantizedVector2()
    return QuantizedVector2.create("normalized_polar_m7_a9")
end

--#endregion
--------------------------------------------------------------------------------
--- 输入系统内部状态量化
--#region

---@class foundation.InputSystem.QuantizedActionSetValues
---@field quantized_last_scalar_action_values  table<string, foundation.InputSystem.QuantizedScalar>
---@field quantized_scalar_action_values       table<string, foundation.InputSystem.QuantizedScalar>
---@field quantized_last_vector2_action_values table<string, foundation.InputSystem.QuantizedVector2>
---@field quantized_vector2_action_values      table<string, foundation.InputSystem.QuantizedVector2>

---@return foundation.InputSystem.QuantizedActionSetValues
local function createQuantizedActionSetValues()
    ---@type foundation.InputSystem.QuantizedActionSetValues
    return {
        quantized_last_scalar_action_values = {},
        quantized_scalar_action_values = {},
        quantized_last_vector2_action_values = {},
        quantized_vector2_action_values = {},
    }
end
---@type table<string, foundation.InputSystem.QuantizedActionSetValues>
local quantized_action_set_values = {}

--- internal HOOK
---@param action_set foundation.InputSystem.ActionSet
---@param action foundation.InputSystem.Action
local function initializeQuantizedActionSetActionValues(action_set, action)
    local quantized = assert(quantized_action_set_values[action_set.name], ("QuantizedActionSetValues '%s' does not exists"):format(action_set.name))
    if action.type == "boolean" then
        -- noop
    elseif action.type == "scalar" then
        ---@cast action foundation.InputSystem.ScalarAction
        if action:isNormalized() then
            quantized.quantized_last_scalar_action_values[action.name] = createNormalizedQuantizedScalar()
            quantized.quantized_scalar_action_values[action.name] = createNormalizedQuantizedScalar()
        else
            quantized.quantized_last_scalar_action_values[action.name] = createQuantizedScalar()
            quantized.quantized_scalar_action_values[action.name] = createQuantizedScalar()
        end
    elseif action.type == "vector2" then
        ---@cast action foundation.InputSystem.Vector2Action
        if action:isNormalized() then
            quantized.quantized_last_vector2_action_values[action.name] = createNormalizedQuantizedVector2()
            quantized.quantized_vector2_action_values[action.name] = createNormalizedQuantizedVector2()
        else
            quantized.quantized_last_vector2_action_values[action.name] = createQuantizedVector2()
            quantized.quantized_vector2_action_values[action.name] = createQuantizedVector2()
        end
    else
        error(("unknown Action type '%s'"):format(action.type))
    end
end

--- internal HOOK
---@param action_set foundation.InputSystem.ActionSet
---@param action foundation.InputSystem.Action
local function uninitializeQuantizedActionSetActionValues(action_set, action)
    local quantized = assert(quantized_action_set_values[action_set.name], ("QuantizedActionSetValues '%s' does not exists"):format(action_set.name))
    if action.type == "boolean" then
        -- noop
    elseif action.type == "scalar" then
        quantized.quantized_last_scalar_action_values[action.name] = nil
        quantized.quantized_scalar_action_values[action.name] = nil
    elseif action.type == "vector2" then
        quantized.quantized_last_vector2_action_values[action.name] = nil
        quantized.quantized_vector2_action_values[action.name] = nil
    else
        error(("unknown Action type '%s'"):format(action.type))
    end
end

table.insert(on_action_added, initializeQuantizedActionSetActionValues) -- internal HOOK
table.insert(on_action_removed, uninitializeQuantizedActionSetActionValues) -- internal HOOK

--- internal HOOK
---@param action_set foundation.InputSystem.ActionSet
local function initializeQuantizedActionSetValues(action_set)
    quantized_action_set_values[action_set.name] = createQuantizedActionSetValues()
end

--- internal HOOK
---@param action_set foundation.InputSystem.ActionSet
local function uninitializeQuantizedActionSetValues(action_set)
    quantized_action_set_values[action_set.name] = nil
end

table.insert(on_action_set_added, initializeQuantizedActionSetValues) -- internal HOOK
table.insert(on_action_set_removed, uninitializeQuantizedActionSetValues) -- internal HOOK

---@param include_action_set_names string[]?
function InputSystem.quantize(include_action_set_names)
    for action_set_name, raw in pairs(raw_action_set_values) do
        if isActionSetIncluded(include_action_set_names, action_set_name) then
            local quantized = quantized_action_set_values[action_set_name]
            for k, v in pairs(raw.scalar_action_values) do
                quantized.quantized_scalar_action_values[k]:set(v)
                raw.scalar_action_values[k] = quantized.quantized_scalar_action_values[k]:get()
            end
            for k, v in pairs(raw.vector2_action_values) do
                quantized.quantized_vector2_action_values[k]:set(v.x, v.y)
                v.x, v.y = quantized.quantized_vector2_action_values[k]:get()
            end
        end
    end
end

--#endregion
--------------------------------------------------------------------------------
--- 输入系统设置
--#region

---@class foundation.InputSystem.OtherSetting
local other_setting = {
    --- 0: Auto  
    --- 1-4: Xinput controllers 1 to 4  
    controller_index = 0,
    --- 0: Auto  
    --- 1-?: DirectInput devices  
    hid_index = 0,
}

local function validateSetting()
    if round(other_setting.controller_index) ~= other_setting.controller_index then
        error("the value of controller_index must a integral number")
    end
    if other_setting.controller_index < 0 or other_setting.controller_index > 4 then
        error("the value of controller_index must be 0 (auto) or 1 or 2 or 3 or 4")
    end
    if round(other_setting.hid_index) ~= other_setting.hid_index then
        error("the value of hid_index must a integral number")
    end
    if other_setting.hid_index < 0 then
        error("the value of hid_index must be greater than or equal to 0")
    end
end

function InputSystem.getSetting()
    return other_setting
end

--#endregion
--------------------------------------------------------------------------------
--- 转换 XInput 和 DirectInput
--#region

---@type foundation.input.adapter.XInput.KeyState[]
local xinput_key_map = {}

local function updateXInput()
    XInput.update()
    for i = 1, 4 do
        if XInput.isConnected(i) then
            xinput_key_map[i] = XInputAdaptor.mapKeyStateFromIndex(i, 0.5)
        else
            xinput_key_map[i] = {}
        end
    end
end

---@type foundation.input.adapter.DirectInput.KeyState[]
local dinput_key_map = {}
---@type table<integer, number>[]
local dinput_axis_map = {}

local function updateDirectInput()
    -- 注意：DirectInput 刷新设备的成本非常高
    -- 建议：在设置界面增加一个刷新设备的按钮，由用户手动刷新
    DirectInput.update()
    local count = DirectInput.count()
    for i = 1, count do
        local axis_ranges = DirectInput.getAxisRange(i)
        local raw_state = DirectInput.getRawState(i)
        if axis_ranges and raw_state then
            dinput_key_map[i] = DirectInputAdaptor.mapKeyState(axis_ranges, raw_state, 0.5)
            dinput_axis_map[i] = DirectInputAdaptor.mapAxis(axis_ranges, raw_state)
        else
            dinput_key_map[i] = {}
            dinput_axis_map[i] = {}
        end
    end
    for i = #dinput_key_map, count + 1, -1 do
        dinput_key_map[i] = nil
        dinput_axis_map[i] = nil
    end
end

--#endregion
--------------------------------------------------------------------------------
--- XInput 辅助函数，根据设置选择合适的设备读取输入
--#region

---@param code integer
---@return boolean
local function isControllerKeyDown(code)
    if other_setting.controller_index == 0 then
        -- 从第一个设备读取输入
        for i = 1, 4 do
            if XInput.isConnected(i) then
                return XInputAdaptor.getKeyState(xinput_key_map[i], code)
            end
        end
    elseif XInput.isConnected(other_setting.controller_index) then
        return XInputAdaptor.getKeyState(xinput_key_map[other_setting.controller_index], code)
    end
    return false
end

---@param code integer
---@return number
local function getControllerAxis(code)
    -- TODO: 如何将扳机映射到轴？扳机是 0.0 到 1.0，静息状态下是 0.0，需要偏移原点吗？
    if other_setting.controller_index == 0 then
        if code == XInputAdaptor.Axis.LeftTrigger then
            return XInput.getLeftTrigger()
        elseif code == XInputAdaptor.Axis.RightTrigger then
            return XInput.getRightTrigger()
        elseif code == XInputAdaptor.Axis.LeftThumbX then
            return XInput.getLeftThumbX()
        elseif code == XInputAdaptor.Axis.LeftThumbY then
            return XInput.getLeftThumbY()
        elseif code == XInputAdaptor.Axis.RightThumbX then
            return XInput.getRightThumbX()
        elseif code == XInputAdaptor.Axis.RightThumbY then
            return XInput.getRightThumbY()
        end
    elseif XInput.isConnected(other_setting.controller_index) then
        if code == XInputAdaptor.Axis.LeftTrigger then
            return XInput.getLeftTrigger(other_setting.controller_index)
        elseif code == XInputAdaptor.Axis.RightTrigger then
            return XInput.getRightTrigger(other_setting.controller_index)
        elseif code == XInputAdaptor.Axis.LeftThumbX then
            return XInput.getLeftThumbX(other_setting.controller_index)
        elseif code == XInputAdaptor.Axis.LeftThumbY then
            return XInput.getLeftThumbY(other_setting.controller_index)
        elseif code == XInputAdaptor.Axis.RightThumbX then
            return XInput.getRightThumbX(other_setting.controller_index)
        elseif code == XInputAdaptor.Axis.RightThumbY then
            return XInput.getRightThumbY(other_setting.controller_index)
        end
    end
    return 0
end

---@param code integer
---@return number x
---@return number y
local function getControllerJoystick(code)
    if other_setting.controller_index == 0 then
        if code == XInputAdaptor.Joystick.LeftThumb then
            return XInput.getLeftThumbX(), XInput.getLeftThumbY()
        elseif code == XInputAdaptor.Joystick.RightThumb then
            return XInput.getRightThumbX(), XInput.getRightThumbY()
        end
    elseif XInput.isConnected(other_setting.controller_index) then
        if code == XInputAdaptor.Joystick.LeftThumb then
            return XInput.getLeftThumbX(other_setting.controller_index), XInput.getLeftThumbY(other_setting.controller_index)
        elseif code == XInputAdaptor.Joystick.RightThumb then
            return XInput.getRightThumbX(other_setting.controller_index), XInput.getRightThumbY(other_setting.controller_index)
        end
    end
    return 0, 0
end

--#endregion
--------------------------------------------------------------------------------
--- DirectInput 辅助函数，根据设置选择合适的设备读取输入
--#region

---@param code integer
---@return boolean
local function isHidKeyDown(code)
    if other_setting.hid_index == 0 then
        -- 从第一个设备读取输入
        if #dinput_key_map > 0 then
            return DirectInputAdaptor.getKeyState(dinput_key_map[1], code)
        end
    elseif other_setting.hid_index <= #dinput_key_map then
        return DirectInputAdaptor.getKeyState(dinput_key_map[other_setting.hid_index], code)
    end
    return false
end

---@param code integer
---@return number
local function getHidAxis(code)
    if other_setting.hid_index == 0 then
        -- 从第一个设备读取输入
        if #dinput_key_map > 0 then
            return dinput_axis_map[1][code] or 0
        end
    elseif other_setting.hid_index <= #dinput_key_map then
        return dinput_axis_map[other_setting.hid_index][code] or 0
    end
    return 0
end

--#endregion
--------------------------------------------------------------------------------
--- 状态更新
--#region

---@param action_set_values foundation.InputSystem.ActionSetValues
---@param clear_last boolean?
local function clearActionSetValues(action_set_values, clear_last)
    if clear_last then
        for k, _ in pairs(action_set_values.last_boolean_action_values) do
            action_set_values.last_boolean_action_values[k] = false
        end
        for k, _ in pairs(action_set_values.boolean_action_frames) do
            action_set_values.boolean_action_frames[k] = 0 -- 这个也属于“过去”的状态
        end
        for k, _ in pairs(action_set_values.last_scalar_action_values) do
            action_set_values.last_scalar_action_values[k] = 0
        end
        for k, _ in pairs(action_set_values.last_vector2_action_values) do
            action_set_values.last_vector2_action_values[k].x = 0
            action_set_values.last_vector2_action_values[k].y = 0
        end
    end
    for k, _ in pairs(action_set_values.boolean_action_values) do
        action_set_values.boolean_action_values[k] = false
    end
    for k, _ in pairs(action_set_values.scalar_action_values) do
        action_set_values.scalar_action_values[k] = 0
    end
    for k, _ in pairs(action_set_values.vector2_action_values) do
        action_set_values.vector2_action_values[k].x = 0
        action_set_values.vector2_action_values[k].y = 0
    end
end

---@param action_set_values foundation.InputSystem.QuantizedActionSetValues
---@param clear_last boolean?
local function clearQuantizedActionSetValues(action_set_values, clear_last)
    if clear_last then
        for _, v in pairs(action_set_values.quantized_last_scalar_action_values) do
            v:set(0)
        end
        for _, v in pairs(action_set_values.quantized_last_vector2_action_values) do
            v:set(0, 0)
        end
    end
    for _, v in pairs(action_set_values.quantized_scalar_action_values) do
        v:set(0)
    end
    for _, v in pairs(action_set_values.quantized_vector2_action_values) do
        v:set(0, 0)
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
        action_set_values.last_vector2_action_values[k].x = v.x
        action_set_values.last_vector2_action_values[k].y = v.y
    end
end

---@param action_set_values foundation.InputSystem.QuantizedActionSetValues
local function copyLastQuantizedActionSetValues(action_set_values)
    for k, v in pairs(action_set_values.quantized_scalar_action_values) do
        action_set_values.quantized_last_scalar_action_values[k]:assign(v)
    end
    for k, v in pairs(action_set_values.quantized_vector2_action_values) do
        action_set_values.quantized_last_vector2_action_values[k]:assign(v)
    end
end

function InputSystem.clear()
    for _, v in pairs(raw_action_set_values) do
        clearActionSetValues(v, true)
    end
    for _, v in pairs(quantized_action_set_values) do
        clearQuantizedActionSetValues(v, true)
    end
end

---@param values table<string, boolean>
---@param name string
---@param value boolean
local function orBooleanActionValue(values, name, value)
    values[name] = values[name] or value
end

---@param action_set foundation.InputSystem.ActionSet
---@param action_set_values foundation.InputSystem.ActionSetValues
local function updateBooleanActions(action_set, action_set_values)
    local values = action_set_values.boolean_action_values
    local frames = action_set_values.boolean_action_frames
    for name, action in action_set:booleanActions() do
        -- 键盘
        for _, binding in action:keyboardBindings() do
            orBooleanActionValue(values, name, Keyboard.GetKeyState(binding.key))
        end
        -- 鼠标
        for _, binding in action:mouseBindings() do
            orBooleanActionValue(values, name, Mouse.GetKeyState(binding.key))
        end
        -- 手柄
        for _, binding in action:controllerBindings() do
            orBooleanActionValue(values, name, isControllerKeyDown(binding.key))
        end
        -- 其他 HID 设备
        for _, binding in action:hidBindings() do
            orBooleanActionValue(values, name, isHidKeyDown(binding.key))
        end
        -- 更新激活计时器
        if values[name] then
            frames[name] = frames[name] + 1
        else
            frames[name] = -1
        end
    end
end

---@param values table<string, number>
---@param name string
---@param value number
local function addScalarActionValue(values, name, value)
    values[name] = values[name] + value
end

---@param action_set foundation.InputSystem.ActionSet
---@param action_set_values foundation.InputSystem.ActionSetValues
local function updateScalarActions(action_set, action_set_values)
    -- 按键按下映射为 1
    local KEY_DOWN_VALUE = 1
    local values = action_set_values.scalar_action_values
    for name, action in action_set:scalarActions() do
        -- 键盘
        for _, binding in action:keyboardBindings() do
            if binding.type == "key" then
                if Keyboard.GetKeyState(binding.key) then
                    addScalarActionValue(values, name, KEY_DOWN_VALUE)
                end
            end
        end
        -- 鼠标
        for _, binding in action:mouseBindings() do
            if binding.type == "key" then
                if Mouse.GetKeyState(binding.key) then
                    addScalarActionValue(values, name, KEY_DOWN_VALUE)
                end
            end
            -- TODO: 绘图板的笔压也许可以映射为标量输入
        end
        -- 手柄
        for _, binding in action:controllerBindings() do
            if binding.type == "key" then
                if isControllerKeyDown(binding.key) then
                    addScalarActionValue(values, name, KEY_DOWN_VALUE)
                end
            elseif binding.type == "axis" then
                addScalarActionValue(values, name, getControllerAxis(binding.axis))
            end
        end
        -- 其他 HID 设备
        for _, binding in action:hidBindings() do
            if binding.type == "key" then
                if isHidKeyDown(binding.key) then
                    addScalarActionValue(values, name, KEY_DOWN_VALUE)
                end
            end
            -- TODO: 我要怎么弄？
        end
        -- 归一化标量
        if action:isNormalized() then
            values[name] = clamp(values[name], 0.0, 1.0)
        end
    end
end

---@param values table<string, foundation.InputSystem.Vector2>
---@param name string
---@param x number
---@param y number
local function addVector2ActionValue(values, name, x, y)
    local vector2 = values[name]
    vector2.x = vector2.x + x
    vector2.y = vector2.y + y
end

---@param positive_x any
---@param negative_x any
---@param positive_y any
---@param negative_y any
---@return number x
---@return number y
local function keyStateToVector2(positive_x, negative_x, positive_y, negative_y)
    local x = 0
    local y = 0
    if negative_x then
        x = x - 1
    elseif positive_x then
        x = x + 1
    end
    if negative_y then
        y = y - 1
    elseif positive_y then
        y = y + 1
    end
    if x ~= 0 and y ~= 0 then
        x = x * SQRT2_2
        y = y * SQRT2_2
    end
    return x, y
end

---@param v foundation.InputSystem.Vector2
local function normalizeVector2(v)
    local l = math.sqrt(v.x * v.x + v.y * v.y)
    if l > 1.0 then
        local a = math.atan2(v.y, v.x)
        v.x = math.cos(a)
        v.y = math.sin(a)
    end
end

---@param action_set foundation.InputSystem.ActionSet
---@param action_set_values foundation.InputSystem.ActionSetValues
local function updateVector2Actions(action_set, action_set_values)
    local values = action_set_values.vector2_action_values
    for name, action in action_set:vector2Actions() do
        -- 键盘：通过四个按键映射到二维矢量的四个方向
        for _, binding in action:keyboardBindings() do
            if binding.type == "key" then
                local x, y = keyStateToVector2(
                    Keyboard.GetKeyState(binding.positive_x_key),
                    Keyboard.GetKeyState(binding.negative_x_key),
                    Keyboard.GetKeyState(binding.positive_y_key),
                    Keyboard.GetKeyState(binding.negative_y_key))
                addVector2ActionValue(values, name, x, y)
            end
        end
        -- 鼠标
        for _, binding in action:mouseBindings() do
            if binding.type == "key" then
                local x, y = keyStateToVector2(
                    Mouse.GetKeyState(binding.positive_x_key),
                    Mouse.GetKeyState(binding.negative_x_key),
                    Mouse.GetKeyState(binding.positive_y_key),
                    Mouse.GetKeyState(binding.negative_y_key))
                addVector2ActionValue(values, name, x, y)
            end
            -- TODO: 鼠标的XY坐标和XY滚轮不属于归一化二维矢量输入组件，需要特殊处理
        end
        -- 手柄
        for _, binding in action:controllerBindings() do
            if binding.type == "key" then
                local x, y = keyStateToVector2(
                    isControllerKeyDown(binding.positive_x_key),
                    isControllerKeyDown(binding.negative_x_key),
                    isControllerKeyDown(binding.positive_y_key),
                    isControllerKeyDown(binding.negative_y_key))
                addVector2ActionValue(values, name, x, y)
            end
            if binding.type == "axis" then
                -- 思考：真的有人会用左摇杆的X轴控制左右，用右摇杆的Y轴控制前后吗？
                -- 思考：会不会有人不小心把摇杆的X轴绑到Y轴上？
                local x = getControllerAxis(binding.x_axis)
                local y = getControllerAxis(binding.y_axis)
                addVector2ActionValue(values, name, x, y)
            end
            if binding.type == "joystick" then
                local x, y = getControllerJoystick(binding.joystick)
                addVector2ActionValue(values, name, x, y)
            end
        end
        -- 其他 HID 设备
        for _, binding in action:hidBindings() do
            if binding.type == "key" then
                local x, y = keyStateToVector2(
                    isHidKeyDown(binding.positive_x_key),
                    isHidKeyDown(binding.negative_x_key),
                    isHidKeyDown(binding.positive_y_key),
                    isHidKeyDown(binding.negative_y_key))
                addVector2ActionValue(values, name, x, y)
            end
            if binding.type == "axis" then
                local x = getHidAxis(binding.x_axis)
                local y = getHidAxis(binding.y_axis)
                addVector2ActionValue(values, name, x, y)
            end
            -- HID 设备的轴映射完全看厂家心情，只有天知道哪两个轴组合成一个摇杆，所以这里忽略摇杆绑定
        end
        -- 归一化向量
        if action:isNormalized() then
            normalizeVector2(values[name])
        end
    end
end

---@param action_set foundation.InputSystem.ActionSet
---@param action_set_values foundation.InputSystem.ActionSetValues
local function updateActionSet(action_set, action_set_values)
    updateBooleanActions(action_set, action_set_values)
    updateScalarActions(action_set, action_set_values)
    updateVector2Actions(action_set, action_set_values)
end

---@param include_action_set_names string[]?
function InputSystem.update(include_action_set_names)
    -- 旧状态
    for k, v in pairs(raw_action_set_values) do
        if isActionSetIncluded(include_action_set_names, k) then
            copyLastActionSetValues(v)
            clearActionSetValues(v)
        end
    end
    for k, v in pairs(quantized_action_set_values) do
        if isActionSetIncluded(include_action_set_names, k) then
            copyLastQuantizedActionSetValues(v)
            clearQuantizedActionSetValues(v)
        end
    end
    -- 新状态
    updateXInput()
    updateDirectInput()
    validateSetting()
    for name, action_set in pairs(action_sets) do
        if isActionSetIncluded(include_action_set_names, name) then
            updateActionSet(action_set, raw_action_set_values[name])
        end
    end
    -- 量化
    InputSystem.quantize(include_action_set_names)
end

--#endregion
--------------------------------------------------------------------------------
--- 内部状态序列化、反序列化
--#region

local ACTION_SET_MARKER = string.byte("[")
local BOOLEAN_ACTION_VALUES_MARKER = string.byte("?")
local SCALAR_ACTION_VALUES_MARKER = string.byte("/")
local VECTOR2_ACTION_VALUES_MARKER = string.byte("^")

---@param bytes integer[]
---@param byte integer
local function appendByte(bytes, byte)
    if byte < 0 or byte > 255 or round(byte) ~= byte then
        error(("invalid byte value '%s'"):format(tostring(byte)))
    end
    bytes[#bytes + 1] = byte
end

---@param bytes integer[]
---@param args integer[]
local function appendBytes(bytes, args)
    local n = #bytes
    for i = 1, #args do
        local byte = args[i]
        if byte < 0 or byte > 255 or round(byte) ~= byte then
            error(("invalid byte value '%s'"):format(tostring(byte)))
        end
        bytes[n + i] = byte
    end
end

---@param bytes integer[]
---@param str string
local function appendString(bytes, str)
    local len = str:len()
    appendByte(bytes, len)
    appendBytes(bytes, { str:byte(1, len) })
end

---@param v any
---@return integer
local function booleanToByte(v)
    if v then
        return 1
    else
        return 0
    end
end

---@param b integer
---@return boolean
local function byteToBoolean(b)
    return b ~= 0
end

---@param include_action_set_names string[]
---@return integer
function InputSystem.getSerializationLength(include_action_set_names)
    local length = 0
    for action_set_name, action_set_values in pairs(raw_action_set_values) do
        if isArrayContains(include_action_set_names, action_set_name) then
            -- 动作集信息
            local quantized = quantized_action_set_values[action_set_name]
            length = length + 1 -- ACTION_SET_MARKER
            length = length + 1 + action_set_name:len()
            -- 布尔动作值
            length = length + 1 -- BOOLEAN_ACTION_VALUES_MARKER
            for action_name, _ in pairs(action_set_values.boolean_action_values) do
                length = length + 1 + action_name:len()
                length = length + 1 -- boolean value
            end
            -- 标量动作值
            length = length + 1 -- SCALAR_ACTION_VALUES_MARKER
            for action_name, action_value in pairs(quantized.quantized_scalar_action_values) do
                length = length + 1 + action_name:len()
                length = length + action_value.size
            end
            -- 矢量动作值
            length = length + 1 -- VECTOR2_ACTION_VALUES_MARKER
            for action_name, action_value in pairs(quantized.quantized_vector2_action_values) do
                length = length + 1 + action_name:len()
                length = length + action_value.size
            end
        end
    end
    return length
end

---@param include_action_set_names string[]
---@return integer[]
function InputSystem.serialize(include_action_set_names)
    ---@type integer[]
    local bytes = {}
    local function writer(byte)
        bytes[#bytes + 1] = byte
    end
    for action_set_name, action_set_values in pairs(raw_action_set_values) do
        if isArrayContains(include_action_set_names, action_set_name) then
            -- 动作集信息
            local quantized = quantized_action_set_values[action_set_name]
            appendByte(bytes, ACTION_SET_MARKER)
            appendString(bytes, action_set_name)
            -- 布尔动作值
            appendByte(bytes, BOOLEAN_ACTION_VALUES_MARKER)
            for action_name, action_value in pairs(action_set_values.boolean_action_values) do
                appendString(bytes, action_name)
                appendByte(bytes, booleanToByte(action_value))
            end
            -- 标量动作值
            appendByte(bytes, SCALAR_ACTION_VALUES_MARKER)
            for action_name, action_value in pairs(quantized.quantized_scalar_action_values) do -- 已量化
                appendString(bytes, action_name)
                action_value:toBytes(writer)
            end
            -- 矢量动作值
            appendByte(bytes, VECTOR2_ACTION_VALUES_MARKER)
            for action_name, action_value in pairs(quantized.quantized_vector2_action_values) do -- 已量化
                appendString(bytes, action_name)
                action_value:toBytes(writer)
            end
        end
    end
    return bytes
end

---@param bytes integer[]
---@param index integer
---@param str_id string
---@return string? string
---@return string? message
local function scanString(bytes, index, str_id)
    local length = #bytes
    -- string length
    if index > length then
        return nil, ("expected string length (%s name), but reached the end of the byte array"):format(str_id)
    end
    local string_length = bytes[index]
    index = index + 1
    -- string
    if (index + string_length - 1) > length then
        return nil, ("expected string (%s name length = %d), but reached the end of the byte array"):format(str_id, string_length)
    end
    local buffer = {}
    for i = 1, string_length do
        buffer[i] = string.char(bytes[index])
        index = index + 1
    end
    return table.concat(buffer), nil
end

---@param marker integer
---@return string
local function getStrIdByMarker(marker)
    if marker == ACTION_SET_MARKER then
        return "ActionSet"
    elseif marker == BOOLEAN_ACTION_VALUES_MARKER then
        return "BooleanAction"
    elseif marker == SCALAR_ACTION_VALUES_MARKER then
        return "ScalarAction"
    elseif marker == VECTOR2_ACTION_VALUES_MARKER then
        return "Vector2Action"
    else
        return "<?>"
    end
end

---@param marker integer
---@return boolean
local function isActionMarker(marker)
    return marker == BOOLEAN_ACTION_VALUES_MARKER
        or marker == SCALAR_ACTION_VALUES_MARKER
        or marker == VECTOR2_ACTION_VALUES_MARKER
end

---@param marker integer
---@return boolean
local function isAnyMarker(marker)
    return isActionMarker(marker)
        or marker == ACTION_SET_MARKER
end

---@param bytes integer[]
---@return boolean result
---@return string? message
function InputSystem.deserialize(bytes)
    local length = #bytes
    local index = 1
    local function reader()
        if index > #bytes then
            return nil, "reader out of bound"
        end
        local byte = bytes[index]
        index = index + 1
        return byte, nil
    end
    while index <= length do
        -- 动作集标记
        if bytes[index] ~= ACTION_SET_MARKER then
            return false, ("expected ActionSet marker, but got %d"):format(bytes[index])
        end
        index = index + 1

        -- 动作集名称
        local action_set_name, e_action_set_name = scanString(bytes, index, "ActionSet")
        if not action_set_name then
            return false, e_action_set_name
        end
        ---@cast action_set_name string
        index = index + 1 + action_set_name:len()

        -- 动作集
        local action_set_values = raw_action_set_values[action_set_name]
        if not action_set_values then
            return false, ("ActionSet '%s' does not exists"):format(action_set_name)
        end
        local quantized = quantized_action_set_values[action_set_name]

        -- 动作值
        while index <= length do
            -- 动作值标记
            local marker = bytes[index]
            if marker == ACTION_SET_MARKER then
                break
            end
            if not isActionMarker(marker) then
                return false, ("expected Action marker, but got %d"):format(bytes[index])
            end
            index = index + 1
            -- 动作值
            while index <= length do
                -- 先检查一下是不是
                if isAnyMarker(bytes[index]) then
                    break
                end
                -- 名称
                local action_name, e_action_name = scanString(bytes, index, getStrIdByMarker(marker))
                if not action_name then
                    return false, e_action_name
                end
                ---@cast action_name string
                index = index + 1 + action_name:len()
                -- 值
                if marker == BOOLEAN_ACTION_VALUES_MARKER then
                    action_set_values.boolean_action_values[action_name] = byteToBoolean(bytes[index])
                    index = index + 1
                elseif marker == SCALAR_ACTION_VALUES_MARKER then
                    local r, e = quantized.quantized_scalar_action_values[action_name]:fromBytes(reader)
                    if not r then
                        return false, e
                    end
                    local v = quantized.quantized_scalar_action_values[action_name]:get()
                    action_set_values.scalar_action_values[action_name] = v
                elseif marker == VECTOR2_ACTION_VALUES_MARKER then
                    local r, e = quantized.quantized_vector2_action_values[action_name]:fromBytes(reader)
                    if not r then
                        return false, e
                    end
                    local x, y = quantized.quantized_vector2_action_values[action_name]:get()
                    action_set_values.vector2_action_values[action_name].x = x
                    action_set_values.vector2_action_values[action_name].y = y
                end
            end
        end
    end

    return true
end

--#endregion
--------------------------------------------------------------------------------
--- 内部状态序列化、反序列化上下文
--#region

local SERIALIZE_CONTEXT_VERBOSE_LOG = false

--#region BitPacker

local BIT_VALUES = { 1, 2, 4, 8, 16, 32, 64, 128 }

---@class foundation.InputSystem.BitPacker
---@field private write     fun(byte:integer)
---@field private bits      boolean[]
---@field private bit_count integer
local BitPacker = {}

function BitPacker:reset()
    for i = 1, 8 do
        self.bits[i] = false
    end
    self.bit_count = 0
end

---@param bit boolean
function BitPacker:push(bit)
    if SERIALIZE_CONTEXT_VERBOSE_LOG then
        logInfo("BitPacker push %s", tostring(bit))
    end
    self.bit_count = self.bit_count + 1
    self.bits[self.bit_count] = not (not bit)
    self:flush(true)
end

---@param only_full boolean?
function BitPacker:flush(only_full)
    if self.bit_count < 0 or self.bit_count > 8 then
        error("invalid internal state")
    end
    if self.bit_count == 0 then
        return
    end
    if (only_full and self.bit_count == 8) or (not only_full) then
        local byte = 0
        for i = 1, 8 do
            if self.bits[i] then
                self.bits[i] = false
                byte = byte + BIT_VALUES[i]
            end
        end
        self.bit_count = 0
        self.write(byte)
        if SERIALIZE_CONTEXT_VERBOSE_LOG then
            logInfo("BitPacker write %d", byte)
        end
    end
end

---@param write fun(byte:integer)
---@return foundation.InputSystem.BitPacker
function BitPacker.create(write)
    ---@type foundation.InputSystem.BitPacker
    local packer = {
        write = write,
        bits = { false, false, false, false, false, false, false, false },
        bit_count = 0,
        reset = BitPacker.reset,
        push = BitPacker.push,
        flush = BitPacker.flush,
    }
    return packer
end

--#endregion

--#region BitUnpacker

---@class foundation.InputSystem.BitUnpacker
---@field private read      fun():integer
---@field private bits      boolean[]
---@field private bit_count integer
local BitUnpacker = {}

function BitUnpacker:reset()
    for i = 1, 8 do
        self.bits[i] = false
    end
    self.bit_count = 0
end

---@return boolean bit
function BitUnpacker:pop()
    self:fetch()
    local bit = self.bits[8 - (self.bit_count - 1)]
    self.bit_count = self.bit_count - 1
    if SERIALIZE_CONTEXT_VERBOSE_LOG then
        logInfo("BitUnpacker pop %s", tostring(bit))
    end
    return bit
end

function BitUnpacker:fetch()
    if self.bit_count < 0 or self.bit_count > 8 then
        error("invalid internal state")
    end
    if self.bit_count == 0 then
        local byte = self.read()
        if SERIALIZE_CONTEXT_VERBOSE_LOG then
            logInfo("BitUnpacker read %d", byte)
        end
        for i = 8, 1, -1 do
            if byte >= BIT_VALUES[i] then
                byte = byte - BIT_VALUES[i]
                self.bits[i] = true
            else
                self.bits[i] = false
            end
        end
        self.bit_count = 8
    end
end

---@param read fun():integer
---@return foundation.InputSystem.BitUnpacker
function BitUnpacker.create(read)
    ---@type foundation.InputSystem.BitUnpacker
    local unpacker = {
        read = read,
        bits = { false, false, false, false, false, false, false, false },
        bit_count = 0,
        reset = BitUnpacker.reset,
        pop = BitUnpacker.pop,
        fetch = BitUnpacker.fetch,
    }
    return unpacker
end

--#endregion

--#region SerializeContext

---@class foundation.InputSystem.SerializeContext.ActionSet
---@field package name                 string
---@field package boolean_action_names string[]
---@field package scalar_action_names  string[]
---@field package vector2_action_names string[]

---@class foundation.InputSystem.SerializeContext
---@field private include_action_set_names string[]?
---@field         initialized              boolean
---@field private packet_size              integer
---@field private action_sets              foundation.InputSystem.SerializeContext.ActionSet[]
local SerializeContext = {}

function SerializeContext:uninitialize()
    self.include_action_set_names = nil
    self.initialized = false
    self.packet_size = 0
    self.action_sets = {}
end

---@param include_action_set_names string[]?
function SerializeContext:initialize(include_action_set_names)
    self.include_action_set_names = include_action_set_names
    self.initialized = false
    self.packet_size = 0
    self.action_sets = {}

    for action_set_name, action_set in pairs(action_sets) do
        if isActionSetIncluded(self.include_action_set_names, action_set_name) then
            ---@type foundation.InputSystem.SerializeContext.ActionSet
            local s_action_set = {
                name = action_set_name,
                boolean_action_names = {},
                scalar_action_names = {},
                vector2_action_names = {},
            }
            for action_name, _ in action_set:booleanActions() do
                table.insert(s_action_set.boolean_action_names, action_name)
            end
            table.sort(s_action_set.boolean_action_names, function(a, b)
                return a < b
            end)
            for action_name, _ in action_set:scalarActions() do
                table.insert(s_action_set.scalar_action_names, action_name)
            end
            table.sort(s_action_set.scalar_action_names, function(a, b)
                return a < b
            end)
            for action_name, _ in action_set:vector2Actions() do
                table.insert(s_action_set.vector2_action_names, action_name)
            end
            table.sort(s_action_set.vector2_action_names, function(a, b)
                return a < b
            end)
            if (#s_action_set.boolean_action_names + #s_action_set.scalar_action_names + #s_action_set.vector2_action_names) > 0 then
                self.packet_size = self.packet_size + math.ceil(#s_action_set.boolean_action_names / 8) -- 打包为字节
                self.packet_size = self.packet_size + #s_action_set.scalar_action_names -- 已量化
                self.packet_size = self.packet_size + 2 * #s_action_set.vector2_action_names -- 已量化
                table.insert(self.action_sets, s_action_set)
            end
        end
    end
    table.sort(self.action_sets, function(a, b)
        return a.name < b.name
    end)

    self.initialized = true
end

---@return integer[] bytes
function SerializeContext:serializeMetadata()
    assert(self.initialized, "SerializeContext not initialized")
    ---@type integer[] bytes
    local bytes = {}
    for _, action_set in ipairs(self.action_sets) do
        -- 动作集信息
        appendByte(bytes, ACTION_SET_MARKER)
        appendString(bytes, action_set.name)
        -- 布尔动作值
        appendByte(bytes, BOOLEAN_ACTION_VALUES_MARKER)
        for _, action_name in pairs(action_set.boolean_action_names) do
            appendString(bytes, action_name)
        end
        -- 标量动作值
        appendByte(bytes, SCALAR_ACTION_VALUES_MARKER)
        for _, action_name in pairs(action_set.scalar_action_names) do
            appendString(bytes, action_name)
        end
        -- 矢量动作值
        appendByte(bytes, VECTOR2_ACTION_VALUES_MARKER)
        for _, action_name in pairs(action_set.vector2_action_names) do
            appendString(bytes, action_name)
        end
    end
    return bytes
end

---@return integer size_in_bytes
function SerializeContext:getPacketSize()
    assert(self.initialized, "SerializeContext not initialized")
    return self.packet_size
end

---@return integer[] bytes
function SerializeContext:serialize()
    assert(self.initialized, "SerializeContext not initialized")
    ---@type integer[] bytes
    local bytes = {}
    local function writer(byte)
        bytes[#bytes + 1] = byte
    end
    local bit_packer = BitPacker.create(writer)
    for _, action_set in ipairs(self.action_sets) do
        -- 动作集信息
        local raw = assert(raw_action_set_values[action_set.name], "ActionSetValues does not exists")
        local quantized = assert(quantized_action_set_values[action_set.name], "QuantizedActionSetValues does not exists")
        -- 布尔动作值
        bit_packer:reset()
        for _, action_name in pairs(action_set.boolean_action_names) do
            bit_packer:push(raw.boolean_action_values[action_name])
        end
        bit_packer:flush()
        -- 标量动作值
        for _, action_name in pairs(action_set.scalar_action_names) do
            quantized.quantized_scalar_action_values[action_name]:toBytes(writer)
            if SERIALIZE_CONTEXT_VERBOSE_LOG then
                local v = quantized.quantized_scalar_action_values[action_name]:get()
                logInfo("serialize / %f", v)
            end
        end
        -- 矢量动作值
        for _, action_name in pairs(action_set.vector2_action_names) do
            quantized.quantized_vector2_action_values[action_name]:toBytes(writer)
            if SERIALIZE_CONTEXT_VERBOSE_LOG then
                local x, y = quantized.quantized_vector2_action_values[action_name]:get()
                logInfo("serialize ^ %f %f", x, y)
            end
        end
    end
    return bytes
end

---@param bytes integer[]
---@return boolean result
---@return string? message
function SerializeContext:deserialize(bytes)
    assert(self.initialized, "SerializeContext not initialized")
    assert(type(bytes) == "table", "bytes must be a table (byte array)")
    if #bytes < self.packet_size then
        return false, "index out of bound"
    end
    local index = 1
    local function reader()
        if index > #bytes then
            return nil, "reader out of bound"
        end
        local byte = bytes[index]
        index = index + 1
        return byte, nil
    end
    local bit_unpacker = BitUnpacker.create(reader)
    for _, action_set in ipairs(self.action_sets) do
        -- 动作集信息
        local raw = assert(raw_action_set_values[action_set.name], "ActionSetValues does not exists")
        local quantized = assert(quantized_action_set_values[action_set.name], "QuantizedActionSetValues does not exists")
        -- 布尔动作值
        bit_unpacker:reset()
        for _, action_name in pairs(action_set.boolean_action_names) do
            raw.boolean_action_values[action_name] = bit_unpacker:pop()
        end
        -- 标量动作值
        for _, action_name in pairs(action_set.scalar_action_names) do
            local r, e = quantized.quantized_scalar_action_values[action_name]:fromBytes(reader)
            if not r then
                return false, e
            end
            local v = quantized.quantized_scalar_action_values[action_name]:get()
            raw.scalar_action_values[action_name] = v
            if SERIALIZE_CONTEXT_VERBOSE_LOG then
                logInfo("deserialize / %f", v)
            end
        end
        -- 矢量动作值
        for _, action_name in pairs(action_set.vector2_action_names) do
            local r, e = quantized.quantized_vector2_action_values[action_name]:fromBytes(reader)
            if not r then
                return false, e
            end
            local x, y = quantized.quantized_vector2_action_values[action_name]:get()
            raw.vector2_action_values[action_name].x = x
            raw.vector2_action_values[action_name].y = y
            if SERIALIZE_CONTEXT_VERBOSE_LOG then
                logInfo("deserialize ^ %f %f", x, y)
            end
        end
    end
    return true, nil
end

---@return foundation.InputSystem.SerializeContext
function InputSystem.createSerializeContext()
    ---@type foundation.InputSystem.SerializeContext
    local context = {
        include_action_set_names = nil,
        initialized = false,
        packet_size = 0,
        action_sets = {},
    }
    setmetatable(context, { __index = SerializeContext })
    return context
end

--#endregion

--#endregion
--------------------------------------------------------------------------------
--- 读取动作值辅助函数
--#region

---@param value boolean?
---@return boolean
local function toBoolean(value)
    if value then
        return true
    else
        return false
    end
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
---@return number x
---@return number y
local function toVector2(value)
    if type(value) == "table" then
        if type(value.x) == "number" and type(value.y) == "number" then
            return value.x, value.y
        end
    end
    return 0.0, 0.0
end

---@param action_locator string
---@return string action_set_name
---@return string action_name
local function parseActionSetNameAndActionName(action_locator)
    assert(type(action_locator) == "string", "action_locator must be a string")
    local action_set_name, action_name = string.match(action_locator, "^(.-):(.*)$")
    if type(action_set_name) ~= "string" or type(action_name) ~= "string" then
        error(("invalid action_locator '%s', incorrect format"):format(action_locator))
    end
    ---@cast action_set_name string
    ---@cast action_name string
    if action_set_name:len() == 0 then
        error(("invalid action_locator '%s', ActionSet name part is empty"):format(action_locator))
    end
    if action_name:len() == 0 then
        error(("invalid action_locator '%s', Action name part is empty"):format(action_locator))
    end
    return action_set_name, action_name
end

---@param action_locator string
---@return foundation.InputSystem.ActionSetValues action_set_values
---@return string action_name
local function findActionSetValuesAndActionName(action_locator)
    local action_set_name, action_name = parseActionSetNameAndActionName(action_locator)
    if not raw_action_set_values[action_set_name] then
        error(("invalid action_locator '%s', ActionSet '%s' does not exists"):format(action_locator, action_set_name))
    end
    return raw_action_set_values[action_set_name], action_name
end

--#endregion
--------------------------------------------------------------------------------
--- 读取动作值
--#region

--- 读取布尔类型的动作值  
--- 可能值有：  
--- * `true`：激活  
--- * `false`：未激活  
---@param action_locator string
---@return boolean
function InputSystem.getBooleanAction(action_locator)
    local action_set_values, action_name = findActionSetValuesAndActionName(action_locator)
    return toBoolean(action_set_values.boolean_action_values[action_name])
end

--- 读取标量动作值  
--- 标量值被映射到 0.0 到 1.0 的归一化实数  
---@param action_locator string
---@return number
function InputSystem.getScalarAction(action_locator)
    local action_set_values, action_name = findActionSetValuesAndActionName(action_locator)
    return toScalar(action_set_values.scalar_action_values[action_name])
end

--- 读取二维矢量动作值  
--- 二维矢量动作值被映射归一化矢量（长度范围 0.0 到 1.0）  
---@param action_locator string
---@return number x
---@return number y
function InputSystem.getVector2Action(action_locator)
    local action_set_values, action_name = findActionSetValuesAndActionName(action_locator)
    return toVector2(action_set_values.vector2_action_values[action_name])
end

--#endregion
--------------------------------------------------------------------------------
--- 追踪动作值变化
--#region

---@param action_locator string
---@return boolean last
---@return boolean current
---@return integer frames
local function getLastAndCurrentBooleanAction(action_locator)
    local action_set_values, action_name = findActionSetValuesAndActionName(action_locator)
    local last = toBoolean(action_set_values.last_boolean_action_values[action_name])
    local current = toBoolean(action_set_values.boolean_action_values[action_name])
    local frames = toScalar(action_set_values.boolean_action_frames[action_name])
    return last, current, frames
end

--- 布尔动作是否在当前帧激活  
--- 填写后面两个参数后会启用重复触发器，
--- repeat_delay 参数用于指定多少帧后开始执行，
--- repeat_interval 参数用于指定执行间隔
---@param action_locator string
---@param repeat_delay integer?
---@param repeat_interval integer?
---@return boolean
function InputSystem.isBooleanActionActivated(action_locator, repeat_delay, repeat_interval)
    if repeat_delay or repeat_interval then
        assert(type(repeat_delay) == "number", "repeat_delay must be a number (integer)")
        assert(type(repeat_interval) == "number", "repeat_interval must be a number (integer)")
        assert(repeat_delay >= 0, "repeat_delay must be greater than or equal to 0")
        assert(repeat_interval >= 0, "repeat_interval must be greater than or equal to 0")
        assert(math.floor(repeat_delay) == repeat_delay, "repeat_delay must be a number (integer)")
        assert(math.floor(repeat_interval) == repeat_interval, "repeat_interval must be a number (integer)")
    end
    local last, current, frames = getLastAndCurrentBooleanAction(action_locator)
    if (not last) and current then
        return true
    elseif current and repeat_delay and repeat_interval then
        if repeat_delay == 0 and repeat_interval == 0 then
            return true
        elseif frames >= repeat_delay then
            if repeat_interval == 0 then
                return true
            elseif ((frames - repeat_delay) % repeat_interval) == 0 then
                return true
            end
        end
    end
    return false
end

--- 布尔动作是否在当前帧释放  
---@param action_locator string
---@return boolean
function InputSystem.isBooleanActionDeactivated(action_locator)
    local last, current = getLastAndCurrentBooleanAction(action_locator)
    return last and (not current)
end

--- 读取标量动作值的增量  
--- 映射规则：  
--- * `false` -> `false`: 0  
--- * `false` -> `true`: 1  
--- * `true` -> `true`: 0  
--- * `true` -> `false`: -1  
---@param action_locator string
---@return number
function InputSystem.getBooleanActionIncrement(action_locator)
    local last, current = getLastAndCurrentBooleanAction(action_locator)
    if (not last) and current then
        return 1
    elseif last and (not current) then
        return -1
    else
        return 0
    end
end

--- 读取标量动作值的增量，负值代表减少  
---@param action_locator string
---@return number
function InputSystem.getScalarActionIncrement(action_locator)
    local action_set_values, action_name = findActionSetValuesAndActionName(action_locator)
    local last = toScalar(action_set_values.last_scalar_action_values[action_name])
    local current = toScalar(action_set_values.scalar_action_values[action_name])
    return current - last
end

--- 读取二维矢量动作值的增量，负值代表减少  
---@param action_locator string
---@return number, number
function InputSystem.getVector2ActionIncrement(action_locator)
    local action_set_values, action_name = findActionSetValuesAndActionName(action_locator)
    local last_x, last_y = toVector2(action_set_values.last_vector2_action_values[action_name])
    local current_x, current_y = toVector2(action_set_values.vector2_action_values[action_name])
    return current_x - last_x, current_y - last_y
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
    data.other_setting = copyTable(other_setting)
    local r, err = Files.writeStringWithBackup(path, cjson_util.format_json(cjson.encode(data)))
    if not r then
        logError("an error occurred while saving the configuration: %s", tostring(err))
    end
end

local LOAD_ERROR_PREFIX = "an error occurred while loading the configuration:"

-- TODO: mergeBooleanAction、mergeScalarAction、mergeVector2Action 需要打印校验日志

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

---@param action_set_name string
---@param source_actions table<string, foundation.InputSystem.BooleanAction>
---@param target_actions table<string, foundation.InputSystem.BooleanAction>
local function mergeBooleanActions(action_set_name, source_actions, target_actions)
    for name, source_action in pairs(source_actions) do
        if type(name) ~= "string" then
            logError('%s action_sets["%s"].boolean_actions[%s (type: %s)] <-- key must be a string', LOAD_ERROR_PREFIX, action_set_name, tostring(name), type(name))
        elseif type(source_action) ~= "table" then
            logError('%s action_sets["%s"].boolean_actions["%s"] must be a table', LOAD_ERROR_PREFIX, action_set_name, name)
        elseif type(source_action.name) ~= "string" then
            logError('%s action_sets["%s"].boolean_actions["%s"].name must be a string', LOAD_ERROR_PREFIX, action_set_name, name)
        elseif name ~= source_action.name then
            logError('%s action_sets["%s"].boolean_actions["%s"] <-- key must equals to action_sets["%s"].boolean_actions["%s"].name', LOAD_ERROR_PREFIX, action_set_name, name, action_set_name, name)
        elseif not target_actions[source_action.name] then
            logError("%s ActionSet '%s': BooleanAction '%s' does not exists", LOAD_ERROR_PREFIX, action_set_name, source_action.name)
        else
            mergeBooleanAction(source_action, target_actions[source_action.name])
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

---@param action_set_name string
---@param source_actions table<string, foundation.InputSystem.ScalarAction>
---@param target_actions table<string, foundation.InputSystem.ScalarAction>
local function mergeScalarActions(action_set_name, source_actions, target_actions)
    for name, source_action in pairs(source_actions) do
        if type(name) ~= "string" then
            logError('%s action_sets["%s"].scalar_actions[%s (type: %s)] <-- key must be a string', LOAD_ERROR_PREFIX, action_set_name, tostring(name), type(name))
        elseif type(source_action) ~= "table" then
            logError('%s action_sets["%s"].scalar_actions["%s"] must be a table', LOAD_ERROR_PREFIX, action_set_name, name)
        elseif type(source_action.name) ~= "string" then
            logError('%s action_sets["%s"].scalar_actions["%s"].name must be a string', LOAD_ERROR_PREFIX, action_set_name, name)
        elseif name ~= source_action.name then
            logError('%s action_sets["%s"].scalar_actions["%s"] <-- key must equals to action_sets["%s"].scalar_actions["%s"].name', LOAD_ERROR_PREFIX, action_set_name, name, action_set_name, name)
        elseif not target_actions[source_action.name] then
            logError("%s ActionSet '%s': ScalarAction '%s' does not exists", LOAD_ERROR_PREFIX, action_set_name, source_action.name)
        else
            mergeScalarAction(source_action, target_actions[source_action.name])
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

---@param action_set_name string
---@param source_actions table<string, foundation.InputSystem.Vector2Action>
---@param target_actions table<string, foundation.InputSystem.Vector2Action>
local function mergeVector2Actions(action_set_name, source_actions, target_actions)
    for name, source_action in pairs(source_actions) do
        if type(name) ~= "string" then
            logError('%s action_sets["%s"].vector2_actions[%s (type: %s)] <-- key must be a string', LOAD_ERROR_PREFIX, action_set_name, tostring(name), type(name))
        elseif type(source_action) ~= "table" then
            logError('%s action_sets["%s"].vector2_actions["%s"] must be a table', LOAD_ERROR_PREFIX, action_set_name, name)
        elseif type(source_action.name) ~= "string" then
            logError('%s action_sets["%s"].vector2_actions["%s"].name must be a string', LOAD_ERROR_PREFIX, action_set_name, name)
        elseif name ~= source_action.name then
            logError('%s action_sets["%s"].vector2_actions["%s"] <-- key must equals to action_sets["%s"].vector2_actions["%s"].name', LOAD_ERROR_PREFIX, action_set_name, name, action_set_name, name)
        elseif not target_actions[source_action.name] then
            logError("%s ActionSet '%s': Vector2Action '%s' does not exists", LOAD_ERROR_PREFIX, action_set_name, source_action.name)
        else
            mergeVector2Action(source_action, target_actions[source_action.name])
        end
    end
end

---@param name string
---@param source_action_set foundation.InputSystem.ActionSet
local function mergeActionSet(name, source_action_set)
    if type(name) ~= "string" then
        logError('%s action_sets[%s (type: %s)] <-- key must be a string', LOAD_ERROR_PREFIX, tostring(name), type(name))
        return
    end
    if type(source_action_set) ~= "table" then
        logError('%s action_sets["%s"] must be a table', LOAD_ERROR_PREFIX, name)
        return
    end
    if type(source_action_set.name) ~= "string" then
        logError('%s action_sets["%s"].name must be a string', LOAD_ERROR_PREFIX, name)
        return
    end
    if name ~= source_action_set.name then
        logError('%s action_sets["%s"] <-- key must equals to action_sets["%s"].name', LOAD_ERROR_PREFIX, name, name)
        return
    end
    local target_action_set = action_sets[source_action_set.name]
    if not target_action_set then
        logError("%s ActionSet '%s' does not exists", LOAD_ERROR_PREFIX, name)
        return
    end
    if type(source_action_set.boolean_actions) == "table" then
        mergeBooleanActions(target_action_set.name, source_action_set.boolean_actions, target_action_set.boolean_actions)
    elseif source_action_set.boolean_actions ~= nil then
        logError('%s action_sets["%s"].boolean_actions must be a table', LOAD_ERROR_PREFIX, name)
    end
    if type(source_action_set.scalar_actions) == "table" then
        mergeScalarActions(target_action_set.name, source_action_set.scalar_actions, target_action_set.scalar_actions)
    elseif source_action_set.scalar_actions ~= nil then
        logError('%s action_sets["%s"].scalar_actions must be a table', LOAD_ERROR_PREFIX, name)
    end
    if type(source_action_set.vector2_actions) == "table" then
        mergeVector2Actions(target_action_set.name, source_action_set.vector2_actions, target_action_set.vector2_actions)
    elseif source_action_set.vector2_actions ~= nil then
        logError('%s action_sets["%s"].vector2_actions must be a table', LOAD_ERROR_PREFIX, name)
    end
end

---@param source_other_setting foundation.InputSystem.OtherSetting
local function mergeOtherSetting(source_other_setting)
    for k, v in pairs(other_setting) do
        if type(v) == type(source_other_setting[k]) then
            other_setting[k] = source_other_setting[k]
        else
            logError('%s other_setting["%s"] must be a %s', LOAD_ERROR_PREFIX, k, type(v))
        end
    end
end

--- 不提供路径参数时，从默认位置读取
---@param path string?
function InputSystem.loadSetting(path)
    path = path or getDefaultSettingPath()

    local content, read_error = Files.readString(path)
    if not content then
        logError("read file '%s' failed: %s", path, tostring(read_error))
        return
    end
    local r, data = pcall(cjson.decode, content)
    if not r then
        logError("decode '%s' failed: %s", path, tostring(data))
        return
    end

    ---@type table<string, foundation.InputSystem.ActionSet>?
    local data_action_sets = data.action_sets
    if type(data_action_sets) == "table" then
        for name, data_action_set in pairs(data_action_sets) do
            mergeActionSet(name, data_action_set)
        end
    elseif data_action_sets ~= nil then
        logError("%s action_sets must be a table", LOAD_ERROR_PREFIX)
    end

    ---@type foundation.InputSystem.OtherSetting?
    local data_setting = data.other_setting
    if type(data_setting) == "table" then
        mergeOtherSetting(data_setting)
    elseif data_setting ~= nil then
        logError("%s other_setting must be a table", LOAD_ERROR_PREFIX)
    end
end

--#endregion
--------------------------------------------------------------------------------

return InputSystem
