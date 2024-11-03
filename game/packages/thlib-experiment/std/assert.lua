local debug = require("debug")
local g_assert = assert
local g_error = error
local g_type = type

---@class std.assert
local m_assert = {}

---@generic T
---@param value T
---@param required_type type
---@param argument_index integer?
function m_assert.argument_type(value, required_type, argument_index)
    local value_type = g_type(value)
    if value_type ~= required_type then
        argument_index = argument_index or 1
        local debug_info = debug.getinfo(2, 'n')
        g_error(("bad argument #%d to '%s' (%s expected, got string)"):format(argument_index, debug_info.name, required_type, value_type))
    end
end

return m_assert
