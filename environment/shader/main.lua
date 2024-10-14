lstg.FileManager.AddSearchPath("../../game/packages/thlib-scripts/")
lstg.FileManager.AddSearchPath("../../game/packages/thlib-resources/")

local post_effect = require("lib.posteffect")

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

local function loadSprite(name, path, mipmap)
    lstg.LoadTexture(name, path, mipmap)
    local width, height = lstg.GetTextureSize(name)
    lstg.LoadImage(name, name, 0, 0, width, height)
end

local timer = -1

function GameInit()
    lstg.ChangeVideoMode(window.width, window.height, true, false)
    lstg.CreateRenderTarget("rt:canvas1")
    lstg.CreateRenderTarget("rt:mask1")
    loadSprite("canvas1", "canvas1.png")
    loadSprite("mask1", "mask1.png")
end

function FrameFunc()
    timer = timer + 1
	return false
end

function RenderFunc()
    lstg.BeginScene()

    lstg.PushRenderTarget("rt:canvas1")
    do
        window:applyCameraSetting()
        lstg.RenderClear(lstg.Color(255, 0, 0, 0))
        lstg.Render("canvas1", window.width / 2, window.height / 2)
    end
    lstg.PopRenderTarget() -- "rt:canvas1"

    lstg.PushRenderTarget("rt:mask1")
    do
        window:applyCameraSetting()
        lstg.RenderClear(lstg.Color(255, 0, 0, 0))
        local dy = (0.5 * window.height / 2) * lstg.sin(timer)
        lstg.Render("mask1", window.width / 2, window.height / 2 + dy)
    end
    lstg.PopRenderTarget() -- "rt:mask1"

    window:applyCameraSetting()
    post_effect.drawMaskEffect("rt:canvas1", "rt:mask1")

    lstg.EndScene()
end
