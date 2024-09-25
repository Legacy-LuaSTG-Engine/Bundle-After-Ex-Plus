---高精度计时器
---@class lstg.StopWatch
---@return lstg.StopWatch
local StopWatch = plus.Class()


---初始化函数
function StopWatch:init()
    self:Reset()
end
---重置计时器
function StopWatch:Reset()
    self._pause = {}
    self._resume = {}
    self.time = os.clock()
    self._is_paused = false
end
---暂停计时器
function StopWatch:Pause()
    if self._is_paused then
        return
    end
    self._is_paused = true
    table.insert(self._pause, os.clock())
end
---恢复计时器
function StopWatch:Resume()
    if not (self._is_paused) then
        return
    end
    self._is_paused = false
    table.insert(self._resume, os.clock())
end
---获取当前相对时间戳
function StopWatch:GetElapsed()
    local t = os.clock()
    local ot = self.time
    local pt = 0
    local n = #self._pause
    if self._is_paused then
        t = self._pause[n]
        n = n - 1
    end
    for i = 1, n do
        pt = pt + (self._resume[i] - self._pause[i])
    end
    t = t - ot - pt
    return t
end

local function matchVar(list, var)
    for _, v in ipairs(list) do
        if v == var then
            return true
        end
    end
    return false
end

local CardsSystem = plus.Class()
boss._cards_system = CardsSystem
---@param system boss.system @要执行符卡组的boss挂载系统
---@param cards table @默认符卡表
---@param is_final boolean @是否执行完删除boss
function CardsSystem:init(system, cards, is_final)
    if is_final == nil then
        is_final = true
    end
    self.system = system
    self.is_finish = false
    self.is_final = is_final
    local b = self.system.boss
    b.cards = cards or {}
    b.card_num = 0
    b.sc_left = 0
    b.last_card = 0
    for i = 1, #b.cards do
        if b.cards[i].is_combat then
            b.last_card = i
        end
        if b.cards[i].is_sc then
            b.sc_left = b.sc_left + 1
        end
    end
    self:next()
end

---执行符卡
---@param card boss.card @要执行的符卡
---@param mode number @血条样式
---@param final boolean @是否为终符
function CardsSystem:doCard(card, mode, final)
    self.system:doCard(card, mode, final and self.is_final)
end

---执行下一张符卡
function CardsSystem:next()
    local b = self.system.boss
    b.card_num = b.card_num + 1
    if not (b.cards[b.card_num]) then
        self.is_finish = true
        return false
    end
    local mode
    if not b.__hpbartype2 then
        local last, now, next
        for n = b.card_num - 1, 1, -1 do
            if b.cards[n] and b.cards[n].is_combat then
                last = b.cards[n]
                break
            end
        end
        now = b.cards[b.card_num]
        for n = b.card_num + 1, #b.cards do
            if b.cards[n] and b.cards[n].is_combat then
                next = b.cards[n]
                break
            end
        end
        if now.is_sc then
            if last and last.is_sc then
                mode = 0
            elseif last and not (last.is_sc) then
                if (last.t1 ~= last.t3) then
                    mode = 2
                else
                    mode = 0
                end
            elseif not (last) then
                mode = 0
            end
        elseif not (now.is_sc) then
            if next and next.is_sc then
                if (next.t1 ~= next.t3) then
                    mode = 1
                else
                    mode = 0
                end
            elseif next and not (next.is_sc) then
                mode = 3
            elseif not (next) then
                mode = 3
            end
        end
        if now.t1 == now.t3 then
            mode = -1
        end
    else
        local last, last2, last3, now, next, next2, next3, temp, flag
        local flag1 = b.__hpbartype2 % 10
        --local flag2=int(b.__hpbartype2/10)
        --b.__hpbartype2=nil -->去你妹的共用血条，我要使用旧版血条
        --b.__hpbartype2=x1 -->除了终符使用独立血条，其余使用三段共用血条
        --b.__hpbartype2=x2 -->无论如何都使用三段共用血条
        --b.__hpbartype2=x3 -->无论如何都不使用三段共用血条
        --b.__hpbartype2=1x -->庙城传璋血条
        --b.__hpbartype2=2x -->预留位
        --b.__hpbartype2=3x -->报错警告
        --GET LAST
        flag = false
        for n = b.card_num - 1, 1, -1 do
            if b.cards[n] and b.cards[n].is_combat then
                last = b.cards[n]
                temp = n
                flag = true
                break
            end
        end
        --GET LAST2
        if flag then
            flag = false
            for n = temp - 1, 1, -1 do
                if b.cards[n] and b.cards[n].is_combat then
                    last2 = b.cards[n]
                    temp = n
                    flag = true
                    break
                end
            end
        end
        --GET LAST3
        if flag then
            for n = temp - 1, 1, -1 do
                if b.cards[n] and b.cards[n].is_combat then
                    last3 = b.cards[n]
                    break
                end
            end
        end
        --GET NOW
        now = b.cards[b.card_num]
        flag = false
        --GET NEXT
        for n = b.card_num + 1, #b.cards do
            if b.cards[n] and b.cards[n].is_combat then
                next = b.cards[n]
                temp = n
                flag = true
                break
            end
        end
        --GET NEXT2
        if flag then
            flag = false
            for n = temp + 1, #b.cards do
                if b.cards[n] and b.cards[n].is_combat then
                    next2 = b.cards[n]
                    temp = n
                    flag = true
                    break
                end
            end

        end
        --GET NEXT3
        if flag then
            for n = temp + 1, #b.cards do
                if b.cards[n] and b.cards[n].is_combat then
                    next3 = b.cards[n]
                    break
                end
            end
        end
        --START!!
        local IsAllowNSS = false
        local IsAllowFinalNSS = false
        if flag1 ~= 3 then
            IsAllowNSS = true
            if flag1 == 1 then
                IsAllowFinalNSS = false
            else
                IsAllowFinalNSS = true
            end
        end

        if now.is_sc then
            if last and last.is_sc then
                mode = 0
                if last.t1 ~= last.t3 then
                    if IsAllowNSS then
                        if (next or ((not next) and IsAllowFinalNSS)) then
                            if last2 and not last2.is_sc and ((not last3) or last3.is_sc) then
                                mode = 2
                            end
                        end
                    end
                end
            elseif last and not (last.is_sc) then
                if (last.t1 ~= last.t3) then
                    mode = 2
                    if IsAllowNSS then
                        if (next2 or ((not next2) and IsAllowFinalNSS)) then
                            if next and next.is_sc and next.t1 ~= next.t3 and ((not last2) or last2.is_sc) then
                                mode = 4
                            end
                        end
                    end
                else
                    mode = 0
                end
            else
                mode = 0
            end
        elseif not (now.is_sc) then
            if next and next.is_sc then
                if (next.t1 ~= next.t3) then
                    mode = 1
                    if IsAllowNSS then
                        if ((not last) or (not last.is_combat) or (last.is_sc)) then
                            if (next3 or ((not next3) and IsAllowFinalNSS)) then
                                if next2 and next2.is_sc and next2.t1 ~= next2.t3 then
                                    mode = 5
                                end
                            end
                        else
                            if ((not last2) or (not last2.is_combat) or (last2.is_sc)) then
                                if (next2 or ((not next2) and IsAllowFinalNSS)) then
                                    mode = 6
                                end
                            end
                        end
                    end
                else
                    mode = 3
                end
            elseif next and not (next.is_sc) then
                mode = 3
                if IsAllowNSS then
                    if (next3 or ((not next3) and IsAllowFinalNSS)) then
                        if next.t1 ~= next.t3 and ((not last) or (not last.is_combat) or (last.is_sc)) and next2 and next2.is_sc and next2.t1 ~= next2.t3 then
                            mode = 7
                        end
                    end
                end
            elseif not next then
                mode = 3
            end
        end
        if now.t1 == now.t3 then
            mode = -1
        end
    end
    self:doCard(b.cards[b.card_num], mode, b.card_num == b.last_card)
    return true
end

---@class boss.system
---@return boss.system
boss.system = plus.Class()
local system = boss.system

---boss系统初始化函数
---@param b object @目标boss
---@param name string @boss显示名
---@param cards table|nil @目标执行符卡组（可不设置）
---@param bg object|nil @boss符卡背景（可不设置）
---@param diff string @难度信息
function system:init(b, name, cards, bg, diff)
    self.boss = b
    b.name = name --显示名称
    b.bg = bg --符卡背景
    b.diff = diff --boss难度
    --boss魔法阵
    b.aura_alpha = 255 --法阵透明度
    b.aura_alpha_d = 4 --法阵透明度单帧变化值
    b.aura_scale = 1 --法阵大小比例
    --boss符卡环
    b.sc_ring_alpha = 255 --符卡环透明度
    --属性设置
    b.difficulty = diff or 'All' --boss难度
    b.dmg_factor = 0 --伤害比例（系统）
    b.DMG_factor = 1 --伤害比例（用户）
    b.sc_pro = 0 --符卡高防剩余帧数
    b.lifepoint = 160 --组合血条截断点
    b.hp_flag = 0 --血条透明度flag
    b.sp_point = {} --血条阶段点位置
    b._sp_point_auto = {} --血条阶段点位置
    b.sc_bonus_max = item.sc_bonus_max --boss符卡默认最高分
    b.sc_bonus_base = item.sc_bonus_base --boss符卡默认基础分
    b.t1, b.t2, b.t3 = 0, 0, 0 --boss阶段时间
    b.is_combat = false --是否为战斗阶段
    b.is_sc = false --当前是否为符卡
    b.sc_left = 0 --boss剩余符卡数
    b.spell_damage = 0
    b.__is_waiting = true --boss是否在等待操作
    b.__hpbartype = -1 --boss血条样式
    b.__hpbartype2 = nil --boss血条样式2
    --b.__hpbartype2=nil -->去你妹的共用血条，我要使用旧版血条
    --b.__hpbartype2=x1 -->除了终符使用独立血条，其余使用三段共用血条
    --b.__hpbartype2=x2 -->无论如何都使用三段共用血条
    --b.__hpbartype2=x3 -->无论如何都不使用三段共用血条
    --b.__hpbartype2=1x -->庙城传璋血条
    --b.__hpbartype2=2x -->预留位
    --b.__hpbartype2=3x -->报错警告
    b.__c0 = Color(0xFF000000)        --底色，默认黑
    b.__c1 = Color(0xFFFFFFFF)        --一非色
    b.__c2 = Color(0xFFFF8080)        --一卡色
    b.__c3 = Color(0xFFC0C0C0)        --二非色
    b.__c4 = Color(0xFFFFC0C0)        --二卡色
    b.__card_timer = 0 --阶段已进行时长
    b.__hpbar_timer = 0 --血条计时器
    b.__hpbar_rendertime = 60 --血条填满时间
    b.__hpbar_defaultvalue = 1200 --符卡血条标准HP
    b.__hpbar_defaultpercent = 0.15 --符卡血条标准HP时占圆比例
    b.__rescore = 0 --符卡分数每帧损失量
    b.__rescore_wait = 300 --符卡分数滑落等待时间
    b.__dieinstantly = false --true时终符结束立刻爆炸
    b.__disallow_100sec = false --true时倒计时显示不超过99.99
    b.ui = New(boss.ui, self, b)
    b.ui_slot = 1
    self.aura = boss.aura(self)
    self.sc_ring = boss.card.drawSpellCircle
    self:resetBonus() --重置bonus
    self.clock = StopWatch()
    if cards then
        self:doCards(cards)
    end
end

---boss系统帧逻辑
function system:frame()
    --执行自身task
    local b = self.boss
    b.__card_timer = b.__card_timer + 1 --更新阶段计时器
    self:checkHP() --检查血量
    self:checkAutoSPPoint() --检查auto阶段点
    self:doTask() --执行task
    self:updateHPFlags() --更新血条flag
    --出屏判定关闭
    local bound = BoxCheck(b, lstg.world.boundl, lstg.world.boundr, lstg.world.boundb, lstg.world.boundt)
    SetAttr(b, 'colli', bound and b._colli)
    self:updatePosition() --更新位置指示器
    self:updateBG() --更新符卡背景
    --魔法阵透明度更新
    b.aura_alpha = b.aura_alpha + b.aura_alpha_d
    b.aura_alpha = min(max(0, b.aura_alpha), 128)
    if self.aura then
        self.aura:frame()
    end
    if b.hp < 1145141919810 then
        b.hpbarlen = b.hp / b.maxhp --更新血条长度
    else
        b.hpbarlen = 0
    end
    --符卡逻辑
    if b.current_card then
        b.current_card.frame(b)
    end
    --阶段逻辑
    if not (b.__is_waiting) and b.is_combat then
        --高防时间计算
        b.sc_pro = max(b.sc_pro - 1, 0)
        local players
        local nsp = 0
        if Players then
            players = Players(b)
        else
            players = { player }
        end
        for _, p in pairs(players) do
            if p.nextspell > nsp then
                nsp = p.nextspell
            end
        end
        if nsp > 0 and b.timer <= 0 then
            b.sc_pro = nsp
        end
        --系统伤害比率运算
        if b.timer < b.t1 then
            b.dmg_factor = 0
        elseif b.sc_pro > 0 then
            b.dmg_factor = min(0.1, (b.timer - b.t1) / (b.t2 - b.t1))
        elseif b.timer < b.t2 then
            b.dmg_factor = (b.timer - b.t1) / (b.t2 - b.t1)
        elseif b.timer < b.t3 then
            b.dmg_factor = 1
        else
            b.hp = 0
            b.timeout = true
        end
        --是否为耐久阶段
        if b.t1 == b.t3 then
            b.dmg_factor = 0
            b.time_sc = true
        else
            b.time_sc = false
        end
        --分数流失
        if b.sc_bonus then
            b.sc_bonus = b.sc_bonus - b.__rescore
        end
        --自机spell保护
        if b.is_extra and nsp > 0 then
            b.dmg_factor = 0
        end
        b.countdown = (b.t3 - b.timer) / 60
        if IsValid(b.ui) then
            b.ui.countdown = (b.t3 - b.timer) / 60
        end
        self:checkBonus()
    else
        b.dmg_factor = 0
        b.DMG_factor = 1
        b.time_sc = false
        b.sc_pro = 0
        b.countdown = 0
        if IsValid(b.ui) then
            b.ui.countdown = b.t3
        end
        b.dropitem = nil
        self:clearBonus("all")
    end
end

---boss系统渲染逻辑
function system:render()
    local b = self.boss
    if self.aura then
        self.aura:render()
    end
    if self.sc_ring then
        self.sc_ring(b)
    end
    --符卡逻辑
    if b.current_card then
        b.current_card.render(b)
    end
end

---boss系统击破结算逻辑
function system:kill()
    self.is_killing = true
    local b = self.boss
    if b.is_combat and b.ui then
        b.ui.drawtimesaver = b.countdown
    end
    if b.timeout and not (b.time_sc) then
        self:clearBonus("all")
    end
    --符卡逻辑
    local card = b.current_card
    if card and card.beforedel then
        PreserveObject(b)
        task.Clear(b)
        task.Clear(self)
        task.New(self, function()
            local t = task.New(b, function()
                card.beforedel(b)
            end)
            while coroutine.status(t) ~= 'dead' do
                task.Wait()
            end
            self:kill_part2()
        end)
        task.Do(self)
    else
        self:kill_part2()
    end
end

function system:kill_part2()
    local b = self.boss
    local card = b.current_card
    if card then
        card.del(b)
    end
    if b.__card_finish then
        b.__card_finish(b)
        b.__card_finish = nil
    end
    self:refresh(1)
    if b.is_final and not (b.no_killeff) and not (b.killed) then
        if b.slowExplodeEffect then
            self:slow_explode()
        else
            self:explode()
        end
    else
        self:popSpellResult()
        if b.is_final then
            self:popResult(true)
            self:refresh(2)
            if card and card.after then
                task.New(b, function()
                    card.after(b)
                    Del(b)
                end)
                self:doTask()
            else
                Del(b)
            end
        else
            self:popResult(true)
            self:refresh(2)
            if card and card.after then
                task.New(b, function()
                    card.after(b)
                    task.Clear(b)
                    task.Clear(self)
                    if self._cards_system then
                        local ref = self._cards_system:next()
                        if not (ref) then
                            self._cards_system = nil
                        end
                    end
                end)
                self:doTask()
            else
                if self._cards_system then
                    local ref = self._cards_system:next()
                    if not (ref) then
                        self._cards_system = nil
                    end
                end
            end
        end
    end
end

---boss系统消亡逻辑
function system:del()
    local b = self.boss
    local unit = { b.ui, b.bg, b.dialog_displayer }
    if IsValid(b.bg) then
        b.bg.alpha = 0
    end
    if IsValid(lstg.tmpvar.bg) then
        lstg.tmpvar.bg.hide = false
    end
    for _, obj in pairs(unit) do
        if IsValid(obj) then
            Del(obj)
        end
    end
end

---设置bossUI槽位
---@param slot number @槽位
function system:setUISlot(slot)
    local b = self.boss
    b.ui_slot = slot
end

---boss爆炸自删
function system:explode()
    local b = self.boss
    local card = b.current_card
    local angle = ran:Float(-15, 15)
    local sign, v = ran:Sign(), 1.5
    b.is_exploding = true
    b.killed = true
    b.no_killeff = true
    PlaySound("enep01", 0.5)
    b._colli = false
    b.hp = 0
    b.lr = sign * 28
    b.vx = sign * v * cos(angle)
    b.vy = v * sin(angle)
    New(bullet_cleaner, b.x, b.y, 3000, 120, 60, true, true, 0)
    if b.protectPlayer then
        player.protect = 120
    end
    task.New(b, function()
        local lifetime, l
        if not b.__dieinstantly then
            for i = 1, 60 do
                v = v * 0.98
                b.vx = sign * v * cos(angle)
                b.vy = v * sin(angle)
                b.hp = 0
                b.timer = b.timer - 1
                lifetime = ran:Int(60, 90)
                l = ran:Float(100, 250)
                New(boss_death_ef_unit, b.x, b.y, l / lifetime, ran:Float(0, 360), lifetime, ran:Float(2, 3))
                task.Wait(1)
            end
        end
        PlaySound("enep01", 0.5, b.x / 256)
        New(deatheff, b.x, b.y, 'first')
        New(deatheff, b.x, b.y, 'second')
        New(boss_death_ef, b.x, b.y)
        self:popSpellResult()
        self:popResult(true)
        self:refresh(1)
        if card and card.after then
            task.New(b, function()
                card.after(b)
                Del(b)
            end)
            self:doTask()
        else
            Del(b)
        end
    end)
end

function system:slow_explode()
    local b = self.boss
    local card = b.current_card
    local clock = self.clock
    local angle = ran:Float(-15, 15)
    local sign, v = ran:Sign(), 1.5
    local lifetime, l
    b.is_exploding = true
    b.killed = true
    b.no_killeff = true
    PlaySound("enep01", 0.5)
    b._colli = false
    b.hp = 0
    b.lr = sign * 28
    b.vx = sign * v * cos(angle)
    b.vy = v * sin(angle)
    New(bullet_cleaner, b.x, b.y, 3000, 120, 60, true, true, 0)
    clock:Pause()
    lstg.var.timeslow = 4
    if b.protectPlayer then
        player.protect = 120
    end
    task.New(self, function()
        for i = 1, 60 do
            v = v * 0.98
            b.vx = sign * v * cos(angle)
            b.vy = v * sin(angle)
            b.hp = 0
            b.timer = b.timer - 1
            b.__card_timer = b.__card_timer - 1
            lifetime = ran:Int(60, 90)
            l = ran:Float(200, 500)
            New(boss_death_ef_unit, b.x, b.y, l / lifetime, ran:Float(0, 360), lifetime, ran:Float(2, 3))
            task.Wait(1)
        end
        PlaySound("enep01", 0.5, b.x / 256)
        New(deatheff, b.x, b.y, 'first')
        New(deatheff, b.x, b.y, 'second')
        New(boss_death_ef, b.x, b.y)
        misc.ShakeScreen(40, 24)
        clock:Resume()
        self:popSpellResult()
        self:popResult(true)
        self:refresh(1)
        if card and card.after then
            task.New(b, function()
                card.after(b)
                Del(b)
            end)
            self:doTask()
        else
            Del(b)
        end
        New(tasker, function()
            task.Wait(20)
            lstg.var.timeslow = 1
        end)
    end)
end

---执行task
function system:doTask()
    local b = self.boss
    task.Do(self)
    task.Do(b)
end

---检查血量
function system:checkHP()
    local b = self.boss
    b.hp = max(0, b.hp) --血量下限
    if b.hp <= 0 then
        if not (b.killed) and not (self.is_killing) then
            Kill(b)
        end
    end
end

---增加一个auto阶段点
---@param dmg number @目标损失血量
---@param timer number @目标计时器
---@param current boolean @是否使用真实帧数计时
function system:addAutoSPPoint(dmg, timer, current)
    local b = self.boss
    if b._sp_point_auto == nil then
        b._sp_point_auto = {}
    end
    local point = {
        dmg = dmg,
        timer = timer,
        current = current,
    }
    table.insert(b._sp_point_auto, point)
end

---检查auto阶段点
function system:checkAutoSPPoint()
    local b = self.boss
    local dmg = b.maxhp - b.hp
    local timer = b.timer
    local current_timer = b.__card_timer
    local p, _flag
    for i = #b._sp_point_auto, 1, -1 do
        p = b._sp_point_auto[i]
        if dmg >= p.dmg then
            _flag = true
        elseif p.current and current_timer >= p.timer then
            _flag = true
        elseif not (p.current) and timer >= p.timer then
            _flag = true
        end
        if _flag then
            table.remove(b._sp_point_auto, i)
        end
    end
end

---更新位置指示器
function system:updatePosition()
    local b = self.boss
    if IsValid(b.ui) then
        b.ui.pointer_x = b.x
    end
    b.pointer_x = b.x
end

---更新血条Flag
function system:updateHPFlags()
    local b = self.boss
    local mode, type
    if IsValid(b.ui) then
        local _ui = b.ui
        if not b.__hpbartype2 then
            if not (_ui.hpbarcolor1) and not (_ui.hpbarcolor2) then
                mode = -1 --无血条（时符等）
            elseif not (_ui.hpbarcolor2) then
                mode = 0
                type = 1 --全血条（符卡）
            elseif not (_ui.hpbarcolor1) then
                mode = 0
                type = 2 --全血条（非符）
            elseif _ui.hpbarcolor1 == _ui.hpbarcolor2 then
                mode = 2 --组合血条（符卡）
            elseif _ui.hpbarcolor1 ~= _ui.hpbarcolor2 then
                mode = 1 --组合血条（非符）
            end
        else
            if not _ui.hpbarcolor3 then
                if not (_ui.hpbarcolor1) and not (_ui.hpbarcolor2) then
                    mode = -1 --无血条（时符等）
                elseif not (_ui.hpbarcolor2) then
                    mode = 0
                    type = 1 --全血条（符卡）
                elseif not (_ui.hpbarcolor1) then
                    mode = 0
                    type = 2 --全血条（非符）（mode=3）
                elseif _ui.hpbarcolor1 == _ui.hpbarcolor2 then
                    mode = 2 --组合血条（符卡）
                elseif _ui.hpbarcolor1 ~= _ui.hpbarcolor2 then
                    mode = 1 --组合血条（非符）
                end
            else
                if not (_ui.hpbarcolor2) then
                    mode = 4    --non->'sp'->sp
                elseif not (_ui.hpbarcolor1) then
                    mode = 5    --'non'->sp->sp
                elseif _ui.hpbarcolor1 == _ui.hpbarcolor2 then
                    mode = 6    --non->'non'->sp
                elseif _ui.hpbarcolor1 ~= _ui.hpbarcolor2 then
                    mode = 7    --'non'->non->sp
                end
            end
        end
    else
        mode = b.__hpbartype
        type = 1
    end
    if not (b.__is_waiting) and mode ~= -1 then
        b.__hpbar_timer = b.__hpbar_timer + 1
        local players
        if Players then
            players = Players(b)
        else
            players = { player }
        end
        local _flag = false
        for _, p in pairs(players) do
            if IsValid(p) and Dist(p, b) <= 70 then
                _flag = true
                break
            end
        end
        if _flag then
            b.hp_flag = b.hp_flag + 1
        else
            b.hp_flag = b.hp_flag - 1
        end
        b.hp_flag = min(max(0, b.hp_flag), 18)
    else
        b.__hpbar_timer = -1
        b.hp_flag = 0
    end
end

---更新符卡背景
function system:updateBG()
    local b = self.boss
    if b.hp <= 0 then
        return
    end
    if b.bg then
        if IsValid(b.bg) then
            if b.__show_scbg then
                b.bg.alpha = min(1, b.bg.alpha + 0.025)
            else
                b.bg.alpha = max(0, b.bg.alpha - 0.025)
            end
        end
        if lstg.tmpvar.bg then
            if IsValid(b.bg) and b.bg.alpha == 1 then
                lstg.tmpvar.bg.hide = true
            else
                lstg.tmpvar.bg.hide = false
            end
        end
    end
end

---刷新bonus
function system:resetBonus()
    local b = self.boss
    b.chip_bonus = true
    b.bombchip_bonus = true
    b.sc_pro = player.nextspell
    if b.is_sc then
        self:setScore(b.sc_bonus_max)
    else
        self:setScore(nil)
    end
end

---移除bonus
---@param type string @取消类型
function system:clearBonus(type)
    local b = self.boss
    if type == "all" or type == nil then
        b.chip_bonus = false
        b.bombchip_bonus = false
    elseif type == "hit" then
        b.chip_bonus = false
    elseif type == "spell" then
        b.bombchip_bonus = false
    end
    if b.sc_bonus then
        b.sc_bonus = nil
    end
end

---检查bonus
function system:checkBonus()
    local b = self.boss
    local players
    if Players then
        players = Players(b)
    else
        players = { player }
    end
    local death, nsp = 0, 0
    for _, p in pairs(players) do
        if p.death > death then
            death = p.death
        end
        if p.nextspell > nsp then
            nsp = p.nextspell
        end
    end
    if death == 90 then
        self:clearBonus("hit")
    end
    if b.sc_pro <= 0 and nsp > 0 then
        self:clearBonus("spell")
    end
end

local time_rate = 1000 / (1000 / 60)
---符卡结算
function system:popSpellResult()
    local b = self.boss
    if b.chip_bonus and b.bombchip_bonus and b.sc_bonus then
        if b.hp <= 0 then
            b._getcard = true
            b._getscore = b.sc_bonus
        elseif b.timeout and b.time_sc then
            b._getcard = true
            b._getscore = b.sc_bonus
        else
            b._getcard = false
            b._getscore = 0
        end
        b._timer = b.timer
    else
        b._getcard = false
        b._getscore = nil
        b._timer = b.timer
        b._timeout = b.timeout
    end
    local t = self.clock:GetElapsed() * time_rate
    b._real_timer = t
    b.timeout = nil
    self:finishSpellHist(b._getcard)
    local c = {}
    c.finish = true --阶段是否已结束
    c.is_sc = b.is_sc --阶段是否为符卡
    c.sc_name = b.sc_name --阶段符卡名
    c.time_sc = b.time_sc --阶段是否为耐久
    c.getcard = b._getcard --阶段是否收取
    c.timeout = b._timeout --阶段是否超时
    c.score = b._getscore --阶段获取分数
    c.chip = { b.chip_bonus, b.bombchip_bonus } --阶段获取碎片
    c.timer = b._timer --阶段结束时timer
    c.current_timer = b.__card_timer --阶段结束时真实timer
    c.damage = b.spell_damage --阶段伤害总计
    c.real_timer = b._real_timer --真实系统时间
    if b._transport then
        --boss设置了这个表后会在阶段结束时传递阶段结果到这个表并断开连接
        for k, v in pairs(c) do
            b._transport[k] = v
        end
        b._transport = nil
    end
    if b.__getspellbonus then
        --结算bonus
        self:resultSpell(c)
        b.__getspellbonus = nil
    end
    b.spell_damage = 0
end

---创建一个符卡数据记录信息
---@param name string @符卡名称
---@param diff string @难度信息
---@param player string @自机信息
function system:startSpellHist(name, diff, player)
    diff = diff or "All"
    player = player or "All"
    local b = self.boss
    if scoredata.spell_card_hist == nil then
        scoredata.spell_card_hist = {}
    end
    local hist = scoredata.spell_card_hist
    if hist[diff] == nil then
        hist[diff] = {}
    end
    if hist[diff][name] == nil then
        hist[diff][name] = {}
    end
    if hist[diff][name][player] == nil then
        hist[diff][name][player] = { 0, 0 }
    end
    if not ext.replay.IsReplay() then
        hist[diff][name][player][2] = hist[diff][name][player][2] + 1
        SaveScoreData()
    end
    b.spellcard_hist = { name = name, diff = diff, player = player }
    b._sc_hist = hist[diff][name][player]
    if IsValid(b.ui) then
        b.ui.sc_hist = hist[diff][name][player]
    end
end

---结束符卡数据信息
---@param getcard boolean @是否收取符卡
function system:finishSpellHist(getcard)
    local b = self.boss
    if b.spellcard_hist then
        local hist = scoredata.spell_card_hist
        local name = b.spellcard_hist.name
        local diff = b.spellcard_hist.diff
        local player = b.spellcard_hist.player
        if getcard and not ext.replay.IsReplay() then
            hist[diff][name][player][1] = hist[diff][name][player][1] + 1
            SaveScoreData()
        end
        b.spellcard_hist = nil
    end
end

---刷新boss状态
---@param part number @阶段
function system:refresh(part)
    local b = self.boss
    PreserveObject(b)
    if not (part) or part == 1 then
        _kill_servants(b)
        task.Clear(self)
        task.Clear(b)
    end
    if not (part) or part == 2 then
        b.t1, b.t2, b.t3 = 0, 0, 0
        b.is_combat = false
        b.is_sc = false
        b.sp_point = {}
        b._sp_point_auto = {}
        b.__is_waiting = true
        b.__hpbartype = -1
        self.is_killing = false 
    end
end

---结算并重置状态以便执行下一阶段
---@param continue boolean @是否保留对象
function system:popResult(continue)
    local b = self.boss
    if b.dropitem then
        item.DropItem(b.x, b.y, b.dropitem)
        b.dropitem = nil
    end
    if b.is_sc then
        b.sc_left = max(0, b.sc_left - 1)
    end
    self:endChipBonus(b.x, b.y)
    self:setIsSpellcard(false)
    self:setSCName("")
    self:setIsWaiting(true)
    --结束符卡后是否需要清除子弹
    if b.no_clear_buller then
        b.no_clear_buller = nil
    elseif b.is_combat then
        PlaySound('enep02', 0.4, 0)
        local players
        if Players then
            players = Players(b)
        else
            players = { player }
        end
        for _, p in pairs(players) do
            New(bullet_killer, p.x, p.y, true)
        end
    end
    if b.is_final or not (continue) then
        Del(b)
    end
    if continue then
        self:setDamageRate(1)
        self:resetTimer()
        enemybase.init(b, 999999999)
        self:resetBonus()
    end
end

---结束bonus
---@param x number @道具生成坐标x
---@param y number @道具生成坐标y
function system:endChipBonus(x, y)
    local b = self.boss
    if not b.is_combat then
        return
    end
    if b.chip_bonus and b.bombchip_bonus then
        New(item_chip, x - 20, y)
        New(item_bombchip, x + 20, y)
    else
        if b.chip_bonus then
            New(item_chip, x, y)
        end
        if b.bombchip_bonus then
            New(item_bombchip, x, y)
        end
    end
end

---结算分数等
---@param info table @数据信息
function system:resultSpell(info)
    local th15yoffset = { 144, 88, 72 }
    local th14yoffset = { 112, 24, 8 }
    local yoffset = th14yoffset
    if self.boss.__resultType == "th15" then
        yoffset = th15yoffset
    end
    if info.is_sc then
        if info.getcard then
            local score = info.score - info.score % 10
            lstg.var.score = lstg.var.score + score
            PlaySound('cardget', 1.0, 0)
            New(hinter_bonus, 'hint.getbonus', 0.6, 0, yoffset[1], 15, 120, true, score)
            New(kill_timer, 0, yoffset[2], info.current_timer)
            New(kill_timer2, 0, yoffset[3], info.real_timer)
        else
            if info.timeout and not (info.time_sc) then
                PlaySound('fault', 1.0, 0)
            end
            New(hinter, 'hint.bonusfail', 0.6, 0, yoffset[1], 15, 120)
            New(kill_timer, 0, yoffset[2], info.current_timer)
            New(kill_timer2, 0, yoffset[3], info.real_timer)
        end
    end
end

---宣言符卡
---@param name string @符卡名
function system:castcard(name)
    local b = self.boss
    self:setIsSpellcard(true)
    self:setSCName(name)
    self:resetBonus()
    New(spell_card_ef)
    PlaySound('cat00', 0.5)
    b.card_timer = -1
    if IsValid(b._sc_name_obj) then
        Kill(b._sc_name_obj)
    end
    local last = New(boss.sc_name, b, name)
    b._sc_name_obj = last
    _connect(b, last, 0, true)
end

---设置血量
---@param maxhp number @最大血量
---@param hp number @血量
function system:setHP(maxhp, hp)
    hp = hp or maxhp
    local b = self.boss
    b.maxhp, b.hp = maxhp, hp
end

---设置血条类型
---@param mode number @血条样式(-1无血条，0完整，1非&符中的非，2非&符中的符, 3完整非)
function system:setHPBar(mode)
    local b = self.boss
    b.__hpbartype = mode
    local color1, color2 = Color(0xFFFF8080), Color(0xFFFFFFFF)
    if IsValid(b.ui) then
        if not b.__hpbartype2 or b.__hpbartype2 % 10 == 3 then
            if mode == -1 then
                b.ui.hpbarcolor1 = nil
                b.ui.hpbarcolor2 = nil
                b.ui.hpbarcolor3 = nil
            elseif mode == 0 then
                b.ui.hpbarcolor1 = color1
                b.ui.hpbarcolor2 = nil
                b.ui.hpbarcolor3 = nil
            elseif mode == 1 then
                b.ui.hpbarcolor1 = color1
                b.ui.hpbarcolor2 = color2
                b.ui.hpbarcolor3 = nil
            elseif mode == 2 then
                b.ui.hpbarcolor1 = color1
                b.ui.hpbarcolor2 = color1
                b.ui.hpbarcolor3 = nil
            elseif mode == 3 then
                b.ui.hpbarcolor1 = nil
                b.ui.hpbarcolor2 = color1
                b.ui.hpbarcolor3 = nil
            end
        else
            if mode == -1 then
                b.ui.hpbarcolor1 = nil
                b.ui.hpbarcolor2 = nil
                b.ui.hpbarcolor3 = nil
            elseif mode == 0 then
                b.ui.hpbarcolor1 = color1
                b.ui.hpbarcolor2 = nil
                b.ui.hpbarcolor3 = nil
            elseif mode == 1 then
                b.ui.hpbarcolor1 = color1
                b.ui.hpbarcolor2 = color2
                b.ui.hpbarcolor3 = nil
            elseif mode == 2 then
                b.ui.hpbarcolor1 = color1
                b.ui.hpbarcolor2 = color1
                b.ui.hpbarcolor3 = nil
            elseif mode == 3 then
                b.ui.hpbarcolor1 = nil
                b.ui.hpbarcolor2 = color1
                b.ui.hpbarcolor3 = nil
            elseif mode == 4 then
                b.ui.hpbarcolor1 = color1
                b.ui.hpbarcolor2 = nil
                b.ui.hpbarcolor3 = color1
            elseif mode == 5 then
                b.ui.hpbarcolor1 = nil
                b.ui.hpbarcolor2 = color1
                b.ui.hpbarcolor3 = color1
            elseif mode == 6 then
                b.ui.hpbarcolor1 = color1
                b.ui.hpbarcolor2 = color1
                b.ui.hpbarcolor3 = color1
            elseif mode == 7 then
                b.ui.hpbarcolor1 = color1
                b.ui.hpbarcolor2 = color2
                b.ui.hpbarcolor3 = color1
            end
        end
    end
end

---设置掉落物
---@param itemtable table @掉落物表
function system:setDropitem(itemtable)
    local b = self.boss
    b.dropitem = itemtable
end

---设置是否不吃雷
---@param is_extra boolean @是否免疫自机符卡
function system:setIsExtra(is_extra)
    local b = self.boss
    b.is_extra = is_extra
end

---设置是否是最后阶段
---@param is_final boolean @是否为最后一张
function system:setIsFinal(is_final)
    local b = self.boss
    b.is_final = is_final
end

---重置timer
function system:resetTimer()
    local b = self.boss
    b.timer = -1
    b.__card_timer = 0
    b.__hpbar_timer = 0
    self.clock:Reset()
end

---设置阶段时间
---@param t1 number @无敌时间
---@param t2 number @防御时间
---@param t3 number @总时间
function system:setStatusTime(t1, t2, t3)
    local b = self.boss
    if t1 > t2 or t2 > t3 then
        error('t1<=t2<=t3 must be satisfied.')
    end
    b.t1, b.t2, b.t3 = int(t1) * 60, int(t2) * 60, int(t3) * 60
end

---设置是否为符卡
---@param is_sc boolean @是否为符卡
function system:setIsSpellcard(is_sc)
    local b = self.boss
    b.is_sc = is_sc
end

---设置是否为战斗阶段
---@param is_combat boolean @是否为战斗阶段
function system:setIsCombat(is_combat)
    local b = self.boss
    b.is_combat = is_combat
end

---设置是否在等待阶段
---@param is_waiting boolean @是否为等待阶段
function system:setIsWaiting(is_waiting)
    local b = self.boss
    b.__is_waiting = is_waiting
end

---设置是否显示符卡背景
---@param open boolean @是否显示符卡背景
function system:openSCBackground(open)
    local b = self.boss
    b.__show_scbg = open
end

---设置是否显示符卡环
---@param open boolean @是否显示符卡环
function system:openSCRing(open)
    local b = self.boss
    b.__draw_sc_ring = open
end

---设置是否有结算bonus
---@param open boolean @是否结算bonus
function system:openSCBonus(open)
    local b = self.boss
    b.__getspellbonus = open
end

---设置符卡名
---@param name string @符卡名
function system:setSCName(name)
    local b = self.boss
    b.sc_name = name
    if IsValid(b.ui) then
        b.ui.sc_name = name
    end
end

---设置符卡分数
---@param score number @符卡分数
---@param rescore number @符卡分数每帧损失量
function system:setScore(score, rescore)
    local b = self.boss
    self:setCurScore(score)
    self:setScoreMiss(rescore)
end

---设置当前符卡分数
---@param score number @符卡分数
function system:setCurScore(score)
    local b = self.boss
    b.sc_bonus = score
end

---设置符卡分数滑落速度
---@param rescore number @符卡分数每帧损失量
function system:setScoreMiss(rescore)
    local b = self.boss
    b.__rescore = rescore or 0
end

---设置符卡分数滑落等待时长
---@param t number @等待时长
function system:setScoreWait(t)
    local b = self.boss
    b.__rescore_wait = int(t)
end

---设置伤害比率
---@param rate number @伤害比率
function system:setDamageRate(rate)
    local b = self.boss
    b.DMG_factor = rate or 1
end

---设置属性
---@param maxhp number @最大生命值
---@param bartype number @血条样式
---@param dropitem table @掉落物
---@param is_extra boolean @是否免疫自机符卡
---@param is_final boolean @是否为最后一张
---@param ret boolean @是否重置timer
---@param t1 number @无敌时间
---@param t2 number @防御时间
---@param t3 number @总时间
---@param is_sc boolean @是否为符卡
---@param sc_bg boolean @是否渲染符卡背景
---@param sc_ring boolean @是否渲染符卡环
function system:setStatus(maxhp, bartype, dropitem, is_extra, is_final, ret, t1, t2, t3, is_sc, sc_bg, sc_ring)
    if sc_bg == nil then
        sc_bg = is_sc
    end
    if sc_ring == nil then
        sc_ring = is_sc
    end
    local b = self.boss
    self:setHP(maxhp)
    self:setHPBar(bartype)
    self:setDropitem(dropitem)
    self:resetBonus()
    self:setIsExtra(is_extra)
    self:setIsFinal(is_final)
    if ret then
        self:resetTimer()
    end
    self:setStatusTime(t1, t2, t3)
    self:setIsSpellcard(is_sc)
    self:setIsCombat(true)
    self:setIsWaiting(false)
    self:openSCBackground(sc_bg)
    self:openSCRing(sc_ring)
    b.countdown = b.t3
    if IsValid(b.ui) then
        b.ui.countdown = b.t3
    end
end

---执行符卡
---@param card boss.card @要执行的符卡
---@param bartype number @血条样式
---@param is_final boolean @是否为最后一张
---@param sc_bg boolean @是否渲染符卡背景
---@param sc_ring boolean @是否渲染符卡环
---@param score boolean @是否有score
---@param sc_bonus boolean @是否有符卡奖励结算
function system:doCard(card, bartype, is_final, sc_bg, sc_ring, score, sc_bonus)
    local b = self.boss
    if score == nil then
        score = card.is_sc
    end
    if sc_bonus == nil then
        sc_bonus = card.is_sc
    end
    b.current_card = card
    task.New(self, function()
        local t
        if card.before then
            t = task.New(b, function()
                card.before(b)
            end)
            while coroutine.status(t) ~= 'dead' do
                task.Wait()
            end
        end
        if card.is_sc then
            self:castcard(card.name)
            if score then
                self:startSpellHist(card.name, b.diff, lstg.var.player_name)
                task.New(self, function()
                    local t = b.__rescore_wait
                    task.Wait(t)
                    if b.sc_bonus ~= nil then
                        self:setScore(b.sc_bonus_max)
                    end
                    if card.t1 ~= card.t3 then
                        self:setScoreMiss((b.sc_bonus_max - b.sc_bonus_base) / (card.t3 - t))
                    end
                end)
            end
            self:openSCBonus(sc_bonus)
        end
        self:setStatus(card.hp, bartype, card.drop, card.is_extra, is_final, true,
                card.t1 / 60, card.t2 / 60, card.t3 / 60, card.is_sc, sc_bg, sc_ring)
        self:setIsCombat(card.is_combat)
        card.init(b)
    end)
end

---执行符卡组
---@param cards table @要执行的符卡组
---@param is_final boolean @是否执行完删除boss
function system:doCards(cards, is_final)
    local b = self.boss
    self._cards_system = CardsSystem(self, cards, is_final)
end