--------------------------------------------------------------------------------
--- SPDX-License-Identifier: MIT
--- author: 璀境石
--- description: 原有的输入 API 的兼容性实现
--------------------------------------------------------------------------------

local lstg = require("lstg")
local Keyboard = lstg.Input.Keyboard
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
menu_action_set:addBooleanAction("cancel")
    :addKeyboardKeyBinding(Keyboard.Escape)
    :addKeyboardKeyBinding(Keyboard.X)

-- 功能键（根据场景决定该按键功能）

menu_action_set:addBooleanAction("special")
    :addKeyboardKeyBinding(Keyboard.C)

-- 呼出菜单（一般用于游戏时打开暂停菜单）

menu_action_set:addBooleanAction("menu")
    :addKeyboardKeyBinding(Keyboard.Escape)

-- 加速、减速
-- 用户界面：加速或减速页面、滑块（Slider）移动等
-- 回放模式（Replay）：加速、减速回放

menu_action_set:addBooleanAction("slow-down")
    :addKeyboardKeyBinding(Keyboard.LeftShift)
    :addKeyboardKeyBinding(Keyboard.RightShift)
menu_action_set:addBooleanAction("speed-up")
    :addKeyboardKeyBinding(Keyboard.LeftControl)
    :addKeyboardKeyBinding(Keyboard.RightControl)

-- 重试/重置
-- 暂停菜单：快速重开关卡/符卡练习

menu_action_set:addBooleanAction("retry")
    :addKeyboardKeyBinding(Keyboard.R)

-- 截图

menu_action_set:addBooleanAction("snapshot")
    :addKeyboardKeyBinding(Keyboard.P)

--------------------------------------------------------------------------------
--- 兼容性 API

KEY = require("foundation.legacy.KEY")

local GAME_ACTION_SET_PREFIX = "game:"
local MENU_ACTION_SET_PREFIX = "menu:"

function GetInput()
    InputSystem.update()
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

--- 将按键二进制码转换为字面值，用于设置界面
function KeyCodeToName()
    local key2name = {}
    -- 按键code（参见launch和微软文档）作为索引，名称为值
    for k, v in pairs(Keyboard) do
        if type(v) == "number" then
            key2name[v] = k
        end
    end
    -- 没有名字的就给个默认名字
    for i = 0, 255 do
        key2name[i] = key2name[i] or ("Key%d"):format(i)
    end
    return key2name
end
