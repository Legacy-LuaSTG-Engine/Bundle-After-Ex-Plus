local player_lib = player_lib
---@class player.system
---@return player.system
player_lib.system = plus.Class()

local defaultKeys = {
    "up", "down", "left", "right",
    "slow", "shoot", "spell", "special",
}
player_lib.defaultKeys = defaultKeys

local defaultKeyEvent = {
    { "up", "down", "key.up.down", 0, function(self)
        self.__up_flag = true
    end },
    { "up", "up", "key.up.up", 0, function(self)
        self.__up_flag = false
    end },
    { "down", "down", "key.down.down", 0, function(self)
        self.__down_flag = true
    end },
    { "down", "up", "key.down.up", 0, function(self)
        self.__down_flag = false
    end },
    { "left", "down", "key.left.down", 0, function(self)
        self.__left_flag = true
    end },
    { "left", "up", "key.left.up", 0, function(self)
        self.__left_flag = false
    end },
    { "right", "down", "key.right.down", 0, function(self)
        self.__right_flag = true
    end },
    { "right", "up", "key.right.up", 0, function(self)
        self.__right_flag = false
    end },
    { "slow", "down", "key.slow.down", 0, function(self)
        self.__slow_flag = true
    end },
    { "slow", "up", "key.slow.up", 0, function(self)
        self.__slow_flag = false
    end },
    { "shoot", "down", "key.shoot.down", 0, function(self)
        self.__shoot_flag = true
    end },
    { "shoot", "up", "key.shoot.up", 0, function(self)
        self.__shoot_flag = false
    end },
    { "spell", "down", "key.spell.down", 0, function(self)
        self.__spell_flag = true
    end },
    { "spell", "up", "key.spell.up", 0, function(self)
        self.__spell_flag = false
    end },
    { "special", "down", "key.special.down", 0, function(self)
        self.__special_flag = true
    end },
    { "special", "up", "key.special.up", 0, function(self)
        self.__special_flag = false
    end },
}
player_lib.defaultKeyEvent = defaultKeyEvent

local defaultFrameEvent = {
    ["frame.updateDeathState"] = { 100, function(self)
        if (self.death == 0 or self.death > 90) and (not self.lock) and not (self.time_stop) then
            self.__death_state = 0
        elseif self.death == 90 then
            self.__death_state = 1
        elseif self.death == 84 then
            self.__death_state = 2
        elseif self.death == 50 then
            self.__death_state = 3
        elseif self.death < 50 and not (self.lock) and not (self.time_stop) then
            self.__death_state = 4
        else
            self.__death_state = -1
        end
    end },
    ["frame.updateSlow"] = { 99, function(self)
        if self.__death_state == 0 then
            if self.__slow_flag then
                self.slow = 1
            else
                self.slow = 0
            end
        end
    end },
    ["frame.control"] = { 98, function(self, system)
        if self.__death_state == 0 then
            if not self.dialog then
                if (self.__shoot_flag or player_lib.debug_data.keep_shooting) and self.nextshoot <= 0 then
                    system:shoot()
                end
                if self.__spell_flag and self.nextspell <= 0 and lstg.var.bomb > 0 and not lstg.var.block_spell then
                    system:spell()
                end
                if self.__special_flag and self.nextsp <= 0 then
                    system:special()
                end
            else
                self.nextshoot = 15
                self.nextspell = 30
            end
        end
    end },
    ["frame.move"] = { 97, function(self)
        local dx, dy, v = 0, 0, self.hspeed
        if self.__death_state == 0 then
            if self.death == 0 and not self.lock then
                if self.slowlock then
                    self.slow = 1
                end
                if self.slow == 1 then
                    v = self.lspeed
                end
                if self.__up_flag then
                    dy = dy + 1
                end
                if self.__down_flag then
                    dy = dy - 1
                end
                if self.__left_flag then
                    dx = dx - 1
                end
                if self.__right_flag then
                    dx = dx + 1
                end
                if dx * dy ~= 0 then
                    v = v * SQRT2_2
                end
                dx = v * dx
                dy = v * dy
                self.x = self.x + dx
                self.y = self.y + dy
                self.x = math.max(math.min(self.x, lstg.world.pr - 8), lstg.world.pl + 8)
                self.y = math.max(math.min(self.y, lstg.world.pt - 32), lstg.world.pb + 16)
            end
        end
        self.__move_dx = dx
        self.__move_dy = dy
    end },
    ["frame.fire"] = { 96, function(self)
        if self.__death_state == 0 then
            if self.__shoot_flag and not self.dialog then
                self.fire = self.fire + 0.16
            else
                self.fire = self.fire - 0.16
            end
            if self.fire < 0 then
                self.fire = 0
            end
            if self.fire > 1 then
                self.fire = 1
            end
        end
    end },
    ["frame.itemCollect"] = { 95, function(self)
        if self.__death_state == 0 then
            if self.y > self.collect_line then
                for _, o in ObjList(GROUP_ITEM) do
                    local flag = false
                    if o.attract < 8 then
                        flag = true
                    elseif o.attract == 8 and o.target ~= self then
                        if (not o.target) or o.target.y < self.y then
                            flag = true
                        end
                    end
                    if flag then
                        o.attract = 8
                        o.num = self.item
                        o.target = self
                    end
                end
            else
                if self.__slow_flag then
                    for _, o in ObjList(GROUP_ITEM) do
                        if Dist(self, o) < 48 then
                            if o.attract < 3 then
                                o.attract = max(o.attract, 3)
                                o.target = self
                            end
                        end
                    end
                else
                    for _, o in ObjList(GROUP_ITEM) do
                        if Dist(self, o) < 24 then
                            if o.attract < 3 then
                                o.attract = max(o.attract, 3)
                                o.target = self
                            end
                        end
                    end
                end
            end
        end
    end },
    ["frame.death1"] = { 94, function(self)
        if self.__death_state == 1 then
            if self.time_stop then
                self.death = self.death - 1
            end
            item.PlayerMiss(self)
            New(death_weapon, self.x, self.y)
            self.deathee = {}
            self.deathee[1] = New(deatheff, self.x, self.y, "first")
            self.deathee[2] = New(deatheff, self.x, self.y, "second")
            New(player_death_ef, self.x, self.y)
        end
    end },
    ["frame.death2"] = { 93, function(self)
        if self.__death_state == 2 then
            if self.time_stop then
                self.death = self.death - 1
            end
            self.hide = true
        end
    end },
    ["frame.death3"] = { 92, function(self)
        if self.__death_state == 3 then
            if self.time_stop then
                self.death = self.death - 1
            end
            self.x = 0
            self.supportx = 0
            self.y = -236
            self.supporty = -236
            self.hide = false
            New(bullet_deleter, self.x, self.y)
        end
    end },
    ["frame.death4"] = { 91, function(self)
        if self.__death_state == 4 then
            self.y = -192 - (1.2 * (self.death - 1))
        end
    end },
    ["frame.updateVar"] = { 90, function(self)
        self.lh = self.lh + (self.slow - 0.5) * 0.3
        if self.lh < 0 then
            self.lh = 0
        end
        if self.lh > 1 then
            self.lh = 1
        end
        if self.nextshoot > 0 then
            self.nextshoot = self.nextshoot - 1
        end
        if self.nextspell > 0 then
            self.nextspell = self.nextspell - 1
        end
        if self.nextsp > 0 then
            self.nextsp = self.nextsp - 1
        end
        if self.support > int(lstg.var.power / 100) then
            self.support = self.support - 0.0625
        elseif self.support < int(lstg.var.power / 100) then
            self.support = self.support + 0.0625
        end
        if abs(self.support - int(lstg.var.power / 100)) < 0.0625 then
            self.support = int(lstg.var.power / 100)
        end
        self.supportx = self.x + (self.supportx - self.x) * 0.6875
        self.supporty = self.y + (self.supporty - self.y) * 0.6875
        if self.protect > 0 then
            self.protect = self.protect - 1
        end
        if self.death > 0 then
            self.death = self.death - 1
        end
        lstg.var.pointrate = item.PointRateFunc(lstg.var)
    end },
    ["frame.updateSupport"] = { 89, function(self)
        if not (self.time_stop) then
            if self.slist then
                self.sp = {}
                if self.support == 5 then
                    for i = 1, 4 do
                        self.sp[i] = MixTable(self.lh, self.slist[6][i])
                        self.sp[i][3] = 1
                    end
                else
                    local s = int(self.support) + 1
                    local t = self.support - int(self.support)
                    for i = 1, 4 do
                        if self.slist[s][i] and self.slist[s + 1][i] then
                            self.sp[i] = MixTable(t, MixTable(self.lh, self.slist[s][i]),
                                    MixTable(self.lh, self.slist[s + 1][i]))
                            self.sp[i][3] = 1
                        elseif self.slist[s + 1][i] then
                            self.sp[i] = MixTable(self.lh, self.slist[s + 1][i])
                            self.sp[i][3] = t
                        end
                    end
                end
            end
        end
    end },
    ["frame.timeStop"] = { 88, function(self)
        if self.time_stop then
            self.timer = self.timer - 1
        end
    end },
}
player_lib.defaultFrameEvent = defaultFrameEvent

local system = player_lib.system
function system:init(p, slot)
    self.player = p
    p.supportx = p.supportx or 0
    p.supporty = p.supporty or p.y
    p.hspeed = p.hspeed or 4
    p.lspeed = p.lspeed or 2
    p.collect_line = p.collect_line or 96
    p.slow = p.slow or 0
    p.A = p.A or 0
    p.B = p.B or 0
    p.lh = p.lh or 0
    p.fire = p.fire or 0
    p.lock = p.lock or false
    p.dialog = p.dialog or false
    p.nextshoot = p.nextshoot or 0
    p.nextspell = p.nextspell or 0
    p.nextsp = p.nextsp or 0
    p.item = p.item or 1
    p.death = p.death or 0
    p.protect = p.protect or 120
    p.grazer = p.grazer or New(grazer, p)
    p.support = p.support or int(lstg.var.power / 100)
    p.sp = p.sp or {}
    p.time_stop = p.time_stop or false
    p.slot = slot
    p.__death_state = 0 --自机状态
    p.__move_dx = 0 --本帧操作移动x距离
    p.__move_dy = 0 --本帧操作移动y距离
    self.listener = eventListener()
    self._keys = {}
    self._keys_remove = {}
    self.keyState = {}
    self.keyStatePre = {}
    for _, key in ipairs(defaultKeys) do
        self:regKeys(key)
    end
    for _, event in ipairs(defaultKeyEvent) do
        self:addKeyEvent(unpack(event))
    end
    for name, event in pairs(defaultFrameEvent) do
        self:addFrameEvent(name, unpack(event))
    end
end

---帧逻辑事件
function system:frame()
    local p = self.player
    p.grazer.world = p.world
    self:updateKeyState() --更新自机按键状态（之后应改为外部调用）
    self:findTarget() --更新target目标
    self:doFrameEvent() --执行帧逻辑事件
    if not (p._wisys) then
        p._wisys = PlayerWalkImageSystem(p)
    end
    if not p.time_stop then
        p._wisys:frame(p.__move_dx)
    end
end

---渲染事件
function system:render()
    local p = self.player
    p._wisys:render()--by OLC，自机行走图系统
end

---Shoot事件
function system:shoot()
    local p = self.player
    if p.class.shoot then
        p.class.shoot(p)
    end
end

---Spell事件
function system:spell()
    local p = self.player
    item.PlayerSpell()
    lstg.var.bomb = lstg.var.bomb - 1
    if p.class.spell then
        p.class.spell(p)
    end
    p.death = 0
    p.nextcollect = 90
end

---Special事件
function system:special()
    local p = self.player
    if p.class.special then
        p.class.special(p)
    end
end

---碰撞回调事件
function system:colli(other)
    local p = self.player
    if not cheat then
        if p.death == 0 and not p.dialog then
            if p.protect == 0 then
                PlaySound("pldead00", 0.5)
                p.death = 100
            end
            if other.group == GROUP_ENEMY_BULLET then
                Del(other)
            end
        end
    else
        local t = player_lib.debug_data
        if t.invincible_enable_collider then
            if p.death == 0 and not p.dialog then
                if p.protect == 0 then
                    if t.invincible_when_hit_play_sound_effect then
                        PlaySound("pldead00", 0.5)
                    end
                    if t.invincible_when_hit_fire_particles then
                        New(player_death_ef, p.x, p.y)
                    end
                end
                if other.group == GROUP_ENEMY_BULLET then
                    if t.invincible_when_hit_delete_object then
                        Del(other)
                    end
                end
            end
        end
    end
end

---更新target目标
function system:findTarget()
    local p = self.player
    if ((not IsValid(p.target)) or (not p.target.colli)) then
        player_class.findtarget(p)
    end
    if not self:keyIsDown("shoot") then
        p.target = nil
    end
end

---注册一个按键
---@param key string @目标按键标识名
function system:regKeys(key)
    self._keys[key] = true
    self._keys_remove[key] = nil
end

---解除注册一个按键
---@param key string @目标按键标识名
function system:unregKeys(key)
    if self._keys[key] then
        self._keys_remove[key] = true
        self._keys[key] = nil
    end
end

---更新自机按键状态
function system:updateKeyState()
    local p = self.player
    local keyState = p.key or KeyState
    for key in pairs(self._keys) do
        --更新已注册按键状态并执行事件组
        self.keyStatePre[key] = self.keyState[key]
        self.keyState[key] = keyState[key] or false
        if self.keyState[key] then
            if self.keyStatePre[key] then
                self:doKeyEvent(key, "hold") --保持按住
            else
                self:doKeyEvent(key, "press") --按下
            end
            self:doKeyEvent(key, "down") --按住（包括按下）
        else
            if self.keyStatePre[key] then
                self:doKeyEvent(key, "release") --抬起
            else
                self:doKeyEvent(key, "none") --保持抬起
            end
            self:doKeyEvent(key, "up") --保持抬起（包括抬起）
        end
    end
    for key in pairs(self._keys_remove) do
        --移除解除注册的按键并执行应有的事件组
        if self.keyState[key] then
            self:doKeyEvent(key, "release") --抬起
            self:doKeyEvent(key, "up") --保持抬起（包括抬起）
        end
        self.keyStatePre[key] = nil
        self.keyState[key] = nil
        self._keys_remove[key] = nil
    end
end

---获取自身注册按键是否按下
---@param key string @目标按键标识名
---@return boolean
function system:keyIsDown(key)
    if self._keys[key] or self._keys_remove[key] then
        return self.keyState[key]
    end
end

---获取自身注册按键是否在当前帧按下
---@param key string @目标按键标识名
---@return boolean
function system:keyIsPressed(key)
    if self._keys[key] then
        return self.keyState[key] and not self.keyStatePre[key]
    end
end

---添加按键事件
---@param key string @目标按键标识名
---@param state string @目标按键事件
---@param eventName string @按键事件名
---@param eventLevel number @按键事件优先度
---@param eventFunc function @按键事件函数
---@return boolean @是否发生覆盖
function system:addKeyEvent(key, state, eventName, eventLevel, eventFunc)
    local event = string.format("keyEvent@%s@%s", key, state)
    return self.listener:addEvent(event, eventName, eventLevel, eventFunc)
end

---移除按键事件
---@param key string @目标按键标识名
---@param state string @目标按键事件
---@param eventName string @按键事件名
function system:removeKeyEvent(key, state, eventName)
    local event = string.format("keyEvent@%s@%s", key, state)
    self.listener:remove(event, eventName)
end

---执行按键事件
---@param key string @目标按键标识名
---@param state string @目标按键事件
function system:doKeyEvent(key, state)
    local p = self.player
    local event = string.format("keyEvent@%s@%s", key, state)
    self.listener:Do(event, p, self)
end

---添加帧逻辑事件（前）
---@param eventName string @事件名
---@param eventLevel number @事件优先度
---@param eventFunc function @事件函数
---@return boolean @是否发生覆盖
function system:addFrameBeforeEvent(eventName, eventLevel, eventFunc)
    return self.listener:addEvent("frameEvent@before", eventName, eventLevel, eventFunc)
end

---移除帧逻辑事件（前）
---@param eventName string @事件名
function system:removeFrameBeforeEvent(eventName)
    self.listener:remove("frameEvent@before", eventName)
end

---执行帧逻辑事件（前）
function system:doFrameBeforeEvent()
    local p = self.player
    self.listener:Do("frameEvent@before", p, self)
end

---添加帧逻辑事件
---@param eventName string @事件名
---@param eventLevel number @事件优先度
---@param eventFunc function @事件函数
---@return boolean @是否发生覆盖
function system:addFrameEvent(eventName, eventLevel, eventFunc)
    return self.listener:addEvent("frameEvent@frame", eventName, eventLevel, eventFunc)
end

---移除帧逻辑事件
---@param eventName string @事件名
function system:removeFrameEvent(eventName)
    self.listener:remove("frameEvent@frame", eventName)
end

---执行帧逻辑事件
function system:doFrameEvent()
    local p = self.player
    self.listener:Do("frameEvent@frame", p, self)
end

---添加帧逻辑事件（后）
---@param eventName string @事件名
---@param eventLevel number @事件优先度
---@param eventFunc function @事件函数
---@return boolean @是否发生覆盖
function system:addFrameAfterEvent(eventName, eventLevel, eventFunc)
    return self.listener:addEvent("frameEvent@after", eventName, eventLevel, eventFunc)
end

---移除帧逻辑事件（后）
---@param eventName string @事件名
function system:removeFrameAfterEvent(eventName)
    self.listener:remove("frameEvent@after", eventName)
end

---执行帧逻辑事件（后）
function system:doFrameAfterEvent()
    local p = self.player
    self.listener:Do("frameEvent@after", p, self)
end

---添加渲染逻辑事件（前）
---@param eventName string @事件名
---@param eventLevel number @事件优先度
---@param eventFunc function @事件函数
---@return boolean @是否发生覆盖
function system:addRenderBeforeEvent(eventName, eventLevel, eventFunc)
    return self.listener:addEvent("renderEvent@before", eventName, eventLevel, eventFunc)
end

---移除渲染逻辑事件（前）
---@param eventName string @事件名
function system:removeRenderBeforeEvent(eventName)
    self.listener:remove("renderEvent@before", eventName)
end

---执行渲染逻辑事件（前）
function system:doRenderBeforeEvent()
    local p = self.player
    self.listener:Do("renderEvent@before", p, self)
end

---添加渲染逻辑事件（后）
---@param eventName string @事件名
---@param eventLevel number @事件优先度
---@param eventFunc function @事件函数
---@return boolean @是否发生覆盖
function system:addRenderAfterEvent(eventName, eventLevel, eventFunc)
    return self.listener:addEvent("renderEvent@after", eventName, eventLevel, eventFunc)
end

---移除渲染逻辑事件（后）
---@param eventName string @事件名
function system:removeRenderAfterEvent(eventName)
    self.listener:remove("renderEvent@after", eventName)
end

---执行渲染逻辑事件（后）
function system:doRenderAfterEvent()
    local p = self.player
    self.listener:Do("renderEvent@after", p, self)
end

---添加碰撞逻辑事件（前）
---@param eventName string @事件名
---@param eventLevel number @事件优先度
---@param eventFunc function @事件函数
---@return boolean @是否发生覆盖
function system:addColliBeforeEvent(eventName, eventLevel, eventFunc)
    return self.listener:addEvent("colliEvent@before", eventName, eventLevel, eventFunc)
end

---移除碰撞逻辑事件（前）
---@param eventName string @事件名
function system:removeColliBeforeEvent(eventName)
    self.listener:remove("colliEvent@before", eventName)
end

---执行碰撞逻辑事件（前）
function system:doColliBeforeEvent(other)
    local p = self.player
    self.listener:Do("colliEvent@before", p, self, other)
end

---添加碰撞逻辑事件（后）
---@param eventName string @事件名
---@param eventLevel number @事件优先度
---@param eventFunc function @事件函数
---@return boolean @是否发生覆盖
function system:addColliAfterEvent(eventName, eventLevel, eventFunc)
    return self.listener:addEvent("colliEvent@after", eventName, eventLevel, eventFunc)
end

---移除碰撞逻辑事件（后）
---@param eventName string @事件名
function system:removeColliAfterEvent(eventName)
    self.listener:remove("colliEvent@after", eventName)
end

---执行碰撞逻辑事件（后）
function system:doColliAfterEvent(other)
    local p = self.player
    self.listener:Do("colliEvent@after", p, self, other)
end