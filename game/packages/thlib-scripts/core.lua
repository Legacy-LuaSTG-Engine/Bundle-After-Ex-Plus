---=====================================
---core
---所有基础的东西都会在这里定义
---=====================================

---@class lstg @内建函数库
lstg = lstg or {}

----------------------------------------
---各个模块

lstg.DoFile("gconfig.lua")--全局配置信息
lstg.DoFile("lib/Llog.lua")--简单的log系统
lstg.DoFile("lib/Lglobal.lua")--用户全局变量
lstg.DoFile("lib/Lmath.lua")--数学常量、数学函数、随机数系统
lstg.DoFile("plus/plus.lua")--CHU神的plus库，replay系统、plusClass、NativeAPI
lstg.DoFile("ex/ex.lua")--ESC神的ex库
lstg.DoFile("lib/Lobject.lua")--Luastg的Class、object
lstg.DoFile("lib/Lresources.lua")--资源的加载函数、资源枚举和判断
lstg.DoFile("lib/Lscreen.lua")--world、3d、viewmode的参数设置
lstg.DoFile("lib/Linput.lua")--按键状态更新
lstg.DoFile("lib/Ltask.lua")--task
lstg.DoFile("lib/Lstage.lua")--stage关卡系统
lstg.DoFile("lib/Ltext.lua")--文字渲染
lstg.DoFile("lib/Lscoredata.lua")--玩家存档
lstg.DoFile("lib/Lplugin.lua")--用户插件

require("lib.debug.AllView")

----------------------------------------
---用户定义的一些函数

--- 加载 THlib 后，会被重载以适应 replay 系统
--- 逻辑帧更新，不和 FrameFunc 一一对应
function DoFrame()
    --设置标题
    --lstg.SetTitle(string.format("%s | %.2f FPS | %d OBJ | %s", setting.mod, lstg.GetFPS(), lstg.GetnObj(), gconfig.window_title))
    lstg.SetTitle(string.format("%s", gconfig.window_title)) -- 启动器阶段不用显示那么多信息
    --获取输入
    GetInput()
    --切关处理
    if stage.NextStageExist() then
        stage.Change()
    end
    stage.Update()
    --object frame function
    ObjFrame()
    --碰撞检测
    BoundCheck()
    CollisionCheck(GROUP_PLAYER, GROUP_ENEMY_BULLET)
    CollisionCheck(GROUP_PLAYER, GROUP_ENEMY)
    CollisionCheck(GROUP_PLAYER, GROUP_INDES)
    CollisionCheck(GROUP_ENEMY, GROUP_PLAYER_BULLET)
    CollisionCheck(GROUP_NONTJT, GROUP_PLAYER_BULLET)
    CollisionCheck(GROUP_ITEM, GROUP_PLAYER)
    --后更新
    UpdateXY()
    AfterFrame()
end

function BeforeRender()
end

function AfterRender()
end

function GameExit()
end

----------------------------------------
---全局回调函数，底层调用

local Ldebug = require("lib.Ldebug")

function GameInit()
    --加载mod包
    if setting.mod ~= 'launcher' then
        Include 'root.lua'
        lstg.plugin.DispatchEvent("afterMod")
        -- TODO: 这玩意还有什么用吗？？？
        _mod_version = _mod_version or 0
        if _mod_version > _luastg_version or _mod_version < _luastg_min_support then
            error(string.format(
                    "Mod version and engine version mismatch. Mod version is %.2f, LuaSTG version is %.2f.",
                    _mod_version / 100,
                    _luastg_version / 100
            ))
        end
    else
        Include 'launcher.lua'
    end
    --最后的准备
    lstg.RegisterAllGameObjectClass() -- 对所有class的回调函数进行整理，给底层调用
    InitScoreData()--装载玩家存档

    SetViewMode("world")
    if stage.next_stage == nil then
        error('Entrance stage not set.')
    end
    SetResourceStatus("stage")
end

function FrameFunc()
    Ldebug.update()
    DoFrame(true, true)
    Ldebug.layout()
    return stage.QuitFlagExist()
end

function RenderFunc()
    if stage.current_stage.timer >= 0 and stage.next_stage == nil then
        BeginScene()
        UpdateScreenResources()
        BeforeRender()
        stage.current_stage:render()
        ObjRender()
        AfterRender()
        Ldebug.draw()
        EndScene()
    end
end

function FocusLoseFunc()
end

function FocusGainFunc()
end
