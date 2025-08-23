--------------------------------------------------------------------------------
--- SPDX-License-Identifier: MIT
--- author: 璀境石
--- description: 原有的输入 API 的兼容性实现
--------------------------------------------------------------------------------

local lstg = require("lstg")
local Keyboard = lstg.Input.Keyboard
local InputSystem = require("foundation.InputSystem")

--------------------------------------------------------------------------------
--- 兼容性 API

function GetInput()
    InputSystem.update()
end

---@param key string
---@return boolean
function KeyIsDown(key)
    return InputSystem.getBooleanAction(key)
end

KeyPress = KeyIsDown

---@param key string
---@return boolean
function KeyIsPressed(key)
    return InputSystem.isBooleanActionActivated(key)
end

KeyTrigger = KeyIsPressed

---@param key string
---@return boolean
function MenuKeyIsDown(key)
    InputSystem.pushActionSet("menu") -- 确保使用的是菜单动作集
    local result = InputSystem.getBooleanAction(key)
    InputSystem.popActionSet()
    return result
end

---@param key string
---@return boolean
function MenuKeyIsPressed(key)
    InputSystem.pushActionSet("menu") -- 确保使用的是菜单动作集
    local result = InputSystem.isBooleanActionActivated(key)
    InputSystem.popActionSet()
    return result
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
