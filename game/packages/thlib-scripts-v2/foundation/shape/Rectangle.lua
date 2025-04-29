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
    foundation_math_Vector2 center;
    double width;
    double height;
    foundation_math_Vector2 direction;
} foundation_shape_Rectangle;
]]

---@class foundation.shape.Rectangle
---@field center foundation.math.Vector2 矩形的中心点
---@field width number 矩形的宽度
---@field height number 矩形的高度
---@field direction foundation.math.Vector2 矩形的宽度轴方向（归一化向量）
local Rectangle = {}
Rectangle.__index = Rectangle
Rectangle.__type = "foundation.shape.Rectangle"

---创建一个新的矩形
---@param center foundation.math.Vector2 中心点
---@param width number 宽度
---@param height number 高度
---@param direction foundation.math.Vector2|nil 宽度轴方向（归一化向量），默认为(1,0)
---@return foundation.shape.Rectangle
function Rectangle.create(center, width, height, direction)
    local dist = direction and direction:length() or 0
    if dist == 0 then
        direction = Vector2.create(1, 0)
    elseif dist ~= 1 then
        direction = direction:normalized()
    else
        direction = direction:clone()
    end
    ---@diagnostic disable-next-line: return-type-mismatch
    return ffi.new("foundation_shape_Rectangle", center, width, height, direction)
end

---使用给定的弧度创建矩形
---@param center foundation.math.Vector2 中心点
---@param width number 宽度
---@param height number 高度
---@param rad number 旋转弧度
---@return foundation.shape.Rectangle
function Rectangle.createFromRad(center, width, height, rad)
    local direction = Vector2.createFromRad(rad, 1)
    return Rectangle.create(center, width, height, direction)
end

---使用给定的角度创建矩形
---@param center foundation.math.Vector2 中心点
---@param width number 宽度
---@param height number 高度
---@param angle number 旋转角度
---@return foundation.shape.Rectangle
function Rectangle.createFromAngle(center, width, height, angle)
    local direction = Vector2.createFromAngle(angle, 1)
    return Rectangle.create(center, width, height, direction)
end

---矩形相等比较
---@param a foundation.shape.Rectangle
---@param b foundation.shape.Rectangle
---@return boolean
function Rectangle.__eq(a, b)
    return a.center == b.center and
            math.abs(a.width - b.width) < 1e-10 and
            math.abs(a.height - b.height) < 1e-10 and
            a.direction == b.direction
end

---矩形的字符串表示
---@param self foundation.shape.Rectangle
---@return string
function Rectangle.__tostring(self)
    return string.format("Rectangle(center=%s, width=%f, height=%f, direction=%s)",
            tostring(self.center), self.width, self.height, tostring(self.direction))
end

---获取矩形的四个顶点
---@return foundation.math.Vector2[]
function Rectangle:getVertices()
    local hw, hh = self.width / 2, self.height / 2
    local dir = self.direction
    local perp = Vector2.create(-dir.y, dir.x) -- 垂直向量（高度方向）
    local vertices = {
        Vector2.create(-hw, -hh),
        Vector2.create(hw, -hh),
        Vector2.create(hw, hh),
        Vector2.create(-hw, hh)
    }
    for i, v in ipairs(vertices) do
        local x = v.x * dir.x + v.y * perp.x
        local y = v.x * dir.y + v.y * perp.y
        vertices[i] = self.center + Vector2.create(x, y)
    end
    return vertices
end

---获取矩形的四条边（线段）
---@return foundation.shape.Segment[]
function Rectangle:getEdges()
    local vertices = self:getVertices()
    return {
        Segment.create(vertices[1], vertices[2]),
        Segment.create(vertices[2], vertices[3]),
        Segment.create(vertices[3], vertices[4]),
        Segment.create(vertices[4], vertices[1])
    }
end

---平移矩形（更改当前矩形）
---@param v foundation.math.Vector2 | number 移动距离
---@return foundation.shape.Rectangle 自身引用
function Rectangle:move(v)
    local moveX, moveY
    if type(v) == "number" then
        moveX, moveY = v, v
    else
        moveX, moveY = v.x, v.y
    end
    self.center.x = self.center.x + moveX
    self.center.y = self.center.y + moveY
    return self
end

---获取平移后的矩形副本
---@param v foundation.math.Vector2 | number 移动距离
---@return foundation.shape.Rectangle
function Rectangle:moved(v)
    local moveX, moveY
    if type(v) == "number" then
        moveX, moveY = v, v
    else
        moveX, moveY = v.x, v.y
    end
    return Rectangle.create(
            Vector2.create(self.center.x + moveX, self.center.y + moveY),
            self.width, self.height, self.direction
    )
end

---旋转矩形（更改当前矩形）
---@param rad number 旋转弧度
---@return foundation.shape.Rectangle 自身引用
function Rectangle:rotate(rad)
    local cosA, sinA = math.cos(rad), math.sin(rad)
    local x = self.direction.x * cosA - self.direction.y * sinA
    local y = self.direction.x * sinA + self.direction.y * cosA
    self.direction = Vector2.create(x, y):normalized()
    return self
end

---获取旋转后的矩形副本
---@param rad number 旋转弧度
---@return foundation.shape.Rectangle
function Rectangle:rotated(rad)
    local cosA, sinA = math.cos(rad), math.sin(rad)
    local x = self.direction.x * cosA - self.direction.y * sinA
    local y = self.direction.x * sinA + self.direction.y * cosA
    return Rectangle.create(self.center, self.width, self.height, Vector2.create(x, y):normalized())
end

---缩放矩形（更改当前矩形）
---@param scale number|foundation.math.Vector2 缩放倍数
---@return foundation.shape.Rectangle 自身引用
function Rectangle:scale(scale)
    local scaleX, scaleY
    if type(scale) == "number" then
        scaleX, scaleY = scale, scale
    else
        scaleX, scaleY = scale.x, scale.y
    end
    self.width = self.width * scaleX
    self.height = self.height * scaleY
    return self
end

---获取缩放后的矩形副本
---@param scale number|foundation.math.Vector2 缩放倍数
---@return foundation.shape.Rectangle
function Rectangle:scaled(scale)
    local scaleX, scaleY
    if type(scale) == "number" then
        scaleX, scaleY = scale, scale
    else
        scaleX, scaleY = scale.x, scale.y
    end
    return Rectangle.create(self.center, self.width * scaleX, self.height * scaleY, self.direction)
end

---检查点是否在矩形内（包括边界）
---@param point foundation.math.Vector2
---@return boolean
function Rectangle:contains(point)
    local p = point - self.center
    local dir = self.direction
    local perp = Vector2.create(-dir.y, dir.x)
    local x = p.x * dir.x + p.y * dir.y
    local y = p.x * perp.x + p.y * perp.y
    local hw, hh = self.width / 2, self.height / 2
    return math.abs(x) <= hw and math.abs(y) <= hh
end

---检查与其他形状的相交
---@param other any
---@return boolean, foundation.math.Vector2[] | nil
function Rectangle:intersects(other)
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

---仅检查是否与其他形状相交
---@param other any
---@return boolean
function Rectangle:hasIntersection(other)
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

---检查与线段的相交
---@param other foundation.shape.Segment
---@return boolean, foundation.math.Vector2[] | nil
function Rectangle:__intersectToSegment(other)
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

---仅检查是否与线段相交
---@param other foundation.shape.Segment
---@return boolean
function Rectangle:__hasIntersectionWithSegment(other)
    local edges = self:getEdges()
    for _, edge in ipairs(edges) do
        if edge:hasIntersection(other) then
            return true
        end
    end
    return self:contains(other.point1) or self:contains(other.point2)
end

---检查与三角形的相交
---@param other foundation.shape.Triangle
---@return boolean, foundation.math.Vector2[] | nil
function Rectangle:__intersectToTriangle(other)
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
    if self:contains(other.point2) then
        points[#points + 1] = other.point2:clone()
    end
    if self:contains(other.point3) then
        points[#points + 1] = other.point3:clone()
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

---仅检查是否与三角形相交
---@param other foundation.shape.Triangle
---@return boolean
function Rectangle:__hasIntersectionWithTriangle(other)
    local edges = self:getEdges()
    for _, edge in ipairs(edges) do
        if edge:hasIntersection(other) then
            return true
        end
    end
    return self:contains(other.point1) or self:contains(other.point2) or self:contains(other.point3)
end

---检查与直线的相交
---@param other foundation.shape.Line
---@return boolean, foundation.math.Vector2[] | nil
function Rectangle:__intersectToLine(other)
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

---仅检查是否与直线相交
---@param other foundation.shape.Line
---@return boolean
function Rectangle:__hasIntersectionWithLine(other)
    local edges = self:getEdges()
    for _, edge in ipairs(edges) do
        if edge:hasIntersection(other) then
            return true
        end
    end
    return false
end

---检查与射线的相交
---@param other foundation.shape.Ray
---@return boolean, foundation.math.Vector2[] | nil
function Rectangle:__intersectToRay(other)
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
        points[#points + 1] = other.point
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

---仅检查是否与射线相交
---@param other foundation.shape.Ray
---@return boolean
function Rectangle:__hasIntersectionWithRay(other)
    local edges = self:getEdges()
    for _, edge in ipairs(edges) do
        if edge:hasIntersection(other) then
            return true
        end
    end
    return self:contains(other.point)
end

---检查与圆的相交
---@param other foundation.shape.Circle
---@return boolean, foundation.math.Vector2[] | nil
function Rectangle:__intersectToCircle(other)
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

---仅检查是否与圆相交
---@param other foundation.shape.Circle
---@return boolean
function Rectangle:__hasIntersectionWithCircle(other)
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

---检查与另一个矩形的相交
---@param other foundation.shape.Rectangle
---@return boolean, foundation.math.Vector2[] | nil
function Rectangle:__intersectToRectangle(other)
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
    local vertices1 = self:getVertices()
    for _, vertex in ipairs(vertices1) do
        if other:contains(vertex) then
            points[#points + 1] = vertex:clone()
        end
    end
    local vertices2 = other:getVertices()
    for _, vertex in ipairs(vertices2) do
        if self:contains(vertex) then
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

---仅检查是否与另一个矩形相交
---@param other foundation.shape.Rectangle
---@return boolean
function Rectangle:__hasIntersectionWithRectangle(other)
    local edges1 = self:getEdges()
    local edges2 = other:getEdges()
    for _, edge1 in ipairs(edges1) do
        for _, edge2 in ipairs(edges2) do
            if edge1:hasIntersection(edge2) then
                return true
            end
        end
    end
    local vertices1 = self:getVertices()
    for _, vertex in ipairs(vertices1) do
        if other:contains(vertex) then
            return true
        end
    end
    local vertices2 = other:getVertices()
    for _, vertex in ipairs(vertices2) do
        if self:contains(vertex) then
            return true
        end
    end
    return false
end

---计算点到矩形的最近点
---@param point foundation.math.Vector2
---@return foundation.math.Vector2
function Rectangle:closestPoint(point)
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

---计算点到矩形的距离
---@param point foundation.math.Vector2
---@return number
function Rectangle:distanceToPoint(point)
    if self:contains(point) then
        return 0
    end
    local edges = self:getEdges()
    local minDistance = math.huge
    for _, edge in ipairs(edges) do
        local distance = edge:distanceToPoint(point)
        if distance < minDistance then
            minDistance = distance
        end
    end
    return minDistance
end

---将点投影到矩形上
---@param point foundation.math.Vector2
---@return foundation.math.Vector2
function Rectangle:projectPoint(point)
    return self:closestPoint(point)
end

---检查点是否在矩形边界上
---@param point foundation.math.Vector2
---@param tolerance number|nil 默认为1e-10
---@return boolean
function Rectangle:containsPoint(point, tolerance)
    tolerance = tolerance or 1e-10
    local edges = self:getEdges()
    for _, edge in ipairs(edges) do
        if edge:containsPoint(point, tolerance) then
            return true
        end
    end
    return false
end

ffi.metatype("foundation_shape_Rectangle", Rectangle)

return Rectangle