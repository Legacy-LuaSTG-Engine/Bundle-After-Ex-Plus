---Deep copy a value (alternative implementation with cycle detection)
---@generic T
---@param orig T
---@return T
local function deep_copy(orig)
    local lookup_table = {}
    
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        
        local new_table = {}
        lookup_table[object] = new_table
        
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        
        return setmetatable(new_table, getmetatable(object))
    end
    
    return _copy(orig)
end

return deep_copy