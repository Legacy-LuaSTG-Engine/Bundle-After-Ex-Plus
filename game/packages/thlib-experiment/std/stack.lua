---@class std.stack
local stack = {}

function stack:top()
    return self._data[self._size]
end

function stack:size()
    return self._size
end

function stack:empty()
    return self._size == 0
end

function stack:push(v)
    local i = self._size + 1
    self._size = i
    self._data[i] = v
end

function stack:pop()
    if self._size > 0 then
        self._size = self._size - 1
    end
end

---@private
function stack:on_create()
    ---@private
    self._data = {}
    ---@private
    self._size = 0
end

function stack.create()
    ---@type std.stack
    local instance = {}
    instance.top = stack.top
    instance.size = stack.size
    instance.empty = stack.empty
    instance.push = stack.push
    instance.pop = stack.pop
    stack.on_create(instance)
    return instance
end

return stack
