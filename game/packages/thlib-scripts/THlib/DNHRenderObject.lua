---获取表index最大数值
---@param t table @目标表
local function max_n(t)
    local n = 0
    for k in pairs(t) do
        if type(k) == "number" and k > n then
            n = k
        end
    end
    return n
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

local BaseRenderObject = Class(object)
function BaseRenderObject:init(master)
    self.master = master
end
function BaseRenderObject:frame()
    self.master:frame()
end
function BaseRenderObject:render()
    self.master:render()
end

---@class DNHRenderObject
---@return DNHRenderObject
lstg.DNHRenderObject = plus.Class()
local RO = lstg.DNHRenderObject
function RO:init()
    self.vertex = {}
    self._obj = New(BaseRenderObject, self)
    self:setBlend("")
    self:setColor(0xFFFFFFFF)
    self:setMaxVertex(3)
end

function RO:frame()
end

do
    local vt, p0, p1, p2
    function RO:render()
        if self.tex then
            vt = self.vertex[0]
            p0 = { vt.x, vt.y, vt.z, vt.u, vt.v, vt.color or self.color }
            for i = 1, self.max_vertex - 1 do
                vt = self.vertex[i]
                p1 = { vt.x, vt.y, vt.z, vt.u, vt.v, vt.color or self.color }
                vt = self.vertex[i + 1]
                p2 = { vt.x, vt.y, vt.z, vt.u, vt.v, vt.color or self.color }
                RenderTexture(self.tex, self.blend, p0, p1, p2, p0)
            end
        end
    end
end

---设置绑定的纹理
---@param tex string @目标纹理
function RO:setTex(tex)
    self.tex = tex
end

---设置渲染层级
---@param layer number @目标渲染层级
function RO:setLayer(layer)
    self._obj.layer = layer
end

---设置是否隐藏渲染
---@param hide boolean @是否隐藏
function RO:setHide(hide)
    if hide ~= false then
        hide = true
    end
    self._obj.hide = hide
end

---设置混合模式
---@param blend string @目标混合模式
function RO:setBlend(blend)
    self.blend = blend
end

---设置颜色
---@param a number @alpha
---@param r number @red
---@param g number @green
---@param b number @blue
---@param index number|nil @目标顶点
---@overload fun(argb:number, index:number|nil)
---@overload fun(color:userdata, index:number|nil)
function RO:setColor(a, r, g, b, index)
    local c
    if a and r and g and b then
        c = Color(a, r, g, b)
    elseif type(a) == "userdata" then
        c = a
    elseif a then
        c = Color(a)
    end
    if index then
        self.vertex[index] = c
    else
        self.color = c
    end
end

---设置顶点上限
---@param n number @顶点总数(实际顶点数为n+1)
function RO:setMaxVertex(n)
    n = max(0, int(n or 0))
    self.max_vertex = n
    for i = 0, n do
        self.vertex[i] = {}
    end
    for i = n + 1, max_n(self.vertex) do
        self.vertex[i] = nil
    end
end

---设置顶点属性
---@param index number @目标顶点
---@param x number @顶点位置x
---@param y number @顶点位置y
---@param z number @顶点位置z
---@param u number @纹理坐标u
---@param v number @纹理坐标v
---@param color lstg.Color|nil @顶点颜色
function RO:setVertex(index, x, y, z, u, v, color)
    self.vertex[index].x = x
    self.vertex[index].y = y
    self.vertex[index].z = z
    self.vertex[index].u = u
    self.vertex[index].v = v
    self.vertex[index].color = color
end

---设置顶点位置
---@param index number @目标顶点
---@param x number @顶点位置x
---@param y number @顶点位置y
---@param z number @顶点位置z
function RO:setVertexXYZ(index, x, y, z)
    self.vertex[index].x = x
    self.vertex[index].y = y
    self.vertex[index].z = z
end

---设置顶点纹理坐标
---@param index number @目标顶点
---@param u number @纹理坐标u
---@param v number @纹理坐标v
function RO:setVertexUV(index, u, v)
    self.vertex[index].u = u
    self.vertex[index].v = v
end

---设置顶点颜色
---@param index number @目标顶点
---@param color lstg.Color|nil @顶点颜色
function RO:setVertexColor(index, color)
    self.vertex[index].color = color
end

---设置渲染矩形
---@param x number @渲染位置中心x
---@param y number @渲染位置中心y
---@param w number @渲染宽度w
---@param h number @渲染高度h
---@param rot number @渲染角度
function RO:setRenderRect(x, y, w, h, rot)
    rot = rot or 0
    if self.max_vertex ~= 3 then
        self:setMaxVertex(3)
    end
    local vx, vy = get_pos(x, y, -w / 2, h / 2, rot)
    self:setVertexXYZ(0, vx, vy, 0.5)
    vx, vy = get_pos(x, y, w / 2, h / 2, rot)
    self:setVertexXYZ(1, vx, vy, 0.5)
    vx, vy = get_pos(x, y, w / 2, -h / 2, rot)
    self:setVertexXYZ(2, vx, vy, 0.5)
    vx, vy = get_pos(x, y, -w / 2, -h / 2, rot)
    self:setVertexXYZ(3, vx, vy, 0.5)
end

---设置纹理矩形
---@param x number @纹理位置中心x
---@param y number @纹理位置中心y
---@param w number @纹理宽度w
---@param h number @纹理高度h
---@param rot number @纹理角度
function RO:setTextureRect(x, y, w, h, rot)
    rot = -(rot or 0)
    if self.max_vertex ~= 3 then
        self:setMaxVertex(3)
    end
    local vx, vy = get_pos(x, y, -w / 2, h / 2, rot)
    self:setVertexUV(0, vx, vy)
    vx, vy = get_pos(x, y, w / 2, h / 2, rot)
    self:setVertexUV(1, vx, vy)
    vx, vy = get_pos(x, y, w / 2, -h / 2, rot)
    self:setVertexUV(2, vx, vy)
    vx, vy = get_pos(x, y, -w / 2, -h / 2, rot)
    self:setVertexUV(3, vx, vy)
end

function RO:isValid()
    return IsValid(self._obj)
end

function RO:delete()
    if IsValid(self._obj) then
        Del(self._obj)
    end
end

---@class DNHRenderClass
---@return DNHRenderClass
lstg.DNHRenderClass = plus.Class()
local RC = lstg.DNHRenderClass
function RC:init()
    self.vertex = {}
    self:setBlend("")
    self:setColor(0xFFFFFFFF)
    self:setMaxVertex(3)
end

do
    local vt, p0, p1, p2
    function RC:render()
        if self.tex then
            vt = self.vertex[0]
            p0 = { vt.x, vt.y, vt.z, vt.u, vt.v, vt.color or self.color }
            for i = 1, self.max_vertex - 1 do
                vt = self.vertex[i]
                p1 = { vt.x, vt.y, vt.z, vt.u, vt.v, vt.color or self.color }
                vt = self.vertex[i + 1]
                p2 = { vt.x, vt.y, vt.z, vt.u, vt.v, vt.color or self.color }
                RenderTexture(self.tex, self.blend, p0, p1, p2, p0)
            end
        end
    end
end

---设置绑定的纹理
---@param tex string @目标纹理
function RC:setTex(tex)
    self.tex = tex
end

---设置混合模式
---@param blend string @目标混合模式
function RC:setBlend(blend)
    self.blend = blend
end

---设置颜色
---@param a number @alpha
---@param r number @red
---@param g number @green
---@param b number @blue
---@param index number|nil @目标顶点
---@overload fun(argb:number, index:number|nil)
---@overload fun(color:userdata, index:number|nil)
function RC:setColor(a, r, g, b, index)
    local c
    if a and r and g and b then
        c = Color(a, r, g, b)
    elseif type(a) == "userdata" then
        c = a
    elseif a then
        c = Color(a)
    end
    if index then
        self.vertex[index] = c
    else
        self.color = c
    end
end

---设置顶点上限
---@param n number @顶点总数(实际顶点数为n+1)
function RC:setMaxVertex(n)
    n = max(0, int(n or 0))
    self.max_vertex = n
    for i = 0, n do
        self.vertex[i] = {}
    end
    for i = n + 1, max_n(self.vertex) do
        self.vertex[i] = nil
    end
end

---设置顶点属性
---@param index number @目标顶点
---@param x number @顶点位置x
---@param y number @顶点位置y
---@param z number @顶点位置z
---@param u number @纹理坐标u
---@param v number @纹理坐标v
---@param color lstg.Color|nil @顶点颜色
function RC:setVertex(index, x, y, z, u, v, color)
    self.vertex[index].x = x
    self.vertex[index].y = y
    self.vertex[index].z = z
    self.vertex[index].u = u
    self.vertex[index].v = v
    self.vertex[index].color = color
end

---设置顶点位置
---@param index number @目标顶点
---@param x number @顶点位置x
---@param y number @顶点位置y
---@param z number @顶点位置z
function RC:setVertexXYZ(index, x, y, z)
    self.vertex[index].x = x
    self.vertex[index].y = y
    self.vertex[index].z = z
end

---设置顶点纹理坐标
---@param index number @目标顶点
---@param u number @纹理坐标u
---@param v number @纹理坐标v
function RC:setVertexUV(index, u, v)
    self.vertex[index].u = u
    self.vertex[index].v = v
end

---设置顶点颜色
---@param index number @目标顶点
---@param color lstg.Color|nil @顶点颜色
function RC:setVertexColor(index, color)
    self.vertex[index].color = color
end

---设置渲染矩形
---@param x number @渲染位置中心x
---@param y number @渲染位置中心y
---@param w number @渲染宽度w
---@param h number @渲染高度h
---@param rot number @渲染角度
function RC:setRenderRect(x, y, w, h, rot)
    rot = rot or 0
    if self.max_vertex ~= 3 then
        self:setMaxVertex(3)
    end
    local vx, vy = get_pos(x, y, -w / 2, h / 2, rot)
    self:setVertexXYZ(0, vx, vy, 0.5)
    vx, vy = get_pos(x, y, w / 2, h / 2, rot)
    self:setVertexXYZ(1, vx, vy, 0.5)
    vx, vy = get_pos(x, y, w / 2, -h / 2, rot)
    self:setVertexXYZ(2, vx, vy, 0.5)
    vx, vy = get_pos(x, y, -w / 2, -h / 2, rot)
    self:setVertexXYZ(3, vx, vy, 0.5)
end

---设置纹理矩形
---@param x number @纹理位置中心x
---@param y number @纹理位置中心y
---@param w number @纹理宽度w
---@param h number @纹理高度h
---@param rot number @纹理角度
function RC:setTextureRect(x, y, w, h, rot)
    rot = -(rot or 0)
    if self.max_vertex ~= 3 then
        self:setMaxVertex(3)
    end
    local vx, vy = get_pos(x, y, -w / 2, h / 2, rot)
    self:setVertexUV(0, vx, vy)
    vx, vy = get_pos(x, y, w / 2, h / 2, rot)
    self:setVertexUV(1, vx, vy)
    vx, vy = get_pos(x, y, w / 2, -h / 2, rot)
    self:setVertexUV(2, vx, vy)
    vx, vy = get_pos(x, y, -w / 2, -h / 2, rot)
    self:setVertexUV(3, vx, vy)
end