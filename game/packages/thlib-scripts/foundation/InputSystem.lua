--- 输入系统
---@class foundation.InputSystem
local InputSystem = {}

--------------------------------------------------------------------------------
--- 动作集辅助函数

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
    return false;
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

--------------------------------------------------------------------------------
--- 动作集

---@alias foundation.InputSystem.ActionType '"boolean"' | '"scalar"' | '"vector2"'

---@class foundation.InputSystem.Action
---@field name string
---@field type foundation.InputSystem.ActionType

---@class foundation.InputSystem.BooleanAction : foundation.InputSystem.Action
---@field keyboard_bindings   integer[]
---@field mouse_bindings      integer[]
---@field controller_bindings integer[]
---@field hid_bindings        integer[]
local BooleanAction = {}

---@param key integer
function BooleanAction:addKeyboardBinding(key)
    if isArrayContains(self.keyboard_bindings, key) then
        return
    end
    table.insert(self.keyboard_bindings, key)
end

---@param key integer
function BooleanAction:removeKeyboardBinding(key)
    removeArrayValue(self.keyboard_bindings, key)
end

---@param key integer
function BooleanAction:addMouseBinding(key)
    if isArrayContains(self.mouse_bindings, key) then
        return
    end
    table.insert(self.mouse_bindings, key)
end

---@param key integer
function BooleanAction:removeMouseBinding(key)
    removeArrayValue(self.mouse_bindings, key)
end

---@param key integer
function BooleanAction:addControllerBinding(key)
    if isArrayContains(self.controller_bindings, key) then
        return
    end
    table.insert(self.controller_bindings, key)
end

---@param key integer
function BooleanAction:removeControllerBinding(key)
    removeArrayValue(self.controller_bindings, key)
end

---@param key integer
function BooleanAction:addHidBinding(key)
    if isArrayContains(self.hid_bindings, key) then
        return
    end
    table.insert(self.hid_bindings, key)
end

---@param key integer
function BooleanAction:removeHidBinding(key)
    removeArrayValue(self.hid_bindings, key)
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

---@alias foundation.InputSystem.PhysicalBindingType '"key"' | '"axis"' | '"joystick"'

---@class foundation.InputSystem.ScalarBinding
---@field type foundation.InputSystem.PhysicalBindingType
---@field key  integer
---@field axis integer

---@class foundation.InputSystem.ScalarAction : foundation.InputSystem.Action
---@field keyboard_bindings   foundation.InputSystem.ScalarBinding[]
---@field mouse_bindings      foundation.InputSystem.ScalarBinding[]
---@field controller_bindings foundation.InputSystem.ScalarBinding[]
---@field hid_bindings        foundation.InputSystem.ScalarBinding[]

---@class foundation.InputSystem.Vector2Binding
---@field type           foundation.InputSystem.PhysicalBindingType
---@field joystick       integer
---@field x_axis         integer
---@field y_axis         integer
---@field positive_x_key integer
---@field negative_x_key integer
---@field positive_y_key integer
---@field negative_y_key integer

---@class foundation.InputSystem.Vector2Action : foundation.InputSystem.Action
---@field keyboard_bindings   foundation.InputSystem.Vector2Binding[]
---@field mouse_bindings      foundation.InputSystem.Vector2Binding[]
---@field controller_bindings foundation.InputSystem.Vector2Binding[]
---@field hid_bindings        foundation.InputSystem.Vector2Binding[]

---@class foundation.InputSystem.ActionSet
---@field name            string
---@field boolean_actions table<string, foundation.InputSystem.BooleanAction>
---@field scalar_actions  table<string, foundation.InputSystem.ScalarAction>
---@field vector2_actions table<string, foundation.InputSystem.Vector2Action>
local ActionSet = {}

function ActionSet:createAction(name)
    
end

---@param name string
---@return foundation.InputSystem.ActionSet
function ActionSet.create(name)
    local instance = {
        name = name,
    }
    setmetatable(instance, { __index = ActionSet })
    return instance
end

---@type table<string, foundation.InputSystem.ActionSet>
local action_sets = {}

---@param name string
---@return foundation.InputSystem.ActionSet
function InputSystem.createActionSet(name)
    assert(type(name) == "string", "name must be a string")
    if action_sets[name] then
        return action_sets[name]
    end
    local action_set = ActionSet.create(name)
    action_sets[name] = action_set
    return action_set
end

--------------------------------------------------------------------------------
--- 动作集切换

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

--------------------------------------------------------------------------------
--- 输入系统内部状态

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

--------------------------------------------------------------------------------
--- 状态更新

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

function InputSystem.update()
    for _, v in pairs(raw_action_set_values) do
        copyLastActionSetValues(v)
    end
    copyLastActionSetValues(merged_action_set_values)
end

--------------------------------------------------------------------------------
--- 读取动作值辅助函数

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

--------------------------------------------------------------------------------
--- 读取动作值

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

--------------------------------------------------------------------------------
--- 追踪动作值变化

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

--------------------------------------------------------------------------------

return InputSystem
