---=====================================
---ex lib
---ex+的函数库
---=====================================

---@class ex @ex+的函数库
ex = {}

---重置ex库变量
function ex.Reset()
    ex.ResetSignals()
    ex.stageframe = 0
    ex.labels = {}--由OLC添加，重置ex全局变量时，顺带清除object标签
end

----------------------------------------
---lable

ex.labels = {}--由OLC添加，用于储存指向object的标签，编辑器功能

---把一个obj添加进全局表里面
---@param label string|number @标签
---@param obj object @luastg对象
function ex.SetLabelToObject(label, obj)
    ex.labels[label] = obj
end

---通过标签索引，从全局表取出一个object
---@param label string|number @标签
---@return object|nil @luastg对象
function ex.GetObjectFromLabel(label)
    if IsValid(ex.labels[label]) then
        return ex.labels[label]
    end
end

----------------------------------------
---signals

ex.signals = {}

---重置所有标记
function ex.ResetSignals()
    ex.signals = {}
end

---设置一个标记
---@param slot string|number @标签
---@param value any @设置的值
function ex.SetSignal(slot, value)
    ex.signals[slot] = value
end

---等待标签所指的值达到传入的value
---！警告：该方法依赖task环境
---@param slot string|number @标签
---@param value any @检测的值
function ex.WaitForSignal(slot, value)
    while ex.signals[slot] ~= value do
        task.Wait(1)
    end
end

----------------------------------------
---unit list

---对一个对象表进行更新，去除无效的luastg object对象
---@param lst table
---@return number @表长度
function ex.UnitListUpdate(lst)
    local n = #lst
    local j = 0
    for i = 1, n do
        local z = lst[i]
        if IsValid(z) then
            j = j + 1
            lst[j] = z;
            if i ~= j then
                lst[i] = nil;
            end
        else
            lst[i] = nil;
        end
    end
    return j
end

---添加一个luastg object对象或者luastg object对象表到已有的对象表上
---@param lst table
---@param obj object|table
---@return number @表长度
function ex.UnitListAppend(lst, obj)
    if IsValid(obj) then
        local n = #lst
        lst[n + 1] = obj
        return n + 1
    elseif IsValid(obj[1]) then
        return ex.UnitListAppendList(lst, obj)
    else
        return #lst
    end
end

---连接两个对象表
---@param lst table
---@param objlist table
---@return number @两个对象表的对象总和
function ex.UnitListAppendList(lst, objlist)
    local n = #lst
    local n2 = #objlist
    for i = 1, n2 do
        lst[n + i] = objlist[i]
    end
    --return n+i--ESC你这个i哪里来的……
    return n + n2
end

---返回指定对象在对象表中的位置
---@param lst table
---@param obj any
---@return number
function ex.UnitListFindUnit(lst, obj)
    for i = 1, #lst do
        if lst[i] == obj then
            return i
        end
    end
    return 0
end

-- TODO:这个函数实现有问题，里面含有不存在的方法
function ex.UnitListInsertEx(lst, obj)
    local l = ex.UnitListFindUnit(lst, obj)
    if l == 0 then
        return ex.UnitListInsert(lst, obj)
    else
        return l
    end
end

----------------------------------------
---lazer

---对曲线激光按照长度采样，返回一个对象组
---@param laser object
---@param l number
function ex.LaserSampleByLength(laser, l)
    return laser.data:SampleByLength(l)
end

---对曲线激光按照时间间隔采样（单位：秒），返回一个对象组
---@param laser object
---@param l number
function ex.LaserSampleByTime(laser, l)
    return laser.data:LaserSampleByTime(l)
end

---使用一个对象组刷新曲线激光的路径，并设置速度和方向,可以接受一个额外的参数revert，用来确定方向,默认情况list中第一个对象是激光头
---@param list table @对象组
---@param rev boolean @是否将自身朝向设置成速度方向
function ex:LaserFormByList(list, rev)
    local l = #list
    if l < 2 then
        Del(self)
    end
    self.data = BentLaserData()
    --防止因_data删除导致老mod内重写的曲光使用该函数出错
    if self._data then
        self._data = BentLaserData()
    end
    local _l = self._l
    if rev == nil then
        for i = l, 2, -1 do
            self.x = list[i].x
            self.y = list[i].y
            self.timer = self.timer + 1
            if self.timer % 4 == 0 then
                self.listx[(self.timer / 4) % _l] = self.x
                self.listy[(self.timer / 4) % _l] = self.y
            end
            self.data:Update(self, self.l, self.w)
            if self._data then
                self._data:Update(self, self.l, self.w + 48)
            end
        end
        self.x = list[1].x
        self.y = list[1].y
        self.vx = self.x - list[2].x
        self.vy = self.y - list[2].y
        self.rot = self._angle
    else
        for i = 1, l - 1, 1 do
            self.x = list[i].x
            self.y = list[i].y
            self.timer = self.timer + 1
            if self.timer % 4 == 0 then
                self.listx[(self.timer / 4) % _l] = self.x
                self.listy[(self.timer / 4) % _l] = self.y
            end
            self.data:Update(self, self.l, self.w)
            if self._data then
                self._data:Update(self, self.l, self.w + 48)
            end
        end
        self.x = list[l].x
        self.y = list[l].y
        self.vx = self.x - list[l - 1].x
        self.vy = self.y - list[l - 1].y
    end
end

---使用一个对象组刷新曲线激光的路径
---@param list table @对象组
function ex:LaserUpdateByList(list)
    local l = #list
    if l < 2 then
        return
    end
    self.data:UpdatePositionByList(list, l, self._w)
    --兼容性接口
    if self._data then
        self._data:UpdatePositionByList(list, l, self._w + 48)
    end
end

----------------------------------------
---value set

MODE_SET = 0
MODE_ADD = 1
MODE_MUL = 2

---平滑设置一个对象的变量
---@param valname string|number|function @索引或者一个变量设置函数
---@param y number @增量
---@param t number @持续时间
---@param mode number @参见移动模式
---@param setter function @变量设置函数
---@param starttime number @等待时间
---@param vmode number @MODE_SET, MODE_ADD, MODE_MUL，增量模式
function ex.SmoothSetValueTo(valname, y, t, mode, setter, starttime, vmode)
    local self = task.GetSelf()
    if starttime then
        task.Wait(starttime)
    end
    t = int(t)
    t = max(1, t)
    local ys = 0
    if setter then
        ys = valname()
    else
        ys = self[valname]
    end
    local dy = y - ys
    if vmode == nil then
        vmode = MODE_SET
    end
    if vmode == MODE_ADD then
        dy = y
    elseif vmode == MODE_MUL then
        dy = ys * y - ys
    end
    if setter then
        if mode == 1 then
            for s = 1 / t, 1 + 0.5 / t, 1 / t do
                s = s * s
                setter(ys + s * dy)
                coroutine.yield()
            end
        elseif mode == 2 then
            for s = 1 / t, 1 + 0.5 / t, 1 / t do
                s = s * 2 - s * s
                setter(ys + s * dy)
                coroutine.yield()
            end
        elseif mode == 3 then
            for s = 1 / t, 1 + 0.5 / t, 1 / t do
                if s < 0.5 then
                    s = s * s * 2
                else
                    s = -2 * s * s + 4 * s - 1
                end
                setter(ys + s * dy)
                coroutine.yield()
            end
        else
            for s = 1 / t, 1 + 0.5 / t, 1 / t do
                setter(ys + s * dy)
                coroutine.yield()
            end
        end
    else
        if mode == 1 then
            for s = 1 / t, 1 + 0.5 / t, 1 / t do
                s = s * s
                self[valname] = ys + s * dy
                coroutine.yield()
            end
        elseif mode == 2 then
            for s = 1 / t, 1 + 0.5 / t, 1 / t do
                s = s * 2 - s * s
                self[valname] = ys + s * dy
                coroutine.yield()
            end
        elseif mode == 3 then
            for s = 1 / t, 1 + 0.5 / t, 1 / t do
                if s < 0.5 then
                    s = s * s * 2
                else
                    s = -2 * s * s + 4 * s - 1
                end
                self[valname] = ys + s * dy
                coroutine.yield()
            end
        else
            for s = 1 / t, 1 + 0.5 / t, 1 / t do
                self[valname] = ys + s * dy
                coroutine.yield()
            end
        end
    end
end

---以增量模式平滑设置一个对象的变量
---@param valname string|number|function @索引或者一个变量设置函数
---@param y number @增量
---@param t number @持续时间
---@param mode number @参见移动模式
---@param setter function @变量设置函数
---@param starttime number @等待时间
---@param vmode number @MODE_SET, MODE_ADD, MODE_MUL，增量模式
function ex.SmoothSetValueToEx(valname, y, t, mode, setter, starttime, vmode)
    local self = task.GetSelf()
    if starttime then
        task.Wait(starttime)
    end
    t = int(t)
    t = max(1, t)

    local ys = 0
    if setter then
        ys = valname()
    else
        ys = self[valname]
    end
    local dy = y - ys
    if vmode == nil then
        vmode = MODE_SET
    end
    if vmode == MODE_ADD then
        dy = y
    elseif vmode == MODE_MUL then
        dy = ys * y - ys
    end
    local lasts = 0
    if setter then
        if mode == 1 then
            for s = 1 / t, 1 + 0.5 / t, 1 / t do
                s = s * s
                setter(valname() + (s - lasts) * dy)
                lasts = s
                coroutine.yield()
            end
        elseif mode == 2 then
            for s = 1 / t, 1 + 0.5 / t, 1 / t do
                s = s * 2 - s * s
                setter(valname() + (s - lasts) * dy)
                lasts = s
                coroutine.yield()
            end
        elseif mode == 3 then
            for s = 1 / t, 1 + 0.5 / t, 1 / t do
                if s < 0.5 then
                    s = s * s * 2
                else
                    s = -2 * s * s + 4 * s - 1
                end
                setter(valname() + (s - lasts) * dy)
                lasts = s
                coroutine.yield()
            end
        else
            for s = 1 / t, 1 + 0.5 / t, 1 / t do
                setter(valname() + (s - lasts) * dy)
                lasts = s
                coroutine.yield()
            end
        end
    else
        if mode == 1 then
            for s = 1 / t, 1 + 0.5 / t, 1 / t do
                s = s * s
                self[valname] = self[valname] + (s - lasts) * dy
                lasts = s
                coroutine.yield()
            end
        elseif mode == 2 then
            for s = 1 / t, 1 + 0.5 / t, 1 / t do
                s = s * 2 - s * s
                self[valname] = self[valname] + (s - lasts) * dy
                lasts = s
                coroutine.yield()
            end
        elseif mode == 3 then
            for s = 1 / t, 1 + 0.5 / t, 1 / t do
                if s < 0.5 then
                    s = s * s * 2
                else
                    s = -2 * s * s + 4 * s - 1
                end
                self[valname] = self[valname] + (s - lasts) * dy
                lasts = s
                coroutine.yield()
            end
        else
            for s = 1 / t, 1 + 0.5 / t, 1 / t do
                self[valname] = self[valname] + (s - lasts) * dy
                lasts = s
                coroutine.yield()
            end
        end
    end
end

----------------------------------------
---step

UNIT_SECOND = 0
UNIT_FRAME = 1
UNIT_MUSIC = 2

ex.stageframe = 0
ex.meterstart = 0
ex.meterclock = 1

---ex帧逻辑
function ex.Frame()
    ex.stageframe = ex.stageframe + 1
end

---返回第a小节开始时对应的游戏时间（秒）
---@param a number
---@return number
function ex.GetMusicMeter(a)
    return a * ex.meterclock + meterstart
end

---返回当前节拍设置下a小节对应的帧数（整数）
---@param a number
---@return number
function ex.GetMusicFrame(a)
    return int(a * ex.meterclock * 60 + 0.5)
end

---可以等待至具体的时间
---@param t number @时间
---@param u number @时间单位，UNIT_SECOND为秒，UNIT_FRAME为帧数，UNIT_MUSIC为节拍数
---@param d boolean @是否当执行到此处时时间已经超过设置的时间时，丢弃挂在自己右侧的代码(编辑器功能)
---@param a boolean @是否为增量模式，是的话可以替代普通task，否则按照stageframe计算
---@return boolean
function ex.WaitTo(t, u, d, a)
    if u == UNIT_SECOND then
        t = t * 60
    end
    if u == UNIT_MUSIC then
        t = (t * ex.meterclock + ex.meterstart) * 60
    end
    if a then
        t = int(t + 0.5)
    else
        t = int(t - ex.stageframe)
    end
    if t < 0 and d then
        return false
    end
    task.Wait(t)
    return true
end

----------------------------------------
--- jstg 最值得留下的遗产

jstg = jstg or {}

function jstg.CreatePlayers()
	New(_G[lstg.var.player_name], 1)
end

jstg.worldcount = 0 -- 实际上用不到
jstg.worlds = {} -- 实际上用不到，0.83以前的编辑器设置宽屏会生成赋值 这个的代码

function jstg.UpdateWorld()
    for i = 1, jstg.worldcount do
        for k, v in pairs(jstg.worlds[i]) do
            lstg.world[k] = v
        end
        lstg.SetBound(lstg.world.boundl, lstg.world.boundr, lstg.world.boundb, lstg.world.boundt)
        break -- 没有多 world 了
    end
end

---对传入的world表设置world参数
---@param world table @传入的table
---@param width number @world宽度
---@param height number @world高度
---@param boundout number @出屏消失扩展范围
---@param sl number @world左边缘在屏幕上的位置
---@param sr number @world右边缘在屏幕上的位置
---@param sb number @world底部在屏幕上的位置
---@param st number @world顶部在屏幕上的位置
function SetLuaSTGWorld(world,width,height,boundout,sl,sr,sb,st,m)
	world.l=-width/2
	world.pl=-width/2
	world.boundl=-width/2-boundout
	world.r=width/2
	world.pr=width/2
	world.boundr=width/2+boundout
	world.b=-height/2
	world.pb=-height/2
	world.boundb=-height/2-boundout
	world.t=height/2
	world.pt=height/2
	world.boundt=height/2+boundout
	world.scrl=sl
	world.scrr=sr
	world.scrb=sb
	world.scrt=st
    world.world=m
    for k, v in pairs(world) do
        lstg.world[k] = v
    end
    lstg.SetBound(lstg.world.boundl, lstg.world.boundr, lstg.world.boundb, lstg.world.boundt)
end

---对传入的world表设置world参数
---@param world table @传入的table
---@param width number @world宽度
---@param height number @world高度
---@param boundout number @出屏消失扩展范围
---@param sl number @world左边缘在屏幕上的位置
---@param sb number @world底部在屏幕上的位置
---@param m number @world的掩码，用于多world
function SetLuaSTGWorld2(world,width,height,boundout,sl,sb,m)
	SetLuaSTGWorld(world,width,height,boundout,sl,sl+width,sb,sb+height,m)
end
