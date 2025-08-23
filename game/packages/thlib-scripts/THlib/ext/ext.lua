---=====================================
---stagegroup|replay|pausemenu system
---extra game loop
---=====================================

local SceneManager = require("foundation.SceneManager")
local IntersectionDetectionManager = require("foundation.IntersectionDetectionManager")
local InputSystem = require("foundation.InputSystem")
local gameEventDispatcher = lstg.globalEventDispatcher

-- input system
local input = require("foundation.input.core")
local input_rep = require("foundation.input.replay")

----------------------------------------
---ext加强库

---@class ext @额外游戏循环加强库
ext = {}

local extpath = "THlib/ext/"

DoFile(extpath .. "ext_pause_menu.lua")
 --暂停菜单和暂停菜单资源
DoFile(extpath .. "ext_replay.lua")
 --CHU爷爷的replay系统以及切关函数重载
DoFile(extpath .. "ext_stage_group.lua")
 --关卡组

ext.replayTicker = 0
 --控制录像播放速度时有用
ext.slowTicker = 0
 --控制时缓的变量
ext.time_slow_level = {1, 2, 3, 4}
 --60/30/20/15 4个程度
ext.pause_menu = ext.pausemenu()
 --实例化的暂停菜单对象，允许运行时动态更改样式

ext.debug_data = {
    --- 调试功能版本 1
    version = 1,
    --- 允许修改更新速率
    x_speed_update = false,
    --- 更新速率，若为 2 则代表每帧更新 2 次  
    --- 如果为负值，如 -2 则代表 (timer % 2) == 0 时更新一次  
    --- 如果值为 0 则停止更新，用于步进模式  
    x_speed_update_value = 0,
    --- 请求触发一次更新，仅当更新速率为 0 时才生效
    request_once_update = false,
    --- 更新计时器
    timer = -1,
    --- 第二代游戏循环
    game_loop_v2 = true,
}

--- [调试功能] 是否启用了更新速率调试
function ext.isUpdateSpeedModifierEnable()
    return (not stage.current_stage.is_menu) and ext.debug_data.x_speed_update
end

--- [调试功能] 根据自定义更新速率更新
function ext.updateWithSpeedModifier()
    local db = ext.debug_data
    db.timer = db.timer + 1
    if db.x_speed_update_value == 0 then
        if db.request_once_update then
            db.request_once_update = false
            DoFrame()
        end
    elseif db.x_speed_update_value > 0 then
        for _ = 1, ext.debug_data.x_speed_update_value do
            if not ext.pop_pause_menu then
                DoFrame()
            end
        end
    else -- if db.x_speed_update_value < 0 then
        if (db.timer % db.x_speed_update_value) == 0 then
            DoFrame()
        end
    end
end

---重置缓速计数器
function ext.ResetTicker()
    ext.replayTicker = 0
    ext.slowTicker = 0
end

---获取暂停菜单发送的命令
---@return string
function ext.GetPauseMenuOrder()
    return ext.pause_menu_order
end

---发送暂停菜单的命令，命令有以下类型：
---'Continue'
---'Return to Title'
---'Quit and Save Replay'
---'Give up and Retry'
---'Restart'
---'Replay Again'
---@param msg string
function ext.PushPauseMenuOrder(msg)
    ext.pause_menu_order = msg
end

--ext pausemenu
--把暂停菜单相关操作移到gameEventDispatcher里完成
--按键弹出菜单
gameEventDispatcher:RegisterEvent("GameState.BeforeDoFrame", "pop_pause_menu", 0, function ()
    if ext.pause_menu:IsKilled() and (MenuKeyIsPressed("menu") or ext.pop_pause_menu) and (not stage.current_stage.is_menu) then
        ext.pause_menu:FlyIn()
    end
end)
--暂停菜单更新
gameEventDispatcher:RegisterEvent("GameState.AfterDoFrame", "pause_menu_frame", 0, function ()
    ext.pause_menu:frame()
end)
-- 暂停菜单渲染
gameEventDispatcher:RegisterEvent("GameState.AfterRender", "pause_menu_render", 0, function ()
    ext.pause_menu:render()
end)

----------------------------------------
---extra collision check

do
    ---@param id string
    ---@param g1 number
    ---@param g2 number
    local function reg(id, g1, g2)
        IntersectionDetectionManager.registerGroupPair(id, g1, g2, "global")
    end
    -- 基础
    reg("thlib-default-basic:player~enemy-bullet", GROUP_PLAYER, GROUP_ENEMY_BULLET)
    reg("thlib-default-basic:player~enemy-bullet1", GROUP_PLAYER, GROUP_INDES)
    reg("thlib-default-basic:player~enemy", GROUP_PLAYER, GROUP_ENEMY)
    reg("thlib-default-basic:enemy~player-bullet", GROUP_ENEMY, GROUP_PLAYER_BULLET)
    reg("thlib-default-basic:enemy1~player-bullet", GROUP_NONTJT, GROUP_PLAYER_BULLET)
    reg("thlib-default-basic:item~player", GROUP_ITEM, GROUP_PLAYER)
    -- 可用于自机 bomb (by OLC)
    reg("thlib-default-player:spell~enemy", GROUP_SPELL, GROUP_ENEMY)
    reg("thlib-default-player:spell~enemy1", GROUP_SPELL, GROUP_NONTJT)
    reg("thlib-default-player:spell~enemy-bullet", GROUP_SPELL, GROUP_ENEMY_BULLET)
    reg("thlib-default-player:spell~enemy-bullet1", GROUP_SPELL, GROUP_INDES)
    -- 用于检查与自机碰撞 (by OLC)
    reg("thlib-default-area:area~player", GROUP_CPLAYER, GROUP_PLAYER)
end

----------------------------------------
---extra user function

function GameStateChange()
end

--- 设置标题
function ChangeGameTitle()
    local mod = setting.mod and #setting.mod > 0 and setting.mod
    local ext =
        table.concat(
        {
            string.format("FPS=%.1f", GetFPS()),
            "OBJ=" .. GetnObj(),
            gconfig.window_title
        },
        " | "
    )
    if mod then
        SetTitle(mod .. " | " .. ext)
    else
        SetTitle(ext)
    end
end

--- 切关处理
function ChangeGameStage()
    ResetWorld()
    ResetWorldOffset() -- by ETC，重置world偏移
    lstg.ResetLstgtmpvar() -- 重置lstg.tmpvar
    ex.Reset() -- 重置ex全局变量
    IntersectionDetectionManager.unregisterAllGroupPairByScope("stage") -- 移除关卡范围的碰撞组对
    IntersectionDetectionManager.unregisterAllGroupByScope("stage") -- 移除关卡范围的碰撞组

    if lstg.nextvar then
        lstg.var = lstg.nextvar
        lstg.nextvar = nil
    end

    -- 初始化随机数
    if lstg.var.ran_seed then
        --Print('RanSeed',lstg.var.ran_seed)
        ran:Seed(lstg.var.ran_seed)
    end

    --刷新最高分
    if not stage.next_stage.is_menu then
        if scoredata.hiscore == nil then
            scoredata.hiscore = {}
        end
        local str
        if stage.next_stage.sc_pr_stage then
            local sc_index
            if lstg.var.sc_pr then
                sc_index = lstg.var.sc_pr.index
            else
                sc_index = lstg.var.sc_index
            end
            str = "SpellCard Practice" .. '@' .. tostring(sc_index) .. '@' .. tostring(lstg.var.player_name)
        elseif lstg.var.is_practice then
            str = stage.next_stage.name .. '@' .. tostring(lstg.var.player_name)
        else
            str = stage.next_stage.group.name .. '@' .. tostring(lstg.var.player_name)
        end
        lstg.tmpvar.hiscore = scoredata.hiscore[str]
        --SaveScoreData() -- 下面固定调用，所以这里可以不重复调用
    end

    --进行一次定期存档
    SaveScoreData()
end

--- 获取输入
local framedata = {}
function GetInput()
    if stage.NextStageExist() then
        input.clear()
        input_rep.clear()
        InputSystem.clear() -- 清除输入系统内部状态，避免切换关卡后残留上一帧的输入状态
    end
    input.update()
    InputSystem.update()

    if ext.pause_menu:IsKilled() then
        -- 不是录像且非暂停时更新按键状态
        if not ext.replay.IsReplay() then
            input_rep.update()
        end
        if ext.replay.IsRecording() then
            -- 录像模式下记录当前帧的按键
            replayWriter:Record(input_rep.encodeToString())
        elseif ext.replay.IsReplay() then
            -- 回放时载入按键状态
            framedata = {}
            if not replayReader:Next(framedata) then
                ext.PushPauseMenuOrder("Replay Again")
                ext.pause_menu:FlyIn()
            else
                input_rep.decodeFromString(framedata.keystate)
            end
        end
    end
end

gameEventDispatcher:RegisterEvent("GameState.AfterObjRender", "render_replay_fps", 0, function ()
    if ext.replay.IsReplay() then
        if framedata.extra and framedata.extra.fps then
            SetViewMode("ui")
            RenderTTF2("menuttf", string.format("Original FPS %0.1f", framedata.extra.fps), screen.width - 10, screen.width - 10, 30, 30, 1, Color(255, 255, 255, 255), "right", "vcenter")
            SetViewMode("world")
        end
    end
end)

--- 逻辑帧更新，不和 FrameFunc 一一对应
function DoFrame()
    -- 标题设置
    ChangeGameTitle()
    if ext.debug_data.game_loop_v2 then
        -- 上一帧的处理
        lstg.AfterFrame(2) -- TODO: remove (2)
        -- 获取输入
        GetInput()
        gameEventDispatcher:DispatchEvent("GameState.AfterGetInput")
        -- 切关处理
        if stage.NextStageExist() then
            gameEventDispatcher:DispatchEvent("GameState.BeforeGameStageChange")
            stage.DestroyCurrentStage()
            ChangeGameStage()
            stage.CreateNextStage()
            gameEventDispatcher:DispatchEvent("GameState.AfterGameStageChange")
        end
        -- 关卡更新
        gameEventDispatcher:DispatchEvent("GameState.BeforeGameStageUpdate")
        if GetCurrentSuperPause() <= 0 or stage.nopause then
            ex.Frame()
            stage.Update()
            gameEventDispatcher:DispatchEvent("GameState.AfterGameStageUpdate")
        end
        -- 游戏对象更新
        gameEventDispatcher:DispatchEvent("GameState.BeforeObjFrame")
        lstg.ObjFrame(2) -- TODO: remove (2)
        gameEventDispatcher:DispatchEvent("GameState.AfterObjFrame")
        -- 碰撞检测
        if GetCurrentSuperPause() <= 0 then
            gameEventDispatcher:DispatchEvent("GameState.BeforeCollisionCheck")
        end
        IntersectionDetectionManager.execute()
        if GetCurrentSuperPause() <= 0 then
            gameEventDispatcher:DispatchEvent("GameState.AfterCollisionCheck")
        end
        -- 出界检测
        if GetCurrentSuperPause() <= 0 or stage.nopause then
            gameEventDispatcher:DispatchEvent("GameState.BeforeBoundCheck")
            lstg.BoundCheck(2) -- TODO: remove (2)
            gameEventDispatcher:DispatchEvent("GameState.AfterBoundCheck")
        end
    else
        -- 获取输入
        GetInput()
        gameEventDispatcher:DispatchEvent("GameState.AfterGetInput")
        -- 切关处理
        if stage.NextStageExist() then
            gameEventDispatcher:DispatchEvent("GameState.BeforeGameStageChange")
            stage.DestroyCurrentStage()
            ChangeGameStage()
            stage.CreateNextStage()
            gameEventDispatcher:DispatchEvent("GameState.AfterGameStageChange")
        end
        -- 关卡更新
        gameEventDispatcher:DispatchEvent("GameState.BeforeGameStageUpdate")
        if GetCurrentSuperPause() <= 0 or stage.nopause then
            ex.Frame()
            stage.Update()
            gameEventDispatcher:DispatchEvent("GameState.AfterGameStageUpdate")
        end
        -- 游戏对象更新
        gameEventDispatcher:DispatchEvent("GameState.BeforeObjFrame")
        lstg.ObjFrame()
        gameEventDispatcher:DispatchEvent("GameState.AfterObjFrame")
        -- 出界检测
        if GetCurrentSuperPause() <= 0 or stage.nopause then
            gameEventDispatcher:DispatchEvent("GameState.BeforeBoundCheck")
            lstg.BoundCheck()
            gameEventDispatcher:DispatchEvent("GameState.AfterBoundCheck")
        end
        -- 碰撞检测
        if GetCurrentSuperPause() <= 0 then
            gameEventDispatcher:DispatchEvent("GameState.BeforeCollisionCheck")
        end
        IntersectionDetectionManager.execute() -- TODO: 并不完全和 V1 一致
        if GetCurrentSuperPause() <= 0 then
            gameEventDispatcher:DispatchEvent("GameState.AfterCollisionCheck")
        end
        -- 上一帧的处理
        lstg.UpdateXY()
        lstg.AfterFrame()
    end
end

--- 缓速和加速
function DoFrameEx()
    if ext.replay.IsReplay() then
        --播放录像时
        ext.replayTicker = ext.replayTicker + 1
        ext.slowTicker = ext.slowTicker + 1
        if MenuKeyIsDown("speed-up") then
            for _ = 1, 4 do
                DoFrame()
                ext.pause_menu_order = nil
            end
        elseif MenuKeyIsDown("slow-down") then
            if ext.replayTicker % 4 == 0 then
                DoFrame()
                ext.pause_menu_order = nil
            end
        else
            if lstg.var.timeslow and lstg.var.timeslow > 0 and lstg.var.timeslow ~= 1 then
                local tmp = min(4, max(1, lstg.var.timeslow))
                if ext.slowTicker % (ext.time_slow_level[tmp]) == 0 then
                    DoFrame()
                end
            else
                DoFrame()
            end
            ext.pause_menu_order = nil
        end
    else
        --正常游戏时
        ext.slowTicker = ext.slowTicker + 1
        if lstg.var.timeslow and lstg.var.timeslow > 0 and lstg.var.timeslow ~= 1 then
            local tmp = min(4, max(1, lstg.var.timeslow))
            if ext.slowTicker % (ext.time_slow_level[tmp]) == 0 then
                DoFrame()
            end
        elseif ext.isUpdateSpeedModifierEnable() then
            ext.updateWithSpeedModifier()
        else
            DoFrame()
        end
    end
end

function AfterRender()
    gameEventDispatcher:DispatchEvent("GameState.AfterRender")
end

----------------------------------------
---extra game call-back function

---@class game.GameScene : foundation.Scene
local GameScene = SceneManager.add("GameScene")

function GameScene:onCreate()
end

function GameScene:onDestroy()
end

function GameScene:onUpdate()
    gameEventDispatcher:DispatchEvent("GameState.BeforeDoFrame")
    --执行场景逻辑
    if ext.pause_menu:IsKilled() then
        --处理录像速度与正常更新逻辑
        DoFrameEx()
    else
        GetInput()
    end
    gameEventDispatcher:DispatchEvent("GameState.AfterDoFrame")
end

function GameScene:onRender()
    BeforeRender()
    gameEventDispatcher:DispatchEvent("GameState.BeforeStageRender")
    stage.current_stage:render()
    gameEventDispatcher:DispatchEvent("GameState.AfterStageRender")
    gameEventDispatcher:DispatchEvent("GameState.BeforeObjRender")
    ObjRender()
    gameEventDispatcher:DispatchEvent("GameState.AfterObjRender")
    SetViewMode("world")
    DrawCollider()
    gameEventDispatcher:DispatchEvent("GameState.AfterColliderRender")
    AfterRender()
end

function GameScene:onActivated()
end

function GameScene:onDeactivated()
    --[[
    if ext.pause_menu == nil and stage.current_stage then
        if not stage.current_stage.is_menu then
            ext.pop_pause_menu = true
        end
    end
    --]]
end

SceneManager.setNext("GameScene")
