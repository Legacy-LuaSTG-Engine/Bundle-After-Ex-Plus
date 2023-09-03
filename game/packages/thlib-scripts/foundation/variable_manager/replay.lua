--[[
    记录关卡内变量，并在replay的关卡开始处读取。用于记录符卡收取时间和关卡内选择等操作。
    By TNW
]]

---@class foundation.variable_manager.replay
local M = {}

local var_replay = {}
local next_var_replay = {}

---清空变量表
function M.reset()
    var_replay = {}
end

---设置下一关将要应用的变量表，原因参见nextvar
---@param vartable table
function M.set_next_vartable(vartable)
    if vartable and type(vartable) == "table" then
        next_var_replay = vartable
    else
        next_var_replay = {}
    end
end

---切入下一关时将先前加载的变量表覆盖当前的
function M.apply_next_vartable()
    var_replay = next_var_replay
    next_var_replay = {}
end

---获取记录所有变量的表
---@return table
function M.get_valuetable()
    return var_replay
end

---设置需要记录的变量
---@param key string
function M.set_value(key, value)
    var_replay[key] = value
end

---通过键值获取变量，若不存在则用提供的默认值创建并返回该值
---@param key string
function M.get_value(key, default_value)
    if var_replay[key] == nil then
        var_replay[key] = default_value
    end
    return var_replay[key]
end

return M