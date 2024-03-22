----------------------------------------
---符卡背景基类

_spellcard_background = Class(background)

function _spellcard_background:init()
    background.init(self, true)
    self.layers = {}
    self.fxsize = 0
end

function _spellcard_background:AddLayer(img, tile, x, y, rot, vx, vy, omiga, blend, hscale, vscale, init, frame, render)
    table.insert(self.layers, {
        img = img,
        tile = tile,
        x = x,
        y = y,
        rot = rot,
        vx = vx,
        vy = vy,
        omiga = omiga,
        blend = blend,
        a = 255,
        r = 255,
        g = 255,
        b = 255,
        frame = frame,
        render = render,
        timer = 0,
        hscale = hscale,
        vscale = vscale,
        _cur_alpha = self.alpha,
    })
    if init then
        init(self.layers[#self.layers])
    end
end

function _spellcard_background:frame()
    for _, l in ipairs(self.layers) do
        l.x = l.x + l.vx
        l.y = l.y + l.vy
        l.rot = l.rot + l.omiga
        l.timer = l.timer + 1
        l._cur_alpha = self.alpha
        if l.frame then
            l.frame(l)
        end
        if lstg.tmpvar.bg and lstg.tmpvar.bg.hide == true then
            self.fxsize = min(self.fxsize + 2, 200)
        else
            self.fxsize = max(self.fxsize - 2, 0)
        end
    end
end

local e1x, e1y, e2x, e2y, width, height
local function transform(x, y, x0, y0)
    x, y = x - x0, y - y0
    return (x * e1x + y * e1y) / width, (x * e2x + y * e2y) / height
end

local function tileRender(self)
    -- get axis
    e1x, e1y = cos(self.rot), sin(self.rot)
    e2x, e2y = -e1y, e1x

    -- get size
    width, height = GetImageSize(self.img)
    width, height = width * self.hscale, height * self.vscale

    -- get map
    local w = lstg.world
    local p1x, p1y = transform(w.l, w.t, self.x, self.y)
    local p2x, p2y = transform(w.r, w.t, self.x, self.y)
    local p3x, p3y = transform(w.r, w.b, self.x, self.y)
    local p4x, p4y = transform(w.l, w.b, self.x, self.y)

    -- get bound
    local left = min(p1x, p2x, p3x, p4x)
    local right = max(p1x, p2x, p3x, p4x)
    local bottom = min(p1y, p2y, p3y, p4y)
    local top = max(p1y, p2y, p3y, p4y)

    -- tile render
    for i = math.floor(left + 0.5), math.ceil(right + 0.5) do
        for j = math.floor(bottom + 0.5), math.ceil(top + 0.5) do
            Render(self.img,
                self.x + i * width * e1x + j * height * e2x,
                self.y + i * width * e1y + j * height * e2y,
                self.rot, self.hscale, self.vscale
            )
        end
    end
end

function _spellcard_background:render()
    SetViewMode 'world'
    if self.alpha > 0 then
        local showboss = lstg.tmpvar.bg and lstg.tmpvar.bg.hide == true
        if showboss then
            background.WarpEffectCapture()
        end
        for i = #(self.layers), 1, -1 do
            local l = self.layers[i]
            l._cur_alpha = self.alpha
            SetImageState(l.img, l.blend, Color(l.a * self.alpha, l.r, l.g, l.b))
            -- local world = lstg.world
            if l.tile then
                -- local w, h = GetTextureSize(l.img)
                -- for i = -int((world.r + 16 + l.x) / w + 0.5), int((world.r + 16 - l.x) / w + 0.5) do
                --     for j = -int((world.t + 16 + l.y) / h + 0.5), int((world.t + 16 - l.y) / h + 0.5) do
                --         Render(l.img, l.x + i * w, l.y + j * h)
                --     end
                -- end
                tileRender(l)
            else
                Render(l.img, l.x, l.y, l.rot, l.hscale, l.vscale)
            end
            if l.render then
                l.render(l)
            end
        end
        if showboss then
            background.WarpEffectApply()
        end
    end
end
