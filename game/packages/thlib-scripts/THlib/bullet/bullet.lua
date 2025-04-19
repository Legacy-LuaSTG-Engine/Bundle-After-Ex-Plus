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

local cjson = require("cjson")

---@class thlib.bullet.Definition.Point
---@field x number
---@field y number

---@class thlib.bullet.Definition.Rect
---@field x number
---@field y number
---@field width number
---@field height number

---@class thlib.bullet.Definition.Texture
---@field name string texture resource name
---@field path string path to texture file
---@field mipmap boolean? enable mipmap, default to false

---@class thlib.bullet.Definition.Sprite
---@field name string sprite resource name
---@field texture string texture resource name
---@field rect thlib.bullet.Definition.Rect
---@field center thlib.bullet.Definition.Point? center of sprite relative to rect, default to center of rect
---@field scaling number? default to 1.0

---@class thlib.bullet.Definition.SpriteSequence
---@field name string sprite-sequence resource name
---@field sprites string[] sprite-sequence frame
---@field interval integer? sprite-sequence frame interval, default to 1

---@alias thlib.bullet.Definition.KnownColor
---| '"deep_red"'
---| '"red"'
---| '"deep_purple"'
---| '"purple"'
---| '"deep_blue"'
---| '"blue"'
---| '"deep_cyan"'
---| '"cyan"'
---| '"deep_green"'
---| '"green"'
---| '"yellow_green"'
---| '"deep_yellow"'
---| '"yellow"'
---| '"orange"'
---| '"gray"'
---| '"white"'

---@class thlib.bullet.Definition.Variant
---@field name string bullet variant name
---@field sprite string? sprite resource name
---@field sprite_sequence string? sprite-sequence resource name
---@field color thlib.bullet.Definition.KnownColor

---@class thlib.bullet.Definition.Collider
---@field type '"circle"' | '"ellipse"' | '"rect"'
---@field radius number? circle
---@field a number? ellipse | rect
---@field b number? ellipse | rect

---@class thlib.bullet.Definition.Family
---@field name string bullet family name
---@field variants thlib.bullet.Definition.Variant[] bullet variants
---@field collider thlib.bullet.Definition.Collider bullet collider

---@class thlib.bullet.Definition
---@field textures thlib.bullet.Definition.Texture[]?
---@field sprites thlib.bullet.Definition.Sprite[]?
---@field sprite_sequences thlib.bullet.Definition.SpriteSequence[]?
---@field families table<string, thlib.bullet.Definition.Family> bullet families

---@param collider thlib.bullet.Definition.Collider
---@return number
local function getColliderArea(collider)
    if collider.type == "circle" then
        return math.pi * collider.radius * collider.radius
    elseif collider.type == "ellipse" then
        return math.pi * collider.a * collider.b
    elseif collider.type == "rect" then
        return 2.0 * collider.a * 2.0 * collider.b
    else
        error(("unknown collider type '%s'"):format(collider.type))
    end
end

---@param collider thlib.bullet.Definition.Collider
---@return boolean rect
---@return number a
---@return number b
local function translateCollider(collider)
    if collider.type == "circle" then
        return false, collider.radius, collider.radius
    elseif collider.type == "ellipse" then
        return false, collider.a, collider.b
    elseif collider.type == "rect" then
        return true, collider.a, collider.b
    else
        error(("unknown collider type '%s'"):format(collider.type))
    end
end

---@param path string
local function loadBulletDefinitions(path)
    ---@type string?
    local root
    for i = #path, 1, -1 do
        local c = path:sub(i, i)
        if c == "/" or c == "\\" then
            root = path:sub(1, i)
            break
        end
    end
    if not root then
        root = ""
    end
    local json_content = assert(lstg.LoadTextFile(path), ("load bullet definitions from '%s' failed, read file failed"):format(path))
    ---@type thlib.bullet.Definition
    local definitions = cjson.decode(json_content)
    if definitions.textures then
        assert(type(definitions.textures) == "table", "bullet definitions field 'textures' must be an array")
        for _, texture in ipairs(definitions.textures) do
            assert(type(texture.name) == "string", "texture field 'name' must be string")
            assert(type(texture.path) == "string", "texture field 'path' must be string")
            if texture.mipmap ~= nil then
                assert(type(texture.mipmap) == "boolean", "texture field 'mipmap' must be boolean")
            end
            if texture.mipmap ~= nil then
                lstg.LoadTexture(texture.name, root .. texture.path, texture.mipmap)
            else
                lstg.LoadTexture(texture.name, root .. texture.path)
            end
        end
    end
    if definitions.sprites then
        assert(type(definitions.sprites) == "table", "bullet definitions field 'sprites' must be an array")
        for _, sprite in ipairs(definitions.sprites) do
            assert(type(sprite.name) == "string", "sprite field 'name' must be string")
            assert(type(sprite.texture) == "string", "sprite field 'texture' must be string")
            assert(type(sprite.rect) == "table", "sprite field 'rect' must be a Rect")
            assert(type(sprite.rect.x) == "number", "Rect field 'x' must be a number")
            assert(type(sprite.rect.y) == "number", "Rect field 'y' must be a number")
            assert(type(sprite.rect.width) == "number", "Rect field 'width' must be a number")
            assert(type(sprite.rect.height) == "number", "Rect field 'height' must be a number")
            if sprite.center ~= nil then
                assert(type(sprite.center) == "table", "sprite field 'center' must be a Point")
                assert(type(sprite.center.x) == "number", "Point field 'x' must be a number")
                assert(type(sprite.center.y) == "number", "Point field 'y' must be a number")
            end
            if sprite.scaling ~= nil then
                assert(type(sprite.scaling) == "number", "sprite field 'scaling' must be number")
            end
            lstg.LoadImage(sprite.name, sprite.texture, sprite.rect.x, sprite.rect.y, sprite.rect.width, sprite.rect.height)
            if sprite.center ~= nil then
                lstg.SetImageCenter(sprite.name, sprite.center.x, sprite.center.y)
            end
            if sprite.scaling ~= nil then
                lstg.SetImageScale(sprite.name, sprite.scaling)
            end
        end
    end
    if definitions.sprite_sequences then
        assert(type(definitions.sprites) == "table", "bullet definitions field 'sprite_sequences' must be an array")
        for _, sprite_sequence in ipairs(definitions.sprite_sequences) do
            assert(type(sprite_sequence.name) == "string", "sprite-sequence field 'name' must be string")
            assert(type(sprite_sequence.sprites) == "table", "sprite-sequence field 'sprites' must be an array")
            for _, sprite in ipairs(sprite_sequence.sprites) do
                assert(type(sprite) == "string", "sprite-sequence field 'sprites' must contains string type")
            end
            if sprite_sequence.interval ~= nil then
                assert(type(sprite_sequence.interval) == "number", "sprite-sequence field 'interval' must be integer")
            end
            ---@diagnostic disable-next-line: param-type-mismatch, missing-parameter
            lstg.LoadAnimation(sprite_sequence.name, sprite_sequence.sprites, sprite_sequence.interval or 1)
        end
    end
    for k, v in pairs(definitions.families) do
        local class_name = k
        local bullet_class = Class(img_class)

        bullet_class.size = getColliderArea(v.collider) / 256.0

        ---@type string[]
        local variants = {}
        if #v.variants == 16 then
            for i = 1, 16 do
                local value = v.variants[i].sprite or v.variants[i].sprite_sequence
                table.insert(variants, value)
            end
        elseif #v.variants == 8 then
            for i = 1, 8 do
                local value = v.variants[i].sprite or v.variants[i].sprite_sequence
                table.insert(variants, value)
                table.insert(variants, value)
            end
        else
            error("unsupported variant count")
        end

        local rect, a, b = translateCollider(v.collider)
        function bullet_class:init(index)
            self.img = variants[index]
            self.rect = rect
            self.a = a
            self.b = b
        end

        _G[class_name] = bullet_class
    end
end

bullet.loadBulletDefinitions = loadBulletDefinitions
