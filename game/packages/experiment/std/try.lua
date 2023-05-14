local debug = require("debug")
local type = type
local assert = assert

---@class std.try
local M = {}

---@type string|nil
local match_error_type = nil

---@param e string
local function match(e)
    if type(e) == "string" then
        local _, pos = e:find(":%d+: ")
        if pos then
            match_error_type = e:sub(pos + 1)
        end
    end
end

---@param e string
---@return string
local function traceback(e)
    match(e)
    return debug.traceback(e, 2)
end

---@param try_f fun()
---@return std.try.context
function M.try(try_f)
    assert(type(try_f) == "function")

    ---@class std.try.context
    local context = {}

    ---@private
    context.try_f = try_f

    ---@param error_type string
    ---@param catch_f fun(e:string)
    ---@return std.try.context
    ---@overload fun(catch_f:fun(e:string)):std.try.context
    function context.catch(error_type, catch_f)
        if catch_f then
            ---@private
            ---@type table<string, fun(e:string)>
            context.catch_map = context.catch_map or {}
            assert(type(error_type) == "string")
            assert(type(catch_f) == "function")
            assert(type(context.catch_map[error_type]) == "nil")
            context.catch_map[error_type] = catch_f
        else
            assert(type(error_type) == "function")
            ---@private
            context.catch_f = error_type
        end
        return context
    end

    ---@param finally_f fun()
    ---@return std.try.context
    function context.finally(finally_f)
        assert(type(finally_f) == "function")
        ---@private
        context.finally_f = finally_f
        return context
    end

    function context.execute()
        match_error_type = nil
        local result, message = xpcall(context.try_f, traceback)
        if not result then
            if context.catch_map and context.catch_map[match_error_type] then
                context.catch_map[match_error_type](message)
            else
                context.catch_f(message)
            end
        end
        if context.finally_f then
            context.finally_f()
        end
    end

    return context
end

return M
