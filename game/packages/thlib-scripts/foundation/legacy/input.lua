--------------------------------------------------------------------------------
--- SPDX-License-Identifier: MIT
--- author: 璀境石
--- description: 原有的输入 API 的兼容性实现
--------------------------------------------------------------------------------

local lstg = require("lstg")
local Keyboard = lstg.Input.Keyboard
local Mouse = lstg.Input.Mouse
local InputSystem = require("foundation.InputSystem")

--------------------------------------------------------------------------------
--- 菜单动作集

local menu_action_set = InputSystem.addActionSet("menu")

-- 方向导航

menu_action_set:addBooleanAction("left")
    :addKeyboardKeyBinding(Keyboard.Left)
menu_action_set:addBooleanAction("right")
    :addKeyboardKeyBinding(Keyboard.Right)
menu_action_set:addBooleanAction("down")
    :addKeyboardKeyBinding(Keyboard.Down)
menu_action_set:addBooleanAction("up")
    :addKeyboardKeyBinding(Keyboard.Up)

-- 确认/进入、取消/返回

menu_action_set:addBooleanAction("confirm")
    :addKeyboardKeyBinding(Keyboard.Enter)
    :addKeyboardKeyBinding(Keyboard.Z)
    :addMouseKeyBinding(Mouse.Left)
menu_action_set:addBooleanAction("cancel")
    :addKeyboardKeyBinding(Keyboard.Escape)
    :addKeyboardKeyBinding(Keyboard.X)
    :addMouseKeyBinding(Mouse.Right)

-- 功能键（根据场景决定该按键功能）

menu_action_set:addBooleanAction("special")
    :addKeyboardKeyBinding(Keyboard.C)

-- 打开菜单
-- 游戏时/回放时：打开暂停菜单

local menu_action_menu = menu_action_set:addBooleanAction("menu")
    :addKeyboardKeyBinding(Keyboard.Escape)

-- 加速、减速
-- 用户界面：加速或减速页面、滑块（Slider）移动等
-- 回放模式（Replay）：加速、减速回放

local menu_action_slow_down = menu_action_set:addBooleanAction("slow-down")
    :addKeyboardKeyBinding(Keyboard.LeftShift)
    :addKeyboardKeyBinding(Keyboard.RightShift)
local menu_action_speed_up = menu_action_set:addBooleanAction("speed-up")
    :addKeyboardKeyBinding(Keyboard.LeftControl)
    :addKeyboardKeyBinding(Keyboard.RightControl)

-- 重试/重置
-- 暂停菜单：快速重开关卡/符卡练习

local menu_action_retry = menu_action_set:addBooleanAction("retry")
    :addKeyboardKeyBinding(Keyboard.R)

-- 截图

local menu_action_snapshot = menu_action_set:addBooleanAction("snapshot")
    :addKeyboardKeyBinding(Keyboard.P)

-- 指针

local menu_action_pointer = menu_action_set:addVector2Action("pointer", true)
    :addInputSource("thlib-ui-pointer")

--------------------------------------------------------------------------------
--- 游戏动作集（玩家动作集）

local game_action_set = InputSystem.addActionSet("game")

-- 玩家移动

local game_action_left = game_action_set:addBooleanAction("left")
    :addKeyboardKeyBinding(Keyboard.Left)
local game_action_right = game_action_set:addBooleanAction("right")
    :addKeyboardKeyBinding(Keyboard.Right)
local game_action_down = game_action_set:addBooleanAction("down")
    :addKeyboardKeyBinding(Keyboard.Down)
local game_action_up = game_action_set:addBooleanAction("up")
    :addKeyboardKeyBinding(Keyboard.Up)

-- 玩家移动（矢量）

local game_action_move = game_action_set:addVector2Action("move")
    :addKeyboardKeyBinding(Keyboard.Right, Keyboard.Left, Keyboard.Up, Keyboard.Down)

-- 功能键

local game_action_slow = game_action_set:addBooleanAction("slow") -- 用于切换射击模式、移动速度（一般为按下后降低移动速度）
    :addKeyboardKeyBinding(Keyboard.LeftShift)
local game_action_shoot = game_action_set:addBooleanAction("shoot") -- 一般用于射击
    :addKeyboardKeyBinding(Keyboard.Z)
local game_action_spell = game_action_set:addBooleanAction("spell") -- 一般用于释放符卡（雷/炸弹）
    :addKeyboardKeyBinding(Keyboard.X)
local game_action_special = game_action_set:addBooleanAction("special") -- 一般用于释放特殊技能
    :addKeyboardKeyBinding(Keyboard.C)
local game_action_skip = game_action_set:addBooleanAction("skip") -- 一般用于跳过对话
    :addKeyboardKeyBinding(Keyboard.LeftControl)

-- 指针

local game_action_pointer = game_action_set:addVector2Action("pointer", true)
    :addInputSource("thlib-world-pointer")

--------------------------------------------------------------------------------
--- 兼容性 API

KEY = require("foundation.legacy.KEY")

local GAME_ACTION_SET_PREFIX = "game:"
local MENU_ACTION_SET_PREFIX = "menu:"

local function fillLegacyKeySetting()
    -- keys

    local keys = {}

    for _, binding in game_action_left:keyboardBindings() do
        keys.left = binding.key
        break
    end
    for _, binding in game_action_right:keyboardBindings() do
        keys.right = binding.key
        break
    end
    for _, binding in game_action_down:keyboardBindings() do
        keys.down = binding.key
        break
    end
    for _, binding in game_action_up:keyboardBindings() do
        keys.up = binding.key
        break
    end

    for _, binding in game_action_slow:keyboardBindings() do
        keys.slow = binding.key
        break
    end
    for _, binding in game_action_shoot:keyboardBindings() do
        keys.shoot = binding.key
        break
    end
    for _, binding in game_action_spell:keyboardBindings() do
        keys.spell = binding.key
        break
    end
    for _, binding in game_action_special:keyboardBindings() do
        keys.special = binding.key
        break
    end

    for k, v in pairs(keys) do
        ---@diagnostic disable-next-line: deprecated
        setting.keys[k] = v
    end

    -- keysys

    local sys_keys = {}

    for _, binding in menu_action_menu:keyboardBindings() do
        sys_keys.menu = binding.key
        break
    end
    for _, binding in menu_action_slow_down:keyboardBindings() do
        sys_keys.repslow = binding.key
        break
    end
    for _, binding in menu_action_speed_up:keyboardBindings() do
        sys_keys.repfast = binding.key
        break
    end
    for _, binding in menu_action_retry:keyboardBindings() do
        sys_keys.retry = binding.key
        break
    end
    for _, binding in menu_action_snapshot:keyboardBindings() do
        sys_keys.snapshot = binding.key
        break
    end

    for k, v in pairs(sys_keys) do
        ---@diagnostic disable-next-line: deprecated
        setting.keysys[k] = v
    end
end

function GetInput()
    InputSystem.update()
    fillLegacyKeySetting()
end

---@param key string
---@return boolean
function KeyIsDown(key)
    return InputSystem.getBooleanAction(GAME_ACTION_SET_PREFIX .. key)
end

KeyPress = KeyIsDown

---@param key string
---@return boolean
function KeyIsPressed(key)
    return InputSystem.isBooleanActionActivated(GAME_ACTION_SET_PREFIX .. key)
end

KeyTrigger = KeyIsPressed

---@param key string
---@return string
local function transformLegacyMenuKey(key)
    if key == "shoot" then
        return "confirm"
    elseif key == "spell" then
        return "cancel"
    elseif key == "slow" then
        return "slow-down"
    else
        return key
    end
end

---@param key string
---@return boolean
function MenuKeyIsDown(key)
    key = transformLegacyMenuKey(key)
    return InputSystem.getBooleanAction(MENU_ACTION_SET_PREFIX .. key)
end

---@param key string
---@return boolean
function MenuKeyIsPressed(key)
    key = transformLegacyMenuKey(key)
    return InputSystem.isBooleanActionActivated(MENU_ACTION_SET_PREFIX .. key, 40, 4) -- TODO: 允许修改该默认设置
end

--------------------------------------------------------------------------------
--- 导出

---@class legacy.input
local M = {}

M.GAME_ACTION_SET_PREFIX = GAME_ACTION_SET_PREFIX
M.MENU_ACTION_SET_PREFIX = MENU_ACTION_SET_PREFIX

M.fillLegacyKeySetting = fillLegacyKeySetting
M.transformLegacyMenuKey = transformLegacyMenuKey

return M
