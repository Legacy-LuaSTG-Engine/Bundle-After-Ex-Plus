--======================================
--th style boss system misc
--额外的函数
--======================================

----------------------------------------
--boss 额外函数
--！警告：新boss系统并未使用该部分代码

function boss:PopSpellResult(c)
    --boss行为结束逻辑，弹出提示文字、写入存档等
    if c.is_combat then
        self.spell_get = false
        if (self.hp <= 0 and self.timeout == 0) or (c.t1 == c.t3 and self.timeout == 1) then
            if c.drop then
                item.DropItem(self.x, self.y, c.drop)
            end
            item.EndChipBonus(self, self.x, self.y)
            if self.sc_bonus and not c.fake then
                if self.sc_bonus > 0 then
                    lstg.var.score = lstg.var.score + self.sc_bonus - self.sc_bonus % 10
                    PlaySound('cardget', 1.0, 0)
                    New(hinter_bonus, 'hint.getbonus', 0.6, 0, 112, 15, 120, true, self.sc_bonus - self.sc_bonus % 10)
                    New(kill_timer, 0, 30, self.timer)
                    if not ext.replay.IsReplay() then
                        scoredata.spell_card_hist[lstg.var.player_name][self.difficulty][c.name][1] = scoredata.spell_card_hist[lstg.var.player_name][self.difficulty][c.name][1] + 1
                        SaveScoreData()
                    end
                    self.spell_get = true
                else
                    New(hinter, 'hint.bonusfail', 0.6, 0, 112, 15, 120)
                    New(kill_timer, 0, 60, self.timer)
                end
            end
        else
            if c.is_sc and self.timeout == 1 then
                PlaySound('fault', 1.0, 0)
            end
            if self.sc_bonus then
                New(hinter, 'hint.bonusfail', 0.6, 0, 112, 15, 120, 15)
            end
        end
        self.spell_timeout = (self.timeout == 1)
        if self.no_clear_buller then
            --结束符卡后是否需要清除子弹
            self.no_clear_buller = nil
        else
            PlaySound('enep02', 0.4, 0)
            New(bullet_killer, player.x, player.y, true)
        end
    end
    if c.is_sc then
        self.ui.sc_left = self.ui.sc_left - 1
    end
end

function boss:explode(a)
    --boss死亡特效
    if a then
        self.killed = true
        self.no_killeff = true
        task.Clear(self)
        if self.ex then
            task.Clear(self.ex)
        end
        PlaySound("enep01", 0.5, self.x / 256)
        self.colli = false
        self.hp = 0
        self.lr = 28
        task.New(self, function()
            local angle = ran:Float(10, 20)
            self.vx = 0.3 * cos(angle)
            self.vy = 0.3 * sin(angle)
            New(bullet_cleaner, self.x, self.y, 1500, 120, 60, true, true, 0)
            for i = 1, 120 do
                self.hp = 0
                self.timer = self.timer - 1
                local lifetime = ran:Int(60, 90)
                local l = ran:Float(200, 500)
                New(boss_death_ef_unit, self.x, self.y, l / lifetime, ran:Float(0, 360), lifetime, ran:Float(2, 3))
                task.Wait(1)
            end
            PlaySound("enep01", 0.5, self.x / 256)
            New(deatheff, self.x, self.y, 'first')
            New(deatheff, self.x, self.y, 'second')
            Kill(self)
        end)
    else
        Kill(self)
    end
end

function boss:GetCurrentCard()
    --已整合进boss system，可能不再使用
    local c = self.current_card
    if not (c) and self.cards then
        c = self.cards[self.card_num]
    end
    if boss.ex and boss.ex.status == 1 then
        c = boss.ex.cards[boss.ex.nextcard]
    end
    return c
end

----------------------------------------
--boss ex
--！警告：一些boss ex逻辑代码从编辑器中生成，可能会造成逻辑梳理困难
--！警告：新boss系统并未对此部分进行适配

function boss:killex()
    if self.ex.status == 1 then
        local c = self.ex.cards[self.ex.nextcard]
        self.ex.lifes[self.ex.nextcard] = 0
        self.ex.nextcard = self.ex.nextcard - 1
        c.del(self)
        boss.PopSpellResult(self, c)
        PreserveObject(self)
        self.hp = 9999
        task.Clear(self)
        self.ex.status = 0
    else
        boss.del(self)
    end
end

function boss:prepareSpellCards(cardlist)
    if self.ex == nil then
        return
    end
    local a = self.ex
    while self.ex.status == 1 do
        task.Wait(1)
    end
    self.ex.lifes = {}
    self.ex.lifesmax = {}
    self.ex.modes = {}
    self.ex.cards = {}
    self.ex.timer = 0
    for i, v in pairs(cardlist) do
        local c = ex.GetCardObject(v)
        a.cards[i] = c
        a.lifes[i] = c.hp
        a.lifesmax[i] = c.hp
        if c.is_sc or c.fake then
            a.modes[i] = 1
        else
            a.modes[i] = 0
        end
    end
    a.nextcard = #cardlist
    a.cardcount = #cardlist
end

function boss:finishSpell(b)
    if self.ex == nil then
        return
    end
    if self.ex.status == 1 then
        if b then
            self.life = 0
        end
        self.life = 0
        Kill(self)
        task.Wait(1)
    end
end

function boss:finishSpellC(b)
    if self.ex == nil then
        return
    end
    if self.ex.status == 1 then
        self.ex.finish = 1
    end
end

function boss:castSpell(spellname, waitforend)
    if self.ex == nil then
        return
    end
    while self.ex.status == 1 do
        task.Wait(1)
    end

    local a = self.ex
    local c = 0
    if spellname == nil then
        c = a.cards[a.nextcard]
    else
        c = ex.GetCardObject(spellname)
    end
    if #a.cards == 0 or a.nextcard == 0 then
        --you have no card left in your hand, get one
        boss.prepareSpellCards(self, { spellname })
    end

    if a.cards[a.nextcard] ~= c then
        --you are using another card to replace your next prepared card
        local i = a.nextcard
        a.cards[i] = c
        a.lifes[i] = c.hp
        a.lifesmax[i] = c.hp
        if c.is_sc then
            a.modes[i] = 1
        else
            a.modes[i] = 0
        end
    end

    a.status = 1
    boss._castcard(self, c)
    if waitforend then
        while a.status == 1 do
            task.Wait(1)
        end
    end
end

function boss:_castcard(c)
    if c.is_sc then
        if not c.fake then
            self.sc_bonus = self.sc_bonus_max
        end

        --    self.ui.hpbarcolor=Color(0xFFFF8080)
        New(spell_card_ef)
        PlaySound('cat00', 0.5)
        if scoredata.spell_card_hist == nil then
            scoredata.spell_card_hist = {}
        end
        if scoredata.spell_card_hist[lstg.var.player_name] == nil then
            scoredata.spell_card_hist[lstg.var.player_name] = {}
        end
        if scoredata.spell_card_hist[lstg.var.player_name][self.difficulty] == nil then
            scoredata.spell_card_hist[lstg.var.player_name][self.difficulty] = {}
        end
        if scoredata.spell_card_hist[lstg.var.player_name][self.difficulty][c.name] == nil then
            scoredata.spell_card_hist[lstg.var.player_name][self.difficulty][c.name] = { 0, 0 }
        end
        if not ext.replay.IsReplay() then
            scoredata.spell_card_hist[lstg.var.player_name][self.difficulty][c.name][2] = scoredata.spell_card_hist[lstg.var.player_name][self.difficulty][c.name][2] + 1
            SaveScoreData()
        end
        self.ui.sc_hist = scoredata.spell_card_hist[lstg.var.player_name][self.difficulty][c.name]
    else
        if not c.fake then
            self.sc_bonus = nil
        end
    end
    if c.is_combat
    then
        item.StartChipBonus(self)
        self.spell_damage = 0
    end
    if c.name ~= '' then
        self.ui.sc_name = c.name
    end
    self.ui.countdown = c.t3 / 60
    self.ui.is_combat = c.is_combat
    task.Clear(self.ui)
    task.Clear(self)
    c.init(self)
    self.timer = -1
    self.hp = c.hp
    self.maxhp = c.hp
    self.dmg_factor = 0

    PreserveObject(self)
end
