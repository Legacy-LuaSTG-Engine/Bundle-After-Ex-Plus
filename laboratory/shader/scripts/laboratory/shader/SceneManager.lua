local lstg = require("lstg")
local Keyboard = lstg.Input.Keyboard
local Scene = require("laboratory.shader.Scene")
local Viewport = require("laboratory.shader.Viewport")

---@generic T
---@param class T
---@return T
local function makeInstance(class)
    local instance = {}
    setmetatable(instance, { __index = class })
    return instance
end

---@type laboratory.shader.Scene[]
local scenes = {}

local current_scene_index = 0

---@type laboratory.shader.Scene
local current_scene = makeInstance(Scene)

---@class laboratory.shader.SceneManager
local SceneManager = {}

function SceneManager.initialize()
    Viewport.initialize()
    lstg.LoadTTF("Sans", "assets/font/SourceHanSansCN-Bold.otf", 0, 24) -- from thlib-scripts
end

function SceneManager.destroy()
    current_scene:destroy()
end

local any_key_down = true

function SceneManager.update()
    local change = 0
    if Keyboard.GetKeyState(Keyboard.Left) then
        if not any_key_down then
            any_key_down = true
            if current_scene_index > 1 then
                change = -1
            end
        end
    elseif Keyboard.GetKeyState(Keyboard.Right) then
        if not any_key_down then
            any_key_down = true
            if current_scene_index < #scenes then
                change = 1
            end
        end
    elseif any_key_down then
        any_key_down = false
    end
    if change ~= 0 then
        current_scene:destroy()
        current_scene_index = current_scene_index + change
        current_scene = makeInstance(scenes[current_scene_index])
        current_scene:create()
    end
    current_scene:update()
end

function SceneManager.draw()
    lstg.BeginScene()
    current_scene:draw()
    Viewport.apply()
    local edge = 4
    lstg.RenderTTF("Sans", string.format("%s\n< %d/%d >", current_scene.name, current_scene_index, #scenes), edge,
    Viewport.width - edge, edge, Viewport.height - edge, 1 + 8, lstg.Color(255, 255, 255, 64), 2)
    lstg.EndScene()
end

---@param scene laboratory.shader.Scene
function SceneManager.add(scene)
    for _, v in ipairs(scenes) do
        if v == scene then
            return
        end
    end
    table.insert(scenes, scene)
    if current_scene_index < 1 then
        current_scene_index = #scenes
        current_scene = makeInstance(scenes[current_scene_index])
        current_scene:create()
    end
end

return SceneManager
