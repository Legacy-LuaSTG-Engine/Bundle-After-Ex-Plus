local debugger = require("lib.Ldebug")
local SceneManager = require("foundation.SceneManager")

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
end

function FocusLoseFunc()
    SceneManager.onDeactivated()
end

function FocusGainFunc()
    SceneManager.onActivated()
end
