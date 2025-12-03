local type = type
local setmetatable = setmetatable

---@class foundation.StateMachine.StateCallbacks
---@field onEnter function|nil @进入状态时的回调函数
---@field onExit function|nil @离开状态时的回调函数
---@field onUpdate function|nil @状态更新时的回调函数

---@class foundation.StateMachine
local M = {}

---@private
function M:initialize()
    self.states = {}
    self.stateCount = 0
    self.nameToId = {}

    self.transitions = {}
    self.transitionCount = 0
    self.transitionsByState = {}

    self.currentStateId = 0
    self.previousStateId = 0

    self.context = {}
end

---注册一个新状态
---@param name string @状态名称
---@param callbacks foundation.StateMachine.StateCallbacks|nil @状态回调函数
---@return number @状态 ID
function M:registerState(name, callbacks)
    local id = self.stateCount + 1
    self.stateCount = id
    self.nameToId[name] = id

    local state = {
        id = id,
        name = name,
        onEnter = callbacks and callbacks.onEnter or nil,
        onExit = callbacks and callbacks.onExit or nil,
        onUpdate = callbacks and callbacks.onUpdate or nil,
    }

    self.states[id] = state
    return id
end

---添加状态转换
---@param fromState string|number @起始状态名称或 ID
---@param toState string|number @目标状态名称或 ID
---@param condition function|nil @转换条件函数，返回 true 时转换
---@return boolean @是否添加成功
function M:addTransition(fromState, toState, condition)
    local fromId = type(fromState) == "string" and self.nameToId[fromState] or fromState
    local toId = type(toState) == "string" and self.nameToId[toState] or toState

    if not fromId or not toId then
        return false
    end

    local idx = self.transitionCount + 1
    self.transitionCount = idx

    local transition = {
        from = fromId,
        to = toId,
        condition = condition,
    }

    self.transitions[idx] = transition

    local stateTransitions = self.transitionsByState[fromId]
    if not stateTransitions then
        stateTransitions = {}
        self.transitionsByState[fromId] = stateTransitions
    end
    stateTransitions[#stateTransitions + 1] = transition

    return true
end

---设置当前状态
---@param state string|number @状态名称或 ID
---@return boolean @是否设置成功
function M:setState(state)
    local stateId = type(state) == "string" and self.nameToId[state] or state

    if not stateId or not self.states[stateId] then
        return false
    end

    local currentState = self.states[self.currentStateId]
    local nextState = self.states[stateId]

    if currentState and currentState.onExit then
        currentState.onExit(self.context)
    end

    self.previousStateId = self.currentStateId
    self.currentStateId = stateId

    if nextState.onEnter then
        nextState.onEnter(self.context)
    end

    return true
end

---更新状态机
---@vararg any @传递给状态更新回调的参数
function M:update(...)
    local currentState = self.states[self.currentStateId]

    if not currentState then
        return
    end

    if currentState.onUpdate then
        currentState.onUpdate(self.context, ...)
    end

    local transitions = self.transitionsByState[self.currentStateId]

    if transitions then
        for i = 1, #transitions do
            local transition = transitions[i]
            local condition = transition.condition
            if not condition or condition(self.context) then
                self:setState(transition.to)
                return
            end
        end
    end
end

---获取当前状态名称
---@return string|nil @当前状态名称
function M:getCurrentStateName()
    local state = self.states[self.currentStateId]
    return state and state.name or nil
end

---获取当前状态 ID
---@return number @当前状态 ID
function M:getCurrentStateId()
    return self.currentStateId
end

---获取前一个状态 ID
---@return number @前一个状态 ID
function M:getPreviousStateId()
    return self.previousStateId
end

---根据名称获取状态 ID
---@param name string @状态名称
---@return number|nil @状态 ID
function M:getStateId(name)
    return self.nameToId[name]
end

---设置上下文数据
---@param key string @键
---@param value any @值
function M:setContext(key, value)
    self.context[key] = value
end

---获取上下文数据
---@param key string @键
---@return any @值
function M:getContext(key)
    return self.context[key]
end

---创建一个新的状态机实例
---@return foundation.StateMachine
function M.new()
    ---@type foundation.StateMachine
    local instance = {}
    setmetatable(instance, { __index = M })
    instance:initialize()
    return instance
end

return M

