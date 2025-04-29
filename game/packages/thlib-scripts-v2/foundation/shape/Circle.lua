local ffi = require("ffi")

local math = math
local type = type
local ipairs = ipairs
local tostring = tostring
local string = string

local Vector2 = require("foundation.math.Vector2")
local Segment = require("foundation.shape.Segment")

ffi.cdef [[
typedef struct {
    foundation_math_Vector2 center;
    double radius;
} foundation_shape_Circle;
]]

---@class foundation.shape.Circle
---@field center foundation.math.Vector2 圆心位置
---@field radius number 圆的半径
local Circle = {}
Circle.__index = Circle
Circle.__type = "foundation.shape.Circle"

---创建一个新的圆
---@param center foundation.math.Vector2 圆心位置
---@param radius number 半径
---@return foundation.shape.Circle
function Circle.create(center, radius)
    ---@diagnostic disable-next-line: return-type-mismatch
    return ffi.new("foundation_shape_Circle", center, radius)
end

---圆相等比较
---@param a foundation.shape.Circle
---@param b foundation.shape.Circle
---@return boolean
function Circle.__eq(a, b)
    return a.center == b.center and math.abs(a.radius - b.radius) < 1e-10
end

---圆的字符串表示
---@param self foundation.shape.Circle
---@return string
function Circle.__tostring(self)
    return string.format("Circle(center=%s, radius=%f)", tostring(self.center), self.radius)
end

---检查点是否在圆内或圆上
---@param point foundation.math.Vector2
---@return boolean
function Circle:contains(point)
    return (point - self.center):length() <= self.radius
end

---移动圆（修改当前圆）
---@param v foundation.math.Vector2 | number
---@return foundation.shape.Circle 自身引用
function Circle:move(v)
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

---获取移动后的圆副本
---@param v foundation.math.Vector2 | number
---@return foundation.shape.Circle
function Circle:moved(v)
    local moveX, moveY
    if type(v) == "number" then
        moveX, moveY = v, v
    else
        moveX, moveY = v.x, v.y
    end
    return Circle.create(Vector2.create(self.center.x + moveX, self.center.y + moveY), self.radius)
end

---缩放圆（修改当前圆）
---@param scale number 缩放比例
---@return foundation.shape.Circle 自身引用
function Circle:scale(scale)
    self.radius = self.radius * scale
    return self
end

---获取缩放后的圆副本
---@param scale number 缩放比例
---@return foundation.shape.Circle
function Circle:scaled(scale)
    return Circle.create(self.center, self.radius * scale)
end

---检查与其他形状的相交
---@param other any
---@return boolean, foundation.math.Vector2[] | nil
function Circle:intersects(other)
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
    end
    return false, nil
end

---只检查是否与其他形状相交，不计算交点
---@param other any
---@return boolean
function Circle:hasIntersection(other)
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
    end
    return false
end

---检查与线段的相交
---@param other foundation.shape.Segment
---@return boolean, foundation.math.Vector2[] | nil
function Circle:__intersectToSegment(other)
    local closest = other:closestPoint(self.center)
    local points = {}
    if (closest - self.center):length() <= self.radius then
        local dir = other.point2 - other.point1
        local len = dir:length()
        if len == 0 then
            if (other.point1 - self.center):length() <= self.radius then
                points[#points + 1] = other.point1:clone()
            end

            if #points == 0 then
                return false, nil
            end
            return true, points
        end
        dir = dir / len
        local L = other.point1 - self.center
        local a = dir:dot(dir)
        local b = 2 * L:dot(dir)
        local c = L:dot(L) - self.radius * self.radius
        local discriminant = b * b - 4 * a * c
        if discriminant >= 0 then
            local sqrt_d = math.sqrt(discriminant)
            local t1 = (-b - sqrt_d) / (2 * a)
            local t2 = (-b + sqrt_d) / (2 * a)
            if t1 >= 0 and t1 <= len then
                points[#points + 1] = other.point1 + dir * t1
            end
            if t2 >= 0 and t2 <= len and math.abs(t2 - t1) > 1e-10 then
                points[#points + 1] = other.point1 + dir * t2
            end
        end
    end

    if #points == 0 then
        return false, nil
    end
    return true, points
end

---检查是否与线段相交
---@param other foundation.shape.Segment
---@return boolean
function Circle:__hasIntersectionWithSegment(other)
    local closest = other:closestPoint(self.center)
    return (closest - self.center):length() <= self.radius
end

---检查与三角形的相交
---@param other foundation.shape.Triangle
---@return boolean, foundation.math.Vector2[] | nil
function Circle:__intersectToTriangle(other)
    local points = {}
    local edges = {
        Segment.create(other.point1, other.point2),
        Segment.create(other.point2, other.point3),
        Segment.create(other.point3, other.point1)
    }
    for i = 1, #edges do
        local success, edge_points = self:__intersectToSegment(edges[i])
        if success then
            for _, p in ipairs(edge_points) do
                points[#points + 1] = p
            end
        end
    end
    if other:contains(self.center) then
        points[#points + 1] = self.center:clone()
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

---检查是否与三角形相交
---@param other foundation.shape.Triangle
---@return boolean
function Circle:__hasIntersectionWithTriangle(other)
    local edges = {
        Segment.create(other.point1, other.point2),
        Segment.create(other.point2, other.point3),
        Segment.create(other.point3, other.point1)
    }
    for i = 1, #edges do
        if self:__hasIntersectionWithSegment(edges[i]) then
            return true
        end
    end

    if other:contains(self.center) then
        return true
    end

    return self:contains(other.point1) or
            self:contains(other.point2) or
            self:contains(other.point3)
end

---检查与直线的相交
---@param other foundation.shape.Line
---@return boolean, foundation.math.Vector2[] | nil
function Circle:__intersectToLine(other)
    local points = {}
    local dir = other.direction
    local len = dir:length()
    if len == 0 then
        return false, nil
    end
    dir = dir / len
    local L = other.point - self.center
    local a = dir:dot(dir)
    local b = 2 * L:dot(dir)
    local c = L:dot(L) - self.radius * self.radius
    local discriminant = b * b - 4 * a * c
    if discriminant >= 0 then
        local sqrt_d = math.sqrt(discriminant)
        local t1 = (-b - sqrt_d) / (2 * a)
        local t2 = (-b + sqrt_d) / (2 * a)
        points[#points + 1] = other.point + dir * t1
        if math.abs(t2 - t1) > 1e-10 then
            points[#points + 1] = other.point + dir * t2
        end
    end

    if #points == 0 then
        return false, nil
    end
    return true, points
end

---检查是否与直线相交
---@param other foundation.shape.Line
---@return boolean
function Circle:__hasIntersectionWithLine(other)
    local dir = other.direction
    local len = dir:length()
    if len == 0 then
        return false
    end
    dir = dir / len
    local L = other.point - self.center
    local a = dir:dot(dir)
    local b = 2 * L:dot(dir)
    local c = L:dot(L) - self.radius * self.radius
    local discriminant = b * b - 4 * a * c
    return discriminant >= 0
end

---检查与射线的相交
---@param other foundation.shape.Ray
---@return boolean, foundation.math.Vector2[] | nil
function Circle:__intersectToRay(other)
    local points = {}
    local dir = other.direction
    local len = dir:length()
    if len == 0 then
        return false, nil
    end
    dir = dir / len
    local L = other.point - self.center
    local a = dir:dot(dir)
    local b = 2 * L:dot(dir)
    local c = L:dot(L) - self.radius * self.radius
    local discriminant = b * b - 4 * a * c
    if discriminant >= 0 then
        local sqrt_d = math.sqrt(discriminant)
        local t1 = (-b - sqrt_d) / (2 * a)
        local t2 = (-b + sqrt_d) / (2 * a)
        if t1 >= 0 then
            points[#points + 1] = other.point + dir * t1
        end
        if t2 >= 0 and math.abs(t2 - t1) > 1e-10 then
            points[#points + 1] = other.point + dir * t2
        end
    end

    if #points == 0 then
        return false, nil
    end
    return true, points
end

---检查是否与射线相交
---@param other foundation.shape.Ray
---@return boolean
function Circle:__hasIntersectionWithRay(other)
    local dir = other.direction
    local len = dir:length()
    if len == 0 then
        return false
    end
    dir = dir / len
    local L = other.point - self.center
    local a = dir:dot(dir)
    local b = 2 * L:dot(dir)
    local c = L:dot(L) - self.radius * self.radius
    local discriminant = b * b - 4 * a * c

    if discriminant < 0 then
        return false
    end

    local sqrt_d = math.sqrt(discriminant)
    local t1 = (-b - sqrt_d) / (2 * a)
    local t2 = (-b + sqrt_d) / (2 * a)

    return t1 >= 0 or t2 >= 0
end

---检查与另一个圆的相交
---@param other foundation.shape.Circle
---@return boolean, foundation.math.Vector2[] | nil
function Circle:__intersectToCircle(other)
    local points = {}
    local d = (self.center - other.center):length()
    if d <= self.radius + other.radius and d >= math.abs(self.radius - other.radius) then
        local a = (self.radius * self.radius - other.radius * other.radius + d * d) / (2 * d)
        local h = math.sqrt(self.radius * self.radius - a * a)
        local p2 = self.center + (other.center - self.center) * (a / d)
        local perp = Vector2.create(-(other.center.y - self.center.y), other.center.x - self.center.x):normalized() * h
        points[#points + 1] = p2 + perp
        if math.abs(h) > 1e-10 then
            points[#points + 1] = p2 - perp
        end
    end

    if #points == 0 then
        return false, nil
    end
    return true, points
end

---检查是否与另一个圆相交
---@param other foundation.shape.Circle
---@return boolean
function Circle:__hasIntersectionWithCircle(other)
    local d = (self.center - other.center):length()
    return d <= self.radius + other.radius and d >= math.abs(self.radius - other.radius)
end

---计算点到圆的最近点
---@param point foundation.math.Vector2 要检查的点
---@return foundation.math.Vector2 圆上最近的点
function Circle:closestPoint(point)
    local dir = point - self.center
    local dist = dir:length()
    if dist == 0 then
        return Vector2.create(self.center.x + self.radius, self.center.y)
    end
    local normalized_dir = dir / dist
    return self.center + normalized_dir * self.radius
end

---计算点到圆的距离
---@param point foundation.math.Vector2 要检查的点
---@return number 点到圆的距离
function Circle:distanceToPoint(point)
    local dist = (point - self.center):length()
    return math.abs(dist - self.radius)
end

---将点投影到圆上
---@param point foundation.math.Vector2 要投影的点
---@return foundation.math.Vector2 投影点
function Circle:projectPoint(point)
    return self:closestPoint(point)
end

---检查点是否在圆上
---@param point foundation.math.Vector2 要检查的点
---@param tolerance number|nil 容差，默认为1e-10
---@return boolean 点是否在圆上
---@overload fun(self:foundation.shape.Circle, point:foundation.math.Vector2): boolean
function Circle:containsPoint(point, tolerance)
    tolerance = tolerance or 1e-10
    local dist = (point - self.center):length()
    return math.abs(dist - self.radius) <= tolerance
end

ffi.metatype("foundation_shape_Circle", Circle)

return Circle