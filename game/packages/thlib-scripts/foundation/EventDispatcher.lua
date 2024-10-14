local type = type
local assert = assert
local ipairs = ipairs
local table = table
local table_sort = require("foundation.QuickSort")

if false then
    ---@class foundation.EventDispatcher.Event
    local event = {
        group = "",
        name = "",
        priority = 0,
        callback = function()
        end,
    }
end

---@param a foundation.EventDispatcher.Event
---@param b foundation.EventDispatcher.Event
---@return boolean
local function compareEventPriority(a, b)
    if a.priority and b.priority then
        return b.priority < a.priority
    elseif b.priority then
        return true
    else
        return false
    end
end

---@param data table<string,foundation.EventDispatcher.Event>
local function sortEvent(data)
    table_sort(data, compareEventPriority)
end

---@class foundation.EventDispatcher
local M = {
    ---@type table<string,table<string,foundation.EventDispatcher.Event>>
    data = {},
}

---创建事件组
---@param group string @事件组名称
function M:CreateEventGroup(group)
    assert(type(group) == "string", "invalid argument #1 (string expected)")
    self.data[group] = self.data[group] or {}
end

---清空所有事件
function M:Clear()
    self.data = {}
end

---查找并获取事件
---@param group string @事件组名称
---@param name string @事件名称
---@return foundation.EventDispatcher.Event|nil
function M:FindEvent(group, name)
    assert(type(group) == "string", "invalid argument #1 (string expected)")
    assert(type(name) == "string", "invalid argument #2 (string expected)")
    return self.data[group] and self.data[group][name]
end

---添加事件
---@param group string @事件组名称
---@param name string @事件名称
---@param priority number @事件优先度
---@param callback function @事件函数
---@return boolean @是否产生了事件覆盖
function M:RegisterEvent(group, name, priority, callback)
    priority = priority or 0
    assert(type(group) == "string", "invalid argument #1 (string expected)")
    assert(type(name) == "string", "invalid argument #2 (string expected)")
    assert(type(priority) == "number", "invalid argument #3 (number expected)")
    assert(type(callback) == "function", "invalid argument #4 (function expected)")
    if not self.data[group] then
        self:CreateEventGroup(group)
    end
    local ref = false
    if self:FindEvent(group, name) then
        self:UnregisterEvent(group, name)
        ref = true
    end
    ---@type foundation.EventDispatcher.Event
    local data = {
        group = group,
        name = name,
        priority = priority,
        callback = callback,
    }
    table.insert(self.data[group], data)
    self.data[group][name] = data
    sortEvent(self.data[group])
    return ref
end

---移除事件
---@param group string @事件组名称
---@param name string @事件名称
function M:UnregisterEvent(group, name)
    assert(type(group) == "string", "invalid argument #1 (string expected)")
    assert(type(name) == "string", "invalid argument #2 (string expected)")
    local data = self:FindEvent(group, name)
    if data then
        data.priority = nil
        sortEvent(self.data[group])
        table.remove(self.data[group], 1)
        self.data[group][name] = nil
    end
end

---执行事件组
---@param group string @事件组名称
function M:DispatchEvent(group, ...)
    assert(type(group) == "string", "invalid argument #1 (string expected)")
    if not self.data[group] then
        return
    end
    for _, data in ipairs(self.data[group]) do
        data.callback(...)
    end
end

---@param self foundation.EventDispatcher
---@param group string
local function sortEventGroup(self, group)
    assert(type(group) == "string", "invalid argument #1 (string expected)")
    if self.data[group] then
        sortEvent(self.data[group])
    end
end

---@return foundation.EventDispatcher
local function createEventDispatcher()
    ---@type foundation.EventDispatcher
    local obj = {
        data = {},
    }
    obj.Clear = M.Clear
    obj.CreateEventGroup = M.CreateEventGroup
    obj.FindEvent = M.FindEvent
    obj.RegisterEvent = M.RegisterEvent
    obj.UnregisterEvent = M.UnregisterEvent
    obj.DispatchEvent = M.DispatchEvent
    -- for compatibility
    obj.create = M.CreateEventGroup
    obj.find = M.FindEvent
    obj.addEvent = M.RegisterEvent
    obj.remove = M.UnregisterEvent
    obj.sort = sortEventGroup
    obj.Do = M.DispatchEvent
    --
    return obj
end

return createEventDispatcher