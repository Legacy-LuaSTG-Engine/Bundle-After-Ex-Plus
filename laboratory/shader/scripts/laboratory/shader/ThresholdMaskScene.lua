local lstg = require("lstg")
local post_effect = require("lib.posteffect")
local Viewport = require("laboratory.shader.Viewport")
local Resources = require("laboratory.shader.Resources")

---@class laboratory.shader.ThresholdMaskScene : laboratory.shader.Scene
local ThresholdMaskScene = {}

ThresholdMaskScene.name = "ThresholdMaskScene"

function ThresholdMaskScene:create()
    local old = lstg.GetResourceStatus()
    lstg.SetResourceStatus("stage")
    lstg.CreateRenderTarget("rt:canvas1")
    lstg.CreateRenderTarget("rt:mask2")
    Resources.loadSprite("canvas1", "assets/texture/canvas1.png")
    Resources.loadSprite("mask2", "assets/texture/mask2.png")
    lstg.SetResourceStatus(old)
    self.timer = -1
end

function ThresholdMaskScene:destroy()
    lstg.RemoveResource("stage")
end

function ThresholdMaskScene:update()
    self.timer = self.timer + 1
end

function ThresholdMaskScene:draw()
    lstg.PushRenderTarget("rt:canvas1")
    do
        Viewport.apply()
        lstg.RenderClear(lstg.Color(255, 0, 0, 0))
        lstg.Render("canvas1", Viewport.width / 2, Viewport.height / 2)
    end
    lstg.PopRenderTarget() -- "rt:canvas1"

    lstg.PushRenderTarget("rt:mask2")
    do
        Viewport.apply()
        lstg.RenderClear(lstg.Color(255, 0, 0, 0))
        lstg.Render("mask2", Viewport.width / 2, Viewport.height / 2)
    end
    lstg.PopRenderTarget() -- "rt:mask2"

    Viewport.apply()
    local threshold = 0.5 + 0.5 * lstg.sin(self.timer)
    post_effect.drawThresholdMaskEffect("rt:canvas1", "rt:mask2", threshold)
end

return ThresholdMaskScene
