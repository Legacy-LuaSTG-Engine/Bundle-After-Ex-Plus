laser_texture_num = 1
laser_data = {}

function LoadLaserTexture(text, l1, l2, l3, margin)
    local n = laser_texture_num
    local texture = "laser" .. n
    LoadTexture(texture, "THlib/laser/" .. text .. ".png")
    local w, h = GetTextureSize(texture)
    h = h / 16
    LoadImageGroup(texture .. 1, texture, 0, 0, l1, h, 1, 16)
    LoadImageGroup(texture .. 2, texture, l1, 0, l2, h, 1, 16)
    LoadImageGroup(texture .. 3, texture, l1 + l2, 0, l3, h, 1, 16)
    h = h / 2
    for i = 1, 3 do
        for j = 1, 16 do
            SetImageCenter(texture .. i .. j, 0, h)
        end
    end
    laser_data[n] = { l1, l2, l3, h, margin, h - margin }
    laser_texture_num = n + 1
end

LoadLaserTexture("laser1", 64, 128, 64, 1)
LoadLaserTexture("laser2", 5, 236, 15, 1)
LoadLaserTexture("laser3", 127, 1, 128, 1)
LoadLaserTexture("laser4", 1, 254, 1, 1)

LoadImageGroup("laser_node", "bullet1", 80, 0, 32, 32, 1, 8)

laser = Class(object)

function laser:init(index, x, y, rot, l1, l2, l3, w, node, head)
    self.index = max(min(int(index), 16), 1)
    self.imgid = 1
    self.img1 = "laser11" .. self.index
    self.img2 = "laser12" .. self.index
    self.img3 = "laser13" .. self.index
    self.img4 = "laser_node" .. int((self.index + 1) / 2)
    self.img5 = "ball_mid_b" .. int((self.index + 1) / 2)
    self.x = x
    self.y = y
    self.rot = rot
    self.prex = x
    self.prey = y
    self.l1 = l1
    self.l2 = l2
    self.l3 = l3
    self.w0 = w
    self.w = 0
    self.alpha = 0
    self.node = node or 0
    self.head = head or 0
    self.group = GROUP_INDES
    self.layer = LAYER_ENEMY_BULLET
    self.a = 0
    self.b = 0
    self.dw = 0
    self.da = 0
    self.counter = 0
    self._inf_graze = true
    self._blend, self._a, self._r, self._g, self._b = "mul+add", 255, 255, 255, 255
end

function laser:frame()
    task.Do(self)
    if self.counter > 0 then
        self.counter = self.counter - 1
        self.w = self.w + self.dw
        self.alpha = self.alpha + self.da
    end
    if self.alpha > 0.999 and self.colli then
        local x = player.x - self.x
        local y = player.y - self.y
        local rot = self.rot
        local dist = 2
        x, y = x * cos(rot) + y * sin(rot), y * cos(rot) - x * sin(rot)
        y = abs(y)
        if x > 0 then
            local flag = false
            if x < self.l1 then
                if y < x / self.l1 * self.w / dist then
                    player.class.colli(player, self)
                end
                if y < x / self.l1 * self.w / dist + 16 then
                    flag = true
                end
            elseif x < self.l1 + self.l2 then
                if y < self.w / dist then
                    player.class.colli(player, self)
                end
                if y < self.w / dist + 16 then
                    flag = true
                end
            elseif x < self.l1 + self.l2 + self.l3 then
                if y < (self.l1 + self.l2 + self.l3 - x) / self.l3 * self.w / dist then
                    player.class.colli(player, self)
                end
                if y < (self.l1 + self.l2 + self.l3 - x) / self.l3 * self.w / dist + 16 then
                    flag = true
                end
            end
            if self.timer % 4 == 0 and flag then
                player.grazer.class.colli(player.grazer, self)
            end
        end
    end
end

function laser:render()
    local b = self._blend
    if self.w > 0 then
        local c = Color(self._a * self.alpha, self._r, self._g, self._b)
        local data = laser_data[self.imgid]
        local l = self.l1 + self.l2 + self.l3
        local w = (self.w / 2) / data[6] * data[4] / data[6]
        SetImageState(self.img1, b, c)
        Render(self.img1, self.x, self.y, self.rot, self.l1 / data[1], w)
        SetImageState(self.img2, b, c)
        Render(self.img2, self.x + self.l1 * cos(self.rot), self.y + self.l1 * sin(self.rot), self.rot, self.l2 / data[2], w)
        SetImageState(self.img3, b, c)
        Render(self.img3, self.x + (self.l1 + self.l2) * cos(self.rot), self.y + (self.l1 + self.l2) * sin(self.rot), self.rot, self.l3 / data[3], w)
        if self.node > 0 then
            c = Color(self._a * self.w / self.w0, self._r, self._g, self._b)
            SetImageState(self.img4, b, c)
            Render(self.img4, self.x, self.y, 18 * self.timer, self.node / 8)
            Render(self.img4, self.x, self.y, -18 * self.timer, self.node / 8)
        end
        if self.head > 0 then
            c = Color(self._a * self.w / self.w0, self._r, self._g, self._b)
            SetImageState(self.img5, b, c)
            Render(self.img5, self.x + l * cos(self.rot), self.y + l * sin(self.rot), 0, self.head / 8)
            Render(self.img5, self.x + l * cos(self.rot), self.y + l * sin(self.rot), 0, 0.75 * self.head / 8)
        end
    end
end

function laser:kill()
    --老的实现
    PreserveObject(self)
    local w = lstg.world
    if self.class ~= laser_death_ef then
        local cx, cy = cos(self.rot), sin(self.rot)
        local x, y = 0, 0
        local length = ((32768 - GetnObj()) / 2) * 12
        length = min(length, self.l1 + self.l2 + self.l3)
        for l = 0, length, 12 do
            x, y = self.x + l * cx, self.y + l * cy
            if (x <= w.r and x >= w.l) and (y <= w.t and y >= w.b) then
                New(item_faith_minor, x, y)
                if self.index and l % 2 == 0 then
                    New(BulletBreak, x, y, self.index)
                end
            end
        end
        self.class = laser_death_ef
        --self.group = GROUP_GHOST
        self.colli = false
        self._want_set_group = true
        local alpha = self.alpha
        local d = self.w
        task.Clear(self)
        task.New(self, function()
            for i = 1, 30 do
                self.alpha = self.alpha - alpha / 30
                self.w = self.w - d / 30
                task.Wait()
            end
            Del(self)
        end)
    end
end

function laser:del()
    PreserveObject(self)
    if self.class ~= laser_death_ef then
        self.class = laser_death_ef
        --self.group = GROUP_GHOST
        self.colli = false
        self._want_set_group = true
        local alpha = self.alpha
        local d = self.w
        task.Clear(self)
        task.New(self, function()
            for i = 1, 30 do
                self.alpha = self.alpha - alpha / 30
                self.w = self.w - d / 30
                task.Wait()
            end
            Del(self)
        end)
    end
end

local function InScope(var, minvar, maxvar)
    return (var >= minvar) and (var <= maxvar)
end

local function GetIntersction(x1, y1, rot1, x2, y2, rot2)
    local t = (x2 - x1) / cos(rot1)
    local y = y1 + t * sin(rot1)
    return x2, y
end

function laser:newkill()
    PreserveObject(self)
    if self.class ~= laser_death_ef then
        local x1, y1, x2, y2, x, y
        local w = lstg.world
        local x0, y0, rot = self.x, self.y, self.rot
        local len = self.l1 + self.l2 + self.l3
        local tx0, ty0 = x0 + len * cos(rot), y0 + len * sin(rot)
        if x0 > tx0 then
            x0, tx0, y0, ty0 = tx0, x0, ty0, y0
        end
        --
        local bx, by = GetIntersction(x0, y0, rot, w.boundl, w.boundb, 0)
        local lx, ly = GetIntersction(x0, y0, rot, w.boundl, w.boundb, 90)
        local tx, ty = GetIntersction(x0, y0, rot, w.boundr, w.boundt, 180)
        local rx, ry = GetIntersction(x0, y0, rot, w.boundr, w.boundt, 270)
        --
        local flag = InScope(x0, w.boundl, w.boundr)
        flag = flag or InScope(tx0, w.boundl, w.boundr)
        flag = flag or InScope(y0, w.boundb, w.boundt)
        flag = flag or InScope(ty0, w.boundb, w.boundt)
        flag = flag or InScope(bx, w.boundl, w.boundr)
        flag = flag or InScope(tx, w.boundl, w.boundr)
        flag = flag or InScope(ly, w.boundb, w.boundt)
        flag = flag or InScope(ry, w.boundb, w.boundt)
        if flag then
            if by < ly then
                if x0 < bx then
                    x1, y1 = bx, by
                else
                    x1, y1 = x0, y0
                end
            else
                if x0 < lx then
                    x1, y1 = lx, ly
                else
                    x1, y1 = x0, y0
                end
            end
            if ry < ty then
                if tx0 < rx then
                    x2, y2 = tx0, ty0
                else
                    x2, y2 = rx, ry
                end
            else
                if tx0 < tx then
                    x2, y2 = tx0, ty0
                else
                    x2, y2 = tx, ty
                end
            end
            len = Dist(x1, y1, x2, y2)
            if self.x <= x1 then
                x, y = x1, y1
            else
                x, y, rot = x2, y2, rot + 180
            end
            local cx, cy = cos(rot), sin(rot)
            for l = 0, len, 12 do
                New(item_faith_minor, x + l * cx, y + l * cy)
                if l % 2 == 0 and self.index then
                    New(BulletBreak, x + l * cx, y + l * cy, self.index)
                end
            end
        end
        self.class = laser_death_ef
        --self.group = GROUP_GHOST
        self.colli = false
        self._want_set_group = true
        local alpha = self.alpha
        local d = self.w
        task.Clear(self)
        task.New(self, function()
            for i = 1, 30 do
                self.alpha = self.alpha - alpha / 30
                self.w = self.w - d / 30
                task.Wait()
            end
            Del(self)
        end)
    end
end

function laser:ChangeImage(id, index)
    self.imgid = max(min(int(id), laser_texture_num - 1), 1)
    if index then
        self.index = max(min(int(index), 16), 1)
    end
    local index = self.index
    local id = self.imgid
    self.img1 = "laser" .. id .. "1" .. index
    self.img2 = "laser" .. id .. "2" .. index
    self.img3 = "laser" .. id .. "3" .. index
    self.img4 = "laser_node" .. int((index + 1) / 2)
    self.img5 = "ball_mid_b" .. int((index + 1) / 2)
end

function laser:grow(time, mute, wait)
    if mute then
        PlaySound("lazer00", 0.25, self.x / 200)
    end
    if time == 0 then
        return
    end
    local l1, l2, l3 = self.l1, self.l2, self.l3
    local add = (l1 + l2 + l3) / time
    self.l1, self.l2, self.l3 = 0, 0, 0
    self.alpha = 1
    self.w = self.w0
    task.New(self, function()
        for i = 1, time do
            if not IsValid(self) then
                break
            elseif self.l2 == l2 then
                self.l1 = self.l1 + add
            elseif self.l2 > l2 then
                self.l1 = self.l1 + add + self.l2 - l2
                self.l2 = l2
            elseif self.l3 == l3 then
                self.l2 = self.l2 + add
            elseif self.l3 > l3 then
                self.l2 = self.l2 + add + self.l3 - l3
                self.l3 = l3
            else
                self.l3 = self.l3 + add
            end
            task.Wait(1)
        end
        if IsValid(self) then
            self.l1 = l1
        end
    end)
    if task.GetSelf() == self and wait then
        task.Wait(time)
    end
end

function laser:TurnOn(t, mute)
    t = t or 30
    t = max(1, int(t))
    if not mute then
        PlaySound("lazer00", 0.25, self.x / 200)
    end
    self.counter = t
    self.da = (1 - self.alpha) / t
    self.dw = (self.w0 - self.w) / t
end

function laser:TurnHalfOn(t)
    t = t or 30
    t = max(1, int(t))
    self.counter = t
    self.da = (0.5 - self.alpha) / t
    self.dw = (0.5 * self.w0 - self.w) / t
end

function laser:TurnOff(t)
    t = t or 30
    t = max(1, int(t))
    self.counter = t
    self.da = -self.alpha / t
    self.dw = -self.w / t
end

laser_death_ef = Class(laser)

function laser_death_ef:frame()
    if self._want_set_group then
        self._want_set_group = false
        self.group = GROUP_GHOST
    end
    task.Do(self)
end

function laser_death_ef:del()
end

function laser_death_ef:kill()
end

Include("THlib/laser/bent laser.lua")
