--------------------------------------------------------------------------------
--- THlib 启动器
--- code by 璀境石
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------

local lstg = require("lstg")
local Keyboard = lstg.Input.Keyboard
local Mouse = lstg.Input.Mouse
local i18n = require("lib.i18n")
local default_setting = require("foundation.legacy.default_setting")
local SceneManager = require("foundation.SceneManager")
local InputSystem = require("foundation.InputSystem")
local KeyboardAdaptor = require("foundation.KeyboardAdaptor")

local i18n_str = i18n.string

--------------------------------------------------------------------------------

---@type ui
local subui = lstg.DoFile("lib/ui.lua")

---@class launcher.menu.Base : lstg.GameObject

---@param obj launcher.menu.Base
local function initMenuObjectCommon(obj)
    obj.layer = LAYER_TOP
    obj.group = GROUP_GHOST
    obj.bound = false -- 飞入飞出可能会离开版面

    -- 菜单飞入飞出
    obj.alpha = 1.0
    obj.alpha0 = 0.0
    obj.x = screen.width * 0.5 - screen.width
    obj.y = screen.height * 0.5
    obj.locked = true
end

local function clamp(v, min, max)
    return math.max(min, math.min(v, max))
end

--------------------------------------------------------------------------------

---@return string[], number
local function enumMods()
    local list = {}
    local pos = 1
    local list_mods = lstg.FileManager.EnumFiles('mod/')
    for _, v in ipairs(list_mods) do
        local filename = v[1]
        local mod_name = ""
        if string.sub(filename, -4, -1) == ".zip" then
            -- 压缩包 mod
            lstg.LoadPack(filename)
            local archive = lstg.FileManager.GetArchive(filename)
            if archive then
                local root_exist = archive:FileExist("root.lua")
                lstg.UnloadPack(filename)
                if root_exist then
                    mod_name = string.sub(filename, 5, -5)
                end
            end
        elseif v[2] then
            -- 文件夹 mod
            if lstg.FileManager.FileExist(v[1] .. "root.lua") then
                mod_name = string.sub(filename, 5, -2)
            end
        end
        if string.len(mod_name) > 0 then
            if mod_name ~= 'launcher' then
                table.insert(list, mod_name)
            end
            if setting.last_mod == mod_name then
                pos = #list
            end
        end
    end
    return list, pos
end

--- 前置声明，实际实现在下方的 launcher_scene
---@param mod_name string
local function setMod(mod_name) end

---@class launcher.menu.SelectMod : launcher.menu.Base
local SelectMod = Class(object)

---@param exit_f fun()
function SelectMod:init(exit_f)
    initMenuObjectCommon(self)

    self.title = ""
    self.exit_func = exit_f

    local _w_height = 16 + 4 * 2 -- 上下都留空隙
    local _width = screen.width - 16 * 2 -- 两侧留边缘
    local _height = 18 * _w_height

    self._back = subui.widget.Button("", exit_f)
    self._back.width = _width / 4
    self._back.height = _w_height

    self._view = subui.layout.LinearScrollView(_width, _height)
    self._view.scroll_height = _w_height -- 一次滚轮滚动一个按键

    function self:_updateViewState()
        self._view.alpha = self.alpha
        self._view.x = self.x - _width / 2
        self._view.y = self.y + _height / 2 - _w_height -- 降一个控件高度

        self._back.alpha = self.alpha
        self._back.x = self.x - _width / 2
        self._back.y = self.y + _height / 2 + _w_height
    end
    function self:refresh()
        self.title = i18n_str("launcher.menu.start.select")
        self._back.text = i18n_str("launcher.back_icon")
        local mods_, pos_ = enumMods()
        local ws_ = {}
        for i, v in ipairs(mods_) do
            local idx = i
            local mod = v
            local w_button = subui.widget.Button(string.format("%d. %s", idx, mod), function()
                subui.sound.playConfirm()
                setMod(mod)
            end)
            w_button.width = _width
            w_button.height = _w_height
            table.insert(ws_, w_button)
        end
        self._view:setWidgets(ws_)
        --self._view._index = pos_
        self._view:setCursorIndex(pos_)
    end

    self:_updateViewState() -- 先更新一次
    self:refresh()
end

function SelectMod:frame()
    task.Do(self)
    self:_updateViewState()
    if not self.locked then
        if self.exit_func and (subui.keyboard.cancel.down or subui.mouse.xbutton1.down) then
            self.exit_func()
        end
    end
    self._back:update(not self.locked and subui.isMouseInRect(self._back))
    self._view:update(not self.locked)
end

function SelectMod:render()
    if self.alpha0 >= 0.0001 then
        SetViewMode("ui")
        local y = self.y + 9.5 * 24
        subui.drawTTF("ttf:menu-font", self.title, self.x, self.x, y, y, lstg.Color(self.alpha * 255, 255, 255, 255), "center", "vcenter")
        self._back:draw()
        self._view:draw()
        SetViewMode("world")
    end
end

---@param exit_f fun()
---@return launcher.menu.SelectMod
function SelectMod.create(exit_f)
    return lstg.New(SelectMod, exit_f)
end

--------------------------------------------------------------------------------

---@class launcher.menu.TextInput : launcher.menu.Base
local TextInput = Class(object)

function TextInput:init()
    initMenuObjectCommon(self)

    self.title = ""
    ---@type fun(text:string)
    self.callback = function() end
    self.text_max_length = 8
    self.text = ""

    local _w_height = 16 + 4 * 2 -- 上下都留空隙
    local _width = _w_height * 13 -- 屏幕键盘宽度
    local _height = 18 * _w_height

    self._back = subui.widget.Button("", function()
        self.callback(false)
    end)
    self._back.width = _width / 4
    self._back.height = _w_height

    local __0 = "\0"
    local __3 = "\3"
    local __8 = "\8"
    local _bs = "\\"
    local _sp = " "
    local chars = {
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
        "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
        "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
        "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z",
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ",", ".", "_",
        "+", "-", "*", "/", "=", "<", ">", "(", ")", "[", "]", "{", "}",
        "#", "$", "%", "&", "@", ":", ";", "!", "?", "^", "~", "`", "|",
        _bs, '"', "'", __0, __0, __0, __0, __0, __0, __0, _sp, __8, __3,
    }
    ---@type ui.widget.Button[]
    local buttons = {}
    for _, v in ipairs(chars) do
        local ch = v
        local w_button = subui.widget.Button(ch, function()
            if self.text:len() < self.text_max_length then
                self.text = self.text .. ch
            end
        end)
        if ch == _sp then
            w_button.text = "␣"
        elseif ch == __8 then
            w_button.text = "←"
            w_button.callback = function()
                if self.text:len() > 0 then
                    self.text = self.text:sub(1, self.text:len() - 1)
                end
            end
        elseif ch == __3 then
            w_button.text = "✓"
            w_button.callback = function()
                self.callback(self.text)
            end
        elseif ch == __0 then
            w_button.text = ""
            w_button.callback = function() end
        end
        w_button.width = 24
        w_button.height = 24
        w_button.halign = "center"
        table.insert(buttons, w_button)
    end
    table.insert(buttons, self._back)
    self._button = buttons
    self._button_index = 1

    function self:_updateButtonLayout()
        local lw = 24 * 13
        local lh = 24 * 8
        local lx = self.x - lw / 2
        local ly = self.y + lh / 2
        for j = 0, 7 do
            for i = 0, 12 do
                local w = buttons[j * 13 + i + 1]
                w.alpha = self.alpha
                w.x = lx + i * 24
                w.y = ly - j * 24
            end
        end

        self._back.alpha = self.alpha
        self._back.x = self.x - _width / 2
        self._back.y = self.y + _height / 2 + _w_height
    end

    ---@param title string
    ---@param init_text string
    ---@param cb fun(text:string)
    function self:reset(title, init_text, cb)
        self._button_index = 1
        self.title = i18n_str(title)
        self._back.text = i18n_str("launcher.back_icon")
        if init_text then
            self.text = init_text
        end
        self.callback = cb
    end

    self:_updateButtonLayout()
end

function TextInput:frame()
    local function indexToPos()
        local zero_base = self._button_index - 1
        return (zero_base % 13) + 1,
            math.floor(zero_base / 13) + 1
    end
    local function posToIndex(x, y)
        x = math.max(1, math.min(x, 13))
        y = math.max(1, math.min(y, 8))
        self._button_index = (y - 1) * 13 + (x - 1) + 1
    end
    task.Do(self)
    self:_updateButtonLayout()
    if not self.locked then
        if subui.keyboard.up.down then
            local x, y = indexToPos()
            y = y - 1
            posToIndex(x, y)
        elseif subui.keyboard.down.down then
            local x, y = indexToPos()
            y = y + 1
            posToIndex(x, y)
        elseif subui.keyboard.left.down then
            local x, y = indexToPos()
            x = x - 1
            posToIndex(x, y)
        elseif subui.keyboard.right.down then
            local x, y = indexToPos()
            x = x + 1
            posToIndex(x, y)
        elseif subui.keyboard.cancel.down then
            if self.text:len() > 0 then
                self.text = self.text:sub(1, self.text:len() - 1)
            else
                self.callback(nil)
            end
        end
        if subui.mouse.is_move then
            for i, w in ipairs(self._button) do
                if subui.isMouseInRect(w) then
                    self._button_index = i
                end
            end
        end
    end
    for i, w in ipairs(self._button) do
        w:update(not self.locked and i == self._button_index)
    end
end

function TextInput:render()
    if self.alpha0 > 0.0001 then
        SetViewMode("ui")
        local y = self.y + 9.5 * 24
        subui.drawTTF("ttf:menu-font", self.title, self.x, self.x, y, y, lstg.Color(self.alpha * 255, 255, 255, 255), "center", "vcenter")
        y = y - 24 * 3
        local w2 = 13 * 24 * 0.5
        lstg.SetImageState("img:menu-white", "", lstg.Color(self.alpha * 32, 255, 255, 255))
        lstg.RenderRect("img:menu-white",
            self.x - w2, self.x + w2,
            y - 12, y + 12)
        subui.drawTTF("ttf:menu-font", self.text, self.x, self.x, y, y, lstg.Color(self.alpha * 255, 255, 255, 255), "center", "vcenter")
        for _, w in ipairs(self._button) do
            w:draw()
        end
        SetViewMode("world")
    end
end

---@return launcher.menu.TextInput
function TextInput.create()
    return lstg.New(TextInput)
end

--------------------------------------------------------------------------------

---@class launcher.menu.MainMenu : launcher.menu.Base
local Main = Class(object)

---@param exit_f fun()
function Main:init(exit_f, entries)
    initMenuObjectCommon(self)

    self.exit_func = exit_f

    local _w_height = 16 + 4 * 2 -- 上下都留空隙
    local _width = 200 --screen.width - 16 * 2 -- 两侧留边缘
    local _height = #entries * _w_height

    self._view = subui.layout.LinearScrollView(_width, _height)
    self._view.scroll_height = _w_height -- 一次滚轮滚动一个按键

    function self:_updateViewState()
        self._view.alpha = self.alpha
        self._view.x = self.x - _width / 2
        self._view.y = self.y + _height / 2
    end
    function self:refresh()
        local _updateTextFunc = {}
        local function _updateText()
            for _, f in ipairs(_updateTextFunc) do
                f()
            end
        end

        local ws_ = {}
        for _, v in ipairs(entries) do
            if v[1] == "$lang" then
                local lci = 1
                local lcs = i18n.listLocale()
                local lcname = {}
                for i, v in ipairs(lcs) do
                    lcname[i] = v.name
                    if setting and setting.locale and setting.locale == v.id then
                        lci = i
                    end
                end
                local w_simpleselector_lang = subui.widget.SimpleSelector()
                    :setText("")
                    :setRect(0, 0, _width, _w_height)
                    :setCallback(function (value)
                        -- NO OP
                    end, function()
                        return lci
                    end, function(value)
                        lci = value
                        i18n.setLocale(lcs[lci].id)
                        _updateText()
                        setting.locale = lcs[lci].id
                        saveConfigure()
                    end)
                w_simpleselector_lang._split_factor = 0.0
                w_simpleselector_lang._item = lcname
                table.insert(ws_, w_simpleselector_lang)
            else
                local val = v
                local w_button = subui.widget.Button(i18n_str(val[1]), function()
                    val[2]()
                end)
                w_button.width = _width
                w_button.height = _w_height
                w_button.halign = "center"
                table.insert(ws_, w_button)
                table.insert(_updateTextFunc, function()
                    w_button.text = i18n_str(val[1])
                end)
            end
        end

        self._view:setWidgets(ws_)
    end

    self:_updateViewState() -- 先更新一次
    self:refresh()
end

function Main:frame()
    task.Do(self)
    if not self.locked and self.exit_func and (subui.keyboard.cancel.down or subui.mouse.xbutton1.down) then
        self.exit_func()
    end
    self:_updateViewState()
    self._view:update(not self.locked)
end

function Main:render()
    if self.alpha0 >= 0.0001 then
        SetViewMode("ui")
        self._view:draw()
        SetViewMode("world")
    end
end

---@param exit_f fun()
---@return launcher.menu.MainMenu
function Main.create(exit_f, entries)
    return lstg.New(Main, exit_f, entries)
end

--------------------------------------------------------------------------------

local api_url_root = "https://api.luastg-sub.com"
local api_url_latest_framework_version = api_url_root .. "/framework/after-ex-plus/version/latest"

local function isVersionHigher(v, v2)
    if type(v) ~= "string" or type(v2) ~= "string" then
        return false
    end
    local x1, y1, z1 = string.gmatch(v , "(%d+).(%d+).(%d+)")()
    local x2, y2, z2 = string.gmatch(v2, "(%d+).(%d+).(%d+)")()
    if type(x1) ~= "string" or type(y1) ~= "string" or type(z1) ~= "string" then
        return false
    end
    if type(x2) ~= "string" or type(y2) ~= "string" or type(z2) ~= "string" then
        return false
    end
    local x1n, y1n, z1n = tonumber(x1), tonumber(y1), tonumber(z1)
    local x2n, y2n, z2n = tonumber(x2), tonumber(y2), tonumber(z2)
    local n1 = x1n * 100000000 + y1n * 10000 + z1n
    local n2 = x2n * 100000000 + y2n * 10000 + z2n
    return n1 < n2
end

---@param t any
local function validateVersionData(t)
    return type(t) == "table" and type(t.name) == "string" and type(t.version) == "string" and type(t.description) == "string"
end

local function getLatestVersion()
    local result = false
    local function request()
        local Request = require("http.Request")
        return Request.get(api_url_latest_framework_version)
            :setResolveTimeout(4000)
            :setConnectTimeout(10000)
            :setSendTimeout(10000)
            :setReceiveTimeout(10000)
            :addHeader("Accept", "application/json")
            :execute()
    end
    local response
    result, response = pcall(request)
    if not result then
        return false, ""
    end
    local data
    result, data = pcall(cjson.decode, response:body())
    if not result or not validateVersionData(data) then
        return false, ""
    end
    return true, data.description
end

---@class launcher.menu.VersionView : launcher.menu.Base
local VersionView = Class(object)

---@param exit_f fun()
function VersionView:init(exit_f)
    initMenuObjectCommon(self)

    self.title = ""
    self.exit_func = exit_f

    local _w_height = 16 + 4 * 2 -- 上下都留空隙
    local _width = screen.width - 16 * 2 -- 两侧留边缘
    local _height = 18 * _w_height

    self._back = subui.widget.Button("", exit_f)
    self._back.width = _width / 4
    self._back.height = _w_height

    self._view = subui.layout.LinearScrollView(_width, _height)
    self._view.scroll_height = _w_height -- 一次滚轮滚动一个按键

    function self:_updateViewState()
        self._view.alpha = self.alpha
        self._view.x = self.x - _width / 2
        self._view.y = self.y + _height / 2 - _w_height -- 降一个控件高度

        self._back.alpha = self.alpha
        self._back.x = self.x - _width / 2
        self._back.y = self.y + _height / 2 + _w_height
    end
    function self:refresh()
        self.title = i18n_str("launcher.menu.check_new_version")
        self._back.text = i18n_str("launcher.back_icon")
        local check_nv, nv_name = getLatestVersion()
        if not check_nv then
            nv_name = i18n_str("launcher.menu.version.fetch_failed")
        end
        local widget_list = {
            { i18n_str("launcher.menu.version.check"), function() self:refresh() end },
            { "", function() end },
            { i18n_str("launcher.menu.version.label_current") .. gconfig.window_title, function() end },
            { i18n_str("launcher.menu.version.label_latest") .. nv_name, function() end },
            { "", function() end },
            { i18n_str("launcher.menu.version.download_sources"), function() end },
            { i18n_str("launcher.menu.version.download_source1"), function() lstg.Execute("https://qm.qq.com/cgi-bin/qm/qr?k=b6VXIK9HauTk33-tiWiMRqfQV1S5aSE_&jump_from=webapi&authKey=9ZNcegQlRo3dVVsMQs5K4R2/DckQYajmO3JnMdzL98/nmdv615q7bXbJCNubFgYi") end },
            { i18n_str("launcher.menu.version.download_source2"), function() lstg.Execute("https://qm.qq.com/cgi-bin/qm/qr?k=0ScR3LsxhNu1YCrHvpEoodu74J21S1fP&jump_from=webapi&authKey=IoAb/UI23m574Igvg93xidQZ1MU7otUjB6LrHp5+rxiU9nT/jeGuuNVxjgCsmlNJ") end },
            { i18n_str("launcher.menu.version.download_source3"), function() lstg.Execute("https://qm.qq.com/cgi-bin/qm/qr?k=8M0k3qfYNQu11ptp-_p4WX-24oXA2djt&jump_from=webapi&authKey=B8/uqQh05JTC0Ss0UzFYBk4FLmqBhNS2I0l0CuAt4sho5uW/+ZvKCGZeBWkOa4hN") end },
            --{ i18n_str("launcher.menu.version.download_source4"), function() lstg.Execute("https://luastg.ritsukage.com") end }, -- R.I.P
            { i18n_str("launcher.menu.version.download_source5"), function() lstg.Execute("https://files.luastg-sub.com") end },
            { i18n_str("launcher.menu.version.download_source6"), function() lstg.Execute("https://home.luastg-sub.com") end },
        }
        local ws_ = {}
        for _, v in ipairs(widget_list) do
            local w_button = subui.widget.Button(v[1], function()
                v[2]()
            end)
            w_button.width = _width
            w_button.height = _w_height
            table.insert(ws_, w_button)
        end
        self._view:setWidgets(ws_)
        self._view._index = 1
    end

    self:_updateViewState() -- 先更新一次
    --self:refresh() -- 创建时不更新，防止触发流控（1s请求1次）
end

function VersionView:frame()
    task.Do(self)
    self:_updateViewState()
    if not self.locked then
        if self.exit_func and (subui.keyboard.cancel.down or subui.mouse.xbutton1.down) then
            self.exit_func()
        end
    end
    self._back:update(not self.locked and subui.isMouseInRect(self._back))
    self._view:update(not self.locked)
end

function VersionView:render()
    if self.alpha0 >= 0.0001 then
        SetViewMode("ui")
        local y = self.y + 9.5 * 24
        subui.drawTTF("ttf:menu-font", self.title, self.x, self.x, y, y, lstg.Color(self.alpha * 255, 255, 255, 255), "center", "vcenter")
        self._back:draw()
        self._view:draw()
        SetViewMode("world")
    end
end

---@param exit_f fun()
---@return launcher.menu.VersionView
function VersionView.create(exit_f)
    return lstg.New(VersionView, exit_f)
end

--------------------------------------------------------------------------------
--- 输入设置
--#region

local TRANSPARENT_THRESHOLD = 1 / 255
local TRANSITION_SPEED = 1 / 30

--#region 数组

---@generic T
---@param array T[]
---@param value T
---@return boolean
local function isArrayContains(array, value)
    if #array == 0 then
        return false
    end
    for _, v in ipairs(array) do
        if v == value then
            return true
        end
    end
    return false
end

--#endregion

--#region 绘图方法

---@param s string css hex color
---@param alpha number? 0.0 to 1.0
---@return lstg.Color
local function parseColor(s, alpha)
    assert(type(s) == "string")
    assert(s:sub(1, 1) == "#")
    assert(s:len() == 7 or s:len() == 9)
    local c = lstg.Color(0)
    c.r = assert(tonumber(s:sub(2, 3), 16))
    c.g = assert(tonumber(s:sub(4, 5), 16))
    c.b = assert(tonumber(s:sub(6, 7), 16))
    if s:len() == 9 then
        c.a = tonumber(s:sub(8, 9), 16)
    else
        c.a = 255
    end
    if alpha ~= nil then
        assert(type(alpha) == "number")
        assert(alpha >= 0.0 and alpha <= 1.0)
        c.a = c.a * alpha
    end
    return c
end

---@param l number
---@param r number
---@param b number
---@param t number
---@param fill_color lstg.Color
local function drawRect(l, r, b, t, fill_color)
    if fill_color.a >= TRANSPARENT_THRESHOLD and r > l and t > b then
        lstg.SetImageState("img:menu-white", "", fill_color)
        lstg.RenderRect("img:menu-white", l, r, b, t)
    end
end

---@param x number
---@param y number
---@param w number
---@param h number
---@param fill_color lstg.Color
local function drawRectAt(x, y, w, h, fill_color)
    drawRect(x, x + w, y, y + h, fill_color)
end

---@param l number
---@param r number
---@param b number
---@param t number
---@param fill_color lstg.Color
---@param border_size number
---@param border_color lstg.Color
local function drawRectWithBorder(l, r, b, t, fill_color, border_size, border_color)
    local has_fill = (r - l) > border_size and (t - b) > border_size
    if border_color.a >= TRANSPARENT_THRESHOLD and r > l and t > b then
        lstg.SetImageState("img:menu-white", "", border_color)
        if has_fill then
            lstg.RenderRect("img:menu-white", l, l + border_size, b + border_size, t - border_size) -- left
            lstg.RenderRect("img:menu-white", r - border_size, r, b + border_size, t - border_size) -- right
            lstg.RenderRect("img:menu-white", l, r, b, b + border_size) -- bottom
            lstg.RenderRect("img:menu-white", l, r, t - border_size, t) -- top
        else
            lstg.RenderRect("img:menu-white", l, r, b, t)
        end
    end
    if fill_color.a >= TRANSPARENT_THRESHOLD and has_fill then
        lstg.SetImageState("img:menu-white", "", fill_color)
        lstg.RenderRect("img:menu-white", l + border_size, r - border_size, b + border_size, t - border_size)
    end
end

---@param x number
---@param y number
---@param w number
---@param h number
---@param fill_color lstg.Color
---@param border_size number
---@param border_color lstg.Color
local function drawRectWithBorderAt(x, y, w, h, fill_color, border_size, border_color)
    return drawRectWithBorder(x, x + w, y, y + h, fill_color, border_size, border_color)
end

---@param horizontal_alignment '"left"' | '"center"' | '"right"'
---@param vertical_alignment  '"top"' | '"center"' | '"bottom"'
---@return integer
local function translateAlignment(horizontal_alignment, vertical_alignment)
    local alignment = 0
    if horizontal_alignment == "left" then
        alignment = alignment + 0
    elseif horizontal_alignment == "center" then
        alignment = alignment + 1
    elseif horizontal_alignment == "right" then
        alignment = alignment + 2
    else
        error("invalid horizontal alignment")
    end
    if vertical_alignment == "top" then
        alignment = alignment + 0
    elseif vertical_alignment == "center" then
        alignment = alignment + 4
    elseif vertical_alignment == "bottom" then
        alignment = alignment + 8
    else
        error("invalid horizontal alignment")
    end
    return alignment
end

---@param font string
---@param text string
---@param l number
---@param r number
---@param b number
---@param t number
---@param scale number
---@param color lstg.Color
---@param horizontal_alignment '"left"' | '"center"' | '"right"' | nil
---@param vertical_alignment  '"top"' | '"center"' | '"bottom"' | nil
local function drawTextInRect(font, text, l, r, b, t, scale, color, horizontal_alignment, vertical_alignment)
    if scale > 0 and color.a >= TRANSPARENT_THRESHOLD then
        lstg.RenderTTF(font, text, l, r, b, t, translateAlignment(horizontal_alignment or "left", vertical_alignment or "top"), color, scale * 2.0) -- fuck LuaSTG
    end
end

---@param font string
---@param text string
---@param x number
---@param y number
---@param scale number
---@param color lstg.Color
---@param horizontal_alignment '"left"' | '"center"' | '"right"' | nil
---@param vertical_alignment  '"top"' | '"center"' | '"bottom"' | nil
local function drawText(font, text, x, y, scale, color, horizontal_alignment, vertical_alignment)
    drawTextInRect(font, text, x, x, y, y, scale, color, horizontal_alignment, vertical_alignment) -- fuck LuaSTG
end

local SQRT2_2 = 0.7071067811865476

---@type number[][]
local stroke_offset = {
    { 1, 0 },
    { 0, 1 },
    { -1, 0 },
    { 0, - 1 },
    { SQRT2_2, SQRT2_2 },
    { -SQRT2_2, SQRT2_2 },
    { -SQRT2_2, -SQRT2_2 },
    { SQRT2_2, -SQRT2_2 },
}

---@param font string
---@param text string
---@param l number
---@param r number
---@param b number
---@param t number
---@param scale number
---@param color lstg.Color
---@param stroke_size number
---@param stroke_color lstg.Color
---@param horizontal_alignment '"left"' | '"center"' | '"right"' | nil
---@param vertical_alignment  '"top"' | '"center"' | '"bottom"' | nil
local function drawTextWithStrokeInRect(font, text, l, r, b, t, scale, color, stroke_size, stroke_color, horizontal_alignment, vertical_alignment)
    if stroke_size > 0 and stroke_color.a >= TRANSPARENT_THRESHOLD then
        for _, offset in ipairs(stroke_offset) do
            local dx, dy = offset[1] * stroke_size, offset[2] * stroke_size
            drawTextInRect(font, text, l + dx, r + dx, b + dy, t + dy, scale, color, horizontal_alignment, vertical_alignment)
        end
    end
    drawTextInRect(font, text, l, r, b, t, scale, color, horizontal_alignment, vertical_alignment)
end

---@param font string
---@param text string
---@param x number
---@param y number
---@param scale number
---@param color lstg.Color
---@param stroke_size number
---@param stroke_color lstg.Color
---@param horizontal_alignment '"left"' | '"center"' | '"right"' | nil
---@param vertical_alignment  '"top"' | '"center"' | '"bottom"' | nil
local function drawTextWithStroke(font, text, x, y, scale, color, stroke_size, stroke_color, horizontal_alignment, vertical_alignment)
    return drawTextWithStrokeInRect(font, text, x, x, y, y, scale, color, stroke_size, stroke_color, horizontal_alignment, vertical_alignment)
end

--#endregion

--#region 新版本

---@class launcher.menu.InputSetting
local InputSetting = {}

function InputSetting:initialize()
    self.is_transitioning = false
    self.transition = 0
    self.transition_delta = -TRANSITION_SPEED
    self.interactive = false
    self.y_offset = 0
    self.y_offset_transition = 0
end

function InputSetting:update()
    self.transition = clamp(self.transition + self.transition_delta, 0.0, 1.0)
    if self.is_transitioning then
        if self.transition >= 1 then
            self.is_transitioning = false
            self.interactive = true
        elseif self.transition <= 0 then
            self.is_transitioning = false
        end
    end
    if self.interactive then
        local scroll_speed = screen.height
        if InputSystem.getBooleanAction("menu:up") then
            self.y_offset = math.max(0, self.y_offset - scroll_speed)
        elseif InputSystem.getBooleanAction("menu:down") then
            self.y_offset = self.y_offset + scroll_speed
        end
        local wheel_delta = Mouse.GetWheelDelta()
        self.y_offset = math.max(0, self.y_offset - wheel_delta * (screen.height / 4))
    end
    self.y_offset_transition = self.y_offset_transition + (self.y_offset - self.y_offset_transition) * 0.2
end

---@param binding foundation.InputSystem.BooleanBinding
---@param vertical_padding integer
---@return integer height
function InputSetting.measureBooleanActionKeyboardBindingContainerHeight(binding, vertical_padding)
    return 24
end
---@param action foundation.InputSystem.BooleanAction
---@param vertical_padding integer
---@return integer height
function InputSetting.measureBooleanActionContainerHeight(action, vertical_padding)
    local height = 0
    height = height + vertical_padding -- top padding
    height = height + 24 -- label
    for _, binding in action:keyboardBindings() do
        height = height + vertical_padding -- padding
        height = height + InputSetting.measureBooleanActionKeyboardBindingContainerHeight(binding, vertical_padding)
    end
    height = height + vertical_padding -- padding
    height = height + 24 -- add binding button
    height = height + vertical_padding -- bottom padding
    return height
end
---@param action_set foundation.InputSystem.ActionSet
---@param exclude_actions string[]
---@param vertical_padding integer
---@return integer height
function InputSetting.measureActionSetContainerHeight(action_set, exclude_actions, vertical_padding)
    local height = 0
    height = height + vertical_padding -- top padding
    height = height + 24 -- label
    for _, action in action_set:booleanActions() do
        if not isArrayContains(exclude_actions, action.name) then
            height = height + vertical_padding -- padding
            height = height + InputSetting.measureBooleanActionContainerHeight(action, vertical_padding)
        end
    end
    height = height + vertical_padding -- bottom padding
    return height
end

function InputSetting:draw()
    local alpha = self.transition
    if alpha >= TRANSPARENT_THRESHOLD then
        SetViewMode("ui")
        local font_scale = 0.5
        local x0, y0 = (screen.width - 400) / 2, screen.height - 16 + self.y_offset_transition
        local w0, h0 = 400, 24
        local gap = 8
        local color_on_surface = parseColor("#E6E0E9", alpha)
        local color_surface_container = parseColor("#211F26", alpha)
        local color_surface_container_high = parseColor("#2B2930", alpha)
        local color_surface_container_highest = parseColor("#36343B", alpha)

        local menu_action_set = InputSystem.getActionSet("menu")
        local game_action_set = InputSystem.getActionSet("menu")

        local exclude_actions = { "pointer" }
        local padding = 8
        local action_set_container_width = w0
        local action_set_container_height = InputSetting.measureActionSetContainerHeight(menu_action_set, exclude_actions, padding)
        drawRectAt(x0, y0 - action_set_container_height, action_set_container_width, action_set_container_height, color_surface_container)
        do
            local x, y = x0, y0
            local w = action_set_container_width
            x = x + padding
            w = w - padding * 2

            y = y - padding

            local menu_action_set_name = i18n_str("thlib.input.action_set." .. menu_action_set.name)
            drawTextInRect("ttf:menu-font-32", menu_action_set_name, x, x + w, y - 24, y, font_scale, color_on_surface, "center")
            y = y - 24
            y = y - padding

            for _, action in menu_action_set:booleanActions() do
                local action_container_height = InputSetting.measureBooleanActionContainerHeight(action, padding)
                drawRectAt(x, y - action_container_height, w, action_container_height, color_surface_container_high)

                x = x + padding
                w = w - padding * 2

                y = y - padding

                local menu_action_name = i18n_str("thlib.input.action_set." .. menu_action_set.name .. ".action." .. action.name)
                drawTextInRect("ttf:menu-font-32", menu_action_name, x, x + w, y - 24, y, font_scale, color_on_surface)
                y = y - 24

                for _, binding in action:keyboardBindings() do
                    y = y - padding

                    local binding_container_height = InputSetting.measureBooleanActionKeyboardBindingContainerHeight(binding, padding)
                    drawRectAt(x, y - binding_container_height, w, binding_container_height, color_surface_container_highest)

                    x = x + padding
                    w = w - padding * 2

                    drawTextInRect("ttf:menu-font-32", KeyboardAdaptor.getKeyName(binding.key), x, x + w, y - 24, y, font_scale, color_on_surface, "center")
                    y = y - 24

                    w = w + padding * 2
                    x = x - padding
                end

                y = y - padding

                do
                    drawRectAt(x, y - 24, w, 24, color_surface_container_highest)

                    x = x + padding
                    w = w - padding * 2

                    drawTextInRect("ttf:menu-font-32", "+添加", x, x + w, y - 24, y, font_scale, color_on_surface, "center")
                    y = y - 24

                    w = w + padding * 2
                    x = x - padding
                end

                y = y - padding

                w = w + padding * 2
                x = x - padding

                y = y - padding -- padding between actions
            end
        end

        SetViewMode("world")
    end
end

function InputSetting:enter()
    self.is_transitioning = true
    self.transition_delta = TRANSITION_SPEED
end

function InputSetting:leave()
    self.is_transitioning = true
    self.transition_delta = -TRANSITION_SPEED
    self.interactive = false
end

---@return launcher.menu.InputSetting
function InputSetting.create()
    local instance = {}
    setmetatable(instance, { __index = InputSetting })
    instance:initialize()
    return instance
end

--#endregion

--#region 老版本

---@class launcher.menu.InputSettingHost : launcher.menu.Base
local InputSettingHost = Class(object)

---@param exit_f fun()
function InputSettingHost:init(exit_f)
    initMenuObjectCommon(self)

    self.title = "?"
    self.exit_func = exit_f

    local _w_height = 16 + 4 * 2 -- 上下都留空隙
    local _width = screen.width - 16 * 2 -- 两侧留边缘
    local _height = 18 * _w_height

    -- 以前的设置

    local last_setting_copy = {}
    local last_setting = {}
    local function copyDataFromSetting()
        for k, v in pairs(setting.keys) do
            last_setting[k] = v
            last_setting_copy[k] = v
        end
        for k, v in pairs(setting.keysys) do
            last_setting[k] = v
            last_setting_copy[k] = v
        end
    end
    local function copyDataToSetting()
        for k, _ in pairs(setting.keys) do
            setting.keys[k] = last_setting[k]
        end
        for k, _ in pairs(setting.keysys) do
            setting.keysys[k] = last_setting[k]
        end
    end
    local function copyDataFromDefaultSetting()
        for k, v in pairs(default_setting.keys) do
            last_setting[k] = v
            last_setting_copy[k] = v
        end
        for k, v in pairs(default_setting.keysys) do
            last_setting[k] = v
            last_setting_copy[k] = v
        end
    end

    local keys = {
        { "launcher.action.left", "keys", "left" },
        { "launcher.action.right", "keys", "right" },
        { "launcher.action.up", "keys", "up" },
        { "launcher.action.down", "keys", "down" },
        { "launcher.action.slow", "keys", "slow" },
        { "launcher.action.shoot", "keys", "shoot" },
        { "launcher.action.spell", "keys", "spell" },
        { "launcher.action.special", "keys", "special" },
        { "launcher.action.menu", "keysys", "menu" },
        { "launcher.action.snapshot", "keysys", "snapshot" },
        { "launcher.action.repfast", "keysys", "repfast" },
        { "launcher.action.repslow", "keysys", "repslow" },
    }

    ---@type ui.widget.Text[]
    local texts = {}
    ---@type ui.widget.Button[]
    local keysetup = {}
    ---@type ui.widget.Button[]
    local buttons = {}

    self._back = subui.widget.Button("?", function()
        self:_discard()
        self.exit_func()
    end)
    self._back.width = _width / 4
    self._back.height = _w_height

    for i, v in ipairs(keys) do
        local idx = i
        local cfg = v

        local w_button = subui.widget.Button("", function() end)
        function w_button.updateText()
            local vkey = last_setting[cfg[3]]
            w_button.text = KeyboardAdaptor.getKeyName(vkey)
        end
        w_button.callback = function()
            self.locked = true
            self._current_edit = idx
            task.New(self, function()
                local last_key = nil
                while true do
                    if KeyboardAdaptor.isAnyKeyDown() then
                        task.Wait(1)
                    else
                        break
                    end
                end
                for _ = 1, 240 do
                    task.Wait(1)
                    last_key = KeyboardAdaptor.isAnyKeyDown()
                    if last_key then
                        break
                    end
                end
                if last_key then
                    last_setting[cfg[3]] = last_key
                    w_button.updateText()
                end
                task.Wait(1)
                self.locked = false
                self._current_edit = 0
            end)
        end
        w_button.width = _width
        w_button.height = _w_height
        w_button.halign = "right"
        table.insert(buttons, w_button)
        table.insert(keysetup, w_button)

        local w_text = subui.widget.Text(i18n_str(cfg[1]))
        w_text.width = _width
        w_text.height = _w_height
        table.insert(texts, w_text)
    end
    local function updateButtonText()
        for _, w in ipairs(keysetup) do
            w.updateText()
        end
    end

    self._current_edit = 0
    self._text = texts
    self._button = buttons
    self._button_index = 1

    self._restore = subui.widget.Button("?", function()
        copyDataFromDefaultSetting()
        updateButtonText()
    end)
    self._restore.width = _width
    self._restore.height = _w_height

    self._save = subui.widget.Button("?", function()
        copyDataToSetting()
        saveConfigure()
        self.exit_func()
    end)
    self._save.width = _width
    self._save.height = _w_height

    table.insert(buttons, self._restore)
    table.insert(buttons, self._save)
    self._save_index = #buttons
    table.insert(buttons, self._back)

    function self:_updateButtonLayout()
        local top_y = self.y + 8 * _w_height
        for i, w in ipairs(buttons) do
            w.alpha = self.alpha
            if w == self._back then
                w.x = self.x - _width / 2
                w.y = self.y + _height / 2 + _w_height
            else
                w.x = self.x - _width / 2
                w.y = top_y - (i - 1) * _w_height
            end
        end
        for i, w in ipairs(texts) do
            w.alpha = self.alpha
            w.x = self.x - _width / 2
            w.y = top_y - (i - 1) * _w_height
        end
    end

    function self:refresh()
        self.title = i18n_str("launcher.menu.setting.input.keyboard")
        self._back.text = i18n_str("launcher.back_icon")
        self._restore.text = i18n_str("launcher.restore_to_default")
        self._save.text = i18n_str("launcher.save_and_return")
        self._button_index = 1
        copyDataFromSetting()
        updateButtonText() -- 因为设置可能有变化
    end

    function self:_discard()
        -- NO OP
    end

    self:refresh()
    self:_updateButtonLayout()

    self.view = InputSetting.create()
    self.enter = function()
        self.view:enter()
    end
    self.leave = function()
        self.view:leave()
    end
end

function InputSettingHost:frame()
    local function formatIndex()
        self._button_index = ((self._button_index - 1) % #self._button) + 1
    end
    task.Do(self)
    self:_updateButtonLayout()
    if not self.locked then
        if subui.keyboard.up.down then
            self._button_index = self._button_index - 1
            formatIndex()
        elseif subui.keyboard.down.down then
            self._button_index = self._button_index + 1
            formatIndex()
        elseif subui.keyboard.cancel.down then
            if self._button_index ~= #self._button then
                self._button_index = #self._button
            else
                self:_discard()
                self.exit_func()
            end
        end
        if subui.mouse.is_move then
            for i, w in ipairs(self._button) do
                if subui.isMouseInRect(w) then
                    self._button_index = i
                end
            end
        end
    end
    for i, w in ipairs(self._button) do
        w:update(not self.locked and i == self._button_index)
    end
    for i, w in ipairs(self._text) do
        w:update(not self.locked and i == self._button_index)
    end
    self.view:update()
end

function InputSettingHost:render()
    if self.alpha0 > 0.0001 then
        SetViewMode("ui")
        local y = self.y + 9.5 * 24
        subui.drawTTF("ttf:menu-font", self.title, self.x, self.x, y, y, lstg.Color(self.alpha * 255, 255, 255, 255), "center", "vcenter")
        for i, w in ipairs(self._button) do
            if i == self._current_edit then
                local a = 48 + 16 * math.sin(self.timer / math.pi)
                lstg.SetImageState("img:menu-white", "", lstg.Color(self.alpha * a, 255, 255, 255))
                lstg.RenderRect("img:menu-white", w.x, w.x + w.width, w.y - w.height, w.y)
            end
            w:draw()
        end
        for _, w in ipairs(self._text) do
            w:draw()
        end
        SetViewMode("world")
    end
    self.view:draw()
end

---@param exit_f fun()
---@return launcher.menu.InputSettingHost
function InputSettingHost.create(exit_f)
    return lstg.New(InputSettingHost, exit_f)
end

--#endregion

--#endregion
--------------------------------------------------------------------------------

---@class launcher.menu.GameSetting : launcher.menu.Base
local GameSetting = Class(object)

---@param exit_f fun()
function GameSetting:init(exit_f)
    initMenuObjectCommon(self)

    self.title = "?"
    self.exit_func = exit_f

    local _w_height = 16 + 4 * 2 -- 上下都留空隙
    local _width = screen.width - 16 * 2 -- 两侧留边缘
    local _height = 18 * _w_height

    ---@type ui.widget.Button[]
    self._button = {}
    self._button_index = 2

    -- 直接返回

    local w_button_back = subui.widget.Button("?", function()
        self:_discard()
        self.exit_func()
    end)
    w_button_back.width = _width / 4
    w_button_back.height = _w_height
    table.insert(self._button, w_button_back)

    -- 旧设置

    local last_setting_copy = {
        resx = setting.resx,
        resy = setting.resy,
        windowed = setting.windowed,
        vsync = setting.vsync,
        sevolume = setting.sevolume,
        bgmvolume = setting.bgmvolume,
    }
    local last_setting = {
        resx = setting.resx,
        resy = setting.resy,
        windowed = setting.windowed,
        vsync = setting.vsync,
        sevolume = setting.sevolume,
        bgmvolume = setting.bgmvolume,
    }
    local function copyDataFromSetting()
        last_setting_copy.resx = setting.resx
        last_setting_copy.resy = setting.resy
        last_setting_copy.windowed = setting.windowed
        last_setting_copy.vsync = setting.vsync
        last_setting_copy.sevolume = setting.sevolume
        last_setting_copy.bgmvolume = setting.bgmvolume

        last_setting.resx = setting.resx
        last_setting.resy = setting.resy
        last_setting.windowed = setting.windowed
        last_setting.vsync = setting.vsync
        last_setting.sevolume = setting.sevolume
        last_setting.bgmvolume = setting.bgmvolume
    end
    local function copyDataToSetting()
        setting.resx = last_setting.resx
        setting.resy = last_setting.resy
        setting.windowed = last_setting.windowed
        setting.vsync = last_setting.vsync
        setting.sevolume = last_setting.sevolume
        setting.bgmvolume = last_setting.bgmvolume
    end

    -- 显示设置

    local mode_window = {
        -- legacy
        {  640,  480, 60, 1 },
        {  800,  600, 60, 1 },
        {  960,  720, 60, 1 },
        { 1024,  768, 60, 1 },
        { 1280,  960, 60, 1 },
        { 1600, 1200, 60, 1 },
        { 1920, 1440, 60, 1 },
        --[[
        -- 4:3
        {  640,  480, 60, 1 }, -- 1x
        {  704,  528, 60, 1 },
        {  768,  576, 60, 1 },
        {  832,  624, 60, 1 },
        {  896,  672, 60, 1 },
        {  960,  720, 60, 1 }, -- 1.5x
        { 1024,  768, 60, 1 },
        { 1088,  816, 60, 1 },
        { 1152,  864, 60, 1 },
        { 1216,  912, 60, 1 },
        { 1280,  960, 60, 1 }, -- 2x
        { 1344, 1008, 60, 1 },
        { 1408, 1056, 60, 1 },
        { 1472, 1104, 60, 1 },
        { 1536, 1152, 60, 1 },
        { 1600, 1200, 60, 1 }, -- 2.5x
        { 1664, 1248, 60, 1 },
        { 1728, 1296, 60, 1 },
        { 1792, 1344, 60, 1 },
        { 1856, 1392, 60, 1 },
        { 1920, 1440, 60, 1 }, -- 3x
        { 1984, 1488, 60, 1 },
        { 2048, 1536, 60, 1 },
        { 2112, 1584, 60, 1 },
        { 2176, 1632, 60, 1 },
        { 2240, 1680, 60, 1 }, -- 3.5x
        { 2304, 1728, 60, 1 },
        { 2368, 1776, 60, 1 },
        { 2432, 1824, 60, 1 },
        { 2496, 1872, 60, 1 },
        { 2560, 1920, 60, 1 }, -- 4x
        { 2624, 1968, 60, 1 },
        { 2688, 2016, 60, 1 },
        { 2752, 2064, 60, 1 },
        { 2816, 2112, 60, 1 },
        { 2880, 2160, 60, 1 }, -- 4.5x
        { 2944, 2208, 60, 1 },
        { 3008, 2256, 60, 1 },
        { 3072, 2304, 60, 1 },
        { 3136, 2352, 60, 1 },
        { 3200, 2400, 60, 1 }, -- 5x
        { 3264, 2448, 60, 1 },
        { 3328, 2496, 60, 1 },
        { 3392, 2544, 60, 1 },
        { 3456, 2592, 60, 1 },
        { 3520, 2640, 60, 1 }, -- 5.5x
        { 3584, 2688, 60, 1 },
        { 3648, 2736, 60, 1 },
        { 3712, 2784, 60, 1 },
        { 3776, 2832, 60, 1 },
        { 3840, 2880, 60, 1 }, -- 6x
        -- 16:9
        {  640,  360, 60, 1 }, -- 1x
        {  704,  396, 60, 1 },
        {  768,  432, 60, 1 },
        {  832,  468, 60, 1 },
        {  896,  504, 60, 1 },
        {  960,  540, 60, 1 }, -- 1.5x
        { 1024,  576, 60, 1 },
        { 1088,  612, 60, 1 },
        { 1152,  648, 60, 1 },
        { 1216,  684, 60, 1 },
        { 1280,  720, 60, 1 }, -- 2x
        { 1344,  756, 60, 1 },
        { 1408,  792, 60, 1 },
        { 1472,  828, 60, 1 },
        { 1536,  864, 60, 1 },
        { 1600,  900, 60, 1 }, -- 2.5x
        { 1664,  936, 60, 1 },
        { 1728,  972, 60, 1 },
        { 1792, 1008, 60, 1 },
        { 1856, 1044, 60, 1 },
        { 1920, 1080, 60, 1 }, -- 3x
        { 1984, 1116, 60, 1 },
        { 2048, 1152, 60, 1 },
        { 2112, 1188, 60, 1 },
        { 2176, 1224, 60, 1 },
        { 2240, 1260, 60, 1 }, -- 3.5x
        { 2304, 1296, 60, 1 },
        { 2368, 1332, 60, 1 },
        { 2432, 1368, 60, 1 },
        { 2496, 1404, 60, 1 },
        { 2560, 1440, 60, 1 }, -- 4x
        { 2624, 1476, 60, 1 },
        { 2688, 1512, 60, 1 },
        { 2752, 1548, 60, 1 },
        { 2816, 1584, 60, 1 },
        { 2880, 1620, 60, 1 }, -- 4.5x
        { 2944, 1656, 60, 1 },
        { 3008, 1692, 60, 1 },
        { 3072, 1728, 60, 1 },
        { 3136, 1764, 60, 1 },
        { 3200, 1800, 60, 1 }, -- 5x
        { 3264, 1836, 60, 1 },
        { 3328, 1872, 60, 1 },
        { 3392, 1908, 60, 1 },
        { 3456, 1944, 60, 1 },
        { 3520, 1980, 60, 1 }, -- 5.5x
        { 3584, 2016, 60, 1 },
        { 3648, 2052, 60, 1 },
        { 3712, 2088, 60, 1 },
        { 3776, 2124, 60, 1 },
        { 3840, 2160, 60, 1 }, -- 6x
        --]]
    }
    local mode_window_index = 1
    local mode_window_name = {}
    local function updateDisplayMode()
        local cfg = last_setting

        mode_window_index = 0
        for i, v in ipairs(mode_window) do
            if v[1] == cfg.resx and v[2] == cfg.resy then
                mode_window_index = i
                break
            end
        end
        if mode_window_index == 0 then
            for i, v in ipairs(mode_window) do
                if v[1] == cfg.resx or v[2] == cfg.resy then
                    mode_window_index = i
                    break
                end
            end
        end
        if mode_window_index == 0 then
            mode_window_index = 1 -- fallback
        end

        mode_window_name = {}
        for i, v in ipairs(mode_window) do
            mode_window_name[i] = string.format("%dx%d", v[1], v[2])
        end
    end

    local w_simpleselector_mode = subui.widget.SimpleSelector()
        :setText("?")
        :setRect(0, 0, _width, _w_height)
        :setCallback(function (value)
            -- NO OP
        end, function ()
            return mode_window_index
        end, function (value)
            mode_window_index = value
        end)
    local function updateModeText()
        w_simpleselector_mode._item = mode_window_name
    end
    table.insert(self._button, w_simpleselector_mode)

    local w_checkbox_fullscreen = subui.widget.CheckBox()
        :setText("launcher.menu.setting.game.fullscreen")
        :setRect(0, 0, _width, _w_height)
        :setCallback(function (value)
            updateModeText()
        end, function ()
            return not last_setting.windowed
        end, function (value)
            last_setting.windowed = not value
        end)
    table.insert(self._button, w_checkbox_fullscreen)

    local w_checkbox_vsync = subui.widget.CheckBox()
        :setText("launcher.menu.setting.game.vsync")
        :setRect(0, 0, _width, _w_height)
        :setCallback(function (value)
            -- NO OP
        end, function ()
            return last_setting.vsync
        end, function (value)
            last_setting.vsync = value
        end)
    table.insert(self._button, w_checkbox_vsync)

    -- 音量设置

    local w_slider_se = subui.widget.Slider()
        :setText("launcher.menu.setting.game.sound_effect")
        :setRect(0, 0, _width, _w_height)
        :setValue(0, 0, 100, "%d")
        :setValueStep(1, 1, 10)
        :setCallback(function(value)
            lstg.SetSEVolume(value / 100.0)
            subui.sound.playSelect()
        end, function ()
            return last_setting.sevolume
        end, function (value)
            last_setting.sevolume = value
        end)
    table.insert(self._button, w_slider_se)

    local w_slider_bgm = subui.widget.Slider()
        :setText("launcher.menu.setting.game.music")
        :setRect(0, 0, _width, _w_height)
        :setValue(0, 0, 100, "%d")
        :setValueStep(1, 1, 10)
        :setCallback(function(value)
            lstg.SetBGMVolume(value / 100.0)
        end, function ()
            return last_setting.bgmvolume
        end, function (value)
            last_setting.bgmvolume = value
        end)
    table.insert(self._button, w_slider_bgm)

    -- 应用

    local function applySetting()
        if not lstg.ChangeVideoMode(setting.resx, setting.resy, setting.windowed, setting.vsync) then
            setting.windowed = true
            saveConfigure()
            if not lstg.ChangeVideoMode(setting.resx, setting.resy, setting.windowed, setting.vsync) then
                stage.QuitGame()
                return
            end
        end
        ResetScreen()
        lstg.SetSEVolume(setting.sevolume / 100)
        lstg.SetBGMVolume(setting.bgmvolume / 100)
    end
    local w_button_apply = subui.widget.Button("launcher.save_and_return", function()
        last_setting.resx = mode_window[mode_window_index][1]
        last_setting.resy = mode_window[mode_window_index][2]
        copyDataToSetting()
        saveConfigure()
        applySetting()
        self.exit_func()
    end)
    w_button_apply.width = _width
    w_button_apply.height = _w_height
    table.insert(self._button, w_button_apply)

    -- 刷新

    function self:refresh()
        self.title = i18n_str("launcher.menu.setting.game")
        w_button_back.text = i18n_str("launcher.back_icon")
        w_simpleselector_mode.text = i18n_str("launcher.menu.setting.game.display_mode")
        w_checkbox_fullscreen.text = i18n_str("launcher.menu.setting.game.fullscreen")
        w_checkbox_vsync.text = i18n_str("launcher.menu.setting.game.vsync")
        w_slider_se.text = i18n_str("launcher.menu.setting.game.sound_effect")
        w_slider_bgm.text = i18n_str("launcher.menu.setting.game.music")
        w_button_apply.text = i18n_str("launcher.save_and_return")
        copyDataFromSetting()
        updateDisplayMode()
        updateModeText()
        self._button_index = 2
    end
    function self:_discard()
        lstg.SetSEVolume(last_setting_copy.sevolume / 100)
        lstg.SetBGMVolume(last_setting_copy.bgmvolume / 100)
    end

    -- 地狱布局

    function self:_updateLayout()
        w_button_back.alpha = self.alpha
        w_button_back.x = self.x - _width / 2
        w_button_back.y = self.y + _height / 2 + _w_height

        local top_y = self.y + 8 * _w_height

        w_simpleselector_mode.alpha = self.alpha
        w_simpleselector_mode.x = self.x - _width / 2
        w_simpleselector_mode.y = top_y

        top_y = top_y - _w_height

        w_checkbox_fullscreen.alpha = self.alpha
        w_checkbox_fullscreen.x = self.x - _width / 2
        w_checkbox_fullscreen.y = top_y

        top_y = top_y - _w_height

        w_checkbox_vsync.alpha = self.alpha
        w_checkbox_vsync.x = self.x - _width / 2
        w_checkbox_vsync.y = top_y

        top_y = top_y - _w_height

        w_slider_se.alpha = self.alpha
        w_slider_se.x = self.x - _width / 2
        w_slider_se.y = top_y

        top_y = top_y - _w_height

        w_slider_bgm.alpha = self.alpha
        w_slider_bgm.x = self.x - _width / 2
        w_slider_bgm.y = top_y

        top_y = top_y - _w_height

        w_button_apply.alpha = self.alpha
        w_button_apply.x = self.x - _width / 2
        w_button_apply.y = top_y
    end

    self:refresh()
end

function GameSetting:frame()
    local function formatIndex()
        self._button_index = ((self._button_index - 1) % #self._button) + 1
    end
    task.Do(self)
    self:_updateLayout()
    if not self.locked then
        if subui.keyboard.up.down then
            self._button_index = self._button_index - 1
            formatIndex()
        elseif subui.keyboard.down.down then
            self._button_index = self._button_index + 1
            formatIndex()
        elseif subui.keyboard.cancel.down then
            if self._button_index ~= 1 then
                self._button_index = 1
            else
                self:_discard()
                self.exit_func()
            end
        end
        if subui.mouse.is_move then
            for i, w in ipairs(self._button) do
                if subui.isMouseInRect(w) then
                    self._button_index = i
                end
            end
        end
    end
    for i, w in ipairs(self._button) do
        w:update(not self.locked and i == self._button_index)
    end
end

function GameSetting:render()
    if self.alpha0 > 0.0001 then
        SetViewMode("ui")
        local y = self.y + 9.5 * 24
        subui.drawTTF("ttf:menu-font", self.title, self.x, self.x, y, y, lstg.Color(self.alpha * 255, 255, 255, 255), "center", "vcenter")
        for _, w in ipairs(self._button) do
            w:draw()
        end
        SetViewMode("world")
    end
end

---@param exit_f fun()
---@return launcher.menu.GameSetting
function GameSetting.create(exit_f)
    return lstg.New(GameSetting, exit_f)
end

--------------------------------------------------------------------------------

---@class launcher.menu.PluginManager : launcher.menu.Base
local PluginManager = Class(object)

---@param exit_f fun()
function PluginManager:init(exit_f)
    initMenuObjectCommon(self)

    self.title = "launcher.menu.plugin_manager"
    self.exit_func = exit_f

    local _w_height = 16 + 4 * 2 -- 上下都留空隙
    local _width = screen.width - 16 * 2 -- 两侧留边缘
    local _height = 18 * _w_height

    self._back = subui.widget.Button("launcher.back_icon", exit_f)
    self._back.width = _width / 4
    self._back.height = _w_height

    self._view = subui.layout.LinearScrollView(_width, _height)
    self._view.scroll_height = _w_height -- 一次滚轮滚动一个按键

    function self:_updateLayout()
        self._view.alpha = self.alpha
        self._view.x = self.x - _width / 2
        self._view.y = self.y + _height / 2 - _w_height -- 降一个控件高度

        self._back.alpha = self.alpha
        self._back.x = self.x - _width / 2
        self._back.y = self.y + _height / 2 + _w_height
    end

    ---@type lstg.plugin.Config.Entry[]
    self.plugins = {}

    function self:refresh()
        self.title = i18n_str("launcher.menu.plugin_manager")
        self._back.text = i18n_str("launcher.back_icon")

        self.plugins = lstg.plugin.LoadConfig()
        self.plugins = lstg.plugin.FreshConfig(self.plugins)
        lstg.plugin.SaveConfig(self.plugins)

        local ws_ = {}
        for i, v in ipairs(self.plugins) do
            local idx = i
            local plg = v
            local w_entry = subui.widget.CheckBox()
                :setText(plg.name)
                :setRect(0, 0, _width, _w_height)
                :setCallback(function (value)
                    lstg.plugin.SaveConfig(self.plugins)
                end, function ()
                    return plg.enable
                end, function (value)
                    plg.enable = value
                end)
            table.insert(ws_, w_entry)
        end
        self._view:setWidgets(ws_)
        self._view._index = 1
    end

    self:refresh()
    self:_updateLayout() -- 先更新一次
end

function PluginManager:frame()
    task.Do(self)
    self:_updateLayout()
    if not self.locked then
        if self.exit_func and (subui.keyboard.cancel.down or subui.mouse.xbutton1.down) then
            self.exit_func()
        end
    end
    self._back:update(not self.locked and subui.isMouseInRect(self._back))
    self._view:update(not self.locked)
end

function PluginManager:render()
    if self.alpha0 >= 0.0001 then
        SetViewMode("ui")
        local y = self.y + 9.5 * 24
        subui.drawTTF("ttf:menu-font", self.title, self.x, self.x, y, y, lstg.Color(self.alpha * 255, 255, 255, 255), "center", "vcenter")
        self._back:draw()
        self._view:draw()
        SetViewMode("world")
    end
end

---@param exit_f fun()
---@return launcher.menu.PluginManager
function PluginManager.create(exit_f)
    return lstg.New(PluginManager, exit_f)
end

--------------------------------------------------------------------------------
--- 启动器场景

---@class game.LauncherScene : foundation.Scene
local LauncherScene = SceneManager.add("LauncherScene")

function LauncherScene:onCreate()
    self.timer = 0
    lstg.SetSplash(true)

    -- 背景
    self.color_value = 0
    self.color_value_d = 1 / 30

    -- 加载菜单资源
    subui.loadResources()

    -- 菜单栈，用来简化菜单跳转
    local empty_menu_obj = lstg.New(object)
    local menu_stack = {}
    local function menuFlyIn(self, dir)
        if type(self.enter) == "function" then
            self.enter()
        end
        self.alpha = 1
        if dir == 'left' then
            self.x = screen.width * 0.5 - screen.width
        elseif dir == 'right' then
            self.x = screen.width * 0.5 + screen.width
        end
        task.Clear(self)
        task.New(self, function()
            task.MoveTo(screen.width * 0.5, self.y, 30, 2)
            self.locked = false
        end)
        task.New(self, function()
            for i = 1, 30 do
                self.alpha0 = i / 30
                task.Wait(1)
            end
        end)
    end
    local function menuFlyOut(self, dir)
        if type(self.leave) == "function" then
            self.leave()
        end
        local x
        if dir == 'left' then
            x = screen.width * 0.5 - screen.width
        elseif dir == 'right' then
            x = screen.width * 0.5 + screen.width
        end
        task.Clear(self)
        if not self.locked then
            task.New(self, function()
                self.locked = true
                task.MoveTo(x, self.y, 30, 1)
            end)
            task.New(self, function()
                for i = 29, 0, -1 do
                    self.alpha0 = i / 30
                    task.Wait(1)
                end
            end)
        end
    end
    local function pushMenuStack(obj)
        obj = obj or empty_menu_obj
        if #menu_stack > 0 then
            menuFlyOut(menu_stack[#menu_stack], 'left')
        end
        table.insert(menu_stack, obj)
        menuFlyIn(obj, 'right')
    end
    local function popMenuStack()
        if #menu_stack > 0 then
            menuFlyOut(menu_stack[#menu_stack], 'right')
            table.remove(menu_stack)
        end
        if #menu_stack > 0 then
            menuFlyIn(menu_stack[#menu_stack], 'left')
        end
    end
    function setMod(mod_name)
        setting.mod = mod_name
        saveConfigure()
        pushMenuStack(nil)
        self.color_value_d = -1 / 30
        task.New(self, function()
            task.Wait(30)
            SceneManager.setNext("LauncherLoadingScene")
        end)
    end

    -- Mod 选择菜单
    local menu_mod = SelectMod.create(function()
        subui.sound.playConfirm()
        popMenuStack()
    end)

    -- 文本输入
    local menu_textinput = TextInput.create()

    -- 按键设置菜单
    local menu_key_setting = InputSettingHost.create(function()
        popMenuStack()
    end)

    -- 设置菜单
    local menu_setting = GameSetting.create(function()
        popMenuStack()
    end)

    -- 插件管理菜单
    local menu_plugin = PluginManager.create(function()
        popMenuStack()
    end)

    -- 版本更新菜单
    local version_view = VersionView.create(function()
        subui.sound.playConfirm()
        popMenuStack()
    end)

    -- 一级菜单
    ---@type launcher.menu.MainMenu
    local menu_main
    local function exitGame()
        subui.sound.playCancel()
        popMenuStack()
        self.color_value_d = -1 / 30
        task.New(self, function()
            task.Wait(30)
            stage.QuitGame()
        end)
    end
    local function exitMain()
        if menu_main._view._index == #menu_main._view._widget then
            exitGame()
        else
            menu_main._view:setCursorIndex(#menu_main._view._widget)
        end
    end
    local main_widgets = {
        { "launcher.menu.start", function()
            subui.sound.playConfirm()
            menu_mod:refresh()
            pushMenuStack(menu_mod)
        end },
        { "launcher.menu.username", function()
            subui.sound.playConfirm()
            menu_textinput:reset("launcher.menu.username", setting.username, function(text)
                if text then
                    setting.username = text
                    saveConfigure()
                end
                popMenuStack()
            end)
            pushMenuStack(menu_textinput)
        end },
        { "launcher.menu.setting.input.keyboard", function()
            subui.sound.playConfirm()
            menu_key_setting:refresh()
            pushMenuStack(menu_key_setting)
        end },
        { "launcher.menu.setting.game", function()
            subui.sound.playConfirm()
            menu_setting:refresh()
            pushMenuStack(menu_setting)
        end },
        { "launcher.menu.plugin_manager", function()
            subui.sound.playConfirm()
            menu_plugin:refresh()
            pushMenuStack(menu_plugin)
        end },
        { "$lang", function() end }, -- 被自己的代码丑到了……
    }
    -- 暂时不在这里做新版本检查，防止被报毒
    --local check_nv, nv_name = checkNewVersion()
    --if check_nv then
    --    table.insert(main_widgets, { "launcher.menu.found_new_version", function()
    --        subui.sound.playConfirm()
    --        version_view:refresh()
    --        pushMenuStack(version_view)
    --    end })
    --else
        table.insert(main_widgets, { "launcher.menu.check_new_version", function()
            subui.sound.playConfirm()
            version_view:refresh()
            pushMenuStack(version_view)
        end })
    --end
    table.insert(main_widgets, { "launcher.menu.exit", exitGame })
    menu_main = Main.create(exitMain, main_widgets)

    -- 开始场景
    subui.sound.playConfirm()
    pushMenuStack(menu_main)
end

function LauncherScene:onDestroy()
    lstg.RemoveResource("stage")
end

function LauncherScene:onUpdate()
    if Keyboard.GetKeyState(Keyboard.LeftControl) and InputSystem.isBooleanActionActivated("menu:retry") then
        stage.DestroyCurrentStage()
        lstg.DoFile("launcher.lua")
        InitAllClass()
        i18n.refresh()
    end
    -- 设置标题
    lstg.SetTitle(string.format("%s", gconfig.window_title)) -- 启动器阶段不用显示那么多信息
    -- 获取输入
    GetInput()
    subui.updateInput()
    -- 更新，这个场景不需要碰撞检测
    self.timer = self.timer + 1
    task.Do(self)
    self.color_value = math.max(0, math.min(self.color_value + self.color_value_d, 1))
    lstg.ObjFrame()
    -- 后更新
    lstg.UpdateXY()
    lstg.AfterFrame()
end

function LauncherScene:onRender()
    SetViewMode("ui")
    local rgb = 16 * self.color_value
    RenderClearViewMode(lstg.Color(255, rgb, rgb, rgb))
    SetViewMode("world")
    lstg.ObjRender()
end

SceneManager.setNext("LauncherScene")

--------------------------------------------------------------------------------
--- 启动器加载场景

---@class game.LauncherLoadingScene : foundation.Scene
local LauncherLoadingScene = SceneManager.add("LauncherLoadingScene")

function LauncherLoadingScene:onCreate()
    if lstg.FileManager and lstg.FileManager.AddSearchPath then
        if lstg.FileManager.FileExist(string.format("mod/%s.zip", setting.mod)) then
            lstg.LoadPack(string.format("mod/%s.zip", setting.mod))
        else
            lstg.FileManager.AddSearchPath(string.format("mod/%s/", setting.mod))
        end
    else
        lstg.LoadPack(string.format("mod/%s.zip", setting.mod))
    end

    lstg.SetSplash(false)
    lstg.SetTitle(setting.mod)
    --lstg.SetSEVolume(setting.sevolume / 100)
    --lstg.SetBGMVolume(setting.bgmvolume / 100)
    --if not lstg.ChangeVideoMode(setting.resx, setting.resy, setting.windowed, setting.vsync) then
    --    setting.windowed = true
    --    saveConfigure()
    --    if not lstg.ChangeVideoMode(setting.resx, setting.resy, setting.windowed, setting.vsync) then
    --        stage.QuitGame()
    --        return
    --    end
    --end
    --ResetScreen()

    lstg.SetResourceStatus("global")
    Include("root.lua")
    lstg.plugin.DispatchEvent("afterMod")
    lstg.RegisterAllGameObjectClass()
    lstg.SetResourceStatus("stage")

    InitScoreData()
    ext.reload()
    stage.Set("init", "none")
    SceneManager.setNext("GameScene") -- 此时 ext 也加载了，使用 GameScene 会更好
end
