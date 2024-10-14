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

local MaskScene = {}
function MaskScene:create()
    local old = lstg.GetResourceStatus()
    lstg.SetResourceStatus("stage")
    lstg.CreateRenderTarget("rt:canvas1")
    lstg.CreateRenderTarget("rt:mask1")
    loadSprite("canvas1", "canvas1.png")
    loadSprite("mask1", "mask1.png")
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
        window:applyCameraSetting()
        lstg.RenderClear(lstg.Color(255, 0, 0, 0))
        lstg.Render("canvas1", window.width / 2, window.height / 2)
    end
    lstg.PopRenderTarget() -- "rt:canvas1"

    lstg.PushRenderTarget("rt:mask1")
    do
        window:applyCameraSetting()
        lstg.RenderClear(lstg.Color(255, 0, 0, 0))
        local dy = (0.5 * window.height / 2) * lstg.sin(self.timer)
        lstg.Render("mask1", window.width / 2, window.height / 2 + dy)
    end
    lstg.PopRenderTarget() -- "rt:mask1"

    window:applyCameraSetting()
    post_effect.drawMaskEffect("rt:canvas1", "rt:mask1")
end

local ThresholdMaskScene = {}
function ThresholdMaskScene:create()
    local old = lstg.GetResourceStatus()
    lstg.SetResourceStatus("stage")
    lstg.CreateRenderTarget("rt:canvas1")
    lstg.CreateRenderTarget("rt:mask2")
    loadSprite("canvas1", "canvas1.png")
    loadSprite("mask2", "mask2.png")
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
        window:applyCameraSetting()
        lstg.RenderClear(lstg.Color(255, 0, 0, 0))
        lstg.Render("canvas1", window.width / 2, window.height / 2)
    end
    lstg.PopRenderTarget() -- "rt:canvas1"

    lstg.PushRenderTarget("rt:mask2")
    do
        window:applyCameraSetting()
        lstg.RenderClear(lstg.Color(255, 0, 0, 0))
        lstg.Render("mask2", window.width / 2, window.height / 2)
    end
    lstg.PopRenderTarget() -- "rt:mask2"

    window:applyCameraSetting()
    local threshold = 0.5 + 0.5 * lstg.sin(self.timer)
    post_effect.drawThresholdMaskEffect("rt:canvas1", "rt:mask2", threshold)
end

local scenes = { MaskScene, ThresholdMaskScene }
local current_scene_index = 2
local current_scene = scenes[current_scene_index]

function GameInit()
    lstg.ChangeVideoMode(window.width, window.height, true, false)
    current_scene:create()
end
function GameExit()
    current_scene:destroy()
end
function FrameFunc()
    current_scene:update()
	return false
end
function RenderFunc()
    lstg.BeginScene()
    current_scene:draw()
    lstg.EndScene()
end
