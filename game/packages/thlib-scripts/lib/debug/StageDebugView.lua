local lstg_debug = require("lib.Ldebug")
local imgui_exist, imgui = pcall(require, "imgui")

---@param v number
---@param a number
---@param b number
local function is_in_range(v, a, b)
    return v >= a and v <= b
end

---@class lstg.debug.StageDebugView : lstg.debug.View
local StageDebugView = {}

function StageDebugView:getWindowName() return "Stage Debug" end
function StageDebugView:getMenuItemName() return "Stage Debug" end
function StageDebugView:getMenuGroupName() return "Game" end
function StageDebugView:getEnable() return self.enable end
---@param v boolean
function StageDebugView:setEnable(v) self.enable = v end

function StageDebugView:initialize()
    ---@type string[]
    self.group_list = {}
    self.group_index = 1

    ---@type string[][]
    self.group_stage_list = {}
    ---@type string[][]
    self.group_stage_name_list = {}
    ---@type number[]
    self.group_stage_index = {}

    ---@type string[]
    self.stage_list = {}
    self.stage_index = 1

    ---@type string[][]
    self.player_list = {}
    self.player_index = 1

    self.tab_index = 0

    ---@type lstg.debug.StageDebugView.BossData[]
    self.boss_list = {}
    self.boss_index = 1
end
local function isBossClass(class_type)
    if class_type == boss then
        return true
    elseif class_type.base then
        return isBossClass(class_type.base)
    else
        return false
    end
end
local function isBossDialogScene(scene_type)
    if scene_type.frame == boss.dialog.frame
	or scene_type.render == boss.dialog.render
	or scene_type.init == boss.dialog.init
	or scene_type.del == boss.dialog.del
    then
        return true
    else
        return false
    end
end
local function isBossMoveScene(scene_type)
    if scene_type.frame == boss.move.frame
	or scene_type.render == boss.move.render
	or scene_type.init == boss.move.init
	or scene_type.del == boss.move.del
    or scene_type.render == boss.escape.render
	or scene_type.init == boss.escape.init
	or scene_type.del == boss.escape.del
    or scene_type.del == boss.escape.del
    then
        return true
    else
        return false
    end
end
local function isBossSceneIncludePrevious(scene_class)
    for _, sc_record in ipairs(_sc_table) do
        if sc_record[3] == scene_class then
            return sc_record[3][5]
        end
    end
    return false
end
local function getBossSceneIndex(scene_class)
    for i, sc_record in ipairs(_sc_table) do
        if sc_record[3] == scene_class then
            return i
        end
    end
    return 0
end
function StageDebugView:refreshBoss()
    if type(_editor_class) ~= "table" then
        return
    end
    ---@type lstg.debug.StageDebugView.BossData[]
    local boss_list = {}
    for class_name, class_type in pairs(_editor_class) do
        if isBossClass(class_type) then
            ---@class lstg.debug.StageDebugView.BossData
            local boss_data = {}
            boss_data.class_name = class_name
            boss_data.class_type = class_type
            boss_data.scene_index = 1
            ---@type lstg.debug.StageDebugView.BossData.SceneData[]
            boss_data.scene_data = {}
            table.insert(boss_list, boss_data)
            imgui.backend.CacheGlyphFromString(tostring(boss_data.class_name))
            imgui.backend.CacheGlyphFromString(tostring(boss_data.class_type.name))
            for i, boss_scene in ipairs(class_type.cards) do
                imgui.backend.CacheGlyphFromString(tostring(boss_scene.name))
                ---@class lstg.debug.StageDebugView.BossData.SceneData[]
                local scene_data = {
                    class_index = i,
                    class_type = boss_scene,
                    include_previous = isBossSceneIncludePrevious(boss_scene),
                    sc_table_index = getBossSceneIndex(boss_scene),
                }
                table.insert(boss_data.scene_data, scene_data)
            end
        end
    end
    table.sort(boss_list, function(a, b)
        return a.class_name < b.class_name
    end)
    self.boss_list = boss_list
    if #self.boss_list < 1 then
        self.boss_index = 1
    else
        self.boss_index = math.max(1, math.min(self.boss_index, #self.boss_list))
    end
end
function StageDebugView:refresh()
    -- 更新关卡组列表

    ---@type string[]
    local group_list = {}
    if type(stage) == "table" and type(stage.group) == "table" then
        for _, group in ipairs(stage.group.groups) do
            if group.name ~= "Spell Practice" then
                table.insert(group_list, group.name)
            end
        end
    end
    self.group_list = group_list
    if #self.group_list < 1 then
        self.group_index = 1
    else
        self.group_index = math.max(1, math.min(self.group_index, #self.group_list))
    end

    -- 更新关卡组关卡列表

    ---@type string[][]
    local group_stage_list = {}
    ---@type string[][]
    local group_stage_name_list = {}
    for _, group_name in ipairs(group_list) do
        local sg = stage.group.Find(group_name)
        ---@cast sg -nil
        ---@type string[]
        local stage_list = {}
        ---@type string[]
        local stage_name_list = {}
        for _, s in ipairs(sg.stages) do
            table.insert(stage_list, s.name)
            table.insert(stage_name_list, string.match(s.name, "^[%w_][%w_ ]*"))
        end
        table.insert(group_stage_list, stage_list)
        table.insert(group_stage_name_list, stage_name_list)
    end
    self.group_stage_list = group_stage_list
    self.group_stage_name_list = group_stage_name_list
    for i, stage_list in ipairs(self.group_stage_list) do
        if #stage_list > 0 then
            self.group_stage_index[i] = self.group_stage_index[i] or 1
            self.group_stage_index[i] = math.max(1, math.min(self.group_stage_index[i], #stage_list))
        else
            self.group_stage_index[i] = 1
        end
    end

    -- 更新关卡列表

    ---@type string[]
    local stage_list = {}
    if type(stage) == "table" and type(stage.stages) == "table" then
        for k, _ in pairs(stage.stages) do
            table.insert(stage_list, k)
        end
    end
    table.sort(stage_list, function(a, b)
        return a < b
    end)
    self.stage_list = stage_list
    if #self.stage_list < 1 then
        self.stage_index = 1
    else
        self.stage_index = math.max(1, math.min(self.stage_index, #self.stage_list))
    end

    -- 更新自机列表

    ---@type string[][]
    local player_list_ = {}
    if type(player_list) == "table" then
        for _, v in ipairs(player_list) do
            if type(v) == "table"
                and type(v[1]) == "string"
                and type(v[2]) == "string"
                and type(v[3]) == "string" then
                table.insert(player_list_, { v[1], v[2], v[3] })
            end
        end
    end
    self.player_list = player_list_
    if #self.player_list < 1 then
        self.player_index = 1
    else
        self.player_index = math.max(1, math.min(self.player_index, #self.player_list))
    end

    self:refreshBoss()
end

local function closePauseMenu()
    if ext then
        if ext.pause_menu and ext.pause_menu.FlyOut then
            ext.pause_menu:FlyOut()
        end
    end
end
function StageDebugView:startStageGroup()
    if #self.player_list > 0 then
        local player_record = self.player_list[self.player_index]
        lstg.var.player_name = player_record[2]
        lstg.var.rep_player = player_record[3]
    else
        return -- 不可用
    end
    if #self.group_list > 0 then
        local group_name = self.group_list[self.group_index]
        stage.group.Start(group_name)
        closePauseMenu()
    end
end
function StageDebugView:startStage()
    if #self.player_list > 0 then
        local player_record = self.player_list[self.player_index]
        lstg.var.player_name = player_record[2]
        lstg.var.rep_player = player_record[3]
    else
        return -- 不可用
    end
    if #self.group_stage_list > 0 and #self.group_stage_list[self.group_index] > 0 then
        local stage_index = self.group_stage_index[self.group_index]
        local stage_name = self.group_stage_list[self.group_index][stage_index]
        stage.group.PracticeStart(stage_name)
        closePauseMenu()
    end
end
function StageDebugView:startAny()
    if #self.player_list > 0 then
        local player_record = self.player_list[self.player_index]
        lstg.var.player_name = player_record[2]
        lstg.var.rep_player = player_record[3]
    else
        return -- 不可用
    end
    if #self.stage_list > 0 then
        local stage_name = self.stage_list[self.stage_index]
        local s = stage.stages[stage_name]
        if type(s.group) == "table" then
            if s.is_menu then
                -- 菜单类型，直接跳转
                stage.Set(stage_name)
                closePauseMenu()
            else
                -- 练习模式
                stage.group.PracticeStart(stage_name)
                closePauseMenu()
            end
        else
            stage.Set(stage_name)
            closePauseMenu()
        end
    end
end
function StageDebugView:startBossScene()
    if #self.player_list > 0 then
        local player_record = self.player_list[self.player_index]
        lstg.var.player_name = player_record[2]
        lstg.var.rep_player = player_record[3]
    else
        return -- 不可用
    end
    if #self.boss_list < 1 then
        return -- 不可用
    end
    local boss_data = self.boss_list[self.boss_index]
    local boss_class = boss_data.class_type
    local boss_scene = boss_class.cards[boss_data.scene_index]
    local boss_scene_data = boss_data.scene_data[boss_data.scene_index]
    -- data 自带
    lstg.var.sc_index = -1
    lstg.var.sc_pr_data = {
        class_name = boss_data.class_name,
        scene_index = boss_data.scene_index,
        include_previous = boss_scene_data.include_previous,
    }
    -- 想不到吧，周末活也改了符卡练习场景
    lstg.var.sc_pr = {
        class_name = boss_data.class_name,
        index = boss_data.scene_index,
        perform = boss_scene_data.include_previous,
    }
    stage.group.PracticeStart("Spell Practice@Spell Practice")
    closePauseMenu()
end

function StageDebugView:update() end
function StageDebugView:layout()
    local ImGui = imgui.ImGui
    if ImGui.Button("Reload View") then
        lstg.DoFile("lib/debug/StageDebugView.lua")
    end
    ImGui.SameLine()
    if ImGui.Button("Refresh") then
        self:refresh()
    end
    if is_in_range(self.tab_index, 2, 4) or self.tab_index == 6 then
        ImGui.SameLine()
        if ImGui.Button("Start") then
            if self.tab_index == 2 then
                self:startStageGroup()
            elseif self.tab_index == 3 then
                self:startStage()
            elseif self.tab_index == 4 then
                self:startAny()
            elseif self.tab_index == 6 then
                self:startBossScene()
            else
                error("unknown error")
            end
        end
    end
    ImGui.Separator()
    if ImGui.BeginTabBar("@TabBar") then
        if ImGui.BeginTabItem("Player") then
            self.tab_index = 1
            for i, v in ipairs(self.player_list) do
                local text = string.format("%d. %s", i, v[1])
                if ImGui.RadioButton(text, self.player_index == i) then
                    self.player_index = i
                end
            end
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem("Stage Group") then
            self.tab_index = 2
            for i, v in ipairs(self.group_list) do
                local text = string.format("%d. %s", i, v)
                if ImGui.RadioButton(text, self.group_index == i) then
                    self.group_index = i
                end
            end
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem("Stage") then
            self.tab_index = 3
            if #self.group_stage_list > 0 then
                for i, v in ipairs(self.group_stage_name_list[self.group_index]) do
                    local text = string.format("%d. %s", i, v)
                    if ImGui.RadioButton(text, self.group_stage_index[self.group_index] == i) then
                        self.group_stage_index[self.group_index] = i
                    end
                end
            end
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem("All Scene") then
            self.tab_index = 4
            for i, v in ipairs(self.stage_list) do
                local text = string.format("%d. %s", i, v)
                if ImGui.RadioButton(text, self.stage_index == i) then
                    self.stage_index = i
                end
            end
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem("Boss Class") then
            self.tab_index = 5
            for i, v in ipairs(self.boss_list) do
                local text = string.format("%d. [%s] %s", i, v.class_name, v.class_type.name)
                if ImGui.RadioButton(text, self.boss_index == i) then
                    self.boss_index = i
                end
            end
            ImGui.EndTabItem()
        end
        if ImGui.BeginTabItem("Boss Scene") then
            self.tab_index = 6
            if #self.boss_list > 0 then
                local boss_data = self.boss_list[self.boss_index]
                local boss_class = boss_data.class_type
                for i, boss_scene in ipairs(boss_class.cards) do
                    local text = string.format("%d. ", i)
                    if isBossDialogScene(boss_scene) then
                        text = text .. "[dialog] "
                    elseif isBossMoveScene(boss_scene) then
                        text = text .. "[move] "
                    elseif boss_scene.is_sc then
                        text = text .. "[spellcard] "
                    elseif boss_scene.is_combat then
                        text = text .. "[attack] "
                    elseif boss_scene.is_combat then
                        text = text .. "[unknown] "
                    end
                    text = text .. boss_scene.name
                    if ImGui.RadioButton(text, boss_data.scene_index == i) then
                        boss_data.scene_index = i
                    end
                end
            end
            ImGui.EndTabItem()
        end
        ImGui.EndTabBar()
    end
end

StageDebugView:initialize()

lstg_debug.addView("lstg.debug.StageDebugView", StageDebugView)
