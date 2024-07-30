---=====================================
---stage group
---=====================================

Extramode = false -- TODO: 需要重新设计
gamecontinueflag = false -- TODO: 需要重新设计
moveoverflag = false -- TODO: 这是什么几把

local deathmusic = 'deathmusic' -- 疮痍曲

----------------------------------------
---关卡组

---@class stage.group
local M = {}

stage.group = M

---@type stage.group.Group[]
M.groups = {}

--- TODO: 需要移除
---@type table<string, stage.group.Group> | string[]
local legacy_groups = {}

--- TODO: 需要移除
stage.groups = legacy_groups

---@class stage.group.Group -- : stage.Stage[]
local group_class = {
    -- 关卡组名称
    name = "",
    -- 主菜单对应的关卡，用于返回主菜单
    title = "",
    --- 包含的关卡数量
    number = 0,
    --- TODO: 需要优化
    --- 初始化一些 lstg.var 值
    ---@type table<string, number>
    item_init = {},
    --- 显示在关卡组练习列表
    allow_practice = false,
    --- 用于难度差分，一般用 1, 2, 3, 4 代表 E, N, H, L 难度
    difficulty = 1,
    --- 包含的关卡
    ---@type stage.group.Stage[]
    stages = {},
}

---@class stage.group.Stage : stage.Stage
local stage_class = {
    --- 当前是第几个关卡
    number = 0,
    --- 所属关卡组
    ---@type stage.group.Group
    group = {},
    x = 0,
    y = 0,
    --- 关卡名称，实际上和 stage_name 一致
    name = "",
    --- TODO: 需要优化
    --- 初始化一些 lstg.var 值
    ---@type table<string, number>
    item_init = {},
    --- 显示在关卡组练习列表
    allow_practice = false,
}

---@param name string
---@return stage.group.Group|nil
function M.Find(name)
    assert(type(name) == "string", "invalid argument #1 (string expected)")
    for _, sg in ipairs(M.groups) do
        if sg.name == name then
            return sg
        end
    end
    return nil
end

---@param title string
---@param stages string[]
---@param name string
---@param item_init table<string, number>
---@param allow_practice boolean
---@param difficulty number
---@return stage.group.Group
---@overload fun(title: string, stages:string[], name:string): stage.group.Group
---@overload fun(title: string, stages:string[], name:string, item_init:table<string, number>): stage.group.Group
---@overload fun(title: string, stages:string[], name:string, item_init:table<string, number>, allow_practice:boolean): stage.group.Group
---@overload fun(title: string, stages:string[], name:string, item_init:table<string, number>, allow_practice:boolean, difficulty:number): stage.group.Group
function M.OldNew(title, stages, name, item_init, allow_practice, difficulty)
    assert(type(title) == "string", "invalid argument #1 (string expected)")
    assert(type(stages) == "table", "invalid argument #2 (table expected)")
    assert(type(name) == "string", "invalid argument #3 (string expected)")
    if item_init then
        assert(type(item_init) == "table", "invalid argument #4 (table expected)")
    end
    allow_practice = not (not allow_practice) -- 转换为 boolean
    if difficulty then
        assert(type(difficulty) == "number", "invalid argument #6 (number expected)")
    end

    ---@param sg stage.group.Group
    local function appendStages(sg)
        -- TODO: 这个有用吗？
        -- 储存预定义关卡
        for i, v in ipairs(stages) do
            local s = stage.New(v)
            ---@cast s -stage.Stage, +stage.group.Stage
            s.frame = M.frame
            s.render = M.render
            s.name = v
            s.group = sg
            s.x, s.y = 0, 0
            table.insert(sg.stages, s)
            s.number = #sg.stages
            sg.number = sg.number + 1
            -- TODO: 应该移除的兼容性代码
            table.insert(sg, v)
            sg[v] = s
        end
    end

    local sg = M.Find(name)
    if sg then
        -- 已有关卡组，直接返回，并检查一致性
        assert(sg.title == title, string.format("stage group '%s' title not match", name))
        -- 限制该参数的使用
        assert(#stages == 0, "stages should be empty") -- appendStages
        -- TODO: 需要重新设计
        if item_init then
            for k, v in pairs(item_init) do
                sg.item_init[k] = v
            end
        end
        assert(allow_practice == sg.allow_practice, string.format("stage group '%s' allow_practice not match", name))
        assert(sg.difficulty == difficulty, string.format("stage group '%s' difficulty not match", name))
        return sg
    else
        ---@type stage.group.Group
        sg = {}
        sg.name = name
        sg.title = title
        sg.number = 0
        if item_init then
            sg.item_init = item_init
        else
            sg.item_init = {}
        end
        sg.allow_practice = allow_practice
        sg.difficulty = difficulty or 1
        sg.stages = {}
        appendStages(sg)
        table.insert(M.groups, sg)
        -- TODO: 需要重新设计
        legacy_groups[name] = sg
        -- TODO: 需要重新设计
        table.insert(legacy_groups, name)
        return sg
    end
end

---@param name string
---@param menu_stage_name string
---@param item_init table<string, number>
---@param allow_practice boolean
---@param difficulty number
---@overload fun(name:string, menu_stage_name: string): stage.group.Group
---@overload fun(name:string, menu_stage_name: string, item_init:table<string, number>): stage.group.Group
---@overload fun(name:string, menu_stage_name: string, item_init:table<string, number>, allow_practice:boolean): stage.group.Group
function M.New(name, menu_stage_name, item_init, allow_practice, difficulty, ...)
    -- TODO: 兼容代码，早期关卡组创建，第一个参数不是名称
    if type(menu_stage_name) == "table" then
        ---@diagnostic disable-next-line: param-type-mismatch
        return M.OldNew(name, menu_stage_name, item_init, allow_practice, difficulty, ...)
    end
    return M.OldNew(menu_stage_name, {}, name, item_init, allow_practice, difficulty)
end

---@param groupname string
---@param stagename string
---@param item_init table<string, number>
---@param allow_practice boolean
---@return stage.group.Stage
function M.AddStage(groupname, stagename, item_init, allow_practice)
    assert(type(groupname) == "string", "invalid argument #1 (string expected)")
    assert(type(stagename) == "string", "invalid argument #2 (string expected)")
    if item_init then
        assert(type(item_init) == "table", "invalid argument #3 (table expected)")
    end
    allow_practice = not (not allow_practice) -- 转换为 boolean

    local sg = M.Find(groupname)
    assert(sg, string.format("stage group '%s' not found", groupname))

    ---@type stage.group.Stage|nil
    local s
    for _, sgs in ipairs(sg.stages) do
        if sgs.name == stagename then
            s = sgs
            break
        end
    end

    if not s then
        local ss = stage.New(stagename)
        ---@cast ss -stage.Stage, +stage.group.Stage
        s = ss
        ---@cast s -nil
        table.insert(sg.stages, s)
        sg.number = sg.number + 1
        s.number = sg.number
        s.frame = M.frame
        s.render = M.render
        s.group = sg
        s.x, s.y = 0, 0
        s.name = stagename
        if item_init then
            s.item_init = item_init
        else
            s.item_init = {}
        end
        s.allow_practice = allow_practice
        -- TODO: 应该移除的兼容性代码
        table.insert(sg, stagename)
        sg[stagename] = s
    end
    return s
end

local allow_callback_names = {
    ["init"] = true,
    ["del"] = true,
    ["frame"] = true,
    ["render"] = true,
}

---@param stagename string
---@param funcname '"init"' | '"del"' | '"frame"' | '"render"'
---@param f fun(self: stage.group.Stage)
function M.DefStageFunc(stagename, funcname, f)
    assert(type(stagename) == "string", "invalid argument #1 (string expected)")
    assert(allow_callback_names[funcname], string.format("invalid argument #2 (invalid function name '%s')", funcname))
    assert(type(f) == "function", "invalid argument #3 (function expected)")

    assert(stage.stages[stagename], string.format("stage '%s' not found", stagename))

    local s = stage.stages[stagename]
    ---@cast s -stage.Stage, +stage.group.Stage
    s[funcname] = f
end

---@param self stage.group.Stage
function M.frame(self)
    ext.sc_pr = false
    if not lstg.var.init_player_data then
        error('Player data has not been initialized. (Call function item.PlayerInit.)')
    end
    --
    if lstg.var.lifeleft <= -1 then
        if ext.replay.IsReplay() then
            ext.pop_pause_menu = true
            ext.rep_over = true
            lstg.tmpvar.pause_menu_text = { 'Replay Again', 'Return to Title', nil }
        else
            PlayMusic(deathmusic, 0.8)
            ext.pop_pause_menu = true
            lstg.tmpvar.death = true
            lstg.tmpvar.pause_menu_text = { 'Continue', 'Quit and Save Replay', 'Restart' }
        end
        lstg.var.lifeleft = 0
    end
    --
    if ext.GetPauseMenuOrder() == 'Return to Title' then
        lstg.var.timeslow = nil
        M.ReturnToTitle(false, 0)
    end
    if ext.GetPauseMenuOrder() == 'Replay Again' then
        lstg.var.timeslow = nil
        stage.Restart()
    end
    if ext.GetPauseMenuOrder() == 'Give up and Retry' then
        StopMusic(deathmusic)
        lstg.var.timeslow = nil
        if lstg.var.is_practice then
            M.PracticeStart(self.name)
        else
            M.Start(self.group.name)
        end
    end
    if ext.GetPauseMenuOrder() == 'Continue' then
        lstg.var.timeslow = nil
        StopMusic(deathmusic)
        if not Extramode then
            gamecontinueflag = true
            if lstg.var.block_spell then
                if lstg.var.is_practice then
                    M.PracticeStart(self.name)
                else
                    M.Start(self.group.name)
                end
                lstg.tmpvar.pause_menu_text = nil
            else
                --item.PlayerInit()
                -- START: modified by 二要 打分等代码修改记录
                local temp = lstg.var.score or 0
                lstg.var.score = 0
                item.PlayerReinit()
                lstg.tmpvar.hiscore = lstg.tmpvar.hiscore or 0
                if lstg.tmpvar.hiscore < temp then
                    lstg.tmpvar.hiscore = temp
                end
                -- END
                lstg.tmpvar.pause_menu_text = nil
                ext.pause_menu_order = nil
                if lstg.var.is_practice then
                    M.PracticeStart(self.name)
                else
                    stage.stages[stage.current_stage.group.title].save_replay = nil
                end
            end
        else
            M.Start(self.group.name)
            lstg.tmpvar.pause_menu_text = nil
        end
    end
    if ext.GetPauseMenuOrder() == 'Quit and Save Replay' then
        M.ReturnToTitle(true, 0)
        lstg.tmpvar.pause_menu_text = nil
        lstg.tmpvar.death = true
        lstg.var.timeslow = nil
    end
    if ext.GetPauseMenuOrder() == 'Restart' then
        StopMusic(deathmusic)
        if lstg.var.is_practice then
            M.PracticeStart(self.name)
        else
            M.Start(self.group.name)
        end
        lstg.tmpvar.pause_menu_text = nil
        lstg.var.timeslow = nil
    end
end

M.sc_pr_fast_retry = false
M.sc_pr_auto_retry = false

---@param self stage.group.Stage
function M.frame_sc_pr(self)
    ext.sc_pr = true
    if not lstg.var.init_player_data then
        error('Player data has not been initialized. (Call function item.PlayerInit)')
    end
    if lstg.var.lifeleft <= -1 then
        if ext.replay.IsReplay() then
            ext.pop_pause_menu = true
            ext.rep_over = true
            lstg.tmpvar.pause_menu_text = { 'Replay Again', 'Return to Title', nil }
        elseif M.sc_pr_auto_retry then
            stage.Restart()
            lstg.var.timeslow = nil
        else
            ext.pop_pause_menu = true
            lstg.tmpvar.death = true
            lstg.tmpvar.pause_menu_text = { 'Continue', 'Quit and Save Replay', 'Return to Title' }
        end
        lstg.var.lifeleft = 0
    end
    if ext.GetPauseMenuOrder() == 'Give up and Retry' or ext.GetPauseMenuOrder() == 'Restart' or (stage.group.sc_pr_fast_retry and lstg.GetLastKey() == KEY.R) then
        stage.Restart()
        lstg.tmpvar.pause_menu_text = nil
        lstg.var.timeslow = nil
    end
    if ext.GetPauseMenuOrder() == 'Return to Title' then
        M.ReturnToTitle(false, 0)
        lstg.var.timeslow = nil
    end
    if ext.GetPauseMenuOrder() == 'Replay Again' then
        stage.Restart()
        lstg.var.timeslow = nil
    end
    if ext.GetPauseMenuOrder() == 'Continue' then
        stage.Restart()
        lstg.var.timeslow = nil
    end
    if ext.GetPauseMenuOrder() == 'Quit and Save Replay' then
        M.ReturnToTitle(true, 0)
        lstg.tmpvar.pause_menu_text = nil
        lstg.tmpvar.death = true
        lstg.var.timeslow = nil
    end
end

---@param self stage.group.Stage
function M.render(self)
    ui.DrawFrame(self)
    if lstg.var.init_player_data then
        ui.DrawScore(self)
    end
    SetViewMode 'world'
    RenderClearViewMode(Color(255, 0, 0, 0))
end

---@param group_name string
function M.Start(group_name)
    -- TODO: 兼容性写法，早期关卡组可以没有名称，所以这里设计的是传入关卡组对象
    if type(group_name) == "table" then
        local sg = group_name
        ---@cast sg -string, +stage.group.Group
        group_name = sg.name
    end

    assert(type(group_name) == "string", "invalid argument #1 (string expected)")

    local sg = M.Find(group_name)
    assert(sg, string.format("stage group '%s' not found", group_name))
    assert(#sg.stages > 0, "stage group is empty")

    lstg.var.is_practice = false
    stage.Set(sg.stages[1].stage_name, "save")
    -- TODO: 需要重新设计
    stage.stages[sg.title].save_replay = { sg.stages[1].stage_name }
end

---@param stagename string
function M.PracticeStart(stagename)
    assert(type(stagename) == "string", "invalid argument #1 (string expected)")

    lstg.var.is_practice = true
    stage.Set(stagename, "save")
    -- TODO: 需要重新设计
    stage.stages[stage.stages[stagename].group.title].save_replay = { stagename }
end

function M.FinishStage()
    local self = stage.current_stage
    ---@cast self -stage.Stage, +stage.group.Stage
    local sg = self.group
    if self.number == sg.number or lstg.var.is_practice then
        if ext.replay.IsReplay() then
            ext.rep_over = true
            ext.pop_pause_menu = true
            lstg.tmpvar.pause_menu_text = { 'Replay Again', 'Return to Title', nil }
        else
            if lstg.var.is_practice then
                M.ReturnToTitle(true, 0)
            else
                M.ReturnToTitle(true, 1)
            end
        end
    else
        if ext.replay.IsReplay() then
            -- 载入关卡并执行录像
            stage.Set(
                ext.replay.GetReplayStageName(ext.replay.GetCurrentReplayIdx() + 1),
                'load',
                ext.replay.GetReplayFilename())
        else
            -- 载入关卡并开始保存录像
            stage.Set(sg[self.number + 1], 'save')
            -- TODO: 需要重新设计
            if stage.stages[sg.title].save_replay then
                table.insert(stage.stages[sg.title].save_replay, sg[self.number + 1])
            end
        end
    end
end

--- 播放 replay 时，提前结束关卡并进入下一关  
--- TODO: 这个设计有点奇怪
function M.FinishReplay()
    local self = stage.current_stage
    ---@cast self -stage.Stage, +stage.group.Stage
    local sg = self.group
    if self.number == sg.number or lstg.var.is_practice then
        if ext.replay.IsReplay() then
            ext.rep_over = true
            ext.pop_pause_menu = true
            lstg.tmpvar.pause_menu_text = { 'Replay Again', 'Return to Title', nil }
        end
    else
        if ext.replay.IsReplay() then
            -- 载入关卡并执行录像
            stage.Set(
                ext.replay.GetReplayStageName(ext.replay.GetCurrentReplayIdx() + 1),
                'load',
                ext.replay.GetReplayFilename())
        end
    end
end

---@param number number
---@overload fun()
function M.GoToStage(number)
    assert(type(number) == "number", "invalid argument #1 (number expected)")
    assert(number > 0, "invalid argument #1 (number must be greater than 0)")

    local self = stage.current_stage
    ---@cast self -stage.Stage, +stage.group.Stage
    local sg = self.group
    number = number or self.number + 1
    if number > sg.number or lstg.var.is_practice then
        if lstg.var.is_practice then
            M.ReturnToTitle(true, 0)
        else
            M.ReturnToTitle(true, 1)
        end
    else
        if ext.replay.IsReplay() then
            stage.Set(sg[number], 'load', ext.replay.GetReplayFilename())
        else
            stage.Set(sg[number], 'save')
            -- TODO: 需要重新设计
            if stage.stages[sg.title].save_replay then
                table.insert(stage.stages[sg.title].save_replay, sg[number])
            end
        end
    end
end

function M.FinishGroup()
    M.ReturnToTitle(true, 1)
end

---@param save_rep boolean
---@param finish 0 | 1
---@overload fun()
---@overload fun(save_rep: boolean)
function M.ReturnToTitle(save_rep, finish)
    if finish then
        assert(finish == 0 or finish == 1, "invalid argument #2 (finish must be 0 or 1)")
    end

    -- 清理一些 flag，并根据条件禁用 replay 保存
    local self = stage.current_stage
    ---@cast self -stage.Stage, +stage.group.Stage
    local title = stage.stages[self.group.title]
    title.finish = finish or 0
    if ext.replay.IsReplay() then
        title.save_replay = nil
    elseif not save_rep then
        title.save_replay = nil
        moveoverflag = true
    end
    gamecontinueflag = false

    StopMusic(deathmusic)
    stage.Set(self.group.title, 'none')
end

----------------------------------------
---编辑器封装

local function _fade_out_music()
    local _, bgm = EnumRes('bgm')
    for i = 1, 30 do
        for _, v in ipairs(bgm) do
            if GetMusicState(v) == 'playing' then
                SetBGMVolume(v, 1 - i / 30)
            end
        end
        task.Wait(1)
    end
end

---@param self stage.group.Stage
---@param f fun(self: stage.group.Stage)
function M.initTask(self, f)
    assert(type(f) == "function", "invalid argument #2 (function expected)")
    _init_item(self)
    difficulty = self.group.difficulty
    New(mask_fader,'open')
    if jstg and jstg.CreatePlayers then
        jstg.CreatePlayers()
    else
        New(_G[lstg.var.player_name])
    end
    local _main_task = task.New(self, function()
        f(self)
    end)
    task.New(self, function()
        while coroutine.status(_main_task) ~= 'dead' do
            task.Wait(1)
        end
        M.FinishReplay()
        New(mask_fader, 'close')
        task.New(self, function()
            _fade_out_music()
        end)
        task.Wait(30)
        _stop_music()
        M.FinishStage()
    end)
end

---@param self stage.group.Stage
---@param number number
---@param wait boolean
---@overload fun(self: stage.group.Stage)
---@overload fun(self: stage.group.Stage, number: number)
function M.GoToStageTask(self, number, wait)
    assert(type(self) == "table", "invalid argument #1 (table expected)")
    if number then
        assert(type(number) == "number", "invalid argument #2 (number expected)")
    end
    local function f()
        New(mask_fader, 'close')
        task.New(self, function()
            _fade_out_music()
        end)
        task.Wait(30)
        _stop_music()
        M.GoToStage(number)
    end
    if wait then
        f()
    else
        task.New(self, f)
    end
end

---@param self stage.group.Stage
---@param wait boolean
---@overload fun(self: stage.group.Stage)
function M.FinishGroupTask(self, wait)
    local function f()
        New(mask_fader,'close')
        task.New(self, function()
            _fade_out_music()
        end)
        task.Wait(30)
        _stop_music()
        M.FinishGroup()
    end
    if wait then
        f()
    else
        task.New(self, f)
    end
end

----------------------------------------
---示例代码

-- stage.group.New("Normal", "menu", {lifeleft=2,power=400,bomb=2}, true, 4)
-- stage.group.AddStage('Normal', 'Stage 1@Normal', {lifeleft=8,power=400,bomb=8}, true)
-- stage.group.DefStageFunc('Stage 1@Normal', 'init', function(self)
--     stage.group.initTask(self, function()
--         New(temple_background)
--         task.Wait(60)
--     end)
-- end)
