---=====================================
---core
---所有基础的东西都会在这里定义
---=====================================

----------------------------------------
---各个模块

require("gconfig") -- 全局配置信息
require("gconfig_auto") -- 全局配置信息（由打包器自动生成）

lstg.DoFile("lib/Lapi.lua")--将 lstg 库的方法导入到全局（很神秘的设计）
lstg.DoFile("lib/Lkeycode.lua")-- 按键常量
require("foundation.legacy.userdata")
require("foundation.legacy.setting")
require("foundation.legacy.scoredata")
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
lstg.DoFile("lib/Lplugin.lua")--用户插件
require("lib.debug.AllView")
require("foundation.MainLoop")
local createEventDispatcher = require("foundation.EventDispatcher")
eventListener = createEventDispatcher -- for compatibility

--------------------------------------------------------------------------------

---@alias lstg.GameStateEventGroup
---| '"GameState.AfterDoFrame"'
---| '"GameState.BeforeDoFrame"'
---| '"GameState.AfterGetInput"'
---| '"GameState.BeforeGameStageChange"'
---| '"GameState.AfterGameStageChange"'
---| '"GameState.BeforeGameStageUpdate"'
---| '"GameState.AfterGameStageUpdate"'
---| '"GameState.BeforeObjFrame"'
---| '"GameState.AfterObjFrame"'
---| '"GameState.BeforeBoundCheck"'
---| '"GameState.AfterBoundCheck"'
---| '"GameState.BeforeCollisionCheck"'
---| '"GameState.AfterCollisionCheck"'
---| '"GameState.BeforeRender"'
---| '"GameState.AfterRender"'
---| '"GameState.BeforeStageRender"'
---| '"GameState.AfterStageRender"'
---| '"GameState.BeforeObjRender"'
---| '"GameState.AfterObjRender"'
---| '"GameState.AfterColliderRender"'

---@class lstg.GlobalEventDispatcher : foundation.EventDispatcher
---@field FindEvent fun(self: lstg.GlobalEventDispatcher, eventType: lstg.GameStateEventGroup, name: string): foundation.EventDispatcher.Event
---@field RegisterEvent fun(self: lstg.GlobalEventDispatcher, eventType: lstg.GameStateEventGroup, name: string, priority: number, callback: function): boolean
---@field UnregisterEvent fun(self: lstg.GlobalEventDispatcher, eventType: lstg.GameStateEventGroup, name: string)
---@field DispatchEvent fun(self: lstg.GlobalEventDispatcher, eventType: lstg.GameStateEventGroup, ...)
local gameEventDispatcher = createEventDispatcher()
lstg.globalEventDispatcher = gameEventDispatcher

--------------------------------------------------------------------------------

local SceneManager = require("foundation.SceneManager")
local IntersectionDetectionManager = require("foundation.IntersectionDetectionManager")

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
    IntersectionDetectionManager.execute()
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

local function initializeMod()
    -- 获取编辑器提供的参数，覆盖部分设置
    -- 警告：该功能可能会被恶意利用，请考虑在正式项目发行版中移除

    ---@param name string
    ---@param str string
    ---@param env table
    ---@return fun()
    local function load_as_sandbox(name, str, env)
        local available = true
        local function read_callback()
            if available then
                available = false
                return str
            else
                return nil
            end
        end
        local chunk, message = load(read_callback, name)
        if chunk then
            setfenv(chunk, env)
            return chunk
        else
            print(tostring(message))
            return function() end
        end
    end

    --- 从命令行选项中找看起来像编辑器参数的
    ---@return string|nil
    local function find_editor_setting()
        for _, v in ipairs(lstg.args) do
            if string.find(v, "setting.mod") then -- 编辑器参数特征，包含 setting.mod
                return v
            end
        end
        return nil
    end

    local editor_setting_text = find_editor_setting()
    local editor_setting = {}
    if editor_setting_text then
        local sandbox_environment = { setting = editor_setting }
        load_as_sandbox("editor_setting", editor_setting_text, sandbox_environment)()
        -- 受信任的全局变量
        if sandbox_environment.start_game then
            start_game = true
        end
        if sandbox_environment.is_debug then
            is_debug = true
        end
        if sandbox_environment.cheat then
            cheat = true
        end
    end

    for k, v in pairs(editor_setting) do
        setting[k] = v
    end

    setting.last_mod = setting.mod
    if not start_game then
        setting.mod = "launcher"
        --setting.resx = 480
        --setting.resy = 640
        --setting.windowed = true
    end

    -- 按需加载启动器包

    lstg.FileManager.CreateDirectory("mod")
    if setting.mod ~= 'launcher' then
        local zip_path = string.format("mod/%s.zip", setting.mod) -- 压缩包文件
        local dir_path = string.format("mod/%s/", setting.mod) -- 文件夹模式的搜索路径
        local dir_root_script = string.format("mod/%s/root.lua", setting.mod) -- 文件夹模式下，这里应该有个 root.lua 脚本
        if lstg.FileManager.FileExist(zip_path) then
            lstg.LoadPack(zip_path) -- 有压缩包则加载压缩包
        elseif lstg.FileManager.FileExist(dir_root_script) then
            lstg.FileManager.AddSearchPath(dir_path) -- 没压缩包但是有文件夹和 root.lua 就添加搜索路径
        end
    else
        if not lstg.FileManager.FileExist('launcher.lua') then
            --尝试加载启动器包
            if lstg.FileManager.FileExist('mod/launcher.zip') then
                lstg.LoadPack('mod/launcher.zip')--正常加载启动器
            else
                --找不到启动器包，尝试使用data.zip里面的启动器
            end
        else
            --使用裸露的启动器脚本
        end
    end
end

---@class game.DefaultScene : foundation.Scene
local DefaultScene = SceneManager.add("DefaultScene")

DefaultScene.initialized = false

function DefaultScene:onCreate()
    if DefaultScene.initialized then
        return -- 只初始化一次
    end

    -- 加载mod包
    initializeMod()
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
