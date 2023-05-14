--------------------------------------------------------------------------------
--- SPDX-License-Identifier: MIT
--- description: input.config
--- version: 1.0.0
--- author: 璀境石
--- detail: 管理按键映射配置
--------------------------------------------------------------------------------

---@class foundation.input.config
local M = {}

---@alias foundation.input.config.ActionType '"boolean"' | '"scalar"' | '"vector2"'

---@alias foundation.input.config.SourceType '"keyboard"' | '"pointer"' | '"controller"'

---@alias foundation.input.config.SourceComponent '"A"' | '"B"' | '"C"'

--------------------------------------------------------------------------------

---@class foundation.input.config.Action
local Action = {}

---@package
---@param name string
---@param type foundation.input.config.ActionType
function Action:onCreate(name, type)
    --- 动作名称  
    ---@package
    ---@type string
    self.name = name

    --- 动作类型  
    --- "boolean" 代表只有两种状态的数字输入，比如按键  
    --- "scalar" 代表输入是标量，比如手柄的扳机  
    --- "vector2" 代表输入是二维向量，比如手柄的摇杆  
    ---@package
    ---@type foundation.input.config.ActionType
    self.type = type
end

---@return string
function Action:getName()
    return self.name
end

---@return foundation.input.config.ActionType
function Action:getType()
    return self.type
end

---@param source_type foundation.input.config.SourceType
---@param source_component foundation.input.config.SourceComponent
function Action:addBinding(source_type, source_component)
end

---@param index number
---@param source_type foundation.input.config.SourceType
---@param source_component foundation.input.config.SourceComponent
function Action:setBinding(index, source_type, source_component)
end

---@return number
function Action:getBindingCount()
    return 0
end

---@return boolean
function Action:getBooleanValue()
    assert(self.type == "boolean", "invalid action type")
    return false
end

---@return number
function Action:getScalarValue()
    assert(self.type == "scalar", "invalid action type")
    return 0
end

---@return number, number
function Action:getVector2Value()
    assert(self.type == "vector2", "invalid action type")
    return 0, 0
end

--------------------------------------------------------------------------------

---@class foundation.input.config.ActionSet
local ActionSet = {}

---@package
---@param name string
function ActionSet:onCreate(name)
    self.name = name
    ---@type table<string, foundation.input.config.Action>
    self.action_set = {}
end

---@param path string
function ActionSet:loadBindingFromFile(path)
end

---@param path string
function ActionSet:saveBindingToFile(path)
end

---@param name string
---@param type foundation.input.config.ActionType
---@return foundation.input.config.Action
function ActionSet:createAction(name, type)
    assert(not self.action_set[name], "action exist")
    ---@type foundation.input.config.Action
    local instance = {}
    self.action_set[name] = instance
    setmetatable(instance, { __index = Action })
    instance:onCreate(name, type)
    return instance
end

---@param name string
---@return foundation.input.config.Action
function ActionSet:findAction(name)
    assert(self.action_set[name], "action does not exist")
    return self.action_set[name]
end

---@param callback fun(action:foundation.input.config.Action)
function ActionSet:forEachAction(callback)
    for _, v in pairs(self.action_set) do
        callback(v)
    end
end

--------------------------------------------------------------------------------

---@type table<string, foundation.input.config.ActionSet>
local action_set = {}

---@param name string
---@return foundation.input.config.ActionSet
function M.createActionSet(name)
    assert(not action_set[name], "action set exist")
    ---@type foundation.input.config.ActionSet
    local instance = {}
    action_set[name] = instance
    setmetatable(instance, { __index = ActionSet })
    instance:onCreate(name)
    return instance
end

---@param name string
---@return foundation.input.config.ActionSet
function M.findActionSet(name)
    assert(action_set[name], "action set does not exist")
    return action_set[name]
end

---@param callback fun(action:foundation.input.config.ActionSet)
function M.forEachActionSet(callback)
    for _, v in pairs(action_set) do
        callback(v)
    end
end

return M
