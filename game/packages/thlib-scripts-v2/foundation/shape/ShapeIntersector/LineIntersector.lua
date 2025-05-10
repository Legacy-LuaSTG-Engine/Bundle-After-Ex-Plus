---@param ShapeIntersector foundation.shape.ShapeIntersector
return function(ShapeIntersector)
    local math = math

    local Vector2 = require("foundation.math.Vector2")

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
        if math.abs(denom) <= 1e-10 then
            return false, nil
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
        if math.abs(denom) <= 1e-10 then
            return false
        end

        local u = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denom

        return u >= 0 and u <= 1
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
        if math.abs(dir_cross) <= 1e-10 then
            local point_diff = line2.point - line1.point
            if math.abs(point_diff:cross(line1.direction)) <= 1e-10 then
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
        if math.abs(dir_cross) <= 1e-10 then
            local point_diff = line2.point - line1.point
            return math.abs(point_diff:cross(line1.direction)) <= 1e-10
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
        if math.abs(denom) <= 1e-10 then
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
        if math.abs(denom) <= 1e-10 then
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
        if len <= 1e-10 then
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
        if len <= 1e-10 then
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
    return ShapeIntersector
end