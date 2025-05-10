local ffi = require("ffi")

local type = type
local tostring = tostring
local string = string
local math = math
local table = table
local error = error
local rawset = rawset
local setmetatable = setmetatable

local Vector2 = require("foundation.math.Vector2")
local Segment = require("foundation.shape.Segment")
local ShapeIntersector = require("foundation.shape.ShapeIntersector")

ffi.cdef [[
typedef struct {
    foundation_math_Vector2 center;
    double rx;
    double ry;
    foundation_math_Vector2 direction;
} foundation_shape_Ellipse;
]]

---@class foundation.shape.Ellipse
---@field center foundation.math.Vector2 椭圆中心
---@field rx number x半轴长度（横向半径）
---@field ry number y半轴长度（纵向半径）
---@field direction foundation.math.Vector2 方向（归一化向量，指向椭圆x轴正半轴方向）
local Ellipse = {}
Ellipse.__type = "foundation.shape.Ellipse"

---@param self foundation.shape.Ellipse
---@param key any
---@return any
function Ellipse.__index(self, key)
    if key == "center" then
        return self.__data.center
    elseif key == "rx" then
        return self.__data.rx
    elseif key == "ry" then
        return self.__data.ry
    elseif key == "direction" then
        return self.__data.direction
    end
    return Ellipse[key]
end

---@param self foundation.shape.Ellipse
---@param key any
---@param value any
function Ellipse.__newindex(self, key, value)
    if key == "center" then
        self.__data.center = value
    elseif key == "rx" then
        self.__data.rx = value
    elseif key == "ry" then
        self.__data.ry = value
    elseif key == "direction" then
        self.__data.direction = value
    else
        rawset(self, key, value)
    end
end

---创建一个新的椭圆
---@param center foundation.math.Vector2 椭圆中心
---@param rx number x半轴长度（横向半径）
---@param ry number y半轴长度（纵向半径）
---@param direction foundation.math.Vector2|nil 方向向量，默认为(1,0)
---@return foundation.shape.Ellipse
function Ellipse.create(center, rx, ry, direction)
    direction = direction or Vector2.create(1, 0)
    direction = direction:normalized()
    local ellipse = ffi.new("foundation_shape_Ellipse", center, rx, ry, direction)
    local result = {
        __data = ellipse,
    }
    ---@diagnostic disable-next-line: return-type-mismatch, missing-return-value
    return setmetatable(result, Ellipse)
end

---使用弧度创建椭圆
---@param center foundation.math.Vector2 椭圆中心
---@param rx number x半轴长度（横向半径）
---@param ry number y半轴长度（纵向半径）
---@param rad number 方向弧度
---@return foundation.shape.Ellipse
function Ellipse.createFromRad(center, rx, ry, rad)
    local dir = Vector2.createFromRad(rad)
    return Ellipse.create(center, rx, ry, dir)
end

---使用角度单位创建椭圆
---@param center foundation.math.Vector2 椭圆中心
---@param rx number x半轴长度（横向半径）
---@param ry number y半轴长度（纵向半径）
---@param angle number 椭圆方向角度（角度）
---@return foundation.shape.Ellipse
function Ellipse.createFromAngle(center, rx, ry, angle)
    return Ellipse.createFromRad(center, rx, ry, math.rad(angle))
end

---椭圆相等比较
---@param a foundation.shape.Ellipse
---@param b foundation.shape.Ellipse
---@return boolean
function Ellipse.__eq(a, b)
    return a.center == b.center and
            math.abs(a.rx - b.rx) <= 1e-10 and
            math.abs(a.ry - b.ry) <= 1e-10 and
            a.direction == b.direction
end

---椭圆的字符串表示
---@param self foundation.shape.Ellipse
---@return string
function Ellipse.__tostring(self)
    return string.format("Ellipse(center=%s, rx=%f, ry=%f, direction=%s)",
            tostring(self.center), self.rx, self.ry, tostring(self.direction))
end

---获取椭圆上指定角度的点
---@param angle number 角度（弧度）
---@return foundation.math.Vector2
function Ellipse:getPointAtAngle(angle)
    local baseAngle = self.direction:angle()

    local cos_angle = math.cos(angle)
    local sin_angle = math.sin(angle)

    local x = self.rx * cos_angle
    local y = self.ry * sin_angle

    local cos_rotation = math.cos(baseAngle)
    local sin_rotation = math.sin(baseAngle)

    local px = cos_rotation * x - sin_rotation * y + self.center.x
    local py = sin_rotation * x + cos_rotation * y + self.center.y

    return Vector2.create(px, py)
end

---将椭圆离散化为一系列点
---@param segments number 分段数
---@return foundation.math.Vector2[]
function Ellipse:discretize(segments)
    segments = segments or 30
    local points = {}

    for i = 0, segments do
        local angle = 2 * math.pi * i / segments
        points[i + 1] = self:getPointAtAngle(angle)
    end

    return points
end

---获取椭圆的离散顶点（重命名discretize以保持一致性）
---@param segments number 分段数
---@return foundation.math.Vector2[]
function Ellipse:getVertices(segments)
    return self:discretize(segments or 30)
end

---获取椭圆的离散边缘线段
---@param segments number 分段数
---@return foundation.shape.Segment[]
function Ellipse:getEdges(segments)
    segments = segments or 30
    local points = self:discretize(segments)
    local segs = {}

    for i = 1, segments do
        local nextIndex = (i % segments) + 1
        segs[i] = Segment.create(points[i], points[nextIndex])
    end

    return segs
end

---计算椭圆的内心
---@return foundation.math.Vector2 椭圆的内心
function Ellipse:incenter()
    return self.center:clone()
end

---计算椭圆的内切圆半径
---@return number 椭圆的内切圆半径
function Ellipse:inradius()
    return math.min(self.rx, self.ry)
end

---计算椭圆的外心
---@return foundation.math.Vector2 椭圆的外心
function Ellipse:circumcenter()
    return self.center:clone()
end

---计算椭圆的外接圆半径
---@return number 椭圆的外接圆半径
function Ellipse:circumradius()
    return math.max(self.rx, self.ry)
end

---移动椭圆（修改当前椭圆）
---@param v foundation.math.Vector2 | number
---@return foundation.shape.Ellipse 自身引用
function Ellipse:move(v)
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

---获取移动后的椭圆副本
---@param v foundation.math.Vector2 | number
---@return foundation.shape.Ellipse
function Ellipse:moved(v)
    local moveX, moveY
    if type(v) == "number" then
        moveX, moveY = v, v
    else
        moveX, moveY = v.x, v.y
    end
    return Ellipse.create(
            Vector2.create(self.center.x + moveX, self.center.y + moveY),
            self.rx, self.ry, self.direction
    )
end

---旋转椭圆（修改当前椭圆）
---@param rad number 旋转弧度
---@param center foundation.math.Vector2|nil 旋转中心点，默认为椭圆中心
---@return foundation.shape.Ellipse 自身引用
function Ellipse:rotate(rad, center)
    self.direction = self.direction:rotated(rad)
    if center then
        local dx = self.center.x - center.x
        local dy = self.center.y - center.y
        local cosA, sinA = math.cos(rad), math.sin(rad)
        self.center.x = center.x + dx * cosA - dy * sinA
        self.center.y = center.y + dx * sinA + dy * cosA
    end
    return self
end

---旋转椭圆（修改当前椭圆）
---@param angle number 旋转角度
---@param center foundation.math.Vector2|nil 旋转中心点，默认为椭圆中心
---@return foundation.shape.Ellipse 自身引用
function Ellipse:degreeRotate(angle, center)
    return self:rotate(math.rad(angle), center)
end

---获取旋转后的椭圆副本
---@param rad number 旋转弧度
---@param center foundation.math.Vector2|nil 旋转中心点，默认为椭圆中心
---@return foundation.shape.Ellipse
function Ellipse:rotated(rad, center)
    local result = Ellipse.create(self.center:clone(), self.rx, self.ry, self.direction:clone())
    return result:rotate(rad, center)
end

---获取旋转后的椭圆副本
---@param angle number 旋转角度
---@param center foundation.math.Vector2|nil 旋转中心点，默认为椭圆中心
---@return foundation.shape.Ellipse
function Ellipse:degreeRotated(angle, center)
    return self:rotated(math.rad(angle), center)
end

---缩放椭圆（修改当前椭圆）
---@param scale number|foundation.math.Vector2 缩放比例
---@param center foundation.math.Vector2|nil 缩放中心点，默认为椭圆中心
---@return foundation.shape.Ellipse 自身引用
function Ellipse:scale(scale, center)
    local scaleX, scaleY
    if type(scale) == "number" then
        scaleX, scaleY = scale, scale
    else
        scaleX, scaleY = scale.x, scale.y
    end
    center = center or self.center

    self.rx = self.rx * scaleX
    self.ry = self.ry * scaleY
    local dx = self.center.x - center.x
    local dy = self.center.y - center.y
    self.center.x = center.x + dx * scaleX
    self.center.y = center.y + dy * scaleY
    return self
end

---获取缩放后的椭圆副本
---@param scale number|foundation.math.Vector2 缩放比例
---@param center foundation.math.Vector2|nil 缩放中心点，默认为椭圆中心
---@return foundation.shape.Ellipse
function Ellipse:scaled(scale, center)
    local result = Ellipse.create(self.center:clone(), self.rx, self.ry, self.direction:clone())
    return result:scale(scale, center)
end

---检查点是否在椭圆内或椭圆上
---@param point foundation.math.Vector2
---@return boolean
function Ellipse:contains(point)
    return ShapeIntersector.ellipseContainsPoint(self, point)
end

---检查与其他形状的相交
---@param other any
---@return boolean, foundation.math.Vector2[] | nil
function Ellipse:intersects(other)
    return ShapeIntersector.intersect(self, other)
end

---只检查是否与其他形状相交，不计算交点
---@param other any
---@return boolean
function Ellipse:hasIntersection(other)
    return ShapeIntersector.hasIntersection(self, other)
end

---计算椭圆的面积
---@return number 椭圆的面积
function Ellipse:area()
    return math.pi * self.rx * self.ry
end

---计算椭圆的周长（近似值）
---@return number 椭圆的周长近似值
function Ellipse:getPerimeter()
    local h = (self.rx - self.ry) ^ 2 / (self.rx + self.ry) ^ 2
    return math.pi * (self.rx + self.ry) * (1 + 3 * h / (10 + math.sqrt(4 - 3 * h)))
end

---计算椭圆的中心
---@return foundation.math.Vector2 椭圆中心点
function Ellipse:getCenter()
    return self.center:clone()
end

---获取椭圆的AABB包围盒
---@return number, number, number, number
function Ellipse:AABB()
    local baseAngle = self.direction:angle()
    local cos_angle = math.cos(baseAngle)
    local sin_angle = math.sin(baseAngle)

    local x_axis = Vector2.create(self.rx * cos_angle, self.rx * sin_angle)
    local y_axis = Vector2.create(-self.ry * sin_angle, self.ry * cos_angle)

    local half_width = math.sqrt(x_axis.x * x_axis.x + y_axis.x * y_axis.x)
    local half_height = math.sqrt(x_axis.y * x_axis.y + y_axis.y * y_axis.y)

    return self.center.x - half_width, self.center.x + half_width, self.center.y - half_height, self.center.y + half_height
end

---计算椭圆的包围盒宽高
---@return number, number
function Ellipse:getBoundingBoxSize()
    local minX, maxX, minY, maxY = self:AABB()
    return maxX - minX, maxY - minY
end

---计算椭圆的重心
---@return foundation.math.Vector2 椭圆中心点
function Ellipse:centroid()
    return self.center:clone()
end

---计算点到椭圆的最近点
---@param point foundation.math.Vector2 要检查的点
---@param boundary boolean 是否限制在边界上，默认为false
---@return foundation.math.Vector2 椭圆上最近的点
---@overload fun(self:foundation.shape.Ellipse, point:foundation.math.Vector2): foundation.math.Vector2
function Ellipse:closestPoint(point, boundary)
    if not boundary and self:contains(point) then
        return point:clone()
    end

    local baseAngle = self.direction:angle()
    local cos_rotation = math.cos(-baseAngle)
    local sin_rotation = math.sin(-baseAngle)

    local dx = point.x - self.center.x
    local dy = point.y - self.center.y

    local x = cos_rotation * dx - sin_rotation * dy
    local y = sin_rotation * dx + cos_rotation * dy

    local px = x / self.rx
    local py = y / self.ry

    local length = math.sqrt(px * px + py * py)
    if length < 1e-10 then
        px = self.rx
        py = 0
    else
        local px1 = px / length * self.rx
        local py1 = py / length * self.ry
        local px2 = -px / length * self.rx
        local py2 = -py / length * self.ry

        local cos_world = math.cos(baseAngle)
        local sin_world = math.sin(baseAngle)

        local result_x1 = cos_world * px1 - sin_world * py1 + self.center.x
        local result_y1 = sin_world * px1 + cos_world * py1 + self.center.y
        local point1 = Vector2.create(result_x1, result_y1)

        local result_x2 = cos_world * px2 - sin_world * py2 + self.center.x
        local result_y2 = sin_world * px2 + cos_world * py2 + self.center.y
        local point2 = Vector2.create(result_x2, result_y2)

        local dist1 = (point - point1):length()
        local dist2 = (point - point2):length()
        return dist1 <= dist2 and point1 or point2
    end

    local cos_world = math.cos(baseAngle)
    local sin_world = math.sin(baseAngle)
    local result_x = cos_world * px - sin_world * py + self.center.x
    local result_y = sin_world * px + cos_world * py + self.center.y

    return Vector2.create(result_x, result_y)
end

---计算点到椭圆的距离
---@param point foundation.math.Vector2 要检查的点
---@return number 点到椭圆的距离
function Ellipse:distanceToPoint(point)
    if self:contains(point) then
        return 0
    end

    local closestPoint = self:closestPoint(point, true)
    return (point - closestPoint):length()
end

---将点投影到椭圆上
---@param point foundation.math.Vector2 要投影的点
---@return foundation.math.Vector2 投影点
function Ellipse:projectPoint(point)
    return self:closestPoint(point, true)
end

---检查点是否在椭圆上
---@param point foundation.math.Vector2 要检查的点
---@param tolerance number|nil 容差，默认为1e-10
---@return boolean 点是否在椭圆上
---@overload fun(self:foundation.shape.Ellipse, point:foundation.math.Vector2): boolean
function Ellipse:containsPoint(point, tolerance)
    tolerance = tolerance or 1e-10
    local projPoint = self:closestPoint(point, true)
    local distance = (point - projPoint):length()
    return distance <= tolerance
end

---创建椭圆的一个副本
---@return foundation.shape.Ellipse
function Ellipse:clone()
    return Ellipse.create(self.center:clone(), self.rx, self.ry, self.direction:clone())
end

---获取按弧长等分的点集和线段集
---@param num_points number 期望的点数（包含起点）
---@param tolerance number|nil 弧长误差容差，默认为1e-6
---@return foundation.math.Vector2[]
function Ellipse:getEqualArcLengthPoints(num_points, tolerance)
    num_points = num_points or 30
    tolerance = tolerance or 1e-6
    if num_points < 2 then
        error("Number of points must be at least 2")
    end

    local total_length = self:getPerimeter()
    local target_segment_length = total_length / num_points
    local points = { self:getPointAtAngle(0) }
    local current_length = 0
    local angle = 0
    local step = 2 * math.pi / 100
    local last_point = points[1]
    local last_angle = 0

    while #points < num_points and angle < 2 * math.pi do
        angle = math.min(angle + step, 2 * math.pi)
        local point = self:getPointAtAngle(angle)
        local segment_length = (point - last_point):length()
        current_length = current_length + segment_length

        if current_length >= target_segment_length - tolerance or angle >= 2 * math.pi then
            table.insert(points, point)
            last_point = point
            last_angle = angle
            current_length = 0

            local remaining_points = num_points - #points
            if remaining_points > 0 then
                local remaining_angle = 2 * math.pi - angle
                step = remaining_angle / (remaining_points * 2)
            end
        else
            last_point = point
            last_angle = angle
        end
    end

    if math.abs(angle - 2 * math.pi) > tolerance and #points == num_points then
        points[#points] = self:getPointAtAngle(2 * math.pi)
    end

    return points
end

---获取按弧长等分的线段集
---@param num_segments number 期望的线段数（包含起点和终点）
---@param tolerance number|nil 弧长误差容差，默认为1e-6
---@return foundation.shape.Segment[]
function Ellipse:getEqualArcLengthSegments(num_segments, tolerance)
    local points = self:getEqualArcLengthPoints(num_segments + 1, tolerance)
    local segments = {}

    for i = 1, #points - 1 do
        segments[i] = Segment.create(points[i], points[i + 1])
    end

    return segments
end

ffi.metatype("foundation_shape_Ellipse", Ellipse)

return Ellipse