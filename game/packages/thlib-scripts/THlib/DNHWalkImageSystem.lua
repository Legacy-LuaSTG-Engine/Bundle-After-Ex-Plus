--[[
动作函数定义：
参数：
wisys    行走图系统自身
self    绑定的渲染对象
actionCount    当前状态已执行帧（静止图固定为0）
actionCountMax    当前状态执行目标帧数
返回：
id    图像id（默认1）
hscale    相对宽比缩放（默认1）
vscale    相对高比缩放（默认1）
rot    相对角度旋转（默认0）
dx    相对x偏移（默认0）
dy    相对y偏移（默认0）
--]]
--[[
漂浮函数定义：
参数：
ani    绑定的渲染对象的ani计数器
返回：
dx    相对x偏移（默认0）
dy    相对y偏移（默认0）
--]]

---默认静止图函数
---固定返回id1
local _ACT_NONE = function(wisys, self, actionCount, actionCountMax)
    return 1
end

---默认左移动函数
---返回第二行的第1或2个id
local _ACT_MOVE_L = function(wisys, self, actionCount, actionCountMax)
    local cutFrame = 8
    local anime = int(actionCount / cutFrame)
    local anime_max = int((actionCountMax - actionCount) / cutFrame)
    anime = min(min(anime, 1), anime_max)
    return wisys.nRow + anime + 1
end

---默认右移动函数
---返回第二行的第3或第4个id
local _ACT_MOVE_R = function(wisys, self, actionCount, actionCountMax)
    local cutFrame = 8
    local anime = int(actionCount / cutFrame)
    local anime_max = int((actionCountMax - actionCount) / cutFrame)
    anime = min(min(anime, 1), anime_max)
    return wisys.nRow + anime + 3
end

---默认移动分发函数
---仅适配单方向移动
---分发至设置的（或默认的）左移动与右移动函数
local _ACT_MOVE = function(wisys, self, actionCount, actionCountMax)
    local dx = self.dx or 0
    local action
    if dx < 0 then
        action = wisys:getActionFunc("move_left") or _ACT_MOVE_L
    elseif dx > 0 then
        action = wisys:getActionFunc("move_right") or _ACT_MOVE_R
    else
        action = wisys:getActionFunc("normal") or _ACT_NONE
    end
    if actionCount > 15 and abs(dx) < 0.25 then
        actionCount = max(actionCount, actionCountMax - 12)
        wisys.actionCount = actionCount
    end
    return action(wisys, self, actionCount, actionCountMax)
end

---@return DNHWalkImageSystem
DNHWalkImageSystem = plus.Class()
---@class DNHWalkImageSystem
local dnh = DNHWalkImageSystem

---基础创建函数
---@param obj table @绑定渲染对象
---@param tex string @绑定渲染纹理
---@param x number @纹理起始x偏移量
---@param y number @纹理起始y偏移量
---@param w number @单帧图像宽度
---@param h number @单帧图像高度
---@param n number @一行的id数
function dnh:init(obj, tex, x, y, w, h, n)
    self.obj = obj
    self.hs, self.vs = 1, 1
    self.rot = 0
    self.dx, self.dy = 0, 0
    self._dx, self._dy = 0, 0
    self.actionFunc = {}
    self:connectAction("normal", _ACT_NONE)
    self:connectAction("move", _ACT_MOVE)
    self:connectAction("move_left", _ACT_MOVE_L)
    self:connectAction("move_right", _ACT_MOVE_R)
    self:setAction("normal")
    self:setTex(tex)
    self:setParam(x, y, w, h, n)
    self:setBlend("")
    self:setColor(0xFFFFFFFF)
end

local function check_color(obj)
    if obj._blend and obj._a and obj._r and obj._g and obj._b then
        return obj._blend, Color(obj._a, obj._r, obj._g, obj._b)
    end
end

---帧逻辑
function dnh:frame()
    if self.actionCount < self.actionCountMax then
        self.actionCount = self.actionCount + 1
    else
        self:setAction("normal")
    end
    local id, hs, vs, rot, dx, dy = self:getID()
    self.id = id
    self.hs = hs or 1
    self.vs = vs or 1
    self.rot = rot or 0
    self.dx = dx or 0
    self.dy = dy or 0
    local _dx, _dy
    if self.floating_func then
        _dx, _dy = self.floating_func(self.obj.ani)
    elseif self.floating then
        _dx = self.floating.dx or 0
        _dy = self.floating.dy or 0
    end
    self._dx, self._dy = _dx or 0, _dy or 0
    self._blend, self._color = check_color(self.obj)
end

---获取旋转坐标
---@param cx number @中心x
---@param cy number @中心y
---@param dx number @要旋转的坐标相对x坐标
---@param dy number @要旋转的坐标相对y坐标
---@param a number @要旋转的角度
---@return number, number
local function get_pos(cx, cy, dx, dy, a)
    local x0 = dx * cos(a) - dy * sin(a) + cx
    local y0 = dx * sin(a) + dy * cos(a) + cy
    return x0, y0
end

---渲染逻辑
function dnh:render(dmgt, dmgmaxt)
    if self.obj and self.tex then
        local c = 0
        local blend = self._blend or self.blend
        local color = self._color or self.color
        if dmgt and dmgmaxt then
            c = dmgt / dmgmaxt
            local a, r, g, b = color:ARGB()
            color = Color(a, r - r * c, g - g * c, b)
        end
        local id = self.id or 1
        local col = int((id - 1) / self.img_n)
        local row = id - (col * self.img_n)
        local _x = self.img_x + self.img_w * (row - 1)
        local _y = self.img_y + self.img_h * col
        local x = self.obj.x + self.dx + self._dx
        local y = self.obj.y + self.dy + self._dy
        local w = self.img_w * self.obj.hscale / 2 * self.hs
        local h = self.img_h * self.obj.vscale / 2 * self.vs
        local rot = self.rot + self.obj.rot
        local px, py = get_pos(x, y, -w, h, rot)
        local p1 = { px, py, 0.5, _x, _y, color }
        px, py = get_pos(x, y, w, h, rot)
        local p2 = { px, py, 0.5, _x + self.img_w, _y, color }
        px, py = get_pos(x, y, w, -h, rot)
        local p3 = { px, py, 0.5, _x + self.img_w, _y + self.img_h, color }
        px, py = get_pos(x, y, -w, -h, rot)
        local p4 = { px, py, 0.5, _x, _y + self.img_h, color }
        RenderTexture(self.tex, blend, p1, p2, p3, p4)
    end
end

---设置绑定纹理
---@param tex string @目标纹理
function dnh:setTex(tex)
    self.tex = tex
end

---设置图像信息
---@param x number @纹理起始x偏移量
---@param y number @纹理起始y偏移量
---@param w number @单帧图像宽度
---@param h number @单帧图像高度
---@param n number @一行的id数
function dnh:setParam(x, y, w, h, n)
    self.img_x = x
    self.img_y = y
    self.img_w = w
    self.img_h = h
    self.img_n = n
end

---绑定函数至状态
---@param action string @目标状态
---@param func function @目标函数
function dnh:connectAction(action, func)
    self.actionFunc[action] = func
end

---设置状态
---@param action string @目标状态
---@param duration number @持续总帧数
function dnh:setAction(action, duration)
    self.action = action
    self.actionCount = 0
    self.actionCountMax = duration or 0
end

---获取当前状态
---@return string, number, number
function dnh:getAction()
    return self.action, self.actionCount, self.actionCountMax
end

---获取状态绑定的函数
---@param action string @目标状态
---@return function
function dnh:getActionFunc(action)
    return self.actionFunc[action]
end

---强行终止当前状态
function dnh:actionStop()
    self:setAction("normal")
end

---使用当前自身属性执行状态函数
---@return number, number, number, number
function dnh:getID()
    local action = self:getActionFunc(self:getAction())
    if action then
        return action(self, self.obj, self.actionCount, self.actionCountMax)
    else
        return 1
    end
end

---设置混合模式
---@param blend string @目标混合模式
function dnh:setBlend(blend)
    self.blend = blend or ""
end

---设置颜色
---@param a number @不透明度
---@param r number @红色
---@param g number @绿色
---@param b number @绿色
---@overload fun(argb:number)
---@overload fun(lstg.Color:userdata)
function dnh:setColor(a, r, g, b)
    if a and r and g and b then
        self.color = Color(a, r, g, b)
    elseif type(a) == "userdata" then
        self.color = a
    elseif a then
        self.color = Color(a)
    end
end

---设置偏移
---@param dx number @偏移x
---@param dy number @偏移y
---@overload fun(func:function) @偏移函数
function dnh:setFloating(dx, dy)
    if type(dx) == "function" then
        self.floating_func = dx
        self.floating = nil
    else
        self.floating_func = nil
        self.floating = self.floating or {}
        self.floating.dx = dx or self.floating.dx or 0
        self.floating.dy = dy or self.floating.dy or 0
    end
end
