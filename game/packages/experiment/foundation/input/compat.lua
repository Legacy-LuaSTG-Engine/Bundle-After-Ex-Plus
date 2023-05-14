--------------------------------------------------------------------------------
--- SPDX-License-Identifier: MIT
--- description: 兼容性 API
--- version: 0.4.0
--- author: 璀境石
--- detail: 原有的输入 API 的兼容性实现
--------------------------------------------------------------------------------

local core = require("foundation.input.core")
local replay = require("foundation.input.replay")

--------------------------------------------------------------------------------
--- 兼容性 API

KeyStatePre = nil
KeyState = nil

function GetInput() end

---@param key string
---@return boolean
function KeyIsDown(key)
    return replay.getBooleanActionValue(key)
end

KeyPress = KeyIsDown

---@param key string
---@return boolean
function KeyIsPressed(key)
    return replay.isBooleanActionActivate(key)
end

KeyTrigger = KeyIsPressed

---@param key string
---@return boolean
function MenuKeyIsDown(key)
    return core.getBooleanActionValue(key)
end

---@param key string
---@return boolean
function MenuKeyIsPressed(key)
    return core.isBooleanActionActivate(key)
end
