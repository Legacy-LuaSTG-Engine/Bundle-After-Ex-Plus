local ffi = require("ffi")

local type = type
local ipairs = ipairs
local table = table
local math = math
local tostring = tostring
local string = string
local error = error
local rawset = rawset
local setmetatable = setmetatable

local Vector2 = require("foundation.math.Vector2")
local Segment = require("foundation.shape.Segment")
local Triangle = require("foundation.shape.Triangle")
local ShapeIntersector = require("foundation.shape.ShapeIntersector")

ffi.cdef [[
typedef struct {
    int size;
    foundation_math_Vector2* points;
} foundation_shape_Polygon;
]]

---@class foundation.shape.Polygon
---@field size number 多边形顶点数量
---@field points foundation.math.Vector2[] 多边形的顶点数组
local Polygon = {}
Polygon.__type = "foundation.shape.Polygon"

---@param self foundation.shape.Polygon
---@param key string
---@return any
function Polygon.__index(self, key)
    if key == "size" then
        return self.__data.size
    elseif key == "points" then
        return self.__data.points
    end
    return Polygon[key]
end

---@param t foundation.math.Vector2[]
---@return number, foundation.math.Vector2[]
local function buildNewVector2Array(t)
    local size = #t
    local points_array = ffi.new("foundation_math_Vector2[?]", size)

    for i = 1, size do
        points_array[i - 1] = Vector2.create(t[i].x, t[i].y)
    end

    return size, points_array
end

---@param self foundation.shape.Polygon
---@param key any
---@param value any
function Polygon.__newindex(self, key, value)
    if key == "size" then
        error("cannot modify size directly")
    elseif key == "points" then
        local size, points_array = buildNewVector2Array(value)
        self.__data.size = size
        self.__data.points = points_array
        self.__data_points_ref = points_array
    else
        rawset(self, key, value)
    end
end

---创建一个多边形
---@param points foundation.math.Vector2[] 多边形的顶点数组，按顺序连线并首尾相接
---@return foundation.shape.Polygon
function Polygon.create(points)
    if not points or #points < 3 then
        error("Polygon must have at least 3 points")
    end

    local size, points_array = buildNewVector2Array(points)

    local polygon = ffi.new("foundation_shape_Polygon", size, points_array)
    local result = {
        __data = polygon,
        __data_points_ref = points_array,
    }
    ---@diagnostic disable-next-line: return-type-mismatch, missing-return-value
    return setmetatable(result, Polygon)
end

---创建一个正多边形
---@param center foundation.math.Vector2 多边形的中心
---@param radius number 外接圆半径
---@param numSides number 边数
---@param startRad number 起始角度（弧度）
---@return foundation.shape.Polygon
function Polygon.createRegularRad(center, radius, numSides, startRad)
    startRad = startRad or 0
    local points = {}
    local angleStep = 2 * math.pi / numSides

    for i = 1, numSides do
        local angle = startRad + (i - 1) * angleStep
        local x = center.x + radius * math.cos(angle)
        local y = center.y + radius * math.sin(angle)
        points[i] = Vector2.create(x, y)
    end

    return Polygon.create(points)
end

---创建一个正多边形
---@param center foundation.math.Vector2 多边形的中心
---@param radius number 外接圆半径
---@param numSides number 边数
---@param startAngle number 起始角度（角度）
---@return foundation.shape.Polygon
function Polygon.createRegularDegree(center, radius, numSides, startAngle)
    return Polygon.createRegularRad(center, radius, numSides, math.rad(startAngle))
end

---多边形相等比较
---@param a foundation.shape.Polygon 第一个多边形
---@param b foundation.shape.Polygon 第二个多边形
---@return boolean
function Polygon.__eq(a, b)
    if a.size ~= b.size then
        return false
    end

    for i = 0, a.size - 1 do
        if a.points[i] ~= b.points[i] then
            return false
        end
    end

    return true
end

---多边形转字符串表示
---@param self foundation.shape.Polygon
---@return string
function Polygon.__tostring(self)
    local pointsStr = {}
    for i = 0, self.size - 1 do
        pointsStr[i + 1] = tostring(self.points[i])
    end
    return string.format("Polygon(%s)", table.concat(pointsStr, ", "))
end

---获取多边形的边数
---@return number
function Polygon:getEdgeCount()
    return self.size
end

---获取多边形的所有边（线段表示）
---@return foundation.shape.Segment[]
function Polygon:getEdges()
    local edges = {}

    for i = 0, self.size - 1 do
        local nextIdx = (i + 1) % self.size
        edges[i + 1] = Segment.create(self.points[i], self.points[nextIdx])
    end

    return edges
end

---获取多边形的顶点数组
---@return foundation.math.Vector2[]
function Polygon:getVertices()
    local vertices = {}
    for i = 0, self.size - 1 do
        vertices[i + 1] = self.points[i]:clone()
    end
    return vertices
end

---获取多边形的AABB包围盒
---@return number, number, number, number
function Polygon:AABB()
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge

    for i = 0, self.size - 1 do
        local point = self.points[i]
        minX = math.min(minX, point.x)
        minY = math.min(minY, point.y)
        maxX = math.max(maxX, point.x)
        maxY = math.max(maxY, point.y)
    end

    return minX, maxX, minY, maxY
end

---计算多边形的重心
---@return foundation.math.Vector2
function Polygon:centroid()
    local totalArea = 0
    local centroidX = 0
    local centroidY = 0

    local p0 = self.points[0]
    for i = 1, self.size - 2 do
        local p1 = self.points[i]
        local p2 = self.points[i + 1]

        local area = math.abs((p1.x - p0.x) * (p2.y - p0.y) - (p2.x - p0.x) * (p1.y - p0.y)) / 2
        totalArea = totalArea + area

        local cx = (p0.x + p1.x + p2.x) / 3
        local cy = (p0.y + p1.y + p2.y) / 3

        centroidX = centroidX + cx * area
        centroidY = centroidY + cy * area
    end

    if totalArea == 0 then
        return self:getCenter()
    end

    return Vector2.create(centroidX / totalArea, centroidY / totalArea)
end

---计算多边形的中心
---@return foundation.math.Vector2
function Polygon:getCenter()
    local minX, maxX, minY, maxY = self:AABB()
    return Vector2.create((minX + maxX) / 2, (minY + maxY) / 2)
end

---计算多边形的包围盒宽高
---@return number, number
function Polygon:getBoundingBoxSize()
    local minX, maxX, minY, maxY = self:AABB()
    return maxX - minX, maxY - minY
end

---计算多边形的面积
---@return number
function Polygon:getArea()
    local area = 0

    for i = 0, self.size - 1 do
        local j = (i + 1) % self.size
        area = area + (self.points[i].x * self.points[j].y) - (self.points[j].x * self.points[i].y)
    end

    return math.abs(area) / 2
end

---计算多边形的周长
---@return number
function Polygon:getPerimeter()
    local perimeter = 0

    for i = 0, self.size - 1 do
        local nextIdx = (i + 1) % self.size
        perimeter = perimeter + (self.points[i] - self.points[nextIdx]):length()
    end

    return perimeter
end

---判断多边形是否为凸多边形
---@return boolean
function Polygon:isConvex()
    if self.size < 3 then
        return false
    end

    local sign = 0
    local allCollinear = true

    for i = 0, self.size - 1 do
        local j = (i + 1) % self.size
        local k = (j + 1) % self.size

        local dx1 = self.points[j].x - self.points[i].x
        local dy1 = self.points[j].y - self.points[i].y
        local dx2 = self.points[k].x - self.points[j].x
        local dy2 = self.points[k].y - self.points[j].y

        local cross = dx1 * dy2 - dy1 * dx2
        local absCross = math.abs(cross)

        if absCross > 1e-10 then
            allCollinear = false
        end

        if i == 0 then
            if absCross > 1e-10 then
                sign = cross > 0 and 1 or -1
            end
        elseif (cross > 1e-10 and sign < 0) or (cross < -1e-10 and sign > 0) or (sign == 0 and absCross > 1e-10) then
            return false
        end
    end

    -- 如果所有点共线，不是合法的凸多边形
    if allCollinear then
        return false
    end

    return true
end

---平移多边形（更改当前多边形）
---@param v foundation.math.Vector2 | number 移动距离
---@return foundation.shape.Polygon 平移后的多边形（自身引用）
function Polygon:move(v)
    local moveX, moveY
    if type(v) == "number" then
        moveX, moveY = v, v
    else
        moveX, moveY = v.x, v.y
    end

    for i = 0, self.size - 1 do
        self.points[i].x = self.points[i].x + moveX
        self.points[i].y = self.points[i].y + moveY
    end

    return self
end

---获取当前多边形平移指定距离的副本
---@param v foundation.math.Vector2 | number 移动距离
---@return foundation.shape.Polygon 移动后的多边形副本
function Polygon:moved(v)
    local moveX, moveY
    if type(v) == "number" then
        moveX, moveY = v, v
    else
        moveX, moveY = v.x, v.y
    end

    local newPoints = {}
    for i = 0, self.size - 1 do
        newPoints[i + 1] = Vector2.create(self.points[i].x + moveX, self.points[i].y + moveY)
    end

    return Polygon.create(newPoints)
end

---将当前多边形旋转指定弧度（更改当前多边形）
---@param rad number 旋转弧度
---@param center foundation.math.Vector2|nil 旋转中心点，默认为多边形重心
---@return foundation.shape.Polygon 自身引用
function Polygon:rotate(rad, center)
    center = center or self:centroid()
    local cosRad = math.cos(rad)
    local sinRad = math.sin(rad)

    for i = 0, self.size - 1 do
        local point = self.points[i]
        local dx = point.x - center.x
        local dy = point.y - center.y
        point.x = center.x + dx * cosRad - dy * sinRad
        point.y = center.y + dx * sinRad + dy * cosRad
    end

    return self
end

---将当前多边形旋转指定角度（更改当前多边形）
---@param angle number 旋转角度
---@param center foundation.math.Vector2|nil 旋转中心点，默认为多边形重心
---@return foundation.shape.Polygon 自身引用
function Polygon:degreeRotate(angle, center)
    return self:rotate(math.rad(angle), center)
end

---获取当前多边形旋转指定弧度的副本
---@param rad number 旋转弧度
---@param center foundation.math.Vector2|nil 旋转中心点，默认为多边形重心
---@return foundation.shape.Polygon
function Polygon:rotated(rad, center)
    local points = self:getVertices()
    local result = Polygon.create(points)
    return result:rotate(rad, center)
end

---获取当前多边形旋转指定角度的副本
---@param angle number 旋转角度
---@param center foundation.math.Vector2|nil 旋转中心点，默认为多边形重心
---@return foundation.shape.Polygon
function Polygon:degreeRotated(angle, center)
    return self:rotated(math.rad(angle), center)
end

---将当前多边形缩放指定倍数（更改当前多边形）
---@param scale number|foundation.math.Vector2 缩放倍数
---@param center foundation.math.Vector2 缩放中心
---@return foundation.shape.Polygon 缩放后的多边形（自身引用）
---@overload fun(self: foundation.shape.Polygon, scale: number): foundation.shape.Polygon 相对多边形中心点缩放指定倍数
function Polygon:scale(scale, center)
    local scaleX, scaleY
    if type(scale) == "number" then
        scaleX, scaleY = scale, scale
    else
        scaleX, scaleY = scale.x, scale.y
    end
    center = center or self:centroid()

    for i = 0, self.size - 1 do
        self.points[i].x = (self.points[i].x - center.x) * scaleX + center.x
        self.points[i].y = (self.points[i].y - center.y) * scaleY + center.y
    end

    return self
end

---获取当前多边形缩放指定倍数的副本
---@param scale number|foundation.math.Vector2 缩放倍数
---@param center foundation.math.Vector2 缩放中心
---@return foundation.shape.Polygon 缩放后的多边形副本
---@overload fun(self: foundation.shape.Polygon, scale: number): foundation.shape.Polygon 相对多边形中心点缩放指定倍数
function Polygon:scaled(scale, center)
    local scaleX, scaleY
    if type(scale) == "number" then
        scaleX, scaleY = scale, scale
    else
        scaleX, scaleY = scale.x, scale.y
    end
    center = center or self:centroid()

    local newPoints = {}
    for i = 0, self.size - 1 do
        newPoints[i + 1] = Vector2.create(
                (self.points[i].x - center.x) * scaleX + center.x,
                (self.points[i].y - center.y) * scaleY + center.y
        )
    end

    return Polygon.create(newPoints)
end

---判断点是否在多边形内（射线法）
---@param point foundation.math.Vector2 要判断的点
---@return boolean 如果点在多边形内或边上则返回true，否则返回false
function Polygon:contains(point)
    return ShapeIntersector.polygonContainsPoint(self, point)
end

---检查与其他形状的相交
---@param other any
---@return boolean, foundation.math.Vector2[] | nil
function Polygon:intersects(other)
    return ShapeIntersector.intersect(self, other)
end

---仅检查是否与其他形状相交
---@param other any
---@return boolean
function Polygon:hasIntersection(other)
    return ShapeIntersector.hasIntersection(self, other)
end

---判断多边形是否包含另一个多边形
---@param other foundation.shape.Polygon 另一个多边形
---@return boolean 如果当前多边形完全包含另一个多边形则返回true，否则返回false
function Polygon:containsPolygon(other)
    for i = 0, other.size - 1 do
        if not self:contains(other.points[i]) then
            return false
        end
    end

    return true
end

---计算点到多边形的最近点
---@param point foundation.math.Vector2 要检查的点
---@param boundary boolean 是否限制在边界内，默认为false
---@return foundation.math.Vector2 多边形上最近的点
---@overload fun(self: foundation.shape.Polygon, point: foundation.math.Vector2): foundation.math.Vector2
function Polygon:closestPoint(point, boundary)
    if not boundary and self:contains(point) then
        return point:clone()
    end

    local edges = self:getEdges()
    local minDistance = math.huge
    local closestPoint

    for _, edge in ipairs(edges) do
        local edgeClosest = edge:closestPoint(point)
        local distance = (point - edgeClosest):length()

        if distance < minDistance then
            minDistance = distance
            closestPoint = edgeClosest
        end
    end

    return closestPoint
end

---计算点到多边形的距离
---@param point foundation.math.Vector2 要检查的点
---@return number 点到多边形的距离
function Polygon:distanceToPoint(point)
    if self:contains(point) then
        return 0
    end

    local closestPoint = self:closestPoint(point)
    return (point - closestPoint):length()
end

---将点投影到多边形上（2D中与closest相同）
---@param point foundation.math.Vector2 要投影的点
---@return foundation.math.Vector2 投影点
function Polygon:projectPoint(point)
    return self:closestPoint(point, true)
end

---检查点是否在多边形上
---@param point foundation.math.Vector2 要检查的点
---@param tolerance number|nil 容差，默认为1e-10
---@return boolean 点是否在多边形上
---@overload fun(self: foundation.shape.Polygon, point: foundation.math.Vector2): boolean
function Polygon:containsPoint(point, tolerance)
    tolerance = tolerance or 1e-10
    local dist = self:distanceToPoint(point)
    if dist > tolerance then
        return false
    end

    for i = 0, self.size - 1 do
        local edge = Segment.create(self.points[i], self.points[(i + 1) % self.size])
        if edge:containsPoint(point, tolerance) then
            return true
        end
    end

    return false
end

--region 三角剖分的辅助函数
---获取前一个点索引
---@param points table 点数组
---@param i number 当前索引
---@return number 前一个点的索引
local function getPrev(points, i)
    return i == 1 and #points or i - 1
end

---获取后一个点索引
---@param points table 点数组
---@param i number 当前索引
---@return number 后一个点的索引
local function getNext(points, i)
    return i == #points and 1 or i + 1
end

---检查点是否为凸点
---@param points table 点数组
---@param i number 当前索引
---@param isClockwise boolean 是否顺时针
---@return boolean 是否为凸点
local function isConvex(points, i, isClockwise)
    local prev = getPrev(points, i)
    local next = getNext(points, i)

    local v1 = points[prev].point - points[i].point
    local v2 = points[next].point - points[i].point

    local cross = v1:cross(v2)
    return (isClockwise and cross < 0) or (not isClockwise and cross > 0)
end

---检查点是否在三角形内部
---@param p foundation.math.Vector2 要检查的点
---@param a foundation.math.Vector2 三角形顶点1
---@param b foundation.math.Vector2 三角形顶点2
---@param c foundation.math.Vector2 三角形顶点3
---@param isClockwise boolean 是否顺时针
---@return boolean 点是否在三角形内部
local function isPointInTriangle(p, a, b, c, isClockwise)
    local ab = b - a
    local bc = c - b
    local ca = a - c

    local ap = p - a
    local bp = p - b
    local cp = p - c

    local cross1 = ab:cross(ap)
    local cross2 = bc:cross(bp)
    local cross3 = ca:cross(cp)

    if isClockwise then
        return cross1 >= 0 and cross2 >= 0 and cross3 >= 0
    else
        return cross1 <= 0 and cross2 <= 0 and cross3 <= 0
    end
end

---检查耳朵是否有效
---@param points table 点数组 
---@param i number 当前索引
---@param isClockwise boolean 是否顺时针
---@return boolean 是否为有效的耳朵
local function isEar(points, i, isClockwise)
    if not isConvex(points, i, isClockwise) then
        return false
    end

    local prev = getPrev(points, i)
    local next = getNext(points, i)

    local a = points[prev].point
    local b = points[i].point
    local c = points[next].point

    for j = 1, #points do
        if j ~= prev and j ~= i and j ~= next then
            if isPointInTriangle(points[j].point, a, b, c, isClockwise) then
                return false
            end
        end
    end

    return true
end
--endregion

---将多边形三角剖分（简单多边形的三角剖分，基于耳切法）
---@return foundation.shape.Triangle[] 三角形数组
function Polygon:triangulate()
    local points = {}
    for i = 0, self.size - 1 do
        points[i + 1] = { index = i, point = self.points[i]:clone() }
    end
    local area = 0
    for i = 0, self.size - 1 do
        local j = (i + 1) % self.size
        area = area + (points[i + 1].point.x * points[j + 1].point.y) - (points[j + 1].point.x * points[i + 1].point.y)
    end
    local isClockwise = area < 0
    local triangles = {}
    local remainingPoints = self.size

    local isConvexCache = {}
    local isEarCache = {}
    for i = 1, #points do
        isConvexCache[i] = isConvex(points, i, isClockwise)
        isEarCache[i] = isConvexCache[i] and isEar(points, i, isClockwise)
    end

    while remainingPoints > 3 do
        local foundEar = false
        for i = 1, #points do
            if points[i] and isEarCache[i] then
                local prev, next = getPrev(points, i), getNext(points, i)
                local a, b, c = points[prev].point, points[i].point, points[next].point
                triangles[#triangles + 1] = Triangle.create(a, b, c)
                points[i] = nil

                local newPoints = {}
                for j = 1, #points do
                    if points[j] then
                        newPoints[#newPoints + 1] = points[j]
                    end
                end
                points = newPoints
                remainingPoints = remainingPoints - 1

                if points[prev] then
                    isConvexCache[prev] = isConvex(points, prev, isClockwise)
                    isEarCache[prev] = isConvexCache[prev] and isEar(points, prev, isClockwise)
                end

                if points[next] then
                    isConvexCache[next] = isConvex(points, next, isClockwise)
                    isEarCache[next] = isConvexCache[next] and isEar(points, next, isClockwise)
                end

                foundEar = true
                break
            end
        end
        if not foundEar then
            break
        end
    end
    if #points == 3 then
        triangles[#triangles + 1] = Triangle.create(points[1].point, points[2].point, points[3].point)
    end
    return triangles
end

---复制当前多边形
---@return foundation.shape.Polygon 复制后的多边形
function Polygon:clone()
    local newPoints = {}
    for i = 0, self.size - 1 do
        newPoints[i + 1] = self.points[i]:clone()
    end
    return Polygon.create(newPoints)
end

ffi.metatype("foundation_shape_Polygon", Polygon)

return Polygon