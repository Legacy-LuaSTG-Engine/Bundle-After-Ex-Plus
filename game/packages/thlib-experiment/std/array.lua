---@class std.array
local array = {}

---@return boolean
function array:empty()
    return self._size == 0
end

---@return integer
function array:size()
    return self._size
end

function array:front()
    assert(self._size >= 1, "array is empty")
    return self._data[1]
end

function array:back()
    assert(self._size >= 1, "array is empty")
    return self._data[self._size]
end

---@param i integer
function array:at(i)
    assert(i >= 1 and i <= self._size, "out of array bound")
    return self._data[i]
end

function array:fill(v)
    for i = 1, self._size do
        self._data[i] = v
    end
end

---@return integer
function array:index_of(v)
    for i = 1, self._size do
        if self._data[i] == v then
            return i
        end
    end
    return 0
end

---@return integer
function array:last_index_of(v)
    for i = self._size, 1, -1 do
        if self._data[i] == v then
            return i
        end
    end
    return 0
end

---@return integer
function array:index_of_list(l)
    local n = #l
    if self._size > 0 and n > 0 and n <= self._size then
        local b = false
        for i = 1, (self._size + 1 - n) do
            b = true
            for j = 1, n do
                if self._data[i - 1 + j] ~= l[j] then
                    b = false
                    break
                end
            end
            if b then
                return i
            end
        end
    end
    return 0
end

function array:contains(v)
    for i = 1, self._size do
        if self._data[i] == v then
            return true
        end
    end
    return false
end

---@private
---@param size integer
function array:on_create(size, initialize_value)
    ---@private
    self._data = {}
    ---@private
    self._size = size
    if type(initialize_value) ~= "nil" then
        for i = 1, self._size do
            self._data[i] = initialize_value
        end
    end
end

---@private
function array:__len()
    return self._size
end

---@private
function array:__index(k)
    assert(k >= 1 and k <= self._size, "out of array bound")
    return self._data[k]
end

---@private
function array:__newindex(k, v)
    assert(k >= 1 and k <= self._size, "out of array bound")
    self._data[k] = v
end

---@private
array._metatable = {
    __len = array.__len,
    __index = array.__index,
    __newindex = array.__newindex,
}

---@param size integer
function array.create(size, initialize_value)
    ---@type std.array
    local instance = {}
    instance.empty = array.empty
    instance.size = array.size
    instance.front = array.front
    instance.back = array.back
    instance.at = array.at
    instance.fill = array.fill
    instance.index_of = array.index_of
    instance.last_index_of = array.last_index_of
    instance.contains = array.contains
    array.on_create(instance, size, initialize_value)
    setmetatable(instance, array._metatable)
    return instance
end

return array
