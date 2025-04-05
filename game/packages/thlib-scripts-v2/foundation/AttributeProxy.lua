local rawget = rawget
local rawset = rawset
local type = type
local pairs = pairs
local setmetatable = setmetatable
local lstg = lstg

local KEY_ATTRIBUTE_PROXIES_LIST = "___attribute_proxies"
local KEY_ATTRIBUTE_PROXIES_IS_GAME_OBJECT = "___attribute_proxies_is_game_object"
local KEY_ATTRIBUTE_PROXIES_STORAGE = "___attribute_proxies_storage"

if false then
    ---@class foundation.AttributeProxy.Proxy
    local Proxy = {
        key = ""
    }

    ---@param key string @The key of the attribute.
    ---@param value any @Current value of the attribute.
    ---@param storage table<string, any> @The storage table of all attributes.
    ---@overload fun(key: string)
    function Proxy:init(key, value, storage)
    end

    ---@param key string @The key of the attribute.
    ---@param storage table<string, any> @The storage table of all attributes.
    ---@return any
    function Proxy:getter(key, storage)
    end

    ---@param key string @The key of the attribute.
    ---@param value any @The new value of the attribute.
    ---@param storage table<string, any> @The storage table of all attributes.
    function Proxy:setter(key, value, storage)
    end
end

local function deep_copy(value)
    if type(value) == "table" then
        local copy = {}
        for k, v in pairs(value) do
            copy[k] = deep_copy(v)
        end
        return copy
    end
    return value
end

---@class foundation.AttributeProxy
local M = {}

---Get the value of an attribute from the storage table.
---@param key string @The key of the attribute.
---@return any
function M:getStorageValue(key)
    return self[KEY_ATTRIBUTE_PROXIES_STORAGE][key]
end

---Set the value of an attribute in the storage table.
---@param key string @The key of the attribute.
---@param value any @The new value of the attribute.
function M:setStorageValue(key, value)
    self[KEY_ATTRIBUTE_PROXIES_STORAGE][key] = value
end

---The metatable index function for the attribute proxy.
---@param key string @The key of the attribute.
---@return any
function M:___metatableIndex(key)
    local proxy = self[KEY_ATTRIBUTE_PROXIES_LIST][key]
    if proxy then
        return proxy.getter(self, key, self[KEY_ATTRIBUTE_PROXIES_STORAGE])
    end
    if self[KEY_ATTRIBUTE_PROXIES_IS_GAME_OBJECT] then
        return lstg.GetAttr(self, key)
    end
    return rawget(self, key)
end

---The metatable newindex function for the attribute proxy.
---@param key string @The key of the attribute.
---@param value any
function M:___metatableNewIndex(key, value)
    local proxy = self[KEY_ATTRIBUTE_PROXIES_LIST][key]
    if proxy then
        proxy.setter(self, key, value, self[KEY_ATTRIBUTE_PROXIES_STORAGE])
        return
    end
    if self[KEY_ATTRIBUTE_PROXIES_IS_GAME_OBJECT] then
        lstg.SetAttr(self, key, value)
        return
    end
    rawset(self, key, value)
end

---Apply a list of proxies to the object.
---@param proxies table<any, foundation.AttributeProxy.Proxy>
function M:applyProxies(proxies)
    proxies = deep_copy(proxies)
    local current_proxies = self[KEY_ATTRIBUTE_PROXIES_LIST]
    if not current_proxies then
        current_proxies = {}
        local isGameObject = lstg.IsValid(self)
        rawset(self, KEY_ATTRIBUTE_PROXIES_LIST, current_proxies)
        rawset(self, KEY_ATTRIBUTE_PROXIES_IS_GAME_OBJECT, isGameObject)
        rawset(self, KEY_ATTRIBUTE_PROXIES_STORAGE, {})
        setmetatable(self, {
            __index = M.___metatableIndex,
            __newindex = M.___metatableNewIndex,
        })
    end
    local storage = self[KEY_ATTRIBUTE_PROXIES_STORAGE]
    for _, proxy in pairs(proxies) do
        if proxies.key == KEY_ATTRIBUTE_PROXIES_LIST or proxies.key == KEY_ATTRIBUTE_PROXIES_STORAGE then
            error(string.format("Invalid proxy key: %q", proxy.key))
        end
        local value = self[proxy.key]
        current_proxies[proxy.key] = proxy
        if value ~= nil then
            rawset(self, proxy.key, nil)
            if proxy.init then
                proxy.init(self, proxy.key, value, storage)
            else
                self[proxy.key] = value
            end
        elseif proxy.init then
            proxy.init(self, proxy.key, storage)
        end
    end
end

---Create a new attribute proxy.
---@param key string
---@param getter function
---@param setter function
---@param init function
---@return foundation.AttributeProxy.Proxy
---@overload fun(key: string): foundation.AttributeProxy.Proxy
---@overload fun(key: string, getter: function): foundation.AttributeProxy.Proxy
---@overload fun(key: string, getter: function, setter: function): foundation.AttributeProxy.Proxy
function M.createProxy(key, getter, setter, init)
    ---@type foundation.AttributeProxy.Proxy
    return {
        key = key,
        getter = getter or M.getStorageValue,
        setter = setter or M.setStorageValue,
        init = init,
    }
end

return M