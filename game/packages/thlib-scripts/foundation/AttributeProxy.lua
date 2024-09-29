local rawget = rawget
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
    ---@overload fun(key: string)
    function Proxy:init(key, value)
    end

    ---@param key string
    ---@return any
    function Proxy:getter(self, key)
    end

    ---@param key string
    ---@param value any
    function Proxy:setter(self, key, value)
    end
end

---@class foundation.AttributeProxy
local M = {}

---@param key string
---@return any
function M:getStorageValue(key)
    return rawget(self, KEY_ATTRIBUTE_PROXIES_STORAGE)[key]
end

---@param key string
---@param value any
function M:setStorageValue(key, value)
    rawget(self, KEY_ATTRIBUTE_PROXIES_STORAGE)[key] = value
end

---@param key string
---@return any
function M:___basicGetter(key)
    return M.getStorageValue(self, key)
end

---@param key string
---@param value any
function M:___basicSetter(key, value)
    M.setStorageValue(self, key, value)
end

---@param key string
---@return any
function M:___metatableIndex(key)
    local proxy = rawget(self, KEY_ATTRIBUTE_PROXIES_LIST)[key]
    if proxy then
        return proxy.getter(self, key)
    end
    return lstg.GetAttr(self, key)
end

---@param key string
---@param value any
function M:___metatableNewIndex(key, value)
    local proxy = rawget(self, KEY_ATTRIBUTE_PROXIES_LIST)[key]
    if proxy then
        proxy.setter(self, key, value)
        return
    end
    lstg.SetAttr(self, key, value)
end

---@param proxies table<any, foundation.AttributeProxy.Proxy>
function M:applyProxies(proxies)
    local current_proxies = rawget(self, KEY_ATTRIBUTE_PROXIES_LIST)
    if not current_proxies then
        current_proxies = {}
        rawset(self, KEY_ATTRIBUTE_PROXIES_LIST, current_proxies)
        rawset(self, KEY_ATTRIBUTE_PROXIES_STORAGE, {})
        setmetatable(self, {
            __index = M.___metatableIndex,
            __newindex = M.___metatableNewIndex,
        })
    end
    for _, proxy in pairs(proxies) do
        local value = self[proxy.key]
        current_proxies[proxy.key] = proxy
        if value ~= nil then
            rawset(self, proxy.key, nil)
            if proxy.init then
                proxy.init(self, proxy.key, value)
            else
                self[proxy.key] = value
            end
        elseif proxy.init then
            proxy.init(self, proxy.key)
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
        getter = getter or M.___basicGetter,
        setter = setter or M.___basicSetter,
        init = init,
    }
end

return M