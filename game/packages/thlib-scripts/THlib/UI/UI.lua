Include "THlib/UI/uiconfig.lua"
Include "THlib/UI/font.lua"
Include "THlib/UI/title.lua"
Include "THlib/UI/sc_pr.lua"

ui = {}

LoadTexture("boss_ui", "THlib/UI/boss_ui.png")
LoadImage("boss_spell_name_bg", "boss_ui", 0, 0, 256, 36)
SetImageCenter("boss_spell_name_bg", 256, 0)

LoadImage("boss_pointer", "boss_ui", 0, 64, 48, 16)
SetImageCenter("boss_pointer", 24, 0)

LoadImage("boss_sc_left", "boss_ui", 64, 64, 32, 32)
SetImageState("boss_sc_left", "", Color(0xFF80FF80))

LoadTexture("hint", "THlib/UI/hint.png", true)
LoadImage("hint.bonusfail", "hint", 0, 64, 256, 64)
LoadImage("hint.getbonus", "hint", 0, 128, 396, 64)
LoadImage("hint.extend", "hint", 0, 192, 160, 64)
LoadImage("hint.power", "hint", 0, 12, 84, 32)
LoadImage("hint.graze", "hint", 86, 12, 74, 32)
LoadImage("hint.point", "hint", 160, 12, 120, 32)
LoadImage("hint.life", "hint", 288, 0, 16, 15)
LoadImage("hint.lifeleft", "hint", 304, 0, 16, 15)
LoadImage("hint.bomb", "hint", 320, 0, 16, 16)
LoadImage("hint.bombleft", "hint", 336, 0, 16, 16)
LoadImage("kill_time", "hint", 232, 200, 152, 56, 16, 16)
SetImageCenter("hint.power", 0, 16)
SetImageCenter("hint.graze", 0, 16)
SetImageCenter("hint.point", 0, 16)
LoadImageGroup("lifechip", "hint", 288, 16, 16, 15, 4, 1, 0, 0)
LoadImageGroup("bombchip", "hint", 288, 32, 16, 16, 4, 1, 0, 0)
LoadImage("hint.hiscore", "hint", 424, 8, 80, 20)
LoadImage("hint.score", "hint", 424, 30, 64, 20)
LoadImage("hint.Pnumber", "hint", 352, 8, 56, 20)
LoadImage("hint.Bnumber", "hint", 352, 30, 72, 20)
LoadImage("hint.Cnumber", "hint", 352, 52, 40, 20)
SetImageCenter("hint.hiscore", 0, 10)
SetImageCenter("hint.score", 0, 10)
SetImageCenter("hint.Pnumber", 0, 10)
SetImageCenter("hint.Bnumber", 0, 10)

LoadTexture("line", "THlib/UI/line.png", true)
LoadImageGroup("line_", "line", 0, 0, 200, 8, 1, 7, 0, 0)

LoadTexture("ui_rank", "THlib/UI/rank.png")
LoadImage("rank_Easy", "ui_rank", 0, 0, 144, 32)
LoadImage("rank_Normal", "ui_rank", 0, 32, 144, 32)
LoadImage("rank_Hard", "ui_rank", 0, 64, 144, 32)
LoadImage("rank_Lunatic", "ui_rank", 0, 96, 144, 32)
LoadImage("rank_Extra", "ui_rank", 0, 128, 144, 32)

ui.menu = {
    font_size = 0.625,
    line_height = 24,
    char_width = 20,
    num_width = 12.5,
    title_color = { 255, 255, 255 },
    unfocused_color = { 128, 128, 128 },
    --	unfocused_color={255,255,255},
    focused_color1 = { 255, 255, 255 },
    focused_color2 = { 255, 192, 192 },
    blink_speed = 7,
    shake_time = 9,
    shake_speed = 40,
    shake_range = 3,
    sc_pr_line_per_page = 12,
    sc_pr_line_height = 22,
    sc_pr_width = 320,
    sc_pr_margin = 8,
    rep_font_size = 0.6,
    rep_line_height = 20,
}

function ui.DrawMenu(title, text, pos, x, y, alpha, timer, shake, align)
    align = align or "center"
    local yos
    if title == "" then
        yos = (#text + 1) * ui.menu.line_height * 0.5
    else
        yos = (#text - 1) * ui.menu.line_height * 0.5
        SetFontState("menu", "", Color(alpha * 255, unpack(ui.menu.title_color)))
        RenderText("menu", title, x, y + yos + ui.menu.line_height, ui.menu.font_size, align, "vcenter")
    end
    for i = 1, #text do
        if i == pos then
            local color = {}
            local k = cos(timer * ui.menu.blink_speed) ^ 2
            for j = 1, 3 do
                color[j] = ui.menu.focused_color1[j] * k + ui.menu.focused_color2[j] * (1 - k)
            end

            local xos = ui.menu.shake_range * sin(ui.menu.shake_speed * shake)

            SetFontState("menu", "", Color(alpha * 255, unpack(color)))
            RenderText("menu", text[i], x + xos, y - i * ui.menu.line_height + yos, ui.menu.font_size, align, "vcenter")
            --	RenderTTF("menuttf",text[i],x+xos+2,x+xos+2,y-i*ui.menu.line_height+yos,y-i*ui.menu.line_height+yos,Color(alpha*255,0,0,0),"centerpoint")
            --	RenderTTF("menuttf",text[i],x+xos,x+xos,y-i*ui.menu.line_height+yos,y-i*ui.menu.line_height+yos,Color(alpha*255,unpack(color)),"centerpoint")
        else
            SetFontState("menu", "", Color(alpha * 255, unpack(ui.menu.unfocused_color)))
            RenderText("menu", text[i], x, y - i * ui.menu.line_height + yos, ui.menu.font_size, align, "vcenter")
            --	RenderTTF("menuttf",text[i],x+2,x+2,y-i*ui.menu.line_height+yos,y-i*ui.menu.line_height+yos,Color(alpha*255,0,0,0),"centerpoint")
            --	RenderTTF("menuttf",text[i],x,x,y-i*ui.menu.line_height+yos,y-i*ui.menu.line_height+yos,Color(alpha*255,unpack(ui.menu.unfocused_color)),"centerpoint")
        end
    end
end

function ui.DrawMenuTTF(ttfname, title, text, pos, x, y, alpha, timer, shake, align)
    align = align or "center"
    local yos
    if title == "" then
        yos = (#text + 1) * ui.menu.sc_pr_line_height * 0.5
    else
        yos = (#text - 1) * ui.menu.sc_pr_line_height * 0.5
        RenderTTF(ttfname, title, x, x, y + yos + ui.menu.sc_pr_line_height, y + yos + ui.menu.sc_pr_line_height, Color(alpha * 255, unpack(ui.menu.title_color)), align, "vcenter", "noclip")
    end
    for i = 1, #text do
        if i == pos then
            local color = {}
            local k = cos(timer * ui.menu.blink_speed) ^ 2
            for j = 1, 3 do
                color[j] = ui.menu.focused_color1[j] * k + ui.menu.focused_color2[j] * (1 - k)
            end
            local xos = ui.menu.shake_range * sin(ui.menu.shake_speed * shake)
            RenderTTF(ttfname, text[i], x + xos, x + xos, y - i * ui.menu.sc_pr_line_height + yos, y - i * ui.menu.sc_pr_line_height + yos, Color(alpha * 255, unpack(color)), align, "vcenter", "noclip")
        else
            RenderTTF(ttfname, text[i], x, x, y - i * ui.menu.sc_pr_line_height + yos, y - i * ui.menu.sc_pr_line_height + yos, Color(alpha * 255, unpack(ui.menu.unfocused_color)), align, "vcenter", "noclip")
        end
    end
end

function ui.DrawMenuTTFBlack(ttfname, title, text, pos, x, y, alpha, timer, shake, align)
    align = align or "center"
    local yos
    if title == "" then
        yos = (#text + 1) * ui.menu.sc_pr_line_height * 0.5
    else
        yos = (#text - 1) * ui.menu.sc_pr_line_height * 0.5
        RenderTTF(ttfname, title, x, x, y + yos + ui.menu.sc_pr_line_height, y + yos + ui.menu.sc_pr_line_height, Color(0xFF000000), align, "vcenter", "noclip")
    end
    for i = 1, #text do
        if i == pos then
            local xos = ui.menu.shake_range * sin(ui.menu.shake_speed * shake)
            RenderTTF(ttfname, text[i], x + xos, x + xos, y - i * ui.menu.sc_pr_line_height + yos, y - i * ui.menu.sc_pr_line_height + yos, Color(0xFF000000), align, "vcenter", "noclip")
        else
            RenderTTF(ttfname, text[i], x, x, y - i * ui.menu.sc_pr_line_height + yos, y - i * ui.menu.sc_pr_line_height + yos, Color(0xFF000000), align, "vcenter", "noclip")
        end
    end
end

function ui.DrawRepText(ttfname, title, text, pos, x, y, alpha, timer, shake)
    local yos
    if title == "" then
        yos = (#text + 1) * ui.menu.sc_pr_line_height * 0.5
    else
        yos = (#text - 1) * ui.menu.sc_pr_line_height * 0.5
        Render(title, x, y + ui.menu.sc_pr_line_height + yos)
        --		RenderTTF(ttfname,title,x,x,y+yos+ui.menu.sc_pr_line_height+1,y+yos+ui.menu.sc_pr_line_height-1,Color(0xFF000000),"center","vcenter","noclip")
        --		RenderTTF(ttfname,title,x,x,y+yos+ui.menu.sc_pr_line_height,y+yos+ui.menu.sc_pr_line_height,Color(255,unpack(ui.menu.title_color)),"center","vcenter","noclip")
    end
    local _text = text
    local xos = { -300, -240, -120, 20, 130, 240 }
    for i = 1, #_text do
        if i == pos then
            local color = {}
            local k = cos(timer * ui.menu.blink_speed) ^ 2
            for j = 1, 3 do
                color[j] = ui.menu.focused_color1[j] * k + ui.menu.focused_color2[j] * (1 - k)
            end
            --			local xos=ui.menu.shake_range*sin(ui.menu.shake_speed*shake)
            SetFontState("replay", "", Color(0xFFFFFF30))
            --			RenderTTF(ttfname,text[i],x+xos,x+xos,y-i*ui.menu.sc_pr_line_height+yos,y-i*ui.menu.sc_pr_line_height+yos,Color(alpha*255,unpack(color)),align,"vcenter","noclip")
            for m = 1, 6 do
                RenderText("replay", _text[i][m], x + xos[m], y - i * ui.menu.rep_line_height + yos, ui.menu.rep_font_size, "vcenter", "left")
            end
        else
            SetFontState("replay", "", Color(0xFF808080))
            --			RenderTTF(ttfname,text[i],x,x,y-i*ui.menu.sc_pr_line_height+yos,y-i*ui.menu.sc_pr_line_height+yos,Color(alpha*255,unpack(ui.menu.unfocused_color)),align,"vcenter","noclip")
            for m = 1, 6 do
                RenderText("replay", _text[i][m], x + xos[m], y - i * ui.menu.rep_line_height + yos, ui.menu.rep_font_size, "vcenter", "left")
            end
        end
    end
end

function ui.DrawRepText2(ttfname, title, text, pos, x, y, alpha, timer, shake)
    local yos
    if title == "" then
        yos = (#text + 1) * ui.menu.sc_pr_line_height * 0.5
    else
        yos = (#text - 1) * ui.menu.sc_pr_line_height * 0.5
        Render(title, x, y + ui.menu.sc_pr_line_height + yos)
        --		RenderTTF(ttfname,title,x,x,y+yos+ui.menu.sc_pr_line_height+1,y+yos+ui.menu.sc_pr_line_height-1,Color(0xFF000000),"center","vcenter","noclip")
        --		RenderTTF(ttfname,title,x,x,y+yos+ui.menu.sc_pr_line_height,y+yos+ui.menu.sc_pr_line_height,Color(255,unpack(ui.menu.title_color)),"center","vcenter","noclip")
    end
    local _text = text
    local xos = { -80, 120 }
    for i = 1, #_text do
        if i == pos then
            local color = {}
            local k = cos(timer * ui.menu.blink_speed) ^ 2
            for j = 1, 3 do
                color[j] = ui.menu.focused_color1[j] * k + ui.menu.focused_color2[j] * (1 - k)
            end
            --			local xos=ui.menu.shake_range*sin(ui.menu.shake_speed*shake)
            SetFontState("replay", "", Color(0xFFFFFF30))
            --			RenderTTF(ttfname,text[i],x+xos,x+xos,y-i*ui.menu.sc_pr_line_height+yos,y-i*ui.menu.sc_pr_line_height+yos,Color(alpha*255,unpack(color)),align,"vcenter","noclip")
            RenderText("replay", _text[i][1], x + xos[1], y - i * ui.menu.rep_line_height + yos, ui.menu.rep_font_size, "vcenter", "center")
            RenderText("replay", _text[i][2], x + xos[2], y - i * ui.menu.rep_line_height + yos, ui.menu.rep_font_size, "vcenter", "right")
        else
            SetFontState("replay", "", Color(0xFF808080))
            --			RenderTTF(ttfname,text[i],x,x,y-i*ui.menu.sc_pr_line_height+yos,y-i*ui.menu.sc_pr_line_height+yos,Color(alpha*255,unpack(ui.menu.unfocused_color)),align,"vcenter","noclip")
            RenderText("replay", _text[i][1], x + xos[1], y - i * ui.menu.rep_line_height + yos, ui.menu.rep_font_size, "vcenter", "center")
            RenderText("replay", _text[i][2], x + xos[2], y - i * ui.menu.rep_line_height + yos, ui.menu.rep_font_size, "vcenter", "right")
        end
    end
end

local function formatnum(num)
    local sign = sign(num)
    num = abs(num)
    local tmp = {}
    local var
    while num >= 1000 do
        var = num - int(num / 1000) * 1000
        table.insert(tmp, 1, string.format("%03d", var))
        num = int(num / 1000)
    end
    table.insert(tmp, 1, tostring(num))
    var = table.concat(tmp, ",")
    if sign < 0 then
        var = string.format("-%s", var)
    end
    return var, #tmp - 1
end
function RenderScore(fontname, score, x, y, size, mode)
    if score < 100000000000 then
        RenderText(fontname, formatnum(score), x, y, size, mode)
    else
        RenderText(fontname, string.format("99,999,999,999"), x, y, size, mode)
    end
end

---@class lstg.lstg_ui_object
lstg.lstg_ui_object = Class(object)
function lstg.lstg_ui_object:init()
    _lstg_ui = self
    self.layer = LAYER_TOP + 1
    if lstg.ui then
        self.ui = lstg.ui
    else
        lstg.ui = lstg.lstg_ui()
        self.ui = lstg.ui
    end
end
function lstg.lstg_ui_object:frame()
    task.Do(self)
end
function lstg.lstg_ui_object:render()
    self.ui:drawFrame()
    self.ui:drawScore()
end

---@class lstg.lstg_ui
---@return lstg.lstg_ui
lstg.lstg_ui = plus.Class()
local lstg_ui = lstg.lstg_ui

local res_list = {
    ["tex"] = {
        "logo",
        "ui_bg",
        "ui_bg2",
        "menu_bg",
        "menu_bg2",
        integer = 1,
    },
    ["img"] = {
        "logo",
        "ui_bg",
        "ui_bg2",
        "menu_bg",
        "menu_bg2",
        integer = 2,
    },
}
function lstg_ui:reloadUI()
    for type, list in pairs(res_list) do
        for _, res in pairs(list) do
            if CheckRes(type, res) == "global" then
                RemoveResource("global", list.integer, res)
            end
        end
    end
    local pool = GetResourceStatus() or "global"
    SetResourceStatus("global")
    if self.type == 1 then
        LoadImageFromFile("logo", "THlib/UI/logo.png")
        SetImageCenter("logo", 0, 0)
        LoadImageFromFile("ui_bg", "THlib/UI/ui_bg.png")
        LoadImageFromFile("menu_bg", "THlib/UI/menu_bg.png")
    elseif self.type == 2 then
        LoadImageFromFile("logo", "THlib/UI/logo.png")
        SetImageCenter("logo", 0, 0)
        LoadImageFromFile("ui_bg", "THlib/UI/ui_bg.png")
        LoadImageFromFile("ui_bg2", "THlib/UI/ui_bg_2.png")
        LoadImageFromFile("menu_bg", "THlib/UI/menu_bg.png")
        LoadImageFromFile("menu_bg2", "THlib/UI/menu_bg_2.png")
    end
    SetResourceStatus(pool)
end
function lstg_ui:init()
    if setting.resx > setting.resy then
        self.type = 1
    else
        self.type = 2
    end
    self:reloadUI()
end
function lstg_ui:drawFrame()
    self["drawFrame" .. self.type](self)
end
function lstg_ui:drawFrame1()
    SetViewMode "ui"
    local w = lstg.world
    local x = (w.scrr - w.scrl) / 2 + w.scrl
    local y = (w.scrt - w.scrb) / 2 + w.scrb
    local hs = (w.scrr - w.scrl) / 384
    local vs = (w.scrt - w.scrb) / 448
    x = x + 96 * hs
    if CheckRes("img", "image:UI_img") then
        Render("image:UI_img", x, y, 0, hs, vs)
    else
        Render("ui_bg", x, y, 0, hs, vs)
    end
    if CheckRes("img", "image:LOGO_img") then
        Render("image:LOGO_img", -16 + w.scrr, 150, 0, 0.5, 0.5)
    else
        Render("logo", -16 + w.scrr, 150, 0, 0.5, 0.5)
    end
    SetFontState("menu", "", Color(0xFFFFFFFF))
    RenderText("menu",
            string.format("%.1ffps", GetFPS()),
            220 + w.scrr, 1, 0.25, "right", "bottom")
    SetViewMode "world"
end
function lstg_ui:drawFrame2()
    SetViewMode "ui"
    Render("ui_bg2", 198, 264)
    SetViewMode "world"
end
function lstg_ui:drawMenuBG()
    self["drawMenuBG" .. self.type](self)
end
function lstg_ui:drawMenuBG1()
    SetViewMode "ui"
    Render("menu_bg", 320, 240)
    SetFontState("menu", "", Color(0xFFFFFFFF))
    RenderText("menu",
            string.format("%.1ffps", GetFPS()),
            636, 1, 0.25, "right", "bottom")
    SetViewMode "world"
end
function lstg_ui:drawMenuBG2()
    SetViewMode "ui"
    Render("menu_bg2", 198, 264)
    SetFontState("menu", "", Color(0xFFFFFFFF))
    RenderText("menu",
            string.format("%.1ffps", GetFPS()),
            392, 1, 0.25, "right", "bottom")
    SetViewMode "world"
end
function lstg_ui:ScoreUpdate()
    local var = lstg.var
    local cur_score = var.score
    local score = self.score or cur_score
    local score_tmp = self.score_tmp or cur_score
    if score_tmp < cur_score then
        if cur_score - score_tmp <= 100 then
            score = score + 10
        elseif cur_score - score_tmp <= 1000 then
            score = score + 100
        else
            score = int(score / 10 + int((cur_score - score_tmp) / 600)) * 10 + cur_score % 10
        end
    end
    if score_tmp > cur_score then
        score_tmp = cur_score
        score = cur_score
    end
    if score >= cur_score then
        score_tmp = cur_score
        score = cur_score
    end
    self.score = score
    self.score_tmp = score_tmp
end
function lstg_ui:drawScore()
    self:ScoreUpdate()
    self["drawScore" .. self.type](self)
end
function lstg_ui:drawScore1()
    SetViewMode "ui"
    self:drawDifficulty()
    self:drawInfo1()
    SetViewMode "world"
end
function lstg_ui:drawScore2()
    SetViewMode "ui"
    self:drawInfo2()
    SetViewMode "world"
end
function lstg_ui:drawDifficulty()
    SetFontState("score3", "", Color(0xFFADADAD))
    local w = lstg.world
    local diff = string.match(stage.current_stage.name, "[%w_][%w_ ]*$")
    local diffimg = CheckRes("img", "image:diff_" .. diff)
    if diffimg then
        Render("image:diff_" .. diff, 112 + w.scrr, 448)
    else
        --by OLC，难度显示加入符卡练习
        if ext.sc_pr and diff == "Spell Practice" and lstg.var.sc_index then
            diff = _editor_class[_sc_table[lstg.var.sc_index][1]].difficulty
            if diff == "All" then
                diff = "SpellCard"
            end
        end
        local x1 = -192 + w.scrr
        local x2 = 112 + w.scrr
        local y1 = 457
        local y2 = 448
        local dy = 22
        local s = stage.current_stage
        local timer = s.timer
        local a, t = 255, 1
        local x, y = x2, y2
        if lstg.var.is_parctice or s.number == 1 then
            if timer < 60 then
                x, y = x1, y1
                dy = 11
                a = int(timer / 4) % 2 * 255
            elseif timer >= 60 and timer < 150 then
                x, y = x1, y1
                dy = 11
            elseif timer >= 150 and timer < 158 then
                x, y = x1, y1
                dy = 11
                t = max((1 - (timer - 150) / 8), 0)
                a = t * 255
            elseif timer >= 158 and timer < 165 then
                t = min((timer - 158) / 9, 1)
                a = t * 255
            end
        end
        if diff == "Easy" or diff == "Normal" or diff == "Hard" or diff == "Lunatic" or diff == "Extra" then
            SetImageState("rank_" .. diff, "", Color(a, 255, 255, 255))
            Render("rank_" .. diff, x, y, 0, 0.5, t * 0.5)
        else
            SetFontState("menu", "", Color(a, 255, 255, 255))
            RenderText("menu", diff, x, y + dy, 0.5, "center")
        end
    end
end
function lstg_ui:drawInfo1()
    local w = lstg.world
    local RenderImgList = {
        { "line_1", 109 + w.scrr, 419, 0, 1, 1 },
        { "line_2", 109 + w.scrr, 397, 0, 1, 1 },
        { "line_3", 109 + w.scrr, 349, 0, 1, 1 },
        { "line_4", 109 + w.scrr, 311, 0, 1, 1 },
        { "line_5", 109 + w.scrr, 247, 0, 1, 1 },
        { "line_6", 109 + w.scrr, 224, 0, 1, 1 },
        { "line_7", 109 + w.scrr, 202, 0, 1, 1 },
        { "hint.hiscore", 12 + w.scrr, 425, 0, 1, 1 },
        { "hint.score", 12 + w.scrr, 403, 0, 1, 1 },
        { "hint.Pnumber", 12 + w.scrr, 371, 0, 1, 1 },
        { "hint.Bnumber", 12 + w.scrr, 334, 0, 1, 1 },
        { "hint.Cnumber", 138 + w.scrr, 316, 0, 0.85, 0.85 },
        { "hint.Cnumber", 138 + w.scrr, 354, 0, 0.85, 0.85 },
        { "hint.power", 39 + w.scrr, 253, 0, 0.5, 0.5 },
        { "hint.point", 39 + w.scrr, 230, 0, 0.5, 0.5 },
        { "hint.graze", 54 + w.scrr, 208, 0, 0.5, 0.5 }
    }
    local s = stage.current_stage
    local timer = s.timer
    local alplat
    if (lstg.var.is_parctice or s.number == 1) and timer < 448 then
        local alpharate = 4
        local alphatrate = 1
        local timerrate = 3
        local y0 = 448 - timer * timerrate
        local dyt = max(300 - y0, 0)
        for i = 1, #RenderImgList do
            local p1, p2, p3, p4, p5, p6 = unpack(RenderImgList[i])
            local dy = max(p3 - y0, 0)
            local alpha = min(dy * alpharate, 255)
            local dw = 1
            if string.find(p1, "line_") then
                dw = alpha / 255
            end
            SetImageState(p1, "", Color(alpha, 255, 255, 255))
            Render(p1, p2, p3, p4, p5 * dw, p6)
        end
        alplat = min(dyt * alphatrate, 255)
    else
        for i = 1, #RenderImgList do
            local p1, p2, p3, p4, p5, p6 = unpack(RenderImgList[i])
            SetImageState(p1, "", Color(255, 255, 255, 255))
            Render(p1, p2, p3, p4, p5, p6)
        end
        alplat = 255
    end
    SetFontState("score3", "", Color(alplat, 173, 173, 173))
    RenderScore("score3", max(lstg.tmpvar.hiscore or 0, self.score or 0), 216 + w.scrr, 436, 0.43, "right")
    SetFontState("score3", "", Color(alplat, 255, 255, 255))
    RenderScore("score3", self.score or 0, 216 + w.scrr, 414, 0.43, "right")
    RenderText("score3", string.format("%d/5", lstg.var.chip), 214 + w.scrr, 361, 0.35, "right")
    RenderText("score3", string.format("%d/5", lstg.var.bombchip), 214 + w.scrr, 323, 0.35, "right")
    SetFontState("score1", "", Color(alplat, 205, 102, 0))
    SetFontState("score2", "", Color(alplat, 34, 216, 221))
    RenderText("score1", string.format("%d.    /4.    ", math.floor(lstg.var.power / 100)), 204 + w.scrr, 262, 0.4, "right")
    RenderText("score1", string.format("      %d%d        00", math.floor((lstg.var.power % 100) / 10), lstg.var.power % 10), 205 + w.scrr, 258.5, 0.3, "right")
    RenderScore("score2", lstg.var.pointrate, 204 + w.scrr, 239, 0.4, "right")
    SetFontState("score3", "", Color(alplat, 173, 173, 173))
    RenderText("score3", string.format("%d", lstg.var.graze), 204 + w.scrr, 216, 0.4, "right")
    SetImageState("hint.life", "", Color(alplat, 255, 255, 255))
    for i = 1, 8 do
        Render("hint.life", 89 + w.scrr + 13 * i, 371, 0, 1, 1)
    end
    SetImageState("hint.lifeleft", "", Color(alplat, 255, 255, 255))
    for i = 1, lstg.var.lifeleft do
        Render("hint.lifeleft", 89 + w.scrr + 13 * i, 371, 0, 1, 1)
    end
    SetImageState("hint.bomb", "", Color(alplat, 255, 255, 255))
    for i = 1, 8 do
        Render("hint.bomb", 89 + w.scrr + 13 * i, 334, 0, 1, 1)
    end
    SetImageState("hint.bombleft", "", Color(alplat, 255, 255, 255))
    for i = 1, lstg.var.bomb do
        Render("hint.bombleft", 89 + w.scrr + 13 * i, 334, 0, 1, 1)
    end
    local Lchip = lstg.var.chip
    if Lchip > 0 and Lchip < 5 and lstg.var.lifeleft < 8 then
        SetImageState("lifechip" .. Lchip, "", Color(alplat, 255, 255, 255))
        Render("lifechip" .. Lchip, 89 + w.scrr + 13 * (lstg.var.lifeleft + 1), 371, 0, 1, 1)
    end
    local Bchip = lstg.var.bombchip
    if Bchip > 0 and Bchip < 5 and lstg.var.bomb < 8 then
        SetImageState("bombchip" .. Bchip, "", Color(alplat, 255, 255, 255))
        Render("bombchip" .. Bchip, 89 + w.scrr + 13 * (lstg.var.bomb + 1), 334, 0, 1, 1)
    end
    SetFontState("score3", "", Color(alplat, 173, 173, 173))
    RenderScore("score3", max(lstg.tmpvar.hiscore or 0, self.score or 0), 216 + w.scrr, 436, 0.43, "right")
    SetFontState("score3", "", Color(alplat, 255, 255, 255))
    RenderScore("score3", self.score or 0, 216 + w.scrr, 414, 0.43, "right")
    RenderText("score3", string.format("%d/5", lstg.var.chip), 214 + w.scrr, 361, 0.35, "right")
    RenderText("score3", string.format("%d/5", lstg.var.bombchip), 214 + w.scrr, 323, 0.35, "right")
    SetFontState("score1", "", Color(alplat, 205, 102, 0))
    SetFontState("score2", "", Color(alplat, 34, 216, 221))
    RenderText("score1", string.format("%d.    /4.    ", math.floor(lstg.var.power / 100)), 204 + w.scrr, 262, 0.4, "right")
    RenderText("score1", string.format("      %d%d        00", math.floor((lstg.var.power % 100) / 10), lstg.var.power % 10), 205 + w.scrr, 258.5, 0.3, "right")
    RenderScore("score2", lstg.var.pointrate, 204 + w.scrr, 239, 0.4, "right")
    SetFontState("score3", "", Color(alplat, 255, 255, 255))
    RenderText("score3", string.format("%d", lstg.var.graze), 204 + w.scrr, 216, 0.4, "right")
end
function lstg_ui:drawInfo2()
    RenderText("score", "HiScore", 8, 520, 0.5, "left", "top")
    RenderText("score",
            string.format("%d", max(lstg.tmpvar.hiscore or 0, lstg.var.score)),
            190, 520, 0.5, "right", "top")
    RenderText("score", "Score", 206, 520, 0.5, "left", "top")
    RenderText("score",
            string.format("%d", lstg.var.score),
            388, 520, 0.5, "right", "top")
    SetFontState("score", "", Color(0xFFFF4040))
    RenderText("score",
            string.format("%1.2f", lstg.var.power / 100),
            8, 496, 0.5, "left", "top")
    SetFontState("score", "", Color(0xFF40FF40))
    RenderText("score",
            string.format("%d", lstg.var.faith),
            84, 496, 0.5, "left", "top")
    SetFontState("score", "", Color(0xFF4040FF))
    RenderText("score",
            string.format("%d", lstg.var.pointrate),
            160, 496, 0.5, "left", "top")
    SetFontState("score", "", Color(0xFFFFFFFF))
    RenderText("score",
            string.format("%d", lstg.var.graze),
            236, 496, 0.5, "left", "top")
    RenderText("score",
            string.rep("*", max(0, lstg.var.lifeleft)),
            388, 496, 0.5, "right", "top")
    RenderText("score",
            string.rep("*", max(0, lstg.var.bomb)),
            380, 490, 0.5, "right", "top")
end

function ResetUI()
    lstg.ui = lstg.lstg_ui()
    function ui.DrawFrame()
    end
    function ui.DrawMenuBG()
        if lstg.ui then
            lstg.ui:drawMenuBG()
        end
    end
    function ui.DrawScore()
        if not IsValid(_lstg_ui) then
            New(lstg.lstg_ui_object)
        end
    end
end

ResetUI()