local lstg = require("lstg")
local Mouse = lstg.Input.Mouse
local post_effect = require("lib.posteffect")
local Viewport = require("laboratory.shader.Viewport")
local Resources = require("laboratory.shader.Resources")

---@class laboratory.shader.HSLShift : laboratory.shader.Scene
local HSLShift = {}

HSLShift.name = "HSLShift"

function HSLShift:create()
    local old = lstg.GetResourceStatus()
    lstg.SetResourceStatus("stage")
    lstg.CreateRenderTarget("rt:canvas1")
    Resources.loadSprite("canvas2", "assets/texture/canvas2.jpg")
    lstg.SetResourceStatus(old)
    self.timer = -1
    self.pointer_x = 0
    self.pointer_y = 0
    self.hue = 0
end

function HSLShift:destroy()
    lstg.RemoveResource("stage")
end

function HSLShift:update()
    self.timer = self.timer + 1
    self.pointer_x, self.pointer_y = Mouse.GetPosition()
    self.hue = self.hue + Mouse.GetWheelDelta()
end

function HSLShift:draw()
    lstg.PushRenderTarget("rt:canvas1")
    do
        Viewport.apply()
        lstg.RenderClear(lstg.Color(255, 0, 0, 0))
        lstg.Render("canvas2", Viewport.width / 2, Viewport.height / 2)
    end
    lstg.PopRenderTarget() -- "rt:canvas1"

    Viewport.apply()
    local w2 = Viewport.width / 2
    local h2 = Viewport.height / 2
    local ds = (self.pointer_x - w2) / w2
    local dl = (self.pointer_y - h2) / h2
    post_effect.drawHSLShiftEffect("rt:canvas1", self.hue, ds, dl)

    local edge = 4
    lstg.RenderTTF("Sans", string.format("H SHIFT: %d\nS SHIFT: %.2f\nL SHIFT: %.2f", self.hue, ds, dl), edge, Viewport.width - edge, edge, Viewport.height - edge, 0 + 0, lstg.Color(255, 255, 255, 64), 2)
end

return HSLShift
