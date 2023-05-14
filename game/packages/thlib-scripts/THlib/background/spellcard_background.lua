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
            local world = lstg.world
            if l.tile then
                local w, h = GetTextureSize(l.img)
                for i = -int((world.r + 16 + l.x) / w + 0.5), int((world.r + 16 - l.x) / w + 0.5) do
                    for j = -int((world.t + 16 + l.y) / h + 0.5), int((world.t + 16 - l.y) / h + 0.5) do
                        Render(l.img, l.x + i * w, l.y + j * h)
                    end
                end
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
