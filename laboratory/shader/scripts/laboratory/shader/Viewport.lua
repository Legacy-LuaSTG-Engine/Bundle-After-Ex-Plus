local lstg = require("lstg")

---@class laboratory.shader.Viewport
local Viewport = {}

Viewport.width = 640

Viewport.height = 480

function Viewport.initialize()
    lstg.ChangeVideoMode(Viewport.width, Viewport.height, true, false)
end

function Viewport.apply()
    lstg.SetViewport(0, Viewport.width, 0, Viewport.height)
    lstg.SetScissorRect(0, Viewport.width, 0, Viewport.height)
    lstg.SetOrtho(0, Viewport.width, 0, Viewport.height)
    lstg.SetFog()
    lstg.SetImageScale(1.0)
    lstg.SetZBufferEnable(0)
end

return Viewport
