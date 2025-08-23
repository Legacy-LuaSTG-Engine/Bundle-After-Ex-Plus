local debugger = require("lib.Ldebug")
local SceneManager = require("foundation.SceneManager")
local LocalFileStorage = require("foundation.LocalFileStorage")
require("foundation.legacy.input")

function GameInit()
end

function GameExit()
end

function FrameFunc()
    debugger.update()
    SceneManager.update()
    debugger.layout()
    return SceneManager.getExitSignal()
end

function RenderFunc()
    lstg.BeginScene()
    -- TODO: 应该改为引擎提供默认常用贴图
    if UpdateScreenResources then
        UpdateScreenResources()
    end
    SceneManager.render()
    debugger.draw()
    lstg.EndScene()
    -- 截图
    if MenuKeyIsPressed("snapshot") then
        LocalFileStorage.snapshot()
    end
end

function FocusLoseFunc()
    SceneManager.onDeactivated()
end

function FocusGainFunc()
    SceneManager.onActivated()
end
