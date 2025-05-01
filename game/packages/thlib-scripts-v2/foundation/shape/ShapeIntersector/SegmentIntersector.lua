---@param ShapeIntersector foundation.shape.ShapeIntersector
return function(ShapeIntersector)
    local math = math

    local Vector2 = require("foundation.math.Vector2")

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
        if math.abs(denom) <= 1e-10 then
            return false, nil
        end

        local t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denom
        local u = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denom

        if t >= 0 and t <= 1 and u >= 0 and u <= 1 then
            local x = a.x + t * (b.x - a.x)
            local y = a.y + t * (b.y - a.y)
            points[#points + 1] = Vector2.create(x, y)
        end

        if #points <= 1e-10 then
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
        if math.abs(denom) <= 1e-10 then
            return false
        end

        local t = ((c.x - a.x) * (d.y - c.y) - (c.y - a.y) * (d.x - c.x)) / denom
        local u = ((c.x - a.x) * (b.y - a.y) - (c.y - a.y) * (b.x - a.x)) / denom

        return t >= 0 and t <= 1 and u >= 0 and u <= 1
    end

    return ShapeIntersector
end