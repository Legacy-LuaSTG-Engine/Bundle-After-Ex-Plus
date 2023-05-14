--------------------------------------------------------------------------------
--- Debug UI
--- 璀境石
--------------------------------------------------------------------------------

---@class lstg.debug
local M = {}

--------------------------------------------------------------------------------

---@class lstg.debug.View
local W = {}
function W:getWindowName() return "View" end
function W:getMenuItemName() return "View" end
function W:getMenuGroupName() return "Tool" end
function W:getEnable() return self.enable end
---@param v boolean
function W:setEnable(v) self.enable = v end
function W:update() end
function W:layout() end

---@type lstg.debug.ViewCollection.Item[]
local view_collection = {}

---@param id any
---@param view lstg.debug.View
function M.addView(id, view)
    local index = 0
    for i, v in ipairs(view_collection) do
        if v.id == id then
            index = i
            break
        end
    end
    ---@class lstg.debug.ViewCollection.Item
    local t = {
        id = id,
        view = view,
    }
    if index > 0 then
        view_collection[index] = t
    else
        table.insert(view_collection, t)
    end
end

--------------------------------------------------------------------------------

local imgui_exist, imgui = pcall(require, "imgui")

---@param vkey number
---@return fun():boolean
function M.KeyDownTrigger(vkey)
    local _last_state = false
    local _state = false
    return function ()
        _state = lstg.GetKeyState(vkey)
        if not _last_state and _state then
            _last_state = _state
            return true
        else
            _last_state = _state
            return false
        end
    end
end

local F1_trigger = M.KeyDownTrigger(KEY.F1)
local F3_trigger = M.KeyDownTrigger(KEY.F3)

-- global cheat = false

local b_show_all = true
local b_show_menubar = false

local b_show_demo_window = false
local b_show_memuse_window = false
local b_show_framept_window = false
local b_show_testinput_window = false
local b_show_resmgr_window = false

---@param view lstg.debug.View
local function layoutViewMenuItem(view)
    local enable = view:getEnable()
    if imgui.ImGui.MenuItem(view:getMenuItemName(), nil, enable) then
        enable = not enable
    end
    view:setEnable(enable)
end

---@param view lstg.debug.View
local function layoutView(view)
    local enable = view:getEnable()
    if not enable then
        return
    end
    local ImGui = imgui.ImGui
    local show = false
    show, enable = ImGui.Begin(view:getWindowName(), enable)
    view:setEnable(enable)
    if show then
        view:layout()
    end
    ImGui.End()
end

function M.update()
    if imgui_exist then
        local flag = false
        if b_show_all then
            flag = flag or b_show_menubar
            flag = flag or b_show_demo_window
            flag = flag or b_show_memuse_window
            flag = flag or b_show_framept_window
            flag = flag or b_show_testinput_window
            flag = flag or b_show_resmgr_window
            for _, v in ipairs(view_collection) do
                flag = flag or v.view:getEnable()
            end
        end
        imgui.backend.NewFrame(flag)
        for _, v in ipairs(view_collection) do
            v.view:update()
        end
    end
end

function M.layout()
    if F1_trigger() then
        b_show_all = not b_show_all
    end
    if F3_trigger() then
        b_show_menubar = not b_show_menubar
    end
    if imgui_exist then
        imgui.ImGui.NewFrame()
        if b_show_all then
            if b_show_menubar then
                if imgui.ImGui.BeginMainMenuBar() then
                    if imgui.ImGui.BeginMenu("Game") then
                        for _, v in ipairs(view_collection) do
                            if v.view:getMenuGroupName() == "Game" then
                                layoutViewMenuItem(v.view)
                            end
                        end
                        imgui.ImGui.EndMenu()
                    end
                    if imgui.ImGui.BeginMenu("Player") then
                        if imgui.ImGui.MenuItem("Cheat", nil, cheat) then cheat = not cheat end
                        if player_lib and player_lib.debug_data then
                            local pdd = player_lib.debug_data
                            if cheat then
                                if type(pdd.invincible_enable_collider) == "boolean" then
                                    if imgui.ImGui.MenuItem("Enable Collider", nil, pdd.invincible_enable_collider) then pdd.invincible_enable_collider = not pdd.invincible_enable_collider end
                                end
                                if pdd.invincible_enable_collider then
                                    if type(pdd.invincible_when_hit_fire_particles) == "boolean" then
                                        if imgui.ImGui.MenuItem("Fire Particles On Hit", nil, pdd.invincible_when_hit_fire_particles) then pdd.invincible_when_hit_fire_particles = not pdd.invincible_when_hit_fire_particles end
                                    end
                                    if type(pdd.invincible_when_hit_play_sound_effect) == "boolean" then
                                        if imgui.ImGui.MenuItem("Play Sound Effect On Hit", nil, pdd.invincible_when_hit_play_sound_effect) then pdd.invincible_when_hit_play_sound_effect = not pdd.invincible_when_hit_play_sound_effect end
                                    end
                                    if type(pdd.invincible_when_hit_delete_object) == "boolean" then
                                        if imgui.ImGui.MenuItem("Delete Bullet On Hit", nil, pdd.invincible_when_hit_delete_object) then pdd.invincible_when_hit_delete_object = not pdd.invincible_when_hit_delete_object end
                                    end
                                end
                            end
                            if type(pdd.keep_shooting) == "boolean" then
                                if imgui.ImGui.MenuItem("Keep Shooting", nil, pdd.keep_shooting) then pdd.keep_shooting = not pdd.keep_shooting end
                            end
                        end
                        for _, v in ipairs(view_collection) do
                            if v.view:getMenuGroupName() == "Player" then
                                layoutViewMenuItem(v.view)
                            end
                        end
                        imgui.ImGui.EndMenu()
                    end
                    --if imgui.ImGui.BeginMenu("Reload") then
                        -- 添加自己的按钮
                        --if imgui.ImGui.MenuItem("example") then lstg.DoFile("example.lua") end
                        --imgui.ImGui.EndMenu()
                    --end
                    if imgui.ImGui.BeginMenu("Tool") then
                        if imgui.ImGui.MenuItem("Memory Usage", nil, b_show_memuse_window) then b_show_memuse_window = not b_show_memuse_window end
                        if imgui.ImGui.MenuItem("Frame Statistics", nil, b_show_framept_window) then b_show_framept_window = not b_show_framept_window end
                        if imgui.ImGui.MenuItem("Test Input", nil, b_show_testinput_window) then b_show_testinput_window = not b_show_testinput_window end
                        if imgui.ImGui.MenuItem("Resource Manager", nil, b_show_resmgr_window) then b_show_resmgr_window = not b_show_resmgr_window end
                        if imgui.ImGui.MenuItem("Demo", nil, b_show_demo_window) then b_show_demo_window = not b_show_demo_window end
                        for _, v in ipairs(view_collection) do
                            if v.view:getMenuGroupName() == "Tool" then
                                layoutViewMenuItem(v.view)
                            end
                        end
                        imgui.ImGui.EndMenu()
                    end
                    imgui.ImGui.EndMainMenuBar()
                end
            end
            
            if b_show_demo_window then
                b_show_demo_window = imgui.ImGui.ShowDemoWindow(b_show_demo_window)
            end
            if b_show_memuse_window and imgui.backend.ShowMemoryUsageWindow then
                b_show_memuse_window = imgui.backend.ShowMemoryUsageWindow(b_show_memuse_window)
            end
            if b_show_framept_window and imgui.backend.ShowFrameStatistics then
                b_show_framept_window = imgui.backend.ShowFrameStatistics(b_show_framept_window)
            end

            if b_show_testinput_window and imgui.backend.ShowTestInputWindow then
                b_show_testinput_window = imgui.backend.ShowTestInputWindow(b_show_testinput_window)
            end

            if b_show_resmgr_window and imgui.backend.ShowResourceManagerDebugWindow then
                b_show_resmgr_window = imgui.backend.ShowResourceManagerDebugWindow(b_show_resmgr_window)
            end

            for _, v in ipairs(view_collection) do
                layoutView(v.view)
            end
        end
        imgui.ImGui.EndFrame()
    end
end

function M.draw()
    if imgui_exist then
        if b_show_all then
            imgui.ImGui.Render()
            imgui.backend.RenderDrawData()
        end
    end
end

return M
