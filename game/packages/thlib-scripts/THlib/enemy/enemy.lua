LoadTexture('enemy1', 'THlib/enemy/enemy1.png')
LoadImageGroup('enemy1_', 'enemy1', 0, 384, 32, 32, 12, 1, 8, 8)
LoadImageGroup('enemy2_', 'enemy1', 0, 416, 32, 32, 12, 1, 8, 8)
LoadImageGroup('enemy3_', 'enemy1', 0, 448, 32, 32, 12, 1, 8, 8)
LoadImageGroup('enemy4_', 'enemy1', 0, 480, 32, 32, 12, 1, 8, 8)
LoadImageGroup('enemy5_', 'enemy1', 0, 0, 48, 32, 4, 3, 8, 8)
LoadImageGroup('enemy6_', 'enemy1', 0, 96, 48, 32, 4, 3, 8, 8)
LoadImageGroup('enemy7_', 'enemy1', 320, 0, 48, 48, 4, 3, 16, 16)
LoadImageGroup('enemy8_', 'enemy1', 320, 144, 48, 48, 4, 3, 16, 16)
LoadImageGroup('enemy9_', 'enemy1', 0, 192, 64, 64, 4, 3, 16, 16)
LoadImageGroup('kedama', 'enemy1', 256, 320, 32, 32, 2, 2, 8, 8)
LoadImageGroup('enemy_x', 'enemy1', 192, 32, 32, 32, 4, 1, 8, 8)
LoadImageGroup('enemy_orb', 'enemy1', 192, 64, 32, 32, 4, 1, 8, 8)
LoadImageGroup('enemy_orb_ring', 'enemy1', 192, 96, 32, 32, 4, 1)
for i = 1, 4 do
    SetImageState('enemy_orb_ring' .. i, 'add+add', Color(0xFF404040))
end
LoadImageGroup('enemy_aura', 'enemy1', 192, 32, 32, 32, 4, 1)
for i = 1, 4 do
    SetImageState('enemy_aura' .. i, '', Color(0x80FFFFFF))
end

LoadTexture('enemy2', 'THlib/enemy/enemy2.png')
LoadImageGroup('enemy10_', 'enemy2', 0, 0, 32, 32, 12, 1, 8, 8)
LoadImageGroup('enemy11_', 'enemy2', 0, 32, 32, 32, 12, 1, 8, 8)
LoadImageGroup('enemy12_', 'enemy2', 0, 64, 32, 32, 12, 1, 8, 8)
LoadImageGroup('enemy13_', 'enemy2', 0, 96, 32, 32, 12, 1, 8, 8)
LoadImageGroup('enemy14_', 'enemy2', 0, 128, 64, 64, 6, 2, 16, 16)
LoadImageGroup('enemy15_', 'enemy2', 0, 288, 32, 32, 12, 1, 8, 8)
LoadImageGroup('enemy16_', 'enemy2', 0, 352, 32, 32, 12, 1, 8, 8)
LoadImageGroup('enemy17_', 'enemy2', 0, 416, 32, 32, 12, 1, 8, 8)
LoadImageGroup('enemy18_', 'enemy2', 0, 480, 32, 32, 12, 1, 8, 8)
LoadPS('ghost_fire_r', 'THlib/enemy/ghost_fire_r.psi', 'parimg1', 8, 8)
LoadPS('ghost_fire_b', 'THlib/enemy/ghost_fire_b.psi', 'parimg1', 8, 8)
LoadPS('ghost_fire_g', 'THlib/enemy/ghost_fire_g.psi', 'parimg1', 8, 8)
LoadPS('ghost_fire_y', 'THlib/enemy/ghost_fire_y.psi', 'parimg1', 8, 8)

LoadTexture('enemy3', 'THlib/enemy/enemy3.png')
LoadImageGroup('Ghost1', 'enemy3', 0, 0, 32, 32, 8, 1, 8, 8)
LoadImageGroup('Ghost3', 'enemy3', 0, 32, 32, 32, 8, 1, 8, 8)
LoadImageGroup('Ghost2', 'enemy3', 0, 64, 32, 32, 8, 1, 8, 8)
LoadImageGroup('Ghost4', 'enemy3', 0, 96, 32, 32, 8, 1, 8, 8)

enemybase = Class(object)

function enemybase:init(hp, nontaijutsu)
    self.layer = LAYER_ENEMY
    self.group = GROUP_ENEMY
    if nontaijutsu then
        self.group = GROUP_NONTJT
    end
    self.bound = false
    self.colli = false
    self.maxhp = hp or 1
    self.hp = hp or 1
    setmetatable(self, { __index = GetAttr, __newindex = enemy_meta_newindex })
    self.colli = true
    self._servants = {}
end

function enemy_meta_newindex(t, k, v)
    if k == 'colli' then
        rawset(t, '_colli', v)
    else
        SetAttr(t, k, v)
    end
end

function enemybase:frame()
    SetAttr(self, 'colli', BoxCheck(self, lstg.world.boundl, lstg.world.boundr, lstg.world.boundb, lstg.world.boundt) and self._colli)
    if self.hp <= 0 then
        Kill(self)
    end
    task.Do(self)
end

function enemybase:colli(other)
    if other.dmg then
        lstg.var.score = lstg.var.score + 10
        local dmg = other.dmg
        Damage(self, dmg)
        if self._master and self._dmg_transfer and IsValid(self._master) then
            Damage(self._master, dmg * self._dmg_transfer)
        end
    end
    other.killerenemy = self
    if not (other.killflag) then
        Kill(other)
    end
    if not other.mute then
        if self.dmg_factor then
            if self.hp > 100 then
                PlaySound('damage00', 0.4, self.x / 200)
            else
                PlaySound('damage01', 0.6, self.x / 200)
            end
        else
            if self.hp > 60 then
                if self.hp > self.maxhp * 0.2 then
                    PlaySound('damage00', 0.4, self.x / 200)
                else
                    PlaySound('damage01', 0.6, self.x / 200)
                end
            else
                PlaySound('damage00', 0.35, self.x / 200, true)
            end
        end
    end
end

function enemybase:del()
    _del_servants(self)
end

function Damage(obj, dmg)
    if obj.class.base.take_damage then
        obj.class.base.take_damage(obj, dmg)
    end
end

enemy = Class(enemybase)

_enemy_aura_tb = { 1, 2, 3, 4, 3, 1, nil, nil, nil, 3, 1, 4, 1, nil, 3, 1, 2, 4, 3, 1, 2, 4, 1, 2, 3, 4, nil, nil, nil, nil, 1, 3, 2, 1 }
_death_ef_tb = { 1, 2, 3, 4, 3, 1, 1, 2, 1, 3, 1, 4, 1, 1, 3, 1, 2, 4, 3, 1, 2, 4, 1, 2, 3, 4, 1, 3, 2, 4, 1, 3, 2, 4 }

function enemy:init(style, hp, clear_bullet, auto_delete, nontaijutsu)
    enemybase.init(self, hp, nontaijutsu)
    self.clear_bullet = clear_bullet
    self.auto_delete = auto_delete
    self._wisys = EnemyWalkImageSystem(self, style, 8)--by OLC，新行走图系统
end

function enemy:frame()
    enemybase.frame(self)
    self._wisys:frame()--by OLC，新行走图系统
    if self.dmgt then
        self.dmgt = max(0, self.dmgt - 1)
    end
    if self.auto_delete and BoxCheck(self, lstg.world.boundl, lstg.world.boundr, lstg.world.boundb, lstg.world.boundt) then
        self.bound = true
    end
end

function enemy:render()
    self._wisys:render(self.dmgt, self.dmgmaxt)--by OLC and ETC，新行走图系统
end

function enemy:take_damage(dmg)
    if self.dmgmaxt then
        self.dmgt = self.dmgmaxt
    end
    if not self.protect then
        self.hp = self.hp - dmg
    end
end

function enemy:kill()
    New(enemy_death_ef, self.death_ef, self.x, self.y)
    if self.drop then
        item.DropItem(self.x, self.y, self.drop)
    end

    if self.clear_bullet then
        New(bullet_killer, player.x, player.y, false)
    end
    _kill_servants(self)
end

enemy_death_ef = Class(object)

function enemy_death_ef:init(index, x, y)
    self.img = 'bubble' .. index
    self.layer = LAYER_ENEMY + 50
    self.group = GROUP_GHOST
    self.x = x
    self.y = y
    self.rot = 45
    PlaySound('enep00', 0.3, self.x / 200, true)
end

function enemy_death_ef:render()
    local alpha = 1 - self.timer / 30
    alpha = 255 * alpha ^ 2
    SetImageState(self.img, '', Color(alpha, 255, 255, 255))
    Render(self.img, self.x, self.y, 15, 0.4 - self.timer * 0.01, self.timer * 0.1 + 0.7)
    Render(self.img, self.x, self.y, 75, 0.4 - self.timer * 0.01, self.timer * 0.1 + 0.7)
    Render(self.img, self.x, self.y, 135, 0.4 - self.timer * 0.01, self.timer * 0.1 + 0.7)
end

function enemy_death_ef:frame()
    if self.timer == 30 then
        Kill(self)
    end
end

Include 'THlib/enemy/boss.lua'

EnemySimple = Class(enemy)

function EnemySimple:init(style, hp, x, y, drop, pro, clr, bound, tjt, tf)
    enemy.init(self, style, hp, clr, bound, tjt)
    self.x, self.y = x, y
    self.drop = drop
    task.New(self, function()
        self.protect = true
        task.Wait(pro)
        self.protect = false
    end)
    tf(self)
end
