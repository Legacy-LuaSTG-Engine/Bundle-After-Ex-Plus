local lstg_debug = require("lib.Ldebug")
local imgui_exist, imgui = pcall(require, "imgui")

local default_id = "__DEFAULT__"
local default_name = "Default"

---@class lstg.debug.SelectRenderDeviceView : lstg.debug.View
local SelectRenderDeviceView = {}

function SelectRenderDeviceView:getWindowName() return "Select Render Device" end
function SelectRenderDeviceView:getMenuItemName() return "Select Render Device" end
function SelectRenderDeviceView:getMenuGroupName() return "Tool" end
function SelectRenderDeviceView:getEnable() return self.enable end
---@param v boolean
function SelectRenderDeviceView:setEnable(v) self.enable = v end

function SelectRenderDeviceView:update()
    if string.len(self.select_render_device) > 0 then
        if self.select_render_device == default_id then
            lstg.ChangeGPU("")
        else
            lstg.ChangeGPU(self.select_render_device)
        end
        self:refresh()
        self.select_render_device = ""
    end
end
function SelectRenderDeviceView:layout()
    local dev = lstg.GetCurrentGpuName()
    if #dev == 0 then
        dev = default_name -- 不可能碰到
    end
    imgui.ImGui.Text("Current: " .. dev)
    --imgui.ImGui.SameLine()
    if imgui.ImGui.Button("Refresh") then
        self:refresh()
    end
    imgui.ImGui.Separator()
    for _, v in ipairs(self.render_device_list) do
        local s = v
        if s == default_id then
            s = default_name
        end
        if imgui.ImGui.Button(s) then
            self.select_render_device = v
        end
    end
end
function SelectRenderDeviceView:refresh()
    ---@type string[]
    self.render_device_list = lstg.EnumGPUs()
    table.insert(self.render_device_list, 1, default_id)
    for _, v in ipairs(self.render_device_list) do
        imgui.backend.CacheGlyphFromString(tostring(v))
    end
end
function SelectRenderDeviceView:init()
    self.select_render_device = ""
    self:refresh()
end

SelectRenderDeviceView:init()
lstg_debug.addView("lstg.debug.SelectRenderDeviceView", SelectRenderDeviceView)
