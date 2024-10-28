local ipairs = ipairs
local pairs = pairs
local table = table
local unpack = unpack or table.unpack
local lstg = lstg
local AttributeProxy = require("foundation.AttributeProxy")
local emptyFunction = function()
end
local emptyColor = lstg.Color(0, 0, 0, 0)
local fullColor = lstg.Color(255, 255, 255, 255)
----------------------------------------
---符卡背景基类

local index = 0

--region layer
local layer = {
    img = "",
    tile = false,
    x = 0,
    y = 0,
    rot = 0,
    vx = 0,
    vy = 0,
    omega = 0,
    blend = "",
    a = 255,
    r = 255,
    g = 255,
    b = 255,
    timer = 0,
    hscale = 1,
    vscale = 1,
    init = emptyFunction,
    frame = emptyFunction,
    render = emptyFunction,
}

--region Attribute Proxies
local layer_proxies = {}
--region omiga
local proxy_omiga = AttributeProxy.createProxy("omiga")
layer_proxies[proxy_omiga.key] = proxy_omiga
function proxy_omiga:getter(key, storage)
    return self.omega
end
function proxy_omiga:setter(key, value, storage)
    self.omega = value
end
--endregion
--region _blend
local proxy_blend = AttributeProxy.createProxy("_blend")
layer_proxies[proxy_blend.key] = proxy_blend
function proxy_blend:getter(key, storage)
    return self.blend
end
function proxy_blend:setter(key, value, storage)
    self.blend = value
end
--endregion
--region _a
local proxy_a = AttributeProxy.createProxy("_a")
layer_proxies[proxy_a.key] = proxy_a
function proxy_a:getter(key, storage)
    return self.a
end
function proxy_a:setter(key, value, storage)
    self.a = value
end
--endregion
--region _r
local proxy_r = AttributeProxy.createProxy("_r")
layer_proxies[proxy_r.key] = proxy_r
function proxy_r:getter(key, storage)
    return self.r
end
function proxy_r:setter(key, value, storage)
    self.r = value
end
--endregion
--region _g
local proxy_g = AttributeProxy.createProxy("_g")
layer_proxies[proxy_g.key] = proxy_g
function proxy_g:getter(key, storage)
    return self.g
end
function proxy_g:setter(key, value, storage)
    self.g = value
end
--endregion
--region _b
local proxy_b = AttributeProxy.createProxy("_b")
layer_proxies[proxy_b.key] = proxy_b
function proxy_b:getter(key, storage)
    return self.b
end
function proxy_b:setter(key, value, storage)
    self.b = value
end
--endregion
--region _speed
local proxy_speed = AttributeProxy.createProxy("_speed")
layer_proxies[proxy_speed.key] = proxy_speed
function proxy_speed:getter(key, storage)
    return lstg.Dist(0, 0, self.vx, self.vy)
end
function proxy_speed:setter(key, value, storage)
    if value == 0 then
        self.vx = 0
        self.vy = 0
    else
        local speed = lstg.Dist(0, 0, self.vx, self.vy)
        if speed == 0 then
            local angle = self.rot
            self.vx = value * lstg.cos(angle)
            self.vy = value * lstg.sin(angle)
        else
            self.vx = value * self.vx / speed
            self.vy = value * self.vy / speed
        end
    end
end
--endregion
--region _angle
local proxy_angle = AttributeProxy.createProxy("_angle")
layer_proxies[proxy_angle.key] = proxy_angle
function proxy_angle:getter(key, storage)
    if self.vx == 0 and self.vy == 0 then
        return self.rot
    end
    return lstg.Angle(0, 0, self.vx, self.vy)
end
function proxy_angle:setter(key, value, storage)
    if self.vx == 0 and self.vy == 0 then
        self.rot = value
    else
        local speed = lstg.Dist(0, 0, self.vx, self.vy)
        self.vx = speed * lstg.cos(value)
        self.vy = speed * lstg.sin(value)
    end
end
--endregion
--endregion

local function createLayer(master, img, tile, x, y, rot, vx, vy, omiga, blend, hscale, vscale, init, frame, render)
    local self = {}
    for k, v in pairs(layer) do
        self[k] = v
    end
    if img then
        self.img = img
    end
    if tile then
        self.tile = tile
    end
    if x then
        self.x = x
    end
    if y then
        self.y = y
    end
    if rot then
        self.rot = rot
    end
    if vx then
        self.vx = vx
    end
    if vy then
        self.vy = vy
    end
    if omiga then
        self.omega = omiga
    end
    if blend then
        self.blend = blend
    end
    if hscale then
        self.hscale = hscale
    end
    if vscale then
        self.vscale = vscale
    end
    if init then
        self.init = init
    end
    if frame then
        self.frame = frame
    end
    if render then
        self.render = render
    end
    local proxy_cur_alpha = AttributeProxy.createProxy("_cur_alpha")
    function proxy_cur_alpha:getter(key, storage)
        return lstg.IsValid(master) and master.alpha or 0
    end
    function proxy_cur_alpha:setter(key, value, storage)
        -- error("_cur_alpha is read-only.")
    end
    AttributeProxy.applyProxies(self, layer_proxies)
    AttributeProxy.applyProxies(self, { proxy_cur_alpha })
    return self
end
--endregion

--region layer methods
local function prepareRenderTexture(self, layers)
    if not self.__render_texture then
        self.__render_texture = {}
        self.__render_texture_prefix = ("spellcard_background_%d_rt_"):format(index)
        index = index + 1
    end
    local list = {}
    local need_to_create = false
    for _, l in ipairs(layers) do
        local img = l.img
        if img and img ~= "" and not self.__render_texture[img] then
            table.insert(list, img)
            self.__render_texture[img] = self.__render_texture_prefix .. img
            need_to_create = true
        end
    end
    if not need_to_create then
        return
    end
    for _, img in ipairs(list) do
        local rt = self.__render_texture[img]
        local args = ImageList[img]
        local tex, x, y, w, h = unpack(args)
        lstg.CreateRenderTarget(rt, w, h)
        lstg.PushRenderTarget(rt)
        lstg.SetViewport(0, w, 0, h)
        lstg.SetScissorRect(0, w, 0, h)
        lstg.SetOrtho(0, w, 0, h)
        lstg.SetFog()
        lstg.SetImageScale(1)
        lstg.RenderClear(emptyColor)
        lstg.RenderTexture(tex, "",
                { 0, 0, 0.5, x, y + h, fullColor },
                { w, 0, 0.5, x + w, y + h, fullColor },
                { w, h, 0.5, x + w, y, fullColor },
                { 0, h, 0.5, x, y, fullColor })
        lstg.PopRenderTarget()
        lstg.SetTextureSamplerState(rt, "linear+wrap")
    end
end

local function unloadRenderTexture(self)
    if not self.__render_texture then
        return
    end
    for _, rt in pairs(self.__render_texture) do
        local pool = lstg.CheckRes(1, rt)
        if pool then
            lstg.RemoveResource(pool, 1, rt)
        end
    end
    self.__render_texture = nil
end

local function renderLayer(self, l, rt)
    if l.hscale == 0 or l.vscale == 0 then
        return
    end
    local w, h = lstg.GetTextureSize(rt)
    local color = lstg.Color(l.a * self.alpha, l.r, l.g, l.b)
    if l.tile then
        local world = lstg.world
        local left = world.l - l.x - w * 0.5
        local right = world.r - l.x - w * 0.5
        local bottom = world.b - l.y - h * 0.5
        local top = world.t - l.y - h * 0.5
        local cx = right - left
        local cy = top - bottom
        left = (left - cx) / l.hscale + cx
        right = (right - cx) / l.hscale + cx
        bottom = (bottom - cy) / l.vscale + cy
        top = (top - cy) / l.vscale + cy
        local rot_cos = lstg.cos(-l.rot)
        local rot_sin = lstg.sin(-l.rot)
        local uv_lt_x = left * rot_cos - top * rot_sin
        local uv_lt_y = left * rot_sin + top * rot_cos
        local uv_rt_x = right * rot_cos - top * rot_sin
        local uv_rt_y = right * rot_sin + top * rot_cos
        local uv_lb_x = left * rot_cos - bottom * rot_sin
        local uv_lb_y = left * rot_sin + bottom * rot_cos
        local uv_rb_x = right * rot_cos - bottom * rot_sin
        local uv_rb_y = right * rot_sin + bottom * rot_cos
        lstg.RenderTexture(rt, l.blend,
                { world.l, world.t, 0.5, uv_lt_x, uv_lt_y, color },
                { world.r, world.t, 0.5, uv_rt_x, uv_rt_y, color },
                { world.r, world.b, 0.5, uv_rb_x, uv_rb_y, color },
                { world.l, world.b, 0.5, uv_lb_x, uv_lb_y, color })
    else
        local rot = l.rot
        local rot_cos = lstg.cos(rot)
        local rot_sin = lstg.sin(rot)
        local left = -w * 0.5 * l.hscale
        local right = w * 0.5 * l.hscale
        local bottom = -h * 0.5 * l.vscale
        local top = h * 0.5 * l.vscale
        local lt_x = left * rot_cos - top * rot_sin + l.x
        local lt_y = left * rot_sin + top * rot_cos + l.y
        local rt_x = right * rot_cos - top * rot_sin + l.x
        local rt_y = right * rot_sin + top * rot_cos + l.y
        local lb_x = left * rot_cos - bottom * rot_sin + l.x
        local lb_y = left * rot_sin + bottom * rot_cos + l.y
        local rb_x = right * rot_cos - bottom * rot_sin + l.x
        local rb_y = right * rot_sin + bottom * rot_cos + l.y
        lstg.RenderTexture(rt, l.blend,
                { lt_x, lt_y, 0.5, 0, 0, color },
                { rt_x, rt_y, 0.5, w, 0, color },
                { rb_x, rb_y, 0.5, w, h, color },
                { lb_x, lb_y, 0.5, 0, h, color })
    end
end
--endregion

--region spellcard_background
local bg = Class(background)
_spellcard_background = bg

function bg:init()
    background.init(self, true)
    self.layers = {}
    self.fxsize = 0
end

function bg:AddLayer(img, tile, x, y, rot, vx, vy, omiga, blend, hscale, vscale, init, frame, render)
    local l = createLayer(self, img, tile, x, y, rot, vx, vy, omiga, blend, hscale, vscale, init, frame, render)
    table.insert(self.layers, l)
    l:init()
end

function bg:frame()
    for _, l in ipairs(self.layers) do
        l.x = l.x + l.vx
        l.y = l.y + l.vy
        l.rot = l.rot + l.omega
        l.timer = l.timer + 1
        l:frame()
    end
    if lstg.IsValid(lstg.tmpvar.bg) and not lstg.tmpvar.bg.hide then
        self.fxsize = min(self.fxsize + 2, 200)
    else
        self.fxsize = max(self.fxsize - 2, 0)
    end
end

function bg:render()
    prepareRenderTexture(self, self.layers)
    SetViewMode("world")
    if self.alpha > 0 then
        local showboss = lstg.IsValid(lstg.tmpvar.bg) and not lstg.tmpvar.bg.hide
        if showboss then
            background.WarpEffectCapture()
        end
        for i = #self.layers, 1, -1 do
            local l = self.layers[i]
            if l.img and l.img ~= "" then
                local rt = self.__render_texture[l.img]
                if rt then
                    renderLayer(self, l, rt)
                end
            end
            l:render()
        end
        if showboss then
            background.WarpEffectApply()
        end
    end
end

function bg:del()
    unloadRenderTexture(self)
end
bg.kill = bg.del
--endregion