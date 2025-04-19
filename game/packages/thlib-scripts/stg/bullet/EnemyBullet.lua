local lstg = require("lstg")
local BulletFadeOutEffect = require("stg.bullet.BulletFadeOutEffect")

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

---@class stg.bullet.StyleClass
---@field size number
local StyleClass = {}

---@param bullet stg.bullet.EnemyBullet
---@param color_variant stg.bullet.ColorVariant | integer
function StyleClass.init(bullet, color_variant)
end

---@class stg.bullet.EnemyBullet : lstg.GameObject
---@field fade_in_frames integer
---@field _blend lstg.BlendMode?
---@field _r number?
---@field _g number?
---@field _b number?
---@field _a number?
---@field index integer  FEATURE: color_variant / 2
---@field _index integer FEATURE: color_variant
local EnemyBullet = Class(object)

---@param style_class stg.bullet.StyleClass
---@param color_variant stg.bullet.ColorVariant | integer
---@param stay_on_fade_in boolean?
---@param destructible boolean?
function EnemyBullet:init(style_class, color_variant, stay_on_fade_in, destructible)
    color_variant = math.floor(clamp(color_variant, 1, 16))

    self.logclass = EnemyBullet
    self.imgclass = style_class

    if destructible then
        self.group = GROUP_ENEMY_BULLET
    else
        self.group = GROUP_INDES
    end

    self.stay = stay_on_fade_in
    self.fade_in_frames = 11

    self._index = color_variant
    self.index = math.floor((color_variant + 1) / 2)

    --self.layer = LAYER_ENEMY_BULLET_EF - imgclass.size * 0.001 + index * 0.00001
    self.layer = LAYER_ENEMY_BULLET - style_class.size * 0.001 + self._index * 0.00001

    style_class.init(self, color_variant)
end

function EnemyBullet:del()
    local w = lstg.world
    if lstg.BoxCheck(self, w.boundl, w.boundr, w.boundb, w.boundt) then
        BulletFadeOutEffect.create(self)
    end
end

function EnemyBullet:kill()
    local w = lstg.world
    if lstg.BoxCheck(self, w.boundl, w.boundr, w.boundb, w.boundt) then
        BulletFadeOutEffect.create(self)
    end
    lstg.New(item_faith_minor, self.x, self.y)
end

function EnemyBullet:frame()
    task.Do(self)
end

function EnemyBullet:render()
    local s = self._blend ~= nil and self._a ~= nil and self._r ~= nil and self._g ~= nil and self._b ~= nil
    if self.timer < self.fade_in_frames then
        local t = clamp(self.timer / self.fade_in_frames, 0.0, 1.0)
        local hscale = self.hscale
        local vscale = self.vscale
        self.hscale = lerp(hscale * 2.0, hscale, t)
        self.vscale = lerp(vscale * 2.0, vscale, t)
        if s then
            lstg.SetImgState(self, self._blend, lerp(0, self._a, t), self._r, self._g, self._b)
        else
            lstg.SetImgState(self, "", lerp(0, 255, t), 255, 255, 255)
        end
        lstg.DefaultRenderFunc(self)
        lstg.SetImgState(self, "", 255, 255, 255, 255)
        self.hscale = hscale
        self.vscale = vscale
    else
        if s then
            lstg.SetImgState(self, self._blend, self._a, self._r, self._g, self._b)
        end
        lstg.DefaultRenderFunc(self)
        if s then
            lstg.SetImgState(self, "", 255, 255, 255, 255)
        end
    end
end

function EnemyBullet:skipFadeIn()
    --self.class = self.logclass
    --self.layer = LAYER_ENEMY_BULLET - self.imgclass.size * 0.001 + self._index * 0.00001
    self.timer = self.fade_in_frames
end

EnemyBullet.skip_fade_in = EnemyBullet.skipFadeIn

---@alias stg.bullet.ColorVariant
---| `COLOR_DEEP_RED`
---| `COLOR_RED`
---| `COLOR_DEEP_PURPLE`
---| `COLOR_PURPLE`
---| `COLOR_DEEP_BLUE`
---| `COLOR_BLUE`
---| `COLOR_ROYAL_BLUE`
---| `COLOR_CYAN`
---| `COLOR_DEEP_GREEN`
---| `COLOR_GREEN`
---| `COLOR_CHARTREUSE`
---| `COLOR_YELLOW`
---| `COLOR_GOLDEN_YELLOW`
---| `COLOR_ORANGE`
---| `COLOR_DEEP_GRAY`
---| `COLOR_GRAY`

---@param style_class stg.bullet.StyleClass
---@param color_variant stg.bullet.ColorVariant | integer
---@param stay_on_fade_in boolean?
---@param destructible boolean?
---@return stg.bullet.EnemyBullet
function EnemyBullet.create(style_class, color_variant, stay_on_fade_in, destructible)
    ---@type stg.bullet.EnemyBullet
    ---@diagnostic disable-next-line: param-type-mismatch, assign-type-mismatch
    local e = lstg.New(EnemyBullet, style_class, color_variant, stay_on_fade_in, destructible)
    return e
end

return EnemyBullet
