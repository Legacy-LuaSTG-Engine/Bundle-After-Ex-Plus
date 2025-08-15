local lstg = require("lstg")
local Viewport = require("laboratory.shader.Viewport")

---@class laboratory.shader.HelloScene : laboratory.shader.Scene
local HelloScene = {}

HelloScene.name = "HelloScene"

function HelloScene:create()
    local last_type = lstg.GetResourceStatus()
    lstg.SetResourceStatus("stage")
    lstg.CreateRenderTarget("rt:1")
    lstg.SetResourceStatus(last_type)
    self.shader = lstg.CreatePostEffectShader("assets/shader/hello.hlsl")
    self.timer = -1
end

function HelloScene:destroy()
    lstg.RemoveResource("stage")
    self.shader = nil
end

function HelloScene:update()
    self.timer = self.timer + 1
end

function HelloScene:draw()
    lstg.PushRenderTarget("rt:1")
    lstg.RenderClear(lstg.Color(0, 0, 0, 0))
    lstg.PopRenderTarget() -- "rt:1"
    Viewport.apply()
    self.shader:setFloat4("background_color", 0.1, 0.2, 0.4, 1.0)
    self.shader:setTexture("render_target", "rt:1")
    lstg.PostEffect(self.shader, "one")
end

return HelloScene
