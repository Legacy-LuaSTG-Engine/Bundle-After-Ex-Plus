local Scene = require("foundation.Scene")

---@generic T
---@param type T
---@return T
local function makeInstance(type)
    local instance = {}
    setmetatable(instance, { __index = type })
    return instance
end

---@class foundation.SceneManager
local SceneManager = {}

local exit_signal = false

---@type foundation.Scene
local current_scene = makeInstance(Scene)

---@type string
local current_scene_name = "__default__"

---@type string|nil
local next_scene_name = nil

---@type table<string, foundation.Scene>
local scene_set = {
    ["__default__"] = Scene,
}

---@param scene_name string
function SceneManager.setNext(scene_name)
    assert(type(scene_name) == "string", "scene name must be a string")
    assert(string.len(scene_name) > 0, "scene name must not be empty")
    assert(scene_set[scene_name], string.format("scene '%s' not found", scene_name))
    if next_scene_name then
        lstg.Log(3, "next scene is updated to: " .. scene_name)
    else
        lstg.Log(2, "next scene: " .. scene_name)
    end
    next_scene_name = scene_name
end

---@return foundation.Scene
function SceneManager.getCurrent()
    return current_scene
end

function SceneManager.update()
    if next_scene_name then
        if current_scene then
            current_scene:onDestroy()
        end
        current_scene_name = next_scene_name
        current_scene = makeInstance(scene_set[next_scene_name])
        ---@diagnostic disable-next-line: duplicate-set-field
        function current_scene:getName()
            return current_scene_name
        end
        next_scene_name = nil
        current_scene:onCreate()
    end
    assert(current_scene_name == current_scene:getName(), "DO NOT DO STUPID THINGS")
    current_scene:onUpdate()
end

function SceneManager.render()
    current_scene:onRender()
end

---@param v boolean
function SceneManager.setExitSignal(v)
    exit_signal = not (not v)
end

---@return boolean
function SceneManager.getExitSignal()
    return exit_signal
end

function SceneManager.onActivated()
    current_scene:onActivated()
end

function SceneManager.onDeactivated()
    current_scene:onDeactivated()
end

---@param scene_name string
---@param scene_type foundation.Scene
---@return foundation.Scene
---@overload fun(scene_name:string): foundation.Scene
function SceneManager.add(scene_name, scene_type)
    assert(type(scene_name) == "string", "scene name must be a string")
    assert(string.len(scene_name) > 0, "scene name must not be empty")
    if scene_set[scene_name] then
        lstg.Log(3, string.format("scene '%s' already exists", scene_name))
    end
    if scene_type then
        assert(type(scene_type) == "table", "scene type must be a table")
    else
        scene_type = {}
        scene_type.onCreate = Scene.onCreate
        scene_type.onDestroy = Scene.onDestroy
        scene_type.onUpdate = Scene.onUpdate
        scene_type.onRender = Scene.onRender
        scene_type.onActivated = Scene.onActivated
        scene_type.onDeactivated = Scene.onDeactivated
    end
    lstg.Log(2, string.format("add scene '%s' to scene manager", scene_name))
    scene_set[scene_name] = scene_type
    return scene_type
end

return SceneManager
