local cjson_util = require("cjson.util")

local temp_file_suffix = ".writing"

---@class foundation.DataStorage
local M = {}

---@generic T
---@param t T
---@return T
local function deep_copy(t)
    local tt = type(t)
    if tt == "boolean" or tt == "number" or tt == "string" then
        return t
    elseif tt == "table" then
        local r = {}
        for k, v in pairs(t) do
            local kt = type(k)
            if kt == "number" or kt == "string" then
                r[k] = deep_copy(v)
            else
                error(string.format("unexpected data type encountered: '%s', which cannot be a table key", kt))
            end
        end
        return r
    else
        error(string.format("unexpected data type encountered: '%s', which cannot be copied", tt))
    end
end

---@generic T
---@generic T
---@param template T
---@param value T
local function template_copy(template, value)
    local Tt = type(template)
    if Tt == type(value) then
        if Tt == "boolean" or Tt == "number" or Tt == "string" then
            return value
        elseif Tt == "table" then
            local result = {}
            for k, v in pairs(template) do
                if type(v) == type(value[k]) then
                    result[k] = template_copy(v, value[k])
                else
                    result[k] = deep_copy(v)
                end
            end
            return result
        end
    else
        return deep_copy(template)
    end
end

local metatable = {}

---@type table<table, table>
local shadow = {}
setmetatable(shadow, { __mode = 'k' })

local function deep_proxy(t)
    local s = {} -- shadow
    for k, v in pairs(t) do
        local kt = type(k)
        if not (kt == "number" or kt == "string") then -- json 不允许 boolean 作为 key
            error(string.format("invalid key type '%s', accept 'number' or 'string'", kt))
        end
        local vt = type(v)
        if not (vt == "boolean" or vt == "number" or vt == "string" or vt == "table") then
            error(string.format("invalid value type '%s', accept 'boolean', 'number', 'string' or 'table'", vt))
        end
        if vt == "table" then
            local mt = getmetatable(v)
            if mt and mt ~= metatable then
                error("invalid table, accept no metatable table")
            end
            s[k] = deep_proxy(v)
        else
            s[k] = v
        end
    end
    for k, _ in pairs(s) do
        t[k] = nil
    end
    shadow[t] = s
    setmetatable(t, metatable)
    return t
end

function metatable:__index(k)
    return shadow[self][k]
end

function metatable:__newindex(k, v)
    local kt = type(k)
    if not (kt == "number" or kt == "string") then -- json 不允许 boolean 作为 key
        error(string.format("invalid key type '%s', accept 'number' or 'string'", kt))
    end
    local vt = type(v)
    if vt == "nil" then
        -- clear Op
        shadow[self][k] = nil
        return
    end
    if not (vt == "boolean" or vt == "number" or vt == "string" or vt == "table") then
        error(string.format("invalid value type '%s', accept 'boolean', 'number', 'string' or 'table'", vt))
    end
    if vt == "table" then
        local mt = getmetatable(v)
        if mt and mt ~= metatable then
            error("invalid table, accept no metatable table")
        end
        v = deep_proxy(v)
    end
    shadow[self][k] = v
end

local function copy_proxy(t)
    local r = {}
    if getmetatable(t) == metatable then
        for k, v in pairs(shadow[t]) do
            if type(v) == "table" then
                r[k] = copy_proxy(v)
            else
                r[k] = v
            end
        end
    else
        for k, v in pairs(t) do
            if type(v) == "table" then
                r[k] = copy_proxy(v)
            else
                r[k] = v
            end
        end
    end
    return r
end

---@return boolean
function M:load()
    if self.default_definitions then
        self.data = deep_proxy(deep_copy(self.default_definitions))
    else
        self.data = deep_proxy({})
    end
    if lstg.FileManager.FileExist(self.path) then
        local f, e = io.open(self.path, "rb") -- TODO: 其他平台应该没有 b 模式
        if f then
            local s = f:read("*a")
            f:close()
            local r, t = pcall(cjson.decode, s)
            if r then
                if self.default_definitions then
                    self.data = deep_proxy(template_copy(self.default_definitions, t))
                else
                    self.data = deep_proxy(deep_copy(t))
                end
                return true
            else
                lstg.Log(4, string.format("decode data storage file '%s' failed: %s", self.path, tostring(t)))
            end
        else
            lstg.Log(4, string.format("open data storage file '%s' failed: %s", self.path, tostring(e)))
        end
        return false
    else
        lstg.Log(2, string.format("data storage file '%s' not exist", self.path))
        return true
    end
end

---@param content string
---@param path string
---@param safemode boolean
---@return boolean
function M.save_text(content, path, safemode)
    local using_safemode = false
    if safemode and lstg.FileManager.FileExist(path) then
        using_safemode = true
    end
    local f, e
    local outputpath
    if using_safemode then
        outputpath = path .. temp_file_suffix
    else
        outputpath = path
    end

    f, e = io.open(outputpath, "wb")
    if f then
        f:write(content)
        f:close()
    else
        lstg.Log(4, string.format("failed to open file '%s': %s", outputpath, tostring(e)))
        return false
    end

    if using_safemode then
        local success, err
        success, err = os.remove(path)
        if not success then
            lstg.Log(4, string.format("remove file '%s' failed: %s", path, tostring(err)))
            return false
        end
        success, err = os.rename(outputpath, path)
        if not success then
            lstg.Log(4, string.format("rename file '%s' to '%s' failed: %s", outputpath, path, tostring(err)))
            return false
        end
        return true
    else
        return true
    end
end

---@param fmt boolean
---@param safemode boolean
---@overload fun(self:foundation.DataStorage)
---@overload fun(self:foundation.DataStorage, fmt:boolean)
function M:save(fmt, safemode)
    local r, s = pcall(cjson.encode, copy_proxy(self.data))
    if r then
        local content
        if fmt then
            content = cjson_util.format_json(s)
        else
            content = s
        end
        return M.save_text(content, self.path, safemode)
    else
        lstg.Log(4, string.format("encode data storage file '%s' failed: %s", self.path, tostring(s)))
    end
    return false
end

---@generic T
---@param key number | string
---@return T
function M:get(key)
    return self.data[key]
end

---@generic T
---@param key number | string
---@param value boolean | number | string | table
function M:set(key, value)
    self.data[key] = value
end

---@generic T
---@return T
function M:root()
    return self.data
end

---@private
---@generic T
---@param path string
---@param default_definitions T
function M:initialize(path, default_definitions)
    self.path = path
    if default_definitions then
        self.default_definitions = deep_copy(default_definitions)
    end
    self:load()
end

---@generic T
---@param path string
---@param default_definitions T
---@return foundation.DataStorage
---@overload fun(path:string): foundation.DataStorage
function M.open(path, default_definitions)
    ---@type foundation.DataStorage
    local I = {}
    setmetatable(I, { __index = M })
    I:initialize(path, default_definitions)
    return I
end

M._visit = copy_proxy

return M
