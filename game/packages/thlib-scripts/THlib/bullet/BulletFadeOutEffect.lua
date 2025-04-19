local lstg = require("lstg")

--- 这里的 clamp 和 lerp 都是最简单高效的实现，没有做边界条件处理

---@param v number
---@param a number
---@param b number
---@return number
local function clamp(v, a, b)
    if v < a then
        return a
    elseif v > b then
        return b
    else
        return v
    end
end

---@param a number
---@param b number
---@param k number
---@return number
local function lerp(a, b, k)
    return (1.0 - k) * a + k * b
end

---@class thlib.bullet.BulletFadeOutEffect : lstg.GameObject
---@field hscale0 number
---@field vscale0 number
---@field has_c_b boolean
---@field _blend lstg.BlendMode
---@field _r number
---@field _g number
---@field _b number
---@field _a number
local BulletFadeOutEffect = Class(object)

function BulletFadeOutEffect:frame()
    if self.timer >= 11 then
        lstg.Del(self)
    end
end

function BulletFadeOutEffect:render()
    local t = clamp(self.timer / 11, 0.0, 1.0)
    self.hscale = lerp(self.hscale0, 0, t)
    self.vscale = lerp(self.vscale0, 0, t)
    if self.has_c_b then
        local r = lerp(self._r, 0, t)
        local g = lerp(self._g, 0, t)
        local b = lerp(self._b, 0, t)
        local a = lerp(self._a, 0, t)
        lstg.SetImgState(self, self._blend, a, r, g, b)
    else
        local r = lerp(255, 0, t)
        local g = lerp(255, 0, t)
        local b = lerp(255, 0, t)
        local a = lerp(255, 0, t)
        lstg.SetImgState(self, "", a, r, g, b)
    end
    lstg.DefaultRenderFunc(self)
    lstg.SetImgState(self, "", 255, 255, 255, 255) -- restore
end

---@return thlib.bullet.BulletFadeOutEffect
function BulletFadeOutEffect.create(o)
    ---@type thlib.bullet.BulletFadeOutEffect
    ---@diagnostic disable-next-line: param-type-mismatch, assign-type-mismatch
    local e = lstg.New(BulletFadeOutEffect)

    e.img = o.img
    e.x = o.x
    e.y = o.y
    e.rot = o.rot
    e.hscale = o.hscale
    e.vscale = o.vscale
    e.layer = LAYER_ENEMY_BULLET - 50

    e._blend = o._blend
    e._r = o._r
    e._g = o._g
    e._b = o._b
    e._a = o._a
    if e._blend and e._r and e._g and e._b and e._a then
        e.has_c_b = true
    else
        e.has_c_b = false
    end

    e.hscale0 = o.hscale
    e.vscale0 = o.vscale
    return e
end

return BulletFadeOutEffect
