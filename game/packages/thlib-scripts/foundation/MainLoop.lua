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
    -- TODO: 整理一下这里的代码
    -- 截图
    ---@diagnostic disable-next-line: deprecated
    if setting and setting.keysys and lstg.GetLastKey() == setting.keysys.snapshot then
        lstg.LocalUserData.Snapshot()
    end
end

function FocusLoseFunc()
    SceneManager.onDeactivated()
end

function FocusGainFunc()
    SceneManager.onActivated()
end
