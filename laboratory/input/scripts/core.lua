local lstg = require("lstg")
local Keyboard = lstg.Input.Keyboard
local InputSystem = require("foundation.InputSystem")
local Viewport = require("laboratory.input.Viewport")

local action_set = InputSystem.addActionSet("menu")
action_set:addBooleanAction("left")
    :addKeyboardKeyBinding(Keyboard.Left)
    :addKeyboardKeyBinding(Keyboard.A)
action_set:addBooleanAction("right")
    :addKeyboardKeyBinding(Keyboard.Right)
    :addKeyboardKeyBinding(Keyboard.D)
action_set:addBooleanAction("up")
    :addKeyboardKeyBinding(Keyboard.Up)
    :addKeyboardKeyBinding(Keyboard.W)
action_set:addBooleanAction("down")
    :addKeyboardKeyBinding(Keyboard.Down)
    :addKeyboardKeyBinding(Keyboard.S)
action_set:addBooleanAction("slow")
    :addKeyboardKeyBinding(Keyboard.LeftShift)
    :addKeyboardKeyBinding(Keyboard.RightShift)
action_set:addBooleanAction("size-smaller")
    :addKeyboardKeyBinding(Keyboard.Minus)
action_set:addBooleanAction("size-larger")
    :addKeyboardKeyBinding(Keyboard.Plus)

local x = 0
local y = 0
local size = 16
local white_initialized = false

function GameInit()
    Viewport.initialize()
    InputSystem.pushActionSet("menu")
    InputSystem.loadSetting()
    InputSystem.saveSetting()

    lstg.CreateRenderTarget("rt:white", 16, 16, false)
    lstg.LoadImage("white", "rt:white", 0, 0, 16, 16)
end

function GameExit()
end

function FrameFunc()
    InputSystem.update()
    local dx = 0
    if InputSystem.getBooleanAction("left") then
        dx = dx - 1
    elseif InputSystem.getBooleanAction("right") then
        dx = dx + 1
    end
    local dy = 0
    if InputSystem.getBooleanAction("down") then
        dy = dy - 1
    elseif InputSystem.getBooleanAction("up") then
        dy = dy + 1
    end
    local v = 1
    if dx ~= 0 and dy ~= 0 then
        v = 0.70710678118654752440084436210485
    end
    local speed = 10
    if InputSystem.getBooleanAction("slow") then
        speed = 5
    end
    x = x + v * speed * dx
    y = y + v * speed * dy
    if InputSystem.isBooleanActionActivated("size-smaller", 60, 60) then
        size = math.max(16, size - 16)
    end
    if InputSystem.isBooleanActionActivated("size-larger", 120, 60) then
        size = size + 16
    end
    return false
end

function RenderFunc()
    lstg.BeginScene()
    if not white_initialized then
        white_initialized = true
        lstg.PushRenderTarget("rt:white")
        lstg.RenderClear(lstg.Color(255, 255, 255, 255))
        lstg.PopRenderTarget()
    end
    Viewport.apply()
    lstg.Render("white", x, y, 0, size / 16)
    lstg.EndScene()
end
