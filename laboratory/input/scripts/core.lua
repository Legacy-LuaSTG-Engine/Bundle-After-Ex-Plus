local lstg = require("lstg")
local Keyboard = lstg.Input.Keyboard
local Mouse = lstg.Input.Mouse
local InputSystem = require("foundation.InputSystem")
local Viewport = require("laboratory.input.Viewport")

---@class laboratory.input.ViewportMouseInputSource : foundation.InputSystem.Vector2InputSource
local ViewportMouseInputSource = {}
function ViewportMouseInputSource:getType()
    return "vector2"
end
function ViewportMouseInputSource:getValue()
    return Mouse.GetPosition()
end
InputSystem.registerInputSource("viewport-mouse", ViewportMouseInputSource)

local action_set = InputSystem.addActionSet("player")
action_set:addBooleanAction("left")
    :addKeyboardKeyBinding(Keyboard.Left)
action_set:addBooleanAction("right")
    :addKeyboardKeyBinding(Keyboard.Right)
action_set:addBooleanAction("up")
    :addKeyboardKeyBinding(Keyboard.Up)
action_set:addBooleanAction("down")
    :addKeyboardKeyBinding(Keyboard.Down)
action_set:addBooleanAction("slow")
    :addKeyboardKeyBinding(Keyboard.LeftShift)
    :addKeyboardKeyBinding(Keyboard.RightShift)
action_set:addBooleanAction("size-smaller")
    :addKeyboardKeyBinding(Keyboard.Minus)
action_set:addBooleanAction("size-larger")
    :addKeyboardKeyBinding(Keyboard.Plus)
action_set:addVector2Action("fps-move")
    :addKeyboardKeyBinding(Keyboard.D, Keyboard.A, Keyboard.W, Keyboard.S)

local action_set_menu = InputSystem.addActionSet("menu")
action_set_menu:addBooleanAction("record")
    :addKeyboardKeyBinding(Keyboard.R)
action_set_menu:addVector2Action("pointer", true)
    :addInputSource("viewport-mouse")

local x = 0
local y = 0
local size = 16
local white_initialized = false

function GameInit()
    Viewport.initialize()
    InputSystem.loadSetting()
    InputSystem.saveSetting()

    lstg.CreateRenderTarget("rt:white", 16, 16, false)
    lstg.LoadImage("white", "rt:white", 0, 0, 16, 16)
    lstg.LoadTTF("sans", "assets/font/SourceHanSansCN-Bold.otf", 0, 32)
end

function GameExit()
end

local begin_x, begin_y = 0, 0
local end_x, end_y = 0, 0
local play_mode = "normal"
local records = {}
local record_index = 0
local serde_names = { "player" }

local serialize_context = InputSystem.createSerializeContext()
serialize_context:initialize(serde_names)
local USING_SERIALIZE_CONTEXT = true

function FrameFunc()
    InputSystem.update()
    if play_mode == "record" then
        if record_index > 600 then
            end_x = x
            end_y = y
            x = begin_x
            y = begin_y
            play_mode = "playback"
            record_index = 1
        end
    elseif play_mode == "playback" then
        if record_index > 600 then
            play_mode = "normal"
            record_index = 0
            assert(end_x == x)
            assert(end_y == y)
        end
    else
        if InputSystem.isBooleanActionActivated("menu:record") then
            play_mode = "record"
            record_index = 1
            begin_x = x
            begin_y = y
        end
    end
    if play_mode == "record" then
        local record
        print("serialize -- ", record_index)
        if USING_SERIALIZE_CONTEXT then
            record = serialize_context:serialize()
        else
            record = InputSystem.serialize(serde_names)
        end
        records[record_index] = record
        record_index = record_index + 1
    elseif play_mode == "playback" then
        print("deserialize -- ", record_index)
        local record = assert(records[record_index])
        record_index = record_index + 1
        if USING_SERIALIZE_CONTEXT then
            serialize_context:deserialize(record)
        else
            InputSystem.deserialize(record)
        end
    end

    local dx = 0
    if InputSystem.getBooleanAction("player:left") then
        dx = dx - 1
    elseif InputSystem.getBooleanAction("player:right") then
        dx = dx + 1
    end
    local dy = 0
    if InputSystem.getBooleanAction("player:down") then
        dy = dy - 1
    elseif InputSystem.getBooleanAction("player:up") then
        dy = dy + 1
    end
    local v = 1
    if dx ~= 0 and dy ~= 0 then
        v = 0.70710678118654752440084436210485
    end
    local speed = 10
    if InputSystem.getBooleanAction("player:slow") then
        speed = 5
    end
    local dx2, dy2 = InputSystem.getVector2Action("player:fps-move")
    x = x + v * speed * (dx + dx2)
    y = y + v * speed * (dy + dy2)
    if InputSystem.isBooleanActionActivated("player:size-smaller", 60, 60) then
        size = math.max(16, size - 16)
    end
    if InputSystem.isBooleanActionActivated("player:size-larger", 120, 60) then
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
    local px, py = InputSystem.getVector2Action("menu:pointer")
    lstg.Render("white", px, py, 45, size / 16)
    local text = ("%03d -- %s"):format(record_index, play_mode)
    lstg.RenderTTF("sans", text, 10, 10, Viewport.height - 10, Viewport.height - 10, 0 + 0, lstg.Color(255, 255, 255, 255), 2)
    lstg.EndScene()
end
