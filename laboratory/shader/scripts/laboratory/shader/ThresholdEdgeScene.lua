local lstg = require("lstg")
local Keyboard = lstg.Input.Keyboard
local post_effect = require("lib.posteffect")
local Viewport = require("laboratory.shader.Viewport")
local Resources = require("laboratory.shader.Resources")

---@class laboratory.shader.ThresholdEdgeScene : laboratory.shader.Scene
local ThresholdEdgeScene = {}

ThresholdEdgeScene.name = "ThresholdEdgeScene"

function ThresholdEdgeScene:create()
    local old = lstg.GetResourceStatus()
    lstg.SetResourceStatus("stage")
    lstg.CreateRenderTarget("rt:canvas1")
    lstg.CreateRenderTarget("rt:mask3")
    Resources.loadSprite("canvas2", "canvas2.jpg")
    Resources.loadSprite("mask3", "mask3.png")
    lstg.SetResourceStatus(old)
    self.timer = -1
end

function ThresholdEdgeScene:destroy()
    lstg.RemoveResource("stage")
end

function ThresholdEdgeScene:update()
    if not Keyboard.GetKeyState(Keyboard.Space) then
        self.timer = self.timer + 1
    end
end

function ThresholdEdgeScene:draw()
    lstg.PushRenderTarget("rt:canvas1")
    do
        Viewport.apply()
        lstg.RenderClear(lstg.Color(255, 0, 0, 0))
        lstg.Render("canvas2", Viewport.width / 2, Viewport.height / 2)
    end
    lstg.PopRenderTarget() -- "rt:canvas1"

    lstg.PushRenderTarget("rt:mask3")
    do
        Viewport.apply()
        lstg.RenderClear(lstg.Color(255, 0, 0, 0))
        lstg.Render("mask3", Viewport.width / 2, Viewport.height / 2)
    end
    lstg.PopRenderTarget() -- "rt:mask3"

    Viewport.apply()
    lstg.RenderClear(lstg.Color(255, 16, 32, 64))
    local threshold = 0.5 + 0.5 * lstg.sin(self.timer)
    post_effect.drawThresholdMaskEffect("rt:canvas1", "rt:mask3", threshold)
    post_effect.drawThresholdEdgeEffect("rt:canvas1", "rt:mask3", "mul+add", threshold, 0.05, lstg.Color(255, 240, 100, 4), 0.05, lstg.Color(255, 250, 140, 1))
end

return ThresholdEdgeScene
