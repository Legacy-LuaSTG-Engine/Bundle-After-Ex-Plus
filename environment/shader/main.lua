lstg.FileManager.AddSearchPath("../../game/packages/thlib-scripts/")
lstg.FileManager.AddSearchPath("../../game/packages/thlib-resources/")

local window = {
    width = 640,
    height = 480,
}

function window:applyCameraSetting()
    lstg.SetViewport(0, self.width, 0, self.height)
    lstg.SetScissorRect(0, self.width, 0, self.height)
    lstg.SetOrtho(0, self.width, 0, self.height)
    lstg.SetFog()
    lstg.SetImageScale(1.0)
    lstg.SetZBufferEnable(0)
end

local post_effect = require("lib.posteffect")

function GameInit()
    lstg.ChangeVideoMode(window.width, window.height, true, false)
    lstg.CreateRenderTarget("canvas1")
    lstg.CreateRenderTarget("mask1")
end

function FrameFunc()
	return false
end

function RenderFunc()
    lstg.BeginScene()

    lstg.PushRenderTarget("canvas1")
    do
        window:applyCameraSetting()
        lstg.RenderClear(lstg.Color(255, 0, 0, 0))
    end
    lstg.PopRenderTarget() -- "canvas1"

    lstg.PushRenderTarget("mask1")
    do
        window:applyCameraSetting()
        lstg.RenderClear(lstg.Color(255, 0, 0, 0))
    end
    lstg.PopRenderTarget() -- "mask1"

    window:applyCameraSetting()
    post_effect.drawMaskEffect("canvas1", "mask1")

    lstg.EndScene()
end
