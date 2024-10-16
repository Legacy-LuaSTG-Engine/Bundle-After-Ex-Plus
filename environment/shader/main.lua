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

local Keyboard = lstg.Input.Keyboard
local any_key_down = true

local MaskScene = {}
MaskScene.name = "MaskScene"
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
ThresholdMaskScene.name = "ThresholdMaskScene"
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

local ThresholdEdgeScene = {}
ThresholdEdgeScene.name = "ThresholdEdgeScene"
function ThresholdEdgeScene:create()
    local old = lstg.GetResourceStatus()
    lstg.SetResourceStatus("stage")
    lstg.CreateRenderTarget("rt:canvas1")
    lstg.CreateRenderTarget("rt:mask3")
    loadSprite("canvas2", "canvas2.jpg")
    loadSprite("mask3", "mask3.png")
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
        window:applyCameraSetting()
        lstg.RenderClear(lstg.Color(255, 0, 0, 0))
        lstg.Render("canvas2", window.width / 2, window.height / 2)
    end
    lstg.PopRenderTarget() -- "rt:canvas1"

    lstg.PushRenderTarget("rt:mask3")
    do
        window:applyCameraSetting()
        lstg.RenderClear(lstg.Color(255, 0, 0, 0))
        lstg.Render("mask3", window.width / 2, window.height / 2)
    end
    lstg.PopRenderTarget() -- "rt:mask3"

    window:applyCameraSetting()
    lstg.RenderClear(lstg.Color(255, 16, 32, 64))
    local threshold = 0.5 + 0.5 * lstg.sin(self.timer)
    post_effect.drawThresholdMaskEffect("rt:canvas1", "rt:mask3", threshold)
    post_effect.drawThresholdEdgeEffect("rt:canvas1", "rt:mask3", "mul+add", threshold, 0.05, lstg.Color(255, 240, 100, 4), 0.05, lstg.Color(255, 250, 140, 1))
end

local BoxBlur3x3Scene = {}
BoxBlur3x3Scene.name = "BoxBlur3x3Scene"
function BoxBlur3x3Scene:create()
    local old = lstg.GetResourceStatus()
    lstg.SetResourceStatus("stage")
    lstg.CreateRenderTarget("rt:mask1")
    loadSprite("mask1", "mask1.png")
    lstg.SetResourceStatus(old)
    self.timer = -1
end
function BoxBlur3x3Scene:destroy()
    lstg.RemoveResource("stage")
end
function BoxBlur3x3Scene:update()
    self.timer = self.timer + 1
end
function BoxBlur3x3Scene:draw()
    lstg.PushRenderTarget("rt:mask1")
    do
        window:applyCameraSetting()
        lstg.RenderClear(lstg.Color(255, 0, 0, 0))
        lstg.Render("mask1", window.width / 2, window.height / 2)
    end
    lstg.PopRenderTarget() -- "rt:mask1"

    window:applyCameraSetting()
    local radius = 0.5 + 0.5 * lstg.sin(self.timer * 3)
    post_effect.drawBoxBlur3x3("rt:mask1", "", radius * 2)
end

local BoxBlur5x5Scene = {}
BoxBlur5x5Scene.name = "BoxBlur5x5Scene"
function BoxBlur5x5Scene:create()
    local old = lstg.GetResourceStatus()
    lstg.SetResourceStatus("stage")
    lstg.CreateRenderTarget("rt:mask1")
    loadSprite("mask1", "mask1.png")
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
        window:applyCameraSetting()
        lstg.RenderClear(lstg.Color(255, 0, 0, 0))
        lstg.Render("mask1", window.width / 2, window.height / 2)
    end
    lstg.PopRenderTarget() -- "rt:mask1"

    window:applyCameraSetting()
    local radius = 0.5 + 0.5 * lstg.sin(self.timer * 3)
    post_effect.drawBoxBlur3x3("rt:mask1", "", radius * 2)
end

local BoxBlur7x7Scene = {}
BoxBlur7x7Scene.name = "BoxBlur7x7Scene"
function BoxBlur7x7Scene:create()
    local old = lstg.GetResourceStatus()
    lstg.SetResourceStatus("stage")
    lstg.CreateRenderTarget("rt:mask1")
    loadSprite("mask1", "mask1.png")
    lstg.SetResourceStatus(old)
    self.timer = -1
end
function BoxBlur7x7Scene:destroy()
    lstg.RemoveResource("stage")
end
function BoxBlur7x7Scene:update()
    self.timer = self.timer + 1
end
function BoxBlur7x7Scene:draw()
    lstg.PushRenderTarget("rt:mask1")
    do
        window:applyCameraSetting()
        lstg.RenderClear(lstg.Color(255, 0, 0, 0))
        lstg.Render("mask1", window.width / 2, window.height / 2)
    end
    lstg.PopRenderTarget() -- "rt:mask1"

    window:applyCameraSetting()
    local radius = 0.5 + 0.5 * lstg.sin(self.timer * 3)
    post_effect.drawBoxBlur3x3("rt:mask1", "", radius * 2)
end

---@generic T
---@param class T
---@return T
local function makeInstance(class)
    local instance = {}
    setmetatable(instance, { __index = class })
    return instance
end

local scenes = {
    MaskScene,
    ThresholdMaskScene,
    ThresholdEdgeScene,
    BoxBlur3x3Scene,
    BoxBlur5x5Scene,
    BoxBlur7x7Scene
}
local current_scene_index = 1
local current_scene = makeInstance(scenes[current_scene_index])

function GameInit()
    lstg.ChangeVideoMode(window.width, window.height, true, false)
    lstg.LoadTTF("Sans", "assets/font/SourceHanSansCN-Bold.otf", 0, 24)
    current_scene:create()
end
function GameExit()
    current_scene:destroy()
end
function FrameFunc()
    local change = 0
    if Keyboard.GetKeyState(Keyboard.Left) then
        if not any_key_down then
            any_key_down = true
            if current_scene_index > 1 then
                change = -1
            end
        end
    elseif Keyboard.GetKeyState(Keyboard.Right) then
        if not any_key_down then
            any_key_down = true
            if current_scene_index < #scenes then
                change = 1
            end
        end
    elseif any_key_down then
        any_key_down = false
    end
    if change ~= 0 then
        current_scene:destroy()
        current_scene = nil
        current_scene_index = current_scene_index + change
        current_scene = makeInstance(scenes[current_scene_index])
        current_scene:create()
    end
    current_scene:update()
	return false
end
function RenderFunc()
    lstg.BeginScene()
    current_scene:draw()
    window:applyCameraSetting()
    local edge = 4
    lstg.RenderTTF("Sans", string.format("%s\n< %d/%d >", current_scene.name, current_scene_index, #scenes), edge, window.width - edge, edge, window.height - edge, 1 + 8, lstg.Color(255, 255, 255, 64), 2)
    lstg.EndScene()
end
