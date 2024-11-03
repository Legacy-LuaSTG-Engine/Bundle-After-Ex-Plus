local debug = require("debug")
local error = error
local type = type

---@class std.assert
local assert = {}

---@param condition boolean
---@param message string?
function assert.is_true(condition, message)
    if not condition then
        error(message, 2)
    end
end

---@param condition boolean
---@param message string?
function assert.is_false(condition, message)
    if condition then
        error(message, 2)
    end
end

---@generic T
---@param value T
---@param required_type type
---@param argument_index integer?
function assert.is_argument_type(value, required_type, argument_index)
    local t = type(value)
    if t ~= required_type then
        argument_index = argument_index or 1
        local debug_info = debug.getinfo(2, 'n')
        local message = ("bad argument #%d to '%s' (%s expected, got %s)")
            :format(argument_index, debug_info.name, required_type, t)
        error(message, 3)
    end
end

return assert
