--======================================
--th style boss dialog
--======================================

----------------------------------------
local align_f = {
    [0] = function(w, h)
        return 0, -h / 2
    end,
    [1] = function(w, h)
        return -w / 2, -h / 2
    end,
    [2] = function(w, h)
        return -w, -h / 2
    end,
    [4] = function(w, h)
        return 0, 0
    end,
    [5] = function(w, h)
        return -w / 2, 0
    end,
    [6] = function(w, h)
        return -w, 0
    end,
    [8] = function(w, h)
        return 0, h / 2
    end,
    [9] = function(w, h)
        return -w / 2, h / 2
    end,
    [10] = function(w, h)
        return -w, h / 2
    end,
}
local TTFDrawer = plus.Class()
function TTFDrawer:init(str)
    self.spstring = sp.string(str)
    self.line = self:getLine()
end
function TTFDrawer:set(str)
    self.spstring:Set(str)
    self.line = self:getLine()
end
function TTFDrawer:getLine()
    local line = 1
    for _, c in ipairs(self.spstring.string) do
        if c == "\n" then
            line = line + 1
        end
    end
    return line
end
function TTFDrawer:render(font, x, y, cw, ch, dx, dy, scale, color, align)
    cw, ch = cw * scale / 2, ch * scale / 2
    local s = self.spstring.string
    local w = self.spstring:GetLength() * cw
    local h = ch * self.line
    local _w, _h = align_f[align](w, h)
    local _align = "center"
    local _x, _y = x + _w, y + _h
    local line = 0
    local n
    dx, dy = dx / 2, dy / 2
    for i = 1, #s do
        if s[i] == "\n" then
            line = line + 1
            _x = x + _w
            _y = y + _h - ch * line
        else
            n = #s[i] > 1
            if n then
                _x = _x + cw + dx
            else
                _x = _x + cw / 2 + dx
            end
            _y = _y + dy
            RenderTTF2(font, s[i], _x, _x, _y, _y, scale, color, _align)
            if n then
                _x = _x + cw + dx
            else
                _x = _x + cw / 2 + dx
            end
            _y = _y + dy
        end
    end
end

----------------------------------------
--boss dialog
--！警告：未适配多玩家，一部分逻辑代码从编辑器中生成，需要相应去修改编辑器
--#待改进：_dialog_can_skip不应该使用全局变量，其逻辑代码从编辑器中生成，需要相应去修改编辑器

local boss = boss
boss.dialog = {}

---boss对话阶段
---@param can_skip boolean @是否可跳过
---@return boss.card
function boss.dialog.New(can_skip)
    local c = {}
    c.frame = boss.dialog.frame
    c.render = boss.dialog.render
    c.init = boss.dialog.init
    c.del = boss.dialog.del
    c.name = ""
    c.t1 = 999999999
    c.t2 = 999999999
    c.t3 = 999999999
    c.hp = 999999999
    c.is_sc = false
    c.is_extra = false
    c.is_combat = false
    _dialog_can_skip = can_skip--怎么是全局变量？？？
    return c
end
function boss.dialog:init()
    lstg.player.dialog = true
    self.dialog_displayer = New(dialog_displayer)
end
function boss.dialog:frame()
    if self.task and coroutine.status(self.task[1]) == "dead" then
        Kill(self)
    end
end
function boss.dialog:render()
end
function boss.dialog:del()
    lstg.player.dialog = false
    Del(self.dialog_displayer)
    self.dialog_displayer = nil
end

----------------------------------------
--boss dialog displayer
--！警告：未适配宽屏等非传统版面
dialog_displayer = Class(object)
function dialog_displayer:init(p_dialog)
    self.layer = LAYER_TOP + 9
    self.char = {}
    self.char[1] = {}
    self.char[-1] = {}
    self._hscale = {}
    self._vscale = {}
    self.balloon = {}
    self.t = 16
    self.death = 0
    self.co = 0
    self.jump_dialog = 0
    self.p_dialog = p_dialog
    self.active = false --active到底是个什么沙雕东西？？？？？？
    if self.p_dialog then
        local players
        if Players then
            players = Players(self)
        else
            players = { player }
        end
        for _, p in pairs(players) do
            p.dialog = true
        end
    end
end
function dialog_displayer:frame()
    task.Do(self)
    if self.t > 0 then
        self.t = self.t - 1
    end
    local players
    local dialog, shoot
    if Players then
        players = Players(self)
    else
        players = { player }
    end
    for _, p in pairs(players) do
        dialog = p.dialog or dialog
        if p.key then
            shoot = p.key["shoot"] or shoot
        else
            shoot = KeyIsDown "shoot" or shoot
        end
    end
    if dialog and self.active == true then
        if shoot then
            self.jump_dialog = self.jump_dialog + 1
        else
            self.jump_dialog = 0
        end
    end
end
function dialog_displayer:render()
end
function dialog_displayer:del()
    local unit_list = { self.char[-1], self.char[1], self.balloon }
    for _, list in ipairs(unit_list) do
        for _, unit in pairs(list) do
            if IsValid(unit) then
                Del(unit)
            end
        end
    end
    task.New(self, function()
        task.Wait(30)
        local players
        if Players then
            players = Players(self)
        else
            players = { player }
        end
        for _, p in pairs(players) do
            p.dialog = false
        end
        RawDel(self)
    end)
end

----------------------------------------
--boss dialog sentence

---boss对话语句气泡
---@param img string @显示图像
---@param pos string @显示方位
---@param text string @文本语句
---@param t number @语句时长
---@param hscale number @图像横向缩放比
---@param vscale number @图像纵向缩放比
---@param tpic number @气泡样式
---@param num string|number @方位图像编号
---@param px number @方位图像x坐标(ADD UP
---@param py number @方位图像y坐标(ADD UP
---@param tx number @气泡x坐标(ADD UP
---@param ty number @气泡y坐标(ADD UP
---@param tn number @语句保留条数
---@param stay boolean @对话后是否保持激活
function boss.dialog:sentence(img, pos, text, t, hscale, vscale, tpic, num, px, py, tx, ty, tn, stay)
    if pos == "left" then
        pos = 1
    else
        pos = -1
    end
    num = num or 1
    px = px or (230 - pos * 150)
    py = py or 128
    tx = tx or (230 - pos * 100)
    ty = ty or 230
    tpic, tn = tpic or 1, tn or 1
    hscale, vscale = hscale or pos, vscale or 1
    local master = self.dialog_displayer
    --------
    master.active = true
    --------
    if not IsValid(master.char[pos][num]) then
        master.char[pos][num] = New(boss.dialog.character, img, pos, px, py, vscale, hscale, num)
    else
        master.char[pos][num].act = true
        master.char[pos][num].img = img
        master.char[pos][num].x = px
        master.char[pos][num].y = py
        master.char[pos][num].vscale = vscale
        master.char[pos][num].hscale = hscale
    end
    lastdialogpic = master.char[pos][num]
    task.Wait()
    --------
    local balloon = New(boss.dialog.balloon, tx, ty, pos, 1, tpic, text, tn)
    table.insert(master.balloon, balloon)
    lastsentence = balloon
    t = t or (60 + #text * 5)
    for _ = 1, t do
        if (KeyIsPressed "shoot" or master.jump_dialog > 60) and _dialog_can_skip then
            PlaySound("plst00", 0.35, 0, true)
            if master.jump_dialog > 60 then
                master.jump_dialog = 56
            end
            break
        end
        task.Wait()
    end
    --------
    local unit
    local n = table.maxn(master.balloon) or 0
    for i = n, 1, -1 do
        unit = master.balloon[i]
        if IsValid(unit) then
            unit.n = unit.n - 1
        else
            table.remove(master.balloon, i)
        end
    end
    master.char[pos][num].act = stay or false
end

---对话气泡
---@class boss.dialog_balloon
---@return boss.dialog_balloon
boss.dialog.balloon = Class(object)
local balloon = boss.dialog.balloon
function balloon:init(x, y, hpos, vpos, pic, text, n)
    self.layer = LAYER_TOP + 233 --无上至尊（啥
    self.x, self.y = x, y
    self.bound = false
    self.alpha = 255
    self.scale = 0
    self.hpos = hpos
    if self.hpos == 2 then
        self.hpos = -1
    end
    self.vpos = vpos
    if self.vpos == 2 then
        self.vpos = -1
    end
    self.pic = ((pic or 1) - 1) % 4 + 1
    self.text = text
    self.ttfdrawer = TTFDrawer(self.text)
    self.d = string.find(text, string.format("\n"), 1)
    if self.d then
        self.text1, self.text2 = string.match(text, "^(.+)\n(.+)$")
        local l1, l2 = sp.string(self.text1):GetLength(), sp.string(self.text2):GetLength()
        self.l = max(l1, l2)
        self.pic = self.pic + 4
    else
        self.l = sp.string(text):GetLength()
    end
    self.l = max(3, self.l)
    self.tx = self.l * 16
    self.n = n or 1
    self.imgs = {
        'balloonHead' .. self.pic,
        'balloonBody' .. self.pic,
        'balloonTail' .. self.pic,
    }
    self.lbs = {}
    local xx = self.x + 7 * self.hpos
    if self.hpos < 0 then
        xx = xx - self.l
    end
    self.n_body = int(max(0, self.l - 3) / 2) + 1
    self.x_target = { 26 * self.hpos }
    xx = self.x_target[1]
    for _ = 1, self.n_body do
        xx = xx + 16 * self.hpos
        table.insert(self.x_target, xx)
    end
end
function balloon:frame()
    local t = min(self.timer, 10)
    self.scale = t / 10
    self.ttfdrawer:set(self.text)
    if self.n <= 0 then
        Del(self)
    end
end
function balloon:render()
    local x, y = self.x + 8, self.y
    local hscale = self.hpos / 2 * self.scale
    local vscale = self.vpos / 2 * self.scale
    SetViewMode "ui"
    Render(self.imgs[1], self.x, self.y, 0, hscale, vscale)
    Render(self.imgs[3], self.x + self.x_target[#self.x_target] * self.scale, self.y, 0, hscale, vscale)
    for i = 1, self.n_body do
        Render(self.imgs[2], self.x + self.x_target[i] * self.scale, self.y, 0, hscale, vscale)
    end
    if self.hpos < 0 then
        x = self.x + (self.x_target[self.n_body] - 16) * self.scale
    end
    if self.vpos > 0 then
        y = y - 22 * self.scale
    else
        y = y + 40 * self.scale
    end
    self.ttfdrawer:render("balloon_font",
            x, y, 16, 32, 0, 0,
            self.scale, Color(self.alpha, 0, 0, 0), 4)
    SetViewMode "world"
end

---对话角色
---改进（不）自EVA（v1.0）
---@class boss.dialog_character
---@return boss.dialog_character
boss.dialog.character = Class(object)
local character = boss.dialog.character
function character:init(img, pos, x, y, vs, hs, num)
    self.layer = LAYER_TOP + 9
    self.bound = false
    self.pos = pos
    self.x, self.y = x, y
    self.vs = vs or 1
    self.hs = hs or pos
    self.rot = 0
    self.img = img
    self.t = 0
    self.act = true
    self.death = 0
    self.vscale = self.vs
    self.hscale = self.hs
    self.cnm = 0 --为了同时提供上升与下降两种函数式0v0
    self.alpha = 0 --立绘还是透明淡入比较好...
    self.num = num
end
function character:frame()
    task.Do(self)
    local v = 1.25 --移动速率
    if self.act then
        self.layer = LAYER_TOP + 9-- + self.num
        self.t = min(self.t + v, 16)
        self.cnm = sin((self.t) * (90 / 16)) ^ 2--阿塔拉希no函数式，我爽了你呢
    else
        self.layer = LAYER_TOP + 8-- + self.num
        self.t = max(self.t - v, 0)
        self.cnm = sin((self.t) * (90 / 16)) ^ 2
    end
    self.alpha = sin(min(self.timer * (90 / 10), 90))
end
function character:render()
    SetViewMode "ui"
    local move_dis = 32
    local dead_dis = 32
    local x, y = self.x, self.y
    local dc = 80 --下降转暗的颜色值
    local alpha = 255 * self.alpha
    if self.pos == 1 then
        local t = self.cnm --函数式改变
        SetImageState(self.img, "", Color(alpha, dc, dc, dc) + t * Color(alpha, 255 - dc, 255 - dc, 255 - dc) - (self.death / 30) * Color(0xFF000000))
        local t1 = sin(self.death * 3)
        Render(self.img, x + t * move_dis - dead_dis * t1, y + t * 16 - dead_dis * t1, 0, self.hscale, self.vscale)--self.death*12是什么沙雕，丑死了（
    else
        local t = self.cnm --函数式改变
        SetImageState(self.img, "", Color(alpha, dc, dc, dc) + t * Color(alpha, 255 - dc, 255 - dc, 255 - dc) - (self.death / 30) * Color(0xFF000000))
        local t1 = sin(self.death * 3)
        Render(self.img, x - t * move_dis + dead_dis * t1, y + t * 16 - dead_dis * t1, 0, self.hscale, self.vscale)
    end
    SetViewMode "world"
end
function character:del()
    PreserveObject(self)
    task.New(self, function()
        for i = 1, 30 do
            self.death = i
            task.Wait()
        end
        RawDel(self)
    end)
end