--======================================
--杂项
--======================================

misc = {}

----------------------------------------
--杂项功能

--多种消亡特效
hinter = Class(object)
function hinter:init(img, size, x, y, t1, t2, fade)
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
end
function hinter:frame()
    if self.timer < self.t1 then
        self.t = self.timer / self.t1
    elseif self.timer < self.t1 + self.t2 then
        self.t = 1
    elseif self.timer < self.t1 * 2 + self.t2 then
        self.t = (self.t1 * 2 + self.t2 - self.timer) / self.t1
    else
        Del(self)
    end
end
function hinter:render()
    if self.fade then
        SetImageState(self.img, '', Color(self.t * 255, 255, 255, 255))
        self.vscale = self.size
        object.render(self)
    else
        SetImageState(self.img, '', Color(0xFFFFFFFF))
        self.vscale = self.t * self.size
        object.render(self)
    end
end

bubble = Class(object)
function bubble:init(img, x, y, life_time, size1, size2, color1, color2, layer, blend)
    self.img = img
    self.x = x
    self.y = y
    self.group = GROUP_GHOST
    self.life_time = life_time
    self.size1 = size1
    self.size2 = size2
    self.color1 = color1
    self.color2 = color2
    self.layer = layer
    self.blend = blend or ''
end
function bubble:render()
    local t = (self.life_time - self.timer) / self.life_time
    local size = self.size1 * t + self.size2 * (1 - t)
    local c = self.color1 * t + self.color2 * (1 - t)
    SetImageState(self.img, self.blend, c)
    Render(self.img, self.x, self.y, 0, size)
end
function bubble:frame()
    if self.timer == self.life_time - 1 then
        Del(self)
    end
end

bubble2 = Class(object)
function bubble2:init(img, x, y, vx, vy, life_time, size1, size2, color1, color2, layer, blend)
    self.img = img
    self.x = x
    self.y = y
    self.vx = vx
    self.vy = vy
    self.group = GROUP_GHOST
    self.life_time = life_time
    self.size1 = size1
    self.size2 = size2
    self.color1 = color1
    self.color2 = color2
    self.layer = layer
    self.blend = blend or ''
end
function bubble2:render()
    local t = (self.life_time - self.timer) / self.life_time
    local size = self.size1 * t + self.size2 * (1 - t)
    local c = self.color1 * t + self.color2 * (1 - t)
    SetImageState(self.img, self.blend, c)
    Render(self.img, self.x, self.y, 0, size)
end
function bubble2:frame()
    if self.timer == self.life_time - 1 then
        Del(self)
    end
end

--收点时头上飞出的数字
float_text = Class(object)
function float_text:init(fnt, text, x, y, v, angle, life_time, size1, size2, color1, color2)
    self.fnt = fnt
    self.text = text
    self.x = x
    self.y = y
    self.vx = v * cos(angle)
    self.vy = v * sin(angle)
    self.group = GROUP_GHOST
    self.life_time = life_time
    self.size1 = size1
    self.size2 = size2
    self.color1 = color1
    self.color2 = color2
    self.layer = LAYER_TOP
end
function float_text:render()
    local t = (self.life_time - self.timer) / self.life_time
    local size = self.size1 * t + self.size2 * (1 - t)
    local c = self.color1 * t + self.color2 * (1 - t)
    SetFontState(self.fnt, '', c)
    RenderText(self.fnt, self.text, self.x, self.y, size, 'centerpoint')
end
function float_text:frame()
    if self.timer == self.life_time - 1 then
        Del(self)
    end
end

float_text2 = Class(object)
function float_text2:init(fnt, text, x, y, v, angle, life_time, size1, size2, color1, color2)
    self.fnt = fnt
    self.text = text
    self.x = x
    self.y = y
    self.vx = v * cos(angle)
    self.vy = v * sin(angle)
    self.group = GROUP_GHOST
    self.life_time = life_time
    self.size1 = size1
    self.size2 = size2
    self.color1 = color1
    self.color2 = color2
    self.layer = LAYER_TOP
end
function float_text2:render()
    local t = (self.life_time - self.timer) / self.life_time
    local size = self.size1 * t + self.size2 * (1 - t)
    local c = self.color1 * t + self.color2 * (1 - t)
    SetFontState(self.fnt, '', Color(255 * t, 80, 80, 80))
    RenderText(self.fnt, self.text, self.x + 0.6, self.y + 0.6, size, 'centerpoint')
    RenderText(self.fnt, self.text, self.x + 0.6, self.y - 0.6, size, 'centerpoint')
    RenderText(self.fnt, self.text, self.x - 0.6, self.y - 0.6, size, 'centerpoint')
    RenderText(self.fnt, self.text, self.x - 0.6, self.y + 0.6, size, 'centerpoint')
    SetFontState(self.fnt, '', c)
    RenderText(self.fnt, self.text, self.x, self.y, size, 'centerpoint')
end
function float_text2:frame()
    if self.timer == self.life_time - 1 then
        Del(self)
    end
end

--tasker
tasker = Class(object)
function tasker:init(f, group)
    self.group = group or GROUP_GHOST
    task.New(self, f)
end
function tasker:frame()
    task.Do(self)
    if coroutine.status(self.task[1]) == 'dead' then
        Del(self)
    end
end

--------------------------------------------------------------------------------
--- 形状渲染

function misc.RenderRing(img, x, y, r1, r2, rot, n, nimg)
    --boss card
    local da = 360 / n
    local a = rot
    for i = 1, n do
        a = rot - da * i
        Render4V(img .. ((i - 1) % nimg + 1),
                r1 * cos(a + da) + x, r1 * sin(a + da) + y, 0.5,
                r2 * cos(a + da) + x, r2 * sin(a + da) + y, 0.5,
                r2 * cos(a) + x, r2 * sin(a) + y, 0.5,
                r1 * cos(a) + x, r1 * sin(a) + y, 0.5)
    end
end

function misc.Renderhp(x, y, rot, la, r1, r2, n, c)
    --boss
    local da = la / n
    local nn = int(n * c)
    for i = 1, nn do
        local a = rot + da * i
        Render4V('hpbar1',
                r1 * cos(a + da) + x, r1 * sin(a + da) + y, 0.5,
                r2 * cos(a + da) + x, r2 * sin(a + da) + y, 0.5,
                r2 * cos(a) + x, r2 * sin(a) + y, 0.5,
                r1 * cos(a) + x, r1 * sin(a) + y, 0.5)
    end
end

function misc.Renderhpbar(x, y, rot, la, r1, r2, n, c)
    --boss
    local da = la / n
    local nn = int(n * c)
    for i = 1, nn do
        local a = rot + da * i
        Render4V('hpbar2',
                r1 * cos(a + da) + x, r1 * sin(a + da) + y, 0.5,
                r2 * cos(a + da) + x, r2 * sin(a + da) + y, 0.5,
                r2 * cos(a) + x, r2 * sin(a) + y, 0.5,
                r1 * cos(a) + x, r1 * sin(a) + y, 0.5)
    end
end

function renderstar(x, y, r, point)
    --?
    local ang = 360 / (2 * point)
    for angle = 360 / point, 360, 360 / point do
        local x1, y1 = x + r * cos(angle + ang) ^ 3, r * sin(angle + ang) ^ 3
        local x2, y2 = x + r * cos(angle - ang) ^ 3, r * sin(angle - ang) ^ 3
        Render4V('_sub_white', x, y, 0.5,
                x, y, 0.5,
                x1, y1, 0.5,
                x2, y2, 0.5)
    end
end

function rendercircle(x, y, r, point)
    --player death effect
    local ang = 360 / (2 * point)
    for angle = 360 / point, 360, 360 / point do
        local x1, y1 = x + r * cos(angle + ang), y + r * sin(angle + ang)
        local x2, y2 = x + r * cos(angle - ang), y + r * sin(angle - ang)
        Render4V('_rev_white', x, y, 0.5,
                x, y, 0.5,
                x1, y1, 0.5,
                x2, y2, 0.5)
    end
end

--------------------------------------------------------------------------------
--- 切换关卡用的幕布

shutter = Class(object)
function shutter:init(mode)
    self.layer = LAYER_TOP + 100
    self.group = GROUP_GHOST
    self.open = (mode == 'open')
end
function shutter:frame()
    if self.timer == 60 then
        Del(self)
    end
end
function shutter:render()
    SetViewMode 'ui'
    SetImageState('white', '', Color(0xFF000000))
    if self.open then
        for i = 0, 15 do
            RenderRect('white', (i + 1 - min(max(1 - self.timer / 30 + i / 16, 0), 1)) * (screen.width / 16), (i + 1) * (screen.width / 16), 0, screen.height)
        end
    else
        for i = 0, 15 do
            RenderRect('white', i * (screen.width / 16), (i + min(max(self.timer / 30 - i / 16, 0), 1)) * (screen.width / 16), 0, screen.height)
        end
    end
end

mask_fader = Class(object)
function mask_fader:init(mode)
    self.layer = LAYER_TOP + 100
    self.group = GROUP_GHOST
    self.open = (mode == 'open')
end
function mask_fader:frame()
    if self.timer > 30 then
        Del(self)
    end
end
function mask_fader:render()
    SetViewMode 'ui'
    if self.open then
        SetImageState('white', '', Color(max(0, min(255, 255 - self.timer * 8.5)), 0, 0, 0))
    else
        SetImageState('white', '', Color(max(0, min(255, self.timer * 8.5)), 0, 0, 0))
    end
    RenderRect('white', 0, screen.width, 0, screen.height)
    SetViewMode 'world'
end

--------------------------------------------------------------------------------
--- 震屏效果

local Shaker = Class(object)
shaker_maker = Shaker
function Shaker:init(time, size)
    lstg.tmpvar._G_shaker = self
    self.time = time
    self.size = size
    self.offset = lstg.worldoffset
    --[[
    self.l=lstg.world.l
    self.r=lstg.world.r
    self.bb=lstg.world.b
    self.t=lstg.world.t
    --]]
end
function Shaker:frame()
    local a = int(self.timer / 3) * 360 / 5 * 2
    local x = self.size * cos(a)
    local y = self.size * sin(a)
    self.offset.dx = x
    self.offset.dy = y
    --[[
    lstg.world.l=self.l+x
    lstg.world.r=self.r+x
    lstg.world.b=self.bb+y
    lstg.world.t=self.t+y
    --]]
    if self.timer >= self.time then
        Del(self)
    end
end
function Shaker:del()
    self.offset.dx = 0
    self.offset.dy = 0
    --[[
    lstg.world.l=self.l
    lstg.world.r=self.r
    lstg.world.b=self.bb
    lstg.world.t=self.t
    --]]
    lstg.tmpvar._G_shaker = nil
end
function Shaker:kill()
    self.offset.dx = 0
    self.offset.dy = 0
    --[[
    lstg.world.l=self.l
    lstg.world.r=self.r
    lstg.world.b=self.bb
    lstg.world.t=self.t
    --]]
    lstg.tmpvar._G_shaker = nil
end

--- 震屏
--- by ETC: 不再直接改lrbt
function misc.ShakeScreen(t, s)
    if lstg.tmpvar._G_shaker then
        lstg.tmpvar._G_shaker.time = t
        lstg.tmpvar._G_shaker.size = s
        lstg.tmpvar._G_shaker.timer = 0
    else
        New(Shaker, t, s)
    end
end

--------------------------------------------------------------------------------
--- 维持粒子特效

local ParticleMaintainer = Class(object)
ParticleKepper = ParticleMaintainer
function ParticleMaintainer:frame()
    -- NEW BEGIN
    if self._want_set_group then
        self._want_set_group = false
        self.group = GROUP_GHOST
    end
    -- NEW END

    if ParticleGetn(self) == 0 then
        Del(self)
    end
end

--- 维持粒子特效直到消失  
--- 警告：使用了改类功能  
--- 警告：新的写法延迟了碰撞组修改的时机，防止在碰撞检测时炸游戏  
function misc.KeepParticle(o)
    o.class = ParticleMaintainer
    PreserveObject(o)
    ParticleStop(o)
    o.bound = false

    -- OLD BEGIN
    --o.group = GROUP_GHOST
    -- OLD END

    -- NEW BEGIN
    o.colli = false
    o._want_set_group = true
    -- NEW END
end

--------------------------------------------------------------------------------
--- 资源

--一些乱七八糟的东西
LoadTexture('misc', 'THlib/misc/misc.png')
LoadImage('player_aura', 'misc', 128, 0, 64, 64)
LoadImageGroup('bubble', 'misc', 192, 0, 64, 64, 1, 4)
LoadImage('border', 'misc', 128, 192, 64, 64)
LoadImage('leaf', 'misc', 0, 32, 32, 32)
LoadImage('white', 'misc', 56, 8, 16, 16)
--预制粒子特效图片
LoadTexture('particles', 'THlib/misc/particles.png')
LoadImageGroup('parimg', 'particles', 0, 0, 32, 32, 4, 4)
--空图片
LoadImageFromFile('img_void', 'THlib/misc/img_void.png')
--反色圈和星星的素材，预先设置好混合和颜色减少性能消耗
CopyImage("_rev_white", "white")
SetImageState('_rev_white', 'add+sub',
        Color(255, 255, 255, 255),
        Color(255, 255, 255, 255),
        Color(255, 0, 0, 0),
        Color(255, 0, 0, 0)
)
CopyImage("_sub_white", "white")
SetImageState('_sub_white', 'mul+sub',
        Color(255, 100, 100, 100),
        Color(255, 255, 255, 255),
        Color(255, 0, 0, 0),
        Color(255, 0, 0, 0)
)
