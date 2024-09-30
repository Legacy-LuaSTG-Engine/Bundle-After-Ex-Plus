local rawset = rawset
local pairs = pairs
local setmetatable = setmetatable
local lstg = lstg

local KEY_ATTRIBUTE_PROXIES_LIST = "___attribute_proxies"
local KEY_ATTRIBUTE_PROXIES_STORAGE = "___attribute_proxies_storage"

if false then
    ---@class foundation.AttributeProxy.Proxy
    local Proxy = {
        key = ""
    }

    ---@param key string
    ---@param value any
    ---@param storage table<string, any>
    ---@overload fun(key: string)
    function Proxy:init(key, value, storage)
    end

    ---@param key string
    ---@param storage table<string, any>
    ---@return any
    function Proxy:getter(self, key, storage)
    end

    ---@param key string
    ---@param value any
    ---@param storage table<string, any>
    function Proxy:setter(self, key, value, storage)
    end
end

---@class foundation.AttributeProxy
local M = {}

---@param key string
---@return any
function M:getStorageValue(key)
    return self[KEY_ATTRIBUTE_PROXIES_STORAGE][key]
end

---@param key string
---@param value any
function M:setStorageValue(key, value)
    self[KEY_ATTRIBUTE_PROXIES_STORAGE][key] = value
end

---@param key string
---@return any
function M:___metatableIndex(key)
    local proxy = self[KEY_ATTRIBUTE_PROXIES_LIST][key]
    if proxy then
        return proxy.getter(self, key, self[KEY_ATTRIBUTE_PROXIES_STORAGE])
    end
    return lstg.GetAttr(self, key)
end

---@param key string
---@param value any
function M:___metatableNewIndex(key, value)
    local proxy = self[KEY_ATTRIBUTE_PROXIES_LIST][key]
    if proxy then
        proxy.setter(self, key, value, self[KEY_ATTRIBUTE_PROXIES_STORAGE])
        return
    end
    lstg.SetAttr(self, key, value)
end

---@param proxies table<any, foundation.AttributeProxy.Proxy>
function M:applyProxies(proxies)
    local current_proxies = self[KEY_ATTRIBUTE_PROXIES_LIST]
    if not current_proxies then
        current_proxies = {}
        rawset(self, KEY_ATTRIBUTE_PROXIES_LIST, current_proxies)
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