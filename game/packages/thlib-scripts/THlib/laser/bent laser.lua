---=====================================
---touhou style bent lazer
---=====================================

----------------------------------------
---res

LoadTexture('laser_bent2', 'THlib/laser/laser5.png')

----------------------------------------
---bent lazer

laser_bent = Class(object)

function laser_bent:init(index, x, y, l, w, sample, node)
    self.index = index
    self.x = x
    self.y = y
    self.l = max(int(l), 2)
    self.w = w
    self.w0 = w
    self._w = w
    self.group = GROUP_INDES
    self.layer = LAYER_ENEMY_BULLET
    self.data = BentLaserData()
    self.bound = false
    self._bound = true
    self.prex = x
    self.prey = y
    self.listx = {}
    self.listy = {}
    self.node = node or 0
    self._l = int(l / 4)
    self.img4 = 'laser_node' .. int((self.index + 1) / 2)
    self.pause = 0
    self.a = 0
    self.b = 0
    self.dw = 0
    self.da = 0
    self.alpha = 1
    self.counter = 0
    self._colli = true
    self._inf_graze = true
    self.deactive = 0
    self.sample = sample--by OLC，不使用换class来实现
    self._blend, self._a, self._r, self._g, self._b = 'mul+add', 255, 255, 255, 255

    setmetatable(self, { __index = GetAttr, __newindex = laser_bent_meta_newindex })
end

function laser_bent_meta_newindex(t, k, v)
    if k == 'bound' then
        rawset(t, '_bound', v)
    elseif k == 'colli' then
        rawset(t, '_colli', v)
    else
        SetAttr(t, k, v)
    end
end

function laser_bent:frame()
    --by ETC
    task.Do(self)

    SetAttr(self, 'colli', self._colli and self.alpha > 0.999)

    if self.counter > 0 then
        self.counter = self.counter - 1
        self.w = self.w + self.dw
        self.alpha = self.alpha + self.da
    end
    local _l = self._l

    if self.pause > 0 then
        --self.pause=self.pause-1
    else
        if self.timer % 4 == 0 then
            self.listx[(self.timer / 4) % _l] = self.x
            self.listy[(self.timer / 4) % _l] = self.y
        end
        self.data:Update(self, self.l, self.w, self.deactive)
    end

    if self.w ~= self._w then
        laser_bent.setWidth(self, self.w)
        self._w = self.w
    end

    if self.alpha > 0.999 and self._colli then
        --可改为使用自机圆碰撞判定
        if self._colli and self.data:CollisionCheck(player.x,player.y,player.rot,player.A,player.B,player.rect) then
        --if self._colli and self.data:CollisionCheck(player.x, player.y) then
            player.class.colli(player, self)
        end
        if self.timer % 4 == 0 then
            --可改为使用自机圆碰撞判定
            if self._colli and self.data:CollisionCheckWidth(player.grazer.x,player.grazer.y,self.w,player.grazer.rot,player.grazer.a,player.grazer.b,player.grazer.rect) then
            --if self._colli and self.data:CollisionCheckWidth(player.x, player.y, self.w + 48) then
                player.grazer.class.colli(player.grazer, self)
            end
        end
    end
    if self._bound and not self.data:BoundCheck() and
            not BoxCheck(self, lstg.world.boundl, lstg.world.boundr, lstg.world.boundb, lstg.world.boundt) then
        Del(self)
    end
end

function laser_bent:setWidth(w)
    self.w = w
    self.data:SetAllWidth(self.w)
end

function laser_bent:render()
    --by OLC
    if laser_bent_renderFunc[self.sample] then
        laser_bent_renderFunc[self.sample](self)
    end
end

function laser_bent:del()
    New(laser_bent_death_ef, self.index, self.data, self.sample, self._blend, self._a, self._r, self._g, self._b)
end

function laser_bent:kill()
    --by ETC
    for i = 0, self._l do
        if self.listx[i] and self.listy[i] then
            New(item_faith_minor, self.listx[i], self.listy[i])
            if self.index and i % 2 == 0 then
                New(BulletBreak, self.listx[i], self.listy[i], self.index)
            end
        end
    end
    New(laser_bent_death_ef, self.index, self.data, self.sample, self._blend, self._a, self._r, self._g, self._b)
end

--by OLC，通过换函数的方式改变样式
laser_bent_renderFunc = {
    [0] = function(self)
        self.data:Render('laser_bent2', self._blend, Color(self._a * self.alpha, self._r, self._g, self._b), 0, 32 * (int(0.5 * self.timer) % 4), 256, 32)
        if self.timer < self._l * 4 and self.node then
            local c = Color(self._a, self._r, self._g, self._b)
            SetImageState(self.img4, self._blend, c)
            Render(self.img4, self.prex, self.prey, -3 * self.timer, (8 + self.timer % 3) * 0.125 * self.node / 8)
            Render(self.img4, self.prex, self.prey, -3 * self.timer + 180, (8 + self.timer % 3) * 0.125 * self.node / 8)
        end
    end,
    [4] = function(self)
        self.data:Render('laser3', self._blend, Color(self._a * self.alpha, self._r, self._g, self._b), 0, self.index * 16 - 12, 256, 8)
        if self.timer < self._l * 4 and self.node then
            local c = Color(self._a, self._r, self._g, self._b)
            SetImageState(self.img4, self._blend, c)
            Render(self.img4, self.prex, self.prey, -3 * self.timer, (8 + self.timer % 3) * 0.125 * self.node / 8)
            Render(self.img4, self.prex, self.prey, -3 * self.timer + 180, (8 + self.timer % 3) * 0.125 * self.node / 8)
        end
    end,
}
laser_bent_renderFuncDeath = {
    [0] = function(self)
        self.data:Render('laser_bent2', self._blend, Color(self._a * (1 - self.timer / 30), self._r, self._g, self._b), 0, 32 * (int(0.5 * self.timer) % 4), 256, 32)
    end,
    [4] = function(self)
        self.data:Render('laser3', self._blend, Color(self._a * (1 - self.timer / 30), self._r, self._g, self._b), 0, self.index * 16 - 12, 256, 8)
    end,
}

--by OLC，可自由添加激光类型
function Add_bentlaser_texture(id, tex)
    if id ~= 0 and id ~= 4 then
        local w, h = GetTextureSize(tex)
        laser_bent_renderFunc[id] = function(self)
            self.data:Render(tex, self._blend, Color(self._a * self.alpha, self._r, self._g, self._b), 0, 0, w, h)
            if self.timer < self._l * 4 and self.node then
                local c = Color(self._a, self._r, self._g, self._b)
                SetImageState(self.img4, self._blend, c)
                Render(self.img4, self.prex, self.prey, -3 * self.timer, (8 + self.timer % 3) * 0.125 * self.node / 8)
                Render(self.img4, self.prex, self.prey, -3 * self.timer + 180, (8 + self.timer % 3) * 0.125 * self.node / 8)
            end
        end
        laser_bent_renderFuncDeath[id] = function(self)
            self.data:Render(tex, self._blend, Color(self._a * (1 - self.timer / 30), self._r, self._g, self._b), 0, 0, w, h)
        end
    else
        Print("不能修改默认曲线激光样式")
    end
end
function Add_bentlaser_thunder_texture(id, tex)
    if id ~= 0 and id ~= 4 then
        local w, h = GetTextureSize(tex)
        h = h / 4
        laser_bent_renderFunc[id] = function(self)
            self.data:Render(tex, self._blend, Color(self._a * self.alpha, self._r, self._g, self._b), 0, h * (int(0.5 * self.timer) % 4), w, h)
            if self.timer < self._l * 4 and self.node then
                local c = Color(self._a, self._r, self._g, self._b)
                SetImageState(self.img4, self._blend, c)
                Render(self.img4, self.prex, self.prey, -3 * self.timer, (8 + self.timer % 3) * 0.125 * self.node / 8)
                Render(self.img4, self.prex, self.prey, -3 * self.timer + 180, (8 + self.timer % 3) * 0.125 * self.node / 8)
            end
        end
        laser_bent_renderFuncDeath[id] = function(self)
            self.data:Render(tex, self._blend, Color(self._a * (1 - self.timer / 30), self._r, self._g, self._b), 0, h * (int(0.5 * self.timer) % 4), w, h)
        end
    else
        Print("不能修改默认曲线激光样式")
    end
end

--by ETC
laser_bent_death_ef = Class(object)
function laser_bent_death_ef:init(index, data, sample, blend, a, r, g, b)
    self.data = data
    self.sample = sample
    self.index = index

    self.group = GROUP_GHOST
    self.bound = false

    self._blend, self._a, self._r, self._g, self._b = blend, a, r, g, b
end
function laser_bent_death_ef:frame()
    if self.timer == 30 then
        self.data:Release()
        Del(self)
    end
end
function laser_bent_death_ef:render()
    if laser_bent_renderFuncDeath[self.sample] then
        laser_bent_renderFuncDeath[self.sample](self)
    end
end
