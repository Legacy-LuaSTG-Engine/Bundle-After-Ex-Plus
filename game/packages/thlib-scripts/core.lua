---=====================================
---core
---所有基础的东西都会在这里定义
---=====================================

----------------------------------------
---各个模块

require("gconfig") -- 全局配置信息
require("gconfig_auto") -- 全局配置信息（由打包器自动生成）

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
local createEventDispatcher = require("foundation.EventDispatcher")
eventListener = createEventDispatcher -- for compatibility

--------------------------------------------------------------------------------

---@alias lstg.GameStateEventGroup '"GameState.AfterGetInput"' | '"GameState.BeforeGameStageChange"' | '"GameState.AfterGameStageChange"' | '"GameState.BeforeGameStageUpdate"' | '"GameState.AfterGameStageUpdate"' | '"GameState.BeforeObjFrame"' | '"GameState.AfterObjFrame"' | '"GameState.BeforeBoundCheck"' | '"GameState.AfterBoundCheck"' | '"GameState.BeforeCollisionCheck"' | '"GameState.AfterCollisionCheck"' | '"GameState.BeforeRender"' | '"GameState.AfterRender"' | '"GameState.BeforeStageRender"' | '"GameState.AfterStageRender"' | '"GameState.BeforeObjRender"' | '"GameState.AfterObjRender"'

---@class lstg.GlobalEventDispatcher : foundation.EventDispatcher
---@field FindEvent fun(self: lstg.GlobalEventDispatcher, eventType: lstg.GameStateEventGroup, name: string): foundation.EventDispatcher.Event
---@field RegisterEvent fun(self: lstg.GlobalEventDispatcher, eventType: lstg.GameStateEventGroup, name: string, priority: number, callback: function): boolean
---@field UnregisterEvent fun(self: lstg.GlobalEventDispatcher, eventType: lstg.GameStateEventGroup, name: string)
---@field DispatchEvent fun(self: lstg.GlobalEventDispatcher, eventType: lstg.GameStateEventGroup, ...)
local gameEventDispatcher = createEventDispatcher()
lstg.globalEventDispatcher = gameEventDispatcher

--------------------------------------------------------------------------------

local SceneManager = require("foundation.SceneManager")

--------------------------------------------------------------------------------
--- 默认的主场景

--- 加载 THlib 后，会被重载以适应 replay 系统
--- 逻辑帧更新，不和 FrameFunc 一一对应
function DoFrame()
    -- 设置标题
    --lstg.SetTitle(string.format("%s | %.2f FPS | %d OBJ | %s", setting.mod, lstg.GetFPS(), lstg.GetnObj(), gconfig.window_title))
    lstg.SetTitle(string.format("%s", gconfig.window_title)) -- 启动器阶段不用显示那么多信息
    -- 上一帧的处理
    lstg.AfterFrame(2) -- TODO: remove (2)
    -- 获取输入
    GetInput()
    gameEventDispatcher:DispatchEvent("GameState.AfterGetInput")
    -- 切关处理
    if stage.NextStageExist() then
        gameEventDispatcher:DispatchEvent("GameState.BeforeGameStageChange")
        stage.Change()
        gameEventDispatcher:DispatchEvent("GameState.AfterGameStageChange")
    end
    -- 关卡更新
    gameEventDispatcher:DispatchEvent("GameState.BeforeGameStageUpdate")
    stage.Update()
    gameEventDispatcher:DispatchEvent("GameState.AfterGameStageUpdate")
    -- 游戏对象更新
    gameEventDispatcher:DispatchEvent("GameState.BeforeObjFrame")
    lstg.ObjFrame(2) -- TODO: remove (2)
    gameEventDispatcher:DispatchEvent("GameState.AfterObjFrame")
    -- 碰撞检测
    gameEventDispatcher:DispatchEvent("GameState.BeforeCollisionCheck")
    -- TODO: 等 API 文档更新后，去除下一行的禁用警告
    ---@diagnostic disable-next-line: param-type-mismatch, missing-parameter
    lstg.CollisionCheck({
        -- 基础
        { GROUP_PLAYER, GROUP_ENEMY_BULLET },
        { GROUP_PLAYER, GROUP_ENEMY },
        { GROUP_PLAYER, GROUP_INDES },
        { GROUP_ENEMY, GROUP_PLAYER_BULLET },
        { GROUP_NONTJT, GROUP_PLAYER_BULLET },
        { GROUP_ITEM, GROUP_PLAYER },
        -- 可用于自机 bomb (by OLC)
        { GROUP_SPELL, GROUP_ENEMY },
        { GROUP_SPELL, GROUP_NONTJT },
        { GROUP_SPELL, GROUP_ENEMY_BULLET },
        { GROUP_SPELL, GROUP_INDES },
        -- 用于检查与自机碰撞 (by OLC)
        { GROUP_CPLAYER, GROUP_PLAYER },
    });
    gameEventDispatcher:DispatchEvent("GameState.AfterCollisionCheck")
    -- 出界检测
    gameEventDispatcher:DispatchEvent("GameState.BeforeBoundCheck")
    lstg.BoundCheck(2) -- TODO: remove (2)
    gameEventDispatcher:DispatchEvent("GameState.AfterBoundCheck")
end

function BeforeRender()
    gameEventDispatcher:DispatchEvent("GameState.BeforeRender")
end

function AfterRender()
    gameEventDispatcher:DispatchEvent("GameState.AfterRender")
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
    gameEventDispatcher:DispatchEvent("GameState.BeforeStageRender")
    stage.current_stage:render()
    gameEventDispatcher:DispatchEvent("GameState.AfterStageRender")
    gameEventDispatcher:DispatchEvent("GameState.BeforeObjRender")
    ObjRender()
    gameEventDispatcher:DispatchEvent("GameState.AfterObjRender")
    AfterRender()
end

SceneManager.setNext("DefaultScene")
