--region Imports
local lstg = lstg
local AttributeProxy = require("foundation.AttributeProxy")
--endregion

--region Class Definition
---@class THlib.v2.bullet.laser.laserCollider : lstg.GameObject
local class = lstg.CreateGameObjectClass()

---@param master lstg.GameObject @Master object
---@param group number @Collider group
---@param args table<string, any> @Arguments
---@param on_del fun(master: lstg.GameObject, self: THlib.v2.bullet.laser.laserCollider, args: table<string, any>) @On Del callback
---@param on_kill fun(master: lstg.GameObject, self: THlib.v2.bullet.laser.laserCollider, args: table<string, any>) @On Kill callback
function class.create(master, group, args, on_del, on_kill)
    local self = lstg.New(class)
    self.group = group or GROUP_ENEMY_BULLET    -- Collider group
    self.layer = LAYER_ENEMY_BULLET             -- Collider layer
    self.rect = true                            -- Use rectangle collider
    self.hide = true                            -- Collider do not render
    ---@diagnostic disable
    self.master = master                        -- Master object
    self.args = args                            -- Arguments
    self.on_del = on_del                        -- On Del callback
    self.on_kill = on_kill                      -- On Kill callback
    ---@diagnostic enable
    AttributeProxy.applyProxies(self, class.___attribute_proxies)
    return self
end

function class:del()
    if self.on_del and lstg.IsValid(self.master) then
        self.on_del(self.master, self, self.args)
    end
end

function class:kill()
    if self.on_kill and lstg.IsValid(self.master) then
        self.on_kill(self.master, self, self.args)
    end
end

--endregion

--region Attribute Proxies
local attribute_proxies = {}
class.___attribute_proxies = attribute_proxies

--region ___killed
local proxy_killed = AttributeProxy.createProxy("___killed")
attribute_proxies["___killed"] = proxy_killed

function proxy_killed:setter(key, value, storage)
    local old_value = storage[key]
    if value == old_value then
        return
    end
    storage[key] = value
    if lstg.IsValid(self.master) then
        lstg.SetAttr(self, "colli", self.master.colli and not value)
    else
        lstg.SetAttr(self, "colli", false)
    end
end

--endregion

--region _graze
local proxy_graze = AttributeProxy.createProxy("_graze")
attribute_proxies["_graze"] = proxy_graze

function proxy_graze:getter(key, storage)
    if IsValid(self.master) then
        return self.master._graze
    end
end

function proxy_graze:setter(key, value, storage)
    if IsValid(self.master) then
        self.master._graze = value
    end
end

--endregion

--region colli
local proxy_colli = AttributeProxy.createProxy("colli")
attribute_proxies["colli"] = proxy_colli

function proxy_colli:getter(key, storage)
    if IsValid(self.master) then
        return self.master.colli and not self.___killed
    end
end

function proxy_colli:setter(key, value, storage)
    if IsValid(self.master) then
        lstg.SetAttr(self, "colli", self.master.colli and value and not self.___killed)
    else
        lstg.SetAttr(self, "colli", false)
    end
end

--endregion

--region bound
local proxy_bound = AttributeProxy.createProxy("bound")
attribute_proxies["bound"] = proxy_bound

function proxy_bound:init()
    lstg.SetAttr(self, "bound", false)
end

function proxy_bound:getter(key, storage)
    if IsValid(self.master) then
        return self.master.bound
    end
end

function proxy_bound:setter(key, value, storage)
    if IsValid(self.master) then
        self.master.bound = value
    else
        lstg.SetAttr(self, "bound", true)
    end
end

--endregion
--endregion

return class
