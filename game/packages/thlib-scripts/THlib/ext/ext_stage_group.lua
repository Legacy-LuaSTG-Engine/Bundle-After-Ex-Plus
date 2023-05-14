---=====================================
---stage group
---=====================================

----------------------------------------
---关卡组

stage.group = {}
stage.groups = {}

gamecontinueflag = false
local deathmusic = 'deathmusic'--疮痍曲

function stage.group.New(title, stages, name, item_init, allow_practice, difficulty)
    local sg = { ['title'] = title, number = #stages }
    for i = 1, #stages do
        sg[i] = stages[i]
        local s = stage.New(stages[i])
        s.frame = stage.group.frame
        s.render = stage.group.render
        s.number = i
        s.group = sg
        sg[stages[i]] = s
        s.x, s.y = 0, 0
        s.name = stages[i]
    end
    if name then
        if stage.groups[name] then
            return stage.groups[name]
        end
        stage.groups[name] = sg
        table.insert(stage.groups, name)
    end
    if item_init then
        sg.item_init = item_init
    end
    sg.allow_practice = allow_practice or false
    sg.difficulty = difficulty or 1
    return sg
end

function stage.group.AddStage(groupname, stagename, item_init, allow_practice)
    local sg = stage.groups[groupname]
    if sg ~= nil then
        sg.number = sg.number + 1
        table.insert(sg, stagename)
        local s = stage.New(stagename)
        if groupname == 'Spell Practice' or groupname == 'SC Debugger' then
            --by OLC,为了使符卡debug模式更加符合符卡练习的模式
            s.frame = stage.group.frame_sc_pr
        else
            s.frame = stage.group.frame
        end
        s.render = stage.group.render
        s.number = sg.number
        s.group = sg
        sg[stagename] = s
        s.x, s.y = 0, 0
        s.name = stagename
        if item_init then
            s.item_init = item_init
        end
        s.allow_practice = allow_practice or false
        return s
    end
end

function stage.group.DefStageFunc(stagename, funcname, f)
    stage.stages[stagename][funcname] = f
end

function stage.group.frame(self)
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
        stage.group.ReturnToTitle(false, 0)
    end
    if ext.GetPauseMenuOrder() == 'Replay Again' then
        lstg.var.timeslow = nil
        stage.Restart()
    end
    if ext.GetPauseMenuOrder() == 'Give up and Retry' then
        StopMusic(deathmusic)
        lstg.var.timeslow = nil
        if lstg.var.is_practice then
            stage.group.PracticeStart(self.name)
        else
            stage.group.Start(self.group)
        end
    end
    if ext.GetPauseMenuOrder() == 'Continue' then
        lstg.var.timeslow = nil
        StopMusic(deathmusic)
        if not Extramode then
            gamecontinueflag = true
            if lstg.var.block_spell then
                if lstg.var.is_practice then
                    stage.group.PracticeStart(self.name)
                else
                    stage.group.Start(self.group)
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
                    stage.group.PracticeStart(self.name)
                else
                    stage.stages[stage.current_stage.group.title].save_replay = nil
                end
            end
        else
            stage.group.Start(self.group)
            lstg.tmpvar.pause_menu_text = nil
        end
    end
    if ext.GetPauseMenuOrder() == 'Quit and Save Replay' then
        stage.group.ReturnToTitle(true, 0)
        lstg.tmpvar.pause_menu_text = nil
        lstg.tmpvar.death = true
        lstg.var.timeslow = nil
    end
    if ext.GetPauseMenuOrder() == 'Restart' then
        StopMusic(deathmusic)
        if lstg.var.is_practice then
            stage.group.PracticeStart(self.name)
        else
            stage.group.Start(self.group)
        end
        lstg.tmpvar.pause_menu_text = nil
        lstg.var.timeslow = nil
    end
end

stage.group.sc_pr_fast_retry = false
stage.group.sc_pr_auto_retry = false

function stage.group.frame_sc_pr(self)
    ext.sc_pr = true
    if not lstg.var.init_player_data then
        error('Player data has not been initialized. (Call function item.PlayerInit)')
    end
    if lstg.var.lifeleft <= -1 then
        if ext.replay.IsReplay() then
            ext.pop_pause_menu = true
            ext.rep_over = true
            lstg.tmpvar.pause_menu_text = { 'Replay Again', 'Return to Title', nil }
        elseif stage.group.sc_pr_auto_retry then
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
        stage.group.ReturnToTitle(false, 0)
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
        stage.group.ReturnToTitle(true, 0)
        lstg.tmpvar.pause_menu_text = nil
        lstg.tmpvar.death = true
        lstg.var.timeslow = nil
    end
end

function stage.group.render(self)
    ui.DrawFrame(self)
    if lstg.var.init_player_data then
        ui.DrawScore(self)
    end
    SetViewMode 'world'
    RenderClearViewMode(Color(255, 0, 0, 0))
end

function stage.group.Start(group)
    lstg.var.is_practice = false
    stage.Set(group[1], 'save')
    stage.stages[group.title].save_replay = { group[1] }
end

function stage.group.PracticeStart(stagename)
    lstg.var.is_practice = true
    stage.Set(stagename, 'save')
    stage.stages[stage.stages[stagename].group.title].save_replay = { stagename }
end

function stage.group.FinishStage()
    local self = stage.current_stage
    local group = self.group
    if self.number == group.number or lstg.var.is_practice then
        if ext.replay.IsReplay() then
            ext.rep_over = true
            ext.pop_pause_menu = true
            lstg.tmpvar.pause_menu_text = { 'Replay Again', 'Return to Title', nil }
        else
            if lstg.var.is_practice then
                stage.group.ReturnToTitle(true, 0)
            else
                stage.group.ReturnToTitle(true, 1)
            end
        end
    else
        if ext.replay.IsReplay() then
            -- 载入关卡并执行录像
            stage.Set(ext.replay.GetReplayStageName(ext.replay.GetCurrentReplayIdx() + 1),
                'load', ext.replay.GetReplayFilename())
        else
            -- 载入关卡并开始保存录像
            stage.Set(group[self.number + 1], 'save')
            if stage.stages[group.title].save_replay then
                table.insert(stage.stages[group.title].save_replay, group[self.number + 1])
            end
        end
    end
end

function stage.group.FinishReplay()
    local self = stage.current_stage
    local group = self.group
    if self.number == group.number or lstg.var.is_practice then
        if ext.replay.IsReplay() then
            ext.rep_over = true
            ext.pop_pause_menu = true
            lstg.tmpvar.pause_menu_text = { 'Replay Again', 'Return to Title', nil }
        end
    else
        if ext.replay.IsReplay() then
            -- 载入关卡并执行录像
            stage.Set(ext.replay.GetReplayStageName(ext.replay.GetCurrentReplayIdx() + 1),
                'load', ext.replay.GetReplayFilename())
        end
    end
end

function stage.group.GoToStage(number)
    local self = stage.current_stage
    local group = self.group
    number = number or self.number + 1
    if number > group.number or lstg.var.is_practice then
        if lstg.var.is_practice then
            stage.group.ReturnToTitle(true, 0)
        else
            stage.group.ReturnToTitle(true, 1)
        end
    else
        if ext.replay.IsReplay() then
            stage.Set(group[number], 'load', ext.replay.GetReplayFilename())
        else
            stage.Set(group[number], 'save')
            if stage.stages[group.title].save_replay then
                table.insert(stage.stages[group.title].save_replay, group[number])
            end
        end
    end
end

function stage.group.FinishGroup()
    stage.group.ReturnToTitle(true, 1)
end

function stage.group.ReturnToTitle(save_rep, finish)
    StopMusic(deathmusic)
    gamecontinueflag = false
    local self = stage.current_stage
    local title = stage.stages[self.group.title]
    title.finish = finish or 0
    if ext.replay.IsReplay() then
        title.save_replay = nil
    elseif not save_rep then
        title.save_replay = nil
        moveoverflag = true
    end
    stage.Set(self.group.title, 'none')
end

----------------------------------------
---编辑器封装

local function _fade_out_music()
    local _, bgm = EnumRes('bgm')
    for i = 1, 30 do
        for _,v in pairs(bgm) do
            if GetMusicState(v) == 'playing' then
                SetBGMVolume(v, 1 - i / 30)
            end
        end
        task.Wait(1)
    end
end

function stage.group.initTask(self, f)
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
        stage.group.FinishReplay()
        New(mask_fader, 'close')
        task.New(self, function()
            _fade_out_music()
        end)
        task.Wait(30)
        _stop_music()
        stage.group.FinishStage()
    end)
end

function stage.group.GoToStageTask(self, number, wait)
    local function f()
        New(mask_fader, 'close')
        task.New(self, function()
            _fade_out_music()
        end)
        task.Wait(30)
        _stop_music()
        stage.group.GoToStage(number)
    end
    if wait then
        f()
    else
        task.New(self, f)
    end
end

function stage.group.FinishGroupTask(self, wait)
    local function f()
        New(mask_fader,'close')
        task.New(self, function()
            _fade_out_music()
        end)
        task.Wait(30)
        _stop_music()
        stage.group.FinishGroup()
    end
    if wait then
        f()
    else
        task.New(self, f)
    end
end

----------------------------------------
---示例代码

-- stage.group.New('menu', {}, "Normal", {lifeleft=2,power=400,bomb=2}, true, 4)
-- stage.group.AddStage('Normal', 'Stage 1@Normal', {lifeleft=8,power=400,bomb=8}, true)
-- stage.group.DefStageFunc('Stage 1@Normal', 'init', function(self)
--     stage.group.initTask(self, function()
--         New(temple_background)
--         task.Wait(60)
--     end)
-- end)
