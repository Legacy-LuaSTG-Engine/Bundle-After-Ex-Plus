local lstg_debug = require("lib.Ldebug")
local imgui_exist, imgui = pcall(require, "imgui")

local default_id = "__DEFAULT__"
local default_name = "Default (Default Audio)"

---@class lstg.debug.SelectAudioDeviceView : lstg.debug.View
local SelectAudioDeviceView = {}

function SelectAudioDeviceView:getWindowName() return "Select Audio Device" end
function SelectAudioDeviceView:getMenuItemName() return "Select Audio Device" end
function SelectAudioDeviceView:getMenuGroupName() return "Tool" end
function SelectAudioDeviceView:getEnable() return self.enable end
---@param v boolean
function SelectAudioDeviceView:setEnable(v) self.enable = v end

function SelectAudioDeviceView:update()
    if string.len(self.select_audio_device) > 0 then
        if self.select_audio_device == default_id then
            lstg.ChangeAudioDevice("")
        else
            lstg.ChangeAudioDevice(self.select_audio_device)
        end
        self:refresh()
        self.select_audio_device = ""
    end
end
function SelectAudioDeviceView:layout()
    local dev = lstg.GetCurrentAudioDeviceName()
    if #dev == 0 then
        dev = default_name
    end
    imgui.ImGui.Text("Current: " .. dev)
    --imgui.ImGui.SameLine()
    if imgui.ImGui.Button("Refresh") then
        self:refresh()
    end
    imgui.ImGui.Separator()
    for _, v in ipairs(self.audio_device_list) do
        local s = v
        if s == default_id then
            s = default_name
        end
        if imgui.ImGui.Button(s) then
            self.select_audio_device = v
        end
    end
end
function SelectAudioDeviceView:refresh()
    ---@type string[]
    self.audio_device_list = lstg.ListAudioDevice(true)
    table.insert(self.audio_device_list, 1, default_id)
    for _, v in ipairs(self.audio_device_list) do
        imgui.backend.CacheGlyphFromString(tostring(v))
    end
end
function SelectAudioDeviceView:init()
    self.select_audio_device = ""
    self:refresh()
end

SelectAudioDeviceView:init()
lstg_debug.addView("lstg.debug.SelectAudioDeviceView", SelectAudioDeviceView)
