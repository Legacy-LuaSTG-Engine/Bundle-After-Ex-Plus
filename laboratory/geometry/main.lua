local lstg = require("lstg")
lstg.FileManager.AddSearchPath("../../game/packages/thlib-scripts/")
lstg.FileManager.AddSearchPath("../../game/packages/thlib-scripts-v2/")
lstg.FileManager.AddSearchPath("../../game/packages/thlib-resources/")

local Keyboard = lstg.Input.Keyboard
local Mouse = lstg.Input.Mouse

local window = {
    width = 640,
    height = 480,
    view_width = 1280,
    view_height = 960,
}
function window:applyWindowSetting()
    lstg.ChangeVideoMode(self.view_width, self.view_height, true, false)
end
function window:applyCameraSetting()
    lstg.SetViewport(0, self.view_width, 0, self.view_height)
    lstg.SetScissorRect(0, self.view_width, 0, self.view_height)
    lstg.SetOrtho(0, self.width, 0, self.height)
    lstg.SetFog()
    lstg.SetImageScale(1.0)
    lstg.SetZBufferEnable(0)
end

local function loadSprite(name, path, mipmap)
    lstg.LoadTexture(name, path, mipmap)
    local width, height = lstg.GetTextureSize(name)
    lstg.LoadImage(name, name, 0, 0, width, height)
end
loadSprite("white", "white.png", false)

--region Geometry
local Vector2 = require("foundation.math.Vector2")

local Line = require("foundation.shape.Line")
local Ray = require("foundation.shape.Ray")
local Segment = require("foundation.shape.Segment")

local Triangle = require("foundation.shape.Triangle")
local Rectangle = require("foundation.shape.Rectangle")
local Polygon = require("foundation.shape.Polygon")
local Circle = require("foundation.shape.Circle")
local Sector = require("foundation.shape.Sector")
--endregion

--region Math Method
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
--endregion

--region Render Method
local function setColor(a, r, g, b)
    lstg.SetImageState("white", "", lstg.Color(a, r, g, b))
end

---@param p {x:number, y:number}
---@param size number
local function renderPoint(p, size)
    lstg.Render("white", p.x, p.y, 0, size / 8)
end

---@param p1 {x:number, y:number}
---@param p2 {x:number, y:number}
---@param width number
local function renderLine(p1, p2, width)
    local cx = (p1.x + p2.x) / 2
    local cy = (p1.y + p2.y) / 2
    local length = Dist(p1, p2)
    local rot = Angle(p1, p2)
    local hscale = length / 16
    local vscale = width / 16
    lstg.Render("white", cx, cy, rot, hscale, vscale)
end

---@param p {x:number, y:number}
---@param radius1 number
---@param radius2 number
---@param n number
local function renderCircle(p, radius1, radius2, n)
    local angle = 360 / n
    for i = 1, n do
        local angle1 = (i - 1) * angle
        local angle2 = i * angle
        local x1 = p.x + radius1 * lstg.cos(angle1)
        local y1 = p.y + radius1 * lstg.sin(angle1)
        local x2 = p.x + radius1 * lstg.cos(angle2)
        local y2 = p.y + radius1 * lstg.sin(angle2)
        local x3 = p.x + radius2 * lstg.cos(angle2)
        local y3 = p.y + radius2 * lstg.sin(angle2)
        local x4 = p.x + radius2 * lstg.cos(angle1)
        local y4 = p.y + radius2 * lstg.sin(angle1)
        lstg.Render4V("white", x1, y1, 0.5,
                x2, y2, 0.5,
                x3, y3, 0.5,
                x4, y4, 0.5)
    end
end

---@param p {x:number, y:number}
---@param radius1 number
---@param radius2 number
---@param angleFrom number
---@param angleTo number
---@param n number
local function renderSector(p, radius1, radius2, angleFrom, angleTo, n)
    local angle = (angleTo - angleFrom) / n
    for i = 1, n do
        local angle1 = angleFrom + (i - 1) * angle
        local angle2 = angleFrom + i * angle
        local x1 = p.x + radius1 * lstg.cos(angle1)
        local y1 = p.y + radius1 * lstg.sin(angle1)
        local x2 = p.x + radius1 * lstg.cos(angle2)
        local y2 = p.y + radius1 * lstg.sin(angle2)
        local x3 = p.x + radius2 * lstg.cos(angle2)
        local y3 = p.y + radius2 * lstg.sin(angle2)
        local x4 = p.x + radius2 * lstg.cos(angle1)
        local y4 = p.y + radius2 * lstg.sin(angle1)
        lstg.Render4V("white", x1, y1, 0.5,
                x2, y2, 0.5,
                x3, y3, 0.5,
                x4, y4, 0.5)
    end
end
--endregion

--region Player Method
local player = {}
function player:pos()
    local mouseX, mouseY = Mouse.GetPosition()
    mouseX = mouseX / window.view_width * window.width
    mouseY = mouseY / window.view_height * window.height
    return Vector2.create(mouseX, mouseY)
end
--endregion

--region Object Method
local object = {
    pool = {},
    collision_result = {},
}
function object:insert(obj)
    table.insert(self.pool, obj)
end
function object:clear()
    self.pool = {}
end
function object:enum()
    return ipairs(self.pool)
end
function object:updateCollisionCheck()
    local result = {}
    for i = 1, #self.pool do
        local obj1 = self.pool[i]
        for j = i + 1, #self.pool do
            local obj2 = self.pool[j]
            local intersection, points = obj1:intersects(obj2)
            if intersection then
                for _, point in ipairs(points) do
                    table.insert(result, point)
                end
            end
        end
    end
    self.collision_result = result
end
function object:update()
    self:updateCollisionCheck()
end
function object:draw()
    local player_pos = player:pos()
    self:renderPlayerPoint(player_pos)
    for _, obj in self:enum() do
        if obj.__type == "foundation.shape.Line" then
            self:renderLine(obj, player_pos)
        elseif obj.__type == "foundation.shape.Ray" then
            self:renderRay(obj, player_pos)
        elseif obj.__type == "foundation.shape.Segment" then
            self:renderSegment(obj, player_pos)
        elseif obj.__type == "foundation.shape.Triangle" then
            self:renderTriangle(obj, player_pos)
        elseif obj.__type == "foundation.shape.Circle" then
            self:renderCircle(obj, player_pos)
        elseif obj.__type == "foundation.shape.Rectangle" then
            self:renderRectangle(obj, player_pos)
        elseif obj.__type == "foundation.shape.Sector" then
            self:renderSector(obj, player_pos)
        elseif obj.__type == "foundation.shape.Polygon" then
            self:renderPolygon(obj, player_pos)
        end
        self:renderProjectPoint(obj, player_pos)
        self:renderClosestPoint(obj, player_pos)
    end
    setColor(192, 0, 255, 255)
    for _, point in ipairs(self.collision_result) do
        renderPoint(point, 4)
    end
end

---@param player_pos {x:number, y:number}
function object:renderPlayerPoint(player_pos)
    setColor(255, 255, 255, 255)
    renderPoint(player_pos, 4)
end

---@param obj {__type:string, closestPoint:function}
---@param player_pos {x:number, y:number}
function object:renderClosestPoint(obj, player_pos)
    local nearestPoint = obj:closestPoint(player_pos)
    setColor(127, 127, 127, 127)
    renderLine(player_pos, nearestPoint, 2)
    setColor(192, 255, 200, 127)
    renderPoint(nearestPoint, 4)
end

---@param obj {__type:string, projectPoint:function}
---@param player_pos {x:number, y:number}
function object:renderProjectPoint(obj, player_pos)
    local projectPoint = obj:projectPoint(player_pos)
    setColor(127, 127, 127, 127)
    renderLine(player_pos, projectPoint, 2)
    setColor(192, 200, 127, 255)
    renderPoint(projectPoint, 4)
end

---@param line foundation.shape.Line
---@param player_pos {x:number, y:number}
function object:renderLine(line, player_pos)
    if line:containsPoint(player_pos, 1) then
        setColor(192, 0, 0, 255)
    else
        setColor(192, 255, 255, 255)
    end
    renderLine(line:getPoint(-1000), line:getPoint(1000), 2)
    setColor(127, 255, 0, 0)
    renderPoint(line.point, 4)
    setColor(127, 255, 63, 63)
    renderLine(line.point, line:getPoint(50), 2)
end

---@param ray foundation.shape.Ray
---@param player_pos {x:number, y:number}
function object:renderRay(ray, player_pos)
    if ray:containsPoint(player_pos, 1) then
        setColor(192, 0, 0, 255)
    else
        setColor(192, 255, 255, 255)
    end
    renderLine(ray.point, ray:getPoint(1000), 2)
    setColor(127, 255, 0, 0)
    renderPoint(ray.point, 4)
    setColor(127, 255, 63, 63)
    renderLine(ray.point, ray:getPoint(50), 2)
end

---@param segment foundation.shape.Segment
---@param player_pos {x:number, y:number}
function object:renderSegment(segment, player_pos)
    if segment:containsPoint(player_pos, 1) then
        setColor(192, 0, 0, 255)
    else
        setColor(192, 255, 255, 255)
    end
    renderLine(segment.point1, segment.point2, 2)
    setColor(127, 127, 0, 0)
    renderPoint(segment.point1, 4)
    renderPoint(segment.point2, 4)
    setColor(127, 255, 0, 0)
    renderPoint(segment:midpoint(), 4)
    setColor(127, 255, 63, 63)
    renderLine(segment:midpoint(), segment.point1, 2)
end

---@param triangle foundation.shape.Triangle
---@param player_pos {x:number, y:number}
function object:renderTriangle(triangle, player_pos)
    setColor(63, 127, 255, 192)
    local incenter = triangle:incenter()
    local inradius = triangle:inradius()
    local circumcenter = triangle:circumcenter()
    local circumradius = triangle:circumradius()
    setColor(63, 127, 255, 192)
    renderCircle(incenter, inradius - 1, inradius + 1, 64)
    setColor(63, 127, 192, 255)
    renderCircle(circumcenter, circumradius - 1, circumradius + 1, 64)
    if triangle:containsPoint(player_pos, 1) then
        setColor(192, 0, 0, 255)
    elseif triangle:contains(player_pos) then
        setColor(192, 127, 255, 0)
    else
        setColor(192, 255, 255, 255)
    end
    renderLine(triangle.point1, triangle.point2, 2)
    renderLine(triangle.point2, triangle.point3, 2)
    renderLine(triangle.point3, triangle.point1, 2)
    setColor(127, 127, 0, 0)
    renderPoint(triangle.point1, 4)
    renderPoint(triangle.point2, 4)
    renderPoint(triangle.point3, 4)
    setColor(127, 255, 0, 0)
    renderPoint(triangle:centroid(), 4)
    setColor(127, 255, 63, 63)
    renderLine(triangle:centroid(), triangle.point1, 2)
end

---@param rectangle foundation.shape.Rectangle
---@param player_pos {x:number, y:number}
function object:renderRectangle(rectangle, player_pos)
    local p = rectangle.center
    local w = rectangle.width / 2
    local h = rectangle.height / 2
    local a = rectangle.direction:degreeAngle()
    local inradius = rectangle:inradius()
    local circumradius = rectangle:circumradius()
    setColor(63, 127, 255, 192)
    renderCircle(p, inradius - 1, inradius + 1, 64)
    setColor(63, 127, 192, 255)
    renderCircle(p, circumradius - 1, circumradius + 1, 64)
    if rectangle:containsPoint(player_pos, 1) then
        setColor(192, 0, 0, 255)
    elseif rectangle:contains(player_pos) then
        setColor(192, 127, 255, 0)
    else
        setColor(192, 255, 255, 255)
    end
    renderLine(p + Vector2.create(-w, -h):degreeRotated(a), p + Vector2.create(w, -h):degreeRotated(a), 2)
    renderLine(p + Vector2.create(w, -h):degreeRotated(a), p + Vector2.create(w, h):degreeRotated(a), 2)
    renderLine(p + Vector2.create(w, h):degreeRotated(a), p + Vector2.create(-w, h):degreeRotated(a), 2)
    renderLine(p + Vector2.create(-w, h):degreeRotated(a), p + Vector2.create(-w, -h):degreeRotated(a), 2)
    setColor(127, 127, 0, 0)
    renderPoint(p + Vector2.create(-w, -h):degreeRotated(a), 4)
    renderPoint(p + Vector2.create(w, -h):degreeRotated(a), 4)
    renderPoint(p + Vector2.create(w, h):degreeRotated(a), 4)
    renderPoint(p + Vector2.create(-w, h):degreeRotated(a), 4)
    setColor(127, 255, 0, 0)
    renderPoint(p, 4)
    setColor(127, 255, 63, 63)
    renderLine(p, p + Vector2.create(w, 0):degreeRotated(a), 2)
end

---@param polygon foundation.shape.Polygon
---@param player_pos {x:number, y:number}
function object:renderPolygon(polygon, player_pos)
    local vertices = polygon:getVertices()
    if polygon:containsPoint(player_pos, 1) then
        setColor(192, 0, 0, 255)
    elseif polygon:contains(player_pos) then
        setColor(192, 127, 255, 0)
    else
        setColor(192, 255, 255, 255)
    end
    for i = 1, #vertices do
        local p1 = vertices[i]
        local p2 = vertices[i % #vertices + 1]
        renderLine(p1, p2, 2)
    end
    setColor(127, 127, 0, 0)
    for _, vertex in ipairs(vertices) do
        renderPoint(vertex, 4)
    end
    setColor(127, 255, 0, 0)
    renderPoint(polygon:centroid(), 4)
    setColor(127, 255, 63, 63)
    renderLine(polygon:centroid(), vertices[1], 2)
end

---@param circle foundation.shape.Circle
---@param player_pos {x:number, y:number}
function object:renderCircle(circle, player_pos)
    local p = circle.center
    local r1 = circle.radius + 1
    local r2 = circle.radius - 1
    if circle:containsPoint(player_pos, 1) then
        setColor(192, 0, 0, 255)
    elseif circle:contains(player_pos) then
        setColor(192, 127, 255, 0)
    else
        setColor(192, 255, 255, 255)
    end
    renderCircle(p, r1, r2, 64)
    setColor(127, 255, 0, 0)
    renderPoint(p, 4)
    setColor(127, 255, 63, 63)
    renderLine(p, p + Vector2.create(0, r1), 2)
end

---@param sector foundation.shape.Sector
---@param player_pos {x:number, y:number}
function object:renderSector(sector, player_pos)
    local p = sector.center
    local r1 = sector.radius - 1
    local r2 = sector.radius + 1
    if sector:containsPoint(player_pos, 1) then
        setColor(192, 0, 0, 255)
    elseif sector:contains(player_pos) then
        setColor(192, 127, 255, 0)
    else
        setColor(192, 255, 255, 255)
    end
    local a1 = sector.direction:degreeAngle()
    local a2 = a1 + sector.range * 360
    renderSector(p, r1, r2, a1, a2, 64)
    renderLine(p, p + sector.direction * r1, 2)
    renderLine(p, p + sector.direction:degreeRotated(sector.range * 360) * r1, 2)
    setColor(127, 255, 0, 0)
    renderPoint(p, 4)
    setColor(127, 255, 63, 63)
    renderLine(p, p + sector.direction * r1, 2)
end
--endregion

--region Scene
local Scene1 = {}
Scene1.name = "Line"
function Scene1:create()
    self.timer = -1
    object:insert(
            Line.create(Vector2.create(0, 0), Vector2.createFromAngle(45))
                :move(Vector2.create(window.width / 4 * 3, window.height / 2))
    )
    object:insert(
            Line.create(Vector2.create(0, 0), Vector2.createFromAngle(45))
                :move(Vector2.create(window.width / 4, window.height / 2))
    )
end
function Scene1:destroy()
    object:clear()
end
function Scene1:update()
    self.timer = self.timer + 1
    for i, obj in object:enum() do
        obj:degreeRotate(-1 + 2 * (i % 2))
    end
    object:updateCollisionCheck()
end
function Scene1:draw()
    object:draw()
end

local Scene2 = {}
Scene2.name = "Ray"
function Scene2:create()
    self.timer = -1
    object:insert(
            Ray.create(Vector2.create(0, 0), Vector2.createFromAngle(135))
               :move(Vector2.create(window.width / 4 * 3, window.height / 2))
    )
    object:insert(
            Ray.create(Vector2.create(0, 0), Vector2.createFromAngle(45))
               :move(Vector2.create(window.width / 4, window.height / 2))
    )
end
function Scene2:destroy()
    object:clear()
end
function Scene2:update()
    self.timer = self.timer + 1
    for i, obj in object:enum() do
        obj:degreeRotate(-1 + 2 * (i % 2))
    end
    object:updateCollisionCheck()
end
function Scene2:draw()
    object:draw()
end

local Scene3 = {}
Scene3.name = "Segment"
function Scene3:create()
    self.timer = -1
    object:insert(
            Segment.create(Vector2.create(0, 0), Vector2.create(400, 0))
                   :move(Vector2.create(0, window.height / 2))
    )
    object:insert(
            Segment.create(Vector2.create(0, 0), Vector2.create(0, 400))
                   :move(Vector2.create(window.width / 2, window.height / 4))
    )
    object:insert(
            Segment.create(Vector2.create(0, 0), Vector2.create(200, 200))
                   :move(Vector2.create(window.width / 3, window.height / 2))
    )
end
function Scene3:destroy()
    object:clear()
end
function Scene3:update()
    self.timer = self.timer + 1
    for i, obj in object:enum() do
        local rotate = (-1 + 2 * (i % 2)) * math.floor((i + 1) / 2)
        local center
        if i % 3 == 0 then
            center = obj.point1
        elseif i % 3 == 1 then
            center = obj.point2
        else
            center = obj:midpoint()
        end
        obj:degreeRotate(rotate, center)
    end
    object:updateCollisionCheck()
end
function Scene3:draw()
    object:draw()
end

local Scene4 = {}
Scene4.name = "Triangle"
function Scene4:create()
    self.timer = -1
    object:insert(
            Triangle.create(Vector2.create(0, 0), Vector2.create(200, 0), Vector2.create(100, 300))
                    :move(Vector2.create(window.width / 4, window.height / 2))
    )
    object:insert(
            Triangle.create(Vector2.create(0, 0), Vector2.create(200, 0), Vector2.create(400, -300))
                    :move(Vector2.create(0, window.height / 2))
    )
    object:insert(
            Triangle.create(Vector2.create(0, 0), Vector2.create(0, 400), Vector2.create(300, 0))
                    :move(Vector2.create(window.width / 2, 0))
    )
end
function Scene4:destroy()
    object:clear()
end
function Scene4:update()
    self.timer = self.timer + 1
    for i, obj in object:enum() do
        obj:degreeRotate(-1 + 2 * (i % 2))
    end
    object:updateCollisionCheck()
end
function Scene4:draw()
    object:draw()
end

local Scene5 = {}
Scene5.name = "Rectangle"
function Scene5:create()
    self.timer = -1
    object:insert(
            Rectangle.create(Vector2.create(0, 0), 200, 200)
                     :move(Vector2.create(window.width / 5 * 2, window.height / 2))
    )
    object:insert(
            Rectangle.create(Vector2.create(0, 0), 400, 100)
                     :move(Vector2.create(window.width / 5 * 3, window.height / 2))
    )
end
function Scene5:destroy()
    object:clear()
end
function Scene5:update()
    self.timer = self.timer + 1
    for i, obj in object:enum() do
        obj:degreeRotate(-1 + 2 * (i % 2))
    end
    object:updateCollisionCheck()
end
function Scene5:draw()
    object:draw()
end

local Scene6 = {}
Scene6.name = "Polygon and Sector and Circle"
function Scene6:create()
    self.timer = -1
    object:insert(
            Polygon.create({
                Vector2.create(0, -100),
                Vector2.create(-100, 0),
                Vector2.create(0, 100),
                Vector2.create(100, 0),
                Vector2.create(0, -100),
                Vector2.create(-100, -100),
                Vector2.create(-100, 100),
                Vector2.create(100, 100),
                Vector2.create(100, -100),
            })     :move(Vector2.create(window.width / 3, window.height / 7 * 5))
    )
    object:insert(
            Sector.create(Vector2.create(0, 0), 100, Vector2.createFromAngle(45), 0.75)
                  :move(Vector2.create(window.width / 3, window.height / 7 * 3))
    )
    object:insert(
            Circle.create(Vector2.create(0, 0), 150)
                  :move(Vector2.create(window.width / 3 * 2, window.height / 2))
    )
end
function Scene6:destroy()
    object:clear()
end
function Scene6:update()
    self.timer = self.timer + 1
    for i, obj in object:enum() do
        obj:degreeRotate(-1 + 2 * (i % 2))
    end
    object:updateCollisionCheck()
end
function Scene6:draw()
    object:draw()
end

local Scene7 = {}
Scene7.name = "Crazy"
function Scene7:create()
    self.timer = -1
    local rand = lstg.Rand()
    rand:Seed(os.time())
    --每种形状都随机创建一个
    object:insert(
            Line.create(Vector2.create(0, 0), Vector2.createFromAngle(rand:Float(0, 360)))
                :move(Vector2.create(window.width * rand:Float(0.25, 0.75), window.height * rand:Float(0.25, 0.75)))
    )
    object:insert(
            Ray.create(Vector2.create(0, 0), Vector2.createFromAngle(rand:Float(0, 360)))
               :move(Vector2.create(window.width * rand:Float(0.25, 0.75), window.height * rand:Float(0.25, 0.75)))
    )
    object:insert(
            Segment.create(Vector2.create(0, 0), Vector2.createFromAngle(rand:Float(0, 360)) * rand:Float(100, 300))
                   :move(Vector2.create(window.width * rand:Float(0.25, 0.75), window.height * rand:Float(0.25, 0.75)))
    )
    object:insert(
            Triangle.create(Vector2.create(0, 0),
                    Vector2.createFromAngle(rand:Float(0, 360)) * rand:Float(100, 300),
                    Vector2.createFromAngle(rand:Float(0, 360)) * rand:Float(100, 300))
                    :move(Vector2.create(window.width * rand:Float(0.25, 0.75), window.height * rand:Float(0.25, 0.75)))
    )
    object:insert(
            Rectangle.create(Vector2.create(0, 0), rand:Float(100, 300), rand:Float(100, 300))
                     :move(Vector2.create(window.width * rand:Float(0.25, 0.75), window.height * rand:Float(0.25, 0.75)))
    )
    object:insert(
            object:insert(
                    Polygon.create({
                        Vector2.create(0, -100),
                        Vector2.create(-100, 0),
                        Vector2.create(0, 100),
                        Vector2.create(100, 0),
                        Vector2.create(0, -100),
                        Vector2.create(-100, -100),
                        Vector2.create(-100, 100),
                        Vector2.create(100, 100),
                        Vector2.create(100, -100),
                    })     :move(Vector2.create(window.width * rand:Float(0.25, 0.75), window.height * rand:Float(0.25, 0.75)))
            )
    )
    object:insert(
            Circle.create(Vector2.create(0, 0), rand:Float(100, 300))
                  :move(Vector2.create(window.width * rand:Float(0.25, 0.75), window.height * rand:Float(0.25, 0.75)))
    )
    object:insert(
            Sector.create(Vector2.create(0, 0), rand:Float(100, 300), Vector2.createFromAngle(rand:Float(0, 360)), rand:Float(0.1, 0.9))
                  :move(Vector2.create(window.width * rand:Float(0.25, 0.75), window.height * rand:Float(0.25, 0.75)))
    )
end
function Scene7:destroy()
    object:clear()
end
function Scene7:update()
    self.timer = self.timer + 1
    for i, obj in object:enum() do
        obj:degreeRotate(-1 + 2 * (i % 2))
    end
    object:updateCollisionCheck()
end
function Scene7:draw()
    object:draw()
end
--endregion

---@generic T
---@param class T
---@return T
local function makeInstance(class)
    local instance = {}
    setmetatable(instance, { __index = class })
    return instance
end

local scenes = {
    Scene1,
    Scene2,
    Scene3,
    Scene4,
    Scene5,
    Scene6,
    Scene7,
}
local current_scene_index = 1
local current_scene = makeInstance(scenes[current_scene_index])
local any_key_down = false

function GameInit()
    window:applyWindowSetting()
    lstg.LoadTTF("Sans", "assets/font/SourceHanSansCN-Bold.otf", 0, 24)
    current_scene:create()
end

function GameExit()
    current_scene:destroy()
end

function FrameFunc()
    local change = 0
    if Keyboard.GetKeyState(Keyboard.Left) then
        if not any_key_down then
            any_key_down = true
            if current_scene_index > 1 then
                change = -1
            end
        end
    elseif Keyboard.GetKeyState(Keyboard.Right) then
        if not any_key_down then
            any_key_down = true
            if current_scene_index < #scenes then
                change = 1
            end
        end
    elseif any_key_down then
        any_key_down = false
    end
    if change ~= 0 then
        current_scene:destroy()
        current_scene_index = current_scene_index + change
        current_scene = makeInstance(scenes[current_scene_index])
        current_scene:create()
    end
    current_scene:update()
    return false
end

function RenderFunc()
    lstg.BeginScene()
    window:applyCameraSetting()
    lstg.RenderClear(lstg.Color(255, 0, 0, 0))
    current_scene:draw()
    local edge = 4
    lstg.RenderTTF("Sans", string.format("%s\n< %d/%d >", current_scene.name, current_scene_index, #scenes), edge, window.width - edge, edge, window.height - edge, 1 + 8, lstg.Color(255, 255, 255, 64), 2)
    lstg.EndScene()
end