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

---@class sp.misc
local lib = {}
sp.misc = lib

_log(string.format("[spmisc] installing"))

---渲染纯色圆
---@param x number @中心x坐标
---@param y number @中心y坐标
---@param R number @半径
---@param N number @边数
---@param blend string @blend mode
---@param a number @alpha
---@param r number @red
---@param g number @green
---@param b number @blue
---@param rot number @旋转角度
function lib.DrawCircle(x, y, R, N, blend, a, r, g, b, rot)
    blend, a, r, g, b, rot = blend or '', a or 255, r or 255, g or 255, b or 255, rot or 0
    SetImageState('white', blend, Color(a, r, g, b))
    for i = 1, N do
        local a1, a2 = (i - 1) * (360 / N) + rot, (i) * (360 / N) + rot
        Render4V('white', x + R * cos(a1), y + R * sin(a1), 0.5, x + R * cos(a2), y + R * sin(a2), 0.5, x, y, 0.5, x, y, 0.5)
    end
    SetImageState('white', '', Color(255, 255, 255, 255))
end

---渲染纯色中心渐变透明圆
---@param x number @中心x坐标
---@param y number @中心y坐标
---@param R number @半径
---@param N number @边数
---@param blend string @blend mode
---@param a number @alpha
---@param r number @red
---@param g number @green
---@param b number @blue
---@param rot number @旋转角度
function lib.DrawCircle2(x, y, R, N, blend, a, r, g, b, rot)
    blend, a, r, g, b, rot = blend or '', a or 255, r or 255, g or 255, b or 255, rot or 0
    SetImageState('white', blend, Color(a, r, g, b), Color(a, r, g, b), Color(0, r, g, b), Color(0, r, g, b))
    for i = 1, N do
        local a1, a2 = (i - 1) * (360 / N) + rot, (i) * (360 / N) + rot
        Render4V('white', x + R * cos(a1), y + R * sin(a1), 0.5, x + R * cos(a2), y + R * sin(a2), 0.5, x, y, 0.5, x, y, 0.5)
    end
    SetImageState('white', '', Color(255, 255, 255, 255))
end

---渲染一个扇形
---@param img string @渲染图像
---@param x number @中心x坐标
---@param y number @中心y坐标
---@param a1 number @左角度
---@param a2 number @右角度
---@param r1 number @外径
---@param r2 number @内径
---@param z number @z坐标
function lib.RenderFanShape(img, x, y, a1, a2, r1, r2, z)
    z = z or 0.5
    local x1, y1 = x + r1 * cos(a1), y + r1 * sin(a1)
    local x2, y2 = x + r1 * cos(a2), y + r1 * sin(a2)
    local x3, y3 = x + r2 * cos(a2), y + r2 * sin(a2)
    local x4, y4 = x + r2 * cos(a1), y + r2 * sin(a1)
    Render4V(img, x1, y1, z, x2, y2, z, x3, y3, z, x4, y4, z)
end

---渲染一个斜椭圆扇形
---@param img string @渲染图像
---@param x number @中心x坐标
---@param y number @中心y坐标
---@param a1 number @左角度
---@param a2 number @右角度
---@param r1 number @外径a
---@param r2 number @外径b
---@param r3 number @内径a
---@param r4 number @内径b
---@param rot number @椭圆倾斜角
---@param z number @z坐标
function lib.RenderFanShape2(img, x, y, a1, a2, r1, r2, r3, r4, rot, z)
    rot, z = rot or 0, z or 0.5
    a1, a2 = a1 + rot, a2 + rot
    local x1 = x + r1 * cos(a1) * cos(rot) - r2 * sin(a1) * sin(rot)
    local y1 = y + r1 * cos(a1) * sin(rot) + r2 * sin(a1) * cos(rot)
    local x2 = x + r1 * cos(a2) * cos(rot) - r2 * sin(a2) * sin(rot)
    local y2 = y + r1 * cos(a2) * sin(rot) + r2 * sin(a2) * cos(rot)
    local x3 = x + r3 * cos(a2) * cos(rot) - r4 * sin(a2) * sin(rot)
    local y3 = y + r3 * cos(a2) * sin(rot) + r4 * sin(a2) * cos(rot)
    local x4 = x + r3 * cos(a1) * cos(rot) - r4 * sin(a1) * sin(rot)
    local y4 = y + r3 * cos(a1) * sin(rot) + r4 * sin(a1) * cos(rot)
    Render4V(img, x1, y1, z, x2, y2, z, x3, y3, z, x4, y4, z)
end

---渲染环形
---@param img string @渲染图像
---@param x number @中心x坐标
---@param y number @中心y坐标
---@param r1 number @外径
---@param r2 number @内径
---@param N number @图片循环次数
---@param rot number @旋转角度
---@param length number @长度
---@param z number @z坐标
function lib.RenderRing(img, x, y, r1, r2, N, rot, length, z)
    N, rot, length, z = N or 1, rot or 0, length or 360, z or 0.5
    local da = length / N
    for i = 1, N do
        lib.RenderFanShape(img, x, y, rot + (i - 1) * da, rot + i * da, r1, r2, z)
    end
end

---渲染斜椭圆环形
---@param img string @渲染图像
---@param x number @中心x坐标
---@param y number @中心y坐标
---@param r1 number @外径a
---@param r2 number @外径b
---@param r3 number @内径a
---@param r4 number @内径b
---@param N number @图片循环次数
---@param ang number @椭圆倾斜角
---@param rot number @旋转角度
---@param length number @长度
---@param z number @z坐标
function lib.RenderRing2(img, x, y, r1, r2, r3, r4, N, ang, rot, length, z)
    N, ang, rot, length, z = N or 1, ang or 0, rot or 0, length or 360, z or 0.5
    local da = length / N
    for i = 1, N do
        lib.RenderFanShape2(img, x, y, rot + (i - 1) * da, rot + i * da, r1, r2, r3, r4, ang, z)
    end
end

---渲染图像分割环形
---@param img string @渲染图像
---@param x number @中心x坐标
---@param y number @中心y坐标
---@param r1 number @外径
---@param r2 number @内径
---@param n number @图片分割次数
---@param N number @图片循环次数
---@param rot number @旋转角度
---@param length number @长度
---@param blend string @blend mode
---@param color lstgColor @颜色
---@param z number @z坐标
function lib.RenderRing3(img, x, y, r1, r2, n, N, rot, length, blend, color, z)
    n, N, rot, length, z = n or 1, N or 1, rot or 0, length or 360, z or 0.5
    local da = length / N
    local dd = da / n
    if not (lstg.tmpvar.ImgList) then
        lstg.tmpvar.ImgList = {}
    end
    if not (lstg.tmpvar.ImgList[img]) then
        local w, h = GetTextureSize(img)
        LoadImageGroup(img, img, 0, 0, w / n, h, n, 1, 0, 0)
        lstg.tmpvar.ImgList[img] = true
    end
    for d = 1, n do
        if blend and color then
            SetImageState(img .. d, blend, color)
        end
        for i = 1, N do
            lib.RenderFanShape(img .. d, x, y, rot + (i - 1) * da + (d - 1) * dd, rot + (i - 1) * da + d * dd, r1, r2, z)
        end
    end
end

---渲染图像分割斜椭圆环形
---@param img string @渲染图像
---@param x number @中心x坐标
---@param y number @中心y坐标
---@param r1 number @外径a
---@param r2 number @外径b
---@param r3 number @内径a
---@param r4 number @内径b
---@param n number @图片分割次数
---@param N number @图片循环次数
---@param ang number @椭圆倾斜角
---@param rot number @旋转角度
---@param length number @长度
---@param blend string @blend mode
---@param color lstgColor @颜色
---@param z number @z坐标
function lib.RenderRing4(img, x, y, r1, r2, r3, r4, n, N, ang, rot, length, blend, color, z)
    n, N, ang, rot, length, z = n or 1, N or 1, ang or 0, rot or 0, length or 360, z or 0.5
    local da = length / N
    local dd = da / n
    if not (lstg.tmpvar.ImgList) then
        lstg.tmpvar.ImgList = {}
    end
    if not (lstg.tmpvar.ImgList[img]) then
        local w, h = GetTextureSize(img)
        LoadImageGroup(img, img, 0, 0, w / n, h, n, 1, 0, 0)
        lstg.tmpvar.ImgList[img] = true
    end
    for d = 1, n do
        if blend and color then
            SetImageState(img .. d, blend, color)
        end
        for i = 1, N do
            lib.RenderFanShape2(img .. d, x, y, rot + (i - 1) * da + (d - 1) * dd, rot + (i - 1) * da + d * dd, r1, r2, r3, r4, ang, z)
        end
    end
end

function lib.Render3DAura2D(img, x, y, z, r, rot, a1, a2, a3)
    local lst = {}
    local dx, dy, ref
    for i = 1, 4 do
        dx = r * cos(225 - i * 90 + rot)
        dy = r * sin(225 - i * 90 + rot)
        ref = sp.math.point3DT(dx, dy, z, 0, 0, 0, 0, a1, a2, a3)
        table.insert(lst, ref[1] + x)
        table.insert(lst, ref[2] + y)
        table.insert(lst, 0.5)
    end
    Render4V(img, unpack(lst))
end

function lib.Render3DAura(img, x, y, z, r, rot, a1, a2, a3)
    local lst = {}
    local dx, dy, ref
    for i = 1, 4 do
        dx = r * cos(225 - i * 90 + rot)
        dy = r * sin(225 - i * 90 + rot)
        ref = sp.math.point3DT(dx, dy, z, 0, 0, 0, 0, a1, a2, a3)
        table.insert(lst, ref[1] + x)
        table.insert(lst, ref[2] + y)
        table.insert(lst, ref[3])
    end
    Render4V(img, unpack(lst))
end

---通过纹理渲染循环矩形
---@param tex string @纹理
---@param x number @起始x坐标
---@param y number @起始y坐标
---@param a number @角度
---@param width number @宽度
---@param offset number @纹理偏移值
---@param blend string @blend mode
---@param c lstgColor @颜色
---@param t number @长度
function lib.CreateLaser(tex, x, y, a, width, offset, blend, c, t)
    width = width / 2
    local w, h = GetTextureSize(tex)
    local n = int(offset / w)
    local length = t % w
    local endl = int(offset - n * w)
    for i = 1, n do
        RenderTexture(tex, blend,
                { x + (length + w * (i - 1)) * cos(a) - width * sin(a), y + (length + w * (i - 1)) * sin(a) + width * cos(a), 0.5, 0, 0, c },
                { x + w * i * cos(a) - width * sin(a), y + w * i * sin(a) + width * cos(a), 0.5, w - length, 0, c },
                { x + w * i * cos(a) + width * sin(a), y + w * i * sin(a) - width * cos(a), 0.5, w - length, h, c },
                { x + (length + w * (i - 1)) * cos(a) + width * sin(a), y + (length + w * (i - 1)) * sin(a) - width * cos(a), 0.5, 0, h, c }
        )
        RenderTexture(tex, blend,
                { x + w * (i - 1) * cos(a) - width * sin(a), y + w * (i - 1) * sin(a) + width * cos(a), 0.5, w - length, 0, c },
                { x + (length + w * (i - 1)) * cos(a) - width * sin(a), y + (length + w * (i - 1)) * sin(a) + width * cos(a), 0.5, w, 0, c },
                { x + (length + w * (i - 1)) * cos(a) + width * sin(a), y + (length + w * (i - 1)) * sin(a) - width * cos(a), 0.5, w, h, c },
                { x + w * (i - 1) * cos(a) + width * sin(a), y + w * (i - 1) * sin(a) - width * cos(a), 0.5, w - length, h, c }
        )
    end
    if length <= endl then
        RenderTexture(tex, blend,
                { x + (length + w * n) * cos(a) - width * sin(a), y + (length + w * n) * sin(a) + width * cos(a), 0.5, 0, 0, c },
                { x + (w * n + endl) * cos(a) - width * sin(a), y + (w * n + endl) * sin(a) + width * cos(a), 0.5, endl - length, 0, c },
                { x + (w * n + endl) * cos(a) + width * sin(a), y + (w * n + endl) * sin(a) - width * cos(a), 0.5, endl - length, h, c },
                { x + (length + w * n) * cos(a) + width * sin(a), y + (length + w * n) * sin(a) - width * cos(a), 0.5, 0, h, c }
        )
        RenderTexture(tex, blend,
                { x + w * n * cos(a) - width * sin(a), y + w * n * sin(a) + width * cos(a), 0.5, w - length, 0, c },
                { x + (length + w * n) * cos(a) - width * sin(a), y + (length + w * n) * sin(a) + width * cos(a), 0.5, w, 0, c },
                { x + (length + w * n) * cos(a) + width * sin(a), y + (length + w * n) * sin(a) - width * cos(a), 0.5, w, h, c },
                { x + w * n * cos(a) + width * sin(a), y + w * n * sin(a) - width * cos(a), 0.5, w - length, h, c }
        )
    else
        RenderTexture(tex, blend,
                { x + w * n * cos(a) - width * sin(a), y + w * n * sin(a) + width * cos(a), 0.5, w - length, 0, c },
                { x + (endl + w * n) * cos(a) - width * sin(a), y + (endl + w * n) * sin(a) + width * cos(a), 0.5, endl + w - length, 0, c },
                { x + (endl + w * n) * cos(a) + width * sin(a), y + (endl + w * n) * sin(a) - width * cos(a), 0.5, endl + w - length, h, c },
                { x + w * n * cos(a) + width * sin(a), y + w * n * sin(a) - width * cos(a), 0.5, w - length, h, c }
        )
    end
end

---判断对象是否在目标矩形内
---@param x0 number @起始x坐标
---@param y0 number @起始y坐标
---@param a number @角度
---@param unit object @对象
---@param w number @宽度
function lib.IsInLaser(x0, y0, a, unit, w)
    local a1 = a - Angle(x0, y0, unit.x, unit.y)
    if a % 180 == 90 then
        return (abs(unit.x - x0) < ((unit.a + unit.b + w) / 2) and cos(a1) >= 0)
    else
        local A = tan(a)
        local C = y0 - A * x0
        return (abs(A * unit.x - unit.y + C) / hypot(A, 1) < ((unit.a + unit.b + w) / 2) and cos(a1) >= 0)
    end
end

_log(string.format("[spmisc] complete"))