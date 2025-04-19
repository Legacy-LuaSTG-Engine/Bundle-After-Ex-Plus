--------------------------------------------------------------------------------
--- common bullet color index

COLOR_DEEP_RED = 1
COLOR_RED = 2
COLOR_DEEP_PURPLE = 3
COLOR_PURPLE = 4
COLOR_DEEP_BLUE = 5
COLOR_BLUE = 6
COLOR_ROYAL_BLUE = 7
COLOR_CYAN = 8
COLOR_DEEP_GREEN = 9
COLOR_GREEN = 10
COLOR_CHARTREUSE = 11
COLOR_YELLOW = 12
COLOR_GOLDEN_YELLOW = 13
COLOR_ORANGE = 14
COLOR_DEEP_GRAY = 15
COLOR_GRAY = 16

--------------------------------------------------------------------------------
--- bullet effect: destroy

-- replace by plugin
BulletBreak = Class(object)

---@diagnostic disable-next-line: duplicate-set-field
function BulletBreak:init(x, y, index)
    -- replace by plugin
    Del(self)
end

---@diagnostic disable-next-line: duplicate-set-field
function BulletBreak:frame()
    -- replace by plugin
end

--------------------------------------------------------------------------------
--- bullet class

bullet = Class(object)

function bullet:init(imgclass, index, stay, destroyable)
    self.logclass = self.class
    self.imgclass = imgclass
    self.class = imgclass
    if destroyable then
        self.group = GROUP_ENEMY_BULLET
    else
        self.group = GROUP_INDES
    end
    if type(index) == 'number' then
        self.colli = true
        self.stay = stay
        index = int(min(max(1, index), 16))
        self.layer = LAYER_ENEMY_BULLET_EF - imgclass.size * 0.001 + index * 0.00001
        self._index = index
        self.index = int((index + 1) / 2)
    end
    imgclass.init(self, index)
end

function bullet:frame()
    task.Do(self)
end

function bullet:kill()
    local w = lstg.world
    New(item_faith_minor, self.x, self.y)
    if self._index and BoxCheck(self, w.boundl, w.boundr, w.boundb, w.boundt) then
        New(BulletBreak, self.x, self.y, self._index)
    end
    if self.imgclass.size == 2.0 then
        self.imgclass.del(self)
    end
end

function bullet:del()
    --	self.imgclass.del(self)
    local w = lstg.world
    if self.imgclass.size == 2.0 then
        self.imgclass.del(self)
    end
    if self._index and BoxCheck(self, w.boundl, w.boundr, w.boundb, w.boundt) then
        New(BulletBreak, self.x, self.y, self._index)
    end
end

function bullet:render()
    if self._blend and self._a and self._r and self._g and self._b then
        SetImgState(self, self._blend, self._a, self._r, self._g, self._b)
    end
    DefaultRenderFunc(self)
    if self._blend and self._a and self._r and self._g and self._b then
        SetImgState(self, '', 255, 255, 255, 255)
    end
end

--- 快速跳过淡入效果（或者叫雾化效果）  
--- 原理是立即切换到子弹逻辑，并根据子弹“尺寸”应用图层  
--- 用法：bullet.skip_fade_in(some_object)  
function bullet:skip_fade_in()
    self.class = self.logclass
    self.layer = LAYER_ENEMY_BULLET - self.imgclass.size * 0.001 + self._index * 0.00001
end

--------------------------------------------------------------------------------
--- bullet class

img_class = Class(object)

function img_class:frame()
    if not self.stay then
        if not (self._forbid_ref) then
            --by OLC，修正了defaul action死循环的问题
            self._forbid_ref = true
            self.logclass.frame(self)
            self._forbid_ref = nil
        end
    else
        self.x = self.x - self.vx
        self.y = self.y - self.vy
        self.rot = self.rot - self.omiga
    end
    if self.timer == 11 then
        self.class = self.logclass
        self.layer = LAYER_ENEMY_BULLET - self.imgclass.size * 0.001 + self._index * 0.00001
        --		self.colli=true
        if self.stay then
            self.timer = -1
        end
    end
end

---@diagnostic disable-next-line: duplicate-set-field
function img_class:del()
    -- replace by plugin
end

function img_class:kill()
    img_class.del(self)
    New(BulletBreak, self.x, self.y, self._index)
    New(item_faith_minor, self.x, self.y)
end

---@diagnostic disable-next-line: duplicate-set-field
function img_class:render()
    -- replace by plugin
end

function ChangeBulletImage(obj, imgclass, index)
    if obj.class == obj.imgclass then
        obj.class = imgclass
        obj.imgclass = imgclass
    else
        obj.imgclass = imgclass
    end
    obj._index = index
    imgclass.init(obj, obj._index)
end

--------------------------------------------------------------------------------

straight = Class(bullet)

function straight:init(imgclass, index, stay, x, y, v, angle, omiga)
    self.x = x
    self.y = y
    SetV(self, v, angle, true)
    self.omiga = omiga or 0
    bullet.init(self, imgclass, index, stay, true)
end

--------------------------------------------------------------------------------

straight_indes = Class(bullet)

function straight_indes:init(imgclass, index, stay, x, y, v, angle, omiga)
    self.x = x
    self.y = y
    SetV(self, v, angle, true)
    self.omiga = omiga or 0
    bullet.init(self, imgclass, index, stay, false)
    self.group = GROUP_INDES
end

--------------------------------------------------------------------------------

straight_495 = Class(bullet)

function straight_495:init(imgclass, index, stay, x, y, v, angle, omiga)
    self.x = x
    self.y = y
    SetV(self, v, angle, true)
    self.omiga = omiga or 0
    bullet.init(self, imgclass, index, stay, true)
end

function straight_495:frame()
    if not self.reflected then
        local world = lstg.world
        local x, y = self.x, self.y
        if y > world.t then
            self.vy = -self.vy
            if self.acceleration and self.acceleration.ay then
                self.acceleration.ay = -self.acceleration.ay
            end
            self.rot = -self.rot
            self.reflected = true
            return
        end
        if x > world.r then
            self.vx = -self.vx
            if self.acceleration and self.acceleration.ax then
                self.acceleration.ax = -self.acceleration.ax
            end
            self.rot = 180 - self.rot
            self.reflected = true
            return
        end
        if x < world.l then
            self.vx = -self.vx
            if self.acceleration and self.acceleration.ax then
                self.acceleration.ax = -self.acceleration.ax
            end
            self.rot = 180 - self.rot
            self.reflected = true
            return
        end
    end
end

--------------------------------------------------------------------------------

bullet_killer = Class(object)

function bullet_killer:init(x, y, kill_indes)
    self.x = x
    self.y = y
    self.group = GROUP_GHOST
    self.hide = true
    self.kill_indes = kill_indes
end

function bullet_killer:frame()
    if self.timer == 40 then
        Del(self)
    end
    for i, o in ObjList(GROUP_ENEMY_BULLET) do
        if Dist(self, o) < self.timer * 20 then
            Kill(o)
        end
    end
    if self.kill_indes then
        for i, o in ObjList(GROUP_INDES) do
            if Dist(self, o) < self.timer * 20 then
                Kill(o)
            end
        end
    end
end

--------------------------------------------------------------------------------

bullet_deleter = Class(object)

function bullet_deleter:init(x, y, kill_indes)
    self.x = x
    self.y = y
    self.group = GROUP_GHOST
    self.hide = true
    self.kill_indes = kill_indes
end

function bullet_deleter:frame()
    if self.timer == 60 then
        Del(self)
    end
    for i, o in ObjList(GROUP_ENEMY_BULLET) do
        if Dist(self, o) < self.timer * 20 then
            Del(o)
        end
    end
    if self.kill_indes then
        for i, o in ObjList(GROUP_INDES) do
            if Dist(self, o) < self.timer * 20 then
                Del(o)
            end
        end
    end
end

--------------------------------------------------------------------------------

bomb_bullet_killer = Class(object)

function bomb_bullet_killer:init(x, y, a, b, kill_indes)
    self.x = x
    self.y = y
    self.a = a
    self.b = b
    if self.a ~= self.b then
        self.rect = true
    end
    self.group = GROUP_PLAYER
    self.hide = true
    self.kill_indes = kill_indes
end

function bomb_bullet_killer:frame()
    if self.timer == 1 then
        Del(self)
    end
end

function bomb_bullet_killer:colli(other)
    if self.kill_indes then
        if other.group == GROUP_INDES then
            Kill(other)
        end
    end
    if other.group == GROUP_ENEMY_BULLET then
        Kill(other)
    end
end

--------------------------------------------------------------------------------
