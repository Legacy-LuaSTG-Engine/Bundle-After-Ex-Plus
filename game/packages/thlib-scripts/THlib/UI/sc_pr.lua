-- boss 练习场景

-- _sc_table = { boss_class, scene_name, scene_class, scene_index, include_previous_scene }

local function getBossClass()
	if lstg.var.sc_index and lstg.var.sc_index > 0 then
		return _editor_class[_sc_table[lstg.var.sc_index][1]]
	elseif lstg.var.sc_pr_data then
		return _editor_class[lstg.var.sc_pr_data.class_name]
	else
		error("unknown error")
	end
end

local function getBossScene()
	if lstg.var.sc_index and lstg.var.sc_index > 0 then
		return _sc_table[lstg.var.sc_index][3]
	elseif lstg.var.sc_pr_data then
		local boss_class = _editor_class[lstg.var.sc_pr_data.class_name]
		return boss_class.cards[lstg.var.sc_pr_data.scene_index]
	else
		error("unknown error")
	end
end

local function isBossSceneIncludePrevious()
	if lstg.var.sc_index and lstg.var.sc_index > 0 then
		return _sc_table[lstg.var.sc_index][5]
	elseif lstg.var.sc_pr_data then
		return lstg.var.sc_pr_data.include_previous
	else
		return false
	end
end

local function getPreviousBossScene()
	if lstg.var.sc_index and lstg.var.sc_index > 0 then
		local boss_class = _editor_class[_sc_table[lstg.var.sc_index][1]]
		return boss_class.cards[_sc_table[lstg.var.sc_index][4] - 1]
	elseif lstg.var.sc_pr_data then
		local boss_class = _editor_class[lstg.var.sc_pr_data.class_name]
		return boss_class.cards[lstg.var.sc_pr_data.scene_index - 1]
	else
		error("unknown error")
	end
end

stage.group.New("Spell Practice", "menu", { lifeleft = 0, power = 400, faith = 50000, bomb = 0 }, false)
local s = stage.group.AddStage('Spell Practice', 'Spell Practice@Spell Practice', { lifeleft = 0, power = 400, faith = 50000, bomb = 0 }, false)
s.sc_pr_stage = true
stage.group.DefStageFunc('Spell Practice@Spell Practice', 'init', function(self)
    _init_item(self)
    New(mask_fader, 'open')
    New(_G[lstg.var.player_name])
    task.New(self, function()
        local boss_class = getBossClass()
		local boss_scene = getBossScene()
        do
            if boss_class.bgm ~= "" then
                LoadMusicRecord(boss_class.bgm)
            else
                LoadMusicRecord('spellcard')
            end
            if boss_class._bg ~= nil then
                New(boss_class._bg)
            else
                New(temple_background or default_stage_background)
            end
        end
        task._Wait(30)
        local _, bgm = EnumRes('bgm')
        for _, v in pairs(bgm) do
            if GetMusicState(v) ~= 'stopped' then
                ResumeMusic(v)
            else
                if boss_class.bgm ~= "" then
                    _play_music(boss_class.bgm)
                else
                    _play_music("spellcard")
                end
            end
        end
        local _boss_wait = true
        local _ref
        if isBossSceneIncludePrevious() then
            _ref = New(boss_class, {
                getPreviousBossScene(),
                boss_scene,
            })
            last = _ref
        else
            _ref = New(boss_class, {
                boss.move.New(0, 144, 60, MOVE_DECEL),
                boss_scene,
            })
            last = _ref
        end
        if _boss_wait then
            while IsValid(_ref) do
                task.Wait()
            end
        end
        task._Wait(150)
        if ext.replay.IsReplay() then
            ext.pop_pause_menu = true
            ext.rep_over = true
            lstg.tmpvar.pause_menu_text = { 'Replay Again', 'Return to Title', nil }
        else
            ext.pop_pause_menu = true
            lstg.tmpvar.death = false
            lstg.tmpvar.pause_menu_text = { 'Continue', 'Quit and Save Replay', 'Return to Title' }
        end
        task._Wait(60)
    end)
    task.New(self, function()
        while coroutine.status(self.task[1]) ~= 'dead' do
            task.Wait()
        end
        New(mask_fader, 'close')
        _stop_music()
        task.Wait(30)
        stage.group.FinishStage()
    end)
end)
stage.group.DefStageFunc('Spell Practice@Spell Practice', 'frame', stage.group.frame_sc_pr)
