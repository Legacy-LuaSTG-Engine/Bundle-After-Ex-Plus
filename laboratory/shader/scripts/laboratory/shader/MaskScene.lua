local lstg = require("lstg")
local post_effect = require("lib.posteffect")
local Viewport = require("laboratory.shader.Viewport")
local Resources = require("laboratory.shader.Resources")

---@class laboratory.shader.MaskScene : laboratory.shader.Scene
local MaskScene = {}

MaskScene.name = "MaskScene"

function MaskScene:create()
    local old = lstg.GetResourceStatus()
    lstg.SetResourceStatus("stage")
    lstg.CreateRenderTarget("rt:canvas1")
    lstg.CreateRenderTarget("rt:mask1")
    Resources.loadSprite("canvas1", "canvas1.png")
    Resources.loadSprite("mask1", "mask1.png")
    lstg.SetResourceStatus(old)
    self.timer = -1
end

function MaskScene:destroy()
    lstg.RemoveResource("stage")
end

function MaskScene:update()
    self.timer = self.timer + 1
end

function MaskScene:draw()
    lstg.PushRenderTarget("rt:canvas1")
    do
        Viewport.apply()
        lstg.RenderClear(lstg.Color(255, 0, 0, 0))
        lstg.Render("canvas1", Viewport.width / 2, Viewport.height / 2)
    end
    lstg.PopRenderTarget() -- "rt:canvas1"

    lstg.PushRenderTarget("rt:mask1")
    do
        Viewport.apply()
        lstg.RenderClear(lstg.Color(255, 0, 0, 0))
        local dy = (0.5 * Viewport.height / 2) * lstg.sin(self.timer)
        lstg.Render("mask1", Viewport.width / 2, Viewport.height / 2 + dy)
    end
    lstg.PopRenderTarget() -- "rt:mask1"

    Viewport.apply()
    post_effect.drawMaskEffect("rt:canvas1", "rt:mask1")
end

return MaskScene
