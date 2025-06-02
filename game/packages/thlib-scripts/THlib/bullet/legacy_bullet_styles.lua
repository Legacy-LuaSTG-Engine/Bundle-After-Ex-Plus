
----------------------------------------------------------------
function img_class:del()
    New(bubble2, 'preimg' .. self._index, self.x, self.y, self.dx, self.dy, 11, self.imgclass.size, 0, Color(0xFFFFFFFF), Color(0xFFFFFFFF), self.layer, 'mul+add')
end
function img_class:render()
    if self._blend then
        SetImageState('preimg' .. self._index, self._blend, Color(255 * self.timer / 11, 255, 255, 255))
    else
        SetImageState('preimg' .. self._index, '', Color(255 * self.timer / 11, 255, 255, 255))
    end
    Render('preimg' .. self._index, self.x, self.y, self.rot, ((11 - self.timer) / 11 * 3 + 1) * self.imgclass.size)
end
----------------------------------------------------------------
particle_img = Class(object)
function particle_img:init(index)
    self.layer = LAYER_ENEMY_BULLET
    self.img = index
    self.class = self.logclass
end
function particle_img:del()
    misc.KeepParticle(self)
end
function particle_img:kill()
    particle_img.del(self)
end
----------------------------------------------------------------
arrow_big = Class(img_class)
arrow_big.size = 0.6
function arrow_big:init(index)
    self.img = 'arrow_big' .. index
end
----------------------------------------------------------------
arrow_mid = Class(img_class)
arrow_mid.size = 0.61
function arrow_mid:init(index)
    self.img = 'arrow_mid' .. int((index + 1) / 2)
end
----------------------------------------------------------------
gun_bullet = Class(img_class)
gun_bullet.size = 0.4
function gun_bullet:init(index)
    self.img = 'gun_bullet' .. index
end
----------------------------------------------------------------
gun_bullet_void = Class(img_class)
gun_bullet_void.size = 0.4
function gun_bullet_void:init(index)
    self.img = 'gun_bullet_void' .. index
end
----------------------------------------------------------------
butterfly = Class(img_class)
butterfly.size = 0.7
function butterfly:init(index)
    self.img = 'butterfly' .. int((index + 1) / 2)
end
----------------------------------------------------------------
square = Class(img_class)
square.size = 0.8
function square:init(index)
    self.img = 'square' .. index
end
----------------------------------------------------------------
ball_mid = Class(img_class)
ball_mid.size = 0.75
function ball_mid:init(index)
    self.img = 'ball_mid' .. index
end
----------------------------------------------------------------
ball_mid_b = Class(img_class)
ball_mid_b.size = 0.751
function ball_mid_b:init(index)
    self.img = 'ball_mid_b' .. int((index + 1) / 2)
end
----------------------------------------------------------------
ball_mid_c = Class(img_class)
ball_mid_c.size = 0.752
function ball_mid_c:init(index)
    self.img = 'ball_mid_c' .. index
end
----------------------------------------------------------------
ball_mid_d = Class(img_class)
ball_mid_d.size = 0.753
function ball_mid_d:init(index)
    self.img = 'ball_mid_d' .. int((index + 1) / 2)
end
----------------------------------------------------------------
money = Class(img_class)
money.size = 0.753
function money:init(index)
    self.img = 'money' .. int((index + 1) / 2)
end
----------------------------------------------------------------
mildew = Class(img_class)
mildew.size = 0.401
function mildew:init(index)
    self.img = 'mildew' .. index
end
----------------------------------------------------------------
ellipse = Class(img_class)
ellipse.size = 0.701
function ellipse:init(index)
    self.img = 'ellipse' .. index
end
----------------------------------------------------------------
star_small = Class(img_class)
star_small.size = 0.5
function star_small:init(index)
    self.img = 'star_small' .. index
end
----------------------------------------------------------------
star_big = Class(img_class)
star_big.size = 0.998
function star_big:init(index)
    self.img = 'star_big' .. int((index + 1) / 2)
end
----------------------------------------------------------------
star_big_b = Class(img_class)
star_big_b.size = 0.999
function star_big_b:init(index)
    self.img = 'star_big_b' .. int((index + 1) / 2)
end
----------------------------------------------------------------
ball_huge = Class(img_class)
ball_huge.size = 2.0
function ball_huge:init(index)
    self.img = 'ball_huge' .. int((index + 1) / 2)
end
function ball_huge:frame()
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
        self.layer = LAYER_ENEMY_BULLET - 2.0 + self.index * 0.00001
        --self.colli=true
        if self.stay then
            self.timer = -1
        end
    end
end
function ball_huge:render()
    SetImageState('fade_' .. self.img, 'mul+add', Color(255 * self.timer / 11, 255, 255, 255))
    Render('fade_' .. self.img, self.x, self.y, self.rot, (11 - self.timer) / 11 + 1)
end
function ball_huge:del()
    New(bubble2, 'fade_' .. self.img, self.x, self.y, self.dx, self.dy, 11, 1, 0, Color(0xFFFFFFFF), Color(0x00FFFFFF), self.layer, 'mul+add')
end
function ball_huge:kill()
    ball_huge.del(self)
end
----------------------------------------------------------------------------
ball_huge_dark = Class(img_class)
ball_huge_dark.size = 2.0
function ball_huge_dark:init(index)
    self.img = 'ball_huge_dark' .. int((index + 1) / 2)
end
function ball_huge_dark:frame()
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
        self.layer = LAYER_ENEMY_BULLET - 2.0 + self.index * 0.00001
        --self.colli=true
        if self.stay then
            self.timer = -1
        end
    end
end
function ball_huge_dark:render()
    SetImageState('fade_' .. self.img, '', Color(255 * self.timer / 11, 255, 255, 255))
    Render('fade_' .. self.img, self.x, self.y, self.rot, (11 - self.timer) / 11 + 1)
end
function ball_huge_dark:del()
    New(bubble2, 'fade_' .. self.img, self.x, self.y, self.dx, self.dy, 11, 1, 0, Color(0xFFFFFFFF), Color(0x00FFFFFF), self.layer, '')
end
function ball_huge_dark:kill()
    ball_huge.del(self)
end
----------------------------------------------------------------
ball_light = Class(img_class)
ball_light.size = 2.0
function ball_light:init(index)
    self.img = 'ball_light' .. int((index + 1) / 2)
end
function ball_light:frame()
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
        self.layer = LAYER_ENEMY_BULLET - 2.0 + self.index * 0.00001
        --self.colli=true
        if self.stay then
            self.timer = -1
        end
    end
end
function ball_light:render()
    SetImageState('fade_' .. self.img, 'mul+add', Color(255 * self.timer / 11, 255, 255, 255))
    Render('fade_' .. self.img, self.x, self.y, self.rot, (11 - self.timer) / 11 + 1)
end
function ball_light:del()
    New(bubble2, 'fade_' .. self.img, self.x, self.y, self.dx, self.dy, 11, 1, 0, Color(0xFFFFFFFF), Color(0x00FFFFFF), self.layer, 'mul+add')
end
function ball_light:kill()
    ball_light.del(self)
end
----------------------------------------------------------------
ball_light_dark = Class(img_class)
ball_light_dark.size = 2.0
function ball_light_dark:init(index)
    self.img = 'ball_light_dark' .. int((index + 1) / 2)
end
function ball_light_dark:frame()
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
        self.layer = LAYER_ENEMY_BULLET - 2.0 + self.index * 0.00001
        --self.colli=true
        if self.stay then
            self.timer = -1
        end
    end
end
function ball_light_dark:render()
    SetImageState('fade_' .. self.img, '', Color(255 * self.timer / 11, 255, 255, 255))
    Render('fade_' .. self.img, self.x, self.y, self.rot, (11 - self.timer) / 11 + 1)
end
function ball_light_dark:del()
    New(bubble2, 'fade_' .. self.img, self.x, self.y, self.dx, self.dy, 11, 1, 0, Color(0xFFFFFFFF), Color(0x00FFFFFF), self.layer, '')
end
function ball_light_dark:kill()
    ball_light.del(self)
end
----------------------------------------------------------------
ball_big = Class(img_class)
ball_big.size = 1.0
function ball_big:init(index)
    self.img = 'ball_big' .. index
end
----------------------------------------------------------------
heart = Class(img_class)
heart.size = 1.0
function heart:init(index)
    self.img = 'heart' .. int((index + 1) / 2)
end
----------------------------------------------------------------
ball_small = Class(img_class)
ball_small.size = 0.402
function ball_small:init(index)
    self.img = 'ball_small' .. index
end
----------------------------------------------------------------
grain_a = Class(img_class)
grain_a.size = 0.403
function grain_a:init(index)
    self.img = 'grain_a' .. index
end
----------------------------------------------------------------
grain_b = Class(img_class)
grain_b.size = 0.404
function grain_b:init(index)
    self.img = 'grain_b' .. index
end
----------------------------------------------------------------
grain_c = Class(img_class)
grain_c.size = 0.405
function grain_c:init(index)
    self.img = 'grain_c' .. index
end
----------------------------------------------------------------
kite = Class(img_class)
kite.size = 0.406
function kite:init(index)
    self.img = 'kite' .. index
end
----------------------------------------------------------------
knife = Class(img_class)
knife.size = 0.754
function knife:init(index)
    self.img = 'knife' .. index
end
----------------------------------------------------------------
knife_b = Class(img_class)
knife_b.size = 0.755
function knife_b:init(index)
    self.img = 'knife_b' .. int((index + 1) / 2)
end
----------------------------------------------------------------
arrow_small = Class(img_class)
arrow_small.size = 0.407
function arrow_small:init(index)
    self.img = 'arrow_small' .. index
end
----------------------------------------------------------------
water_drop = Class(img_class)   --2 4 6 10 12
water_drop.size = 0.702
function water_drop:init(index)
    self.img = 'water_drop' .. int((index + 1) / 2)
end
function water_drop:render()
    SetImageState('preimg' .. self._index, 'mul+add', Color(255 * self.timer / 11, 255, 255, 255))
    Render('preimg' .. self._index, self.x, self.y, self.rot, ((11 - self.timer) / 11 * 2 + 1) * self.imgclass.size)
end
----------------------------------------------------------------
water_drop_dark = Class(img_class)   --2 4 6 10 12
water_drop_dark.size = 0.702
function water_drop_dark:init(index)
    self.img = 'water_drop_dark' .. int((index + 1) / 2)
end
----------------------------------------------------------------
music = Class(img_class)
music.size = 0.8
function music:init(index)
    self.img = 'music' .. int((index + 1) / 2)
end
----------------------------------------------------------------
silence = Class(img_class)
silence.size = 0.8
function silence:init(index)
    self.img = 'silence' .. int((index + 1) / 2)
end
----------------------------------------------------------------
BULLETSTYLE = {
    arrow_big, arrow_mid, arrow_small, gun_bullet, butterfly, square,
    ball_small, ball_mid, ball_mid_c, ball_big, ball_huge, ball_light,
    star_small, star_big, grain_a, grain_b, grain_c, kite, knife, knife_b,
    water_drop, mildew, ellipse, heart, money, music, silence,
    water_drop_dark, ball_huge_dark, ball_light_dark
}--30
