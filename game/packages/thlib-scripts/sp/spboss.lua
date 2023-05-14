--[[
LuaSTG Special Plus 系 boss函数库
data by OLC
]]

if not (sp) then
    sp = {}
    sp.logfile = "userdata/sp_log.txt"
    do
        lstg.FileManager.CreateDirectory("userdata")
        local f = io.open(sp.logfile, 'w')
        f:close()
    end
    function sp.logWrite(str)
        local f = io.open(sp.logfile, 'a+')
        f:write(str .. "\n")
        f:close()
    end
end

--输出log至sp_log文件
local function _log(...)
    local list = { ... }
    for i, v in ipairs(list) do
        list[i] = tostring(v)
    end
    local str = table.concat(list, "\t")
    Print(str)
    sp.logWrite(str)
end

---@class sp.boss
local lib = {}
local SCREEN_SCALE = 1 --坐标系倍率，1为常规坐标系
sp.boss = lib

--以下为spboss正式定义
lib.list = { boss = {}, init = {}, card = {} }

_log(string.format("[spboss] Installing"))

---检查值是否存在于表内
---@param list table @检查表
---@param var any @目标值
---@return boolean / nil
local table_match = function(list, var)
    for k, v in pairs(list) do
        if v == var then
            return true
        end
    end
end

---定义spboss样式
---@param id string @样式编号
---@param name string @显示名称
---@param img string @行走图路径
---@param nCol number @纵向分割数
---@param nRow number @水平分割数
---@param a number @横向判定半径
---@param b number @纵向判定半径
---@param intv number @行走图更新间隔
---@param imgs table @每行图片数目
---@param anis table @动画循环帧数
---@param scbg string @符卡背景对象名称
function lib.define(id, name, img, nCol, nRow, a, b, intv, imgs, anis, scbg)
    lib.list.boss[id] = Class(lib.boss_default)
    lib.list.boss[id].id = id
    lib.list.init[id] = { name, img, nCol, nRow, a, b, intv, imgs, anis, scbg }
    lib.list.boss[id].init = function(self, id, x, y, slot)
        lib.boss_default.init(self, x, y, slot, scbg)
        if img ~= '' then
            self.nn, self.mm = imgs, anis
            local bossimg = img
            local number_n = {}
            for i = 1, nRow do
                number_n[i] = nCol
            end
            LoadTexture('anonymous:' .. bossimg, bossimg)
            local bosstexture_n, bosstexture_m = GetTextureSize('anonymous:' .. bossimg)
            local w, h = bosstexture_n / nCol, bosstexture_m / nRow
            for i = 1, nRow do
                LoadImageGroup('anonymous:' .. bossimg .. i, 'anonymous:' .. bossimg,
                        0, h * (i - 1), w, h, number_n[i], 1, a, b)
            end
            for i = 1, nRow do
                self['img' .. i] = {}
            end
            for i = 2, nRow do
                self['ani' .. i] = imgs[i] - anis[i - 1]
            end
            for i = 1, nRow do
                for j = 1, imgs[i] do
                    self['img' .. i][j] = 'anonymous:' .. bossimg .. i .. j
                end
            end
        end
        self.ani_intv = intv
        self.name = name
    end
end

---建立spboss
---@param id string @样式编号
---@param x number @生成坐标x
---@param y number @生成坐标y
---@param slot number @偏移槽位
---@return object
function lib.New(id, x, y, slot)
    return New(lib.list.boss[id], id, x, y, slot)
end

---默认spboss type定义
lib.boss_default = Class(enemybase)
---@param x number @生成坐标x
---@param y number @生成坐标y
---@param slot number @偏移槽位
---@param scbg string @符卡背景对象名称
function lib.boss_default:init(x, y, slot, scbg)
    _log(string.format("[spboss] Boss(%s) Creating ...", self))
    enemybase.init(self, 999999999)
    self.is_spboss = true
    self.bound = false
    self.x, self.y = x, y
    self.name = ''
    self.img = 'undefined'
    self.lr = 1
    self.cast = 0
    self.aura_alpha = 255
    self.aura_alpha_d = 4
    self.dmg_factor = 0
    self.DMG_factor = 1
    self.cast_t = 0
    self.sc_pro = 0
    self.lifepoint = 160
    self.hp_flag = 0
    self.sp_point = {}
    self.sc_bonus_max = item.sc_bonus_max
    self.sc_bonus_base = item.sc_bonus_base
    if scbg then
        self.bg = New(scbg)
    end
    self.aura = New(lib.aura, self)
    self.pointer = New(lib.pointer, self)
    self.ui = New(lib.ui, self)
    self.sub_list = {
        bg = self.bg,
        aura = self.scbg,
        pointer = self.pointer,
        ui = self.ui
    }
    lib.ResetBonus(self)
    self.is_finish = true
    self.hptimer = 0
    self.sc_left = 0
    self.sc_name = ''
    self.slot = slot or 0
    self.ui_dy = 36 * self.slot * SCREEN_SCALE
    self.ui_dy2 = 44 * self.slot * SCREEN_SCALE
    self.show_hp = false
    self.show_name = true
    self.show_scname = true
    self.cd_sound = true
    self.drawtime = true
    self.is_card = false
    self.t1, self.t2, self.t3 = 0, 0, 0
    self.card_timer = 0
    self._wisys = BossWalkImageSystem(self)
    _log(string.format("[spboss] Boss(%s) Created", self))
end
function lib.boss_default:frame()
    if not (self.is_finish) and table_match({ 0, 1, 2 }, self.hpbartype) then
        self.hptimer = self.hptimer + 1
        local players
        if Players then
            players = Players(self)
        else
            players = { player }
        end
        local _flag = false
        for i = 1, #players do
            if IsValid(players[i]) and Dist(players[i], self) <= 70 * SCREEN_SCALE then
                self.hp_flag = self.hp_flag + 1
                _flag = true
            end
        end
        if not _flag then
            self.hp_flag = self.hp_flag - 1
        end
        self.hp_flag = min(max(0, self.hp_flag), 18)
    else
        self.hptimer = -1
        self.hp_flag = 0
    end
    self.card_timer = self.card_timer + 1
    self.hp = max(0, self.hp)
    SetAttr(self, 'colli', BoxCheck(self, lstg.world.boundl, lstg.world.boundr, lstg.world.boundb, lstg.world.boundt) and self._colli)
    if self.hp <= 0 then
        if not (self.killed) then
            Kill(self)
        end
    end
    task.Do(self)
    local wisys = self._wisys
    if self.img4 then
        wisys.mode = 4
    elseif self.img3 then
        wisys.mode = 3
    elseif self.img2 then
        wisys.mode = 2
    elseif self.img1 then
        wisys.mode = 1
    else
        wisys.mode = 0
    end
    local dy_flag = (self.img4 and self.use_up_down_img)
    local obj, lv, rt = self, 2, 28
    local dx
    if dy_flag then
        dx = self.dy / SCREEN_SCALE
    else
        dx = self.dx / SCREEN_SCALE
    end
    if dx == nil then
        dx = obj.dx
    end
    if dx > 0.5 then
        dx = lv
    elseif dx < -0.5 then
        dx = -lv
    else
        dx = 0
    end
    obj.lr = obj.lr + dx
    if obj.lr > rt then
        obj.lr = rt
    end
    if obj.lr < -rt then
        obj.lr = -rt
    end
    if obj.lr == 0 then
        obj.lr = obj.lr + dx
    end
    if dx == 0 then
        if obj.lr > 1 then
            obj.lr = obj.lr - 1
        end
        if obj.lr < -1 then
            obj.lr = obj.lr + 1
        end
    end
    if self.cast_t > 0 then
        self.cast = self.cast + 1
    elseif self.cast_t < 0 then
        self.cast = 0
        self.cast_t = 0
    end
    if self.dx ~= 0 then
        self.cast = 0
        self.cast_t = 0
    end
    self.ani_intv = self.ani_intv or 8
    if BossWalkImageSystem['UpdateImage' .. wisys.mode] then
        BossWalkImageSystem['UpdateImage' .. wisys.mode](self)
    end
    if dy_flag then
        local scale = abs(self.hscale)
        self.hscale = sign(self.lr) * scale
    end
    if self.nextimg and #self.nextimg > 0 then
        if not (self._nextchanget) then
            self._nextchanget = self.ani_intv - (self.ani % self.ani_intv)
        end
        self._nextchanget = max(0, self._nextchanget - 1)
        if self._nextchanget <= 0 then
            self.img = self.nextimg[1]
            self._nextchanget = self.ani_intv
            self._ischangeimg = true
        end
        if self._nextchanget == 1 and self._ischangeimg then
            table.remove(self.nextimg, 1)
            if #self.nextimg == 0 then
                self.nextimg = nil
            end
            self._ischangeimg = false
        end
    end
    if type(self.A) == 'number' and type(self.B) == 'number' then
        self.a = self.A;
        self.b = self.B
    end
    if self.dmgt then
        self.dmgt = max(0, self.dmgt - 1)
    end
    self.pointer_x = self.x
    if self.bg and IsValid(self.bg) and not (self.no_scbg) then
        if self.is_card then
            self.bg.alpha = min(self.bg.alpha + 0.025, 1)
        else
            self.bg.alpha = max(self.bg.alpha - 0.025, 0)
        end
    end
    self.aura_alpha = self.aura_alpha + self.aura_alpha_d
    self.aura_alpha = min(max(0, self.aura_alpha), 128)
    self.hpbarlen = self.hp / self.maxhp
    if self.ex_card then
        self.ex_card.frame(self)
    end
    if self._card_system then
        self._card_system:frame(self)
    end
    if not (self.is_finish) and not (self.is_fake) then
        self.sc_pro = max(self.sc_pro - 1, 0)
        if player.nextspell > 0 and self.timer <= 0 then
            self.sc_pro = player.nextspell
        end
        if self.timer < self.t1 then
            self.dmg_factor = 0
        elseif self.sc_pro > 0 then
            self.dmg_factor = 0.1
        elseif self.timer < self.t2 then
            self.dmg_factor = (self.timer - self.t1) / (self.t2 - self.t1)
        elseif self.timer < self.t3 then
            self.dmg_factor = 1
        else
            self.hp = 0
            self.timeout = true
        end
        if self.t1 == self.t3 then
            self.dmg_factor = 0
            self.time_sc = true
        else
            self.time_sc = false
        end
        if self._flag then
            if self._flag.score and self.t1 ~= self.t3 and not (self.killed) then
                self._flag.score = self._flag.score - (self.sc_bonus_max - self.sc_bonus_base) / self.t3
            end
        end
        if self.is_extra and lstg.player.nextspell > 0 then
            self.dmg_factor = 0
        end
        self.countdown = (self.t3 - self.timer) / 60
        lib.CheckBonus(self)
    else
        self.dmg_factor = 0
        self.DMG_factor = 1
        self.time_sc = false
        self.sc_pro = 0
        self.countdown = 0
        lib.ClearBonus(self, "all")
        self.dropitem = nil
    end
end
function lib.boss_default:render()
    if self.ex_card then
        self.ex_card.render(self)
    end
    if self._card_system then
        self._card_system:render(self)
    end
    self._wisys:render(self.dmgt, self.dmgmaxt)
end
---@param dmg number @伤害值
function lib.boss_default:take_damage(dmg)
    if self.dmgmaxt then
        self.dmgt = self.dmgmaxt
    end
    if not (self.protect) and not (self.is_finish) then
        self.hp = self.hp - dmg * self.dmg_factor * self.DMG_factor
    end
    lstg.var.score = lstg.var.score + 10
end
function lib.boss_default:kill()
    _log(string.format("[spboss] Boss(%s) was killed", self))
    if self.timer > self.t3 and not (self.time_sc) then
        lib.ClearBonus(self, "all")
    end
    if self._task_finish then
        self._task_finish(self)
        self._task_finish = nil
    end
    if self.ex_card then
        self.ex_card.del(self)
    end
    if self._card_system then
        self._card_system:del(self)
    end
    lib.PopSpellResult(self)
    lib.Refresh(self, 1)
    if self.is_final and not (self.no_killeff) and not (self.killed) then
        lib.explode(self)
    else
        lib.Refresh(self, 2)
        lib.PopResult(self, true)
        if self._precards then
            self._predo = self._predo + 1
            lib.card.do_card(self, self._precards[self._predo], self._prehptype[self._predo], (self._predo == self._last_card))
        end
        if self._ex_cards then
            lib.ex_card.next(self)
        end
        if self._card_system then
            self._card_system:next(self)
        end
        _log(string.format("[spboss] Boss(%s) continue", self))
    end
end
function lib.boss_default:del()
    for k, v in pairs(self.sub_list) do
        if IsValid(v) then
            Del(v)
        end
    end
    _log(string.format("[spboss] Boss(%s) remove", self))
end
function lib.boss_default:show_aura(show)
    _log(string.format("[spboss] Boss(%s) Aura Show Mode Changed", self))
    if show then
        self.aura_alpha_d = 4
    else
        self.aura_alpha_d = -4
    end
end
function lib.boss_default:turn_aura(open)
    _log(string.format("[spboss] Boss(%s) Aura Show Mode Changed", self))
    if open then
        if IsValid(self.aura) then
            self.aura.show = true
        end
    else
        if IsValid(self.aura) then
            self.aura.show = false
        end
    end
end
---@param cast_t number @施法动作时长
function lib.boss_default:cast(cast_t)
    self.cast_t = cast_t + 0.5
    self.cast = 1
end
---@param blend string @blend mode
---@param a number @alpha
---@param r number @red
---@param g number @green
---@param b number @blue
function lib.boss_default:set_color(blend, a, r, g, b)
    _log(string.format("[spboss] Boss(%s) Color Set to %s ; %s ; %s ; %s ; %s", self, blend, a, r, g, b))
    self._blend, self._a, self._r, self._g, self._b = blend, a, r, g, b
end

---符卡结算
---@param boss object @spboss对象
function lib.PopSpellResult(boss)
    if boss._flag then
        if boss._flag.hit and boss._flag.spell and boss._flag.score then
            if boss.hp <= 0 then
                boss._getcard = true
                boss._getscore = boss._flag.score
            elseif boss.timeout and boss.time_sc then
                boss._getcard = true
                boss._getscore = boss._flag.score
            else
                boss._getcard = false
                boss._getscore = 0
            end
            boss._timer = boss.timer
        else
            boss._getcard = false
            boss._getscore = nil
            boss._timer = boss.timer
            boss._timeout = boss.timeout
        end
        boss.timeout = nil
        boss._flag = nil
        lib.FinishSpellHist(boss, boss._getcard)
    end
    local c = {}
    if boss._transport then
        boss._transport.finish = true
        boss._transport.is_sc = boss.is_card
        boss._transport.sc_name = boss.sc_name
        boss._transport.time_sc = boss.time_sc
        boss._transport.getcard = boss._getcard
        boss._transport.timeout = boss._timeout
        boss._transport.score = boss._getscore
        boss._transport.chip = boss.chip_bonus
        boss._transport.timer = boss._timer
        c = boss._transport
        boss._transport = nil
    end
    if boss._getspellbonus then
        lib.ResultSpell(c)
        boss._getspellbonus = nil
    end
    _log(string.format("[spboss] Boss(%s) got a result", boss))
end

---刷新boss状态
---@param boss object @spboss对象
---@param part number @阶段
function lib.Refresh(boss, part)
    PreserveObject(boss)
    if not (part) or part == 1 then
        lib.killconnect(boss)
        _kill_servants(boss)
        task.Clear(boss)
    end
    if not (part) or part == 2 then
        boss.t1, boss.t2, boss.t3 = 0, 0, 0
        boss.hpbartype = -1
        boss.sp_point = {}
        boss.is_fake = nil
        boss.ex_card = nil
    end
    _log(string.format("[spboss] Boss(%s) refresh part %s", boss, part or "ALL"))
end

---boss爆炸自删
---@param boss object @spboss对象
function lib.explode(boss)
    _log(string.format("[spboss] Boss(%s) explode", boss))
    boss.killed = true
    boss.no_killeff = true
    PlaySound("enep01", 0.5)
    boss._colli = false
    boss.hp = 0
    boss.lr = 28
    task.New(boss, function()
        local angle = ran:Float(-180, 180)
        boss.vx = 0.45 * cos(angle)
        boss.vy = 0.15 * sin(angle)
        New(bullet_cleaner, boss.x, boss.y, 1500, 120, 60, true, true, 0)
        for i = 1, 120 do
            boss.hp = 0
            boss.timer = boss.timer - 1
            local lifetime = ran:Int(60, 90)
            local l = ran:Float(200, 500)
            New(boss_death_ef_unit, boss.x, boss.y, l / lifetime, ran:Float(0, 360), lifetime, ran:Float(2, 3))
            task.Wait(1)
        end
        New(deatheff, boss.x, boss.y, 'first')
        New(deatheff, boss.x, boss.y, 'second')
        New(boss_death_ef, boss.x, boss.y)
        lib.PopResult(boss, false)
    end)
end

---结算并重置状态以便执行下一阶段
---@param boss object @spboss对象
---@param continue boolean @是否保留对象
function lib.PopResult(boss, continue)
    if boss.dropitem then
        item.DropItem(boss.x, boss.y, boss.dropitem)
        boss.dropitem = nil
    end
    lib.EndChipBonus(boss, boss.x, boss.y)
    boss.is_card = false
    boss.sc_name = ''
    boss.is_finish = true
    if boss.is_final or not (continue) then
        Del(boss)
    end
    if continue then
        if boss.is_card then
            boss.sc_left = max(0, boss.sc_left - 1)
        end
        boss.DMG_factor = 1
        boss.timer = -1
        boss.hptimer = -1
        boss.card_timer = -1
        enemybase.init(boss, 999999999)
        lib.ResetBonus(boss)
    end
    _log(string.format("[spboss] Boss(%s) finished a part", boss))
end

---宣言符卡
---@param boss object @spboss对象
---@param name string @符卡名
function lib.castcard(boss, name)
    _log(string.format("[spboss] Boss(%s) Cast Card %q", boss, name))
    boss.is_card = true
    boss.sc_name = name
    New(spell_card_ef)
    PlaySound('cat00', 0.5)
    boss.card_timer = -1
    if boss.show_scname then
        last = New(lib.sc_name, boss, name, boss.slot)
        _connect(boss, last, 0, true)
    end
    lib.ResetBonus(boss)
end

---切换符卡背景
---@param boss object @boss对象
---@param scbg string @目标符卡背景名
---@param follow boolean @是否跟随timer
function lib.change_scbg(boss, scbg, follow)
    if scbg == "nil" then
        if boss.bg and IsValid(boss.bg) then
            Del(boss.bg)
            boss.bg = nil
        end
        if IsValid(lstg.tmpvar.bg) then
            lstg.tmpvar.bg.hide = false
        end
    elseif scbg == "" then
        local t = 0
        local alpha = 0
        if boss.bg and IsValid(boss.bg) then
            alpha = boss.bg.alpha
            if follow then
                t = boss.bg.timer
            end
            Del(boss.bg)
        end
        boss.bg = New(default_spellcard_background)
        boss.bg.alpha = alpha
        if follow then
            for _ = 1, t do
                for _, l in ipairs(boss.bg.layers) do
                    l.x = l.x + l.vx
                    l.y = l.y + l.vy
                    l.rot = l.rot + l.omiga
                    l.timer = l.timer + 1
                    if l.frame then
                        l.frame(l)
                    end
                    if lstg.tmpvar.bg and lstg.tmpvar.bg.hide == true then
                        boss.bg.fxsize = min(boss.bg.fxsize + 2, 200)
                    else
                        boss.bg.fxsize = max(boss.bg.fxsize - 2, 0)
                    end
                end
            end
        end
    else
        local t = 0
        local alpha = 0
        if boss.bg and IsValid(boss.bg) then
            alpha = boss.bg.alpha
            if follow then
                t = boss.bg.timer
            end
            Del(boss.bg)
        end
        boss.bg = New(_editor_class[scbg])
        boss.bg.alpha = alpha
        if follow then
            for _ = 1, t do
                for _, l in ipairs(boss.bg.layers) do
                    l.x = l.x + l.vx
                    l.y = l.y + l.vy
                    l.rot = l.rot + l.omiga
                    l.timer = l.timer + 1
                    if l.frame then
                        l.frame(l)
                    end
                    if lstg.tmpvar.bg and lstg.tmpvar.bg.hide == true then
                        boss.bg.fxsize = min(boss.bg.fxsize + 2, 200)
                    else
                        boss.bg.fxsize = max(boss.bg.fxsize - 2, 0)
                    end
                end
            end
        end
    end
    _log(string.format("[spboss] Boss(%s) SpellCard BackGround Changed", boss))
end

---设置init
---@param boss object @spboss对象
---@param maxhp number @最大生命值
---@param bartype number @血条样式
---@param dropitem table @掉落物数目
---@param is_extra boolean @是否免疫自机符卡
---@param is_final boolean @是否为最后一张
---@param ret boolean @是否重置timer
---@param t1 number @无敌时间
---@param t2 number @防御时间
---@param t3 number @总时间
---@param is_sc boolean @是否为符卡
function lib.set_init(boss, maxhp, bartype, dropitem, is_extra, is_final, ret, t1, t2, t3, is_sc)
    _log(string.format("[spboss] Reset Boss(%s) Init", boss))
    boss.maxhp = maxhp
    boss.hp = maxhp
    _log(string.format("[spboss] Boss maxhp and hp set to %s", maxhp))
    boss.hpbartype = bartype
    local hpbartype
    if bartype == -1 then
        hpbartype = "Disabled"
    end
    if bartype == 0 then
        hpbartype = "Full"
    end
    if bartype == 1 then
        hpbartype = "Part_NonSpell"
    end
    if bartype == 2 then
        hpbartype = "Part_Spell"
    end
    _log(string.format("[spboss] Boss hpbar type set to %s", hpbartype))
    boss.dropitem = dropitem
    _log(string.format("[spboss] Boss dropitem set to (power:%s;faith:%s;point:%s)", dropitem[1], dropitem[2], dropitem[3]))
    boss.is_extra = is_extra
    _log(string.format("[spboss] Boss is_extra set to %s", is_extra))
    boss.is_final = is_final
    _log(string.format("[spboss] Boss is_final set to %s", is_final))
    if ret then
        boss.timer = -1
        boss.hptimer = -1
        boss.card_timer = -1
        _log(string.format("[spboss] Boss Timer Reset"))
    end
    boss.t1, boss.t2, boss.t3 = int(t1) * 60, int(t2) * 60, int(t3) * 60
    _log(string.format("[spboss] Boss Time set (t1 = %s;t2 = %s;t3 = %s)", int(t1), int(t2), int(t3)))
    if is_sc then
        boss.is_card = true
        _log(string.format("[spboss] Boss set to spellcard"))
    else
        boss.is_card = false
        _log(string.format("[spboss] Boss set to non-spellcard"))
    end
    boss.is_finish = false
    boss.countdown = boss.t3
    lib.ResetFlags(boss)
    _log(string.format("[spboss] Reset Boss(%s) Init Finished", boss))
end

---阶段点设置
---@param boss object @boss对象
---@param temp_hp table @血量表
---@param teml_t table @时间表
function lib.SetStagePoint(boss, temp_hp, temp_t)
    if not (IsValid(lib.spcheckobj)) then
        New(lib.StagePointCheckobj)
    end
    if not (lib.StagePointList) then
        lib.StagePointList = {}
    end
    local hp = temp_hp or {}
    local t = temp_t or {}
    for i = 1, #hp do
        hp[i] = boss.maxhp - hp[i]
    end
    boss.sp_point = {}
    for i = 1, #hp do
        table.insert(boss.sp_point, (360 * (hp[i] / boss.maxhp) + 90))
    end
    lib.StagePointList[boss] = { boss, hp, t }
    _log(string.format('[spboss] Boss(%s) Stage Point changed', boss))
end
function lib.StagePointCheck()
    local tmp = {}
    local boss
    for k, v in pairs(lib.StagePointList) do
        boss = v[1]
        if IsValid(boss) then
            local plist = boss.sp_point
            local hplist, tlist = v[2], v[3]
            local hp, timer = boss.hp, boss.timer
            for i = #hplist, 1, -1 do
                if hp <= hplist[i] then
                    table.remove(plist, i)
                    table.remove(hplist, i)
                    table.remove(tlist, i)
                    _log(string.format("[spboss] Boss(%s) Stage Point has been changed", boss))
                end
            end
            for i = #tlist, 1, -1 do
                if timer >= tlist[i] then
                    table.remove(plist, i)
                    table.remove(hplist, i)
                    table.remove(tlist, i)
                    _log(string.format("[spboss] Boss(%s) Stage Point has been changed", boss))
                end
            end
            boss.sp_point = plist
            if #plist ~= 0 then
                tmp[boss] = { boss, hplist, tlist }
            end
        end
    end
    lib.StagePointList = tmp
end
lib.StagePointCheckobj = Class(object)
function lib.StagePointCheckobj:init()
    lib.spcheckobj = boss
end
function lib.StagePointCheckobj:frame()
    lib.StagePointCheck()
end

---刷新bonus
---@param boss object @spboss对象
function lib.ResetFlags(boss)
    boss._flag = { hit = true, spell = true, score = boss.sc_bonus_max }
    _log(string.format("[spboss] Boss(%s) Flags has been Reset", boss))
end

---刷新bonus
---@param boss object @spboss对象
function lib.ResetBonus(boss)
    boss.chip_bonus = { true, true }
    boss.sc_pro = player.nextspell
    _log(string.format("[spboss] Boss(%s) Bonus has been Reset", boss))
end

---检查bonus
---@param boss object @spboss对象
function lib.CheckBonus(boss)
    if not (ex) or not (jstg and jstg.players and jstg.players[2]) then
        if player.death == 90 then
            lib.ClearBonus(boss, "hit")
        end
        if boss.sc_pro <= 0 and player.nextspell > 0 then
            lib.ClearBonus(boss, "spell")
        end
    elseif (jstg and jstg.players) then
        if (jstg.players[1].death == 90) or (jstg.players[2].death == 90) then
            lib.ClearBonus(boss, "hit")
        end
        if (boss.sc_pro <= 0) and ((jstg.players[1].nextspell > 0) or (jstg.players[2].nextspell > 0)) then
            lib.ClearBonus(boss, "spell")
        end
    else
        if player.death == 90 then
            lib.ClearBonus(boss, "hit")
        end
        if boss.sc_pro <= 0 and player.nextspell > 0 then
            lib.ClearBonus(boss, "spell")
        end
    end
    if boss._flag then
        if not (boss.is_card) then
            boss._flag.score = nil
        end
    end
end

---移除bonus
---@param boss object @spboss对象
---@param type string @取消类型
function lib.ClearBonus(boss, type)
    if type == "all" or type == nil then
        if boss._flag then
            boss._flag.hit = false
            boss._flag.spell = false
        end
        boss.chip_bonus = { false, false }
    elseif type == "hit" then
        if boss._flag then
            boss._flag.hit = false
        end
        boss.chip_bonus[1] = false
    elseif type == "spell" then
        if boss._flag then
            boss._flag.spell = false
        end
        boss.chip_bonus[2] = false
    end
    if boss._flag then
        boss._flag.score = nil
    end
end

---结束bonus
---@param boss object @spboss对象
---@param x number @道具生成坐标x
---@param y number @道具生成坐标y
function lib.EndChipBonus(boss, x, y)
    if boss.chip_bonus[1] and boss.chip_bonus[2] then
        New(item_chip, x - 20 * SCREEN_SCALE, y)
        New(item_bombchip, x + 20 * SCREEN_SCALE, y)
    else
        if boss.chip_bonus[1] then
            New(item_chip, x, y)
        end
        if boss.chip_bonus[2] then
            New(item_bombchip, x, y)
        end
    end
end

---结算分数等
---@param boss object @spboss对象
---@param info table @数据信息
function lib.ResultSpell(info)
    if (not (info.time_sc) and not (info.timeout)) or (info.time_sc and info.timeout) then
        if info.score then
            local score = info.score - info.score % 10
            lstg.var.score = lstg.var.score + score
            PlaySound('cardget', 1.0, 0)
            New(hinter_bonus, 'hint.getbonus', 0.6, 0, 112 * SCREEN_SCALE, 15, 120, true, score)
            New(kill_timer, 0, 30 * SCREEN_SCALE, info.timer)
        else
            New(hinter, 'hint.bonusfail', 0.6, 0, 112 * SCREEN_SCALE, 15, 120)
            New(kill_timer, 0, 60 * SCREEN_SCALE, info.timer)
        end
    else
        if info.is_sc and info.timeout then
            PlaySound('fault', 1.0, 0)
        end
        if info.score then
            New(hinter, 'hint.bonusfail', 0.6, 0, 112 * SCREEN_SCALE, 15, 120, 15)
        end
    end
end

---创建一个符卡数据记录信息
---@param boss object @spboss对象
---@param name string @符卡名称
---@param diff string @难度信息
---@param player string @自机信息
function lib.StartSpellHist(boss, name, diff, player)
    diff = diff or "All"
    player = player or "All"
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
    end
    boss.spellcard_hist = { name = name, diff = diff, player = player }
    local str = "[spboss] Start to record a score for %q in difficulty %q and player %q"
    _log(string.format(str, name, diff, player))
end

---结束符卡数据信息
---@param boss object @spboss对象
---@param getcard boolean @是否收取符卡
function lib.FinishSpellHist(boss, getcard)
    if boss.spellcard_hist then
        local hist = scoredata.spell_card_hist
        local name = boss.spellcard_hist.name
        local diff = boss.spellcard_hist.diff
        local player = boss.spellcard_hist.player
        if getcard and not ext.replay.IsReplay() then
            hist[diff][name][player][1] = hist[diff][name][player][1] + 1
        end
        local str = "[spboss] Finish to record the score for %q in difficulty %q and player %q"
        _log(string.format(str, name, diff, player))
        boss.spellcard_hist = nil
    end
end

---boss图片组修改
---@param boss object @boss对象
---@param img string @行走图路径
---@param nRow number @水平分割数
---@param nCol number @纵向分割数
---@param imgs table @每行图片数目
---@param anis table @动画循环帧数
---@param a number @横向判定半径
---@param b number @纵向判定半径
function lib.ChangeImageGroup(boss, img, nRow, nCol, imgs, anis, a, b)
    if IsValid(boss) then
        img = img or nil
        if not (img) or img == '' then
            for i = 1, 4 do
                boss['img' .. i] = nil
                boss['ani' .. i] = nil
            end
        else
            for i = 1, 4 do
                boss['img' .. i] = nil
                boss['ani' .. i] = nil
            end
            local nn = imgs or boss.nn or {}
            local mm = anis or boss.mm or {}
            boss.nn, boss.mm = nn, mm
            local bossimg = img
            local number_n = {}
            for i = 1, nRow do
                number_n[i] = nCol
            end
            LoadTexture('anonymous:' .. bossimg, bossimg)
            local bosstexture_n, bosstexture_m = GetTextureSize('anonymous:' .. bossimg)
            local w, h = bosstexture_n / nCol, bosstexture_m / nRow
            for i = 1, nRow do
                LoadImageGroup('anonymous:' .. bossimg .. i, 'anonymous:' .. bossimg,
                        0, h * (i - 1), w, h, number_n[i], 1, a, b)
            end
            for i = 1, nRow do
                boss['img' .. i] = {}
            end
            for i = 2, nRow do
                boss['ani' .. i] = imgs[i] - anis[i - 1]
            end
            for i = 1, nRow do
                for j = 1, imgs[i] do
                    boss['img' .. i][j] = 'anonymous:' .. bossimg .. i .. j
                end
            end
        end
    end
end

---等待spboss组结束
function lib.WaitForAllBossFinish(...)
    local b = { ... }
    local check = {}
    local ref = {}
    for i = 1, #b do
        check[i] = { b = b[i], ref = {} }
        b[i]._transport = check[i].ref
    end
    while #check > 0 do
        local i, m = 1, #check
        while i <= m do
            if IsValid(check[i]) then
                if check[i].ref.finish then
                    table.insert(ref, check[i].b)
                    table.remove(check, i)
                    m = m - 1
                else
                    i = i + 1
                end
            else
                table.remove(check, i)
                m = m - 1
            end
        end
        task.Wait(1)
    end
    return ref
end

---Kill链接对象
---@param boss object @spboss对象
---@param flag boolean @是否经过处理
function lib.killconnect(boss, flag)
    if not (flag) then
        local forbid = {}
        local function _k(o)
            if o._connect_death then
                for n, u in pairs(o._connect_death) do
                    if forbid[tostring(u)] then
                        o._connect_death[n] = nil
                    else
                        forbid[tostring(u)] = true
                        _k(u)
                    end
                end
            end
        end
        _k(boss)
    end
    if boss._connect_death then
        for i = 1, #boss._connect_death do
            if IsValid(boss._connect_death[i]) then
                Kill(boss._connect_death[i])
            end
        end
        boss._connect_death = nil
    end
end

---链接spboss
function lib.connectdeath(...)
    local l = { ... }
    for i = 1, #l do
        l[i]._connect_death = {}
        for n = 1, #l do
            if n ~= i and l[i].is_spboss then
                table.insert(l[i]._connect_death, l[i])
            end
        end
    end
end

---boss法阵
lib.aura = Class(object)
---@param boss object @目标对象
function lib.aura:init(boss)
    self.layer = LAYER_ENEMY - 1
    self.group = GROUP_GHOST
    self.boss = boss
    self.show = false
    self.t = 0
end
function lib.aura:frame()
    if not (IsValid(self.boss)) then
        Del(self)
    end
    if self.show then
        self.t = min(self.t + 1, 30)
    else
        self.t = max(self.t - 1, 0)
    end
end
function lib.aura:render()
    if IsValid(self.boss) then
        for i = 1, 25 do
            SetImageState('boss_aura_3D' .. i, 'mul+add', Color(self.boss.aura_alpha, 255, 255, 255))
        end
        local size = sin(self.t * 3) ^ 2
        Render('boss_aura_3D' .. self.ani % 25 + 1, self.boss.x, self.boss.y, self.ani * 0.75, 0.92 * size, (0.8 + 0.12 * sin(90 + self.ani * 0.75)) * size)
    end
end

---boss ui
lib.ui = Class(object)
---@param boss object @目标对象
function lib.ui:init(boss)
    self.layer = LAYER_TOP + 2
    self.group = GROUP_GHOST
    self.boss = boss
end
function lib.ui:frame()
    task.Do(self)
    if not (IsValid(self.boss)) then
        Del(self)
    else
        if self.boss.countdown and self.boss.cd_sound then
            local cd = self.boss.countdown
            local t1 = max(self.boss.count_t1 or 5, 0)
            local t2 = max(self.boss.count_t2 or 10, t1)
            if cd > t1 and cd <= t2 and cd % 1 == 0 then
                PlaySound('timeout', 0.6)
            end
            if cd > 0 and cd <= t1 and cd % 1 == 0 then
                PlaySound('timeout2', 0.8)
            end
        end
    end
end
function lib.ui:render()
    if IsValid(self.boss) then
        --hpbar
        local hp_flag = self.boss.hp_flag or 0
        local alpha1 = 1 - hp_flag / 30
        SetImageState('base_hp', '', Color(alpha1 * 255, 255, 0, 0))
        SetImageState('hpbar1', '', Color(alpha1 * 255, 255, 255, 255))
        SetImageState('hpbar2', '', Color(0, 255, 255, 255))
        SetImageState('life_node', '', Color(alpha1 * 255, 255, 255, 255))
        local r1, r2 = 60 * SCREEN_SCALE, 64 * SCREEN_SCALE
        local r3 = 61 * SCREEN_SCALE
        if self.boss.hpbartype == 0 then
            misc.Renderhpbar(self.boss.x, self.boss.y, 90, 360, r1, r2, 360, 1)
            misc.Renderhp(self.boss.x, self.boss.y, 90, 360, r1, r2, 360, self.boss.hpbarlen * min(1, self.boss.hptimer / 60))
            Render('base_hp', self.boss.x, self.boss.y, 0, 0.274, 0.274)
            Render('base_hp', self.boss.x, self.boss.y, 0, 0.256, 0.256)
            if self.boss.sp_point and #self.boss.sp_point ~= 0 then
                for i = 1, #self.boss.sp_point do
                    Render('life_node', self.boss.x + r3 * cos(self.boss.sp_point[i]), self.boss.y + r3 * sin(self.boss.sp_point[i]), self.boss.sp_point[i] - 90, 0.5)
                end
            end
        elseif self.boss.hpbartype == 1 then
            misc.Renderhpbar(self.boss.x, self.boss.y, 90, 360, r1, r2, 360, 1)
            if self.boss.hptimer <= 60 then
                misc.Renderhp(self.boss.x, self.boss.y, 90, 360, r1, r2, 360, self.boss.hpbarlen * min(1, self.boss.hptimer / 60))
            else
                misc.Renderhp(self.boss.x, self.boss.y, 90, self.boss.lifepoint - 90, r1, r2, self.boss.lifepoint - 88, 1)
                misc.Renderhp(self.boss.x, self.boss.y, self.boss.lifepoint, 450 - self.boss.lifepoint, r1, r2, 450 - self.boss.lifepoint, self.boss.hpbarlen)
            end
            Render('base_hp', self.boss.x, self.boss.y, 0, 0.274, 0.274)
            Render('base_hp', self.boss.x, self.boss.y, 0, 0.256, 0.256)
            Render('life_node', self.boss.x + r3 * cos(self.boss.lifepoint), self.boss.y + r3 * sin(self.boss.lifepoint), self.boss.lifepoint - 90, 0.55)
            SetFontState('bonus', '', Color(255, 255, 255, 255))
        elseif self.boss.hpbartype == 2 then
            misc.Renderhpbar(self.boss.x, self.boss.y, 90, 360, r1, r2, 360, 1)
            misc.Renderhp(self.boss.x, self.boss.y, 90, self.boss.lifepoint - 90, r1, r2, self.boss.lifepoint - 88, self.boss.hpbarlen)
            Render('base_hp', self.boss.x, self.boss.y, 0, 0.274, 0.274)
            Render('base_hp', self.boss.x, self.boss.y, 0, 0.256, 0.256)
        end
        if self.boss.show_hp then
            SetFontState('bonus', '', Color(255, 0, 0, 0))
            RenderText('bonus', int(max(0, self.boss.hp)) .. ' / ' .. self.boss.maxhp, self.boss.x - SCREEN_SCALE, self.boss.y - 81 * SCREEN_SCALE, 1.2 * SCREEN_SCALE, 'centerpoint')
            SetFontState('bonus', '', Color(255, 255, 255, 255))
            RenderText('bonus', int(max(0, self.boss.hp)) .. ' / ' .. self.boss.maxhp, self.boss.x, self.boss.y - 80 * SCREEN_SCALE, 1.2 * SCREEN_SCALE, 'centerpoint')
        end
        --boss name and sc left star
        local x = -185 * SCREEN_SCALE
        local y = 222 * SCREEN_SCALE
        local x2 = x - SCREEN_SCALE
        local y2 = y - SCREEN_SCALE
        local dy1 = self.boss.ui_dy
        local dy2 = self.boss.ui_dy2
        if self.boss.show_name then
            RenderTTF('boss_name', self.boss.name, x, x, y - dy1, y - dy1, Color(0xFF000000), 'noclip')
            RenderTTF('boss_name', self.boss.name, x2, x2, y2 - dy1, y2 - dy1, Color(0xFF80FF80), 'noclip')
            local m = int((self.boss.sc_left - 1) / 8)
            local x, dx = -194 * SCREEN_SCALE, 12 * SCREEN_SCALE
            local y, dy = 207 * SCREEN_SCALE, 12 * SCREEN_SCALE
            if m >= 0 then
                for i = 0, m - 1 do
                    for j = 1, 8 do
                        Render('boss_sc_left', x + j * dx, y - i * dy - dy1, 0, 0.5)
                    end
                end
                for i = 1, int(self.boss.sc_left - 1 - 8 * m) do
                    Render('boss_sc_left', x + i * dx, y - m * dy - dy1, 0, 0.5)
                end
            end
        end
        if not (self.boss.is_finish) and self.boss.drawtime then
            local countdown = self.boss.countdown
            local cd = (countdown - int(countdown)) * 100
            local yoffset
            if self.boss._flag and self.boss._flag.score then
                yoffset = max(20 - self.boss.timer, 0)
            else
                yoffset = min(20, (self.boss.timer + 1))
            end
            local x1, y1 = 4 * SCREEN_SCALE, 192 * SCREEN_SCALE
            local x2, y2 = 4 * SCREEN_SCALE, 189 * SCREEN_SCALE
            local count_t = self.boss.count_t2 or 10
            if countdown >= count_t then
                SetFontState('time', '', Color(alpha1 * 255, 255, 255, 255))
            else
                SetFontState('time', '', Color(alpha1 * 255, 255, 30, 30))
            end
            if countdown >= 10.0 then
                RenderText('time', string.format('%d',
                        int(countdown)), x1, y1 + yoffset - dy2,
                        0.5 * SCREEN_SCALE, 'vcenter', 'right')
                RenderText('time', '.' .. string.format('%d%d',
                        min(9, cd / 10), min(9, cd % 10)), x2, y2 + yoffset - dy2,
                        0.3 * SCREEN_SCALE, 'vcenter', 'left')
            else
                RenderText('time', string.format('0%d',
                        min(99.99, int(countdown))), x1, y1 + yoffset - dy2,
                        0.5 * SCREEN_SCALE, 'vcenter', 'right')
                RenderText('time', '.' .. string.format('%d%d',
                        min(9, cd / 10), min(9, cd % 10)), x2, y2 + yoffset - dy2,
                        0.3 * SCREEN_SCALE, 'vcenter', 'left')
            end
        end
    end
end

---boss spellcard name
---@param boss object @目标对象
---@param name string @符卡名称
---@param slot number @使用槽位
lib.sc_name = Class(object)
function lib.sc_name:init(boss, name, slot)
    self.boss = boss
    self.name = name or ""
    if self.name == "" then
        RawDel(self)
    end
    self.slot = slot or 0
    self.ui_dy = 44 * self.slot * SCREEN_SCALE
    self.ui_dy2 = 44 * self.slot * SCREEN_SCALE
    self.x = 384 * SCREEN_SCALE
    self.y = 336 * SCREEN_SCALE
    self.bound = false
    self.alpha = 1
end
function lib.sc_name:frame()
    if self.timer > 90 then
        local axy = 0
        local players
        if Players then
            players = Players(self)
        else
            players = { player }
        end
        for _, p in pairs(players) do
            local ax, ay = 0, 0
            if IsValid(p) then
                ax = min(max(p.x * 0.05, 0), 0.9)
                ay = min(max((p.y - 172 * SCREEN_SCALE - (self.ui_dy + self.y)) * 0.05, 0), 0.9)
            end
            if ax * ay > axy then
                axy = ax * ay
            end
        end
        self.alpha = 1 - axy
    else
        self.alpha = 1
    end
    if not (self.death) then
        self.x = max(self.x - 12.8 * SCREEN_SCALE, 0)
        if self.timer > 60 then
            self.y = max(self.y - 11.2 * SCREEN_SCALE, 0)
        end
    else
        self.x = min(self.x + 7 * SCREEN_SCALE, 384 * SCREEN_SCALE)
        if self.timer > 60 then
            RawDel(self)
        end
    end
    if IsValid(self.boss) then
        if self.boss.is_spboss then
            local _flag = self.boss._flag
            local sc_hist = self.boss.spellcard_hist
            local hist = scoredata.spell_card_hist
            if hist and sc_hist then
                name = sc_hist.name
                diff = sc_hist.diff
                player = sc_hist.player
                sc_hist = hist[name][diff][player]
            else
                sc_hist = { 0, 0 }
            end
            self.sc_hist = sc_hist
            self.score = _flag.score
        else
            self.sc_hist = self.boss.ui.sc_hist
            self.score = self.boss.sc_bonus
            if self.score == 0 then
                self.score = nil
            end
        end
    end
end
function lib.sc_name:render()
    local alpha = self.alpha
    local xoffset, yoffset = self.x, self.y
    local dy1, dy2 = self.ui_dy + yoffset, self.ui_dy2 + yoffset
    if self.m == 1 then
        dy1 = dy1 - 18 * SCREEN_SCALE
        dy2 = dy2 - 18 * SCREEN_SCALE
    end
    local x1, x2 = 193 * SCREEN_SCALE, 192 * SCREEN_SCALE
    local y1, y2 = 226 * SCREEN_SCALE, 227 * SCREEN_SCALE
    SetImageState('boss_spell_name_bg', '', Color(alpha * 255, 255, 255, 255))
    Render('boss_spell_name_bg', x2 + xoffset, 236 * SCREEN_SCALE - dy1)
    RenderTTF('sc_name', self.name,
            x1 + xoffset, x1 + xoffset, y1 - dy1, y1 - dy1,
            Color(alpha * 255, 0, 0, 0), 'right', 'noclip')
    RenderTTF('sc_name', self.name,
            x2 + xoffset, x2 + xoffset, y2 - dy1, y2 - dy1,
            Color(alpha * 255, 255, 255, 255), 'right', 'noclip')
    local sc_hist = self.sc_hist
    local score = self.score
    if sc_hist then
        local b
        if score then
            b = string.format('%.0f', score - score % 10)
        else
            b = 'FAILED '
        end
        local x1, y1 = 187 * SCREEN_SCALE, 207 * SCREEN_SCALE
        local x2, y2 = 97 * SCREEN_SCALE, 207 * SCREEN_SCALE
        local x3, y3 = 137 * SCREEN_SCALE, 207 * SCREEN_SCALE
        local x4, y4 = 186 * SCREEN_SCALE, 208 * SCREEN_SCALE
        local x5, y5 = 96 * SCREEN_SCALE, 208 * SCREEN_SCALE
        local x6, y6 = 136 * SCREEN_SCALE, 208 * SCREEN_SCALE
        SetFontState('bonus', '', Color(alpha * 255, 0, 0, 0))
        RenderText('bonus', b, x1 + xoffset, y1 - dy2, 0.5 * SCREEN_SCALE, 'right')
        RenderText('bonus', string.format('%d/%d', sc_hist[1], sc_hist[2]),
                x2 + xoffset, y2 - dy2, 0.5 * SCREEN_SCALE, 'right')
        RenderText('bonus', 'HISTORY       BONUS', x3 + xoffset, y3 - dy2, 0.5 * SCREEN_SCALE, 'right')
        SetFontState('bonus', '', Color(alpha * 255, 255, 255, 255))
        RenderText('bonus', b, x4 + xoffset, y4 - dy2, 0.5 * SCREEN_SCALE, 'right')
        RenderText('bonus', string.format('%d/%d', sc_hist[1], sc_hist[2]),
                x5 + xoffset, y5 - dy2, 0.5 * SCREEN_SCALE, 'right')
        RenderText('bonus', 'HISTORY       BONUS', x6 + xoffset, y6 - dy2, 0.5 * SCREEN_SCALE, 'right')
    end
end
function lib.sc_name:kill()
    self.class.del(self)
end
function lib.sc_name:del()
    PreserveObject(self)
    if not (self.death) then
        self.death = true
        self.timer = -1
    end
end

---boss指示器
lib.pointer = Class(object)
---@param boss object @目标对象
function lib.pointer:init(boss)
    self.layer = LAYER_TOP + 2
    self.group = GROUP_GHOST
    self.boss = boss
    self.y = lstg.world.b
end
function lib.pointer:frame()
    if not (IsValid(self.boss)) then
        Del(self)
    end
end
function lib.pointer:render()
    if IsValid(self.boss) then
        if self.boss.pointer_x and self.boss.y <= lstg.world.boundt then
            local w = lstg.world
            local cenx = (w.l + w.r) / 2
            local ceny = (w.t + w.b) / 2
            if abs(self.boss.pointer_x - cenx) <= (lstg.world.r - lstg.world.l) / 2 then
                SetViewMode 'ui'
                Render('boss_pointer', WorldToScreen(max(min(self.boss.pointer_x, w.r), -w.r) * (w.r - w.l) / (w.scrr - w.scrl), self.y * (w.t - w.b) / (w.scrt - w.scrb) + ceny))
                SetViewMode 'world'
            end
        end
    end
end

_log(string.format("[spboss] complete"))

lib.card = {}
---定义符卡
---@param id string @符卡编号
---@param name string @符卡名
---@param t1 number @无敌时间
---@param t2 number @防御时间
---@param t3 number @总时间
---@param hp number @血量
---@param dropitem table @掉落物数目
---@param is_extra boolean @是否免疫自机符卡
---@param before function @符卡前置动作
---@param start function @符卡起始动作
---@param finish function @符卡结束动作
function lib.card.add(id, name, t1, t2, t3, hp, dropitem, is_extra, before, start, finish, fake)
    lib.list.card[id] = {}
    local c = lib.list.card[id]
    c.is_sc = not (name == '')
    c.name = name
    c.t1, c.t2, c.t3 = t1, t2, t3
    c.hp = hp
    c.dropitem = dropitem
    c.is_extra = is_extra
    c.before = before
    c.start = start
    c.finish = finish
    c.is_combat = not (fake)
    _log(string.format("[spboss][card] Add a card for id %q", id))
end

---获取符卡
---@param id string @符卡编号
---@return table
function lib.card.get(id)
    return lib.list.card[id]
end

---获取符卡init并设置
---@param boss object @spboss对象
---@param c table @符卡数据
---@param bartype number @血条样式
---@param is_final boolean @是否为终符
function lib.card.get_init(boss, c, bartype, is_final)
    lib.set_init(boss, c.hp, bartype, c.dropitem, c.is_extra, is_final, true, c.t1, c.t2, c.t3, c.is_sc)
end

---执行符卡
---@param boss object @spboss对象
---@param id string @符卡编号
---@param bartype number @血条样式
---@param is_final boolean @是否为终符
function lib.card.do_card(boss, id, bartype, is_final)
    _log(string.format("[spboss][card] Boss(%s) set to use a card (id:%q)", boss, id))
    task.New(boss, function()
        local c = lib.card.get(id)
        if c then
            boss.now_card = c
            boss.is_fake = not (c.is_combat)
            if c.finish then
                boss._task_finish = c.finish
            end
            if c.before then
                if not boss.task then
                    boss.task = {}
                end
                local rt = coroutine.create(c.before())
                table.insert(boss.task, rt)
                local i = #boss.task
                while coroutine.status(boss.task[i]) ~= 'dead' do
                    task.Wait()
                end
            end
            if c.start then
                lib.card.get_init(boss, c, bartype, is_final)
                if c.name ~= '' then
                    lib.castcard(boss, c.name)
                end
                task.New(boss, c.start())
            end
        end
    end)
end

---设置boss执行符卡表
---@param boss object @spboss对象
function lib.card.prepare(boss, ...)
    _log(string.format("[spboss][card] Boss(%s) set to use a card list", boss))
    local card_id_list = { ... }
    if #card_id_list > 0 then
        local cards = {}
        for i = 1, #card_id_list do
            table.insert(cards, lib.card.get(card_id_list[i]))
        end
        boss._precards = card_id_list
        boss._prehptype = {}
        local typ = {}
        local last_card = 0
        for i = 1, #cards do
            if cards[i].is_combat then
                last_card = i
                local ctype = {}
                for n = i - 1, 1, -1 do
                    if cards[n] and cards[n].is_combat then
                        ctype[1] = cards[n].is_sc
                        break
                    end
                end
                ctype[2] = cards[i].is_sc
                for n = i + 1, #cards do
                    if cards[n] and cards[n].is_combat then
                        ctype[1] = cards[n].is_sc
                        break
                    end
                end
                if ctype[1] == nil then
                    if ctype[2] then
                        table.insert(typ, 1)
                    elseif ctype[3] then
                        table.insert(typ, 2)
                    else
                        table.insert(typ, 1)
                    end
                else
                    if ctype[1] then
                        if ctype[2] then
                            table.insert(typ, 0)
                        elseif ctype[3] then
                            table.insert(typ, 1)
                        else
                            table.insert(typ, 0)
                        end
                    else
                        if ctype[2] then
                            table.insert(typ, 2)
                        elseif ctype[3] then
                            table.insert(typ, 1)
                        else
                            table.insert(typ, 0)
                        end
                    end
                end
            else
                table.insert(typ, -1)
            end
        end
        boss._prehptype = typ
        boss._predo = 1
        local c = 0
        for i = 1, #cards do
            if cards[i].is_sc then
                c = c + 1
            end
        end
        boss.sc_left = c
        boss._last_card = last_card
        lib.card.do_card(boss, boss._precards[boss._predo], boss._prehptype[boss._predo], (boss._predo == boss._last_card))
    end
end

---spboss内置dialog对话系统
lib.card.dialog = { list = {} }
LoadImageFromFile('dialog_box', 'THlib/enemy/dialog_box.png')
function lib.card.dialog:sentence(img, pos, text, t, hscale, vscale)
    if pos == 'left' then
        pos = 1
    else
        pos = -1
    end
    self.dialog_displayer.text = text
    self.dialog_displayer.char[pos] = img
    if self.dialog_displayer.active ~= pos then
        self.dialog_displayer.active = pos
        self.dialog_displayer.t = 16
    end
    self.dialog_displayer._hscale[pos] = hscale or pos
    self.dialog_displayer._vscale[pos] = vscale or 1
    task.Wait()
    t = t or (60 + #text * 5)
    for i = 1, t do
        if (KeyIsPressed 'shoot' or self.dialog_displayer.jump_dialog > 60) and _dialog_can_skip then
            PlaySound('plst00', 0.35, 0, true)
            break
        end
        task.Wait()
    end
    task.Wait(2)
end
lib.card.dialog.dialog_displayer = Class(object)
function lib.card.dialog.dialog_displayer:init()
    self.layer = LAYER_TOP
    self.char = {}
    self._hscale = {}
    self._vscale = {}
    self.t = 16
    self.death = 0
    self.co = 0
    self.jump_dialog = 0
end
function lib.card.dialog.dialog_displayer:frame()
    task.Do(self)
    if self.t > 0 then
        self.t = self.t - 1
    end
    if self.active then
        self.co = max(min(60, self.co + 1.5 * self.active), -60)
    end
    if player.dialog == true and self.active then
        if KeyIsDown 'shoot' then
            self.jump_dialog = self.jump_dialog + 1
        else
            self.jump_dialog = 0
        end
    end
end
function lib.card.dialog.dialog_displayer:render()
    if self.active then
        SetViewMode 'ui'
        if self.char[-self.active] then
            SetImageState(self.char[-self.active], '', Color(0xFF404040) + (self.t / 16) * Color(0xFFC0C0C0) - (self.death / 30) * Color(0xFF000000))
            local t = (1 - self.t / 16) ^ 3
            Render(self.char[-self.active], 224 + self.active * (-(1 - 2 * t) * 16 + 128) + self.death * self.active * 12, 240 - 65 - t * 16 - 25, 0, self._hscale[-self.active], self._vscale[-self.active])
        end
        if self.char[self.active] then
            SetImageState(self.char[self.active], '', Color(0xFF404040) + (1 - self.t / 16) * Color(0xFFC0C0C0) - (self.death / 30) * Color(0xFF000000))
            local t = (self.t / 16) ^ 3
            Render(self.char[self.active], 224 + self.active * ((1 - 2 * t) * 16 - 128) - self.death * self.active * 12, 240 - 65 - t * 16 - 25, 0, self._hscale[self.active], self._vscale[self.active])
        end
        SetViewMode 'world'
    end
    if self.text and self.active then
        local kx, ky1, ky2, dx, dy1, dy2
        kx = 168
        ky1 = -210
        ky2 = -90
        dx = 160
        dy1 = -144
        dy2 = -126
        SetImageState('dialog_box', '', Color(225, 195 - self.co, 150, 195 + self.co))
        Render('dialog_box', 0, -144 - self.death * 8)
        RenderTTF('dialog', self.text, -dx, dx, dy1 - self.death * 8, dy2 - self.death * 8, Color(0xFF000000), 'paragraph')
        if self.active > 0 then
            RenderTTF('dialog', self.text, -dx, dx, dy1 - self.death * 8, dy2 - self.death * 8, Color(255, 255, 200, 200), 'paragraph')
        else
            RenderTTF('dialog', self.text, -dx, dx, dy1 - self.death * 8, dy2 - self.death * 8, Color(255, 200, 200, 255), 'paragraph')
        end
    end
end
function lib.card.dialog.dialog_displayer:del()
    PreserveObject(self)
    task.New(self, function()
        for i = 1, 30 do
            self.death = i
            task.Wait()
        end
        RawDel(self)
    end)
end
lib.card.add('boss_dialog', '', 999999999, 999999999, 999999999, 999999999, { 0, 0, 0 }, true, nil,
        function()
            return function()
                local self = task.GetSelf()
                local c = lib.card.dialog.list[self.dialog_id]
                self._flag = nil
                player.dialog = true
                self._dialog_can_skip = c.can_skip
                self.dialog_displayer = New(lib.card.dialog.dialog_displayer)
                local continue = false
                if c.func then
                    task.New(self, function()
                        c.func()
                        continue = true
                    end)
                else
                    for i = 1, #c.sentence do
                        lib.card.dialog.sentence(self, unpack(c.sentence[i]))
                    end
                    continue = true
                end
                while not (continue) do
                    task.Wait()
                end
                player.dialog = false
                Del(self.dialog_displayer)
                self.dialog_displayer = nil
                self.chip_bonus = { false, false }
                self.dialog_id = nil
                self._in_dialog = nil
                Kill(self)
            end
        end, nil, true)

---执行对话
---@param id string @对话编号
function lib.card.dialog:Do(id)
    self.dialog_id = id
    self._in_dialog = true
    lib.card.do_card(self, 'boss_dialog', -1, false)
end

---新建对话
---@param id string @对话编号
---@param can_skip boolean @对话能否跳过
function lib.card.dialog.New(id, can_skip)
    local c = {}
    c.can_skip = can_skip
    c.sentence = {}
    lib.card.dialog.list[id] = c
end

---添加语句
---@param id string @对话编号
---@param img string @对话图像
---@param pos string @对话方位
---@param text string @对话内容
---@param t number @对话时长
---@param hscale number @图像横向缩放比
---@param vscale number @图像纵向缩放比
function lib.card.dialog.AddSentence(id, img, pos, text, t, hscale, vscale)
    table.insert(lib.card.dialog.list[id].sentence, { img, pos, text, t, hscale, vscale })
end

---设置对话动作
---@param id string @对话编号
---@param f function @对话动作
function lib.card.dialog.SetTask(id, f)
    lib.card.dialog.list[id].func = f
end

---等待对话结束
function lib.card.dialog:WaitDialog()
    while self._in_dialog do
        task.Wait(1)
    end
    task.Wait(1)
end

---默认符卡系统适配函数库
lib.ex_card = {}
---符卡转换
---@param c table @通常boss符卡
---@retuen table
function lib.ex_card.get_init(c)
    local card = {
        name = c.name,
        t1 = c.t1 / 60, t2 = c.t2 / 60, t3 = c.t3 / 60,
        hp = c.hp, is_sc = c.is_sc,
        dropitem = c.drop,
        is_extra = c.is_extra,
        fake = not (c.is_combat),
        init = c.init,
        frame = c.frame,
        render = c.render,
        del = c.del
    }
    return card
end

---执行通常符卡
---@param card table @通常boss符卡
---@param bartype number @血条样式
---@param is_final boolean @是否为终符
function lib.ex_card:do_card(card, bartype, is_final)
    local c = lib.ex_card.get_init(card)
    self.ex_card = c
    self.cards = { self.ex_card }
    self.card_num = 1
    if self.ex_card.name ~= '' then
        lib.castcard(self, self.ex_card.name)
    end
    lib.card.get_init(self, self.ex_card, bartype, is_final)
    self.ex_card.init(self)
end

---执行转化符卡
---@param card table @转化后符卡
---@param bartype number @血条样式
---@param is_final boolean @是否为终符
function lib.ex_card:do_card_sp(card, bartype, is_final)
    self.ex_card = card
    self.current_card = self.ex_card
    self.cards = { self.ex_card }
    self.card_num = 1
    if self.ex_card.name ~= '' then
        lib.castcard(self, self.ex_card.name)
    end
    lib.card.get_init(self, self.ex_card, bartype, is_final)
    self.ex_card.init(self)
end

---执行通常boss符卡列
---@param carda table @通常boss符卡表
function lib.ex_card:do_card_list(cards)
    _log(string.format("[spboss][card] Boss(%s) set to use a nomal card list", self))
    local curcards = {}
    for i = 1, cards do
        table.insert(curcards, lib.ex_card.get_init(cards[i]))
    end
    local typ = {}
    local last_id = 0
    for i = 1, #curcards do
        if curcards[i].is_combat then
            last_id = i
            local ctype = {}
            for n = i - 1, 1, -1 do
                if curcards[n] and curcards[n].is_combat then
                    ctype[1] = curcards[n].is_sc
                    break
                end
            end
            ctype[2] = curcards[i].is_sc
            for n = i + 1, #curcards do
                if curcards[n] and curcards[n].is_combat then
                    ctype[1] = curcards[n].is_sc
                    break
                end
            end
            if ctype[1] == nil then
                if ctype[2] then
                    table.insert(typ, 1)
                elseif ctype[3] then
                    table.insert(typ, 2)
                else
                    table.insert(typ, 1)
                end
            else
                if ctype[1] then
                    if ctype[2] then
                        table.insert(typ, 0)
                    elseif ctype[3] then
                        table.insert(typ, 1)
                    else
                        table.insert(typ, 0)
                    end
                else
                    if ctype[2] then
                        table.insert(typ, 2)
                    elseif ctype[3] then
                        table.insert(typ, 1)
                    else
                        table.insert(typ, 0)
                    end
                end
            end
        else
            table.insert(typ, -1)
        end
    end
    local c
    for i = 1, #curcards do
        if curcards[i].is_sc then
            c = c + 1
        end
    end
    self.sc_left = c
    self._ex_cards = curcards
    self._ex_cards_num = 0
    self._ex_cards_last_id = last_id
    self._ex_cards_prehptype = typ
    lib.ex_card.next(self)
end

---执行符卡组内下一张符卡
function lib.ex_card:next()
    if self._ex_cards then
        self._ex_cards_num = self._ex_cards_num + 1
        lib.ex_card.do_card_sp(self, self._ex_cards[self._ex_cards_num], self._ex_cards_prehptype[self._ex_cards_num], self._ex_cards_num == self._ex_cards_last_id)
    end
end

---默认符卡系统扩展
lib.sp_card = {}
---使用plus.Class的更加优良的符卡系统
lib.sp_card.CardSystem = plus.Class()
local CardSystem = lib.sp_card.CardSystem
---@param boss object @要执行符卡组的boss
---@param cards table @默认符卡表
function CardSystem:init(boss, cards)
    self.cards = cards or {}
    boss.cards = self.cards
    boss.card_num = 0
    self.num = 0
    self.sc_left = 0
    self.final = 0
    self.is_finish = false
    for i = 1, #self.cards do
        if self.cards[i].is_combat then
            self.final = i
        end
        if self.cards[i].is_sc then
            self.sc_left = self.sc_left + 1
        end
    end
end
---帧逻辑适配
---@param boss object @要执行符卡组的boss
function CardSystem:frame(boss)
    if self.cards[self.num] then
        self.cards[self.num].frame(boss)
    end
end
---渲染逻辑适配
---@param boss object @要执行符卡组的boss
function CardSystem:render(boss)
    if self.cards[self.num] then
        self.cards[self.num].render(boss)
    end
end
---结束逻辑适配
---@param boss object @要执行符卡组的boss
function CardSystem:del(boss)
    if self.cards[self.num] then
        self.cards[self.num].del(boss)
    end
end
---执行通常符卡
---@param boss object @要执行符卡组的boss
---@param card table @通常boss符卡
---@param mode number @血条样式
---@param final boolean @是否为终符
function CardSystem:DoCard(boss, card, mode, final)
    local c = {
        name = card.name,
        t1 = card.t1 / 60, t2 = card.t2 / 60, t3 = card.t3 / 60,
        hp = card.hp, is_sc = card.is_sc,
        dropitem = card.drop,
        is_extra = card.is_extra,
        fake = not (card.is_combat),
        init = card.init,
        frame = card.frame,
        render = card.render,
        del = card.del
    }
    if c.name ~= '' then
        lib.castcard(self, c.name)
    end
    self.current_card = card
    lib.card.get_init(self, c, mode, final)
    c.init(self)
end
---执行下一张符卡
---@param boss object @要执行符卡组的boss
function CardSystem:next(boss)
    self.num = self.num + 1
    boss.card_num = boss.card_num + 1
    if not (self.cards[self.num]) then
        self.is_finish = true
        return false
    end
    local last, now, next, mode
    for n = self.num - 1, 1, -1 do
        if self.cards[n] and self.cards[n].is_combat then
            last = self.cards[n]
            break
        end
    end
    now = self.cards[self.num]
    for n = self.num + 1, #self.cards do
        if self.cards[n] and self.cards[n].is_combat then
            next = self.cards[n]
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
            mode = 0
        elseif not (next) then
            mode = 0
        end
    end
    if now.t1 == now.t3 then
        mode = -1
    end
    self:DoCard(boss, self.cards[self.num], mode, self.num == self.final)
end

---执行默认符卡组
---@param cards table @默认符卡表
function lib.sp_card:do_cards(cards)
    self._card_system = lib.sp_card.CardSystem(self, cards)
    self.sc_left = self._card_system.sc_left
    self._card_system:next(self)
end

_log(string.format("[spboss] SpellCard Additional Library install"))
