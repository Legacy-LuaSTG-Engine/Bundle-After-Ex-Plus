---=====================================
---luastg stage background
---=====================================

----------------------------------------
---background

local input = require("foundation.input.core")
local key_repeated_activate = input.isBooleanActionRepeatedActivate

background = Class(object)

function background:init(is_sc_bg)
    self.group = GROUP_GHOST
    if is_sc_bg then
        self.layer = LAYER_BG
        self.alpha = 0
    else
        self.layer = LAYER_BG - 0.1
        self.alpha = 1
        if lstg.tmpvar.bg and IsValid(lstg.tmpvar.bg) then
            Del(lstg.tmpvar.bg)
        end
        lstg.tmpvar.bg = self
    end
end

function background:render()
    SetViewMode 'world'
    RenderClearViewMode(Color(0x00000000))
end

----------------------------------------
---辅助工具

camera_setter = Class(object)

function camera_setter:init()
    player.lock = true
    self.group = GROUP_GHOST
    self.text = { 'eye', 'at', 'up', 'fovy', 'z', 'fog', 'color' }
    self.nitem = { 3, 3, 3, 1, 2, 2, 3 }
    self.pos = 1
    self.posx = 1
    self.pos_changed = 0
    self.edit = false
end

function camera_setter:frame()
    if key_repeated_activate("shoot") then
        self.edit = true
        PlaySound('select00', 0.3)
        if not self.edit then
            self.posx = 1
        end
    end
    if key_repeated_activate("spell") then
        self.edit = false
        PlaySound('cancel00', 0.3)
    end
    if self.pos_changed > 0 then
        self.pos_changed = self.pos_changed - 1
    end
    if self.edit then
        local step = 0.1
        if KeyIsDown 'slow' then
            step = 0.01
        end
        if key_repeated_activate("left") then
            self.posx = self.posx - 1
            PlaySound('select00', 0.3)
        end
        if key_repeated_activate("right") then
            self.posx = self.posx + 1
            PlaySound('select00', 0.3)
        end
        self.posx = (self.posx - 1 + self.nitem[self.pos]) % self.nitem[self.pos] + 1
        if self.pos <= 3 or self.pos == 5 then
            local item = lstg.view3d[self.text[self.pos]]
            if key_repeated_activate("up") then
                item[self.posx] = item[self.posx] + step
                PlaySound('select00', 0.3)
            end
            if key_repeated_activate("down") then
                item[self.posx] = item[self.posx] - step
                PlaySound('select00', 0.3)
            end
        elseif self.pos == 6 then
            if key_repeated_activate("up") then
                lstg.view3d.fog[self.posx] = lstg.view3d.fog[self.posx] + step
                PlaySound('select00', 0.3)
                if lstg.view3d.fog[1] < -0.0001 then
                    if lstg.view3d.fog[1] > -0.9999 then
                        lstg.view3d.fog[1] = 0
                    elseif lstg.view3d.fog[1] > -1.9999 then
                        lstg.view3d.fog[1] = -1
                    end
                end
            end
            if key_repeated_activate("down") then
                lstg.view3d.fog[self.posx] = lstg.view3d.fog[self.posx] - step
                if lstg.view3d.fog[1] < -1.0001 then
                    lstg.view3d.fog[1] = -2
                elseif lstg.view3d.fog[1] < -0.0001 then
                    lstg.view3d.fog[1] = -1
                end
                PlaySound('select00', 0.3)
            end
            if abs(lstg.view3d.fog[1]) < 0.0001 then
                lstg.view3d.fog[1] = 0
            end
            if abs(lstg.view3d.fog[2]) < 0.0001 then
                lstg.view3d.fog[2] = 0
            end
        elseif self.pos == 7 then
            local c = {}
            local alpha
            local step = 10
            if KeyIsDown 'slow' then
                step = 1
            end
            alpha, c[1], c[2], c[3] = lstg.view3d.fog[3]:ARGB()
            if key_repeated_activate("up") then
                c[self.posx] = c[self.posx] + step
                PlaySound('select00', 0.3)
            end
            if key_repeated_activate("down") then
                c[self.posx] = c[self.posx] - step
                PlaySound('select00', 0.3)
            end
            c[self.posx] = max(0, min(c[self.posx], 255))
            lstg.view3d.fog[3] = Color(alpha, unpack(c))
        elseif self.pos == 4 then
            if key_repeated_activate("up") then
                lstg.view3d.fovy = lstg.view3d.fovy + step
                PlaySound('select00', 0.3)
            end
            if key_repeated_activate("down") then
                lstg.view3d.fovy = lstg.view3d.fovy - step
                PlaySound('select00', 0.3)
            end
        end
    else
        if key_repeated_activate("up") then
            self.pos = self.pos - 1
            self.pos_changed = ui.menu.shake_time
            PlaySound('select00', 0.3)
        end
        if key_repeated_activate("down") then
            self.pos = self.pos + 1
            self.pos_changed = ui.menu.shake_time
            PlaySound('select00', 0.3)
        end
        self.pos = (self.pos + 6) % 7 + 1
    end
    if KeyIsPressed 'special' then
        Print("--set camera")
        Print(string.format("Set3D('eye',%.2f,%.2f,%.2f)", unpack(lstg.view3d.eye)))
        Print(string.format("Set3D('at',%.2f,%.2f,%.2f)", unpack(lstg.view3d.at)))
        Print(string.format("Set3D('up',%.2f,%.2f,%.2f)", unpack(lstg.view3d.up)))
        Print(string.format("Set3D('fovy',%.2f)", lstg.view3d.fovy))
        Print(string.format("Set3D('z',%.2f,%.2f)", unpack(lstg.view3d.z)))
        Print(string.format("Set3D('fog',%.2f,%.2f,Color(%d,%d,%d,%d))", lstg.view3d.fog[1], lstg.view3d.fog[2], lstg.view3d.fog[3]:ARGB()))
        Print("--")
    end
end

local function _str(num)
    return string.format('%.2f', num)
end

function camera_setter:render()
    local y = 340
    SetViewMode 'ui'
    SetImageState('white', '', Color(0xFF000000))
    RenderRect('white', 424, 632, 256, 464)
    RenderTTF('sc_pr', 'camera setting', 528, 528, y + 4.5 * ui.menu.sc_pr_line_height, y + 4.5 * ui.menu.sc_pr_line_height, Color(255, unpack(ui.menu.title_color)), 'centerpoint')
    ui.DrawMenuTTF('sc_pr', '', self.text, self.pos, 432, y, 1, self.timer, self.pos_changed, 'left')
    local _a, _r, _g, _b = lstg.view3d.fog[3]:ARGB()
    ui.DrawMenuTTF('sc_pr', '', {
        _str(lstg.view3d.eye[1]),
        _str(lstg.view3d.at[1]),
        _str(lstg.view3d.up[1]),
        _str(lstg.view3d.fovy),
        _str(lstg.view3d.z[1]),
        _str(lstg.view3d.fog[1]),
        tostring(_r)
    }, self.pos, 496, y, 1, self.timer, self.pos_changed, 'right')
    ui.DrawMenuTTF('sc_pr', '', {
        _str(lstg.view3d.eye[2]),
        _str(lstg.view3d.at[2]),
        _str(lstg.view3d.up[2]),
        '',
        _str(lstg.view3d.z[2]),
        _str(lstg.view3d.fog[2]),
        tostring(_g)
    }, self.pos, 560, y, 1, self.timer, self.pos_changed, 'right')
    ui.DrawMenuTTF('sc_pr', '', {
        _str(lstg.view3d.eye[3]),
        _str(lstg.view3d.at[3]),
        _str(lstg.view3d.up[3]),
        '',
        '',
        '',
        tostring(_b)
    }, self.pos, 624, y, 1, self.timer, self.pos_changed, 'right')
    if self.edit and self.timer % 30 < 15 then
        RenderTTF('sc_pr', '_', 432 + self.posx * 64, 432 + self.posx * 64, y + (4 - self.pos) * ui.menu.sc_pr_line_height, y + (4 - self.pos) * ui.menu.sc_pr_line_height, Color(255, unpack(ui.menu.title_color)), 'right', 'vcenter', 'noclip')
    end
    SetViewMode 'world'
end

----------------------------------------
---一些效果

LoadFX('boss_distortion', 'shader/boss_distortion.hlsl')
CreateRenderTarget("_boss_distortion_render_buffer")

local RENDER_BUFFER_NAME = "_boss_distortion_render_buffer"
local WARP_EFFECT_NAME = "boss_distortion"

---开始捕获用于执行扭曲特效的画面
function background.WarpEffectCapture()
    if IsValid(_boss) then
        PushRenderTarget(RENDER_BUFFER_NAME)
        RenderClear(Color(0, 0, 0, 0))
    end
end

---停止捕获用于执行扭曲特效的画面并应用扭曲特效、绘制出来
function background.WarpEffectApply()
    if IsValid(_boss) then
        PopRenderTarget(RENDER_BUFFER_NAME)

        local x, y = WorldToScreen(_boss.x, _boss.y)
        local x1 = x * screen.scale
        local y1 = (screen.height - y) * screen.scale
        local fxr = _boss.fxr or 163
        local fxg = _boss.fxg or 73
        local fxb = _boss.fxb or 164
        PostEffect(WARP_EFFECT_NAME, RENDER_BUFFER_NAME, 6, "",
            {
                { x1, y1, 0.0, 0.0 }, -- centerX, centerY, 后面两个 0 只是用于填充成 float4
                { fxr / 255.0, fxg / 255.0, fxb / 255.0, 125.0 / 255.0 }, -- color
                {
                    _boss.aura_alpha * 200 * lstg.scale_3d, -- size
                    1500 * _boss.aura_alpha / 128 * lstg.scale_3d, -- arg
                    _boss.aura_alpha * 200 * lstg.scale_3d, -- colorsize
                    _boss.ani, -- timer
                },
            },
            {}
        )
    end
end

function background.ClearToFogColor()
    RenderClearViewMode(lstg.view3d.fog[3])
end

----------------------------------------
---其他

Include("THlib/background/default_stage_background.lua")
Include("THlib/background/spellcard_background.lua")
Include("THlib/background/default_spellcard_background.lua")
