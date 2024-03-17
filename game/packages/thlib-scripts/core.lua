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
lstg.DoFile("lib/Lobject.lua")--Luastg的Class、object
lstg.DoFile("lib/Lresources.lua")--资源的加载函数、资源枚举和判断
lstg.DoFile("lib/Lscreen.lua")--world、3d、viewmode的参数设置
lstg.DoFile("lib/Linput.lua")--按键状态更新
---@diagnostic disable-next-line: lowercase-global
task = require("lib.Ltaskmove")--task
lstg.DoFile("lib/Lstage.lua")--stage关卡系统
lstg.DoFile("lib/Ltext.lua")--文字渲染
require("foundation.legacy.scoredata")
lstg.DoFile("lib/Lplugin.lua")--用户插件
require("lib.debug.AllView")
require("foundation.MainLoop")

local SceneManager = require("foundation.SceneManager")

--------------------------------------------------------------------------------
--- 默认的主场景

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

---@class game.DefaultScene : foundation.Scene
local DefaultScene = SceneManager.add("DefaultScene")

DefaultScene.initialized = false

function DefaultScene:onCreate()
    if DefaultScene.initialized then
        return -- 只初始化一次
    end

    -- 加载mod包
    if setting.mod ~= 'launcher' then
        Include 'root.lua'
        lstg.plugin.DispatchEvent("afterMod")
    else
        Include 'launcher.lua'
    end
    -- 最后的准备
    lstg.RegisterAllGameObjectClass() -- 对所有class的回调函数进行整理，给底层调用
    InitScoreData() -- 装载玩家存档

    SetViewMode("world")
    --if stage.next_stage == nil then
    --    error('Entrance stage not set.')
    --end
    SetResourceStatus("stage")

    DefaultScene.initialized = true
end

function DefaultScene:onDestroy()
end

function DefaultScene:onUpdate()
    DoFrame()
end

function DefaultScene:onRender()
    BeforeRender()
    stage.current_stage:render()
    ObjRender()
    AfterRender()
end

SceneManager.setNext("DefaultScene")
