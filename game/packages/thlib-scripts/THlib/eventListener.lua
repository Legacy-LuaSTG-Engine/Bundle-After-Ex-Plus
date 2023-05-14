---@class eventListener.event
local event = {
    group = "",
    name = "",
    level = 0,
    func = function()
    end,
}

---@class eventListener
---@return eventListener
eventListener = plus.Class()
local eventListener = eventListener

function eventListener:init()
    self.data = {}
end

---创建事件组
---@param group string @事件组名称
function eventListener:create(group)
    assert(type(group) == "string")
    self.data[group] = self.data[group] or {}
end

---查找并获取事件
---@param group string @事件组名称
---@param name string @事件名称
---@return eventListener.event|nil
function eventListener:find(group, name)
    assert(type(group) == "string")
    assert(type(name) == "string")
    if self.data[group] and self.data[group][name] then
        return self.data[group][name]
    end
end

---排序事件组
---@param group string @事件组名称
function eventListener:sort(group)
    assert(type(group) == "string")
    table.sort(self.data[group], function(a, b)
        if a.level and b.level then
            return b.level < a.level
        elseif b.level then
            return true
        else
            return false
        end
    end)
end

---添加事件
---@param group string @事件组名称
---@param name string @事件名称
---@param level number @事件优先度
---@param func function @事件函数
---@return boolean @是否产生了事件覆盖
function eventListener:addEvent(group, name, level, func)
    level = level or 0
    assert(type(group) == "string")
    assert(type(name) == "string")
    assert(type(level) == "number")
    assert(type(func) == "function")
    if not self.data[group] then
        self:create(group)
    end
    local ref = false
    if self:find(group, name) then
        self:remove(group, name)
        ref = true
    end
    local data = {
        group = group,
        name = name,
        level = level,
        func = func,
    }
    table.insert(self.data[group], data)
    self.data[group][name] = data
    self:sort(group)
    return ref
end

---移除事件
---@param group string @事件组名称
---@param name string @事件名称
function eventListener:remove(group, name)
    assert(type(group) == "string")
    assert(type(name) == "string")
    local data = self:find(group, name)
    if data then
        data.level = nil
        self:sort(group)
        self.data[group][name] = nil
        table.remove(self.data[group], 1)
    end
end

---执行事件组
---@param group string @事件组名称
function eventListener:Do(group, ...)
    assert(type(group) == "string")
    if not self.data[group] then
        return
    end
    self:sort(group)
    for _, data in ipairs(self.data[group]) do
        data.func(...)
    end
end

return eventListener