local ffi = require("ffi")

local type = type
local tostring = tostring
local string = string
local math = math
local table = table
local ipairs = ipairs
local error = error
local rawset = rawset
local setmetatable = setmetatable

local Vector2 = require("foundation.math.Vector2")
local Segment = require("foundation.shape.Segment")
local ShapeIntersector = require("foundation.shape.ShapeIntersector")

ffi.cdef [[
typedef struct {
    int order;
    int num_points;
    foundation_math_Vector2* control_points;
} foundation_shape_BezierCurve;
]]

---@class foundation.shape.BezierCurve
---@field order number 贝塞尔曲线的阶数 (2=二次曲线，3=三次曲线)
---@field num_points number 控制点的数量
---@field control_points foundation.math.Vector2[] 控制点数组
local BezierCurve = {}
BezierCurve.__type = "foundation.shape.BezierCurve"

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

---@param self foundation.shape.BezierCurve
---@param key any
---@return any
function BezierCurve.__index(self, key)
    if key == "order" then
        return self.__data.order
    elseif key == "num_points" then
        return self.__data.num_points
    elseif key == "control_points" then
        return self.__data.control_points
    end
    return BezierCurve[key]
end

---@param self foundation.shape.BezierCurve
---@param key any
---@param value any
function BezierCurve.__newindex(self, key, value)
    if key == "order" then
        self.__data.order = value
    elseif key == "num_points" then
        error("cannot modify num_points directly")
    elseif key == "control_points" then
        local size, points_array = buildNewVector2Array(value)
        self.__data.num_points = size
        self.__data.control_points = points_array
        self.__data_points_ref = points_array
    else
        rawset(self, key, value)
    end
end

---创建一个贝塞尔曲线
---@param control_points foundation.math.Vector2[] 控制点数组
---@return foundation.shape.BezierCurve
function BezierCurve.create(control_points)
    if not control_points or #control_points < 2 then
        error("BezierCurve requires at least 2 control points")
    end

    local size, points_array = buildNewVector2Array(control_points)
    local order = size - 1

    local curve = ffi.new("foundation_shape_BezierCurve", order, size, points_array)
    local result = {
        __data = curve,
        __data_points_ref = points_array,
    }

    ---@diagnostic disable-next-line: return-type-mismatch, missing-return-value
    return setmetatable(result, BezierCurve)
end

---创建一个二次贝塞尔曲线
---@param p0 foundation.math.Vector2 起始点
---@param p1 foundation.math.Vector2 控制点
---@param p2 foundation.math.Vector2 结束点
---@return foundation.shape.BezierCurve
function BezierCurve.createQuadratic(p0, p1, p2)
    return BezierCurve.create({ p0, p1, p2 })
end

---创建一个三次贝塞尔曲线
---@param p0 foundation.math.Vector2 起始点
---@param p1 foundation.math.Vector2 控制点1
---@param p2 foundation.math.Vector2 控制点2
---@param p3 foundation.math.Vector2 结束点
---@return foundation.shape.BezierCurve
function BezierCurve.createCubic(p0, p1, p2, p3)
    return BezierCurve.create({ p0, p1, p2, p3 })
end

---贝塞尔曲线相等比较
---@param a foundation.shape.BezierCurve 第一条贝塞尔曲线
---@param b foundation.shape.BezierCurve 第二条贝塞尔曲线
---@return boolean
function BezierCurve.__eq(a, b)
    if a.order ~= b.order or a.num_points ~= b.num_points then
        return false
    end

    for i = 0, a.num_points - 1 do
        if a.control_points[i] ~= b.control_points[i] then
            return false
        end
    end

    return true
end

---贝塞尔曲线转字符串表示
---@param self foundation.shape.BezierCurve
---@return string
function BezierCurve.__tostring(self)
    local pointsStr = {}
    for i = 0, self.num_points - 1 do
        pointsStr[i + 1] = tostring(self.control_points[i])
    end
    return string.format("BezierCurve(%s)", table.concat(pointsStr, ", "))
end

---获取贝塞尔曲线上参数为t的点（t范围0到1）
---@param t number 参数值(0-1)
---@return foundation.math.Vector2
function BezierCurve:getPoint(t)
    if t <= 0 then
        return self.control_points[0]:clone()
    elseif t >= 1 then
        return self.control_points[self.num_points - 1]:clone()
    end

    local points = {}
    for i = 0, self.num_points - 1 do
        points[i + 1] = self.control_points[i]:clone()
    end

    for r = 1, self.order do
        for i = 1, self.num_points - r do
            points[i] = points[i] * (1 - t) + points[i + 1] * t
        end
    end

    return points[1]
end

---获取贝塞尔曲线上参数为t的切线单位向量
---@param t number 参数值(0-1)
---@return foundation.math.Vector2
function BezierCurve:getTangent(t)
    if self.order <= 1 then
        return (self.control_points[1] - self.control_points[0]):normalized()
    end

    local dt = 0.0001
    local p1 = self:getPoint(t)
    local p2 = self:getPoint(t + dt)
    return (p2 - p1):normalized()
end

---获取贝塞尔曲线的起点
---@return foundation.math.Vector2
function BezierCurve:getStartPoint()
    return self.control_points[0]:clone()
end

---获取贝塞尔曲线的终点
---@return foundation.math.Vector2
function BezierCurve:getEndPoint()
    return self.control_points[self.num_points - 1]:clone()
end

---转换为一系列线段的近似表示
---@param segments number 分段数
---@return foundation.shape.Segment[]
function BezierCurve:toSegments(segments)
    segments = segments or 10

    local points = self:discretize(segments)
    local segs = {}

    for i = 1, #points - 1 do
        segs[i] = Segment.create(points[i], points[i + 1])
    end

    return segs
end

---将贝塞尔曲线离散化为一系列点
---@param segments number 分段数
---@return foundation.math.Vector2[]
function BezierCurve:discretize(segments)
    segments = segments or 10
    local points = {}

    for i = 0, segments do
        local t = i / segments
        points[i + 1] = self:getPoint(t)
    end

    return points
end

---获取贝塞尔曲线的近似长度
---@param segments number 分段数，用于近似计算
---@return number
function BezierCurve:length(segments)
    segments = segments or 20
    local points = self:discretize(segments)
    local length = 0

    for i = 2, #points do
        length = length + (points[i] - points[i - 1]):length()
    end

    return length
end

---计算贝塞尔曲线的中心
---@return foundation.math.Vector2
function BezierCurve:getCenter()
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge

    local function updateBounds(point)
        minX = math.min(minX, point.x)
        minY = math.min(minY, point.y)
        maxX = math.max(maxX, point.x)
        maxY = math.max(maxY, point.y)
    end

    updateBounds(self.control_points[0])
    updateBounds(self.control_points[self.num_points - 1])

    local n = self.order
    if n > 1 then
        local deriv_points = {}
        for i = 0, n - 1 do
            deriv_points[i + 1] = (self.control_points[i + 1] - self.control_points[i]) * n
        end

        local t_values = { 0, 1 }
        if n == 2 then
            local p0, p1, p2 = self.control_points[0], self.control_points[1], self.control_points[2]
            local dx1 = p1.x - p0.x
            local dx2 = p2.x - p1.x
            local dy1 = p1.y - p0.y
            local dy2 = p2.y - p1.y

            if dx1 ~= dx2 then
                local tx = dx1 / (dx1 - dx2)
                if tx > 0 and tx < 1 then
                    table.insert(t_values, tx)
                end
            end

            if dy1 ~= dy2 then
                local ty = dy1 / (dy1 - dy2)
                if ty > 0 and ty < 1 then
                    table.insert(t_values, ty)
                end
            end
        elseif n == 3 then
            local q0 = deriv_points[1]
            local q1 = deriv_points[2]
            local q2 = deriv_points[3]

            local a_x = q0.x - 2 * q1.x + q2.x
            local b_x = 2 * (q1.x - q0.x)
            local c_x = q0.x
            if a_x ~= 0 then
                local discriminant_x = b_x * b_x - 4 * a_x * c_x
                if discriminant_x >= 0 then
                    local sqrt_d = math.sqrt(discriminant_x)
                    local t1 = (-b_x + sqrt_d) / (2 * a_x)
                    local t2 = (-b_x - sqrt_d) / (2 * a_x)
                    if t1 > 0 and t1 < 1 then
                        table.insert(t_values, t1)
                    end
                    if t2 > 0 and t2 < 1 then
                        table.insert(t_values, t2)
                    end
                end
            elseif b_x ~= 0 then
                local t = -c_x / b_x
                if t > 0 and t < 1 then
                    table.insert(t_values, t)
                end
            end

            local a_y = q0.y - 2 * q1.y + q2.y
            local b_y = 2 * (q1.y - q0.y)
            local c_y = q0.y
            if a_y ~= 0 then
                local discriminant_y = b_y * b_y - 4 * a_y * c_y
                if discriminant_y >= 0 then
                    local sqrt_d = math.sqrt(discriminant_y)
                    local t1 = (-b_y + sqrt_d) / (2 * a_y)
                    local t2 = (-b_y - sqrt_d) / (2 * a_y)
                    if t1 > 0 and t1 < 1 then
                        table.insert(t_values, t1)
                    end
                    if t2 > 0 and t2 < 1 then
                        table.insert(t_values, t2)
                    end
                end
            elseif b_y ~= 0 then
                local t = -c_y / b_y
                if t > 0 and t < 1 then
                    table.insert(t_values, t)
                end
            end
        end

        for _, t in ipairs(t_values) do
            updateBounds(self:getPoint(t))
        end
    end

    return Vector2.create((minX + maxX) / 2, (minY + maxY) / 2)
end

---获取贝塞尔曲线的AABB包围盒
---@return number, number, number, number
function BezierCurve:AABB()
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge

    -- 首先检查所有控制点
    for i = 0, self.num_points - 1 do
        local point = self.control_points[i]
        minX = math.min(minX, point.x)
        minY = math.min(minY, point.y)
        maxX = math.max(maxX, point.x)
        maxY = math.max(maxY, point.y)
    end

    -- 对于高阶贝塞尔曲线，还需要检查曲线上的极值点
    if self.order > 1 then
        local segments = self.order * 10 -- 使用更多的分段来获得更精确的包围盒
        for i = 0, segments do
            local t = i / segments
            local point = self:getPoint(t)
            minX = math.min(minX, point.x)
            minY = math.min(minY, point.y)
            maxX = math.max(maxX, point.x)
            maxY = math.max(maxY, point.y)
        end
    end

    return minX, maxX, minY, maxY
end

---计算贝塞尔曲线的包围盒宽高
---@return number, number
function BezierCurve:getBoundingBoxSize()
    local minX, maxX, minY, maxY = self:AABB()
    return maxX - minX, maxY - minY
end

---将当前贝塞尔曲线平移指定距离（更改当前曲线）
---@param v foundation.math.Vector2 | number 移动距离
---@return foundation.shape.BezierCurve 自身引用
function BezierCurve:move(v)
    local moveX, moveY
    if type(v) == "number" then
        moveX, moveY = v, v
    else
        moveX, moveY = v.x, v.y
    end

    local new_points = {}
    for i = 0, self.num_points - 1 do
        local p = self.control_points[i]
        new_points[i + 1] = Vector2.create(p.x + moveX, p.y + moveY)
    end

    self.control_points = new_points
    return self
end

---获取平移后的贝塞尔曲线副本
---@param v foundation.math.Vector2 | number 移动距离
---@return foundation.shape.BezierCurve
function BezierCurve:moved(v)
    local moveX, moveY
    if type(v) == "number" then
        moveX, moveY = v, v
    else
        moveX, moveY = v.x, v.y
    end

    local new_points = {}
    for i = 0, self.num_points - 1 do
        local p = self.control_points[i]
        new_points[i + 1] = Vector2.create(p.x + moveX, p.y + moveY)
    end

    return BezierCurve.create(new_points)
end

---将当前贝塞尔曲线旋转指定弧度（更改当前曲线）
---@param rad number 旋转弧度
---@param center foundation.math.Vector2 旋转中心，默认为曲线的中心
---@return foundation.shape.BezierCurve 自身引用
function BezierCurve:rotate(rad, center)
    center = center or self:getCenter()
    local cosRad = math.cos(rad)
    local sinRad = math.sin(rad)

    local new_points = {}
    for i = 0, self.num_points - 1 do
        local p = self.control_points[i]
        local v = p - center
        local x = v.x * cosRad - v.y * sinRad + center.x
        local y = v.x * sinRad + v.y * cosRad + center.y
        new_points[i + 1] = Vector2.create(x, y)
    end

    self.control_points = new_points
    return self
end

---将当前贝塞尔曲线旋转指定角度（更改当前曲线）
---@param angle number 旋转角度
---@param center foundation.math.Vector2 旋转中心，默认为曲线的中心
---@return foundation.shape.BezierCurve 自身引用
function BezierCurve:degreeRotate(angle, center)
    return self:rotate(math.rad(angle), center)
end

---获取旋转后的贝塞尔曲线副本
---@param rad number 旋转弧度
---@param center foundation.math.Vector2 旋转中心，默认为曲线的中心
---@return foundation.shape.BezierCurve
function BezierCurve:rotated(rad, center)
    center = center or self:getCenter()
    local cosRad = math.cos(rad)
    local sinRad = math.sin(rad)

    local new_points = {}
    for i = 0, self.num_points - 1 do
        local p = self.control_points[i]
        local v = p - center
        local x = v.x * cosRad - v.y * sinRad + center.x
        local y = v.x * sinRad + v.y * cosRad + center.y
        new_points[i + 1] = Vector2.create(x, y)
    end

    return BezierCurve.create(new_points)
end

---获取旋转后的贝塞尔曲线副本
---@param angle number 旋转角度
---@param center foundation.math.Vector2 旋转中心，默认为曲线的中心
---@return foundation.shape.BezierCurve
function BezierCurve:degreeRotated(angle, center)
    return self:rotated(math.rad(angle), center)
end

---将当前贝塞尔曲线缩放指定倍数（更改当前曲线）
---@param scale number | foundation.math.Vector2 缩放倍数
---@param center foundation.math.Vector2 缩放中心，默认为曲线的中心
---@return foundation.shape.BezierCurve 自身引用
function BezierCurve:scale(scale, center)
    local scaleX, scaleY
    if type(scale) == "number" then
        scaleX, scaleY = scale, scale
    else
        scaleX, scaleY = scale.x, scale.y
    end

    center = center or self:getCenter()

    local new_points = {}
    for i = 0, self.num_points - 1 do
        local p = self.control_points[i]
        local x = (p.x - center.x) * scaleX + center.x
        local y = (p.y - center.y) * scaleY + center.y
        new_points[i + 1] = Vector2.create(x, y)
    end

    self.control_points = new_points
    return self
end

---获取缩放后的贝塞尔曲线副本
---@param scale number | foundation.math.Vector2 缩放倍数
---@param center foundation.math.Vector2 缩放中心，默认为曲线的中心
---@return foundation.shape.BezierCurve
function BezierCurve:scaled(scale, center)
    local scaleX, scaleY
    if type(scale) == "number" then
        scaleX, scaleY = scale, scale
    else
        scaleX, scaleY = scale.x, scale.y
    end

    center = center or self:getCenter()

    local new_points = {}
    for i = 0, self.num_points - 1 do
        local p = self.control_points[i]
        local x = (p.x - center.x) * scaleX + center.x
        local y = (p.y - center.y) * scaleY + center.y
        new_points[i + 1] = Vector2.create(x, y)
    end

    return BezierCurve.create(new_points)
end

---获取曲线上最近的点
---@param point foundation.math.Vector2 参考点
---@return foundation.math.Vector2 曲线上最近的点
function BezierCurve:closestPoint(point)
    return self:closestPointWithSegments(point)
end

---获取曲线上最近的点
---@param point foundation.math.Vector2 参考点
---@param segments number 分段数，用于近似计算
---@return foundation.math.Vector2 曲线上最近的点
---@overload fun(self: foundation.shape.BezierCurve, point: foundation.math.Vector2): foundation.math.Vector2
function BezierCurve:closestPointWithSegments(point, segments)
    segments = segments or 20
    local minDist = math.huge
    local closest

    local points = self:discretize(segments)
    for _, p in ipairs(points) do
        local dist = (p - point):length()
        if dist < minDist then
            minDist = dist
            closest = p
        end
    end

    return closest
end

---将点投影到贝塞尔曲线上
---@param point foundation.math.Vector2 要投影的点
---@return foundation.math.Vector2, number
function BezierCurve:projectPoint(point)
    return self:projectPointWithSegments(point)
end

---将点投影到贝塞尔曲线上
---@param point foundation.math.Vector2 要投影的点
---@param segments number 分段数，用于近似计算
---@return foundation.math.Vector2, number
---@overload fun(self: foundation.shape.BezierCurve, point: foundation.math.Vector2): foundation.math.Vector2, number
function BezierCurve:projectPointWithSegments(point, segments)
    segments = segments or 20
    local minDist = math.huge
    local closestPoint
    local closestT

    for i = 0, segments do
        local t = i / segments
        local p = self:getPoint(t)
        local dist = (p - point):length()
        if dist < minDist then
            minDist = dist
            closestPoint = p
            closestT = t
        end
    end

    return closestPoint, closestT
end

---计算点到贝塞尔曲线的距离
---@param point foundation.math.Vector2 参考点
---@param segments number 分段数，用于近似计算
---@return number 距离
function BezierCurve:distanceToPoint(point, segments)
    local closestPoint = self:closestPointWithSegments(point, segments)
    return (closestPoint - point):length()
end

---拆分贝塞尔曲线为两部分
---@param t number 分割参数(0-1)
---@return foundation.shape.BezierCurve, foundation.shape.BezierCurve 前半部分和后半部分
function BezierCurve:split(t)
    if t <= 0 then
        return BezierCurve.create({ self.control_points[0] }), self
    elseif t >= 1 then
        return self, BezierCurve.create({ self.control_points[self.num_points - 1] })
    end

    local points = {}
    for i = 0, self.num_points - 1 do
        points[i + 1] = self.control_points[i]:clone()
    end

    local left_points = { points[1] }

    for r = 1, self.order do
        for i = 1, self.num_points - r do
            points[i] = points[i] * (1 - t) + points[i + 1] * t
        end
        left_points[r + 1] = points[1]
    end

    local right_points = {}
    for i = 1, self.order + 1 do
        right_points[i] = points[i]
    end

    return BezierCurve.create(left_points), BezierCurve.create(right_points)
end

---检查与其他形状的相交
---@param other any
---@return boolean, foundation.math.Vector2[] | nil
function BezierCurve:intersects(other)
    return ShapeIntersector.intersect(self, other)
end

---仅检查是否与其他形状相交
---@param other any
---@return boolean
function BezierCurve:hasIntersection(other)
    return ShapeIntersector.hasIntersection(self, other)
end

---检查点是否在贝塞尔曲线上
---@param point foundation.math.Vector2
---@param tolerance number|nil 容差，默认为1e-10
---@param segments number|nil 分段数，用于近似计算
---@return boolean
---@overload fun(self: foundation.shape.BezierCurve, point: foundation.math.Vector2, tolerance: number): boolean
---@overload fun(self: foundation.shape.BezierCurve, point: foundation.math.Vector2): boolean
function BezierCurve:containsPoint(point, tolerance, segments)
    tolerance = tolerance or 1e-10
    local projPoint = self:closestPointWithSegments(point, segments)
    return (point - projPoint):length() <= tolerance
end

---克隆贝塞尔曲线
---@return foundation.shape.BezierCurve
function BezierCurve:clone()
    local new_points = {}
    for i = 0, self.num_points - 1 do
        new_points[i + 1] = self.control_points[i]:clone()
    end
    return BezierCurve.create(new_points)
end

---获取按弧长等分的点集
---@param num_points number 期望的点数（包含起点和终点）
---@param tolerance number|nil 弧长误差容差，默认为1e-6
---@return foundation.math.Vector2[]
function BezierCurve:getEqualArcLengthPoints(num_points, tolerance)
    num_points = num_points or 10
    tolerance = tolerance or 1e-6
    if num_points < 2 then
        error("Number of points must be at least 2")
    end

    local total_length = self:length(100)
    local target_segment_length = total_length / (num_points - 1)
    local points = { self:getPoint(0) }
    local current_length = 0
    local t = 0
    local step = 0.01
    local last_point = points[1]
    local last_t = 0

    while #points < num_points and t <= 1 do
        t = math.min(t + step, 1)
        local point = self:getPoint(t)
        local segment_length = (point - last_point):length()
        current_length = current_length + segment_length

        if current_length >= target_segment_length - tolerance or t >= 1 then
            table.insert(points, point)
            last_point = point
            last_t = t
            current_length = 0

            local remaining_points = num_points - #points
            if remaining_points > 0 then
                local remaining_t = 1 - t
                step = remaining_t / (remaining_points * 2)
            end
        else
            last_point = point
            last_t = t
        end
    end

    if math.abs(t - 1) > tolerance and #points == num_points then
        points[#points] = self:getPoint(1)
    end

    return points
end

---获取按弧长等分的线段集
---@param num_segments number 期望的线段数（包含起点和终点）
---@param tolerance number|nil 弧长误差容差，默认为1e-6
---@return foundation.shape.Segment[]
function BezierCurve:getEqualArcLengthSegments(num_segments, tolerance)
    local points = self:getEqualArcLengthPoints(num_segments + 1, tolerance)
    local segments = {}

    for i = 1, #points - 1 do
        segments[i] = Segment.create(points[i], points[i + 1])
    end

    return segments
end

ffi.metatype("foundation_shape_BezierCurve", BezierCurve)

return BezierCurve