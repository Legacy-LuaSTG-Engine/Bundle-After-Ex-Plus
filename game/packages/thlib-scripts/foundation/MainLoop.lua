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
