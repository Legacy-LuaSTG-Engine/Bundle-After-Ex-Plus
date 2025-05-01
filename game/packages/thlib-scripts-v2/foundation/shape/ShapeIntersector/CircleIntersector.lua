---@param ShapeIntersector foundation.shape.ShapeIntersector
return function(ShapeIntersector)
    local math = math

    local Vector2 = require("foundation.math.Vector2")

    ---检查圆与线段的相交
    ---@param circle foundation.shape.Circle 圆
    ---@param segment foundation.shape.Segment 线段
    ---@return boolean, foundation.math.Vector2[] | nil
    function ShapeIntersector.circleToSegment(circle, segment)
        local points = {}
        local dir = segment.point2 - segment.point1
        local len = dir:length()

        if len <= 1e-10 then
            if ShapeIntersector.circleContainsPoint(circle, segment.point1) then
                return true, { segment.point1:clone() }
            end
            return false, nil
        end

        dir = dir / len

        local closest = segment:closestPoint(circle.center)
        local dist = (closest - circle.center):length()
        if dist > circle.radius + 1e-10 then
            return false, nil
        end

        local vector_to_start = segment.point1 - circle.center
        local b = 2 * vector_to_start:dot(dir)
        local c = vector_to_start:dot(vector_to_start) - circle.radius * circle.radius
        local discriminant = b * b - 4 * c

        if discriminant >= -1e-10 then
            local sqrt_d = math.sqrt(math.max(discriminant, 0))
            local t1 = (-b - sqrt_d) / 2
            local t2 = (-b + sqrt_d) / 2

            if t1 >= 0 and t1 <= len then
                points[#points + 1] = segment.point1 + dir * t1
            end
            if t2 >= 0 and t2 <= len and discriminant > 1e-10 then
                points[#points + 1] = segment.point1 + dir * t2
            end
        end

        if #points <= 1e-10 then
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
        return (closest - circle.center):length() <= circle.radius + 1e-10
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

        if #points <= 1e-10 then
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

    return ShapeIntersector
end