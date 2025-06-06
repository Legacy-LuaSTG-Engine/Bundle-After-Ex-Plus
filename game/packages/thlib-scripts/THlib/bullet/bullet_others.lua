lstg.LoadTexture('etbreak', 'assets/olc/bullet/etbreak.png')
for j = 1, 16 do
    lstg.LoadAnimation('etbreak' .. j, 'etbreak', 0, 0, 128, 128, 4, 2, 3)
    lstg.SetAnimationScale('etbreak' .. j, 0.5)
end
local BulletBreakIndex = {
    lstg.Color(0xC0FF3030), --red
    lstg.Color(0xC0FF30FF), --purple
    lstg.Color(0xC03030FF), --blue
    lstg.Color(0xC030FFFF), --cyan
    lstg.Color(0xC030FF30), --green
    lstg.Color(0xC0FFFF30), --yellow
    lstg.Color(0xC0FF8030), --orange
    lstg.Color(0xC0D0D0D0), --gray
}
for j = 1, 16 do
    if j % 2 == 0 then
        lstg.SetAnimationState('etbreak' .. j, 'mul+add', BulletBreakIndex[j / 2])
    elseif j == 15 then
        lstg.SetAnimationState('etbreak' .. j, '', 0.5 * BulletBreakIndex[(j + 1) / 2] + Color(0x60000000))
    else
        lstg.SetAnimationState('etbreak' .. j, 'mul+add', 0.5 * BulletBreakIndex[(j + 1) / 2] + Color(0x60000000))
    end
end
function BulletBreak:init(x, y, index)
    self.x = x
    self.y = y
    self.group = GROUP_GHOST
    self.layer = LAYER_ENEMY_BULLET - 50
    self.img = 'etbreak' .. index
    local s = ran:Float(0.5, 0.75)
    self.hscale = s * ran:Sign()
    self.vscale = s
    self.rot = ran:Float(0, 360)
end
function BulletBreak:frame()
    if self.timer == 23 then
        Del(self)
    end
end
