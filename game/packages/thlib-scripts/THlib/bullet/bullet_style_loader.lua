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
---@field blend lstg.BlendMode?

---@class thlib.bullet.Definition.SpriteSequence
---@field name string sprite-sequence resource name
---@field sprites string[] sprite-sequence frame
---@field interval integer? sprite-sequence frame interval, default to 1
---@field blend lstg.BlendMode?

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
---@field blend lstg.BlendMode?

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

local function refreshMagicTable()
    -- 祖宗之法不可变
    BULLETSTYLE = {
        arrow_big, arrow_mid, arrow_small, gun_bullet, butterfly, square,
        ball_small, ball_mid, ball_mid_c, ball_big, ball_huge, ball_light,
        star_small, star_big, grain_a, grain_b, grain_c, kite, knife, knife_b,
        water_drop, mildew, ellipse, heart, money, music, silence,
        water_drop_dark, ball_huge_dark, ball_light_dark
    }
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
            if sprite.blend ~= nil then
                lstg.SetImageState(sprite.name, sprite.blend, lstg.Color(255, 255, 255, 255))
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
            if sprite_sequence.blend ~= nil then
                lstg.SetAnimationState(sprite_sequence.name, sprite_sequence.blend, lstg.Color(255, 255, 255, 255))
            end
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
        if v.blend ~= nil then
            local blend = v.blend
            function bullet_class:init(index)
                self.img = variants[index]
                self.rect = rect
                self.a = a
                self.b = b
                self._blend = blend
                self._r = 255
                self._g = 255
                self._b = 255
                self._a = 255
            end
        else
            function bullet_class:init(index)
                self.img = variants[index]
                self.rect = rect
                self.a = a
                self.b = b
            end
        end

        _G[class_name] = bullet_class
    end
    refreshMagicTable()
end

-- default bullet style
loadBulletDefinitions("assets/cake/bullet/generated/bullet_atlas.json")

bullet.loadBulletDefinitions = loadBulletDefinitions
