local lstg_debug = require("lib.Ldebug")
local imgui_exist, imgui = pcall(require, "imgui")

---@class lstg.debug.UpdateControllerView : lstg.debug.View
local UpdateControllerView = {}

function UpdateControllerView:getWindowName() return "Update Controller" end
function UpdateControllerView:getMenuItemName() return "Update Controller" end
function UpdateControllerView:getMenuGroupName() return "Game" end
function UpdateControllerView:getEnable() return self.enable end
---@param v boolean
function UpdateControllerView:setEnable(v) self.enable = v end

function UpdateControllerView:update() end
function UpdateControllerView:layout()
    if ext and ext.debug_data then
        local db = ext.debug_data
    
        _, db.x_speed_update = imgui.ImGui.Checkbox("Enable", db.x_speed_update)
    
        if db.x_speed_update_value == 0 then
            if imgui.ImGui.Button("Request Once Update") then
                db.request_once_update = true
            end
        end
    
        if imgui.ImGui.RadioButton("Speed x1/16", db.x_speed_update_value == -16) then
            db.x_speed_update_value = -16
        end
        if imgui.ImGui.RadioButton("Speed x1/8", db.x_speed_update_value == -8) then
            db.x_speed_update_value = -8
        end
        if imgui.ImGui.RadioButton("Speed x1/4", db.x_speed_update_value == -4) then
            db.x_speed_update_value = -4
        end
        if imgui.ImGui.RadioButton("Speed x1/2", db.x_speed_update_value == -2) then
            db.x_speed_update_value = -2
        end
        if imgui.ImGui.RadioButton("Speed x0", db.x_speed_update_value == 0) then
            db.x_speed_update_value = 0
        end
        if imgui.ImGui.RadioButton("Speed x1", db.x_speed_update_value == 1) then
            db.x_speed_update_value = 1
        end
        if imgui.ImGui.RadioButton("Speed x2", db.x_speed_update_value == 2) then
            db.x_speed_update_value = 2
        end
        if imgui.ImGui.RadioButton("Speed x4", db.x_speed_update_value == 4) then
            db.x_speed_update_value = 4
        end
        if imgui.ImGui.RadioButton("Speed x8", db.x_speed_update_value == 8) then
            db.x_speed_update_value = 8
        end
        if imgui.ImGui.RadioButton("Speed x16", db.x_speed_update_value == 16) then
            db.x_speed_update_value = 16
        end
    end
end

lstg_debug.addView("lstg.debug.UpdateControllerView", UpdateControllerView)
