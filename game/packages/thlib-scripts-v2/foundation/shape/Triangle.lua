local ffi = require("ffi")

local type = type
local ipairs = ipairs
local tostring = tostring
local string = string
local math = math

local Vector2 = require("foundation.math.Vector2")
local Segment = require("foundation.shape.Segment")

ffi.cdef [[
typedef struct {
    foundation_math_Vector2 point1, point2, point3;
} foundation_shape_Triangle;
]]

---@class foundation.shape.Triangle
---@field point1 foundation.math.Vector2 三角形的第一个顶点
---@field point2 foundation.math.Vector2 三角形的第二个顶点
---@field point3 foundation.math.Vector2 三角形的第三个顶点
local Triangle = {}
Triangle.__index = Triangle
Triangle.__type = "foundation.shape.Triangle"

---创建一个新的三角形
---@param v1 foundation.math.Vector2 三角形的第一个顶点
---@param v2 foundation.math.Vector2 三角形的第二个顶点
---@param v3 foundation.math.Vector2 三角形的第三个顶点
---@return foundation.shape.Triangle 新创建的三角形
function Triangle.create(v1, v2, v3)
    ---@diagnostic disable-next-line: return-type-mismatch
    return ffi.new("foundation_shape_Triangle", v1, v2, v3)
end

---三角形相等比较
---@param a foundation.shape.Triangle 第一个三角形
---@param b foundation.shape.Triangle 第二个三角形
---@return boolean 如果两个三角形的所有顶点都相等则返回true，否则返回false
function Triangle.__eq(a, b)
    return a.point1 == b.point1 and a.point2 == b.point2 and a.point3 == b.point3
end

---三角形转字符串表示
---@param t foundation.shape.Triangle 要转换的三角形
---@return string 三角形的字符串表示
function Triangle.__tostring(t)
    return string.format("Triangle(%s, %s, %s)", tostring(t.point1), tostring(t.point2), tostring(t.point3))
end

---计算三角形的面积
---@return number 三角形的面积
function Triangle:area()
    local v2v1 = self.point2 - self.point1
    local v3v1 = self.point3 - self.point1
    return 0.5 * math.abs(v2v1:cross(v3v1))
end

---计算三角形的重心
---@return foundation.math.Vector2 三角形的重心
function Triangle:centroid()
    return (self.point1 + self.point2 + self.point3) / 3
end

---计算三角形的外接圆半径
---@return number 三角形的外接圆半径
function Triangle:circumradius()
    local center = self:circumcenter()
    if center then
        return (center - self.point1):length()
    end
    return 0
end

---计算三角形的内切圆半径
---@return number 三角形的内切圆半径
function Triangle:inradius()
    local a = (self.point2 - self.point3):length()
    local b = (self.point1 - self.point3):length()
    local c = (self.point1 - self.point2):length()
    return self:area() / ((a + b + c) / 2)
end

---计算三角形的外心
---@return foundation.math.Vector2 | nil 三角形的外心
function Triangle:circumcenter()
    local x1, y1 = self.point1.x, self.point1.y
    local x2, y2 = self.point2.x, self.point2.y
    local x3, y3 = self.point3.x, self.point3.y

    local D = x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2)
    if math.abs(D) < 1e-10 then
        return nil
    end

    local x0_num = (x1 * x1 + y1 * y1) * (y2 - y3) + (x2 * x2 + y2 * y2) * (y3 - y1) + (x3 * x3 + y3 * y3) * (y1 - y2)
    local x0 = x0_num / (2 * D)

    local y0_num = (x1 * x1 + y1 * y1) * (x3 - x2) + (x2 * x2 + y2 * y2) * (x1 - x3) + (x3 * x3 + y3 * y3) * (x2 - x1)
    local y0 = y0_num / (2 * D)

    return Vector2.create(x0, y0)
end

---计算三角形的内心
---@return foundation.math.Vector2 三角形的内心
function Triangle:incenter()
    local a = (self.point2 - self.point3):length()
    local b = (self.point1 - self.point3):length()
    local c = (self.point1 - self.point2):length()

    local p = (a * self.point1 + b * self.point2 + c * self.point3) / (a + b + c)
    return p
end

---将当前三角形平移指定距离（更改当前三角形）
---@param v foundation.math.Vector2 | number 移动距离
---@return foundation.shape.Triangle 移动后的三角形（自身引用）
function Triangle:move(v)
    local moveX, moveY
    if type(v) == "number" then
        moveX, moveY = v, v
    else
        moveX, moveY = v.x, v.y
    end
    self.point1.x = self.point1.x + moveX
    self.point1.y = self.point1.y + moveY
    self.point2.x = self.point2.x + moveX
    self.point2.y = self.point2.y + moveY
    self.point3.x = self.point3.x + moveX
    self.point3.y = self.point3.y + moveY
    return self
end

---获取三角形平移指定距离的副本
---@param v foundation.math.Vector2 | number 移动距离
---@return foundation.shape.Triangle 移动后的三角形副本
function Triangle:moved(v)
    local moveX, moveY
    if type(v) == "number" then
        moveX, moveY = v, v
    else
        moveX, moveY = v.x, v.y
    end
    return Triangle.create(
            Vector2.create(self.point1.x + moveX, self.point1.y + moveY),
            Vector2.create(self.point2.x + moveX, self.point2.y + moveY),
            Vector2.create(self.point3.x + moveX, self.point3.y + moveY)
    )
end

---将当前三角形旋转指定弧度（更改当前三角形）
---@param rad number 旋转弧度
---@param center foundation.math.Vector2 旋转中心
---@return foundation.shape.Triangle 旋转后的三角形（自身引用）
---@overload fun(self: foundation.shape.Triangle, rad: number): foundation.shape.Triangle 绕三角形重心旋转指定弧度
function Triangle:rotate(rad, center)
    center = center or self:centroid()
    local cosAngle = math.cos(rad)
    local sinAngle = math.sin(rad)
    local v1 = self.point1 - center
    local v2 = self.point2 - center
    local v3 = self.point3 - center
    self.point1.x = v1.x * cosAngle - v1.y * sinAngle + center.x
    self.point1.y = v1.x * sinAngle + v1.y * cosAngle + center.y
    self.point2.x = v2.x * cosAngle - v2.y * sinAngle + center.x
    self.point2.y = v2.x * sinAngle + v2.y * cosAngle + center.y
    self.point3.x = v3.x * cosAngle - v3.y * sinAngle + center.x
    self.point3.y = v3.x * sinAngle + v3.y * cosAngle + center.y
    return self
end

---将当前三角形旋转指定角度（更改当前三角形）
---@param angle number 旋转角度
---@param center foundation.math.Vector2 旋转中心
---@return foundation.shape.Triangle 旋转后的三角形（自身引用）
---@overload fun(self: foundation.shape.Triangle, angle: number): foundation.shape.Triangle 绕三角形重心旋转指定角度
function Triangle:degreeRotate(angle, center)
    angle = math.rad(angle)
    return self:rotate(angle, center)
end

---获取三角形的旋转指定弧度的副本
---@param rad number 旋转弧度
---@param center foundation.math.Vector2 旋转中心
---@return foundation.shape.Triangle 旋转后的三角形副本
---@overload fun(self: foundation.shape.Triangle, rad: number): foundation.shape.Triangle 绕三角形重心旋转指定弧度
function Triangle:rotated(rad, center)
    center = center or self:centroid()
    local cosAngle = math.cos(rad)
    local sinAngle = math.sin(rad)
    local v1 = self.point1 - center
    local v2 = self.point2 - center
    local v3 = self.point3 - center
    return Triangle.create(
            Vector2.create(v1.x * cosAngle - v1.y * sinAngle + center.x, v1.x * sinAngle + v1.y * cosAngle + center.y),
            Vector2.create(v2.x * cosAngle - v2.y * sinAngle + center.x, v2.x * sinAngle + v2.y * cosAngle + center.y),
            Vector2.create(v3.x * cosAngle - v3.y * sinAngle + center.x, v3.x * sinAngle + v3.y * cosAngle + center.y)
    )
end

---获取三角形的旋转指定角度的副本
---@param angle number 旋转角度
---@param center foundation.math.Vector2 旋转中心
---@return foundation.shape.Triangle 旋转后的三角形副本
---@overload fun(self: foundation.shape.Triangle, angle: number): foundation.shape.Triangle 绕三角形重心旋转指定角度
function Triangle:degreeRotated(angle, center)
    angle = math.rad(angle)
    return self:rotated(angle, center)
end

---将当前三角形缩放指定倍数（更改当前三角形）
---@param scale number|foundation.math.Vector2 缩放倍数
---@param center foundation.math.Vector2 缩放中心
---@return foundation.shape.Triangle 缩放后的三角形（自身引用）
---@overload fun(self: foundation.shape.Triangle, scale: number): foundation.shape.Triangle 相对三角形重心缩放指定倍数
function Triangle:scale(scale, center)
    local scaleX, scaleY
    if type(scale) == "number" then
        scaleX, scaleY = scale, scale
    else
        scaleX, scaleY = scale.x, scale.y
    end
    center = center or self:centroid()
    self.point1.x = (self.point1.x - center.x) * scaleX + center.x
    self.point1.y = (self.point1.y - center.y) * scaleY + center.y
    self.point2.x = (self.point2.x - center.x) * scaleX + center.x
    self.point2.y = (self.point2.y - center.y) * scaleY + center.y
    self.point3.x = (self.point3.x - center.x) * scaleX + center.x
    self.point3.y = (self.point3.y - center.y) * scaleY + center.y
    return self
end

---获取三角形的缩放指定倍数的副本
---@param scale number|foundation.math.Vector2 缩放倍数
---@param center foundation.math.Vector2 缩放中心
---@return foundation.shape.Triangle 缩放后的三角形副本
---@overload fun(self: foundation.shape.Triangle, scale: number): foundation.shape.Triangle 相对三角形重心缩放指定倍数
function Triangle:scaled(scale, center)
    local scaleX, scaleY
    if type(scale) == "number" then
        scaleX, scaleY = scale, scale
    else
        scaleX, scaleY = scale.x, scale.y
    end
    center = center or self:centroid()
    return Triangle.create(
            Vector2.create((self.point1.x - center.x) * scaleX + center.x, (self.point1.y - center.y) * scaleY + center.y),
            Vector2.create((self.point2.x - center.x) * scaleX + center.x, (self.point2.y - center.y) * scaleY + center.y),
            Vector2.create((self.point3.x - center.x) * scaleX + center.x, (self.point3.y - center.y) * scaleY + center.y)
    )
end

---判断点是否在三角形内（包括边界）
---@param point foundation.math.Vector2 要检查的点
---@return boolean 如果点在三角形内（包括边界）返回true，否则返回false
function Triangle:contains(point)
    local v3v1 = self.point3 - self.point1
    local v2v1 = self.point2 - self.point1
    local pv1 = point - self.point1

    local dot00 = v3v1:dot(v3v1)
    local dot01 = v3v1:dot(v2v1)
    local dot02 = v3v1:dot(pv1)
    local dot11 = v2v1:dot(v2v1)
    local dot12 = v2v1:dot(pv1)

    local invDenom = 1 / (dot00 * dot11 - dot01 * dot01)
    local u = (dot11 * dot02 - dot01 * dot12) * invDenom
    local v = (dot00 * dot12 - dot01 * dot02) * invDenom

    return (u >= 0) and (v >= 0) and (u + v <= 1)
end

---检查三角形是否与其他形状相交
---@param other any 其他的形状
---@return boolean, foundation.math.Vector2[] | nil
function Triangle:intersects(other)
    if other.__type == "foundation.shape.Segment" then
        return self:__intersectToSegment(other)
    elseif other.__type == "foundation.shape.Triangle" then
        return self:__intersectToTriangle(other)
    elseif other.__type == "foundation.shape.Line" then
        return self:__intersectToLine(other)
    elseif other.__type == "foundation.shape.Ray" then
        return self:__intersectToRay(other)
    elseif other.__type == "foundation.shape.Circle" then
        return self:__intersectToCircle(other)
    elseif other.__type == "foundation.shape.Rectangle" then
        return self:__intersectToRectangle(other)
    end
    return false, nil
end

---仅检查三角形是否与其他形状相交，不返回相交点
---@param other any 其他的形状
---@return boolean
function Triangle:hasIntersection(other)
    if other.__type == "foundation.shape.Segment" then
        return self:__hasIntersectionWithSegment(other)
    elseif other.__type == "foundation.shape.Triangle" then
        return self:__hasIntersectionWithTriangle(other)
    elseif other.__type == "foundation.shape.Line" then
        return self:__hasIntersectionWithLine(other)
    elseif other.__type == "foundation.shape.Ray" then
        return self:__hasIntersectionWithRay(other)
    elseif other.__type == "foundation.shape.Circle" then
        return self:__hasIntersectionWithCircle(other)
    elseif other.__type == "foundation.shape.Rectangle" then
        return self:__hasIntersectionWithRectangle(other)
    end
    return false
end

---获取三角形的顶点
---@return foundation.math.Vector2[]
function Triangle:getVertices()
    return {
        self.point1:clone(),
        self.point2:clone(),
        self.point3:clone()
    }
end

---获取三角形的边（线段）
---@return foundation.shape.Segment[]
function Triangle:getEdges()
    return {
        Segment.create(self.point1, self.point2),
        Segment.create(self.point2, self.point3),
        Segment.create(self.point3, self.point1)
    }
end

---检查三角形是否与线段相交
---@param other foundation.shape.Segment 要检查的线段
---@return boolean, foundation.math.Vector2[] | nil
function Triangle:__intersectToSegment(other)
    local points = {}
    local edges = self:getEdges()
    for _, edge in ipairs(edges) do
        local success, edge_points = edge:intersects(other)
        if success then
            for _, p in ipairs(edge_points) do
                points[#points + 1] = p
            end
        end
    end
    if self:contains(other.point1) then
        points[#points + 1] = other.point1:clone()
    end
    if other.point1 ~= other.point2 and self:contains(other.point2) then
        points[#points + 1] = other.point2:clone()
    end
    local unique_points = {}
    local seen = {}
    for _, p in ipairs(points) do
        local key = tostring(p.x) .. "," .. tostring(p.y)
        if not seen[key] then
            seen[key] = true
            unique_points[#unique_points + 1] = p
        end
    end

    if #unique_points == 0 then
        return false, nil
    end
    return true, unique_points
end

---检查三角形是否与另一个三角形相交
---@param other foundation.shape.Triangle 要检查的三角形
---@return boolean, foundation.math.Vector2[] | nil
function Triangle:__intersectToTriangle(other)
    local points = {}
    local edges1 = self:getEdges()
    local edges2 = other:getEdges()
    
    for _, edge1 in ipairs(edges1) do
        for _, edge2 in ipairs(edges2) do
            local success, edge_points = edge1:intersects(edge2)
            if success then
                for _, p in ipairs(edge_points) do
                    points[#points + 1] = p
                end
            end
        end
    end
    
    local vertices = other:getVertices()
    for _, vertex in ipairs(vertices) do
        if self:contains(vertex) then
            points[#points + 1] = vertex:clone()
        end
    end
    
    vertices = self:getVertices()
    for _, vertex in ipairs(vertices) do
        if other:contains(vertex) then
            points[#points + 1] = vertex:clone()
        end
    end
    
    local unique_points = {}
    local seen = {}
    for _, p in ipairs(points) do
        local key = tostring(p.x) .. "," .. tostring(p.y)
        if not seen[key] then
            seen[key] = true
            unique_points[#unique_points + 1] = p
        end
    end

    if #unique_points == 0 then
        return false, nil
    end
    return true, unique_points
end

---检查三角形是否与直线相交
---@param other foundation.shape.Line 要检查的直线
---@return boolean, foundation.math.Vector2[] | nil
function Triangle:__intersectToLine(other)
    local points = {}
    local edges = self:getEdges()
    for _, edge in ipairs(edges) do
        local success, edge_points = edge:intersects(other)
        if success then
            for _, p in ipairs(edge_points) do
                points[#points + 1] = p
            end
        end
    end
    local unique_points = {}
    local seen = {}
    for _, p in ipairs(points) do
        local key = tostring(p.x) .. "," .. tostring(p.y)
        if not seen[key] then
            seen[key] = true
            unique_points[#unique_points + 1] = p
        end
    end

    if #unique_points == 0 then
        return false, nil
    end
    return true, unique_points
end

---检查三角形是否与射线相交
---@param other foundation.shape.Ray 要检查的射线
---@return boolean, foundation.math.Vector2[] | nil
function Triangle:__intersectToRay(other)
    local points = {}
    local edges = self:getEdges()
    for _, edge in ipairs(edges) do
        local success, edge_points = edge:intersects(other)
        if success then
            for _, p in ipairs(edge_points) do
                points[#points + 1] = p
            end
        end
    end
    if self:contains(other.point) then
        points[#points + 1] = other.point:clone()
    end
    local unique_points = {}
    local seen = {}
    for _, p in ipairs(points) do
        local key = tostring(p.x) .. "," .. tostring(p.y)
        if not seen[key] then
            seen[key] = true
            unique_points[#unique_points + 1] = p
        end
    end

    if #unique_points == 0 then
        return false, nil
    end
    return true, unique_points
end

---检查三角形是否与圆相交
---@param other foundation.shape.Circle 要检查的圆
---@return boolean, foundation.math.Vector2[] | nil
function Triangle:__intersectToCircle(other)
    local points = {}
    local edges = self:getEdges()
    for _, edge in ipairs(edges) do
        local success, edge_points = edge:intersects(other)
        if success then
            for _, p in ipairs(edge_points) do
                points[#points + 1] = p
            end
        end
    end
    
    local vertices = self:getVertices()
    for _, vertex in ipairs(vertices) do
        if other:contains(vertex) then
            points[#points + 1] = vertex:clone()
        end
    end
    
    if self:contains(other.center) then
        points[#points + 1] = other.center:clone()
    end
    
    local unique_points = {}
    local seen = {}
    for _, p in ipairs(points) do
        local key = tostring(p.x) .. "," .. tostring(p.y)
        if not seen[key] then
            seen[key] = true
            unique_points[#unique_points + 1] = p
        end
    end

    if #unique_points == 0 then
        return false, nil
    end
    return true, unique_points
end

---仅检查三角形是否与线段相交
---@param other foundation.shape.Segment 要检查的线段
---@return boolean
function Triangle:__hasIntersectionWithSegment(other)
    local edges = self:getEdges()

    for _, edge in ipairs(edges) do
        if edge:hasIntersection(other) then
            return true
        end
    end

    if self:contains(other.point1) or self:contains(other.point2) then
        return true
    end

    return false
end

---仅检查三角形是否与另一个三角形相交
---@param other foundation.shape.Triangle 要检查的三角形
---@return boolean
function Triangle:__hasIntersectionWithTriangle(other)
    local edges1 = self:getEdges()
    local edges2 = other:getEdges()

    for _, edge1 in ipairs(edges1) do
        for _, edge2 in ipairs(edges2) do
            if edge1:hasIntersection(edge2) then
                return true
            end
        end
    end

    local vertices = other:getVertices()
    for _, vertex in ipairs(vertices) do
        if self:contains(vertex) then
            return true
        end
    end

    vertices = self:getVertices()
    for _, vertex in ipairs(vertices) do
        if other:contains(vertex) then
            return true
        end
    end

    return false
end

---仅检查三角形是否与直线相交
---@param other foundation.shape.Line 要检查的直线
---@return boolean
function Triangle:__hasIntersectionWithLine(other)
    local edges = self:getEdges()

    for _, edge in ipairs(edges) do
        if edge:hasIntersection(other) then
            return true
        end
    end

    return false
end

---仅检查三角形是否与射线相交
---@param other foundation.shape.Ray 要检查的射线
---@return boolean
function Triangle:__hasIntersectionWithRay(other)
    local edges = self:getEdges()

    for _, edge in ipairs(edges) do
        if edge:hasIntersection(other) then
            return true
        end
    end

    if self:contains(other.point) then
        return true
    end

    return false
end

---仅检查三角形是否与圆相交
---@param other foundation.shape.Circle 要检查的圆
---@return boolean
function Triangle:__hasIntersectionWithCircle(other)
    if self:contains(other.center) then
        return true
    end

    local edges = self:getEdges()
    for _, edge in ipairs(edges) do
        if edge:hasIntersection(other) then
            return true
        end
    end

    local vertices = self:getVertices()
    for _, vertex in ipairs(vertices) do
        if other:contains(vertex) then
            return true
        end
    end

    return false
end

---检查与矩形的相交
---@param other foundation.shape.Rectangle
---@return boolean, foundation.math.Vector2[] | nil
function Triangle:__intersectToRectangle(other)
    return other:__intersectToTriangle(self)
end

---仅检查是否与矩形相交
---@param other foundation.shape.Rectangle
---@return boolean
function Triangle:__hasIntersectionWithRectangle(other)
    return other:__hasIntersectionWithTriangle(self)
end

---计算点到三角形的最近点
---@param point foundation.math.Vector2 要检查的点
---@return foundation.math.Vector2 三角形上最近的点
function Triangle:closestPoint(point)
    if self:contains(point) then
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

---计算点到三角形的距离
---@param point foundation.math.Vector2 要检查的点
---@return number 点到三角形的距离
function Triangle:distanceToPoint(point)
    if self:contains(point) then
        return 0
    end

    local edges = {
        Segment.create(self.point1, self.point2),
        Segment.create(self.point2, self.point3),
        Segment.create(self.point3, self.point1)
    }

    local minDistance = math.huge

    for i = 1, #edges do
        local distance = edges[i]:distanceToPoint(point)
        if distance < minDistance then
            minDistance = distance
        end
    end

    return minDistance
end

---将点投影到三角形平面上（2D中与closest相同）
---@param point foundation.math.Vector2 要投影的点
---@return foundation.math.Vector2 投影点
function Triangle:projectPoint(point)
    return self:closestPoint(point)
end

---检查点是否在三角形上
---@param point foundation.math.Vector2 要检查的点
---@param tolerance number|nil 容差，默认为1e-10
---@return boolean 点是否在三角形上
---@overload fun(self:foundation.shape.Triangle, point:foundation.math.Vector2): boolean
function Triangle:containsPoint(point, tolerance)
    tolerance = tolerance or 1e-10
    local edges = self:getEdges()
    for _, edge in ipairs(edges) do
        if edge:containsPoint(point, tolerance) then
            return true
        end
    end
    return false
end

ffi.metatype("foundation_shape_Triangle", Triangle)

return Triangle
