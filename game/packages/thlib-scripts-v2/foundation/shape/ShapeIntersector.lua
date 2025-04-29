local Vector2 = require("foundation.math.Vector2")
local math = math
local tostring = tostring
local ipairs = ipairs

---@class foundation.shape.ShapeIntersector
local ShapeIntersector = {}

---检查点是否在圆内或圆上
---@param circle foundation.shape.Circle 圆形
---@param point foundation.math.Vector2 点
---@return boolean
function ShapeIntersector.circleContainsPoint(circle, point)
    return (point - circle.center):length() <= circle.radius
end

---检查点是否在矩形内（包括边界）
---@param rectangle foundation.shape.Rectangle 矩形
---@param point foundation.math.Vector2 点
---@return boolean
function ShapeIntersector.rectangleContainsPoint(rectangle, point)
    local p = point - rectangle.center
    local dir = rectangle.direction
    local perp = Vector2.create(-dir.y, dir.x)
    local x = p.x * dir.x + p.y * dir.y
    local y = p.x * perp.x + p.y * perp.y
    local hw, hh = rectangle.width / 2, rectangle.height / 2
    return math.abs(x) <= hw and math.abs(y) <= hh
end

---检查点是否在扇形内（包括边界）
---@param sector foundation.shape.Sector 扇形
---@param point foundation.math.Vector2 点
---@return boolean
function ShapeIntersector.sectorContainsPoint(sector, point)
    local v = point - sector.center
    local dist = v:length()
    if dist > sector.radius then
        return false
    end

    if dist < 1e-10 then
        return true
    end

    local angle = math.atan2(v.y, v.x)
    if angle < 0 then
        angle = angle + 2 * math.pi
    end

    local start = sector.startDirection:angle()
    local end_dir = sector.endDirection:angle()

    if start > end_dir then
        end_dir = end_dir + 2 * math.pi
    end

    if angle < start then
        angle = angle + 2 * math.pi
    end

    return angle <= end_dir
end

---检查点是否在三角形内
---@param triangle foundation.shape.Triangle 三角形
---@param point foundation.math.Vector2 点
---@return boolean
function ShapeIntersector.triangleContainsPoint(triangle, point)
    local v1 = triangle.point1
    local v2 = triangle.point2
    local v3 = triangle.point3
    local p = point

    local v3v1 = v3 - v1
    local v2v1 = v2 - v1
    local pv1 = p - v1

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

---整理相交点，去除重复点
---@param points foundation.math.Vector2[] 原始点列表
---@return foundation.math.Vector2[] 去重后的点列表
function ShapeIntersector.getUniquePoints(points)
    local unique_points = {}
    local seen = {}
    for _, p in ipairs(points) do
        local key = tostring(p.x) .. "," .. tostring(p.y)
        if not seen[key] then
            seen[key] = true
            unique_points[#unique_points + 1] = p
        end
    end
    return unique_points
end

---检查三角形与线段的相交
---@param triangle foundation.shape.Triangle 三角形
---@param segment foundation.shape.Segment 线段
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.triangleToSegment(triangle, segment)
    local points = {}
    local edges = triangle:getEdges()
    for _, edge in ipairs(edges) do
        local success, edge_points = ShapeIntersector.segmentToSegment(edge, segment)
        if success then
            for _, p in ipairs(edge_points) do
                points[#points + 1] = p
            end
        end
    end
    if ShapeIntersector.triangleContainsPoint(triangle, segment.point1) then
        points[#points + 1] = segment.point1:clone()
    end
    if segment.point1 ~= segment.point2 and ShapeIntersector.triangleContainsPoint(triangle, segment.point2) then
        points[#points + 1] = segment.point2:clone()
    end

    local unique_points = ShapeIntersector.getUniquePoints(points)

    if #unique_points == 0 then
        return false, nil
    end
    return true, unique_points
end

---只检查三角形与线段是否相交
---@param triangle foundation.shape.Triangle 三角形
---@param segment foundation.shape.Segment 线段
---@return boolean
function ShapeIntersector.triangleHasIntersectionWithSegment(triangle, segment)
    local edges = triangle:getEdges()

    for _, edge in ipairs(edges) do
        if ShapeIntersector.segmentHasIntersectionWithSegment(edge, segment) then
            return true
        end
    end

    if ShapeIntersector.triangleContainsPoint(triangle, segment.point1) or
            ShapeIntersector.triangleContainsPoint(triangle, segment.point2) then
        return true
    end

    return false
end

---检查三角形与另一个三角形的相交
---@param triangle1 foundation.shape.Triangle 第一个三角形
---@param triangle2 foundation.shape.Triangle 第二个三角形
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.triangleToTriangle(triangle1, triangle2)
    local points = {}
    local edges1 = triangle1:getEdges()
    local edges2 = triangle2:getEdges()

    for _, edge1 in ipairs(edges1) do
        for _, edge2 in ipairs(edges2) do
            local success, edge_points = ShapeIntersector.segmentToSegment(edge1, edge2)
            if success then
                for _, p in ipairs(edge_points) do
                    points[#points + 1] = p
                end
            end
        end
    end

    local vertices = triangle2:getVertices()
    for _, vertex in ipairs(vertices) do
        if ShapeIntersector.triangleContainsPoint(triangle1, vertex) then
            points[#points + 1] = vertex
        end
    end

    vertices = triangle1:getVertices()
    for _, vertex in ipairs(vertices) do
        if ShapeIntersector.triangleContainsPoint(triangle2, vertex) then
            points[#points + 1] = vertex
        end
    end

    local unique_points = ShapeIntersector.getUniquePoints(points)

    if #unique_points == 0 then
        return false, nil
    end
    return true, unique_points
end

---只检查三角形与另一个三角形是否相交
---@param triangle1 foundation.shape.Triangle 第一个三角形
---@param triangle2 foundation.shape.Triangle 第二个三角形
---@return boolean
function ShapeIntersector.triangleHasIntersectionWithTriangle(triangle1, triangle2)
    local edges1 = triangle1:getEdges()
    local edges2 = triangle2:getEdges()

    for _, edge1 in ipairs(edges1) do
        for _, edge2 in ipairs(edges2) do
            if ShapeIntersector.segmentHasIntersectionWithSegment(edge1, edge2) then
                return true
            end
        end
    end

    local vertices = triangle2:getVertices()
    for _, vertex in ipairs(vertices) do
        if ShapeIntersector.triangleContainsPoint(triangle1, vertex) then
            return true
        end
    end

    vertices = triangle1:getVertices()
    for _, vertex in ipairs(vertices) do
        if ShapeIntersector.triangleContainsPoint(triangle2, vertex) then
            return true
        end
    end

    return false
end

---检查三角形与直线的相交
---@param triangle foundation.shape.Triangle 三角形
---@param line foundation.shape.Line 直线
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.triangleToLine(triangle, line)
    local points = {}
    local edges = triangle:getEdges()
    for _, edge in ipairs(edges) do
        local success, edge_points = ShapeIntersector.lineToSegment(line, edge)
        if success then
            for _, p in ipairs(edge_points) do
                points[#points + 1] = p
            end
        end
    end

    local unique_points = ShapeIntersector.getUniquePoints(points)

    if #unique_points == 0 then
        return false, nil
    end
    return true, unique_points
end

---只检查三角形与直线是否相交
---@param triangle foundation.shape.Triangle 三角形
---@param line foundation.shape.Line 直线
---@return boolean
function ShapeIntersector.triangleHasIntersectionWithLine(triangle, line)
    local edges = triangle:getEdges()

    for _, edge in ipairs(edges) do
        if ShapeIntersector.lineHasIntersectionWithSegment(line, edge) then
            return true
        end
    end

    return false
end

---检查三角形与射线的相交
---@param triangle foundation.shape.Triangle 三角形
---@param ray foundation.shape.Ray 射线
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.triangleToRay(triangle, ray)
    local points = {}
    local edges = triangle:getEdges()
    for _, edge in ipairs(edges) do
        local success, edge_points = ShapeIntersector.rayToSegment(ray, edge)
        if success then
            for _, p in ipairs(edge_points) do
                points[#points + 1] = p
            end
        end
    end
    if ShapeIntersector.triangleContainsPoint(triangle, ray.point) then
        points[#points + 1] = ray.point:clone()
    end

    local unique_points = ShapeIntersector.getUniquePoints(points)

    if #unique_points == 0 then
        return false, nil
    end
    return true, unique_points
end

---只检查三角形与射线是否相交
---@param triangle foundation.shape.Triangle 三角形
---@param ray foundation.shape.Ray 射线
---@return boolean
function ShapeIntersector.triangleHasIntersectionWithRay(triangle, ray)
    local edges = triangle:getEdges()

    for _, edge in ipairs(edges) do
        if ShapeIntersector.rayHasIntersectionWithSegment(ray, edge) then
            return true
        end
    end

    if ShapeIntersector.triangleContainsPoint(triangle, ray.point) then
        return true
    end

    return false
end

---检查三角形与圆的相交
---@param triangle foundation.shape.Triangle 三角形
---@param circle foundation.shape.Circle 圆
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.triangleToCircle(triangle, circle)
    local points = {}
    local edges = triangle:getEdges()
    for _, edge in ipairs(edges) do
        local success, edge_points = ShapeIntersector.circleToSegment(circle, edge)
        if success then
            for _, p in ipairs(edge_points) do
                points[#points + 1] = p
            end
        end
    end

    local vertices = triangle:getVertices()
    for _, vertex in ipairs(vertices) do
        if circle:contains(vertex) then
            points[#points + 1] = vertex
        end
    end

    if ShapeIntersector.triangleContainsPoint(triangle, circle.center) then
        points[#points + 1] = circle.center:clone()
    end

    local unique_points = ShapeIntersector.getUniquePoints(points)

    if #unique_points == 0 then
        return false, nil
    end
    return true, unique_points
end

---只检查三角形与圆是否相交
---@param triangle foundation.shape.Triangle 三角形
---@param circle foundation.shape.Circle 圆
---@return boolean
function ShapeIntersector.triangleHasIntersectionWithCircle(triangle, circle)
    if ShapeIntersector.triangleContainsPoint(triangle, circle.center) then
        return true
    end

    local edges = triangle:getEdges()
    for _, edge in ipairs(edges) do
        if ShapeIntersector.circleHasIntersectionWithSegment(circle, edge) then
            return true
        end
    end

    local vertices = triangle:getVertices()
    for _, vertex in ipairs(vertices) do
        if circle:contains(vertex) then
            return true
        end
    end

    return false
end

---检查两条线段的相交
---@param segment1 foundation.shape.Segment 第一条线段
---@param segment2 foundation.shape.Segment 第二条线段
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.segmentToSegment(segment1, segment2)
    local points = {}
    local a = segment1.point1
    local b = segment1.point2
    local c = segment2.point1
    local d = segment2.point2

    local denom = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
    if math.abs(denom) < 1e-10 then
        -- 平行或共线情况
        return false, nil
    end

    local t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denom
    local u = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denom

    if t >= 0 and t <= 1 and u >= 0 and u <= 1 then
        local x = a.x + t * (b.x - a.x)
        local y = a.y + t * (b.y - a.y)
        points[#points + 1] = Vector2.create(x, y)
    end

    if #points == 0 then
        return false, nil
    end
    return true, points
end

---检查两条线段是否相交
---@param segment1 foundation.shape.Segment 第一条线段
---@param segment2 foundation.shape.Segment 第二条线段
---@return boolean
function ShapeIntersector.segmentHasIntersectionWithSegment(segment1, segment2)
    local a = segment1.point1
    local b = segment1.point2
    local c = segment2.point1
    local d = segment2.point2

    local denom = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
    if math.abs(denom) < 1e-10 then
        -- 平行或共线情况
        return false
    end

    local t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denom
    local u = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denom

    return t >= 0 and t <= 1 and u >= 0 and u <= 1
end

---检查直线与线段的相交
---@param line foundation.shape.Line 直线
---@param segment foundation.shape.Segment 线段
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.lineToSegment(line, segment)
    local points = {}
    local a = line.point
    local b = line.point + line.direction
    local c = segment.point1
    local d = segment.point2

    local denom = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
    if math.abs(denom) < 1e-10 then
        return false, points
    end

    local t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denom
    local u = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denom

    if u >= 0 and u <= 1 then
        local x = a.x + t * (b.x - a.x)
        local y = a.y + t * (b.y - a.y)
        points[#points + 1] = Vector2.create(x, y)
    end

    if #points == 0 then
        return false, nil
    end
    return true, points
end

---检查直线是否与线段相交
---@param line foundation.shape.Line 直线
---@param segment foundation.shape.Segment 线段
---@return boolean
function ShapeIntersector.lineHasIntersectionWithSegment(line, segment)
    local a = line.point
    local b = line.point + line.direction
    local c = segment.point1
    local d = segment.point2

    local denom = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
    if math.abs(denom) < 1e-10 then
        return false
    end

    local u = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denom

    return u >= 0 and u <= 1
end

---检查射线与线段的相交
---@param ray foundation.shape.Ray 射线
---@param segment foundation.shape.Segment 线段
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.rayToSegment(ray, segment)
    local points = {}
    local a = ray.point
    local b = ray.point + ray.direction
    local c = segment.point1
    local d = segment.point2

    local denom = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
    if math.abs(denom) < 1e-10 then
        return false, nil
    end

    local t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denom
    local u = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denom

    if t >= 0 and u >= 0 and u <= 1 then
        local x = a.x + t * (b.x - a.x)
        local y = a.y + t * (b.y - a.y)
        points[#points + 1] = Vector2.create(x, y)
    end

    if #points == 0 then
        return false, nil
    end
    return true, points
end

---检查射线是否与线段相交
---@param ray foundation.shape.Ray 射线
---@param segment foundation.shape.Segment 线段
---@return boolean
function ShapeIntersector.rayHasIntersectionWithSegment(ray, segment)
    local a = ray.point
    local b = ray.point + ray.direction
    local c = segment.point1
    local d = segment.point2

    local denom = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
    if math.abs(denom) < 1e-10 then
        return false
    end

    local t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denom
    local u = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denom

    return t >= 0 and u >= 0 and u <= 1
end

---检查圆与线段的相交
---@param circle foundation.shape.Circle 圆
---@param segment foundation.shape.Segment 线段
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.circleToSegment(circle, segment)
    local points = {}
    local closest = segment:closestPoint(circle.center)

    if (closest - circle.center):length() <= circle.radius then
        local dir = segment.point2 - segment.point1
        local len = dir:length()
        if len == 0 then
            if (segment.point1 - circle.center):length() <= circle.radius then
                points[#points + 1] = segment.point1:clone()
            end

            if #points == 0 then
                return false, nil
            end
            return true, points
        end
        dir = dir / len
        local L = segment.point1 - circle.center
        local a = dir:dot(dir)
        local b = 2 * L:dot(dir)
        local c = L:dot(L) - circle.radius * circle.radius
        local discriminant = b * b - 4 * a * c
        if discriminant >= 0 then
            local sqrt_d = math.sqrt(discriminant)
            local t1 = (-b - sqrt_d) / (2 * a)
            local t2 = (-b + sqrt_d) / (2 * a)
            if t1 >= 0 and t1 <= len then
                points[#points + 1] = segment.point1 + dir * t1
            end
            if t2 >= 0 and t2 <= len and math.abs(t2 - t1) > 1e-10 then
                points[#points + 1] = segment.point1 + dir * t2
            end
        end
    end

    if #points == 0 then
        return false, nil
    end
    return true, points
end

---检查圆是否与线段相交
---@param circle foundation.shape.Circle 圆
---@param segment foundation.shape.Segment 线段
---@return boolean
function ShapeIntersector.circleHasIntersectionWithSegment(circle, segment)
    local closest = segment:closestPoint(circle.center)
    return (closest - circle.center):length() <= circle.radius
end

---检查直线与直线的相交
---@param line1 foundation.shape.Line 第一条直线
---@param line2 foundation.shape.Line 第二条直线
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.lineToLine(line1, line2)
    local points = {}
    local a = line1.point
    local b = line1.point + line1.direction
    local c = line2.point
    local d = line2.point + line2.direction

    local dir_cross = line1.direction:cross(line2.direction)
    if math.abs(dir_cross) < 1e-10 then
        local point_diff = line2.point - line1.point
        if math.abs(point_diff:cross(line1.direction)) < 1e-10 then
            points[#points + 1] = line1.point:clone()
            points[#points + 1] = line1:getPoint(1)
            return true, points
        else
            return false, nil
        end
    end

    local denom = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
    local t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denom
    local x = a.x + t * (b.x - a.x)
    local y = a.y + t * (b.y - a.y)
    points[#points + 1] = Vector2.create(x, y)

    return true, points
end

---检查直线是否与直线相交
---@param line1 foundation.shape.Line 第一条直线
---@param line2 foundation.shape.Line 第二条直线
---@return boolean
function ShapeIntersector.lineHasIntersectionWithLine(line1, line2)
    local dir_cross = line1.direction:cross(line2.direction)
    if math.abs(dir_cross) < 1e-10 then
        local point_diff = line2.point - line1.point
        return math.abs(point_diff:cross(line1.direction)) < 1e-10
    end
    return true
end

---检查直线与射线的相交
---@param line foundation.shape.Line 直线
---@param ray foundation.shape.Ray 射线
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.lineToRay(line, ray)
    local points = {}
    local a = line.point
    local b = line.point + line.direction
    local c = ray.point
    local d = ray.point + ray.direction

    local denom = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
    if math.abs(denom) < 1e-10 then
        return false, nil
    end

    local t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denom
    local u = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denom

    if u >= 0 then
        local x = a.x + t * (b.x - a.x)
        local y = a.y + t * (b.y - a.y)
        points[#points + 1] = Vector2.create(x, y)
    end

    if #points == 0 then
        return false, nil
    end
    return true, points
end

---检查直线是否与射线相交
---@param line foundation.shape.Line 直线
---@param ray foundation.shape.Ray 射线
---@return boolean
function ShapeIntersector.lineHasIntersectionWithRay(line, ray)
    local a = line.point
    local b = line.point + line.direction
    local c = ray.point
    local d = ray.point + ray.direction

    local denom = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
    if math.abs(denom) < 1e-10 then
        return false
    end

    local u = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denom

    return u >= 0
end

---检查直线与圆的相交
---@param line foundation.shape.Line 直线
---@param circle foundation.shape.Circle 圆
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.lineToCircle(line, circle)
    local points = {}
    local dir = line.direction
    local len = dir:length()
    if len == 0 then
        return false, nil
    end
    dir = dir / len
    local L = line.point - circle.center
    local a = dir:dot(dir)
    local b = 2 * L:dot(dir)
    local c = L:dot(L) - circle.radius * circle.radius
    local discriminant = b * b - 4 * a * c
    if discriminant >= 0 then
        local sqrt_d = math.sqrt(discriminant)
        local t1 = (-b - sqrt_d) / (2 * a)
        local t2 = (-b + sqrt_d) / (2 * a)
        points[#points + 1] = line.point + dir * t1
        if math.abs(t2 - t1) > 1e-10 then
            points[#points + 1] = line.point + dir * t2
        end
    end

    if #points == 0 then
        return false, nil
    end
    return true, points
end

---检查直线是否与圆相交
---@param line foundation.shape.Line 直线
---@param circle foundation.shape.Circle 圆
---@return boolean
function ShapeIntersector.lineHasIntersectionWithCircle(line, circle)
    local dir = line.direction
    local len = dir:length()
    if len == 0 then
        return false
    end
    dir = dir / len
    local L = line.point - circle.center
    local a = dir:dot(dir)
    local b = 2 * L:dot(dir)
    local c = L:dot(L) - circle.radius * circle.radius
    local discriminant = b * b - 4 * a * c
    return discriminant >= 0
end

---检查射线与射线的相交
---@param ray1 foundation.shape.Ray 第一条射线
---@param ray2 foundation.shape.Ray 第二条射线
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.rayToRay(ray1, ray2)
    local points = {}
    local a = ray1.point
    local b = ray1.point + ray1.direction
    local c = ray2.point
    local d = ray2.point + ray2.direction

    local denom = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
    if math.abs(denom) < 1e-10 then
        local dir_cross = ray1.direction:cross(ray2.direction)
        if math.abs(dir_cross) < 1e-10 then
            local point_diff = ray2.point - ray1.point
            local t = point_diff:dot(ray1.direction)
            if t >= 0 then
                points[#points + 1] = ray1.point + ray1.direction * t
            end
        end

        if #points == 0 then
            return false, nil
        end
        return true, points
    end

    local t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denom
    local u = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denom

    if t >= 0 and u >= 0 then
        local x = a.x + t * (b.x - a.x)
        local y = a.y + t * (b.y - a.y)
        points[#points + 1] = Vector2.create(x, y)
    end

    if #points == 0 then
        return false, nil
    end
    return true, points
end

---检查射线是否与射线相交
---@param ray1 foundation.shape.Ray 第一条射线
---@param ray2 foundation.shape.Ray 第二条射线
---@return boolean
function ShapeIntersector.rayHasIntersectionWithRay(ray1, ray2)
    local a = ray1.point
    local b = ray1.point + ray1.direction
    local c = ray2.point
    local d = ray2.point + ray2.direction

    local denom = (b.x - a.x) * (d.y - c.y) - (b.y - a.y) * (d.x - c.x)
    if math.abs(denom) < 1e-10 then
        local dir_cross = ray1.direction:cross(ray2.direction)
        if math.abs(dir_cross) < 1e-10 then
            local point_diff = ray2.point - ray1.point
            local t = point_diff:dot(ray1.direction)
            return t >= 0
        end
        return false
    end

    local t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denom
    local u = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denom

    return t >= 0 and u >= 0
end

---检查射线与圆的相交
---@param ray foundation.shape.Ray 射线
---@param circle foundation.shape.Circle 圆
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.rayToCircle(ray, circle)
    local points = {}
    local dir = ray.direction
    local len = dir:length()
    if len == 0 then
        return false, nil
    end
    dir = dir / len
    local L = ray.point - circle.center
    local a = dir:dot(dir)
    local b = 2 * L:dot(dir)
    local c = L:dot(L) - circle.radius * circle.radius
    local discriminant = b * b - 4 * a * c
    if discriminant >= 0 then
        local sqrt_d = math.sqrt(discriminant)
        local t1 = (-b - sqrt_d) / (2 * a)
        local t2 = (-b + sqrt_d) / (2 * a)
        if t1 >= 0 then
            points[#points + 1] = ray.point + dir * t1
        end
        if t2 >= 0 and math.abs(t2 - t1) > 1e-10 then
            points[#points + 1] = ray.point + dir * t2
        end
    end

    if #points == 0 then
        return false, nil
    end
    return true, points
end

---检查射线是否与圆相交
---@param ray foundation.shape.Ray 射线
---@param circle foundation.shape.Circle 圆
---@return boolean
function ShapeIntersector.rayHasIntersectionWithCircle(ray, circle)
    local dir = ray.direction
    local len = dir:length()
    if len == 0 then
        return false
    end
    dir = dir / len
    local L = ray.point - circle.center
    local a = dir:dot(dir)
    local b = 2 * L:dot(dir)
    local c = L:dot(L) - circle.radius * circle.radius
    local discriminant = b * b - 4 * a * c

    if discriminant < 0 then
        return false
    end

    local sqrt_d = math.sqrt(discriminant)
    local t1 = (-b - sqrt_d) / (2 * a)
    local t2 = (-b + sqrt_d) / (2 * a)

    return t1 >= 0 or t2 >= 0
end

---检查圆与圆的相交
---@param circle1 foundation.shape.Circle 第一个圆
---@param circle2 foundation.shape.Circle 第二个圆
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.circleToCircle(circle1, circle2)
    local points = {}
    local d = (circle1.center - circle2.center):length()
    if d <= circle1.radius + circle2.radius and d >= math.abs(circle1.radius - circle2.radius) then
        local a = (circle1.radius * circle1.radius - circle2.radius * circle2.radius + d * d) / (2 * d)
        local h = math.sqrt(circle1.radius * circle1.radius - a * a)
        local p2 = circle1.center + (circle2.center - circle1.center) * (a / d)
        local perp = Vector2.create(-(circle2.center.y - circle1.center.y), circle2.center.x - circle1.center.x):normalized() * h
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

---检查圆是否与圆相交
---@param circle1 foundation.shape.Circle 第一个圆
---@param circle2 foundation.shape.Circle 第二个圆
---@return boolean
function ShapeIntersector.circleHasIntersectionWithCircle(circle1, circle2)
    local d = (circle1.center - circle2.center):length()
    return d <= circle1.radius + circle2.radius and d >= math.abs(circle1.radius - circle2.radius)
end

---检查矩形与线段的相交
---@param rectangle foundation.shape.Rectangle 矩形
---@param segment foundation.shape.Segment 线段
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.rectangleToSegment(rectangle, segment)
    local points = {}
    local edges = rectangle:getEdges()
    for _, edge in ipairs(edges) do
        local success, edge_points = ShapeIntersector.segmentToSegment(segment, edge)
        if success then
            for _, p in ipairs(edge_points) do
                points[#points + 1] = p
            end
        end
    end
    if rectangle:contains(segment.point1) then
        points[#points + 1] = segment.point1:clone()
    end
    if segment.point1 ~= segment.point2 and rectangle:contains(segment.point2) then
        points[#points + 1] = segment.point2:clone()
    end

    local unique_points = ShapeIntersector.getUniquePoints(points)

    if #unique_points == 0 then
        return false, nil
    end
    return true, unique_points
end

---仅检查矩形是否与线段相交
---@param rectangle foundation.shape.Rectangle 矩形
---@param segment foundation.shape.Segment 线段
---@return boolean
function ShapeIntersector.rectangleHasIntersectionWithSegment(rectangle, segment)
    local edges = rectangle:getEdges()
    for _, edge in ipairs(edges) do
        if ShapeIntersector.segmentHasIntersectionWithSegment(edge, segment) then
            return true
        end
    end
    return rectangle:contains(segment.point1) or rectangle:contains(segment.point2)
end

---检查矩形与三角形的相交
---@param rectangle foundation.shape.Rectangle 矩形
---@param triangle foundation.shape.Triangle 三角形
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.rectangleToTriangle(rectangle, triangle)
    local points = {}
    local edges = rectangle:getEdges()
    for _, edge in ipairs(edges) do
        local success, edge_points = ShapeIntersector.triangleToSegment(triangle, edge)
        if success then
            for _, p in ipairs(edge_points) do
                points[#points + 1] = p
            end
        end
    end

    local vertices = triangle:getVertices()
    for _, vertex in ipairs(vertices) do
        if rectangle:contains(vertex) then
            points[#points + 1] = vertex
        end
    end

    local unique_points = ShapeIntersector.getUniquePoints(points)

    if #unique_points == 0 then
        return false, nil
    end
    return true, unique_points
end

---仅检查矩形是否与三角形相交
---@param rectangle foundation.shape.Rectangle 矩形
---@param triangle foundation.shape.Triangle 三角形
---@return boolean
function ShapeIntersector.rectangleHasIntersectionWithTriangle(rectangle, triangle)
    local edges = rectangle:getEdges()
    for _, edge in ipairs(edges) do
        if ShapeIntersector.triangleHasIntersectionWithSegment(triangle, edge) then
            return true
        end
    end
    return rectangle:contains(triangle.point1) or rectangle:contains(triangle.point2) or rectangle:contains(triangle.point3)
end

---检查矩形与直线的相交
---@param rectangle foundation.shape.Rectangle 矩形
---@param line foundation.shape.Line 直线
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.rectangleToLine(rectangle, line)
    local points = {}
    local edges = rectangle:getEdges()
    for _, edge in ipairs(edges) do
        local success, edge_points = ShapeIntersector.lineToSegment(line, edge)
        if success then
            for _, p in ipairs(edge_points) do
                points[#points + 1] = p
            end
        end
    end

    local unique_points = ShapeIntersector.getUniquePoints(points)

    if #unique_points == 0 then
        return false, nil
    end
    return true, unique_points
end

---仅检查矩形是否与直线相交
---@param rectangle foundation.shape.Rectangle 矩形
---@param line foundation.shape.Line 直线
---@return boolean
function ShapeIntersector.rectangleHasIntersectionWithLine(rectangle, line)
    local edges = rectangle:getEdges()
    for _, edge in ipairs(edges) do
        if ShapeIntersector.lineHasIntersectionWithSegment(line, edge) then
            return true
        end
    end
    return rectangle:contains(line.point)
end

---检查矩形与射线的相交
---@param rectangle foundation.shape.Rectangle 矩形
---@param ray foundation.shape.Ray 射线
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.rectangleToRay(rectangle, ray)
    local points = {}
    local edges = rectangle:getEdges()
    for _, edge in ipairs(edges) do
        local success, edge_points = ShapeIntersector.rayToSegment(ray, edge)
        if success then
            for _, p in ipairs(edge_points) do
                points[#points + 1] = p
            end
        end
    end

    if rectangle:contains(ray.point) then
        points[#points + 1] = ray.point:clone()
    end

    local unique_points = ShapeIntersector.getUniquePoints(points)

    if #unique_points == 0 then
        return false, nil
    end
    return true, unique_points
end

---仅检查矩形是否与射线相交
---@param rectangle foundation.shape.Rectangle 矩形
---@param ray foundation.shape.Ray 射线
---@return boolean
function ShapeIntersector.rectangleHasIntersectionWithRay(rectangle, ray)
    local edges = rectangle:getEdges()
    for _, edge in ipairs(edges) do
        if ShapeIntersector.rayHasIntersectionWithSegment(ray, edge) then
            return true
        end
    end
    return rectangle:contains(ray.point)
end

---检查矩形与圆的相交
---@param rectangle foundation.shape.Rectangle 矩形
---@param circle foundation.shape.Circle 圆
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.rectangleToCircle(rectangle, circle)
    local points = {}
    local edges = rectangle:getEdges()
    for _, edge in ipairs(edges) do
        local success, edge_points = ShapeIntersector.circleToSegment(circle, edge)
        if success then
            for _, p in ipairs(edge_points) do
                points[#points + 1] = p
            end
        end
    end

    local vertices = rectangle:getVertices()
    for _, vertex in ipairs(vertices) do
        if circle:contains(vertex) then
            points[#points + 1] = vertex
        end
    end

    if rectangle:contains(circle.center) then
        points[#points + 1] = circle.center:clone()
    end

    local unique_points = ShapeIntersector.getUniquePoints(points)

    if #unique_points == 0 then
        return false, nil
    end
    return true, unique_points
end

---仅检查矩形是否与圆相交
---@param rectangle foundation.shape.Rectangle 矩形
---@param circle foundation.shape.Circle 圆
---@return boolean
function ShapeIntersector.rectangleHasIntersectionWithCircle(rectangle, circle)
    if rectangle:contains(circle.center) then
        return true
    end

    local edges = rectangle:getEdges()
    for _, edge in ipairs(edges) do
        if ShapeIntersector.circleHasIntersectionWithSegment(circle, edge) then
            return true
        end
    end

    local vertices = rectangle:getVertices()
    for _, vertex in ipairs(vertices) do
        if circle:contains(vertex) then
            return true
        end
    end

    return false
end

---检查矩形与矩形的相交
---@param rectangle1 foundation.shape.Rectangle 第一个矩形
---@param rectangle2 foundation.shape.Rectangle 第二个矩形
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.rectangleToRectangle(rectangle1, rectangle2)
    local points = {}
    local edges1 = rectangle1:getEdges()
    local edges2 = rectangle2:getEdges()

    for _, edge1 in ipairs(edges1) do
        for _, edge2 in ipairs(edges2) do
            local success, edge_points = ShapeIntersector.segmentToSegment(edge1, edge2)
            if success then
                for _, p in ipairs(edge_points) do
                    points[#points + 1] = p
                end
            end
        end
    end

    local vertices1 = rectangle1:getVertices()
    for _, vertex in ipairs(vertices1) do
        if rectangle2:contains(vertex) then
            points[#points + 1] = vertex
        end
    end

    local vertices2 = rectangle2:getVertices()
    for _, vertex in ipairs(vertices2) do
        if rectangle1:contains(vertex) then
            points[#points + 1] = vertex
        end
    end

    local unique_points = ShapeIntersector.getUniquePoints(points)

    if #unique_points == 0 then
        return false, nil
    end
    return true, unique_points
end

---仅检查矩形是否与矩形相交
---@param rectangle1 foundation.shape.Rectangle 第一个矩形
---@param rectangle2 foundation.shape.Rectangle 第二个矩形
---@return boolean
function ShapeIntersector.rectangleHasIntersectionWithRectangle(rectangle1, rectangle2)
    local edges1 = rectangle1:getEdges()
    local edges2 = rectangle2:getEdges()

    for _, edge1 in ipairs(edges1) do
        for _, edge2 in ipairs(edges2) do
            if ShapeIntersector.segmentHasIntersectionWithSegment(edge1, edge2) then
                return true
            end
        end
    end

    local vertices1 = rectangle1:getVertices()
    for _, vertex in ipairs(vertices1) do
        if rectangle2:contains(vertex) then
            return true
        end
    end

    local vertices2 = rectangle2:getVertices()
    for _, vertex in ipairs(vertices2) do
        if rectangle1:contains(vertex) then
            return true
        end
    end

    return false
end

---检查扇形与线段的相交
---@param sector foundation.shape.Sector 扇形
---@param segment foundation.shape.Segment 线段
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.sectorToSegment(sector, segment)
    local points = {}
    local success, circle_points = ShapeIntersector.circleToSegment({ center = sector.center, radius = sector.radius }, segment)
    if success then
        for _, p in ipairs(circle_points) do
            if ShapeIntersector.sectorContainsPoint(sector, p) then
                points[#points + 1] = p
            end
        end
    end

    if ShapeIntersector.sectorContainsPoint(sector, segment.point1) then
        points[#points + 1] = segment.point1:clone()
    end
    if segment.point1 ~= segment.point2 and ShapeIntersector.sectorContainsPoint(sector, segment.point2) then
        points[#points + 1] = segment.point2:clone()
    end

    local unique_points = ShapeIntersector.getUniquePoints(points)

    if #unique_points == 0 then
        return false, nil
    end
    return true, unique_points
end

---仅检查扇形是否与线段相交
---@param sector foundation.shape.Sector 扇形
---@param segment foundation.shape.Segment 线段
---@return boolean
function ShapeIntersector.sectorHasIntersectionWithSegment(sector, segment)
    if ShapeIntersector.sectorContainsPoint(sector, segment.point1) or
            ShapeIntersector.sectorContainsPoint(sector, segment.point2) then
        return true
    end

    local success, circle_points = ShapeIntersector.circleToSegment({ center = sector.center, radius = sector.radius }, segment)
    if success then
        for _, p in ipairs(circle_points) do
            if ShapeIntersector.sectorContainsPoint(sector, p) then
                return true
            end
        end
    end

    return false
end

---检查扇形与直线的相交
---@param sector foundation.shape.Sector 扇形
---@param line foundation.shape.Line 直线
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.sectorToLine(sector, line)
    local points = {}
    local success, circle_points = ShapeIntersector.lineToCircle(line, { center = sector.center, radius = sector.radius })
    if success then
        for _, p in ipairs(circle_points) do
            if ShapeIntersector.sectorContainsPoint(sector, p) then
                points[#points + 1] = p
            end
        end
    end

    local unique_points = ShapeIntersector.getUniquePoints(points)

    if #unique_points == 0 then
        return false, nil
    end
    return true, unique_points
end

---仅检查扇形是否与直线相交
---@param sector foundation.shape.Sector 扇形
---@param line foundation.shape.Line 直线
---@return boolean
function ShapeIntersector.sectorHasIntersectionWithLine(sector, line)
    local success, circle_points = ShapeIntersector.lineToCircle(line, { center = sector.center, radius = sector.radius })
    if success then
        for _, p in ipairs(circle_points) do
            if ShapeIntersector.sectorContainsPoint(sector, p) then
                return true
            end
        end
    end
    return false
end

---检查扇形与射线的相交
---@param sector foundation.shape.Sector 扇形
---@param ray foundation.shape.Ray 射线
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.sectorToRay(sector, ray)
    local points = {}
    local success, circle_points = ShapeIntersector.rayToCircle(ray, { center = sector.center, radius = sector.radius })
    if success then
        for _, p in ipairs(circle_points) do
            if ShapeIntersector.sectorContainsPoint(sector, p) then
                points[#points + 1] = p
            end
        end
    end

    if ShapeIntersector.sectorContainsPoint(sector, ray.point) then
        points[#points + 1] = ray.point:clone()
    end

    local unique_points = ShapeIntersector.getUniquePoints(points)

    if #unique_points == 0 then
        return false, nil
    end
    return true, unique_points
end

---仅检查扇形是否与射线相交
---@param sector foundation.shape.Sector 扇形
---@param ray foundation.shape.Ray 射线
---@return boolean
function ShapeIntersector.sectorHasIntersectionWithRay(sector, ray)
    if ShapeIntersector.sectorContainsPoint(sector, ray.point) then
        return true
    end

    local success, circle_points = ShapeIntersector.rayToCircle(ray, { center = sector.center, radius = sector.radius })
    if success then
        for _, p in ipairs(circle_points) do
            if ShapeIntersector.sectorContainsPoint(sector, p) then
                return true
            end
        end
    end
    return false
end

---检查扇形与三角形的相交
---@param sector foundation.shape.Sector 扇形
---@param triangle foundation.shape.Triangle 三角形
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.sectorToTriangle(sector, triangle)
    local points = {}
    local edges = triangle:getEdges()
    for _, edge in ipairs(edges) do
        local success, edge_points = ShapeIntersector.sectorToSegment(sector, edge)
        if success then
            for _, p in ipairs(edge_points) do
                points[#points + 1] = p
            end
        end
    end

    local vertices = triangle:getVertices()
    for _, vertex in ipairs(vertices) do
        if ShapeIntersector.sectorContainsPoint(sector, vertex) then
            points[#points + 1] = vertex
        end
    end

    if ShapeIntersector.triangleContainsPoint(triangle, sector.center) then
        points[#points + 1] = sector.center:clone()
    end

    local unique_points = ShapeIntersector.getUniquePoints(points)

    if #unique_points == 0 then
        return false, nil
    end
    return true, unique_points
end

---仅检查扇形是否与三角形相交
---@param sector foundation.shape.Sector 扇形
---@param triangle foundation.shape.Triangle 三角形
---@return boolean
function ShapeIntersector.sectorHasIntersectionWithTriangle(sector, triangle)
    local edges = triangle:getEdges()
    for _, edge in ipairs(edges) do
        if ShapeIntersector.sectorHasIntersectionWithSegment(sector, edge) then
            return true
        end
    end

    local vertices = triangle:getVertices()
    for _, vertex in ipairs(vertices) do
        if ShapeIntersector.sectorContainsPoint(sector, vertex) then
            return true
        end
    end

    if ShapeIntersector.triangleContainsPoint(triangle, sector.center) then
        return true
    end

    return false
end

---检查扇形与圆的相交
---@param sector foundation.shape.Sector 扇形
---@param circle foundation.shape.Circle 圆
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.sectorToCircle(sector, circle)
    local points = {}
    local success, circle_points = ShapeIntersector.circleToCircle({ center = sector.center, radius = sector.radius }, circle)
    if success then
        for _, p in ipairs(circle_points) do
            if ShapeIntersector.sectorContainsPoint(sector, p) then
                points[#points + 1] = p
            end
        end
    end

    if ShapeIntersector.sectorContainsPoint(sector, circle.center) then
        points[#points + 1] = circle.center:clone()
    end

    local unique_points = ShapeIntersector.getUniquePoints(points)

    if #unique_points == 0 then
        return false, nil
    end
    return true, unique_points
end

---仅检查扇形是否与圆相交
---@param sector foundation.shape.Sector 扇形
---@param circle foundation.shape.Circle 圆
---@return boolean
function ShapeIntersector.sectorHasIntersectionWithCircle(sector, circle)
    if ShapeIntersector.sectorContainsPoint(sector, circle.center) then
        return true
    end

    local success, circle_points = ShapeIntersector.circleToCircle({ center = sector.center, radius = sector.radius }, circle)
    if success then
        for _, p in ipairs(circle_points) do
            if ShapeIntersector.sectorContainsPoint(sector, p) then
                return true
            end
        end
    end

    return false
end

---检查扇形与矩形的相交
---@param sector foundation.shape.Sector 扇形
---@param rectangle foundation.shape.Rectangle 矩形
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.sectorToRectangle(sector, rectangle)
    local points = {}
    local edges = rectangle:getEdges()
    for _, edge in ipairs(edges) do
        local success, edge_points = ShapeIntersector.sectorToSegment(sector, edge)
        if success then
            for _, p in ipairs(edge_points) do
                points[#points + 1] = p
            end
        end
    end

    local vertices = rectangle:getVertices()
    for _, vertex in ipairs(vertices) do
        if ShapeIntersector.sectorContainsPoint(sector, vertex) then
            points[#points + 1] = vertex
        end
    end

    if ShapeIntersector.rectangleContainsPoint(rectangle, sector.center) then
        points[#points + 1] = sector.center:clone()
    end

    local unique_points = ShapeIntersector.getUniquePoints(points)

    if #unique_points == 0 then
        return false, nil
    end
    return true, unique_points
end

---仅检查扇形是否与矩形相交
---@param sector foundation.shape.Sector 扇形
---@param rectangle foundation.shape.Rectangle 矩形
---@return boolean
function ShapeIntersector.sectorHasIntersectionWithRectangle(sector, rectangle)
    local edges = rectangle:getEdges()
    for _, edge in ipairs(edges) do
        if ShapeIntersector.sectorHasIntersectionWithSegment(sector, edge) then
            return true
        end
    end

    local vertices = rectangle:getVertices()
    for _, vertex in ipairs(vertices) do
        if ShapeIntersector.sectorContainsPoint(sector, vertex) then
            return true
        end
    end

    if ShapeIntersector.rectangleContainsPoint(rectangle, sector.center) then
        return true
    end

    return false
end

---检查扇形与扇形的相交
---@param sector1 foundation.shape.Sector 第一个扇形
---@param sector2 foundation.shape.Sector 第二个扇形
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.sectorToSector(sector1, sector2)
    local points = {}
    local success, circle_points = ShapeIntersector.circleToCircle(
            { center = sector1.center, radius = sector1.radius },
            { center = sector2.center, radius = sector2.radius }
    )
    if success then
        for _, p in ipairs(circle_points) do
            if ShapeIntersector.sectorContainsPoint(sector1, p) and ShapeIntersector.sectorContainsPoint(sector2, p) then
                points[#points + 1] = p
            end
        end
    end

    if ShapeIntersector.sectorContainsPoint(sector1, sector2.center) then
        points[#points + 1] = sector2.center:clone()
    end
    if ShapeIntersector.sectorContainsPoint(sector2, sector1.center) then
        points[#points + 1] = sector1.center:clone()
    end

    local unique_points = ShapeIntersector.getUniquePoints(points)

    if #unique_points == 0 then
        return false, nil
    end
    return true, unique_points
end

---仅检查扇形是否与扇形相交
---@param sector1 foundation.shape.Sector 第一个扇形
---@param sector2 foundation.shape.Sector 第二个扇形
---@return boolean
function ShapeIntersector.sectorHasIntersectionWithSector(sector1, sector2)
    if ShapeIntersector.sectorContainsPoint(sector1, sector2.center) or
            ShapeIntersector.sectorContainsPoint(sector2, sector1.center) then
        return true
    end

    local success, circle_points = ShapeIntersector.circleToCircle(
            { center = sector1.center, radius = sector1.radius },
            { center = sector2.center, radius = sector2.radius }
    )
    if success then
        for _, p in ipairs(circle_points) do
            if ShapeIntersector.sectorContainsPoint(sector1, p) and ShapeIntersector.sectorContainsPoint(sector2, p) then
                return true
            end
        end
    end

    return false
end

---@type table<string, table<string, fun(shape1: any, shape2: any): boolean, foundation.math.Vector2[] | nil>>
local intersectionMap = {
    ["foundation.shape.Sector"] = {
        ["foundation.shape.Segment"] = ShapeIntersector.sectorToSegment,
        ["foundation.shape.Line"] = ShapeIntersector.sectorToLine,
        ["foundation.shape.Ray"] = ShapeIntersector.sectorToRay,
        ["foundation.shape.Triangle"] = ShapeIntersector.sectorToTriangle,
        ["foundation.shape.Circle"] = ShapeIntersector.sectorToCircle,
        ["foundation.shape.Rectangle"] = ShapeIntersector.sectorToRectangle,
        ["foundation.shape.Sector"] = ShapeIntersector.sectorToSector,
    },
    ["foundation.shape.Rectangle"] = {
        ["foundation.shape.Triangle"] = ShapeIntersector.rectangleToTriangle,
        ["foundation.shape.Segment"] = ShapeIntersector.rectangleToSegment,
        ["foundation.shape.Line"] = ShapeIntersector.rectangleToLine,
        ["foundation.shape.Ray"] = ShapeIntersector.rectangleToRay,
        ["foundation.shape.Circle"] = ShapeIntersector.rectangleToCircle,
        ["foundation.shape.Rectangle"] = ShapeIntersector.rectangleToRectangle,
    },
    ["foundation.shape.Triangle"] = {
        ["foundation.shape.Segment"] = ShapeIntersector.triangleToSegment,
        ["foundation.shape.Triangle"] = ShapeIntersector.triangleToTriangle,
        ["foundation.shape.Line"] = ShapeIntersector.triangleToLine,
        ["foundation.shape.Ray"] = ShapeIntersector.triangleToRay,
        ["foundation.shape.Circle"] = ShapeIntersector.triangleToCircle,
    },
    ["foundation.shape.Line"] = {
        ["foundation.shape.Segment"] = ShapeIntersector.lineToSegment,
        ["foundation.shape.Line"] = ShapeIntersector.lineToLine,
        ["foundation.shape.Ray"] = ShapeIntersector.lineToRay,
        ["foundation.shape.Circle"] = ShapeIntersector.lineToCircle,
    },
    ["foundation.shape.Ray"] = {
        ["foundation.shape.Segment"] = ShapeIntersector.rayToSegment,
        ["foundation.shape.Ray"] = ShapeIntersector.rayToRay,
        ["foundation.shape.Circle"] = ShapeIntersector.rayToCircle,
    },
    ["foundation.shape.Circle"] = {
        ["foundation.shape.Segment"] = ShapeIntersector.circleToSegment,
        ["foundation.shape.Circle"] = ShapeIntersector.circleToCircle,
    },
    ["foundation.shape.Segment"] = {
        ["foundation.shape.Segment"] = ShapeIntersector.segmentToSegment,
    },
}

---检查与其他形状的相交
---@param shape1 any 第一个形状
---@param shape2 any 第二个形状
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.intersect(shape1, shape2)
    local type1 = shape1.__type
    local type2 = shape2.__type

    local intersectionFunc = intersectionMap[type1] and intersectionMap[type1][type2]
    if intersectionFunc then
        return intersectionFunc(shape1, shape2)
    end

    intersectionFunc = intersectionMap[type2] and intersectionMap[type2][type1]
    if intersectionFunc then
        return intersectionFunc(shape2, shape1)
    end

    return false, nil
end

---@type table<string, table<string, fun(shape1: any, shape2: any): boolean>>
local hasIntersectionMap = {
    ["foundation.shape.Sector"] = {
        ["foundation.shape.Segment"] = ShapeIntersector.sectorHasIntersectionWithSegment,
        ["foundation.shape.Line"] = ShapeIntersector.sectorHasIntersectionWithLine,
        ["foundation.shape.Ray"] = ShapeIntersector.sectorHasIntersectionWithRay,
        ["foundation.shape.Triangle"] = ShapeIntersector.sectorHasIntersectionWithTriangle,
        ["foundation.shape.Circle"] = ShapeIntersector.sectorHasIntersectionWithCircle,
        ["foundation.shape.Rectangle"] = ShapeIntersector.sectorHasIntersectionWithRectangle,
        ["foundation.shape.Sector"] = ShapeIntersector.sectorHasIntersectionWithSector,
    },
    ["foundation.shape.Rectangle"] = {
        ["foundation.shape.Triangle"] = ShapeIntersector.rectangleHasIntersectionWithTriangle,
        ["foundation.shape.Segment"] = ShapeIntersector.rectangleHasIntersectionWithSegment,
        ["foundation.shape.Line"] = ShapeIntersector.rectangleHasIntersectionWithLine,
        ["foundation.shape.Ray"] = ShapeIntersector.rectangleHasIntersectionWithRay,
        ["foundation.shape.Circle"] = ShapeIntersector.rectangleHasIntersectionWithCircle,
        ["foundation.shape.Rectangle"] = ShapeIntersector.rectangleHasIntersectionWithRectangle,
    },
    ["foundation.shape.Triangle"] = {
        ["foundation.shape.Segment"] = ShapeIntersector.triangleHasIntersectionWithSegment,
        ["foundation.shape.Triangle"] = ShapeIntersector.triangleHasIntersectionWithTriangle,
        ["foundation.shape.Line"] = ShapeIntersector.triangleHasIntersectionWithLine,
        ["foundation.shape.Ray"] = ShapeIntersector.triangleHasIntersectionWithRay,
        ["foundation.shape.Circle"] = ShapeIntersector.triangleHasIntersectionWithCircle,
    },
    ["foundation.shape.Line"] = {
        ["foundation.shape.Segment"] = ShapeIntersector.lineHasIntersectionWithSegment,
        ["foundation.shape.Line"] = ShapeIntersector.lineHasIntersectionWithLine,
        ["foundation.shape.Ray"] = ShapeIntersector.lineHasIntersectionWithRay,
        ["foundation.shape.Circle"] = ShapeIntersector.lineHasIntersectionWithCircle,
    },
    ["foundation.shape.Ray"] = {
        ["foundation.shape.Segment"] = ShapeIntersector.rayHasIntersectionWithSegment,
        ["foundation.shape.Ray"] = ShapeIntersector.rayHasIntersectionWithRay,
        ["foundation.shape.Circle"] = ShapeIntersector.rayHasIntersectionWithCircle,
    },
    ["foundation.shape.Circle"] = {
        ["foundation.shape.Segment"] = ShapeIntersector.circleHasIntersectionWithSegment,
        ["foundation.shape.Circle"] = ShapeIntersector.circleHasIntersectionWithCircle,
    },
    ["foundation.shape.Segment"] = {
        ["foundation.shape.Segment"] = ShapeIntersector.segmentHasIntersectionWithSegment,
    },
}

---只检查是否与其他形状相交
---@param shape1 any 第一个形状
---@param shape2 any 第二个形状
---@return boolean
function ShapeIntersector.hasIntersection(shape1, shape2)
    local type1 = shape1.__type
    local type2 = shape2.__type

    local intersectionFunc = hasIntersectionMap[type1] and hasIntersectionMap[type1][type2]
    if intersectionFunc then
        return intersectionFunc(shape1, shape2)
    end

    intersectionFunc = hasIntersectionMap[type2] and hasIntersectionMap[type2][type1]
    if intersectionFunc then
        return intersectionFunc(shape2, shape1)
    end

    return false
end

function ShapeIntersector.checkMissingIntersection()
    local keys = {}
    for k, _ in pairs(intersectionMap) do
        keys[#keys + 1] = k
    end

    local missing = {}
    for i = 1, #keys do
        local key1 = keys[i]
        for j = i, #keys do
            local key2 = keys[j]
            if not intersectionMap[key1][key2] and not intersectionMap[key2][key1] then
                missing[#missing + 1] = { key1, key2 }
            end
        end
    end

    if #missing > 0 then
        print("Missing intersections:")
        for _, pair in ipairs(missing) do
            print(pair[1], pair[2])
        end
    else
        print("No missing intersections found.")
    end

    local hasIntersectionKeys = {}
    for k, _ in pairs(hasIntersectionMap) do
        hasIntersectionKeys[#hasIntersectionKeys + 1] = k
    end

    local missingHasIntersection = {}
    for i = 1, #hasIntersectionKeys do
        local key1 = hasIntersectionKeys[i]
        for j = i, #hasIntersectionKeys do
            local key2 = hasIntersectionKeys[j]
            if not hasIntersectionMap[key1][key2] and not hasIntersectionMap[key2][key1] then
                missingHasIntersection[#missingHasIntersection + 1] = { key1, key2 }
            end
        end
    end

    if #missingHasIntersection > 0 then
        print("Missing hasIntersection:")
        for _, pair in ipairs(missingHasIntersection) do
            print(pair[1], pair[2])
        end
    else
        print("No missing hasIntersection found.")
    end
end

ShapeIntersector.checkMissingIntersection()

return ShapeIntersector