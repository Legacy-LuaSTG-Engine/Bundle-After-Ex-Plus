---boss 符卡
boss.card = {}

---@class boss.card
local card = {}
boss.card._default_card = card
function card:before()
end
function card:init()
end
function card:frame()
end
function card:render()
end
function card:beforedel()
end
function card:del()
end
function card:after()
end

---创建一个符卡
---@param name @符卡名
---@param t1 number @无敌时间
---@param t2 number @防御时间
---@param t3 number @总时间
---@param hp number @最大生命值
---@param drop table @掉落物
---@param is_extra boolean @是否免疫自机符卡
---@return boss.card
function boss.card.New(name, t1, t2, t3, hp, drop, is_extra)
    local c = {}
    for k, v in pairs(boss.card._default_card) do
        c[k] = v
    end
    c.name = tostring(name)
    if t1 > t2 or t2 > t3 then
        error('t1<=t2<=t3 must be satisfied.')
    end
    c.t1 = int(t1) * 60
    c.t2 = int(t2) * 60
    c.t3 = int(t3) * 60
    c.hp = hp
    c.is_sc = (name ~= '')
    c.drop = drop
    c.is_extra = is_extra or false
    c.is_combat = true
    return c
end

---渲染符卡环
---@param self object @要渲染的对象
local extend_rate = 1 + 16 / 60
function boss.card.drawSpellCircle(self)
    local alpha = min(self.sc_ring_alpha or 144, 144)
    local exr1 = -0.5 --红外环半径偏移
    local bold = 2 --环粗偏移值，原环粗16
    local main_radius = 164 --卡环半径
    local timer, rov, cut, flag = self.timer, 4, 48, 1
    local pause = ext.pause_menu
    if pause and pause.IsKilled and pause:IsKilled() then
        pause = false
    end
    local ringx = self._sc_ring_x or self.x
    local ringy = self._sc_ring_y or self.y
    if not pause then
        local minspeed = self._sc_ring_minspeed or 0.5
        local ratespeed = self._sc_ring_ratespeed or 0.08
        local speed = Dist(ringx, ringy, self.x, self.y)
        local angle = Angle(ringx, ringy, self.x, self.y)
        speed = min(speed, max(speed * ratespeed, minspeed))
        ringx = ringx + speed * cos(angle)
        ringy = ringy + speed * sin(angle)
    end
    self._sc_ring_x = ringx
    self._sc_ring_y = ringy
    if not self.__is_waiting and self.__draw_sc_ring and self.t1 ~= self.t3 then
        for i = 1, 16 do
            SetImageState('bossring1' .. i, 'mul+add', Color(alpha, 255, 255, 255))
        end
        if timer < 90 then
            if self.fxr and self.fxg and self.fxb then
                local of = 1 - timer / 180
                for i = 1, 16 do
                    SetImageState('bossring2' .. i, 'mul+add',
                            Color(1.9 * alpha, self.fxr * of, self.fxg * of, self.fxb * of))
                end
            else
                for i = 1, 16 do
                    SetImageState('bossring2' .. i, 'mul+add',
                            Color(alpha, 255, 255, 255))
                end
            end
            misc.RenderRing('bossring1', ringx, ringy,
                    timer * (main_radius / 90) + main_radius * 1.5 * sin(timer * 2) + 14 + exr1 + bold,
                    timer * (main_radius / 90) + main_radius * 1.5 * sin(timer * 2) - 2 + exr1,
                    -self.ani * rov, cut, 16)
            misc.RenderRing('bossring2', ringx, ringy,
                    90 + ((main_radius - 90) / 90) * timer + 4,
                    -main_radius + (1 - cos(timer) ^ 2) * (main_radius * 2 - 12) - bold,
                    self.ani * rov, cut, 16)--white
        else
            if self.fxr and self.fxg and self.fxb then
                for i = 1, 16 do
                    SetImageState('bossring2' .. i, 'mul+add',
                            Color(1.9 * alpha, self.fxr / 2, self.fxg / 2, self.fxb / 2))
                end
            else
                for i = 1, 16 do
                    SetImageState('bossring2' .. i, 'mul+add',
                            Color(alpha, 255, 255, 255))
                end
            end
            local t = self.t3 * extend_rate --多给点收缩时间,符卡环最终半径不要为0
            misc.RenderRing('bossring1', ringx, ringy,
                    (t - timer * 1.08) / (t - 90) * main_radius + 14 + exr1 + bold,
                    (t - timer * 1.08) / (t - 90) * main_radius - 2 + exr1,
                    -self.ani * rov, cut, 16)
            misc.RenderRing('bossring2', ringx, ringy,
                    (t - timer) / (t - 90) * main_radius + 4,
                    (t - timer) / (t - 90) * main_radius - 12 - bold,
                    self.ani * rov, cut, 16)--white
        end
    end
end

--boss移动
boss.move = {}
---创建boss移动阶段
---@param x number @目标x坐标
---@param y number @目标y坐标
---@param t number @移动时长
---@param m number @移动模式
---@return boss.card
function boss.move.New(x, y, t, m)
    local c = {}
    c.frame = boss.move.frame
    c.render = boss.move.render
    c.init = boss.move.init
    c.del = boss.move.del
    c.name = ''
    c.t1 = 999999999
    c.t2 = 999999999
    c.t3 = 999999999
    c.hp = 999999999
    c.is_sc = false
    c.is_extra = false
    c.is_combat = false
    c.is_move = true
    c.x = x
    c.y = y
    c.t = t
    c.m = m
    return c
end
function boss.move:init()
    local c = boss.GetCurrentCard(self)
    task.New(self, function()
        task.MoveTo(c.x, c.y, c.t, c.m)
        Kill(self)
    end)
end
function boss.move:frame()
end
function boss.move:render()
end
function boss.move:del()
end

--boss逃跑
boss.escape = {}
---创建boss逃跑阶段（和移动没有区别）
---@param x number @目标x坐标
---@param y number @目标y坐标
---@param t number @移动时长
---@param m number @移动模式
---@return boss.card
function boss.escape.New(x, y, t, m)
    local c = {}
    c.frame = boss.escape.frame
    c.render = boss.escape.render
    c.init = boss.escape.init
    c.del = boss.escape.del
    c.name = ''
    c.t1 = 999999999
    c.t2 = 999999999
    c.t3 = 999999999
    c.hp = 999999999
    c.is_sc = false
    c.is_extra = false
    c.is_combat = false
    c.is_escape = true
    c.x = x
    c.y = y
    c.t = t
    c.m = m
    return c
end
function boss.escape:frame()
end
function boss.escape:render()
end
function boss.escape:init()
    local c = boss.GetCurrentCard(self)
    task.New(self, function()
        task.MoveTo(c.x, c.y, c.t, c.m)
        Kill(self)
    end)
end
function boss.escape:del()
end