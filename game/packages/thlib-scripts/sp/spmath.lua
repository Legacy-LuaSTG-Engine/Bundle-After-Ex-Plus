if not (sp) then
    sp = {}
    sp.logfile = "userdata/sp_log.txt"
    do
        lstg.FileManager.CreateDirectory("userdata")
        local f = io.open(sp.logfile, 'w')
        f:close()
    end
    function sp.logWrite(str)
        local f = io.open(sp.logfile, 'a+')
        f:write(str .. "\n")
        f:close()
    end
end

--输出log至sp_log文件
local function _log(...)
    local list = { ... }
    for i, v in ipairs(list) do
        list[i] = tostring(v)
    end
    local str = table.concat(list, "\t")
    Print(str)
    sp.logWrite(str)
end

---@class sp.math
local lib = {}
sp.math = lib

_log(string.format("[spmath] installing"))

--角速度与半径相互转换
local function UniformSpiralTransform(speed, var)
    return (speed * 180) / (math.pi * var)
end
lib.UniformSpiralTransform = UniformSpiralTransform

--角度计算
local function _A(x1, y1, x2, y2)
    return math.deg(math.atan2(y2 - y1, x2 - x1))
end
local function Angle(a, b, c, d)
    if a and b and c and d then
        return _A(a, b, c, d)
    elseif a and b and c then
        if type(a) == "table" then
            return _A(a.x, a.y, b, c)
        elseif type(c) == "table" then
            return _A(a, b, c.x, c.y)
        else
            error("Error parameters")
        end
    elseif a and b then
        return _A(a.x, a.y, b.x, b.y)
    else
        error("Error parameters")
    end
end
lib.Angle = Angle

--距离计算
local function _D(x1, y1, x2, y2)
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end
local function Dist(a, b, c, d)
    if a and b and c and d then
        return _D(a, b, c, d)
    elseif a and b and c then
        if type(a) == "table" then
            return _D(a.x, a.y, b, c)
        elseif type(c) == "table" then
            return _D(a, b, c.x, c.y)
        else
            error("Error parameters")
        end
    elseif a and b then
        return _D(a.x, a.y, b.x, b.y)
    else
        error("Error parameters")
    end
end
lib.Dist = Dist

--合计数值
---@param a table @待计算数组
---@return number
local function sum(a)
    local b = 0
    for i = 1, #a do
        b = b + a[i]
    end
    return b
end
lib.sum = sum

--获取角度差，范围：(-180, 180]
---@param a1 number
---@param a2 number
---@return number
local function subAngle(a1, a2)
    local a = (a2 - a1) % 360
    if a > 180 then
        a = a - 360
    end
    return a
end
lib.subAngle = subAngle

--计算圆形
---@param r number @半径
---@param a number @角度
---@param x number @中心x
---@param y number @中心y
local function circle(r, a, x, y)
    x, y = x or 0, y or 0
    return x + r * cos(a), y + r * sin(a)
end
lib.circle = circle

--计算椭圆形
---@param ra number @半径a
---@param rb number @半径b
---@param a1 number @角度
---@param a2 number @倾角
---@param x number @中心x
---@param y number @中心y
local function circle2(ra, rb, a1, a2, x, y)
    x, y = x or 0, y or 0
    local x0 = x + ra * cos(a1) * cos(a2) - rb * sin(a1) * sin(a2)
    local y0 = y + ra * cos(a1) * sin(a2) + rb * sin(a1) * cos(a2)
    return x0, y0
end
lib.circle2 = circle2

--圆环坐标迭代器
---@param x number @中心x坐标
---@param y number @中心y坐标
---@param r number @半径
---@param a number @弧长
---@param n number @分段数
---@param rot number @起始角度
---@param m boolean @头尾相差完整弧长
local function GetCircle(x, y, r, a, n, rot, m)
    x, y, r = x or 0, y or 0, r or 0
    a, n, rot = a or 360, n or 1, rot or 0
    m = m or false
    local i = 0
    local c = a / n
    if m then
        c = a / (n - sign(n))
    end
    return function()
        if i < n then
            local ang = rot + c * i
            local x, y = circle(r, a, x, y)
            i = i + 1
            return x, y
        end
    end
end
lib.GetCircle = GetCircle

--斜椭圆圆环坐标迭代器
---@param x number @中心x坐标
---@param y number @中心y坐标
---@param ra number @半径a
---@param rb number @半径b
---@param a number @弧长
---@param n number @分段数
---@param angle number @椭圆倾斜角
---@param rot number @起始角度
---@param m boolean @头尾相差完整弧长
local function GetCircle2(x, y, ra, rb, a, n, angle, rot, m)
    x, y, ra, rb = x or 0, y or 0, ra or 0, rb or ra
    a, n, angle, rot = a or 360, n or 1, angle or 0, rot or 0
    m = m or false
    local i = 0
    local c = a / n
    if m then
        c = a / (n - sign(n))
    end
    return function()
        if i < n then
            local ang_a = rot + c * i
            local ang_b = angle
            local x, y = circle2(ra, rb, ang_a, ang_b, x, y)
            i = i + 1
            return x, y
        end
    end
end
lib.GetCircle2 = GetCircle2

--向量相乘
---@param a table @向量A
---@param b table @向量B
---@return number
local function vecmul(a, b)
    local x = 0
    local num = math.min(#a, #b)
    for i = 1, num do
        x = x + a[i] * b[i]
    end
    return x
end
lib.vecmul = vecmul

--矩阵转阵
---@param a table @待处理矩阵
---@return table
local function shuffle(a)
    local b = {}
    for i = 1, #a[1] do
        b[i] = {}
        for j = 1, #a do
            b[i][j] = a[j][i]
        end
    end
    return b
end
lib.shuffle = shuffle

--矩阵相乘
---@param a table @矩阵A
---@param b table @矩阵B
---@param toCol1 boolean @是否转阵矩阵A
---@param toCol2 boolean @是否转阵矩阵B
---@return table
local function matmul(a, b, toCol1, toCol2)
    if toCol1 then
        a = shuffle(a)
    end
    if toCol2 then
        b = shuffle(b)
    end
    local c = {}
    for i = 1, #a do
        c[i] = {}
        for j = 1, #b do
            c[i][j] = vecmul(a[i], b[j])
        end
    end
    return c
end
lib.matmul = matmul

--3D初始矩阵（四元）
---@param x number @X坐标
---@param y number @Y坐标
---@param z number @Z坐标
---@param w number @是否为向量(0为点，1为向量)
---@return table
local function _MAT_3D_P(x, y, z, w)
    return { { x, y, z, w } }
end
lib._MAT_3D_P = _MAT_3D_P

--3D平移矩阵（四元）
---@param x number @X偏移
---@param y number @Y偏移
---@param z number @Z偏移
---@return table
local function _MAT_3D_T(x, y, z)
    return {
        { 1, 0, 0, x },
        { 0, 1, 0, y },
        { 0, 0, 1, z },
        { 0, 0, 0, 1 },
    }
end
lib._MAT_3D_T = _MAT_3D_T

--3D旋转矩阵（X轴）（四元）
---@param a number @旋转角度
---@return table
local function _MAT_3D_RX(a)
    return {
        { 1, 0, 0, 0 },
        { 0, cos(a), -sin(a), 0 },
        { 0, sin(a), cos(a), 0 },
        { 0, 0, 0, 1 },
    }
end
lib._MAT_3D_RX = _MAT_3D_RX

--3D旋转矩阵（Y轴）（四元）
---@param a number @旋转角度
---@return table
local function _MAT_3D_RY(a)
    return {
        { cos(a), 0, sin(a), 0 },
        { 0, 1, 0, 0 },
        { -sin(a), 0, cos(a), 0 },
        { 0, 0, 0, 1 },
    }
end
lib._MAT_3D_RY = _MAT_3D_RY

--3D旋转矩阵（Z轴）（四元）
---@param a number @旋转角度
---@return table
local function _MAT_3D_RZ(a)
    return {
        { cos(a), -sin(a), 0, 0 },
        { sin(a), cos(a), 0, 0 },
        { 0, 0, 1, 0 },
        { 0, 0, 0, 1 },
    }
end
lib._MAT_3D_RZ = _MAT_3D_RZ

--3D缩放矩阵（四元）
---@param x number @X缩放比
---@param y number @Y缩放比
---@param z number @Z缩放比
---@return table
local function _MAT_3D_S(x, y, z)
    return {
        { x, 0, 0, 0 },
        { 0, y, 0, 0 },
        { 0, 0, z, 0 },
        { 0, 0, 0, 1 },
    }
end
lib._MAT_3D_S = _MAT_3D_S

--3D变化计算（四元）
---@param x number @X坐标
---@param y number @Y坐标
---@param z number @Z坐标
---@param w number @是否为向量(0为点，1为向量)
---@param tx number @X偏移
---@param ty number @Y偏移
---@param tz number @Z偏移
---@param rx number @X轴旋转角度
---@param ry number @Y轴旋转角度
---@param rz number @Z轴旋转角度
---@param sx number @X缩放比
---@param sy number @Y缩放比
---@param sz number @Z缩放比
---@return table @结果点
local function point3DT(x, y, z, w, tx, ty, tz, rx, ry, rz, sx, sy, sz)
    tx, ty, tz = tx or 0, ty or 0, tz or 0
    rx, ry, rz = rx or 0, ry or 0, rz or 0
    sx, sy, sz = sx or 1, sy or 1, sz or 1
    local p = _MAT_3D_P(x, y, z, w)
    local mat = _MAT_3D_T(tx, ty, tz)
    mat = matmul(mat, _MAT_3D_RY(ry))
    mat = matmul(mat, _MAT_3D_RX(rx))
    mat = matmul(mat, _MAT_3D_RZ(rz))
    mat = matmul(mat, _MAT_3D_S(sx, sy, sz))
    p = matmul(p, mat)
    return unpack(p)
end
lib.point3DT = point3DT

--3D变化计算（三元）
---@param x number @X坐标
---@param y number @Y坐标
---@param z number @Z坐标
---@param a number @Z轴旋转角度(1)
---@param b number @X轴旋转角度
---@param c number @Z轴旋转角度(2)
---@param dx number @X偏移
---@param dy number @Y偏移
---@param dz number @Z偏移
---@return table
local function Axis3D(x, y, z, a, b, c, dx, dy, dz)
    local p = { { x }, { y }, { z } }
    local C1 = {
        { cos(a), sin(a), 0 },
        { -sin(a), cos(a), 0 },
        { 0, 0, 1 }
    }
    local C2 = {
        { 1, 0, 0 },
        { 0, cos(b), sin(b) },
        { 0, -sin(b), cos(b) }
    }
    local C3 = {
        { cos(c), sin(c), 0 },
        { -sin(c), cos(c), 0 },
        { 0, 0, 1 }
    }
    local temp = matmul(C2, C3, false, true)
    local r = matmul(C1, temp, false, true)
    p = matmul(r, p, false, true)
    local q = {}
    q[1] = sum(p[1]) + dx
    q[2] = sum(p[2]) + dy
    q[3] = sum(p[3]) + dz
    return q
end
lib.Axis3D = Axis3D

--伪透视计算
---@param x number @X坐标
---@param y number @Y坐标
---@param z number @Z坐标
---@param dist number @距离
---@return number, number
local function Per3D(x, y, z, dist)
    local a0 = math.atan2(192, dist)
    local ax = math.atan2(x, dist + z)
    local ay = math.atan2(y, dist + z)
    x = 192 * ax / a0
    y = 192 * ay / a0
    return x, y
end
lib.Per3D = Per3D

_log(string.format("[spmath] complete"))