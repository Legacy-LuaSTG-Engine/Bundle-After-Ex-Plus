--------------------------------------------------------------------------------
--- 简易的 UI 库，支持键盘、鼠标操作
--- 璀境石 2022-06-01
--------------------------------------------------------------------------------

---@class ui
local ui = {}

--------------------------------------------------------------------------------
--- 常量、基础函数

---@param v number
---@param v_min number
---@param v_max number
---@return number
local function clamp(v, v_min, v_max)
    v_min, v_max = math.min(v_min, v_max), math.max(v_min, v_max)
    return math.max(v_min, math.min(v, v_max))
end

local minimum_alpha = 1.0 / 255.0
local minimum_wheel = 1.0 / 120.0

local TTF_FMT = {
    left = 0x00000000,
    center = 0x00000001,
    right = 0x00000002,

    top = 0x00000000,
    vcenter = 0x00000004,
    bottom = 0x00000008,

    wordbreak = 0x00000010,
    paragraph = 0x00000010,

    centerpoint = 0x00000005,
}
setmetatable(TTF_FMT, { __index = function(_, _) return 0 end })

---@param ttf string
---@param text string
---@param l number
---@param r number
---@param b number
---@param t number
---@param scale number
---@param color lstg.Color
local function _drawTTF(ttf, text, l, r, b, t, scale, color, ...)
    local fmt = 0
    local arg = { ... }
    for i = 1, #arg do
        fmt = fmt + TTF_FMT[arg[i]]
    end
    lstg.RenderTTF(ttf, text, l, r, b, t, fmt, color, scale)
end

local _ttfdx = { -1, 1,  0, 0, -0.707, 0.707, -0.707,  0.707 }
local _ttfdy = {  0, 0, -1, 1,  0.707, 0.707, -0.707, -0.707 }
local _ttfbk = lstg.Color(0)
---@param ttf string
---@param text string
---@param l number
---@param r number
---@param b number
---@param t number
---@param color lstg.Color
function ui.drawTTF(ttf, text, l, r, b, t, color, ...)
    _ttfbk.a = color.a
    local s = 1.5
    for i = 1, 8 do
        _drawTTF(ttf, text, l + s * _ttfdx[i], r + s * _ttfdx[i], b + s * _ttfdy[i], t + s * _ttfdy[i], 1, _ttfbk, ...)
    end
    _drawTTF(ttf, text, l, r, b, t, 1, color, ...)
end
local drawTTF = ui.drawTTF

local color_white = lstg.Color(255, 255, 255, 255)
local color_focus = lstg.Color(255, 255, 255, 255)
local color_not_focus = lstg.Color(255, 160, 160, 160)
local color_press = lstg.Color(255, 160, 160, 255)

--------------------------------------------------------------------------------
--- UI 字体、纹理、音效资源

function ui.loadResources()
    if not lstg.CheckRes(8, "ttf:menu-font") then
        --local windir = os.getenv("windir")
        --if windir and string.len(windir) > 0 then
        --    lstg.Print("%WinDir%: " .. windir)
        --else
        --    windir = "C:\\Windows"
        --end
        --if not lstg.LoadTTF("ttf:menu-font", windir .. "\\Fonts\\msyhbd.ttc", 0, 36) then
        --    assert(lstg.LoadTTF("ttf:menu-font", windir .. "\\Fonts\\msyhbd.ttf", 0, 36))
        --end
        lstg.LoadTTF("ttf:menu-font", "assets/font/SourceHanSansCN-Bold.otf", 0, 36)
        lstg.CreateRenderTarget("rt:menu-white", 64, 64)
        lstg.LoadImage("img:menu-white", "rt:menu-white", 16, 16, 16, 16)
        if lstg.FileManager.FileExist("THlib/se/se_select00.wav", true) then
            lstg.LoadSound("se:menu-select", "THlib/se/se_select00.wav")
        end
        if lstg.FileManager.FileExist("THlib/se/se_ok00.wav", true) then
            lstg.LoadSound("se:menu-confirm", "THlib/se/se_ok00.wav")
        end
        if lstg.FileManager.FileExist("THlib/se/se_cancel00.wav", true) then
            lstg.LoadSound("se:menu-cancel", "THlib/se/se_cancel00.wav")
        end
    end
end

function ui.updateResources()
    ui.loadResources()
    -- 确保这个资源一直是可用的
    lstg.PushRenderTarget("rt:menu-white")
    lstg.RenderClear(lstg.Color(255, 255, 255, 255))
    lstg.PopRenderTarget()
end

--------------------------------------------------------------------------------
--- UI 音效

---@class ui.sound
local sound = {}
ui.sound = sound

function sound.playSelect()
    if lstg.CheckRes(5, "se:menu-select") then
        lstg.PlaySound("se:menu-select", 0.8, 0.0)
    end
end

function sound.playConfirm()
    if lstg.CheckRes(5, "se:menu-confirm") then
        lstg.PlaySound("se:menu-confirm", 0.8, 0.0)
    end
end

function sound.playCancel()
    if lstg.CheckRes(5, "se:menu-cancel") then
        lstg.PlaySound("se:menu-cancel", 0.8, 0.0)
    end
end

--------------------------------------------------------------------------------
--- UI 输入

local default_keyboard_map = {
    left = lstg.Input.Keyboard.Left,
    right = lstg.Input.Keyboard.Right,
    up = lstg.Input.Keyboard.Up,
    down = lstg.Input.Keyboard.Down,
    slow = lstg.Input.Keyboard.LeftShift,
    shoot = lstg.Input.Keyboard.Z,
    spell = lstg.Input.Keyboard.X,
}

function ui.KeyboardInput()
    ---@param k string
    ---@return table<string, number>
    local function getKeyMap(k)
        local map = default_keyboard_map
        if setting then
            if setting.keysys then
                if setting.keysys[k] then
                    map = setting.keysys
                end
            end
            if setting.keys then
                if setting.keys[k] and map == default_keyboard_map then
                    map = setting.keys
                end
            end
        end
        return map
    end

    local function makeButton()
        ---@class ui.KeyboardInput.Button
        local t = {}
        t.last_state = false
        t.state = false
        t.up = false
        t.down = false
        return t
    end

    ---@param t ui.KeyboardInput.Button
    ---@param k string
    local function updateButton(t, k)
        local map = getKeyMap(k)
        t.last_state = t.state
        t.state = lstg.GetKeyState(map[k])
        -- 按键按下
        if not t.last_state and t.state then
            t.down = true
        else
            t.down = false
        end
        t.down = t.down or (lstg.GetLastKey() == map[k]) -- Windows 的连击键功能
        -- 按键抬起
        if t.last_state and not t.state then
            t.up = true
        else
            t.up = false
        end
    end

    ---@class ui.KeyboardInput
    local cls = {}

    function cls:init()
        -- public
        self.left  = makeButton()
        self.right   = makeButton()
        self.up = makeButton()
        self.down = makeButton()
        self.shift = makeButton()
        self.confirm = makeButton()
        self.cancel = makeButton()
    end

    function cls:update()
        updateButton(self.left, "left")
        updateButton(self.right, "right")
        updateButton(self.up, "up")
        updateButton(self.down, "down")
        updateButton(self.shift, "slow")
        updateButton(self.confirm, "shoot")
        updateButton(self.cancel, "spell")
    end

    cls:init()
    return cls
end

local ui_keyboard = ui.KeyboardInput()
ui.keyboard = ui_keyboard

function ui.MouseInput()
    local function getMousePositionToUI()
        local mx, my = lstg.GetMousePosition() -- 左下角为原点，y 轴向上
        -- 转换到 UI 视口
        mx = mx - screen.dx
        my = my - screen.dy

        -- 方法一：正常思路

        -- 归一化
        --mx = mx / (screen.width * screen.scale)
        --my = my / (screen.height * screen.scale)
        -- 转换到 UI 坐标
        --mx = mx * screen.width
        --my = my * screen.height

        -- 方法二：由于 UI 坐标系左下角就是原点，直接用 screen.scale

        mx = mx / screen.scale
        my = my / screen.scale

        return mx, my
    end

    local function makeButton()
        ---@class ui.MouseInput.Button
        local t = {}
        t.last_state = false
        t.state = false
        t.up = false
        t.down = false
        return t
    end

    ---@param t ui.MouseInput.Button
    ---@param k number
    local function updateButton(t, k)
        t.last_state = t.state
        t.state = lstg.GetMouseState(k)
        -- 按键按下
        if not t.last_state and t.state then
            t.down = true
        else
            t.down = false
        end
        -- 按键抬起
        if t.last_state and not t.state then
            t.up = true
        else
            t.up = false
        end
    end

    ---@class ui.MouseInput
    local cls = {}

    function cls:init()
        -- public
        self.x, self.y = getMousePositionToUI()
        self.is_move = false
        self.wheel = 0
        self.is_wheel = false
        self.primary  = makeButton()
        self.middle   = makeButton()
        self.secondly = makeButton()
        self.xbutton1 = makeButton()
        self.xbutton2 = makeButton()

        -- private
        self._last_sx, self._last_sy = lstg.GetMousePosition()
    end

    function cls:update()
        self.is_move = false
        self.is_wheel = false
        self.x, self.y = getMousePositionToUI()
        self.wheel = lstg.GetMouseWheelDelta() / 120.0
        updateButton(self.primary, 0)
        updateButton(self.middle, 1)
        updateButton(self.secondly, 2)
        updateButton(self.xbutton1, 3)
        updateButton(self.xbutton2, 4)
        -- 检测是否有鼠标活动
        local sx, sy = lstg.GetMousePosition()
        if math.abs(sx - self._last_sx) > 0.5 or math.abs(sy - self._last_sy) > 0.5 then
            self.is_move = true
        end
        self._last_sx, self._last_sy = sx, sy
        if math.abs(self.wheel) >= minimum_wheel then
            self.is_wheel = true
        end
    end

    cls:init()
    return cls
end

local ui_mouse = ui.MouseInput()
ui.mouse = ui_mouse

---@param l number
---@param r number
---@param b number
---@param t number
---@return boolean
---@overload fun(l):boolean
function ui.isMouseInRect(l, r, b, t)
    if type(l) == "table" then
        return ui_mouse.x > l.x and ui_mouse.x < (l.x + l.width) and ui_mouse.y > (l.y - l.height) and ui_mouse.y < l.y
    else
        return ui_mouse.x > l and ui_mouse.x < r and ui_mouse.y > b and ui_mouse.y < t
    end
end
local isMouseInRect = ui.isMouseInRect

function ui.updateInput()
    ui_mouse:update()
    ui_keyboard:update()
end

--------------------------------------------------------------------------------
--- UI 控件

---@class ui.widget
local widget = {}
ui.widget = widget

---@param text string
function widget.Text(text)
    ---@class ui.widget.Text
    local cls = {}

    ---@param text_ string
    function cls:init(text_)
        -- ui.widget.Text
        self.disable = false
        self.alpha = 1.0
        self.text = text_
        self.x = 0
        self.y = 0
        self.width = 64.0
        self.height = 16.0
        self.halign = "left"
        self.valign = "vcenter"

        -- private
        self._focus = false
        self._press = false
    end

    ---@param focus boolean
    function cls:update(focus)
        self._focus = focus
    end

    function cls:draw()
        if self.alpha < minimum_alpha then
            return
        end
        if string.len(self.text) < 1 then
            return
        end
        local color = color_not_focus
        if self._press then
            color = color_press
        elseif self._focus then
            color = color_focus
        end
        color.a = self.alpha * 255
        drawTTF("ttf:menu-font", self.text,
            self.x, self.x + self.width,
            self.y - self.height, self.y,
            color,
            self.halign, self.valign)
        color.a = 255
    end

    cls:init(text)
    return cls
end

---@param text string
---@param callback fun()
function widget.Button(text, callback)
    ---@class ui.widget.Button : ui.widget.Text
    local cls = {}

    ---@param text_ string
    ---@param callback_ fun()
    function cls:init(text_, callback_)
        -- ui.widget.Text
        self.disable = false
        self.alpha = 1.0
        self.text = text_
        self.x = 0
        self.y = 0
        self.width = 64.0
        self.height = 16.0
        self.halign = "left"
        self.valign = "vcenter"

        -- ui.widget.Button
        self.callback = callback_

        -- private
        self._focus = false
        self._focus_v = 0.0
        self._press = false
        self._last_press_is_mouse = false
    end

    ---@param focus boolean
    function cls:update(focus)
        self._focus = focus
        if self._focus and not self.disable then
            if not self._press then
                if ui_keyboard.confirm.down then
                    self._press = true
                    self._last_press_is_mouse = false
                elseif isMouseInRect(self) and ui_mouse.primary.down then
                    self._press = true
                    self._last_press_is_mouse = true
                end
            elseif self._press and not ui_keyboard.confirm.state then
                if not self._last_press_is_mouse then
                    if not ui_keyboard.confirm.state then
                        self._press = false
                        self.callback() -- 抬起时才触发
                    end
                else
                    if not ui_mouse.primary.state then
                        self._press = false
                        self.callback() -- 抬起时才触发
                    end
                end
            end
        else
            self._press = false -- 润了
        end
        if self._focus then
            self._focus_v = math.min(self._focus_v + 0.1, 1)
        else
            self._focus_v = math.max(0, self._focus_v - 0.1)
        end
    end

    function cls:draw()
        if self.alpha < minimum_alpha then
            return
        end
        local color = color_not_focus
        if self._press then
            color = color_press
        elseif self._focus then
            color = color_focus
        end
        color.a = self.alpha * 255
        lstg.SetImageState("img:menu-white", "", lstg.Color(self.alpha * self._focus_v * 32, 255, 255, 255))
        lstg.RenderRect("img:menu-white",
            self.x, self.x + self.width,
            self.y - self.height, self.y)
        drawTTF("ttf:menu-font", self.text,
            self.x, self.x + self.width,
            self.y - self.height, self.y,
            color,
            self.halign, self.valign)
        color.a = 255
    end

    cls:init(text, callback)
    return cls
end

function widget.CheckBox()
    ---@class ui.widget.CheckBox
    local cls = {}

    function cls:init()
        -- ui.widget.Text
        self.disable = false
        self.alpha = 1.0
        self.text = ""
        self.x = 0
        self.y = 0
        self.width = 64.0
        self.height = 16.0
        self.halign = "left"
        self.valign = "vcenter"

        self._value = false
        self._value_v = 0.0

        ---@type fun(value:boolean)
        self.callback = function(value) end

        self._enbale_getter_setter = false
        ---@type fun():boolean
        self._getter = function() return false end
        ---@type fun(value:boolean)
        self._setter = function(value) end

        function self._getValue()
            if self._enbale_getter_setter then
                return self._getter()
            else
                return self._value
            end
        end
        ---@param v boolean
        function self._setValue(v)
            if self._enbale_getter_setter then
                self._setter(v)
            else
                self._value = v
            end
            self.callback(v)
        end
        function self._toggleValue()
            local v = self._getValue()
            self._setValue(not v)
        end

        self._focus = false
        self._focus_v = 0.0

        self._toggle_button = widget.Button("", function()
            self._toggleValue()
        end)
    end

    ---@param text string
    function cls:setText(text)
        self.text = text
        return self
    end

    ---comment
    ---@param x number
    ---@param y number
    ---@param width number
    ---@param height number
    function cls:setRect(x, y, width, height)
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        return self
    end

    ---@param value boolean
    function cls:setValue(value)
        self._value = value
        return self
    end

    ---@param callback fun(value:boolean)
    ---@param getter fun():boolean
    ---@param setter fun(value:boolean)
    ---@overload fun(self:ui.widget.CheckBox, callback:fun(value:boolean)):ui.widget.CheckBox
    function cls:setCallback(callback, getter, setter)
        self.callback = callback
        if getter and setter then
            self._enbale_getter_setter = true
            self._getter = getter
            self._setter = setter
        else
            self._enbale_getter_setter = false
        end
        return self
    end

    ---@param focus boolean
    function cls:update(focus)
        self._focus = focus
        if self._focus and not self.disable then
            if ui_keyboard.confirm.down then
                self._toggleValue()
            end
        end

        self._toggle_button.x = self.x + self.width - self.height
        self._toggle_button.y = self.y
        self._toggle_button.width = self.height
        self._toggle_button.height = self.height
        self._toggle_button:update(self._focus and ui.isMouseInRect(self._toggle_button))

        if self._focus then
            self._focus_v = math.min(self._focus_v + 0.1, 1)
        else
            self._focus_v = math.max(0, self._focus_v - 0.1)
        end
        if self._getValue() then
            self._value_v = math.min(self._value_v + 0.25, 1)
        else
            self._value_v = math.max(0, self._value_v - 0.25)
        end
    end

    function cls:draw()
        if self.alpha < minimum_alpha then
            return
        end
        local color = color_not_focus
        if self._focus then
            color = color_focus
        end
        color.a = self.alpha * 255

        -- 焦点底色

        lstg.SetImageState("img:menu-white", "", lstg.Color(self.alpha * self._focus_v * 32, 255, 255, 255))
        lstg.RenderRect("img:menu-white",
            self.x, self.x + self.width,
            self.y - self.height, self.y)

        -- 标签文本

        drawTTF("ttf:menu-font", self.text,
            self.x, self.x + self.width,
            self.y - self.height, self.y,
            color,
            self.halign, self.valign)

        -- 绘制点击框

        local bboxl = self.x + self.width - self.height
        local bboxr = self.x + self.width
        local bboxb = self.y - self.height
        local bboxt = self.y

        lstg.SetImageState("img:menu-white", "", lstg.Color(self.alpha * 255, 0, 0, 0))
        lstg.RenderRect("img:menu-white", bboxl, bboxr, bboxb, bboxt)

        lstg.SetImageState("img:menu-white", "", color)
        lstg.RenderRect("img:menu-white", bboxl + 2, bboxr - 2, bboxb + 2, bboxt - 2)

        lstg.SetImageState("img:menu-white", "", lstg.Color(self.alpha * 255, 0, 0, 0))
        lstg.RenderRect("img:menu-white", bboxl + 4, bboxr - 4, bboxb + 4, bboxt - 4)

        if self._value_v > 0.0001 then
            local cx = (bboxl + bboxr) * 0.5
            local cy = (bboxb + bboxt) * 0.5
            local k = math.sin(math.pi * 0.5 * self._value_v)
            local w2 = k * (bboxr - bboxl - 4 - 4) * 0.5
            local h2 = k * (bboxt - bboxb - 4 - 4) * 0.5
            lstg.SetImageState("img:menu-white", "", color)
            lstg.RenderRect("img:menu-white", cx - w2, cx + w2, cy - h2, cy + h2)
        end

        color.a = 255
    end

    cls:init()
    return cls
end

function widget.Slider()
    ---@class ui.widget.Slider
    local cls = {}

    function cls:init()
        -- ui.widget.Text
        self.disable = false
        self.alpha = 1.0
        self.text = ""
        self.x = 0
        self.y = 0
        self.width = 64.0
        self.height = 16.0
        self.halign = "left"
        self.valign = "vcenter"

        self._split_factor = 0.5 -- 标签、滑条各占一半

        ---@type fun(value:number)
        self.callback = function(value) end
        self._enbale_getter_setter = false
        ---@type fun():number
        self._getter = function() return 0.0 end
        ---@type fun(value:number)
        self._setter = function(value) end

        self._value = 0
        self._value_min = 0
        self._value_max = 0
        self._value_fmt = "%.2f"
        self._step = 0
        self._step_slow = 0
        self._step_fast = 0

        self._focus = false
        self._focus_v = 0.0

        function self._getValue()
            if self._enbale_getter_setter then
                return self._getter()
            else
                return self._value
            end
        end
        ---@param v number
        function self._setValue(v)
            if self._enbale_getter_setter then
                self._setter(v)
            else
                self._value = v
            end
            self.callback(v)
        end
        ---@param factor number
        ---@param slow_flag boolean
        ---@param fast_flag boolean
        function self._addValue(factor, slow_flag, fast_flag)
            local v = self._getValue()
            local dv = self._step
            if fast_flag then
                dv = self._step_fast
            elseif slow_flag then
                dv = self._step_slow
            end
            v = v + dv * factor
            v = math.max(self._value_min, math.min(v, self._value_max))
            self._setValue(v)
        end

        self._left_button = widget.Button("<", function()
            self._addValue(-1, ui_keyboard.shift.state, ui_keyboard.confirm.state)
        end)
        self._left_button.width = 24

        self._right_button = widget.Button(">", function()
            self._addValue(1, ui_keyboard.shift.state, ui_keyboard.confirm.state)
        end)
        self._right_button.width = 24
        self._right_button.halign = "right"

        self._is_drag = false
        self._last_drag_v = 0
        self._last_drag_x = 0
        self._last_drag_y = 0
    end

    ---@param text string
    ---@return ui.widget.Slider
    function cls:setText(text)
        self.text = text
        return self
    end

    ---comment
    ---@param x number
    ---@param y number
    ---@param width number
    ---@param height number
    ---@return ui.widget.Slider
    function cls:setRect(x, y, width, height)
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        return self
    end

    ---@param value number
    ---@param value_min number
    ---@param value_max number
    ---@param value_fmt string
    ---@return ui.widget.Slider
    ---@overload fun(self:ui.widget.Slider, value:number, value_min:number, value_max:number)
    function cls:setValue(value, value_min, value_max, value_fmt)
        self._value = value
        self._value_min = value_min
        self._value_max = value_max
        if value_fmt then
            self._value_fmt = value_fmt
        end
        return self
    end

    ---@param step number
    ---@param step_slow number
    ---@param step_fast number
    ---@return ui.widget.Slider
    function cls:setValueStep(step, step_slow, step_fast)
        self._step = step
        self._step_slow = step_slow
        self._step_fast = step_fast
        return self
    end

    ---@param callback fun(value:number)
    ---@param getter fun():number
    ---@param setter fun(value:number)
    ---@return ui.widget.Slider
    ---@overload fun(self:ui.widget.Slider, callback:fun(value:number)):ui.widget.Slider
    function cls:setCallback(callback, getter, setter)
        self.callback = callback
        if getter and setter then
            self._enbale_getter_setter = true
            self._getter = getter
            self._setter = setter
        else
            self._enbale_getter_setter = false
        end
        return self
    end

    ---@param focus boolean
    function cls:update(focus)
        self._focus = focus
        if self._focus and not self.disable then
            if ui_keyboard.left.down then
                self._addValue(-1, ui_keyboard.shift.state, ui_keyboard.confirm.state)
            elseif ui_keyboard.right.down then
                self._addValue(1, ui_keyboard.shift.state, ui_keyboard.confirm.state)
            end
            -- 拖拽逻辑
            local bboxl = self.x + self.width * self._split_factor + self._left_button.width + 4
            local bboxr = self.x + self.width - self._right_button.width - 4
            local bboxb = self.y - self.height + 4
            local bboxt = self.y - 4
            if not self._is_drag and ui_mouse.primary.down and ui.isMouseInRect(bboxl, bboxr, bboxb, bboxt) then
                self._is_drag = true
                self._last_drag_v = self._getValue()
                self._last_drag_x = ui_mouse.x
                self._last_drag_y = ui_mouse.y
            elseif self._is_drag and (not ui_mouse.primary.state or not ui.isMouseInRect(self)) then
                self._is_drag = false
            elseif self._is_drag and ui_mouse.is_move then
                local k = (ui_mouse.x - self._last_drag_x) / (bboxr - bboxl)
                local dv = k * (self._value_max - self._value_min)
                local v = clamp(self._last_drag_v + dv, self._value_min, self._value_max)
                self._setValue(v)
            end
        else
            self._is_drag = false
        end

        self._left_button.x = self.x + self.width * self._split_factor
        self._left_button.y = self.y
        self._left_button.height = self.height
        self._left_button:update(self._focus and ui.isMouseInRect(self._left_button))

        self._right_button.x = self.x + self.width - self._right_button.width
        self._right_button.y = self.y
        self._right_button.height = self.height
        self._right_button:update(self._focus and ui.isMouseInRect(self._right_button))

        if self._focus then
            self._focus_v = math.min(self._focus_v + 0.1, 1)
        else
            self._focus_v = math.max(0, self._focus_v - 0.1)
        end
    end

    function cls:draw()
        if self.alpha < minimum_alpha then
            return
        end
        local color = color_not_focus
        if self._focus then
            color = color_focus
        end
        color.a = self.alpha * 255

        -- 焦点底色

        lstg.SetImageState("img:menu-white", "", lstg.Color(self.alpha * self._focus_v * 32, 255, 255, 255))
        lstg.RenderRect("img:menu-white",
            self.x, self.x + self.width,
            self.y - self.height, self.y)

        -- 标签文本

        drawTTF("ttf:menu-font", self.text,
            self.x, self.x + self.width,
            self.y - self.height, self.y,
            color,
            self.halign, self.valign)

        -- 绘制滑条

        local bboxl = self.x + self.width * self._split_factor + self._left_button.width
        local bboxr = self.x + self.width - self._right_button.width
        local bboxb = self.y - self.height
        local bboxt = self.y

        lstg.SetImageState("img:menu-white", "", lstg.Color(self.alpha * 255, 0, 0, 0))
        lstg.RenderRect("img:menu-white", bboxl, bboxr, bboxb, bboxt)

        lstg.SetImageState("img:menu-white", "", color)
        lstg.RenderRect("img:menu-white", bboxl + 2, bboxr - 2, bboxb + 2, bboxt - 2)

        lstg.SetImageState("img:menu-white", "", lstg.Color(self.alpha * 255, 0, 0, 0))
        lstg.RenderRect("img:menu-white", bboxl + 4, bboxr - 4, bboxb + 4, bboxt - 4)

        local k = 0.0
        if self._value_min ~= self._value_max then
            k = math.max(0.0, math.min((self._getValue() - self._value_min) / (self._value_max - self._value_min), 1.0))
        else
            k = 1.0
        end
        local l = bboxl + 4
        local w = bboxr - 4 - l
        local r = l + k * w
        lstg.SetImageState("img:menu-white", "", color)
        lstg.RenderRect("img:menu-white", l, r, bboxb + 4, bboxt - 4)

        drawTTF("ttf:menu-font", string.format(self._value_fmt, self._getValue()),
            bboxl, bboxr, bboxb, bboxt,
            color,
            "center", self.valign)

        -- 按钮

        self._left_button:draw()
        self._right_button:draw()

        color.a = 255
    end

    cls:init()
    return cls
end

function widget.SimpleSelector()
    ---@class ui.widget.SimpleSelector
    local cls = {}

    function cls:init()
        -- ui.widget.Text
        self.disable = false
        self.alpha = 1.0
        self.text = ""
        self.x = 0
        self.y = 0
        self.width = 64.0
        self.height = 16.0
        self.halign = "left"
        self.valign = "vcenter"

        self._split_factor = 0.5 -- 标签、滑条各占一半

        self._value = 1
        self._value_v = 1
        ---@type string[]
        self._item = { "" }

        ---@type fun(value:number)
        self.callback = function(value) end

        self._enbale_getter_setter = false
        ---@type fun():number
        self._getter = function() return false end
        ---@type fun(value:number)
        self._setter = function(value) end

        function self._getValue()
            if self._enbale_getter_setter then
                return self._getter()
            else
                return self._value
            end
        end
        ---@param v number
        function self._setValue(v)
            if self._enbale_getter_setter then
                self._setter(v)
            else
                self._value = v
            end
            self.callback(v)
        end
        ---@param factor number
        function self._addValue(factor)
            local v = self._getValue()
            if #self._item > 0 then
                v = clamp(v + factor, 1, #self._item)
            else
                v = 1
            end
            self._setValue(v)
        end

        self._focus = false
        self._focus_v = 0.0

        self._left_button = widget.Button("<", function()
            self._addValue(-1)
        end)
        self._left_button.width = 24

        self._right_button = widget.Button(">", function()
            self._addValue(1)
        end)
        self._right_button.width = 24
        self._right_button.halign = "right"
    end

    ---@param text string
    function cls:setText(text)
        self.text = text
        return self
    end

    ---comment
    ---@param x number
    ---@param y number
    ---@param width number
    ---@param height number
    function cls:setRect(x, y, width, height)
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        return self
    end

    ---@param callback fun(value:number)
    ---@param getter fun():number
    ---@param setter fun(value:number)
    ---@return ui.widget.SimpleSelector
    ---@overload fun(self:ui.widget.SimpleSelector, callback:fun(value:number)):ui.widget.SimpleSelector
    function cls:setCallback(callback, getter, setter)
        self.callback = callback
        if getter and setter then
            self._enbale_getter_setter = true
            self._getter = getter
            self._setter = setter
        else
            self._enbale_getter_setter = false
        end
        return self
    end

    ---@param focus boolean
    function cls:update(focus)
        self._focus = focus
        if self._focus and not self.disable then
            if ui_keyboard.left.down then
                self._addValue(-1)
            elseif ui_keyboard.right.down then
                self._addValue(1)
            end
        end

        self._left_button.x = self.x + self.width * self._split_factor
        self._left_button.y = self.y
        self._left_button.height = self.height
        self._left_button:update(self._focus and ui.isMouseInRect(self._left_button))

        self._right_button.x = self.x + self.width - self._right_button.width
        self._right_button.y = self.y
        self._right_button.height = self.height
        self._right_button:update(self._focus and ui.isMouseInRect(self._right_button))

        if self._focus then
            self._focus_v = math.min(self._focus_v + 0.1, 1)
        else
            self._focus_v = math.max(0, self._focus_v - 0.1)
        end
    end

    function cls:draw()
        if self.alpha < minimum_alpha then
            return
        end
        local color = color_not_focus
        if self._focus then
            color = color_focus
        end
        color.a = self.alpha * 255

        -- 焦点底色

        lstg.SetImageState("img:menu-white", "", lstg.Color(self.alpha * self._focus_v * 32, 255, 255, 255))
        lstg.RenderRect("img:menu-white",
            self.x, self.x + self.width,
            self.y - self.height, self.y)

        -- 文本标签

        drawTTF("ttf:menu-font", self.text,
            self.x, self.x + self.width,
            self.y - self.height, self.y,
            color,
            "left", self.valign)

        -- 内容

        if #self._item > 0 then
            drawTTF("ttf:menu-font", self._item[self._getValue()],
                self.x + self.width * self._split_factor, self.x + self.width,
                self.y - self.height, self.y,
                color,
                "center", self.valign)
        end

        -- 按钮

        self._left_button:draw()
        self._right_button:draw()

        color.a = 255
    end

    cls:init()
    return cls
end

--------------------------------------------------------------------------------
--- UI 布局

---@class ui.layout
local layout = {}
ui.layout = layout

---@param width number
---@param height number
function layout.LinearScrollView(width, height)
    ---@class ui.layout.LinearScrollView
    local cls = {}

    ---@param width_ number
    ---@param height_ number
    function cls:init(width_, height_)
        self.alpha = 1.0
        self.x = 0
        self.y = 0
        self.width = width_
        self.height = height_
        self.scroll_height = 16

        ---@type ui.widget.Text[]
        self._widget = {}
        self._index = 1 -- 即使一个控件都没有
        self._focus = false
        self._view_offset_y = 0.0
        self._view_offset_y_v = 0.0 -- 平滑
    end

    ---@param idx number
    function cls:setCursorIndex(idx)
        -- 光标移动
        self._index = idx
        sound.playSelect()
        -- 限制光标位置
        if #self._widget > 0 then
            self._index = math.max(1, math.min(self._index, #self._widget))
        else
            self._index = 1
        end
        -- 更新控件布局位置
        if #self._widget > 0 then
            -- 计算控件上边缘到布局顶部的高度
            local total_offset_top = 0
            for i = 1, (self._index - 1) do
                total_offset_top = total_offset_top + self._widget[i].height
            end
            -- 计算控件下边缘到布局顶部的高度
            local total_offset_bottom = total_offset_top + self._widget[self._index].height
            -- 限制布局位置
            if self._view_offset_y > total_offset_top then
                self._view_offset_y = math.min(self._view_offset_y, total_offset_top) -- 布局向上偏移不能太大，不然控件上边缘就超过视图上边缘
            elseif (total_offset_bottom - self._view_offset_y) > self.height then
                self._view_offset_y = math.max(self._view_offset_y, total_offset_bottom - self.height) -- 布局向上偏移不能太小，不然控件下边缘就超过视图下边缘
            end
        end
    end

    ---@param focus boolean
    function cls:update(focus)
        self._focus = focus
        local _focus = focus
        -- 看看鼠标有没有指到视图里
        local is_mouse_in_view = false
        if ui_mouse.x > self.x and ui_mouse.x < (self.x + self.width) and ui_mouse.y > (self.y - self.height) and ui_mouse.y < self.y then
            is_mouse_in_view = true
        end
        -- 更新当前的焦点控件
        local update_by_keyboard = false
        local update_by_mouse = false
        if _focus then
            -- 光标移动
            if ui_keyboard.up.down then
                self._index = self._index - 1
                update_by_keyboard = true
                sound.playSelect()
            elseif ui_keyboard.down.down then
                self._index = self._index + 1
                update_by_keyboard = true
                sound.playSelect()
            end
            -- 限制光标位置
            if #self._widget > 0 then
                self._index = math.max(1, math.min(self._index, #self._widget))
            else
                self._index = 1
            end
            -- 鼠标滚轮
            if is_mouse_in_view and ui_mouse.is_wheel then
                self._view_offset_y = self._view_offset_y - ui_mouse.wheel * self.scroll_height
                update_by_mouse = true
            end
        end
        -- 更新控件布局位置
        if #self._widget > 0 then
            if update_by_keyboard then
                -- 计算控件上边缘到布局顶部的高度
                local total_offset_top = 0
                for i = 1, (self._index - 1) do
                    total_offset_top = total_offset_top + self._widget[i].height
                end
                -- 计算控件下边缘到布局顶部的高度
                local total_offset_bottom = total_offset_top + self._widget[self._index].height
                -- 限制布局位置
                if self._view_offset_y > total_offset_top then
                    self._view_offset_y = math.min(self._view_offset_y, total_offset_top) -- 布局向上偏移不能太大，不然控件上边缘就超过视图上边缘
                elseif (total_offset_bottom - self._view_offset_y) > self.height then
                    self._view_offset_y = math.max(self._view_offset_y, total_offset_bottom - self.height) -- 布局向上偏移不能太小，不然控件下边缘就超过视图下边缘
                end
            else
                -- 计算控件总高度
                local total_height = 0
                for _, v in ipairs(self._widget) do
                    total_height = total_height + v.height
                end
                -- 限制布局位置
                self._view_offset_y = math.max(0, math.min(self._view_offset_y, total_height - self.height))
            end
        end
        -- 平滑过渡
        self._view_offset_y_v = self._view_offset_y + (self._view_offset_y_v - self._view_offset_y) * 0.8
        -- 更新控件位置
        do
            local top = self.y
            for _, w in ipairs(self._widget) do
                w.x = self.x
                w.y = top + self._view_offset_y_v
                top = top - w.height
            end
        end
        -- 如果鼠标动了，看看鼠标指到了哪个控件上
        if _focus then
            if is_mouse_in_view and (ui_mouse.is_move or update_by_mouse) then
                local mouse_focus_index = 0
                for i, w in ipairs(self._widget) do
                    if ui_mouse.x > w.x and ui_mouse.x < (w.x + w.width) and ui_mouse.y > (w.y - w.height) and ui_mouse.y < w.y then
                        mouse_focus_index = i
                        break
                    end
                end
                if mouse_focus_index > 0 then
                    if self._index ~= mouse_focus_index then
                        sound.playSelect()
                    end
                    self._index = mouse_focus_index
                end
            end
        end
        -- 更新所有控件
        for i, w in ipairs(self._widget) do
            w:update(_focus and (i == self._index))
        end
    end

    function cls:draw()
        if self.alpha < minimum_alpha then
            return
        end
        for _, w in ipairs(self._widget) do
            -- 判断控件是不是在视图范围内
            local a = 1.0
            if (w.y - w.height) > self.y then
                -- 控件下边缘超出视图上边缘
                a = 0.0
            elseif w.y < (self.y - self.height) then
                -- 控件上边缘超出视图下边缘
                a = 0.0
            elseif w.y > self.y then
                -- 控件上边缘超出视图上边缘，需要透明度过渡
                a = 1.0 - ((w.y - self.y) / w.height)
            elseif (w.y - w.height) < (self.y - self.height) then
                -- 控件下边缘超出视图下边缘，需要透明度过渡
                a = 1.0 - (((self.y - self.height) - (w.y - w.height)) / w.height)
            end
            -- 渲染控件
            if a >= minimum_alpha then
                local old_a = w.alpha
                w.alpha = self.alpha * w.alpha * a
                w:draw()
                w.alpha = old_a
            end
        end
    end

    ---@param w ui.widget.Text
    function cls:insert(w)
        self:remove(w)
        table.insert(self._widget, w)
    end

    ---@param w ui.widget.Text
    function cls:remove(w)
        for i = #self._widget, 1, -1 do
            if w == self._widget[i] then
                table.remove(self._widget, i)
            end
        end
    end

    ---@param ws ui.widget.Text[]
    function cls:setWidgets(ws)
        self._widget = ws
        if #self._widget > 0 then
            self._index = math.max(1, math.min(self._index, #self._widget))
        else
            self._index = 1
        end
    end

    cls:init(width, height)
    return cls
end

--- TODO
---@param width number
---@param height number
function layout.StaticView(width, height)
    ---@class ui.layout.StaticView
    local cls = {}

    ---@param width_ number
    ---@param height_ number
    function cls:init(width_, height_)
        self.alpha = 1.0
        self.x = 0
        self.y = 0
        self.width = width_
        self.height = height_

        ---@type ui.widget.Text[]
        self._widget = {}
        self._index = 1 -- 即使一个控件都没有
        self._focus = false
    end
end

return ui
