---@class taskex : task
local task = require("lib.Ltask")

-- 常量

MOVE_NORMAL = 0
MOVE_ACCEL = 1
MOVE_DECEL = 2
MOVE_ACC_DEC = 3

MOVE_TOWARDS_PLAYER = 0
MOVE_X_TOWARDS_PLAYER = 1
MOVE_Y_TOWARDS_PLAYER = 2
MOVE_RANDOM = 3

-- 直线移动

function task.MoveTo(x, y, t, mode)
    local self = task.GetSelf()
    t = int(t)
    t = max(1, t)
    local dx = x - self.x
    local dy = y - self.y
    local xs = self.x
    local ys = self.y
    if mode == 1 then
        for s = 1 / t, 1 + 0.5 / t, 1 / t do
            s = s * s
            self.x = xs + s * dx
            self.y = ys + s * dy
            coroutine.yield()
        end
    elseif mode == 2 then
        for s = 1 / t, 1 + 0.5 / t, 1 / t do
            s = s * 2 - s * s
            self.x = xs + s * dx
            self.y = ys + s * dy
            coroutine.yield()
        end
    elseif mode == 3 then
        for s = 1 / t, 1 + 0.5 / t, 1 / t do
            if s < 0.5 then
                s = s * s * 2
            else
                s = -2 * s * s + 4 * s - 1
            end
            self.x = xs + s * dx
            self.y = ys + s * dy
            coroutine.yield()
        end
    else
        for s = 1 / t, 1 + 0.5 / t, 1 / t do
            self.x = xs + s * dx
            self.y = ys + s * dy
            coroutine.yield()
        end
    end
end

function task.MoveToEx(x, y, t, mode)
    local self = task.GetSelf()
    t = int(t)
    t = max(1, t)
    local dx = x
    local dy = y
    local xs = 0
    local ys = 0
    local slast = 0
    if mode == 1 then
        for s = 1 / t, 1 + 0.5 / t, 1 / t do
            s = s * s
            self.x = self.x + (s - slast) * dx
            self.y = self.y + (s - slast) * dy
            coroutine.yield()
            slast = s
        end
    elseif mode == 2 then
        for s = 1 / t, 1 + 0.5 / t, 1 / t do
            s = s * 2 - s * s
            self.x = self.x + (s - slast) * dx
            self.y = self.y + (s - slast) * dy
            coroutine.yield()
            slast = s
        end
    elseif mode == 3 then
        for s = 1 / t, 1 + 0.5 / t, 1 / t do
            if s < 0.5 then
                s = s * s * 2
            else
                s = -2 * s * s + 4 * s - 1
            end
            self.x = self.x + (s - slast) * dx
            self.y = self.y + (s - slast) * dy
            coroutine.yield()
            slast = s
        end
    else
        for s = 1 / t, 1 + 0.5 / t, 1 / t do
            self.x = self.x + (s - slast) * dx
            self.y = self.y + (s - slast) * dy
            coroutine.yield()
            slast = s
        end
    end
end

function task.MoveToPlayer(t, x1, x2, y1, y2, dxmin, dxmax, dymin, dymax, mmode, dmode)
    local dirx, diry = ran:Sign(), ran:Sign()
    local self = task.GetSelf()
    local p = player
    if dmode < 2 then
        if self.x > p.x then
            dirx = -1
        else
            dirx = 1
        end
    end
    if dmode == 0 or dmode == 2 then
        if self.y > p.y then
            diry = -1
        else
            diry = 1
        end
    end
    local dx = ran:Float(dxmin, dxmax)
    local dy = ran:Float(dymin, dymax)
    if self.x + dx * dirx < x1 then
        dirx = 1
    end
    if self.x + dx * dirx > x2 then
        dirx = -1
    end
    if self.y + dy * diry < y1 then
        diry = 1
    end
    if self.y + dy * diry > y2 then
        diry = -1
    end
    task.MoveTo(self.x + dx * dirx, self.y + dy * diry, t, mmode)
end

-- 青山写的贝塞尔曲线

function task.BezierMoveTo(t, mode, ...)
    local arg = { ... }
    local self = task.GetSelf()
    t = int(t)
    t = max(1, t)
    local count = (#arg) / 2
    local x = {}
    local y = {}
    x[1] = self.x
    y[1] = self.y
    for i = 1, count do
        x[i + 1] = arg[i * 2 - 1]
        y[i + 1] = arg[i * 2]
    end
    local com_num = {}
    for i = 0, count do
        com_num[i + 1] = combinNum(i, count)
    end
    if mode == 1 then
        for s = 1 / t, 1 + 0.5 / t, 1 / t do
            s = s * s
            local _x, _y = 0, 0
            for j = 0, count do
                _x = _x + x[j + 1] * com_num[j + 1] * (1 - s) ^ (count - j) * s ^ (j)
                _y = _y + y[j + 1] * com_num[j + 1] * (1 - s) ^ (count - j) * s ^ (j)
            end
            self.x = _x
            self.y = _y
            coroutine.yield()
        end
    elseif mode == 2 then
        for s = 1 / t, 1 + 0.5 / t, 1 / t do
            s = s * 2 - s * s
            local _x, _y = 0, 0
            for j = 0, count do
                _x = _x + x[j + 1] * com_num[j + 1] * (1 - s) ^ (count - j) * s ^ (j)
                _y = _y + y[j + 1] * com_num[j + 1] * (1 - s) ^ (count - j) * s ^ (j)
            end
            self.x = _x
            self.y = _y
            coroutine.yield()
        end
    elseif mode == 3 then
        for s = 1 / t, 1 + 0.5 / t, 1 / t do
            if s < 0.5 then
                s = s * s * 2
            else
                s = -2 * s * s + 4 * s - 1
            end
            local _x, _y = 0, 0
            for j = 0, count do
                _x = _x + x[j + 1] * com_num[j + 1] * (1 - s) ^ (count - j) * s ^ (j)
                _y = _y + y[j + 1] * com_num[j + 1] * (1 - s) ^ (count - j) * s ^ (j)
            end
            self.x = _x
            self.y = _y
            coroutine.yield()
        end
    else
        for s = 1 / t, 1 + 0.5 / t, 1 / t do
            local _x, _y = 0, 0
            for j = 0, count do
                _x = _x + x[j + 1] * com_num[j + 1] * (1 - s) ^ (count - j) * s ^ (j)
                _y = _y + y[j + 1] * com_num[j + 1] * (1 - s) ^ (count - j) * s ^ (j)
            end
            self.x = _x
            self.y = _y
            coroutine.yield()
        end
    end
end

function task.BezierMoveToEx(t, mode, ...)
    local arg = { ... }
    local self = task.GetSelf()
    t = int(t)
    t = max(1, t)
    local count = (#arg) / 2
    local x = {}
    local y = {}
    local last_x = 0;
    local last_y = 0;
    x[1] = 0
    y[1] = 0
    for i = 1, count do
        x[i + 1] = arg[i * 2 - 1]
        y[i + 1] = arg[i * 2]
    end
    local com_num = {}
    for i = 0, count do
        com_num[i + 1] = combinNum(i, count)
    end
    if mode == 1 then
        for s = 1 / t, 1 + 0.5 / t, 1 / t do
            s = s * s
            local _x, _y = 0, 0
            for j = 0, count do
                _x = _x + x[j + 1] * com_num[j + 1] * (1 - s) ^ (count - j) * s ^ (j)
                _y = _y + y[j + 1] * com_num[j + 1] * (1 - s) ^ (count - j) * s ^ (j)
            end
            self.x = self.x + _x - last_x
            self.y = self.y + _y - last_y
            last_x = _x
            last_y = _y
            coroutine.yield()
        end
    elseif mode == 2 then
        for s = 1 / t, 1 + 0.5 / t, 1 / t do
            s = s * 2 - s * s
            local _x, _y = 0, 0
            for j = 0, count do
                _x = _x + x[j + 1] * com_num[j + 1] * (1 - s) ^ (count - j) * s ^ (j)
                _y = _y + y[j + 1] * com_num[j + 1] * (1 - s) ^ (count - j) * s ^ (j)
            end
            self.x = self.x + _x - last_x
            self.y = self.y + _y - last_y
            last_x = _x
            last_y = _y
            coroutine.yield()
        end
    elseif mode == 3 then
        for s = 1 / t, 1 + 0.5 / t, 1 / t do
            if s < 0.5 then
                s = s * s * 2
            else
                s = -2 * s * s + 4 * s - 1
            end
            local _x, _y = 0, 0
            for j = 0, count do
                _x = _x + x[j + 1] * com_num[j + 1] * (1 - s) ^ (count - j) * s ^ (j)
                _y = _y + y[j + 1] * com_num[j + 1] * (1 - s) ^ (count - j) * s ^ (j)
            end
            self.x = self.x + _x - last_x
            self.y = self.y + _y - last_y
            last_x = _x
            last_y = _y
            coroutine.yield()
        end
    else
        for s = 1 / t, 1 + 0.5 / t, 1 / t do
            local _x, _y = 0, 0
            for j = 0, count do
                _x = _x + x[j + 1] * com_num[j + 1] * (1 - s) ^ (count - j) * s ^ (j)
                _y = _y + y[j + 1] * com_num[j + 1] * (1 - s) ^ (count - j) * s ^ (j)
            end
            self.x = self.x + _x - last_x
            self.y = self.y + _y - last_y
            last_x = _x
            last_y = _y
            coroutine.yield()
        end
    end
end

-- 青山写的埃尔金样条

function task.CRMoveTo(t, mode, ...)
    local self = task.GetSelf()
    local arg = { ... }
    local count = (#arg) / 2
    local x = {}
    local y = {}
    x[1] = self.x
    y[1] = self.y
    for i = 1, count do
        x[i + 1] = arg[i * 2 - 1]
        y[i + 1] = arg[i * 2]
    end

    table.insert(x, 2 * x[#x] - x[#x - 1])
    table.insert(x, 1, 2 * x[1] - x[2])

    table.insert(y, 2 * y[#y] - y[#y - 1])
    table.insert(y, 1, 2 * y[1] - y[2])

    t = int(t)
    t = max(1, t)

    local timeMark = {}
    if mode == 1 then
        for i = 1, t do
            timeMark[i] = count * (i / t) * (i / t)
        end
    elseif mode == 2 then
        for i = 1, t do
            timeMark[i] = count * ((i / t) * 2 - (i / t) * (i / t))
        end
    elseif mode == 3 then
        for i = 1, t do
            if i / t < 0.5 then
                timeMark[i] = count * (i / t) * (i / t) * 2
            else
                timeMark[i] = count * (-2 * (i / t) * (i / t) + 4 * (i / t) - 1)
            end
        end
    else
        for i = 1, t do
            timeMark[i] = count * (i / t)
        end
    end

    for i = 1, t - 1 do
        local s = math.floor(timeMark[i]) + 1
        local j = timeMark[i] % 1
        local _x = x[s] * (-0.5 * j * j * j + j * j - 0.5 * j)
                + x[s + 1] * (1.5 * j * j * j - 2.5 * j * j + 1.0)
                + x[s + 2] * (-1.5 * j * j * j + 2.0 * j * j + 0.5 * j)
                + x[s + 3] * (0.5 * j * j * j - 0.5 * j * j)
        local _y = y[s] * (-0.5 * j * j * j + j * j - 0.5 * j)
                + y[s + 1] * (1.5 * j * j * j - 2.5 * j * j + 1.0)
                + y[s + 2] * (-1.5 * j * j * j + 2.0 * j * j + 0.5 * j)
                + y[s + 3] * (0.5 * j * j * j - 0.5 * j * j)
        self.x = _x
        self.y = _y
        coroutine.yield()
    end
    self.x = x[count + 2]
    self.y = y[count + 2]
    coroutine.yield()
end

function task.CRMoveToEx(t, mode, ...)
    local self = task.GetSelf()
    local arg = { ... }
    local count = (#arg) / 2
    local x = {}
    local y = {}
    local last_x = 0;
    local last_y = 0;
    x[1] = 0
    y[1] = 0
    for i = 1, count do
        x[i + 1] = arg[i * 2 - 1]
        y[i + 1] = arg[i * 2]
    end

    table.insert(x, 2 * x[#x] - x[#x - 1])
    table.insert(x, 1, 2 * x[1] - x[2])

    table.insert(y, 2 * y[#y] - y[#y - 1])
    table.insert(y, 1, 2 * y[1] - y[2])

    t = int(t)
    t = max(1, t)

    local timeMark = {}
    if mode == 1 then
        for i = 1, t do
            timeMark[i] = count * (i / t) * (i / t)
        end
    elseif mode == 2 then
        for i = 1, t do
            timeMark[i] = count * ((i / t) * 2 - (i / t) * (i / t))
        end
    elseif mode == 3 then
        for i = 1, t do
            if i / t < 0.5 then
                timeMark[i] = count * (i / t) * (i / t) * 2
            else
                timeMark[i] = count * (-2 * (i / t) * (i / t) + 4 * (i / t) - 1)
            end
        end
    else
        for i = 1, t do
            timeMark[i] = count * (i / t)
        end
    end

    for i = 1, t - 1 do
        local s = math.floor(timeMark[i]) + 1
        local j = timeMark[i] % 1
        local _x = x[s] * (-0.5 * j * j * j + j * j - 0.5 * j)
                + x[s + 1] * (1.5 * j * j * j - 2.5 * j * j + 1.0)
                + x[s + 2] * (-1.5 * j * j * j + 2.0 * j * j + 0.5 * j)
                + x[s + 3] * (0.5 * j * j * j - 0.5 * j * j)
        local _y = y[s] * (-0.5 * j * j * j + j * j - 0.5 * j)
                + y[s + 1] * (1.5 * j * j * j - 2.5 * j * j + 1.0)
                + y[s + 2] * (-1.5 * j * j * j + 2.0 * j * j + 0.5 * j)
                + y[s + 3] * (0.5 * j * j * j - 0.5 * j * j)
        self.x = self.x + _x - last_x
        self.y = self.y + _y - last_y
        last_x = _x
        last_y = _y
        coroutine.yield()
    end
    self.x = self.x + x[count + 2] - last_x
    self.y = self.y + y[count + 2] - last_y
    coroutine.yield()
end

-- Xiliusha写的二次B样条,过采样点间的中点，为二次曲线

function task.Basis2MoveTo(t, mode, ...)
    --获得基本参数
    local self = task.GetSelf()
    local arg = { ... }
    t = math.max(1, math.floor(t))
    --构造采样点列表
    local count = (#arg) / 2
    local x = {}
    local y = {}
    x[1] = self.x
    y[1] = self.y
    for i = 1, count do
        x[i + 1] = arg[i * 2 - 1]
        y[i + 1] = arg[i * 2]
    end
    --检查采样点数量，如果不足3个，则插值到3个
    if count < 2 then
        --只有两个采样点时，取中点插值
        x[3] = x[2];
        y[3] = y[2]
        x[2] = x[1] + 0.5 * (x[3] - x[1])
        y[2] = y[1] + 0.5 * (y[3] - y[1])
    elseif count < 1 then
        --只有一个采样点时，只能这样了
        for i = 2, 3 do
            x[i] = x[1];
            y[i] = y[1]
        end
    end
    count = math.max(2, count)
    --储存末点，给末尾使用
    local fx, fy = x[#x], y[#y]
    --对首末采样点特化处理
    do
        --首点处理
        x[1] = x[2] + 2 * (x[1] - x[2])
        y[1] = y[2] + 2 * (y[1] - y[2])
        --末点处理
        x[count + 1] = x[count] + 2 * (x[count + 1] - x[count])
        y[count + 1] = y[count] + 2 * (y[count + 1] - y[count])
        --插入尾数据解决越界报错
        x[count + 2] = x[count + 1]
        y[count + 2] = y[count + 1]
    end
    --准备采样方式函数
    local mfunc = {
        [0] = function(n)
            --线性
            return n
        end,
        [1] = function(n)
            --加速
            return n ^ 2
        end,
        [2] = function(n)
            --减速
            return (1 - (n - 1) ^ 2)
        end,
        [3] = function(n)
            --加减速
            if n < 0.5 then
                return 2 * (n ^ 2)
            else
                return (-2 * (n ^ 2) + 4 * n - 1)
            end
        end,
    }
    --开始运动
    for i = 1 / t, 1, 1 / t do
        local j = (count - 1) * mfunc[mode](i)--采样方式
        local se = math.floor(j) + 1        --3采样选择
        local ct = j - math.floor(j)        --切换
        local _x = 0
                + x[se] * (0.5 * (ct - 1) ^ 2) --基函数1
                + x[se + 1] * (0.5 * (-2 * ct ^ 2 + 2 * ct + 1)) --基函数2
                + x[se + 2] * (0.5 * ct ^ 2)              --基函数3
        local _y = 0
                + y[se] * (0.5 * (ct - 1) ^ 2) --基函数1
                + y[se + 1] * (0.5 * (-2 * ct ^ 2 + 2 * ct + 1)) --基函数2
                + y[se + 2] * (0.5 * ct ^ 2)              --基函数3
        self.x, self.y = _x, _y
        coroutine.yield()
    end
    --末尾处理，解决曲线采样带来的误差
    self.x, self.y = fx, fy
    --待改善：采样方式。希望以后采样能更加精确
end

function task.Basis2MoveToEX(t, mode, ...)
    --获得基本参数
    local self = task.GetSelf()
    local arg = { ... }
    t = math.max(1, math.floor(t))
    local last_x, last_y = 0, 0
    --构造采样点列表
    local count = (#arg) / 2
    local x = {}
    local y = {}
    x[1] = 0
    y[1] = 0
    for i = 1, count do
        x[i + 1] = arg[i * 2 - 1]
        y[i + 1] = arg[i * 2]
    end
    --检查采样点数量，如果不足3个，则插值到3个
    if count < 2 then
        --只有两个采样点时，取中点插值
        x[3] = x[2];
        y[3] = y[2]
        x[2] = x[1] + 0.5 * (x[3] - x[1])
        y[2] = y[1] + 0.5 * (y[3] - y[1])
    elseif count < 1 then
        --只有一个采样点时，只能这样了
        for i = 2, 3 do
            x[i] = x[1];
            y[i] = y[1]
        end
    end
    count = math.max(2, count)
    --储存末点，给末尾使用
    local fx, fy = x[#x], y[#y]
    --对首末采样点特化处理
    do
        --首点处理
        x[1] = x[2] + 2 * (x[1] - x[2])
        y[1] = y[2] + 2 * (y[1] - y[2])
        --末点处理
        x[count + 1] = x[count] + 2 * (x[count + 1] - x[count])
        y[count + 1] = y[count] + 2 * (y[count + 1] - y[count])
        --插入尾数据解决越界报错
        x[count + 2] = x[count + 1]
        y[count + 2] = y[count + 1]
    end
    --准备采样方式函数
    local mfunc = {
        [0] = function(n)
            --线性
            return n
        end,
        [1] = function(n)
            --加速
            return n ^ 2
        end,
        [2] = function(n)
            --减速
            return (1 - (n - 1) ^ 2)
        end,
        [3] = function(n)
            --加减速
            if n < 0.5 then
                return 2 * (n ^ 2)
            else
                return (-2 * (n ^ 2) + 4 * n - 1)
            end
        end,
    }
    --开始运动
    for i = 1 / t, 1, 1 / t do
        local j = (count - 1) * mfunc[mode](i)--采样方式
        local se = math.floor(j) + 1        --3采样选择
        local ct = j - math.floor(j)        --切换
        local _x = 0
                + x[se] * (0.5 * (ct - 1) ^ 2) --基函数1
                + x[se + 1] * (0.5 * (-2 * ct ^ 2 + 2 * ct + 1)) --基函数2
                + x[se + 2] * (0.5 * ct ^ 2)              --基函数3
        local _y = 0
                + y[se] * (0.5 * (ct - 1) ^ 2) --基函数1
                + y[se + 1] * (0.5 * (-2 * ct ^ 2 + 2 * ct + 1)) --基函数2
                + y[se + 2] * (0.5 * ct ^ 2)              --基函数3
        self.x = self.x + _x - last_x
        self.y = self.y + _y - last_y
        last_x = _x
        last_y = _y
        coroutine.yield()
    end
    --末尾处理，解决曲线采样带来的误差
    self.x = self.x + fx - last_x
    self.y = self.y + fy - last_y
    --待改善：采样方式。希望以后采样能更加精确
end

return task
