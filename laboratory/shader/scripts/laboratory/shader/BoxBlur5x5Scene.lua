local lstg = require("lstg")
local post_effect = require("lib.posteffect")
local Viewport = require("laboratory.shader.Viewport")
local Resources = require("laboratory.shader.Resources")

---@class laboratory.shader.BoxBlur5x5Scene : laboratory.shader.Scene
local BoxBlur5x5Scene = {}

BoxBlur5x5Scene.name = "BoxBlur5x5Scene"

function BoxBlur5x5Scene:create()
    local old = lstg.GetResourceStatus()
    lstg.SetResourceStatus("stage")
    lstg.CreateRenderTarget("rt:mask1")
    Resources.loadSprite("mask1", "assets/texture/mask1.png")
    lstg.SetResourceStatus(old)
    self.timer = -1
end

function BoxBlur5x5Scene:destroy()
    lstg.RemoveResource("stage")
end

function BoxBlur5x5Scene:update()
    self.timer = self.timer + 1
end

function BoxBlur5x5Scene:draw()
    lstg.PushRenderTarget("rt:mask1")
    do
        Viewport.apply()
        lstg.RenderClear(lstg.Color(255, 0, 0, 0))
        lstg.Render("mask1", Viewport.width / 2, Viewport.height / 2)
    end
    lstg.PopRenderTarget() -- "rt:mask1"

    Viewport.apply()
    local radius = 0.5 + 0.5 * lstg.sin(self.timer * 3)
    post_effect.drawBoxBlur3x3("rt:mask1", "", radius * 2)
end

return BoxBlur5x5Scene
