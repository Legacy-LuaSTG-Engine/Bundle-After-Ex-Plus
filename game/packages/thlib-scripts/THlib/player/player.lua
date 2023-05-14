---=====================================
---player
---=====================================
player_lib = {}
local player_lib = player_lib

----------------------------------------
---加载资源
LoadPS("player_death_ef", "THlib/player/player_death_ef.psi", "parimg1")
LoadPS("graze", "THlib/player/graze.psi", "parimg6")
LoadImageFromFile("player_spell_mask", "THlib/player/spellmask.png")
Include("THlib/player/player_system.lua")

----------------------------------------
---player class
---@class player : lstg.GameObject
player_class = Class(object)
local player_class = player_class

player_lib.player_class = player_class

player_lib.debug_data = {
    --- 持续射击（用于测试游戏）
    keep_shooting = false,
    --- 开启无敌状态
    --invincible = false, -- 暂时先用 cheat
    --- [无敌时] 仍然启用碰撞检测
    invincible_enable_collider = true,
    --- [无敌时] 被击中后，投射粒子效果
    invincible_when_hit_fire_particles = true,
    --- [无敌时] 被击中后，播放经典死亡音效
    invincible_when_hit_play_sound_effect = true,
    --- [无敌时] 被击中后，消除子弹/敌人
    invincible_when_hit_delete_object = true,
}

function player_class:init(slot)
    self.group = GROUP_PLAYER
    self.layer = LAYER_PLAYER
    self.bound = false
    self.y = -176
    self._wisys = PlayerWalkImageSystem(self) --by OLC，自机行走图系统
    self._playersys = player_lib.system(self, slot) --by OLC，自机逻辑系统
    lstg.player = self
    player = self
    if not lstg.var.init_player_data then
        error("Player data has not been initialized. (Call function item.PlayerInit.)")
    end
end

function player_class:frame()
    self._playersys:doFrameBeforeEvent()
    self._playersys:frame()
    self._playersys:doFrameAfterEvent()
end

function player_class:render()
    self._playersys:doRenderBeforeEvent()
    self._playersys:render()
    self._playersys:doRenderAfterEvent()
end

function player_class:colli(other)
    self._playersys:doColliBeforeEvent(other)
    self._playersys:colli(other)
    self._playersys:doColliAfterEvent(other)
end

function player_class:findtarget()
    self.target = nil
    local maxpri = -1
    for i, o in ObjList(GROUP_ENEMY) do
        if o.colli then
            local dx = self.x - o.x
            local dy = self.y - o.y
            local pri = abs(dy) / (abs(dx) + 0.01)
            if pri > maxpri then
                maxpri = pri
                self.target = o
            end
        end
    end
    for i, o in ObjList(GROUP_NONTJT) do
        if o.colli then
            local dx = self.x - o.x
            local dy = self.y - o.y
            local pri = abs(dy) / (abs(dx) + 0.01)
            if pri > maxpri then
                maxpri = pri
                self.target = o
            end
        end
    end
end

function MixTable(x, t1, t2)
    --子机位置表的线性插值
    r = {}
    local y = 1 - x
    if t2 then
        for i = 1, #t1 do
            r[i] = y * t1[i] + x * t2[i]
        end
        return r
    else
        local n = int(#t1 / 2)
        for i = 1, n do
            r[i] = y * t1[i] + x * t1[i + n]
        end
        return r
    end
end

grazer = Class(object)

function grazer:init(player)
    self.layer = LAYER_ENEMY_BULLET_EF + 50
    self.group = GROUP_PLAYER
    self.player = player or lstg.player
    --self.player=lstg.player
    self.grazed = false
    self.img = "graze"
    ParticleStop(self)
    self.a = 24
    self.b = 24
    self.aura = 0
    self.aura_d = 0
    self.log_state = self.player.slow
    self._slowTimer = 0
    self._pause = 0
end

function grazer:frame()
    local p = self.player
    local alive = (p.death == 0 or p.death > 90)
    if alive then
        self.x = p.x
        self.y = p.y
        self.hide = p.hide
    end
    if not p.time_stop then
        if alive then
            if self.log_state ~= p.slow then
                self.log_state = p.slow
                self._pause = 30
            end
        end
        if p.slow == 1 then
            self._slowTimer = min(self._slowTimer + 1, 30)
        else
            self._slowTimer = 0
        end
        if self._pause == 0 then
            self.aura = self.aura + 1.5
        end
        self._pause = max(0, self._pause - 1)
        self.aura_d = 180 * cos(90 * self._slowTimer / 30) ^ 2
    end
    --
    if self.grazed then
        PlaySound("graze", 0.3, self.x / 200)
        self.grazed = false
        ParticleFire(self)
    else
        ParticleStop(self)
    end
end

function grazer:render()
    object.render(self)
    SetImageState("player_aura", "", Color(0xC0FFFFFF))
    Render("player_aura", self.x, self.y, -self.aura + self.aura_d, self.player.lh)
    SetImageState("player_aura", "", Color(0xC0FFFFFF) * self.player.lh + Color(0x00FFFFFF) * (1 - self.player.lh))
    Render("player_aura", self.x, self.y, self.aura, 2 - self.player.lh)
end

function grazer:colli(other)
    if other.group ~= GROUP_ENEMY and (not (other._graze) or other._inf_graze) then
        item.PlayerGraze()
        self.grazed = true
        if not (other._inf_graze) then
            other._graze = true
        end
    end
end

death_weapon = Class(object)

function death_weapon:init(x, y)
    self.x = x
    self.y = y
    self.group = GROUP_GHOST
    self.hide = true
end

function death_weapon:frame()
    if self.timer >= 90 then
        Del(self)
    end
    for i, o in ObjList(GROUP_ENEMY) do
        if o.colli == true then
            if Dist(self, o) < 800 and self.timer > 60 then
                Damage(o, 0.75)
                if o.dmgsound == 1 then
                    if o.dmg_factor then
                        if o.hp > 100 then
                            PlaySound('damage00', 0.3, o.x / 200)
                        else
                            PlaySound('damage01', 0.6, o.x / 200)
                        end
                    else
                        if o.hp > o.maxhp * 0.2 then
                            PlaySound('damage00', 0.3, o.x / 200)
                        else
                            PlaySound('damage01', 0.8, o.x / 200)
                        end
                    end
                end
            end
        end
    end
    for i, o in ObjList(GROUP_NONTJT) do
        if o.colli == true then
            if Dist(self, o) < 800 and self.timer > 60 then
                Damage(o, 0.75)
                if o.dmgsound == 1 then
                    if o.dmg_factor then
                        if o.hp > 100 then
                            PlaySound('damage00', 0.3, o.x / 200)
                        else
                            PlaySound('damage01', 0.6, o.x / 200)
                        end
                    else
                        if o.hp > o.maxhp * 0.2 then
                            PlaySound('damage00', 0.3, o.x / 200)
                        else
                            PlaySound('damage01', 0.8, o.x / 200)
                        end
                    end
                end
            end
        end
    end
end

----------------------------------------
---一些自机组件

player_bullet_straight = Class(object)

function player_bullet_straight:init(img, x, y, v, angle, dmg)
    self.group = GROUP_PLAYER_BULLET
    self.layer = LAYER_PLAYER_BULLET
    self.img = img
    self.x = x
    self.y = y
    self.rot = angle
    self.vx = v * cos(angle)
    self.vy = v * sin(angle)
    self.dmg = dmg
    if self.a ~= self.b then
        self.rect = true
    end
end

player_bullet_hide = Class(object)

function player_bullet_hide:init(a, b, x, y, v, angle, dmg, delay)
    self.group = GROUP_PLAYER_BULLET
    self.layer = LAYER_PLAYER_BULLET
    self.colli = false
    self.a = a
    self.b = b
    self.x = x
    self.y = y
    self.rot = angle
    self.vx = v * cos(angle)
    self.vy = v * sin(angle)
    self.dmg = dmg
    self.delay = delay or 0
end

function player_bullet_hide:frame()
    if self.timer == self.delay then
        self.colli = true
    end
end

player_bullet_trail = Class(object)

function player_bullet_trail:init(img, x, y, v, angle, target, trail, dmg)
    self.group = GROUP_PLAYER_BULLET
    self.layer = LAYER_PLAYER_BULLET
    self.img = img
    self.x = x
    self.y = y
    self.rot = angle
    self.v = v
    self.target = target
    self.trail = trail
    self.dmg = dmg
end

function player_bullet_trail:frame()
    if IsValid(self.target) and self.target.colli then
        local a = math.mod(Angle(self, self.target) - self.rot + 720, 360)
        if a > 180 then
            a = a - 360
        end
        local da = self.trail / (Dist(self, self.target) + 1)
        if da >= abs(a) then
            self.rot = Angle(self, self.target)
        else
            self.rot = self.rot + sign(a) * da
        end
    end
    self.vx = self.v * cos(self.rot)
    self.vy = self.v * sin(self.rot)
end

player_spell_mask = Class(object)

function player_spell_mask:init(r, g, b, t1, t2, t3)
    self.x = 0
    self.y = 0
    self.group = GROUP_GHOST
    self.layer = LAYER_BG + 1
    self.img = "player_spell_mask"
    self.bcolor = { ["blend"] = "mul+add", ["a"] = 0, ["r"] = r, ["g"] = g, ["b"] = b }
    task.New(self, function()
        for i = 1, t1 do
            self.bcolor.a = i * 255 / t1
            task.Wait(1)
        end
        task.Wait(t2)
        for i = t3, 1, -1 do
            self.bcolor.a = i * 255 / t3
            task.Wait(1)
        end
        Del(self)
    end)
end

function player_spell_mask:frame()
    task.Do(self)
end

function player_spell_mask:render()
    local w = lstg.world
    local c = self.bcolor
    SetImageState(self.img, c.blend, Color(c.a, c.r, c.g, c.b))
    RenderRect(self.img, w.l, w.r, w.b, w.t)
end

player_death_ef = Class(object)

function player_death_ef:init(x, y)
    self.x = x
    self.y = y
    self.img = "player_death_ef"
    self.layer = LAYER_PLAYER + 50
end

function player_death_ef:frame()
    if self.timer == 4 then
        ParticleStop(self)
    end
    if self.timer == 60 then
        Del(self)
    end
end

deatheff = Class(object)

function deatheff:init(x, y, type_)
    self.x = x
    self.y = y
    self.type = type_
    self.size = 0
    self.size1 = 0
    self.layer = LAYER_TOP - 1
    task.New(self, function()
        local size = 0
        local size1 = 0
        if self.type == "second" then
            task.Wait(30)
        end
        for i = 1, 360 do
            self.size = size
            self.size1 = size1
            size = size + 12
            size1 = size1 + 8
            task.Wait(1)
        end
    end)
end

function deatheff:frame()
    task.Do(self)
    if self.timer > 180 then
        Del(self)
    end
end

function deatheff:render()
    --稍微减少了死亡反色圈的分割数，视觉效果基本不变，减少性能消耗（原分割数为180）
    if self.type == "first" then
        rendercircle(self.x, self.y, self.size, 60)
        rendercircle(self.x + 35, self.y + 35, self.size1, 60)
        rendercircle(self.x + 35, self.y - 35, self.size1, 60)
        rendercircle(self.x - 35, self.y + 35, self.size1, 60)
        rendercircle(self.x - 35, self.y - 35, self.size1, 60)
    elseif self.type == "second" then
        rendercircle(self.x, self.y, self.size, 60)
    end
end

----------------------------------------
---加载自机

local PLAYER_PATH = "Library/players/"    --自机插件路径
local ENTRY_POINT_SCRIPT_PATH = ""          --入口点文件路径
local ENTRY_POINT_SCRIPT = "__init__.lua"   --入口点文件

---检查目录是否存在，不存在则创建
local function check_directory()
    lstg.FileManager.CreateDirectory(PLAYER_PATH)
end

---检查一个自机插件包是否合法（有入口点文件）
---该函数会装载自机插件包，然后进行检查，如果不是合法的自机插件包，将会卸载掉
---@param player_plugin_path string @插件包路径
---@return boolean
local function LoadAndCheckValidity(player_plugin_path)
    lstg.LoadPack(player_plugin_path)
    local fs = lstg.FindFiles("", "lua", player_plugin_path)
    for _, v in pairs(fs) do
        local filename = string.sub(v[1], string.len(ENTRY_POINT_SCRIPT_PATH) + 1, -1)
        if filename == ENTRY_POINT_SCRIPT then
            return true
        end
    end
    lstg.UnloadPack(player_plugin_path)
    lstg.Log(4, "\"" .. player_plugin_path .. "\"不是有效的自机插件包，没有入口点文件\"" .. ENTRY_POINT_SCRIPT .. "\"")
    return false
end

---储存自机的信息表
---@type table @{{displayname,classname,replayname}, ... }
player_list = {}

---对自机表进行排序
local function PlayerListSort()
    local playerDisplayName = {}--{displayname, ... }
    local pl2id = {}--{[displayname]=player_list_pos, ... }
    for i, v in ipairs(player_list) do
        table.insert(playerDisplayName, v[1])
        pl2id[v[1]] = i
    end
    table.sort(playerDisplayName)
    local id2pl = {}--{[pos]=player_list_pos}
    for i, v in ipairs(playerDisplayName) do
        id2pl[i] = pl2id[v]
    end
    local tmp_player_list = {}
    for i, v in ipairs(id2pl) do
        tmp_player_list[i] = player_list[v]
    end
    player_list = tmp_player_list
end

---添加自机信息到自机信息表
---@param displayname string @显示在菜单中的名字
---@param classname string @全局中的自机类名
---@param replayname string @显示在rep信息中的名字
---@param pos number @插入的位置
---@param _replace boolean @是否取代该位置
function AddPlayerToPlayerList(displayname, classname, replayname, pos, _replace)
    if _replace then
        player_list[pos] = { displayname, classname, replayname }
    elseif pos then
        table.insert(player_list, pos, { displayname, classname, replayname })
    else
        table.insert(player_list, { displayname, classname, replayname })
    end
end

---加载自机包【废弃】
local function LoadPlayerPacks()
    player_list = {}--先清空一次

    check_directory()
    local fs = lstg.FindFiles(PLAYER_PATH, "zip", "")--罗列插件包
    for _, v in pairs(fs) do
        --尝试加载插件包并检查插件包合法性
        local result = LoadAndCheckValidity(v[1])
        --加载入口点脚本
        if result then
            lstg.DoFile(ENTRY_POINT_SCRIPT, v[1])
        end
    end

    PlayerListSort()
end
