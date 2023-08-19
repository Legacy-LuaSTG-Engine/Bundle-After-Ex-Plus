--- by @Xrysnow: https://github.com/Xrysnow
--- from: https://github.com/Xrysnow/lstgx_LuaCore/blob/master/setting_util.lua

---@class cjson.util
local M = {}

---@param str string
---@param indent string
---@return string
---@overload fun(str:string): string
function M.format_json(str, indent)
    assert(type(str) == "string")
    if indent then
        assert(type(indent) == "string")
    else
        indent = '    '
    end
    local ret = ''
    local level = 0
    local in_string = false
    for i = 1, #str do
        local s = string.sub(str, i, i)
        if s == '{' and (not in_string) then
            level = level + 1
            ret = ret .. '{\n' .. string.rep(indent, level)
        elseif s == '}' and (not in_string) then
            level = level - 1
            ret = string.format('%s\n%s}', ret, string.rep(indent, level))
        elseif s == '"' then
            in_string = not in_string
            ret = ret .. '"'
        elseif s == ':' and (not in_string) then
            ret = ret .. ': '
        elseif s == ',' and (not in_string) then
            ret = ret .. ',\n'
            ret = ret .. string.rep(indent, level)
        elseif s == '[' and (not in_string) then
            level = level + 1
            ret = ret .. '[\n' .. string.rep(indent, level)
        elseif s == ']' and (not in_string) then
            level = level - 1
            ret = string.format('%s\n%s]', ret, string.rep(indent, level))
        else
            ret = ret .. s
        end
    end
    return ret
end

return M
