--======================================
--th style boss ui
--======================================

if GetImageScale == nil then
    local _scale
    local old = SetImageScale

    ---获取全局图像缩放比
    ---@return number
    function GetImageScale()
        return _scale
    end

    ---设置全局图像缩放比
    ---@param scale number
    function SetImageScale(scale)
        old(scale)
        _scale = scale
    end
end

----------------------------------------
--boss ui
--！警告：未适配宽屏等非传统版面

---@class boss.ui
---@return boss
boss.ui = Class(object)
function boss.ui:init(system, b)
    self.layer = LAYER_TOP + 2
    self.boss = b
    self.system = system
    self.drawhp = true
    self.drawname = true
    self.drawtime = true
    self.drawspell = true
    self.needposition = true
    self.drawpointer = true
    self.drawtimesaver = nil
    self.infobar = boss.infobar(self, self.system)
    self.hpbar = boss.hpbar(self, self.system)
    self.timeCounter = boss.timeCounter(self, self.system)
    self.pointer = boss.pointer(self, self.system)
end
function boss.ui:frame()
    if IsValid(self.boss) then
        if self.infobar then
            self.infobar:frame()
        end
        if self.hpbar then
            self.hpbar:frame()
        end
        if self.timeCounter then
            self.timeCounter:frame()
        end
        if self.pointer then
            self.pointer:frame()
        end
    else
        Del(self)
    end
end
function boss.ui:render()
    if IsValid(self.boss) then
        if self.infobar then
            self.infobar:render()
        end
        if self.hpbar then
            self.hpbar:render()
        end
        if self.timeCounter then
            self.timeCounter:render()
        end
        if self.pointer then
            self.pointer:render()
        end
    end
end

----------------------------------------
---boss 法阵
---@class boss.aura
---@return boss.aura
boss.aura = plus.Class()
local aura = boss.aura
---@param system boss.system
function aura:init(system)
    self.system = system
    self.open = true
    self.t = 0
    self.size = 0
end
function aura:frame()
    if self.open then
        self.t = min(self.t + 1, 30)
    else
        self.t = max(self.t - 1, 0)
    end
    self.size = sin(self.t * 3)
end
function aura:render()
    local b = self.system.boss
    if not (IsValid(b)) then
        return
    end
    local size = self.size * b.aura_scale
    for i = 1, 25 do
        SetImageState("boss_aura_3D" .. i, "mul+add", Color(b.aura_alpha, 255, 255, 255))
    end
    Render("boss_aura_3D" .. b.ani % 25 + 1, b.x, b.y, b.ani * 0.75,
            0.92 * size, (0.8 + 0.12 * sin(90 + b.ani * 0.75)) * size)
end

----------------------------------------
---boss 血条
---@class boss.hpbar
---@return boss.hpbar
boss.hpbar = plus.Class()
local hpbar = boss.hpbar
---@param ui boss.ui
---@param system boss.system
function hpbar:init(ui, system)
    self.ui = ui
    self.system = system
end
function hpbar:frame()
end
function hpbar:render()
    local _ui = self.ui
    local b = self.system.boss
    if not (self.ui.drawhp) or not (IsValid(b)) then
        return
    end
    local alpha1 = 1 - b.hp_flag / 30
    SetImageState("base_hp", "", Color(alpha1 * 255, 255, 0, 0))
    SetImageState("hpbar1", "", Color(alpha1 * 255, 255, 255, 255))
    SetImageState("hpbar2", "", Color(0, 255, 255, 255))
    SetImageState("life_node", "", Color(alpha1 * 255, 255, 255, 255))

    local mode, type
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
        if mode == -1 then
        elseif mode == 0 and type == 1 then
            misc.Renderhpbar(b.x, b.y, 90, 360, 60, 64, 360, 1)
            misc.Renderhp(b.x, b.y, 90, 360, 60, 64, 360, b.hpbarlen * min(1, b.__hpbar_timer / 60))
            Render("base_hp", b.x, b.y, 0, 0.274, 0.274)
            Render("base_hp", b.x, b.y, 0, 0.256, 0.256)
            if b.sp_point and #b.sp_point ~= 0 then
                for i = 1, #b.sp_point do
                    Render("life_node", b.x + 61 * cos(b.sp_point[i]), b.y + 61 * sin(b.sp_point[i]), b.sp_point[i] - 90, 0.5)
                end
            end
            if b._sp_point_auto and #b._sp_point_auto ~= 0 then
                local p, a
                for i = 1, #b._sp_point_auto do
                    p = b._sp_point_auto[i]
                    a = 90 - (p.dmg / b.maxhp) * 360
                    Render("life_node", b.x + 61 * cos(a), b.y + 61 * sin(a), a - 90, 0.5)
                end
            end
        elseif mode == 0 and type == 2 then
            misc.Renderhpbar(b.x, b.y, 90, 360, 60, 64, 360, 1)
            misc.Renderhp(b.x, b.y, 90, 360, 60, 64, 360, b.hpbarlen * min(1, b.__hpbar_timer / 60))
            Render("base_hp", b.x, b.y, 0, 0.274, 0.274)
            Render("base_hp", b.x, b.y, 0, 0.256, 0.256)
            if b.sp_point and #b.sp_point ~= 0 then
                for i = 1, #b.sp_point do
                    Render("life_node", b.x + 61 * cos(b.sp_point[i]), b.y + 61 * sin(b.sp_point[i]), b.sp_point[i] - 90, 0.5)
                end
            end
            if b._sp_point_auto and #b._sp_point_auto ~= 0 then
                local p, a
                for i = 1, #b._sp_point_auto do
                    p = b._sp_point_auto[i]
                    a = 90 - (p.dmg / b.maxhp) * 360
                    Render("life_node", b.x + 61 * cos(a), b.y + 61 * sin(a), a - 90, 0.5)
                end
            end
        elseif mode == 2 then
            misc.Renderhpbar(b.x, b.y, 90, 360, 60, 64, 360, 1)
            misc.Renderhp(b.x, b.y, 90, b.lifepoint - 90, 60, 64, b.lifepoint - 88, b.hpbarlen)
            Render("base_hp", b.x, b.y, 0, 0.274, 0.274)
            Render("base_hp", b.x, b.y, 0, 0.256, 0.256)
        elseif mode == 1 then
            misc.Renderhpbar(b.x, b.y, 90, 360, 60, 64, 360, 1)
            if b.timer <= 60 then
                misc.Renderhp(b.x, b.y, 90, 360, 60, 64, 360, b.hpbarlen * min(1, b.__hpbar_timer / 60))
            else
                misc.Renderhp(b.x, b.y, 90, b.lifepoint - 90, 60, 64, b.lifepoint - 88, 1)
                misc.Renderhp(b.x, b.y, b.lifepoint, 450 - b.lifepoint, 60, 64, 450 - b.lifepoint, b.hpbarlen)
            end
            Render("base_hp", b.x, b.y, 0, 0.274, 0.274)
            Render("base_hp", b.x, b.y, 0, 0.256, 0.256)
            Render("life_node", b.x + 61 * cos(b.lifepoint), b.y + 61 * sin(b.lifepoint), b.lifepoint - 90, 0.55)
            SetFontState("bonus", "", Color(255, 255, 255, 255))
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
                mode = 4
            elseif not (_ui.hpbarcolor1) then
                mode = 5
            elseif _ui.hpbarcolor1 == _ui.hpbarcolor2 then
                mode = 6
            elseif _ui.hpbarcolor1 ~= _ui.hpbarcolor2 then
                mode = 7
            end
        end

        local flag2 = int(b.__hpbartype2 / 10)
        if flag2 == 1 then
            if mode == -1 then
            elseif mode == 0 and type == 1 then
                misc.Renderhpbar(b.x, b.y, 90, 360, 60, 64, 360, 1)
                misc.Renderhp(b.x, b.y, 90, 360, 60, 64, 360, b.hpbarlen * min(1, b.__hpbar_timer / b.__hpbar_rendertime))
                Render("base_hp", b.x, b.y, 0, 0.274, 0.274)
                Render("base_hp", b.x, b.y, 0, 0.256, 0.256)
                if b.sp_point and #b.sp_point ~= 0 then
                    for i = 1, #b.sp_point do
                        Render("life_node", b.x + 61 * cos(b.sp_point[i]), b.y + 61 * sin(b.sp_point[i]), b.sp_point[i] - 90, 0.5)
                    end
                end
                if b._sp_point_auto and #b._sp_point_auto ~= 0 then
                    local p, a
                    for i = 1, #b._sp_point_auto do
                        p = b._sp_point_auto[i]
                        a = 90 - (p.dmg / b.maxhp) * 360
                        Render("life_node", b.x + 61 * cos(a), b.y + 61 * sin(a), a - 90, 0.5)
                    end
                end
            elseif mode == 0 and type == 2 then
                misc.Renderhpbar(b.x, b.y, 90, 360, 60, 64, 360, 1)
                misc.Renderhp(b.x, b.y, 90, 360, 60, 64, 360, b.hpbarlen * min(1, b.__hpbar_timer / b.__hpbar_rendertime))
                Render("base_hp", b.x, b.y, 0, 0.274, 0.274)
                Render("base_hp", b.x, b.y, 0, 0.256, 0.256)
                if b.sp_point and #b.sp_point ~= 0 then
                    for i = 1, #b.sp_point do
                        Render("life_node", b.x + 61 * cos(b.sp_point[i]), b.y + 61 * sin(b.sp_point[i]), b.sp_point[i] - 90, 0.5)
                    end
                end
                if b._sp_point_auto and #b._sp_point_auto ~= 0 then
                    local p, a
                    for i = 1, #b._sp_point_auto do
                        p = b._sp_point_auto[i]
                        a = 90 - (p.dmg / b.maxhp) * 360
                        Render("life_node", b.x + 61 * cos(a), b.y + 61 * sin(a), a - 90, 0.5)
                    end
                end
            elseif mode == 2 then
                local now = b.cards[b.card_num]
                local rate = b.__hpbar_defaultpercent * now.hp / b.__hpbar_defaultvalue
                local ang = min(360 * rate, 359)

                misc.Renderhpbar(b.x, b.y, 90, 360, 60, 64, 360, 1)
                misc.Renderhp(b.x, b.y, 90, ang, 60, 64, ang + 2, b.hpbarlen)
                Render("base_hp", b.x, b.y, 0, 0.274, 0.274)
                Render("base_hp", b.x, b.y, 0, 0.256, 0.256)


            elseif mode == 1 then
                local nextcard
                for n = b.card_num + 1, #b.cards do
                    if b.cards[n] and b.cards[n].is_combat then
                        nextcard = b.cards[n]
                        break
                    end
                end
                local rate = b.__hpbar_defaultpercent * nextcard.hp / b.__hpbar_defaultvalue
                local ang = min(360 * rate, 359)

                misc.Renderhpbar(b.x, b.y, 90, 360, 60, 64, 360, 1)
                if b.__hpbar_timer <= (b.__hpbar_rendertime * rate) then
                    misc.Renderhp(b.x, b.y, 90, ang, 60, 64, 360, min(1, b.__hpbar_timer / (b.__hpbar_rendertime * rate)))
                    Render("base_hp", b.x, b.y, 0, 0.274, 0.274)
                    Render("base_hp", b.x, b.y, 0, 0.256, 0.256)
                else
                    misc.Renderhp(b.x, b.y, 90, ang, 60, 64, 360, 1)
                    misc.Renderhp(b.x, b.y, 90 + ang, 360 - ang, 60, 64, 360, b.hpbarlen * min(1, (b.__hpbar_timer - (b.__hpbar_rendertime * rate)) / (b.__hpbar_rendertime - (b.__hpbar_rendertime * rate))))
                    Render("base_hp", b.x, b.y, 0, 0.274, 0.274)
                    Render("base_hp", b.x, b.y, 0, 0.256, 0.256)
                    Render("life_node", b.x + 61 * cos(ang + 90), b.y + 61 * sin(ang + 90), ang, 0.55)
                end
            elseif mode == 4 then
                local now = b.cards[b.card_num]
                local rate1 = b.__hpbar_defaultpercent * now.hp / b.__hpbar_defaultvalue
                --local ang1 = min (360 * rate1 , 179)
                local ang1 = 360 * rate1
                local nextcard
                for n = b.card_num + 1, #b.cards do
                    if b.cards[n] and b.cards[n].is_combat then
                        nextcard = b.cards[n]
                        break
                    end
                end
                local rate2 = b.__hpbar_defaultpercent * nextcard.hp / b.__hpbar_defaultvalue
                --local ang2 = min (360 * rate2 , 179)
                local ang2 = 360 * rate2
                misc.Renderhpbar(b.x, b.y, 90, 360, 60, 64, 360, 1)
                misc.Renderhp(b.x, b.y, 90, ang2, 60, 64, 360, 1)
                misc.Renderhp(b.x, b.y, 90 + ang2, ang1, 60, 64, ang1 + 2, b.hpbarlen)
                Render("base_hp", b.x, b.y, 0, 0.274, 0.274)
                Render("base_hp", b.x, b.y, 0, 0.256, 0.256)
                Render("life_node", b.x + 61 * cos(ang2 + 90), b.y + 61 * sin(ang2 + 90), ang2, 0.55)
            elseif mode == 5 then
                local nextcard, next2card, temp
                for n = b.card_num + 1, #b.cards do
                    if b.cards[n] and b.cards[n].is_combat then
                        nextcard = b.cards[n]
                        temp = n
                        break
                    end
                end
                local rate1 = b.__hpbar_defaultpercent * nextcard.hp / b.__hpbar_defaultvalue
                --local ang1 = min (360 * rate1 , 179)
                local ang1 = 360 * rate1
                local R1 = b.__hpbar_rendertime * rate1

                for n = temp + 1, #b.cards do
                    if b.cards[n] and b.cards[n].is_combat then
                        next2card = b.cards[n]
                        break
                    end
                end
                local rate2 = b.__hpbar_defaultpercent * next2card.hp / b.__hpbar_defaultvalue
                --local ang2 = min (360 * rate2 , 179)
                local ang2 = 360 * rate2
                local R2 = b.__hpbar_rendertime * rate2

                local rate_all = rate1 + rate2
                local ang_all = ang1 + ang2
                local R_all = R1 + R2

                misc.Renderhpbar(b.x, b.y, 90, 360, 60, 64, 360, 1)
                if b.__hpbar_timer <= (R2) then
                    misc.Renderhp(b.x, b.y, 90, ang2, 60, 64, 360, min(1, b.__hpbar_timer / (R2)))
                    Render("base_hp", b.x, b.y, 0, 0.274, 0.274)
                    Render("base_hp", b.x, b.y, 0, 0.256, 0.256)
                elseif b.__hpbar_timer <= (R1 + R2) then
                    misc.Renderhp(b.x, b.y, 90, ang2, 60, 64, 360, 1)
                    misc.Renderhp(b.x, b.y, 90 + ang2, ang1, 60, 64, 360, min(1, (b.__hpbar_timer - (R2)) / (R1)))
                    Render("base_hp", b.x, b.y, 0, 0.274, 0.274)
                    Render("base_hp", b.x, b.y, 0, 0.256, 0.256)
                    Render("life_node", b.x + 61 * cos(ang2 + 90), b.y + 61 * sin(ang2 + 90), ang2, 0.55)
                else
                    misc.Renderhp(b.x, b.y, 90, ang2, 60, 64, 360, 1)
                    misc.Renderhp(b.x, b.y, 90 + ang2, ang1, 60, 64, 360, 1)
                    misc.Renderhp(b.x, b.y, 90 + ang_all, 360 - ang_all, 60, 64, 360, b.hpbarlen * min(1, (b.__hpbar_timer - (R_all)) / (b.__hpbar_rendertime * (1 - rate_all))))
                    Render("base_hp", b.x, b.y, 0, 0.274, 0.274)
                    Render("base_hp", b.x, b.y, 0, 0.256, 0.256)
                    Render("life_node", b.x + 61 * cos(ang2 + 90), b.y + 61 * sin(ang2 + 90), ang2, 0.55)
                    Render("life_node", b.x + 61 * cos(ang_all + 90), b.y + 61 * sin(ang_all + 90), ang_all, 0.55)
                end
            elseif mode == 6 then
                local nextcard
                for n = b.card_num + 1, #b.cards do
                    if b.cards[n] and b.cards[n].is_combat then
                        nextcard = b.cards[n]
                        break
                    end
                end
                local now = b.cards[b.card_num]
                local lastcard
                for n = b.card_num - 1, 1, -1 do
                    if b.cards[n] and b.cards[n].is_combat then
                        lastcard = b.cards[n]
                        break
                    end
                end

                local rate = b.__hpbar_defaultpercent * nextcard.hp / b.__hpbar_defaultvalue
                --local ang = min (360 * rate , 179)
                local ang = 360 * rate
                local rate2 = (1 - rate) * now.hp / (now.hp + lastcard.hp)
                local ang2 = 360 * rate2
                misc.Renderhpbar(b.x, b.y, 90, 360, 60, 64, 360, 1)
                misc.Renderhp(b.x, b.y, 90, ang, 60, 64, 360, 1)
                misc.Renderhp(b.x, b.y, 90 + ang, ang2, 60, 64, ang2 + 2, b.hpbarlen)
                Render("base_hp", b.x, b.y, 0, 0.274, 0.274)
                Render("base_hp", b.x, b.y, 0, 0.256, 0.256)
                Render("life_node", b.x + 61 * cos(ang + 90), b.y + 61 * sin(ang + 90), ang, 0.55)
            elseif mode == 7 then
                local nextcard, next2card, temp
                local now = b.cards[b.card_num]

                for n = b.card_num + 1, #b.cards do
                    if b.cards[n] and b.cards[n].is_combat then
                        nextcard = b.cards[n]
                        temp = n
                        break
                    end
                end

                for n = temp + 1, #b.cards do
                    if b.cards[n] and b.cards[n].is_combat then
                        next2card = b.cards[n]
                        break
                    end
                end
                local rate2 = b.__hpbar_defaultpercent * next2card.hp / b.__hpbar_defaultvalue
                --local ang2 = min (360 * rate2 , 179)
                local ang2 = 360 * rate2
                local R2 = b.__hpbar_rendertime * rate2

                local rate1 = (1 - rate2) * nextcard.hp / (now.hp + nextcard.hp)
                local ang1 = 360 * rate1
                local R1 = b.__hpbar_rendertime * rate1

                local rate_all = rate1 + rate2
                local ang_all = ang1 + ang2
                local R_all = R1 + R2

                misc.Renderhpbar(b.x, b.y, 90, 360, 60, 64, 360, 1)
                if b.__hpbar_timer <= (R2) then
                    misc.Renderhp(b.x, b.y, 90, ang2, 60, 64, 360, min(1, b.__hpbar_timer / (R2)))
                    Render("base_hp", b.x, b.y, 0, 0.274, 0.274)
                    Render("base_hp", b.x, b.y, 0, 0.256, 0.256)
                elseif b.__hpbar_timer <= (R1 + R2) then
                    misc.Renderhp(b.x, b.y, 90, ang2, 60, 64, 360, 1)
                    misc.Renderhp(b.x, b.y, 90 + ang2, ang1, 60, 64, 360, min(1, (b.__hpbar_timer - (R2)) / (R1)))
                    Render("base_hp", b.x, b.y, 0, 0.274, 0.274)
                    Render("base_hp", b.x, b.y, 0, 0.256, 0.256)
                    Render("life_node", b.x + 61 * cos(ang2 + 90), b.y + 61 * sin(ang2 + 90), ang2, 0.55)
                else
                    misc.Renderhp(b.x, b.y, 90, ang2, 60, 64, 360, 1)
                    misc.Renderhp(b.x, b.y, 90 + ang2, ang1, 60, 64, 360, 1)
                    misc.Renderhp(b.x, b.y, 90 + ang_all, 360 - ang_all, 60, 64, 360, b.hpbarlen * min(1, (b.__hpbar_timer - (R_all)) / (b.__hpbar_rendertime * (1 - rate_all))))
                    Render("base_hp", b.x, b.y, 0, 0.274, 0.274)
                    Render("base_hp", b.x, b.y, 0, 0.256, 0.256)
                    Render("life_node", b.x + 61 * cos(ang2 + 90), b.y + 61 * sin(ang2 + 90), ang2, 0.55)
                    Render("life_node", b.x + 61 * cos(ang_all + 90), b.y + 61 * sin(ang_all + 90), ang_all, 0.55)
                end
            end
        elseif flag2 == 2 then
            if mode == -1 then
            else
                local c0 = b.__c0
                local c1 = b.__c1
                local c2 = b.__c2
                local c3 = b.__c3
                local c4 = b.__c4

                SetImageState('hpbar', '', c0)
                if mode == 0 and type == 1 then
                    Render('hpbar', -183, 217, 90, 0.25, 2.55 * b.hpbarlen * min(1, b.__hpbar_timer / b.__hpbar_rendertime))
                    SetImageState('hpbar', '', c2)
                    Render('hpbar', -184, 218, 90, 0.25, 2.55 * b.hpbarlen * min(1, b.__hpbar_timer / b.__hpbar_rendertime))
                elseif mode == 0 and type == 2 then
                    Render('hpbar', -183, 217, 90, 0.25, 2.55 * b.hpbarlen * min(1, b.__hpbar_timer / b.__hpbar_rendertime))
                    SetImageState('hpbar', '', c1)
                    Render('hpbar', -184, 218, 90, 0.25, 2.55 * b.hpbarlen * min(1, b.__hpbar_timer / b.__hpbar_rendertime))
                elseif mode == 2 then
                    local now = b.cards[b.card_num]
                    local rate = b.__hpbar_defaultpercent * now.hp / b.__hpbar_defaultvalue
                    Render('hpbar', -183, 217, 90, 0.25, 2.55 * b.hpbarlen * rate)
                    SetImageState('hpbar', '', c2)
                    Render('hpbar', -184, 218, 90, 0.25, 2.55 * b.hpbarlen * rate)
                elseif mode == 1 then
                    local nextcard
                    for n = b.card_num + 1, #b.cards do
                        if b.cards[n] and b.cards[n].is_combat then
                            nextcard = b.cards[n]
                            break
                        end
                    end
                    local rate = b.__hpbar_defaultpercent * nextcard.hp / b.__hpbar_defaultvalue
                    Render('hpbar', -183, 217, 90, 0.25, 2.55 * min(1, b.__hpbar_timer / (b.__hpbar_rendertime * rate)) * rate)
                    SetImageState('hpbar', '', c2)
                    Render('hpbar', -184, 218, 90, 0.25, 2.55 * min(1, b.__hpbar_timer / (b.__hpbar_rendertime * rate)) * rate)

                    if b.__hpbar_timer > (b.__hpbar_rendertime * rate) then
                        SetImageState('hpbar', '', c0)
                        Render('hpbar', -183 + 2.55 * 128 * rate, 217, 90, 0.25, 2.55 * b.hpbarlen * min(1, (b.__hpbar_timer - (b.__hpbar_rendertime * rate)) / (b.__hpbar_rendertime - (b.__hpbar_rendertime * rate))) * (1 - rate))
                        SetImageState('hpbar', '', c1)
                        Render('hpbar', -184 + 2.55 * 128 * rate, 218, 90, 0.25, 2.55 * b.hpbarlen * min(1, (b.__hpbar_timer - (b.__hpbar_rendertime * rate)) / (b.__hpbar_rendertime - (b.__hpbar_rendertime * rate))) * (1 - rate))
                    end
                elseif mode == 4 then
                    local now = b.cards[b.card_num]
                    local rate = b.__hpbar_defaultpercent * now.hp / b.__hpbar_defaultvalue
                    local nextcard
                    for n = b.card_num + 1, #b.cards do
                        if b.cards[n] and b.cards[n].is_combat then
                            nextcard = b.cards[n]
                            break
                        end
                    end
                    local rate_2 = b.__hpbar_defaultpercent * nextcard.hp / b.__hpbar_defaultvalue
                    Render('hpbar', -183, 217, 90, 0.25, 2.55 * rate)
                    SetImageState('hpbar', '', c2)
                    Render('hpbar', -184, 218, 90, 0.25, 2.55 * rate)
                    SetImageState('hpbar', '', c0)
                    Render('hpbar', -183 + 2.55 * 128 * rate, 217, 90, 0.25, 2.55 * b.hpbarlen * rate_2)
                    SetImageState('hpbar', '', c4)
                    Render('hpbar', -184 + 2.55 * 128 * rate, 218, 90, 0.25, 2.55 * b.hpbarlen * rate_2)
                elseif mode == 5 then
                    local nextcard, next2card, temp
                    for n = b.card_num + 1, #b.cards do
                        if b.cards[n] and b.cards[n].is_combat then
                            nextcard = b.cards[n]
                            temp = n
                            break
                        end
                    end
                    local rate = b.__hpbar_defaultpercent * nextcard.hp / b.__hpbar_defaultvalue
                    for n = temp + 1, #b.cards do
                        if b.cards[n] and b.cards[n].is_combat then
                            next2card = b.cards[n]
                            break
                        end
                    end
                    local rate_2 = b.__hpbar_defaultpercent * next2card.hp / b.__hpbar_defaultvalue
                    local R1 = b.__hpbar_rendertime * rate
                    local R2 = b.__hpbar_rendertime * rate_2
                    local rate_all = rate + rate_2
                    local R_all = R1 + R2

                    Render('hpbar', -183, 217, 90, 0.25, 2.55 * min(1, b.__hpbar_timer / (R2)) * rate_2)
                    SetImageState('hpbar', '', c2)
                    Render('hpbar', -184, 218, 90, 0.25, 2.55 * min(1, b.__hpbar_timer / (R2)) * rate_2)

                    if b.__hpbar_timer > (R2) then
                        SetImageState('hpbar', '', c0)
                        Render('hpbar', -183 + 2.55 * 128 * rate_2, 217, 90, 0.25, 2.55 * min(1, (b.__hpbar_timer - R2) / R1) * rate)
                        SetImageState('hpbar', '', c4)
                        Render('hpbar', -184 + 2.55 * 128 * rate_2, 218, 90, 0.25, 2.55 * min(1, (b.__hpbar_timer - R2) / R1) * rate)
                    end

                    if b.__hpbar_timer > (R1 + R2) then
                        SetImageState('hpbar', '', c0)
                        Render('hpbar', -183 + 2.55 * 128 * rate_all, 217, 90, 0.25, 2.55 * b.hpbarlen * min(1, (b.__hpbar_timer - (R_all)) / (b.__hpbar_rendertime - (R_all))) * (1 - rate_all))
                        SetImageState('hpbar', '', c1)
                        Render('hpbar', -184 + 2.55 * 128 * rate_all, 218, 90, 0.25, 2.55 * b.hpbarlen * min(1, (b.__hpbar_timer - (R_all)) / (b.__hpbar_rendertime - (R_all))) * (1 - rate_all))
                    end
                elseif mode == 6 then
                    local nextcard
                    for n = b.card_num + 1, #b.cards do
                        if b.cards[n] and b.cards[n].is_combat then
                            nextcard = b.cards[n]
                            break
                        end
                    end
                    local now = b.cards[b.card_num]
                    local lastcard
                    for n = b.card_num - 1, 1, -1 do
                        if b.cards[n] and b.cards[n].is_combat then
                            lastcard = b.cards[n]
                            break
                        end
                    end
                    local rate = b.__hpbar_defaultpercent * nextcard.hp / b.__hpbar_defaultvalue
                    local rate_2 = (1 - rate) * now.hp / (now.hp + lastcard.hp)

                    Render('hpbar', -183, 217, 90, 0.25, 2.55 * rate)
                    SetImageState('hpbar', '', c2)
                    Render('hpbar', -184, 218, 90, 0.25, 2.55 * rate)

                    SetImageState('hpbar', '', c0)
                    Render('hpbar', -183 + 2.55 * 128 * rate, 217, 90, 0.25, 2.55 * b.hpbarlen * rate_2)
                    SetImageState('hpbar', '', c3)
                    Render('hpbar', -184 + 2.55 * 128 * rate, 218, 90, 0.25, 2.55 * b.hpbarlen * rate_2)
                elseif mode == 7 then
                    local nextcard, next2card, temp
                    local now = b.cards[b.card_num]

                    for n = b.card_num + 1, #b.cards do
                        if b.cards[n] and b.cards[n].is_combat then
                            nextcard = b.cards[n]
                            temp = n
                            break
                        end
                    end

                    for n = temp + 1, #b.cards do
                        if b.cards[n] and b.cards[n].is_combat then
                            next2card = b.cards[n]
                            break
                        end
                    end
                    local rate_2 = b.__hpbar_defaultpercent * next2card.hp / b.__hpbar_defaultvalue
                    local R2 = b.__hpbar_rendertime * rate_2

                    local rate = (1 - rate_2) * nextcard.hp / (now.hp + nextcard.hp)
                    local R1 = b.__hpbar_rendertime * rate
                    local rate_all = rate + rate_2
                    local R_all = R1 + R2

                    Render('hpbar', -183, 217, 90, 0.25, 2.55 * min(1, b.__hpbar_timer / (R2)) * rate_2)
                    SetImageState('hpbar', '', c2)
                    Render('hpbar', -184, 218, 90, 0.25, 2.55 * min(1, b.__hpbar_timer / (R2)) * rate_2)

                    if b.__hpbar_timer > (R2) then
                        SetImageState('hpbar', '', c0)
                        Render('hpbar', -183 + 2.55 * 128 * rate_2, 217, 90, 0.25, 2.55 * min(1, (b.__hpbar_timer - R2) / R1) * rate)
                        SetImageState('hpbar', '', c3)
                        Render('hpbar', -184 + 2.55 * 128 * rate_2, 218, 90, 0.25, 2.55 * min(1, (b.__hpbar_timer - R2) / R1) * rate)
                    end

                    if b.__hpbar_timer > (R1 + R2) then
                        SetImageState('hpbar', '', c0)
                        Render('hpbar', -183 + 2.55 * 128 * rate_all, 217, 90, 0.25, 2.55 * b.hpbarlen * min(1, (b.__hpbar_timer - (R_all)) / (b.__hpbar_rendertime - (R_all))) * (1 - rate_all))
                        SetImageState('hpbar', '', c1)
                        Render('hpbar', -184 + 2.55 * 128 * rate_all, 218, 90, 0.25, 2.55 * b.hpbarlen * min(1, (b.__hpbar_timer - (R_all)) / (b.__hpbar_rendertime - (R_all))) * (1 - rate_all))
                    end

                end
            end
        end
    end
    if b.show_hp then
        SetFontState("bonus", "", Color(255, 0, 0, 0))
        RenderText("bonus", int(max(0, b.hp)) .. "/" .. b.maxhp, b.x - 1, b.y - 40 - 1, 0.6, "centerpoint")
        SetFontState("bonus", "", Color(255, 255, 255, 255))
        RenderText("bonus", int(max(0, b.hp)) .. "/" .. b.maxhp, b.x, b.y - 40, 0.6, "centerpoint")
    end
end

----------------------------------------
---boss 计时器
---@class boss.timeCounter
---@return boss.timeCounter
boss.timeCounter = plus.Class()
local timeCounter = boss.timeCounter
---@param ui boss.ui
---@param system boss.system
function timeCounter:init(ui, system)
    self.ui = ui
    self.system = system
    local b = self.system.boss
    if b.__hpbartype2 and int(b.__hpbartype2 / 10) == 2 then
        self.x, self.y = 176, 214
        self.oldstyle = true
    else
        self.x, self.y = 2, 192
        self.oldstyle = false
    end
    self.scale = 0.5
    self.scalewarning = 1
    self.scalewarning_current = 1.0
    self.scalewarning_1 = 1.25
    self.scalewarning_2 = 1.5
    self.yoffset = 0
    self.yoffsettemp = 0
    self.yoffsetmax = 24
    self.yoffsetspeedrate = 0.4
    self.open = false
    self.t1 = 10
    self.t2 = 5
    self.sound = true
    self.flag = 0
    self.cd1 = 0
    self.cd2 = 0
end
function timeCounter:frame()
    local _ui = self.ui
    local b = self.system.boss
    if not (IsValid(b)) then
        return
    end
    assert(self.t2 <= self.t1, "time counter's t1 > t2 must be satisfied.")
    if b.__hpbartype2 and int(b.__hpbartype2 / 10) == 2 then
        self.x, self.y = 176, 214
        self.oldstyle = true
    else
        self.x, self.y = 2, 192
        self.oldstyle = false
    end
    if _ui.countdown and self.sound then
        if _ui.countdown > self.t2 and _ui.countdown <= self.t1 and _ui.countdown % 1 == 0 then
            PlaySound("timeout", 0.6)
            self.scalewarning = self.scalewarning_1
            self.scalewarning_current = self.scalewarning_1
        end
        if _ui.countdown > 0 and _ui.countdown <= self.t2 and _ui.countdown % 1 == 0 then
            PlaySound("timeout2", 0.8)
            self.scalewarning = self.scalewarning_2
            self.scalewarning_current = self.scalewarning_2
        end
    end
    if not (self.open) then
        if not (b.__is_waiting) and b.is_combat then
            if b.is_sc then
                self.yoffsettemp = self.yoffsetmax
            else
                self.yoffsettemp = 0
            end
            self.open = true
        end
    elseif (b.__is_waiting and (lstg.player.dialog or not self.ui.drawtimesaver)) or (not (b.is_combat) and (lstg.player.dialog or not self.ui.drawtimesaver)) then
        self.open = false
        self.ui.drawtimesaver = nil
    end
    if self.open then
        if b.is_sc then
            self.yoffsettemp = max(0, self.yoffsettemp - 1 * self.yoffsetspeedrate)
            local s = self.yoffsettemp / self.yoffsetmax
            self.yoffset = (s * s) * self.yoffsetmax
        else
            self.yoffsettemp = min(self.yoffsetmax, self.yoffsettemp + 1 * self.yoffsetspeedrate)
            local s = self.yoffsettemp / self.yoffsetmax
            self.yoffset = (s * s) * self.yoffsetmax
        end

        if not self.ui.drawtimesaver or _ui.countdown ~= 0 then
            self.cd1 = _ui.countdown
        end

        if not b.is_combat and self.ui.drawtimesaver and not lstg.player.dialog then
            self.cd1 = self.ui.drawtimesaver
        end

        self.cd2 = (self.cd1 - int(self.cd1)) * 100
        local players
        if Players then
            players = Players(b)
        else
            players = { player }
        end
        local _flag = false
        for _, p in pairs(players) do
            if IsValid(p) and Dist(p.x, p.y, self.x, self.y) <= 70 then
                _flag = true
                break
            end
        end
        if _flag then
            self.flag = self.flag + 1
        else
            self.flag = self.flag - 1
        end
        self.flag = min(max(0, self.flag), 18)
    else
        self.flag = 0
    end
    if self.scalewarning > 1 then
        self.scalewarning = self.scalewarning - (self.scalewarning_current - 1.0) * 0.2
    else
        self.scalewarning = 1
        self.scalewarning_current = 1.0
    end
end
function timeCounter:render()
    local b = self.system.boss
    if not (IsValid(b)) then
        return
    end
    if self.open and self.ui.drawtime then
        local alpha1 = 1 - self.flag / 30
        local cd1, cd2 = max(self.cd1, 0), max(self.cd2, 0)
        local dy = (b.ui_slot - 1) * 44
        local x = self.x
        local y1
        if self.oldstyle then
            y1 = self.y - dy
        else
            y1 = self.y + self.yoffset - dy
        end
        local y2 = y1 - 3
        local scalew = self.scalewarning
        local scale1 = self.scale
        local scale2 = scale1 * 0.6
        if cd1 >= self.t1 then
            SetFontState("time", "", Color(alpha1 * 255, 255, 255, 255))
        elseif cd1 >= self.t2 then
            SetFontState("time", "", Color(alpha1 * 255, 255, 144, 144))
        else
            SetFontState("time", "", Color(alpha1 * 255, 255, 48, 48))
        end
        if self.cd1 >= 99.99 and b.__disallow_100sec then
            cd1 = 99
            cd2 = 99
        end
        if cd1 >= self.t1 then
            RenderText("time", string.format("%2d", int(cd1)) .. ".", x, y1, scale1, "vcenter", "right")
            RenderText("time", string.format("%d%d", min(9, cd2 / 10), min(9, cd2 % 10)), x, y2, scale2, "vcenter", "left")
        else
            RenderText("time", string.format("0%d", min(99.99, int(cd1))) .. " ", x, y1, scale1 * scalew, "vcenter", "right")
            RenderText("time", ".", x, y1, scale1, "vcenter", "right")
            RenderText("time", string.format("%d%d", min(9, cd2 / 10), min(9, cd2 % 10)), x, y2, scale2, "vcenter", "left")
        end
    end
end

----------------------------------------
---boss 下标
---@class boss.pointer
---@return boss.pointer
boss.pointer = plus.Class()
local pointer = boss.pointer
---@param ui boss.ui
---@param system boss.system
function pointer:init(ui, system)
    self.ui = ui
    self.system = system
    self.y = lstg.world.b
    self.scale = 1
    self.EnemyIndicater = 0
end
function pointer:frame()
    local b = self.system.boss
    if not (IsValid(b)) then
        return
    end
    if b.hp >= 0 then
        self.EnemyIndicater = self.EnemyIndicater + (max(0, (b.maxhp / 2 - b.hp))) / (b.maxhp / 2) * 90
    end
end
function pointer:render()
    local _ui = self.ui
    local b = self.system.boss
    if not (IsValid(b)) then
        return
    end
    if _ui.pointer_x and _ui.drawpointer then
        local w = lstg.world
        local scale = self.scale
        SetRenderRect(w.l, w.r, w.b - max(16 * scale, 0), w.t,
                w.scrl, w.scrr, w.scrb - max(16 * scale, 0), w.scrt)
        local x, y = _ui.pointer_x, self.y
        local distsub = 1
        local players
        if Players then
            players = Players(b)
        else
            players = { player }
        end
        for _, p in pairs(players) do
            if IsValid(p) then
                distsub = min((1 - (min(abs(x - p.x), 64) / 128)), distsub)
            end
        end
        local hpsub = (sin(self.EnemyIndicater + 270) + 1) * 0.125
        local alpha = (1 - distsub * 0.6 - hpsub) * 255
        SetImageState("boss_pointer", "", Color(alpha, 255, 255, 255))
        Render("boss_pointer", x, y, 0, self.scale)
        SetViewMode "world"
    end
end

----------------------------------------
---boss 信息板
---@class boss.infobar
---@return boss.infobar
boss.infobar = plus.Class()
local infobar = boss.infobar
function infobar:init(ui, system)
    self.ui = ui
    self.system = system
    local b = self.system.boss
    if b.__hpbartype2 and int(b.__hpbartype2 / 10) == 2 then
        self.x, self.y = -185, 213
    else
        self.x, self.y = -185, 222
    end
    self.t = 0
    self.mt = 15
end
function infobar:frame()
    local b = self.system.boss
    if not (IsValid(b)) then
        return
    end
    if b.__hpbartype2 and int(b.__hpbartype2 / 10) == 2 then
        self.x, self.y = -185, 213
    else
        self.x, self.y = -185, 222
    end
    local bscl = b.sc_left
    if self.sc_left == nil then
        self.sc_left = bscl
    end
    if self.sc_left > bscl then
        self.t = self.t + self.mt * (self.sc_left - bscl)
        self.sc_left = bscl
    end
    if self.t > 0 then
        self.t = self.t - 1
    end
end
function infobar:render()
    local _ui = self.ui
    local b = self.system.boss
    if not (IsValid(b)) then
        return
    end
    if _ui.drawname then
        local dy = (b.ui_slot - 1) * 44
        local x, y = self.x, self.y - dy
        local anisc = int(self.t / self.mt)
        local sc_left = self.sc_left + anisc
        RenderTTF('boss_name', b.name, x, x, y, y, Color(0xFF000000), "noclip")
        x = x - 1
        y = y + 1
        RenderTTF('boss_name', b.name, x, x, y, y, Color(0xFF80FF80), "noclip")
        local m = int((sc_left - 1) / 8)
        local m2 = sc_left - 1 - 8 * m
        x = self.x - 9
        y = self.y - 15 - dy
        if m >= 0 then
            SetImageState("boss_cardleft", "", Color(0xFFFFFFFF))
            for i = 0, m - 1 do
                for j = 1, 8 do
                    Render('boss_cardleft', x + j * 12, y - i * 12, 0, 0.5)
                end
            end
            y = y - m * 12
            for i = 1, m2 do
                Render("boss_cardleft", x + i * 12, y, 0, 0.5)
            end
            local t, at, x2, y2
            t = self.mt - (self.t - anisc * self.mt)
            at = self.mt
            if self.t > 0 then
                x2 = x + (m2 + 1) * 12 + t / 5
                y2 = y - t / 5
                SetImageState("boss_cardleft", "",
                        Color(255 * (1 - (t / at)), 255, 255, 255))
                Render("boss_cardleft", x2, y2, 0, 0.5 + (t / at) * 0.5)
            end
        end
    end
end

----------------------------------------
---boss 符卡名（gzz式）
---@class boss.sc_name
---@return boss.sc_name
boss.sc_name = Class(object)
local sc_name = boss.sc_name
---@param b object @目标对象
---@param name string @符卡名称
---@param score boolean @是否显示score
local sc_name = boss.sc_name
function sc_name:init(b, name, score)
    if score == nil then
        score = true
    end
    self.layer = LAYER_TOP + 1
    self.boss = b
    self.name = name or ""
    self.score = score
    self.xp = -8
    self.yp = 0
    if self.name == "" then
        RawDel(self)
    end
    self.x = 192
    self.y = 236
    self.ybot = 380
    self.xoffset = 200
    self.xoffset2 = 0
    self.yoffset = -self.ybot
    local b = self.boss
    if b.__hpbartype2 and int(b.__hpbartype2 / 10) == 2 then
        self.yp = -8
    end
    self.bound = false
    self.flag = 0
    self._scale = 1
    self._scale2 = 1
    self._alpha = 0
    self.talpha = 0
    self.talpha2 = 0
end
function sc_name:frame()
    local b = self.boss
    local _ui = b.ui
    local sc_hist = 0
    if IsValid(b) then
        sc_hist = b._sc_hist
    end
    if IsValid(_ui) then
        self.hide = not (_ui.drawspell)
        sc_hist = _ui.sc_hist
    end
    self.sc_hist = sc_hist
    local t, t1, t2, ct, t3 = 60, 30, 30, 10, 40
    local etc = abs(t2 - t3) - 0
    if IsValid(b) then
        local dy = (b.ui_slot - 1) * 44
        self._dy = dy
        local bonus
        if b.sc_bonus then
            bonus = string.format("0%.0f", b.sc_bonus - b.sc_bonus % 10)
        else
            bonus = "FAILED"
        end
        self.bonus = bonus
        local players
        if Players then
            players = Players(b)
        else
            players = { player }
        end
        local _flag = false
        local x = self.x
        local y = self.y + self.yoffset + dy
        for _, p in pairs(players) do
            if IsValid(p) and abs(p.x - x) <= 180
                    and abs(p.y - y) <= 60
                    and self.timer > 100 + etc + t1 then
                _flag = true
                break
            end
        end
        if _flag then
            self.flag = self.flag + 1
        else
            self.flag = self.flag - 1
        end
    else
        self.flag = 0
    end
    self.flag = min(max(0, self.flag), 18)
    if not (self.death) then
        if self.timer > 30 then
            self.xoffset = max(self.xoffset - 10, 0)
        end
        self.xoffset2 = 0
        local _t = self.timer - 60
        local _t1 = 100 + etc
        local _t2 = _t1 + t1
        local _t3 = 60 + etc
        local _t4 = _t3 + t
        local _t5 = t3 - ct
        local _t6 = _t5 + t2
        if self.timer > _t1 and self.timer < _t2 then
            self.talpha = min(self.talpha + (1 / t1), 1)
        end
        if self.timer > _t3 and self.timer < _t4 then
            local tmp = (90 / t) * (_t - etc)
            self.yoffset = -self.ybot + (self.ybot + self.yp) * sin(tmp * sin(tmp))
        end
        if self.timer > _t5 and self.timer < _t6 then
            self.talpha2 = min(self.talpha2 + (1 / t2), 1)
            self._scale2 = max(1 - sin((90 / t2) * (self.timer - t3 + ct)), 0)
        end
        if self.timer < t3 then
            self._scale = max(150 - 120 * sin((90 / t3) * self.timer), 30) / 30
        end
        self._alpha = min(self.timer / t3, 1)
    else
        if IsValid(b) and b.is_exploding and not (self.explodeFlag) then
            self.timer = -60
            self.explodeFlag = true
        end
        if self.timer > 0 then
            self.xoffset = min(self.xoffset + 8 + self.xp, 220)
        end
        self.xoffset2 = self.xoffset
        self._scale = 1
        self._alpha = 1
        if self.timer > 60 then
            RawDel(self)
        end
    end
end
function sc_name:render()
    local b = self.boss
    local sc_hist = self.sc_hist or { 0, 0 }
    local bonus = self.bonus
    local dy = self._dy
    local x = self.x + self.xoffset + self.xp
    local y = self.y + self.yoffset - dy + self.yp
    local alpha = 1 - self.flag / 30
    local alpha2 = alpha * self._alpha
    local s = GetImageScale()
    SetImageState("boss_spell_name_bg", "",
            Color(alpha * 255 * self.talpha2, 255, 255, 255))
    x = self.x + self.xoffset2
    Render("boss_spell_name_bg", x, y, 0, 1 + 0.5 * self._scale2)
    x = self.x + self.xoffset2 + self.xp
    y = y - 10
    SetImageScale(s * self._scale)
    local d = sqrt(2)
    local _x, _y
    for i = 0, 8 do
        --沙雕描边
        _x = x + d * cos(i * 45)
        _y = y + d * sin(i * 45)
        RenderTTF("sc_name", self.name,
                _x, _x, _y - 2, _y - 2,
                Color(alpha2 * 255, 0, 0, 0),
                "right", "noclip")
    end
    RenderTTF("sc_name", self.name,
            x, x, y - 2, y - 2,
            Color(alpha2 * 255, 255, 255, 255),
            "right", "noclip")
    SetImageScale(s)
    local a = alpha * 255 * self.talpha
    if self.score then
        local fontsize = 0.5
        local xm, ym = 4, -1 --字符坐标偏移值
        x = self.x + self.xoffset - 5 + self.xp
        y = self.y - dy - 31 + self.yp
        SetFontState("bonus2", "", Color(a, 0, 0, 0))
        --RenderText("bonus2", bonus, x - 90, y, fontsize, "right")
        --RenderText("bonus2", string.format("%d/%d", sc_hist[1], sc_hist[2]), x, y, fontsize, "right")
        --RenderText("bonus", "BONUS          HISTORY", x - 40, y, 0.5, "right")
        SetImageState("cardui_history", "", Color(a, 255, 255, 255))
        SetImageState("cardui_bonus", "", Color(a, 255, 255, 255))
        Render("cardui_history", x - 63 + self.xp, y - 6 + self.yp, 0, 0.5)
        Render("cardui_bonus", x - 156 + self.xp, y - 6 + self.yp, 0, 0.5)
        SetFontState("bonus2", "", Color(a, 255, 255, 255))
        --x = x - 1
        --y = y + 1
        --RenderText("bonus", "BONUS          HISTORY", x - 40, y, 0.5, "right")

        if not (self.death) or (self.death and IsValid(b) and b.is_exploding and self.timer <= 0) then
            x = x + xm + 4 + self.xp
            y = y + ym + self.yp
            if bonus ~= "FAILED" then
                RenderText("bonus2", bonus, x - 90, y, fontsize, "right")
            else
                SetImageState("sc_failed", "", Color(a, 255, 255, 255))
                Render("sc_failed", x - 108, y - ym - 6, 0, fontsize)
            end
            if self.yp == 0 then
                if sc_hist[2] < 100 then
                    ---------对history显示原作化
                    x = x - 8
                    RenderText("bonus2", string.format("%02d/%02d", sc_hist[1], sc_hist[2]), x, y, fontsize, "right")
                elseif sc_hist[1] <= 99 then
                    x = x - 8
                    RenderText("bonus2", string.format("%02d/99+", sc_hist[1], sc_hist[2]), x, y, fontsize, "right")
                elseif sc_hist[1] > 99 then
                    SetImageState("sc_master", "", Color(a, 255, 255, 255))
                    Render("sc_master", x - 29, y - ym - 7, 0, fontsize)
                end
            else
                x = x - 52
                RenderText("bonus2", string.format("%02d/%02d", sc_hist[1], sc_hist[2]), x, y, fontsize, "left")
            end
        end
    end
end
function sc_name:kill()
    self.class.del(self)
end
function sc_name:del()
    PreserveObject(self)
    if not (self.death) then
        self.death = true
        self.timer = -1
    end
end

----------------------------------------
--boss ui（old）
--！警告：未适配宽屏等非传统版面

boss_ui = Class(object)

boss_ui.active_count = 0--多boss时，boss ui 槽位计数

function boss_ui:init(b)
    self.layer = LAYER_TOP
    self.group = GROUP_GHOST
    self.boss = b
    self.sc_name = ""
    self.drawhp = 1
    self.drawname = 1
    self.drawtime = 1
    self.drawspell = 1
    self.needposition = 1
    self.drawpointer = 1
    --b.ex={}
    --test_ex(b.ex)
    if b.class.sc_image then
        self.sc_image = New(b.class.sc_image)
    end
end

function boss_ui:frame()
    task.Do(self)
    if self.countdown then
        if self.countdown > 5 and self.countdown <= 10 and self.countdown % 1 == 0 then
            PlaySound("timeout", 0.6)
        end
        if self.countdown > 0 and self.countdown <= 5 and self.countdown % 1 == 0 then
            PlaySound("timeout2", 0.8)
        end
    end
end

function boss_ui:render()
    SetViewMode "world"

    local yn = boss_ui.active_count
    local dy1 = yn * 36
    local dy2 = yn * 44
    if self.needposition then
        boss_ui.active_count = boss_ui.active_count + 1
    end
    local _dy = 0
    local alpha1 = 1 - self.boss.hp_flag / 30

    SetImageState("base_hp", "", Color(alpha1 * 255, 255, 0, 0))
    SetImageState("hpbar1", "", Color(alpha1 * 255, 255, 255, 255))
    SetImageState("hpbar2", "", Color(0, 255, 255, 255))
    SetImageState("life_node", "", Color(alpha1 * 255, 255, 255, 255))
    --血条、boss名、剩余符卡
    if self.boss.ex then
        if self.boss.ex.cardcount and self.drawhp then
            boss_ui.render_hpbar_ex(self)
        end
    end
    --RenderText("bonus",self.ex.status,0,207,0.5,"right")
    if self.is_combat then
        if self.hpbarlen or self.boss.ex then
            --boss hpbar
            boss_ui.render_hpbar(self)
            --boss name and cards left
            if self.drawname then
                RenderTTF("boss_name", self.name, -185, -185, 222 - dy1, 222 - dy1, Color(0xFF000000), "noclip")
                RenderTTF("boss_name", self.name, -186, -186, 223 - dy1, 223 - dy1, Color(0xFF80FF80), "noclip")
                local m = int((self.sc_left - 1) / 8)
                if m >= 0 then
                    for i = 0, m - 1 do
                        for j = 1, 8 do
                            Render("boss_sc_left", -194 + j * 12, 207 - i * 12 - dy1, 0, 0.5)
                        end
                    end
                    for i = 1, int(self.sc_left - 1 - 8 * m) do
                        Render("boss_sc_left", -194 + i * 12, 207 - m * 12 - dy1, 0, 0.5)
                    end
                end
            end
        end
    end
    --位置指示器
    if self.pointer_x and self.drawpointer then
        SetViewMode "ui"
        Render("boss_pointer", WorldToScreen(max(min(self.pointer_x, lstg.world.r - 24), lstg.world.l + 24), lstg.world.b))--适配宽屏
        SetViewMode "world"
    end
    --为boss ex时，下方逻辑不执行
    if self.boss.ex then
        if self.boss.ex.status == 0 then
            return
        end
    end
    --透明度和位置处理
    local axy = 0
    local players
    if Players then
        players = Players(b)
    else
        players = { player }
    end
    for _, p in pairs(players) do
        local ax, ay = 0, 0
        if IsValid(p) then
            ax = min(max(p.x * 0.05, 0), 0.9)
            ay = min(max((p.y - 160) * 0.05, 0), 0.9)
        end
        if ax * ay > axy then
            axy = ax * ay
        end
    end
    local alpha = 1 - axy
    SetFontState("time", "", Color(alpha * 255, 255, 255, 255))
    local xoffset = 384
    if self.boss.sc_bonus then
        xoffset = max(384 - self.boss.timer * 7, 0)
    else
        xoffset = min(384, (self.boss.timer + 1) * 7)
    end
    --符卡
    if self.drawspell then
        if self.sc_name ~= "" then
            SetImageState("boss_spell_name_bg", "", Color(alpha * 255, 255, 255, 255))
            Render("boss_spell_name_bg", 192 + xoffset, 236 - dy2)
            RenderTTF("sc_name", self.sc_name, 193 + xoffset, 193 + xoffset, 226 - dy2, 226 - dy2, Color(alpha * 255, 0, 0, 0), "right", "noclip")
            RenderTTF("sc_name", self.sc_name, 192 + xoffset, 192 + xoffset, 227 - dy2, 227 - dy2, Color(alpha * 255, 255, 255, 255), "right", "noclip")
        end
        if self.boss.sc_bonus and self.sc_hist then
            local b
            if self.boss.sc_bonus > 0 then
                b = string.format("%.0f", self.boss.sc_bonus - self.boss.sc_bonus % 10)
            else
                b = "FAILED "
            end
            SetFontState("bonus", "", Color(alpha * 255, 0, 0, 0))
            RenderText("bonus", b, 187 + xoffset, 207 - dy2, 0.5, "right")
            RenderText("bonus", string.format("%d/%d", self.sc_hist[1], self.sc_hist[2]), 97 + xoffset, 207 - dy2, 0.5, "right")
            RenderText("bonus", "HISTORY        BONUS", 137 + xoffset, 207 - dy2, 0.5, "right")
            SetFontState("bonus", "", Color(alpha * 255, 255, 255, 255))
            RenderText("bonus", b, 186 + xoffset, 208 - dy2, 0.5, "right")
            RenderText("bonus", string.format("%d/%d", self.sc_hist[1], self.sc_hist[2]), 96 + xoffset, 208 - dy2, 0.5, "right")
            RenderText("bonus", "HISTORY        BONUS", 136 + xoffset, 208 - dy2, 0.5, "right")
        end
    end
    --非符、符卡时间
    if self.is_combat and self.drawtime then
        local cd = (self.countdown - int(self.countdown)) * 100
        local yoffset
        if self.boss.sc_bonus then
            yoffset = max(20 - self.boss.timer, 0)
        else
            yoffset = min(20, (self.boss.timer + 1))
        end
        if self.countdown >= 10.0 then
            SetFontState("time", "", Color(alpha1 * 255, 255, 255, 255))
            RenderText("time", string.format("%d", int(self.countdown)), 4, 192 + yoffset + _dy - dy2, 0.5, "vcenter", "right")
            RenderText("time", "." .. string.format("%d%d", min(9, cd / 10), min(9, cd % 10)), 4, 189 + yoffset + _dy - dy2, 0.3, "vcenter", "left")
        else
            SetFontState("time", "", Color(alpha1 * 255, 255, 30, 30))
            RenderText("time", string.format("0%d", min(99.99, int(self.countdown))), 4, 192 + yoffset + _dy - dy2, 0.5, "vcenter", "right")
            RenderText("time", "." .. string.format("%d%d", min(9, cd / 10), min(9, cd % 10)), 4, 189 + yoffset + _dy - dy2, 0.3, "vcenter", "left")
        end
    end
end

function boss_ui:render_hpbar()
    if not (self.boss.time_sc) and self.drawhp then
        local mode, type
        if not (self.hpbarcolor1) and not (self.hpbarcolor2) then
            mode = -1 --无血条（时符等）
        elseif not (self.hpbarcolor2) then
            mode = 0
            type = 1 --全血条（符卡）
        elseif not (self.hpbarcolor1) then
            mode = 0
            type = 2 --全血条（非符）
        elseif self.hpbarcolor1 == self.hpbarcolor2 then
            mode = 2 --组合血条（符卡）
        elseif self.hpbarcolor1 ~= self.hpbarcolor2 then
            mode = 1 --组合血条（非符）
        end
        if mode == -1 then
        elseif mode == 0 and type == 1 then
            misc.Renderhpbar(self.boss.x, self.boss.y, 90, 360, 60, 64, 360, 1)
            misc.Renderhp(self.boss.x, self.boss.y, 90, 360, 60, 64, 360, self.hpbarlen * min(1, self.boss.timer / 60))
            Render("base_hp", self.boss.x, self.boss.y, 0, 0.274, 0.274)
            Render("base_hp", self.boss.x, self.boss.y, 0, 0.256, 0.256)
            if self.boss.sp_point and #self.boss.sp_point ~= 0 then
                for i = 1, #self.boss.sp_point do
                    Render("life_node", self.boss.x + 61 * cos(self.boss.sp_point[i]), self.boss.y + 61 * sin(self.boss.sp_point[i]), self.boss.sp_point[i] - 90, 0.5)
                end
            end
        elseif mode == 0 and type == 2 then
            misc.Renderhpbar(self.boss.x, self.boss.y, 90, 360, 60, 64, 360, 1)
            misc.Renderhp(self.boss.x, self.boss.y, 90, 360, 60, 64, 360, self.hpbarlen * min(1, self.boss.timer / 60))
            Render("base_hp", self.boss.x, self.boss.y, 0, 0.274, 0.274)
            Render("base_hp", self.boss.x, self.boss.y, 0, 0.256, 0.256)
        elseif mode == 2 then
            misc.Renderhpbar(self.boss.x, self.boss.y, 90, 360, 60, 64, 360, 1)
            misc.Renderhp(self.boss.x, self.boss.y, 90, self.boss.lifepoint - 90, 60, 64, self.boss.lifepoint - 88, self.hpbarlen)
            Render("base_hp", self.boss.x, self.boss.y, 0, 0.274, 0.274)
            Render("base_hp", self.boss.x, self.boss.y, 0, 0.256, 0.256)
        elseif mode == 1 then
            misc.Renderhpbar(self.boss.x, self.boss.y, 90, 360, 60, 64, 360, 1)
            if self.boss.timer <= 60 then
                misc.Renderhp(self.boss.x, self.boss.y, 90, 360, 60, 64, 360, self.hpbarlen * min(1, self.boss.timer / 60))
            else
                misc.Renderhp(self.boss.x, self.boss.y, 90, self.boss.lifepoint - 90, 60, 64, self.boss.lifepoint - 88, 1)
                misc.Renderhp(self.boss.x, self.boss.y, self.boss.lifepoint, 450 - self.boss.lifepoint, 60, 64, 450 - self.boss.lifepoint, self.hpbarlen)
            end
            Render("base_hp", self.boss.x, self.boss.y, 0, 0.274, 0.274)
            Render("base_hp", self.boss.x, self.boss.y, 0, 0.256, 0.256)
            Render("life_node", self.boss.x + 61 * cos(self.boss.lifepoint), self.boss.y + 61 * sin(self.boss.lifepoint), self.boss.lifepoint - 90, 0.55)
            SetFontState("bonus", "", Color(255, 255, 255, 255))
        end
        if self.boss.show_hp then
            SetFontState("bonus", "", Color(255, 0, 0, 0))
            RenderText("bonus", int(max(0, self.boss.hp)) .. "/" .. self.boss.maxhp, self.boss.x - 1, self.boss.y - 40 - 1, 0.6, "centerpoint")
            SetFontState("bonus", "", Color(255, 255, 255, 255))
            RenderText("bonus", int(max(0, self.boss.hp)) .. "/" .. self.boss.maxhp, self.boss.x, self.boss.y - 40, 0.6, "centerpoint")
        end
    end
end

function boss_ui:render_hpbar_ex()
    SetViewMode "world"

    local alpha1 = 1 - self.boss.hp_flag / 30

    local ex = self.boss.ex
    if ex == nil then
        return
    end
    local lifes = ex.lifes
    local lifesmax = ex.lifesmax
    local modes = ex.modes
    local rate = min(1, self.boss.ex.timer / 60)

    SetImageState("base_hp", "", Color(alpha1 * 255, 255, 0, 0))
    SetImageState("hpbar1", "", Color(alpha1 * 255, 255, 100, 100))
    SetImageState("hpbar2", "", Color(alpha1 * 255, 255, 255, 255))
    SetImageState("life_node", "", Color(alpha1 * 255, 255, 255, 255))
    local maxlife = 0
    local life = 0
    for i, z in ipairs(lifesmax) do
        maxlife = maxlife + z
    end
    for i, z in ipairs(lifes) do
        life = life + z
    end
    life = min(maxlife * rate, life)

    local start = 90
    local startlife = 0
    local stop = 90

    local ddy = 0
    --RenderText("bonus",ex.cardcount,0,0,0.5,"right")

    for i, z in ipairs(lifesmax) do
        stop = 90 + 360 * (startlife + z) / maxlife
        if life > startlife then
            local d = life - startlife
            local r = min(d / z, 1)

            --RenderText("bonus",d,187,207-ddy,0.5,"right")
            --RenderText("bonus",z,187,207-ddy-20,0.5,"right")
            --ddy=ddy+50

            if modes[i] == 0 then
                misc.Renderhpbar(self.boss.x, self.boss.y, start, stop - start, 60, 64, int(stop - start), r)
            else
                misc.Renderhp(self.boss.x, self.boss.y, start, stop - start, 60, 64, int(stop - start), r)
            end
            --misc.Renderhpbar(self.boss.x,self.boss.y,90,360,60,64,360,1)
            --misc.Renderhp(self.boss.x,self.boss.y,90,360,60,64,360,1)
            Render("life_node", self.boss.x + 61 * cos(stop), self.boss.y + 61 * sin(stop), stop - 90, 0.55)
        end
        startlife = startlife + z
        start = stop
    end
    Render("base_hp", self.boss.x, self.boss.y, 0, 0.274, 0.274)
    Render("base_hp", self.boss.x, self.boss.y, 0, 0.256, 0.256)
    start = 90
    startlife = 0
    stop = 90

    for i, z in ipairs(lifesmax) do
        stop = 90 + 360 * (startlife + z) / maxlife
        Render("life_node", self.boss.x + 61 * cos(stop), self.boss.y + 61 * sin(stop), stop - 90, 0.55)
        startlife = startlife + z
        start = stop
    end
end

function boss_ui:kill()
    --kill and del function
    Del(self.sc_image)
    boss_ui.active_count = boss_ui.active_count - 1
end
boss_ui.del = boss_ui.kill

function boss:SetUIDisplay(hp, name, cd, spell, pos, pointer)
    self.ui.drawhp = hp
    self.ui.drawname = name
    self.ui.drawtime = cd
    self.ui.drawspell = spell
    self.ui.needposition = pos
    self.ui.drawpointer = pointer
end
