--将debug信息存入lstg.var以便rep存取
lstg.var._boss_class_name = _boss_class_name
lstg.var._boss_class_sc_index = _boss_class_sc_index

local stage_init = stage.New('init', true, true)
function stage_init:init()
    menu_items = {}
    for i, v in ipairs(player_list) do
        table.insert(menu_items, { player_list[i][1], function()
            menu.FlyOut(menu_player_select, 'left')
            lstg.var.player_name = player_list[i][2]
            lstg.var.rep_player = player_list[i][3]
            task.New(stage_init, function()
                task.Wait(30)
                New(mask_fader, 'close')
                task.Wait(30)
                stage.group.PracticeStart('SC Debugger@SC Debugger')
            end)
        end })
    end
    menu_player_select = New(simple_menu, 'Select Player', menu_items)
    New(mask_fader, 'open')
    menu.FlyIn(menu_player_select, 'right')
end
function stage_init:render()
    ui.DrawMenuBG()
end

stage.group.New("SC Debugger", "menu", { lifeleft = 7, power = 400, faith = 50000, bomb = 2 }, false)
local s = stage.group.AddStage('SC Debugger', 'SC Debugger@SC Debugger', { lifeleft = 7, power = 400, faith = 50000, bomb = 2 }, false)
s.sc_pr_stage = true
stage.group.DefStageFunc('SC Debugger@SC Debugger', 'init', function(self)
    _init_item(self)
    New(mask_fader, 'open')
    New(_G[lstg.var.player_name])
    --取出lstg.var中记录的debug信息
    local _boss_class_name = lstg.var._boss_class_name
    local _boss_class_sc_index = lstg.var._boss_class_sc_index
    task.New(self, function()
        local musicname = "spellcard"
        do
            --LoadMusicRecord('spellcard')
            --by 青山 and OLC，提供符卡debug的背景和bossBGM支持
            if _editor_class[_boss_class_name].bgm ~= "" then
                LoadMusicRecord(_editor_class[_boss_class_name].bgm)
                musicname = _editor_class[_boss_class_name].bgm
            else
                LoadMusicRecord('spellcard')
            end
            if _editor_class[_boss_class_name]._bg ~= nil then
                New(_editor_class[_boss_class_name]._bg)
            else
                New(temple_background or default_stage_background)
            end
        end
        task._Wait(60)

        ----by 青山 and OLC，提供符卡debug的bossBGM支持
        local _, bgm = EnumRes('bgm')
        for _, v in pairs(bgm) do
            if GetMusicState(v) ~= 'stopped' then
                ResumeMusic(v)
            else
                _play_music(musicname)
            end
        end

        --local _boss_wait=true local _ref=New(_editor_class[_boss_class_name],_editor_class[_boss_class_name].cards) last=_ref
        --by OLC，提供符卡debug时执行前一个动作支持
        local debug_boss = _editor_class[_boss_class_name]
        local index = _boss_class_sc_index
        local cards = {}
        if index then
            local cur_card = debug_boss.cards[index]
            if cur_card.perform and debug_boss.cards[index - 1] then
                table.insert(cards, debug_boss.cards[index - 1])
            else
                table.insert(cards, boss.move.New(0, 144, 60, MOVE_DECEL))
            end
            table.insert(cards, cur_card)
        else
            cards = debug_boss.cards
        end

        local _boss_wait = true
        local _ref = New(debug_boss, cards)
        last = _ref
        if _boss_wait then
            while IsValid(_ref) do
                task.Wait(1)
            end
        end
        task._Wait(180)
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
stage.group.DefStageFunc('SC Debugger@SC Debugger', 'frame', stage.group.frame_sc_pr)
