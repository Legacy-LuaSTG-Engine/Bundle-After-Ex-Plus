---@param ShapeIntersector foundation.shape.ShapeIntersector
return function(ShapeIntersector)
    local math = math
    local require = require

    local Vector2 = require("foundation.math.Vector2")

    local Segment

    ---检查点是否在圆内或圆上
    ---@param circle foundation.shape.Circle 圆形
    ---@param point foundation.math.Vector2 点
    ---@return boolean
    function ShapeIntersector.circleContainsPoint(circle, point)
        return (point - circle.center):length() <= circle.radius + 1e-10
    end

    ---检查点是否在椭圆内（包括边界）
    ---@param ellipse foundation.shape.Ellipse 椭圆
    ---@param point foundation.math.Vector2 点
    ---@return boolean
    function ShapeIntersector.ellipseContainsPoint(ellipse, point)
        local baseAngle = ellipse.direction:angle()
        local cos_rotation = math.cos(-baseAngle)
        local sin_rotation = math.sin(-baseAngle)

        local dx = point.x - ellipse.center.x
        local dy = point.y - ellipse.center.y

        local x = cos_rotation * dx - sin_rotation * dy
        local y = sin_rotation * dx + cos_rotation * dy

        local value = (x * x) / (ellipse.rx * ellipse.rx) + (y * y) / (ellipse.ry * ellipse.ry)
        return math.abs(value) <= 1 + 1e-10
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
        return math.abs(x) <= hw + 1e-10 and math.abs(y) <= hh + 1e-10
    end

    ---检查点是否在扇形内（包括边界）
    ---@param sector foundation.shape.Sector 扇形
    ---@param point foundation.math.Vector2 点
    ---@return boolean
    function ShapeIntersector.sectorContainsPoint(sector, point)
---@diagnostic disable-next-line: param-type-mismatch
        local inCircle = ShapeIntersector.circleContainsPoint(sector, point)
        if not inCircle then
            return false
        end
        if math.abs(sector.range) >= 1 then
            return true
        end

        local range = sector.range * math.pi * 2
        local angle_begin
        if range > 0 then
            angle_begin = sector.direction:angle()
        else
            range = -range
            angle_begin = sector.direction:angle() - range
        end

        local vec = point - sector.center
        local vec_angle = vec:angle()
        vec_angle = vec_angle - 2 * math.pi * math.floor((vec_angle - angle_begin) / (2 * math.pi))
        return angle_begin <= vec_angle and vec_angle <= angle_begin + range
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

    ---检查点是否在多边形内
    ---@param polygon foundation.shape.Polygon 多边形
    ---@param point foundation.math.Vector2 点
    ---@return boolean
    function ShapeIntersector.polygonContainsPoint(polygon, point)
        if polygon.size < 3 then
            return false
        end

        Segment = Segment or require("foundation.shape.Segment")
        for i = 0, polygon.size - 1 do
            local j = (i + 1) % polygon.size
            local segment = Segment.create(polygon.points[i], polygon.points[j])
            if ShapeIntersector.segmentContainsPoint(segment, point) then
                return true
            end
        end

        local inside = false
        for i = 0, polygon.size - 1 do
            local j = (i + 1) % polygon.size

            local pi = polygon.points[i]
            local pj = polygon.points[j]

            if (pi.x - point.x) * (pi.x - point.x) + (pi.y - point.y) * (pi.y - point.y) < 1e-10 then
                return true
            end

            if ((pi.y > point.y) ~= (pj.y > point.y)) and
                    (point.x < (pj.x - pi.x) * (point.y - pi.y) / (pj.y - pi.y) + pi.x) then
                inside = not inside
            end
        end

        return inside
    end

    ---判断点是否在线段上
    ---@param segment foundation.shape.Segment 线段
    ---@param point foundation.math.Vector2 点
    ---@return boolean
    function ShapeIntersector.segmentContainsPoint(segment, point)
        local d1 = (point - segment.point1):length()
        local d2 = (point - segment.point2):length()
        local lineLen = (segment.point2 - segment.point1):length()

        return math.abs(d1 + d2 - lineLen) <= 1e-10
    end

    return ShapeIntersector
end