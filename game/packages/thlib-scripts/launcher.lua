--------------------------------------------------------------------------------
--- THlib 启动器
--- code by 璀境石
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------

local i18n = require("lib.i18n")
local default_setting = require("foundation.legacy.default_setting")
local SceneManager = require("foundation.SceneManager")

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

local function checkNewVersion()
    local http = require("socket.http")
    local ltn12 = require("ltn12")
    local cjson = require("cjson")

    local t = {}
    local r, c, h = http.request({
        url = api_url_root .. "/framework/after-ex-plus/version/latest",
        method = "GET",
        sink = ltn12.sink.table(t),
    })

    if r and c == 200 then
        local json_text = table.concat(t)
        local json_data = cjson.decode(json_text)
        if isVersionHigher(gconfig.bundle_version, json_data.version) then
            return true, json_data.description
        end
    end

    return false, ""
end

---@param t any
local function validateVersionData(t)
    return type(t) == "table" and type(t.name) == "string" and type(t.version) == "string" and type(t.description) == "string"
end

local function getLatestVersion()
    -- 他奶奶的，luasocket 不支持 https，还得靠 curl
    local tmp = os.tmpname()
    local cmd = ("..\\tools\\curl\\curl.exe --get --output \"%s\" %s"):format(tmp, api_url_latest_framework_version)
    os.execute(cmd)
    local f = io.open(tmp, "r")
    if f then
        local s = f:read("*a")
        f:close()
        f = nil
        os.remove(tmp)
        local r, t = pcall(cjson.decode, s)
        if r and validateVersionData(t) then
            return true, t.description
        end
    end
    return false, ""
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
            { i18n_str("launcher.menu.version.download_source4"), function() lstg.Execute("https://luastg.ritsukage.com") end },
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

---@class launcher.menu.InputSetting : launcher.menu.Base
local InputSetting = Class(object)

---@param exit_f fun()
function InputSetting:init(exit_f)
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

    local key_code_to_name = KeyCodeToName()
    for i, v in ipairs(keys) do
        local idx = i
        local cfg = v

        local w_button = subui.widget.Button("", function() end)
        function w_button.updateText()
            local vkey = last_setting[cfg[3]]
            w_button.text = key_code_to_name[vkey]
        end
        w_button.callback = function()
            self.locked = true
            self._current_edit = idx
            task.New(self, function()
                local last_key = KEY.NULL
                for i = 1, 240 do
                    task.Wait(1)
                    last_key = lstg.GetLastKey()
                    if last_key ~= KEY.NULL then
                        break
                    end
                end
                if last_key ~= KEY.NULL then
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
end

function InputSetting:frame()
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
end

function InputSetting:render()
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
end

---@param exit_f fun()
---@return launcher.menu.InputSetting
function InputSetting.create(exit_f)
    return lstg.New(InputSetting, exit_f)
end

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
    local menu_key_setting = InputSetting.create(function()
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
end

function LauncherScene:onUpdate()
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
    subui.updateResources()
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
