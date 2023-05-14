WalkImageSystem = plus.Class()
function WalkImageSystem:init(obj, intv, dx_level, dx_rate)
    self.dx_level = abs(dx_level)
    self.dx_rate = abs(dx_rate)
    self.obj = obj
    self.obj.ani_intv = intv or 8
    self.obj.lr = self.obj.lr or 1
end
function WalkImageSystem:frame(dx)
    local obj, lv, rt = self.obj, self.dx_level, self.dx_rate
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
end
local dx, dy, tmpx, tmpy
function WalkImageSystem:render(dmgt, dmgmaxt)
    local obj = self.obj
    local c = 0
    if dmgt and dmgmaxt then
        c = dmgt / dmgmaxt
    end
    if obj._blend and obj._a and obj._r and obj._g and obj._b then
        SetImageState(obj.img, obj._blend, Color(obj._a, obj._r - obj._r * 0.75 * c, obj._g - obj._g * 0.75 * c, obj._b))
    else
        SetImageState(obj.img, '', Color(255, 255 - 255 * 0.75 * c, 255 - 255 * 0.75 * c, 255))
    end
    dx, dy = self.dx or 0, self.dy or 0
    if self.float_func then
        tmpx, tmpy = self.float_func(obj.ani)
        dx, dy = tmpx or dx, tmpy or dy
        self.dx, self.dy = dx, dy
    end
    Render(obj.img, obj.x + dx, obj.y + dy, obj.rot, obj.hscale, obj.vscale)
    if obj._blend and obj._a and obj._r and obj._g and obj._b then
        SetImageState(obj.img, "", Color(0xFFFFFFFF))
    end
end
function WalkImageSystem:SetFloat(a, b)
    if not (a) and not (b) then
        self.float_func = nil
    elseif type(a) == "function" and not (b) then
        self.float_func = a
    elseif type(a) == "number" and type(b) == "number" then
        self.dx, self.dy = a or self.dx or 0, b or self.dy or 0
    end
end
function WalkImageSystem:SetImage()
end

BossWalkImageSystem = plus.Class(WalkImageSystem)
function BossWalkImageSystem:init(obj, img, nRow, nCol, imgs, anis, intv, a, b)
    WalkImageSystem.init(self, obj, intv, 2, 28)
    self.obj.cast = self.obj.cast or 0
    self.obj.cast_t = self.obj.cast_t or 0
    self:SetImage(img, nRow, nCol, imgs, anis, intv, a, b)
end
function BossWalkImageSystem:frame()
    local obj = self.obj
    WalkImageSystem.frame(self, obj.dx)
    if obj.img4 then
        self.mode = 4
    elseif obj.img3 then
        self.mode = 3
    elseif obj.img2 then
        self.mode = 2
    elseif obj.img1 then
        self.mode = 1
    else
        self.mode = 0
    end
    if obj.cast_t > 0 then
        obj.cast = obj.cast + 1
    elseif obj.cast_t < 0 then
        obj.cast = 0
        obj.cast_t = 0
    end
    if obj.dx ~= 0 then
        obj.cast = 0
        obj.cast_t = 0
    end
    if BossWalkImageSystem['UpdateImage' .. self.mode] then
        BossWalkImageSystem['UpdateImage' .. self.mode](obj)
    end
    if type(obj.A) == 'number' and type(obj.B) == 'number' then
        obj.a = obj.A;
        obj.b = obj.B
    end
end
function BossWalkImageSystem:render(dmgt, dmgmaxt)

    local obj = self.obj
    local c = 0
    if dmgt and dmgmaxt then
        c = dmgt / dmgmaxt
    end
    if self.mode == 0 then
        if obj._blend and obj._a and obj._r and obj._g and obj._b then
            SetImageState('undefined', obj._blend, Color(obj._a, obj._r - obj._r * 0.75 * c, obj._g - obj._g * 0.75 * c, obj._b))
        else
            SetImageState('undefined', 'mul+add', Color(128, 255 - 255 * 0.75 * c, 255 - 255 * 0.75 * c, 255))
        end
        Render('undefined', obj.x + cos(obj.ani * 6 + 180) * 3, obj.y + sin(obj.ani * 6 + 180) * 3, obj.ani * 10)
        Render('undefined', obj.x + cos(-obj.ani * 6 + 180) * 3, obj.y + sin(-obj.ani * 6 + 180) * 3, -obj.ani * 10)
        Render('undefined', obj.x + cos(obj.ani * 6) * 3, obj.y + sin(obj.ani * 6) * 3, obj.ani * 20)
        Render('undefined', obj.x + cos(-obj.ani * 6) * 3, obj.y + sin(-obj.ani * 6) * 3, -obj.ani * 20)
        if obj._blend and obj._a and obj._r and obj._g and obj._b then
            SetImageState('undefined', 'mul+add', Color(0x80FFFFFF))
        end
    else
        WalkImageSystem.render(self, dmgt, dmgmaxt)
    end
end
function BossWalkImageSystem:SetImage(img, nRow, nCol, imgs, anis, intv, a, b)
    local obj = self.obj
    for i = 1, 4 do
        obj['img' .. i] = nil
        obj['ani' .. i] = nil
    end
    if lstg.tmpvar._WLS_IMG_CHECK == nil then
        lstg.tmpvar._WLS_IMG_CHECK = {}
    end
    if img then
        if not (lstg.tmpvar._WLS_IMG_CHECK[img]) then
            local number_n = {}
            for i = 1, nRow do
                number_n[i] = nCol
            end
            LoadTexture('anonymous:' .. img, img)
            local bt_n, bt_m = GetTextureSize('anonymous:' .. img)
            local w, h = bt_n / nCol, bt_m / nRow
            for i = 1, nRow do
                LoadImageGroup('anonymous:' .. img .. i, 'anonymous:' .. img,
                        0, h * (i - 1), w, h, number_n[i], 1, a, b)
            end
            lstg.tmpvar._WLS_IMG_CHECK[img] = true
        end
        for i = 1, nRow do
            obj['img' .. i] = {}
        end
        for i = 2, nRow do
            obj['ani' .. i] = imgs[i] - anis[i - 1]
        end
        for i = 1, nRow do
            for j = 1, imgs[i] do
                obj['img' .. i][j] = 'anonymous:' .. img .. i .. j
            end
        end
        obj.ani_intv = intv or obj.ani_intv or 8
        obj.lr = obj.lr or 1
        obj.nn, obj.mm = imgs, anis
        self.mode = nCol
    else
        self.mode = 0
    end
end
function BossWalkImageSystem:UpdateImage4()
    if self.cast > 0 and self.dx == 0 then
        if self.cast >= self.ani_intv * self.nn[4] then
            if self.mm[3] == 1 then
                self.img = self.img4[self.nn[4]]
            else
                self.img = self.img4[int(self.cast / self.ani_intv) % self.mm[3] + self.ani4 + 1]
            end
            self.cast_t = self.cast_t - 1
        else
            self.img = self.img4[int(self.cast / self.ani_intv) + 1]
        end
    elseif self.lr > 0 then
        if abs(self.lr) == 1 then
            self.img = self.img1[int(self.ani / self.ani_intv) % self.nn[1] + 1]
        elseif abs(self.lr) == 28 then
            if self.mm[1] == 1 then
                self.img = self.img2[self.nn[2]]
            else
                self.img = self.img2[int(self.ani / self.ani_intv) % self.mm[1] + self.ani2 + 1]
            end
        else
            if self.ani2 == 2 then
                self.img = self.img2[int((abs(self.lr) + 2) / 10) + 1]
            elseif self.ani2 == 3 then
                self.img = self.img2[int((abs(self.lr)) / 7) + 1]
            elseif self.ani2 == 4 then
                self.img = self.img2[int((abs(self.lr) + 2) / 6) + 1]
            elseif self.ani2 > 4 then
                self.img = self.img2[int((abs(self.lr) + 2) / 5) + 1]
            end
        end
    else
        if abs(self.lr) == 1 then
            self.img = self.img1[int(self.ani / self.ani_intv) % self.nn[1] + 1]
        elseif abs(self.lr) == 28 then
            if self.mm[2] == 1 then
                self.img = self.img3[self.nn[3]]
            else
                self.img = self.img3[int(self.ani / self.ani_intv) % self.mm[2] + self.ani3 + 1]
            end
        else
            if self.ani3 == 2 then
                self.img = self.img3[int((abs(self.lr) + 2) / 10) + 1]
            elseif self.ani3 == 3 then
                self.img = self.img3[int((abs(self.lr)) / 7) + 1]
            elseif self.ani3 == 4 then
                self.img = self.img3[int((abs(self.lr) + 2) / 6) + 1]
            elseif self.ani3 > 4 then
                self.img = self.img3[int((abs(self.lr) + 2) / 5) + 1]
            end
        end
    end
end
function BossWalkImageSystem:UpdateImage3()
    if self.cast > 0 and self.dx == 0 then
        if self.cast >= self.ani_intv * self.nn[3] then
            if self.mm[2] == 1 then
                self.img = self.img3[self.nn[3]]
            else
                self.img = self.img3[int(self.cast / self.ani_intv) % self.mm[2] + self.ani3 + 1]
            end
            self.cast_t = self.cast_t - 1
        else
            self.img = self.img3[int(self.cast / self.ani_intv) + 1]
        end
    else
        if abs(self.lr) == 1 then
            self.img = self.img1[int(self.ani / self.ani_intv) % self.nn[1] + 1]
        elseif abs(self.lr) == 28 then
            if self.mm[1] == 1 then
                self.img = self.img2[self.nn[2]]
            else
                self.img = self.img2[int(self.ani / self.ani_intv) % self.mm[1] + self.ani2 + 1]
            end
        else
            if self.ani2 == 2 then
                self.img = self.img2[int((abs(self.lr) + 2) / 10) + 1]
            elseif self.ani2 == 3 then
                self.img = self.img2[int((abs(self.lr)) / 7) + 1]
            elseif self.ani2 == 4 then
                self.img = self.img2[int((abs(self.lr) + 2) / 6) + 1]
            elseif self.ani2 > 4 then
                self.img = self.img2[int((abs(self.lr) + 2) / 5) + 1]
            end
        end
    end
    local scale = abs(self.hscale)
    self.hscale = sign(self.lr) * scale
end
function BossWalkImageSystem:UpdateImage2()
    if self.cast > 0 and self.dx == 0 then
        if self.cast >= self.ani_intv * self.nn[2] then
            if self.mm[1] == 1 then
                self.img = self.img2[self.nn[2]]
            else
                self.img = self.img2[int(self.cast / self.ani_intv) % self.mm[1] + self.ani2 + 1]
            end
            self.cast_t = self.cast_t - 1
        else
            self.img = self.img2[int(self.cast / self.ani_intv) + 1]
        end
    else
        if abs(self.lr) == 1 then
            self.img = self.img1[1]
        elseif abs(self.lr) == 28 then
            self.img = self.img1[self.nn[1]]
        else
            if self.ani2 == 2 then
                self.img = self.img2[int((abs(self.lr) + 2) / 10) + 1]
            elseif self.ani2 == 3 then
                self.img = self.img2[int((abs(self.lr)) / 7) + 1]
            elseif self.ani2 == 4 then
                self.img = self.img2[int((abs(self.lr) + 2) / 6) + 1]
            elseif self.ani2 > 4 then
                self.img = self.img2[int((abs(self.lr) + 2) / 5) + 1]
            end
        end
    end
    local scale = abs(self.hscale)
    self.hscale = sign(self.lr) * scale
end
function BossWalkImageSystem:UpdateImage1()
    --    if self.cast>0 then
    --        self.cast=self.cast-1
    --        self.img=self.imgs[int(self.cast/8)+9]
    --    else
    --        if abs(self.lr)==1 then
    --            self.img=self.imgs[int(self.ani/self.ani_intv)%4+1]
    --        elseif abs(self.lr)==18 then
    --            self.img=self.imgs[8]
    --        else
    --            self.img=self.imgs[int((abs(self.lr)-2)/4)+5]
    --        end
    --    end
    --    self.hscale=sign(self.lr)
end

EnemyWalkImageSystem = plus.Class(WalkImageSystem)
function EnemyWalkImageSystem:init(obj, style, intv)
    WalkImageSystem.init(self, obj, intv, 1, 18)
    self:SetImage(style)
end
function EnemyWalkImageSystem:frame()
    local obj = self.obj
    WalkImageSystem.frame(self, obj.dx)
    if obj.style <= 18 then
        EnemyWalkImageSystem.UpdateImage(obj)
    end
    if type(obj.A) == 'number' and type(obj.B) == 'number' then
        obj.a = obj.A;
        obj.b = obj.B
    end
end
function EnemyWalkImageSystem:render(dmgt, dmgmaxt)
    local obj = self.obj
    local c = 0
    if dmgt and dmgmaxt then
        c = dmgt / dmgmaxt
    end
    if obj._blend and obj._a and obj._r and obj._g and obj._b then
        SetImgState(obj, obj._blend, obj._a, obj._r - obj._r * 0.75 * c, obj._g - obj._g * 0.75 * c, obj._b)
    else
        SetImgState(obj, '', 255, 255 - 255 * 0.75 * c, 255 - 255 * 0.75 * c, 255)
    end

    if obj.aura then
        if obj._blend and obj._a and obj._r and obj._g and obj._b then
            SetImageState('enemy_aura' .. obj.aura, obj._blend, Color(obj._a, obj._r, obj._g, obj._b))
        end
        local breath = 1.25 + 0.15 * sin(obj.timer * 6)
        Render('enemy_aura' .. obj.aura, obj.x, obj.y, obj.timer * 3, obj.hscale * breath, obj.vscale * breath)
        if obj._blend and obj._a and obj._r and obj._g and obj._b then
            SetImageState('enemy_aura' .. obj.aura, '', Color(0xFFFFFFFF))
        end
    end

    --调换到低一层
    if obj.style > 27 and obj.style <= 30 then
        local img = 'Ghost' .. (obj.style - 26) .. int((obj.timer / 4) % 8) + 1
        if obj._blend and obj._a and obj._r and obj._g and obj._b then
            SetImageState(img, obj._blend, Color(obj._a, obj._r, obj._g, obj._b))
        end
        Render(img, obj.x, obj.y, 90, obj.hscale * 1.1, obj.vscale * 1.1)
        if obj._blend and obj._a and obj._r and obj._g and obj._b then
            SetImageState(img, '', Color(0xFFFFFFFF))
        end
    end
    if obj.style > 30 then
        local img = 'Ghost' .. (obj.style - 30) .. int((obj.timer / 4) % 8) + 1
        if obj._blend and obj._a and obj._r and obj._g and obj._b then
            SetImageState(img, obj._blend, Color(obj._a, obj._r, obj._g, obj._b))
        end
        Render(img, obj.x, obj.y, 90, obj.hscale * 1.1, obj.vscale * 1.1)
        if obj._blend and obj._a and obj._r and obj._g and obj._b then
            SetImageState(img, '', Color(0xFFFFFFFF))
        end
    end

    object.render(obj)

    if obj.style > 22 and obj.style <= 26 then
        if obj._blend and obj._a and obj._r and obj._g and obj._b then
            SetImageState('enemy_orb_ring' .. obj.aura, 'mul+add', Color(obj._a, obj._r, obj._g, obj._b))
        end
        Render('enemy_orb_ring' .. obj.aura, obj.x, obj.y, -obj.timer * 6, obj.hscale, obj.vscale)
        Render('enemy_orb_ring' .. obj.aura, obj.x, obj.y, obj.timer * 4, obj.hscale * 1.4, obj.vscale * 1.4)
    end

    if obj._blend and obj._a and obj._r and obj._g and obj._b then
        SetImgState(obj, '', 255, 255, 255, 255)
    end
end
function EnemyWalkImageSystem:SetImage(style, intv)
    local obj = self.obj
    obj.style = style
    obj.aura = _enemy_aura_tb[style]
    obj.death_ef = _death_ef_tb[style]
    obj.ani_intv = intv or obj.ani_intv or 8
    obj.lr = obj.lr or 1
    if style <= 18 then
        obj.imgs = {}
        for i = 1, 12 do
            obj.imgs[i] = 'enemy' .. style .. '_' .. i
        end
    elseif style <= 22 then
        obj.img = 'kedama' .. (style - 18)
        obj.omiga = 12
    elseif style <= 26 then
        obj.img = 'enemy_orb' .. (style - 22)
        obj.omiga = 6
    elseif style == 27 or style == 31 then
        obj.img = 'ghost_fire_r'
        obj.rot = -90
    elseif style == 28 or style == 32 then
        obj.img = 'ghost_fire_b'
        obj.rot = -90
    elseif style == 29 or style == 33 then
        obj.img = 'ghost_fire_g'
        obj.rot = -90
    elseif style == 30 or style == 34 then
        obj.img = 'ghost_fire_y'
        obj.rot = -90
    else
        obj.img = obj.imgs[1]
        obj.style = 0
    end
end
function EnemyWalkImageSystem:UpdateImage()
    if abs(self.lr) == 1 then
        self.img = self.imgs[int(self.ani / self.ani_intv) % 4 + 1]
    elseif abs(self.lr) == 18 then
        self.img = self.imgs[int(self.ani / self.ani_intv) % 4 + 9]
    else
        self.img = self.imgs[int((abs(self.lr) - 2) / 4) + 5]
    end
    self.hscale = sign(self.lr) * abs(self.hscale)
end

PlayerWalkImageSystem = plus.Class()
function PlayerWalkImageSystem:init(obj, intv, leftlr, rightlr)
    self.obj = obj
    self.obj.ani_intv = intv or 8
    self.obj.lr = self.obj.lr or 1
    self.leftlr = leftlr or 6
    self.rightlr = rightlr or 6
    self.obj.protect = self.obj.protect or 0
end
function PlayerWalkImageSystem:update(dx)
    local obj = self.obj
    if dx == nil then
        dx = obj.dx
    end
    if dx > 0.5 then
        dx = 1
    elseif dx < -0.5 then
        dx = -1
    else
        dx = 0
    end
    obj.lr = obj.lr + dx
    if obj.lr > self.rightlr then
        obj.lr = self.rightlr
    end
    if obj.lr < -self.leftlr then
        obj.lr = -self.leftlr
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
end
function PlayerWalkImageSystem:frame(dx)
    local obj = self.obj
    PlayerWalkImageSystem.UpdateImage(obj)
    self:update(dx or 0)
end
function PlayerWalkImageSystem:render()
    local obj = self.obj
    local blend = obj._blend or ""
    local a = obj._alpha or 255
    local r = obj._r or 255
    local g = obj._g or 255
    local b = obj._b or 255
    if obj.protect % 3 == 1 then
        SetImageState(obj.img, blend, Color(a, 0, 0, b))
    else
        SetImageState(obj.img, blend, Color(a, r, g, b))
    end
    Render(obj.img, obj.x, obj.y, obj.rot, obj.hscale, obj.vscale)
end
function PlayerWalkImageSystem:UpdateImage()
    if abs(self.lr) == 1 then
        if self.imgs["normal"] then
            self._wisys.UpdateImageByType(self, "normal")
        else
            self.img = self.imgs[int(self.ani / 8) % 8 + 1]
        end
    elseif self.lr == -self._wisys.leftlr then
        if self.imgs["left"] then
            self._wisys.UpdateImageByType(self, "left2")
        else
            self.img = self.imgs[int(self.ani / 8) % 4 + 13]
        end
    elseif self.lr == self._wisys.rightlr then
        if self.imgs["right"] then
            self._wisys.UpdateImageByType(self, "right2")
        else
            self.img = self.imgs[int(self.ani / 8) % 4 + 21]
        end
    elseif self.lr < 0 then
        if self.imgs["left"] then
            self._wisys.UpdateImageByType(self, "left1")
        else
            self.img = self.imgs[7 - self.lr]
        end
    elseif self.lr > 0 then
        if self.imgs["right"] then
            self._wisys.UpdateImageByType(self, "right1")
        else
            self.img = self.imgs[15 + self.lr]
        end
    end
    self.a = self.A
    self.b = self.B
end
local c1, c2
function PlayerWalkImageSystem:UpdateImageByType(t)
    if t == "normal" then
        c1 = #self.imgs["normal"]
        self.img = self.imgs["normal"][int(self.ani / 8) % c1 + 1]
    elseif t == "left1" then
        self.img = self.imgs["left"][-1 - self.lr]
    elseif t == "right1" then
        self.img = self.imgs["right"][-1 + self.lr]
    elseif t == "left2" then
        c1 = #self.imgs["left"]
        c2 = self.imgs["left"].ani or int(c1 / 2)
        self.img = self.imgs["left"][int(self.ani / 8) % c2 + (c1 - c2) + 1]
    elseif t == "right2" then
        c1 = #self.imgs["right"]
        c2 = self.imgs["right"].ani or int(c1 / 2)
        self.img = self.imgs["right"][int(self.ani / 8) % c2 + (c1 - c2) + 1]
    end
end
