---@param ShapeIntersector foundation.shape.ShapeIntersector
return function(ShapeIntersector)
    local math = math

    local Vector2 = require("foundation.math.Vector2")

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
        if math.abs(denom) <= 1e-10 then
            return false, nil
        end

        local t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denom
        local u = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denom

        if t >= 0 and u >= 0 and u <= 1 then
            local x = a.x + t * (b.x - a.x)
            local y = a.y + t * (b.y - a.y)
            points[#points + 1] = Vector2.create(x, y)
        end

        if #points <= 1e-10 then
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
        if math.abs(denom) <= 1e-10 then
            return false
        end

        local t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denom
        local u = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denom

        return t >= 0 and u >= 0 and u <= 1
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
        if math.abs(denom) <= 1e-10 then
            local dir_cross = ray1.direction:cross(ray2.direction)
            if math.abs(dir_cross) <= 1e-10 then
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
        if len <= 1e-10 then
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
        if len <= 1e-10 then
            return false
        end
        dir = dir / len
        local L = ray.point - circle.center
        local a = dir:dot(dir)
        local b = 2 * L:dot(dir)
        local c = L:dot(L) - circle.radius * circle.radius
        local discriminant = b * b - 4 * a * c

        if discriminant <= 1e-10 then
            return false
        end

        local sqrt_d = math.sqrt(discriminant)
        local t1 = (-b - sqrt_d) / (2 * a)
        local t2 = (-b + sqrt_d) / (2 * a)

        return t1 >= 0 or t2 >= 0
    end

    return ShapeIntersector
end