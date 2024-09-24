local rawget = rawget
local rawset = rawset
local pairs = pairs
local setmetatable = setmetatable
local lstg = lstg

local KEY_ATTRIBUTE_PROXIES_LIST = "___attribute_proxies"
local KEY_ATTRIBUTE_PROXIES_STORAGE = "___attribute_proxies_storage"


---@class foundation.AttributeProxy
local M = {}

function M:getStorageValue(key)
    return rawget(self, KEY_ATTRIBUTE_PROXIES_STORAGE)[key]
end

function M:setStorageValue(key, value)
    rawget(self, KEY_ATTRIBUTE_PROXIES_STORAGE)[key] = value
end

function M:___basicGetter(key)
    return M.getStorageValue(self, key)
end

function M:___basicSetter(key, value)
    M.setStorageValue(self, key, value)
end

function M:___metatableIndex(key)
    local proxy = rawget(self, KEY_ATTRIBUTE_PROXIES_LIST)[key]
    if proxy then
        return proxy.getter(self, key)
    end
    return lstg.GetAttr(self, key)
end

function M:___metatableNewIndex(key, value)
    local proxy = rawget(self, KEY_ATTRIBUTE_PROXIES_LIST)[key]
    if proxy then
        proxy.setter(self, key, value)
        return
    end
    lstg.SetAttr(self, key, value)
end

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
        current_proxies[proxy.key] = proxy
        if proxy.init then
            proxy.init(self, proxy.key)
        end
    end
end

function M.createProxy(key, getter, setter, init)
    return {
        key = key,
        getter = getter or M.___basicGetter,
        setter = setter or M.___basicSetter,
        init = init,
    }
end

return M