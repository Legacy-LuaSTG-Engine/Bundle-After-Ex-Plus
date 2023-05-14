---=====================================
---th style boss
---特效、其他组件
---=====================================

----------------------------------------
---boss move

--随机移动（没有使用）

function boss.MoveTowardsPlayer(t)
    local dirx, diry
    local self = task.GetSelf()
    local p = player
    if self.x > 64 then
        dirx = -1
    elseif self.x < -64 then
        dirx = 1
    else
        --if self.x>lstg.player.x then dirx=-1 else dirx=1 end
        if self.x > p.x then
            dirx = -1
        else
            dirx = 1
        end
    end
    if self.y > 144 then
        diry = -1
    elseif self.y < 128 then
        diry = 1
    else
        diry = ran:Sign()
    end
    --local dx=max(16,min(abs((self.x-lstg.player.x)*0.3),32))
    local dx = max(16, min(abs((self.x - p.x) * 0.3), 32))
    task.MoveTo(self.x + ran:Float(dx, dx * 2) * dirx, self.y + diry * ran:Float(16, 32), t)
end

----------------------------------------
---boss 特效
---一些华丽的效果（

--开卡文字
--！警告：未适配宽屏等非传统版面

spell_card_ef = Class(object)
function spell_card_ef:init()
    self.layer = LAYER_BG + 1
    self.group = GROUP_GHOST
    self.alpha = 0
    task.New(self, function()
        for i = 1, 50 do
            task.Wait()
            self.alpha = self.alpha + 0.02
        end
        task.Wait(60)
        for i = 1, 50 do
            task.Wait()
            self.alpha = self.alpha - 0.02
        end
        Del(self)
    end)
end
function spell_card_ef:frame()
    task.Do(self)
end
function spell_card_ef:render()
    SetImageState("spell_card_ef", "", Color(128 * self.alpha, 255, 255, 255))
    for j = 1, 10 do
        local h = (j - 4.5) * 32
        for i = -2, 2 do
            local l = i * 128 + ((self.timer) % 128) * (2 * (j % 2) - 1)
            Render("spell_card_ef", l * cos(30), l * sin(30) + h, -60)
        end
    end
    for j = 1, 8 do
        local h = (j - 4.5) * 32
        local l = -self.timer * 1.5
        local da = 45
        local dr = 20
        local minr = 112
        local ddr = 32
        local cx = 160
        local cy = -192
        local dir = { -1, 1, 1 }
        for i = 0, 2 do
            Render4V("spell_card_ef", cx + (minr + ddr * i) * cos(j * 45 + l * dir[i + 1]), cy + (minr + ddr * i) * sin(j * 45 + l * dir[i + 1]), 0.5,
                    cx + (minr + ddr * i - dr) * cos(j * 45 + l * dir[i + 1]), cy + (minr + ddr * i - dr) * sin(j * 45 + l * dir[i + 1]), 0.5,
                    cx + (minr + ddr * i - dr) * cos(j * 45 - da + l * dir[i + 1]), cy + (minr + ddr * i - dr) * sin(j * 45 - da + l * dir[i + 1]), 0.5,
                    cx + (minr + ddr * i) * cos(j * 45 - da + l * dir[i + 1]), cy + (minr + ddr * i) * sin(j * 45 - da + l * dir[i + 1]), 0.5)
        end
        Render4V("spell_card_ef", -cx + (minr + ddr) * cos(j * 45 + l), -cy + (minr + ddr) * sin(j * 45 + l), 0.5,
                -cx + (minr + ddr - dr) * cos(j * 45 + l), -cy + (minr + ddr - dr) * sin(j * 45 + l), 0.5,
                -cx + (minr + ddr - dr) * cos(j * 45 - da + l), -cy + (minr + ddr - dr) * sin(j * 45 - da + l), 0.5,
                -cx + (minr + ddr) * cos(j * 45 - da + l), -cy + (minr + ddr) * sin(j * 45 - da + l), 0.5)
    end
end

--老蓄力特效，已废弃

--[[
boss_cast_ef = Class(object)
function boss_cast_ef:init(x, y)
    self.hide = true
    PlaySound("ch00", 0.5, 0)
    for i = 1, 50 do
        local angle = ran:Float(0, 360)
        local lifetime = ran:Int(50, 80)
        local l = ran:Float(300, 500)
        New(boss_cast_ef_unit, x + l * cos(angle), y + l * sin(angle), l / lifetime, angle + 180, lifetime, ran:Float(2, 3))
    end
    Del(self)
end
--]]

boss_cast_ef_unit = Class(object)
function boss_cast_ef_unit:init(x, y, v, angle, lifetime, size)
    self.x = x
    self.y = y
    self.rot = ran:Float(0, 360)
    SetV(self, v, angle)
    self.lifetime = lifetime
    self.omiga = 5
    self.layer = LAYER_ENEMY - 50
    self.group = GROUP_GHOST
    self.bound = false
    self.img = "leaf"
    self.hscale = size
    self.vscale = size
end
function boss_cast_ef_unit:frame()
    if self.timer == self.lifetime then
        Del(self)
    end
end
function boss_cast_ef_unit:render()
    if self.timer > self.lifetime - 15 then
        SetImageState(self.img, "mul+add", Color(max(0, 255 * (self.lifetime - self.timer - 1) / 15), 255, 255, 255))
    else
        SetImageState(self.img, "mul+add", Color(255, 255, 255, 255))
    end
    DefaultRenderFunc(self)
end

--新蓄力特效
--由无耳定义，OLC修改

--蓄力物件（允许设置img）
boss_cast_ef_unit_new = Class(object)
function boss_cast_ef_unit_new:init(x, y, v, a, lifetime, size, img)
    self.x, self.y = x, y
    self.group = GROUP_GHOST
    self.layer = LAYER_ENEMY + 30
    self.img = img or "img_void"
    self.rot = ran:Float(0, 360)
    self.lifetime = lifetime
    self.omiga = ran:Float(0.8, 1.2) * ran:Sign()
    self.hscale, self.vscale = size, size
    self.bound = false
    task.New(self, function()
        local s, al, i, l = size, 125, 0, v * lifetime
        local _s, _al, _i, _l = -ran:Float(1, 3) * size / lifetime, -125 / lifetime, 90 / lifetime, 0
        for j = 1, lifetime do
            self.x = x + l * cos(a) * sin(i)
            self.y = y + l * sin(a) * sin(i)
            self.hscale = s
            s = s + _s
            al = al + _al
            i = i + _i
            task.Wait(1)
        end
        Del(self)
    end)
end

function boss_cast_ef_unit_new:frame()
    task.Do(self)
    if self.timer == self.lifetime then
        Del(self)
    end
end

function boss_cast_ef_unit_new:render()
    if self.timer > self.lifetime - 15 then
        SetImageState(self.img, "mul+add", Color(max(0, 125 * (self.lifetime - self.timer - 1) / 15), 255, 255, 255))
    else
        SetImageState(self.img, "mul+add", Color(125, 255, 255, 255))
    end
    DefaultRenderFunc(self)
end

--向内收缩蓄力（可设置图像与音效）
boss_cast_ef_in = Class(object)
function boss_cast_ef_in:init(x, y, img, r, g, b, sound)
    self.x = x
    self.y = y
    self.img = "boss_shockwave" -- "boss_charge"
    self.unitimg = img
    self.group = GROUP_GHOST
    self.layer = LAYER_ENEMY + 50
    self._r = r
    self._g = g
    self._b = b
    self.hscale, self.vscale = 1, 1
    if sound and sound ~= "" then
        PlaySound(sound, 0.5, 0, false)
    end
end

function boss_cast_ef_in:frame()
    if self.timer < 45 then
        local angle = ran:Float(0, 360)
        local lifetime = ran:Int(30, 45)
        local l = ran:Float(120, 200)
        New(boss_cast_ef_unit_new, self.x + l * cos(angle), self.y + l * sin(angle), l / lifetime, angle + 180, lifetime, ran:Float(3.5, 5), self.unitimg)
    end
    self.hscale = 1 - self.timer / 60
    self.vscale = 1 - self.timer / 60
    if self.timer > 59 then
        Del(self)
    end
end

function boss_cast_ef_in:render()
    SetImageState(self.img, "mul+add", Color(80 + self.timer * 2, self._r, self._g, self._b))
    object.render(self)
end

--向外扩散蓄力（可设置图像与音效）
boss_cast_ef_out = Class(object)
function boss_cast_ef_out:init(x, y, img, r, g, b, sound)
    self.x = x
    self.y = y
    self.img = "boss_shockwave" -- "boss_charge"
    self.unitimg = img
    self.group = GROUP_GHOST
    self.layer = LAYER_ENEMY + 50
    self._r = r
    self._g = g
    self._b = b
    self.hscale, self.vscale = 0, 0
    if sound and sound ~= "" then
        PlaySound(sound, 0.5, 0, false)
    end
end

local boss_cast_ef_out_range = { { 100, 200 }, { 150, 300 }, { 250, 500 } }
function boss_cast_ef_out:frame()
    local angle, lifetime, l
    if self.timer < 15 then
        for i = 1, 3 do
            angle = ran:Float(0, 360)
            lifetime = ran:Int(45, 60)
            l = ran:Float(unpack(boss_cast_ef_out_range[i]))
            New(boss_cast_ef_unit_new, self.x, self.y,
                    l / lifetime, angle + 180, lifetime, ran:Float(3.5, 5), self.unitimg)
        end
    end
    self.hscale = self.timer * 0.025
    self.vscale = self.timer * 0.025
    if self.timer > 59 then
        Del(self)
    end
end

function boss_cast_ef_out:render()
    SetImageState(self.img, "mul+add", Color(240 - self.timer * 4, self._r, self._g, self._b))
    object.render(self)
end

--蓄力特效
--由EVA定义，OLC修改

--蓄力（使用弹幕风樱花蓄力)
boss_cast_ef = Class(object)
function boss_cast_ef:init(x, y, range, r, g, b, t, mode, nosound, master)
    range = range or 250
    r = r or 255
    g = g or 0
    b = b or 0
    t = t or 60
    mode = mode or 2
    if not (nosound) then
        PlaySound("ch00", 0.1, 0, false)
    end
    local last = New(boss_cast_cherry, x, y, range, r, g, b, t, mode)
    if master then
        last.master = master
    end
    Del(self)
end


--New(_editor_class["黑球蓄力"],self.x,self.y,60,80,280,3,120,255,64,64,-1.5)

--弹幕风樱花蓄力
boss_cast_cherry = Class(object)
function boss_cast_cherry:init(x, y, range, r, g, b, t, mode)
    mode = mode or 2
    self.x, self.y = x, y
    self.layer = LAYER_ENEMY + 10
    self.bound = false
    self.img = "boss_shockwave"
    self.hscale = range / 128
    self.vscale = self.hscale
    _object.set_color(self, "mul+add", 0, r, g, b)
    local t1 = int(t * 1.5)
    local t2 = int(t * 0.8)
    local t3 = int(t * 0.7)
    task.New(self, function()
        ex.SmoothSetValueTo("vscale", 0, t1, mode, nil, 0, MODE_SET)
    end)
    task.New(self, function()
        ex.SmoothSetValueTo("hscale", 0, t1, mode, nil, 0, MODE_SET)
    end)
    task.New(self, function()
        local rd = range
        local ra = 0
        local jg = 3
        local ang
        for _ = 1, (t / jg) - (t / 60) do
            rd = self.hscale * 128
            ra = ra + 19
            for i = 1, 4 do
                ang = ra + i * 90
                New(boss_cast_cherry_unit,
                        self.x + rd * cos(ang),
                        self.y + rd * sin(ang),
                        60, self.x, self.y, r, g, b, mode)
            end
            task.Wait(jg)
        end
    end)
    task.New(self, function()
        local a, _d_a = 0, 255 / t2
        for _ = 0, t2 do
            self._a = a
            task.Wait(1)
            a = a + _d_a
        end
        task.Wait(t3)
        Del(self)
    end)
end
function boss_cast_cherry:frame()
    if IsValid(self.master) then
        self.x, self.y = self.master.x, self.master.y
    end
    task.Do(self)
end
function boss_cast_cherry:render()
    SetImgState(self, self._blend, self._a, self._r, self._g, self._b)
    DefaultRenderFunc(self)
end

boss_cast_cherry_unit = Class(object)
function boss_cast_cherry_unit:init(x, y, t, cx, cy, r, g, b, mode)
    self.x, self.y = x, y
    self.layer = LAYER_ENEMY + 10
    self.bound = false
    self.img = "boss_Cherry"
    local rs = ran:Float(0.1, 0.2)
    self.omiga = ran:Sign() * ran:Float(3, 6)
    self.hscale, self.vscale = rs, rs
    self.rot = ran:Float(-180, 180)
    _object.set_color(self, "mul+add", 0, r, g, b)
    task.New(self, function()
        task.MoveTo(cx, cy, t, mode)
    end)
    task.New(self, function()
        local t1 = int(t * 0.2)
        local t2 = int(t * 0.6)
        local a, _d_a = 0, 128 / t1
        for _ = 0, t1 do
            self._a = a
            task.Wait(1)
            a = a + _d_a
        end
        task.Wait(t2)
        a, _d_a = 128, -128 / t1
        for _ = 0, t1 do
            self._a = a
            task.Wait(1)
            a = a + _d_a
        end
        Del(self)
    end)
end
function boss_cast_cherry_unit:frame()
    task.Do(self)
end
function boss_cast_cherry_unit:render()
    SetImgState(self, self._blend, self._a, self._r, self._g, self._b)
    DefaultRenderFunc(self)
end

--黑球蓄力
boss_cast_darkball = Class(object)
function boss_cast_darkball:init(x, y, KeepTime, ContractTime, Radius, Ways, Angle, R, G, B, ROT_V)
    self.x, self.y = x, y
    self.layer = LAYER_ENEMY + 10
    self.bound = false
    local T = KeepTime
    local jg1, jg2 = 3, 2
    task.New(self, function()
        for _ = 0, (T / jg1) do
            local c, _d_c = Angle, 360 / Ways
            for _ = 1, Ways do
                for _ = 1, 3 do
                    New(boss_cast_darkball_unit,
                            x, y,
                            Radius, ContractTime,
                            c, 2, 255 - R, 255 - G, 255 - B, 15, ROT_V)
                end
                c = c + _d_c
            end
            task.Wait(jg1)
        end
        task.Wait(60)
        Del(self)
    end)
    task.New(self, function()
        -- mul+rev(dark)
        local jg3 = 4
        do
            for _ = 1, (T / jg3) + 1 do
                do
                    local c, _d_c = (Angle), (360 / Ways)
                    for _ = 1, Ways do
                        do
                            for _ = 1, 1 do
                                New(boss_cast_darkball_unit,
                                        x, y,
                                        Radius, ContractTime,
                                        c, 2, 200, 200, 200, 10, ROT_V)
                            end
                        end
                        c = c + _d_c
                    end
                end
                task.Wait(jg3)
            end
        end
    end)
    task.New(self, function()
        for _ = 0, (T / jg2) do
            local c, _d_c = Angle, 360 / Ways
            for _ = 1, Ways do
                New(boss_cast_darkball_unit,
                        x, y,
                        Radius, ContractTime,
                        c, 3, R, G, B, 5, ROT_V)
                c = c + _d_c
            end
            task.Wait(jg2)
        end
    end)
end
function boss_cast_darkball:frame()
    task.Do(self)
end

boss_cast_darkball_unit = Class(object)
function boss_cast_darkball_unit:init(CX, CY, Radius, T, c, blendtype, R, G, B, LAYER_MOVE, rv)
    self.x, self.y = CX, CY
    self.img = "boss_light"
    self.layer = LAYER_ENEMY + 10
    self.bound = false
    self.lm = LAYER_MOVE
    local rotv = rv + ran:Float(0, 0.25)
    local t1 = 45
    local rs
    if blendtype == 1 then
        rs = ran:Float(1.75, 1.5) + 0.5
    elseif blendtype == 2 then
        rs = ran:Float(1.55, 1.75) + 0.5
    elseif blendtype == 3 then
        rs = ran:Float(1.4, 1.25) + 0.25
    end
    self.rot = ran:Float(0, 360)
    self.r_floater = ran:Float(-20, 20)
    self.r = Radius + self.r_floater
    self.a_floater = ran:Float(-30, 30)
    self.hscale, self.vscale = rs, rs
    if blendtype == 1 then
        _object.set_color(self, "", 255, R, G, B)
    elseif blendtype == 2 then
        _object.set_color(self, "mul+rev", 255, R, G, B)
    elseif blendtype == 3 then
        _object.set_color(self, "mul+add", 255, R, G, B)
    end
    task.New(self, function()
        task.New(self, function()
            local a, _d_a = 0, 255 / t1
            for _ = 0, t1 do
                self._a = a
                task.Wait(1)
                a = a + _d_a
            end
        end)
        local final_scale = 2
        local a, _d_a = 0, 90 / T
        local ra, _d_ra = 0, rotv
        local d
        for _ = 0, T do
            self.hscale = rs + (final_scale - rs) * sin(a)
            self.vscale = rs + (final_scale - rs) * sin(a)
            d = ((self.r) * (1 - sin(a)))
            if blendtype == 3 then
                _object.set_color(self, "mul+add", 255 * cos(a), R, G, B)
            end
            self.x = CX + d * cos(c + self.a_floater + ra)
            self.y = CY + d * sin(c + self.a_floater + ra)
            task.Wait(1)
            a = a + _d_a
            ra = ra + _d_ra
        end
        local gather_time = 10
        task.Wait(gather_time)
        local disapt = 30
        a, _d_a = 0, 90 / disapt
        for _ = 0, disapt do
            if blendtype == 1 then
                _object.set_color(self, "", 255 * cos(a), R, G, B)
            elseif blendtype == 2 then
                _object.set_color(self, "mul+rev", 255 * cos(a), R, G, B)
            elseif blendtype == 3 then
                _object.set_color(self, "mul+add", 0, R, G, B)
            end
            self.hscale = final_scale * cos(a)
            self.vscale = final_scale * cos(a)
            task.Wait(1)
            a = a + _d_a
        end
        Del(self)
    end)
end
function boss_cast_darkball_unit:frame()
    task.Do(self)
    self.layer = LAYER_ENEMY + self.lm
end
function boss_cast_darkball_unit:render()
    if self._blend and self._a and self._r and self._g and self._b then
        SetImgState(self, self._blend, self._a, self._r, self._g, self._b)
    end
    DefaultRenderFunc(self)
end

--死亡爆炸

boss_death_ef = Class(object)
function boss_death_ef:init(x, y, playsound, shakescreen)
    if playsound then
        PlaySound("enep01", 0.4, 0)
    end
    self.hide = true
    if shakescreen then
        misc.ShakeScreen(30, 15)
    end
    for i = 1, 70 do
        local angle = ran:Float(0, 360)
        local lifetime = ran:Int(40, 120)
        local l = ran:Float(100, 500)
        New(boss_death_ef_unit, x, y, l / lifetime, angle, lifetime, ran:Float(2, 4))
    end
    Del(self)--哪个傻吊把这个漏了……
end

boss_death_ef_unit = Class(object)
function boss_death_ef_unit:init(x, y, v, angle, lifetime, size)
    self.x = x
    self.y = y
    self.rot = ran:Float(0, 360)
    SetV(self, v, angle)
    self.lifetime = lifetime
    self.omiga = 3
    self.layer = LAYER_ENEMY + 50
    self.group = GROUP_GHOST
    self.bound = false
    self.img = "leaf"
    self.hscale = size
    self.vscale = size
end
function boss_death_ef_unit:frame()
    if self.timer == self.lifetime then
        Del(self)
    end
end
function boss_death_ef_unit:render()
    if self.timer < 15 then
        SetImageState("leaf", "mul+add", Color(self.timer * 12, 255, 255, 255))
    else
        SetImageState("leaf", "mul+add", Color(((self.lifetime - self.timer) / (self.lifetime - 15)) * 180, 255, 255, 255))
    end
    DefaultRenderFunc(self)
end

--非或符结束时弹出的文字

kill_timer = Class(object)
function kill_timer:init(x, y, t)
    self.t = t
    self.x = x
    self.y = y - 3
    --self.yy = y
    self.alph = 0
end
function kill_timer:frame()
    if self.timer <= 30 then
        self.alph = self.timer / 30
        --修改：不再上浮
        --self.y = self.yy - 30 * cos(3 * self.timer)
    end
    if self.timer > 120 then
        self.alph = 1 - (self.timer - 120) / 30
    end
    if self.timer >= 150 then
        Del(self)
    end
end
function kill_timer:render()
    SetViewMode "world"
    local alpha = self.alph
    --略修改位置，小数点后位缩小
    local basex = 54
    SetFontState("time", "", Color(alpha * 255, 0, 0, 0))
    RenderText("time", string.format("%d.", int(self.t / 60)), basex - 1, self.y, 0.5, "vcenter", "right")
    RenderText("time", string.format("%02ds", int(self.t / 60 * 100 % 100)), basex - 1, self.y - 1, 0.3, "vcenter", "left")

    SetFontState("time", "", Color(alpha * 255, 200, 200, 200))
    RenderText("time", string.format("%d.", int(self.t / 60)), basex, self.y + 1, 0.5, "vcenter", "right")
    RenderText("time", string.format("%02ds", int(self.t / 60 * 100 % 100)), basex, self.y, 0.3, "vcenter", "left")

    SetImageState("hint.killtimer", "", Color(alpha * 255, 255, 255, 255))
    Render("hint.killtimer", -39, self.y + 2, 0.5, 0.5)

end

kill_timer2 = Class(object)
function kill_timer2:init(x, y, t)
    self.t = t
    self.x = x
    self.y = y - 3
    --self.yy = y
    self.alph = 0
end
function kill_timer2:frame()
    if self.timer <= 30 then
        self.alph = self.timer / 30
        --修改：不再上浮
        --self.y = self.yy - 30 * cos(3 * self.timer)
    end
    if self.timer > 120 then
        self.alph = 1 - (self.timer - 120) / 30
    end
    if self.timer >= 150 then
        Del(self)
    end
end
function kill_timer2:render()
    SetViewMode "world"
    local alpha = self.alph
    --略修改位置，小数点后位缩小
    local basex = 54
    SetFontState("time", "", Color(alpha * 255, 0, 0, 0))
    RenderText("time", string.format("%d.", int(self.t / 60)), basex - 1, self.y, 0.5, "vcenter", "right")
    RenderText("time", string.format("%02ds", int(self.t / 60 * 100 % 100)), basex - 1, self.y - 1, 0.3, "vcenter", "left")
    SetFontState("time", "", Color(alpha * 255, 127, 127, 127))
    RenderText("time", string.format("%d.", int(self.t / 60)), basex, self.y + 1, 0.5, "vcenter", "right")
    RenderText("time", string.format("%02ds", int(self.t / 60 * 100 % 100)), basex, self.y, 0.3, "vcenter", "left")
    SetImageState("hint.truetimer", "", Color(alpha * 255, 255, 255, 255))
    Render("hint.truetimer", -39, self.y + 2, 0.5, 0.5)
end

local function formatnum(num)
    local sign = sign(num)
    num = abs(num)
    local tmp = {}
    local var
    while num >= 1000 do
        var = num - int(num / 1000) * 1000
        table.insert(tmp, 1, string.format("%03d", var))
        num = int(num / 1000)
    end
    table.insert(tmp, 1, tostring(num))
    var = table.concat(tmp, ",")
    if sign < 0 then
        var = string.format("-%s", var)
    end
    return var, #tmp - 1
end

hinter_bonus = Class(object)
function hinter_bonus:init(img, size, x, y, t1, t2, fade, bonus)
    self.img = img
    self.x = x
    self.y = y
    self.t1 = t1
    self.t2 = t2
    self.fade = fade
    self.group = GROUP_GHOST
    self.layer = LAYER_TOP
    self.size = size
    self.t = 0
    self.hscale = self.size
    self.bonus = bonus
    --新增：用于SC得分特效的东西
    local text, commacount = formatnum(self.bonus)
    self.bonustext = text
    self.bonustext = sp.string(self.bonustext).string
    self.digital = #self.bonustext
    self.textspace = 12
    local ts = self.textspace
    self.textright = self.x + (self.digital - commacount) * ts / 2 + commacount * (ts / 2 + 2) / 2
end
function hinter_bonus:frame()
    if self.timer < self.t1 then
        self.t = self.timer / self.t1
    elseif self.timer < self.t1 + self.t2 then
        self.t = 1
    elseif self.timer < self.t1 * 2 + self.t2 then
        self.t = (self.t1 * 2 + self.t2 - self.timer) / self.t1
    else
        Del(self)
    end
    self.vscale = self.t * self.size
end
function hinter_bonus:render()
    if self.fade then
        --旧版
        --[[
        SetImageState(self.img, "", Color(self.t * 255, 255, 255, 255))
        self.vscale = self.size
        SetFontState("score3", "", Color(self.t * 255, 255, 255, 255))
        RenderScore("score3", self.bonus, self.x + 1, self.y - 41, 0.7, "centerpoint")
        object.render(self)
        --]]

        --更改：SC得分特效
        local alpha = self.t * 255
        local rgb = 255
        local ts = self.textspace
        local initx = self.textright
        local t, y, fade
        if self.timer < 60 and self.timer % 4 == 0 then
            rgb = 63
        end
        SetImageState(self.img, "", Color(alpha, rgb, rgb, rgb))
        for i = 1, self.digital do
            if self.timer >= self.t1 + self.t2 then
                SetFontState("score3", "", Color(alpha, 255, 255, 255))
            else
                t = (self.timer * 8 - i * 32) * 0.4
                if t > 135 and t < 195 and self.timer % 4 == 0 then
                    fade = 1
                else
                    fade = 0
                end
                t = self.timer * 4 - i * 16
                alpha = min(max(0, t), 255)
                rgb = 255 - 128 * fade
                SetFontState("score3", "", Color(alpha, rgb, rgb, rgb))
            end
            t = (self.timer * 8 - i * 32) * 0.4
            y = self.y - 60 + 60 * sin(max(0, min(t, 135)))
            RenderText("score3", self.bonustext[self.digital - i + 1], initx, y, (ts - 2) / 20, "right")
            if i % 4 == 0 then
                initx = initx - ts / 2
            else
                initx = initx - ts
            end
        end
        object.render(self)
    else
        SetImageState(self.img, "", Color(0xFFFFFFFF))
        self.vscale = self.t * self.size
        SetFontState("score3", "", Color(255, 255, 255, 255))
        RenderScore("score3", self.bonus, self.x + 1, self.y - 41, 0.7, "centerpoint")
        object.render(self)
    end
end

----------------------------------------
---杂项

function Render_RIng_4(angle, r, angle_offset, x0, y0, r_, imagename)
    --未使用
    local A_1 = angle + angle_offset
    local A_2 = angle - angle_offset
    local R_1 = r + r_
    local R_2 = r - r_
    local x1, x2, x3, x4, y1, y2, y3, y4
    x1 = x0 + (R_1) * cos(A_1)
    y1 = y0 + (R_1) * sin(A_1)

    x2 = x0 + (R_1) * cos(A_2)
    y2 = y0 + (R_1) * sin(A_2)

    x3 = x0 + (R_2) * cos(A_2)
    y3 = y0 + (R_2) * sin(A_2)

    x4 = x0 + (R_2) * cos(A_1)
    y4 = y0 + (R_2) * sin(A_1)
    Render4V(imagename, x1, y1, 0.5, x2, y2, 0.5, x3, y3, 0.5, x4, y4, 0.5)
end

function test_ex(ex)
    --测试代码，日后要移除
    ex.lifes = { 300, 100, 400 }
    ex.lifesmax = { 300, 100, 700 }
    ex.modes = { 0, 1, 0 }
end
