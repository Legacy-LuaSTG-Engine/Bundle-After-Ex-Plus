---@param ShapeIntersector foundation.shape.ShapeIntersector
return function(ShapeIntersector)
    local ipairs = ipairs

    ---贝塞尔曲线与线段相交
    ---@param bezier foundation.shape.BezierCurve
    ---@param segment foundation.shape.Segment
    ---@return boolean, foundation.math.Vector2[]|nil
    function ShapeIntersector.bezierCurveToSegment(bezier, segment)
        local segments = 20
        local bezierSegments = bezier:toSegments(segments)
        local intersectionPoints = {}
        local hasIntersection = false

        for _, seg in ipairs(bezierSegments) do
            local intersect, points = ShapeIntersector.segmentToSegment(seg, segment)
            if intersect and points then
                hasIntersection = true
                for _, p in ipairs(points) do
                    intersectionPoints[#intersectionPoints + 1] = p
                end
            end
        end

        if hasIntersection then
            return true, ShapeIntersector.getUniquePoints(intersectionPoints)
        else
            return false, nil
        end
    end

    ---贝塞尔曲线与线段相交检查
    ---@param bezier foundation.shape.BezierCurve
    ---@param segment foundation.shape.Segment
    ---@return boolean
    function ShapeIntersector.bezierCurveHasIntersectionWithSegment(bezier, segment)
        local segments = 20
        local bezierSegments = bezier:toSegments(segments)

        for _, seg in ipairs(bezierSegments) do
            if ShapeIntersector.segmentHasIntersectionWithSegment(seg, segment) then
                return true
            end
        end

        return false
    end

    ---贝塞尔曲线与线相交
    ---@param bezier foundation.shape.BezierCurve
    ---@param line foundation.shape.Line
    ---@return boolean, foundation.math.Vector2[]|nil
    function ShapeIntersector.bezierCurveToLine(bezier, line)
        local segments = 20
        local bezierSegments = bezier:toSegments(segments)
        local intersectionPoints = {}
        local hasIntersection = false

        for _, seg in ipairs(bezierSegments) do
            local intersect, points = ShapeIntersector.lineToSegment(line, seg)
            if intersect and points then
                hasIntersection = true
                for _, p in ipairs(points) do
                    intersectionPoints[#intersectionPoints + 1] = p
                end
            end
        end

        if hasIntersection then
            return true, ShapeIntersector.getUniquePoints(intersectionPoints)
        else
            return false, nil
        end
    end

    ---贝塞尔曲线与线相交检查
    ---@param bezier foundation.shape.BezierCurve
    ---@param line foundation.shape.Line
    ---@return boolean
    function ShapeIntersector.bezierCurveHasIntersectionWithLine(bezier, line)
        local segments = 20
        local bezierSegments = bezier:toSegments(segments)

        for _, seg in ipairs(bezierSegments) do
            if ShapeIntersector.lineHasIntersectionWithSegment(line, seg) then
                return true
            end
        end

        return false
    end

    ---贝塞尔曲线与射线相交
    ---@param bezier foundation.shape.BezierCurve
    ---@param ray foundation.shape.Ray
    ---@return boolean, foundation.math.Vector2[]|nil
    function ShapeIntersector.bezierCurveToRay(bezier, ray)
        local segments = 20
        local bezierSegments = bezier:toSegments(segments)
        local intersectionPoints = {}
        local hasIntersection = false

        for _, seg in ipairs(bezierSegments) do
            local intersect, points = ShapeIntersector.rayToSegment(ray, seg)
            if intersect and points then
                hasIntersection = true
                for _, p in ipairs(points) do
                    intersectionPoints[#intersectionPoints + 1] = p
                end
            end
        end

        if hasIntersection then
            return true, ShapeIntersector.getUniquePoints(intersectionPoints)
        else
            return false, nil
        end
    end

    ---贝塞尔曲线与射线相交检查
    ---@param bezier foundation.shape.BezierCurve
    ---@param ray foundation.shape.Ray
    ---@return boolean
    function ShapeIntersector.bezierCurveHasIntersectionWithRay(bezier, ray)
        local segments = 20
        local bezierSegments = bezier:toSegments(segments)

        for _, seg in ipairs(bezierSegments) do
            if ShapeIntersector.rayHasIntersectionWithSegment(ray, seg) then
                return true
            end
        end

        return false
    end

    ---贝塞尔曲线与圆相交
    ---@param bezier foundation.shape.BezierCurve
    ---@param circle foundation.shape.Circle
    ---@return boolean, foundation.math.Vector2[]|nil
    function ShapeIntersector.bezierCurveToCircle(bezier, circle)
        local segments = 20
        local bezierSegments = bezier:toSegments(segments)
        local intersectionPoints = {}
        local hasIntersection = false

        for _, seg in ipairs(bezierSegments) do
            local intersect, points = ShapeIntersector.circleToSegment(circle, seg)
            if intersect and points then
                hasIntersection = true
                for _, p in ipairs(points) do
                    intersectionPoints[#intersectionPoints + 1] = p
                end
            end
        end

        if hasIntersection then
            return true, ShapeIntersector.getUniquePoints(intersectionPoints)
        else
            return false, nil
        end
    end

    ---贝塞尔曲线与圆相交检查
    ---@param bezier foundation.shape.BezierCurve
    ---@param circle foundation.shape.Circle
    ---@return boolean
    function ShapeIntersector.bezierCurveHasIntersectionWithCircle(bezier, circle)
        local segments = 20
        local bezierSegments = bezier:toSegments(segments)

        for _, seg in ipairs(bezierSegments) do
            if ShapeIntersector.circleHasIntersectionWithSegment(circle, seg) then
                return true
            end
        end

        return false
    end

    ---贝塞尔曲线与矩形相交
    ---@param bezier foundation.shape.BezierCurve
    ---@param rectangle foundation.shape.Rectangle
    ---@return boolean, foundation.math.Vector2[]|nil
    function ShapeIntersector.bezierCurveToRectangle(bezier, rectangle)
        local segments = 20
        local bezierSegments = bezier:toSegments(segments)
        local intersectionPoints = {}
        local hasIntersection = false

        for _, seg in ipairs(bezierSegments) do
            local intersect, points = ShapeIntersector.rectangleToSegment(rectangle, seg)
            if intersect and points then
                hasIntersection = true
                for _, p in ipairs(points) do
                    intersectionPoints[#intersectionPoints + 1] = p
                end
            end
        end

        if hasIntersection then
            return true, ShapeIntersector.getUniquePoints(intersectionPoints)
        else
            return false, nil
        end
    end

    ---贝塞尔曲线与矩形相交检查
    ---@param bezier foundation.shape.BezierCurve
    ---@param rectangle foundation.shape.Rectangle
    ---@return boolean
    function ShapeIntersector.bezierCurveHasIntersectionWithRectangle(bezier, rectangle)
        local segments = 20
        local bezierSegments = bezier:toSegments(segments)

        for _, seg in ipairs(bezierSegments) do
            if ShapeIntersector.rectangleHasIntersectionWithSegment(rectangle, seg) then
                return true
            end
        end

        return false
    end

    ---贝塞尔曲线与三角形相交
    ---@param bezier foundation.shape.BezierCurve
    ---@param triangle foundation.shape.Triangle
    ---@return boolean, foundation.math.Vector2[]|nil
    function ShapeIntersector.bezierCurveToTriangle(bezier, triangle)
        local segments = 20
        local bezierSegments = bezier:toSegments(segments)
        local intersectionPoints = {}
        local hasIntersection = false

        for _, seg in ipairs(bezierSegments) do
            local intersect, points = ShapeIntersector.triangleToSegment(triangle, seg)
            if intersect and points then
                hasIntersection = true
                for _, p in ipairs(points) do
                    intersectionPoints[#intersectionPoints + 1] = p
                end
            end
        end

        if hasIntersection then
            return true, ShapeIntersector.getUniquePoints(intersectionPoints)
        else
            return false, nil
        end
    end

    ---贝塞尔曲线与三角形相交检查
    ---@param bezier foundation.shape.BezierCurve
    ---@param triangle foundation.shape.Triangle
    ---@return boolean
    function ShapeIntersector.bezierCurveHasIntersectionWithTriangle(bezier, triangle)
        local segments = 20
        local bezierSegments = bezier:toSegments(segments)

        for _, seg in ipairs(bezierSegments) do
            if ShapeIntersector.triangleHasIntersectionWithSegment(triangle, seg) then
                return true
            end
        end

        return false
    end

    ---贝塞尔曲线与多边形相交
    ---@param bezier foundation.shape.BezierCurve
    ---@param polygon foundation.shape.Polygon
    ---@return boolean, foundation.math.Vector2[]|nil
    function ShapeIntersector.bezierCurveToPolygon(bezier, polygon)
        local segments = 20
        local bezierSegments = bezier:toSegments(segments)
        local intersectionPoints = {}
        local hasIntersection = false

        for _, seg in ipairs(bezierSegments) do
            local intersect, points = ShapeIntersector.polygonToSegment(polygon, seg)
            if intersect and points then
                hasIntersection = true
                for _, p in ipairs(points) do
                    intersectionPoints[#intersectionPoints + 1] = p
                end
            end
        end

        if hasIntersection then
            return true, ShapeIntersector.getUniquePoints(intersectionPoints)
        else
            return false, nil
        end
    end

    ---贝塞尔曲线与多边形相交检查
    ---@param bezier foundation.shape.BezierCurve
    ---@param polygon foundation.shape.Polygon
    ---@return boolean
    function ShapeIntersector.bezierCurveHasIntersectionWithPolygon(bezier, polygon)
        local segments = 20
        local bezierSegments = bezier:toSegments(segments)

        for _, seg in ipairs(bezierSegments) do
            if ShapeIntersector.polygonHasIntersectionWithSegment(polygon, seg) then
                return true
            end
        end

        return false
    end

    ---贝塞尔曲线与扇形相交
    ---@param bezier foundation.shape.BezierCurve
    ---@param sector foundation.shape.Sector
    ---@return boolean, foundation.math.Vector2[]|nil
    function ShapeIntersector.bezierCurveToSector(bezier, sector)
        local segments = 20
        local bezierSegments = bezier:toSegments(segments)
        local intersectionPoints = {}
        local hasIntersection = false

        for _, seg in ipairs(bezierSegments) do
            local intersect, points = ShapeIntersector.sectorToSegment(sector, seg)
            if intersect and points then
                hasIntersection = true
                for _, p in ipairs(points) do
                    intersectionPoints[#intersectionPoints + 1] = p
                end
            end
        end

        if hasIntersection then
            return true, ShapeIntersector.getUniquePoints(intersectionPoints)
        else
            return false, nil
        end
    end

    ---贝塞尔曲线与扇形相交检查
    ---@param bezier foundation.shape.BezierCurve
    ---@param sector foundation.shape.Sector
    ---@return boolean
    function ShapeIntersector.bezierCurveHasIntersectionWithSector(bezier, sector)
        local segments = 20
        local bezierSegments = bezier:toSegments(segments)

        for _, seg in ipairs(bezierSegments) do
            if ShapeIntersector.sectorHasIntersectionWithSegment(sector, seg) then
                return true
            end
        end

        return false
    end

    ---贝塞尔曲线与椭圆相交
    ---@param bezier foundation.shape.BezierCurve
    ---@param ellipse foundation.shape.Ellipse
    ---@return boolean, foundation.math.Vector2[]|nil
    function ShapeIntersector.bezierCurveToEllipse(bezier, ellipse)
        local segments = 20
        local bezierSegments = bezier:toSegments(segments)
        local intersectionPoints = {}
        local hasIntersection = false

        for _, seg in ipairs(bezierSegments) do
            local intersect, points = ShapeIntersector.ellipseToSegment(ellipse, seg)
            if intersect and points then
                hasIntersection = true
                for _, p in ipairs(points) do
                    intersectionPoints[#intersectionPoints + 1] = p
                end
            end
        end

        if hasIntersection then
            return true, ShapeIntersector.getUniquePoints(intersectionPoints)
        else
            return false, nil
        end
    end

    ---贝塞尔曲线与椭圆相交检查
    ---@param bezier foundation.shape.BezierCurve
    ---@param ellipse foundation.shape.Ellipse
    ---@return boolean
    function ShapeIntersector.bezierCurveHasIntersectionWithEllipse(bezier, ellipse)
        local segments = 20
        local bezierSegments = bezier:toSegments(segments)

        for _, seg in ipairs(bezierSegments) do
            if ShapeIntersector.ellipseHasIntersectionWithSegment(ellipse, seg) then
                return true
            end
        end

        return false
    end


    ---贝塞尔曲线与贝塞尔曲线相交
    ---@param bezier1 foundation.shape.BezierCurve
    ---@param bezier2 foundation.shape.BezierCurve
    ---@return boolean, foundation.math.Vector2[]|nil
    function ShapeIntersector.bezierCurveToBezierCurve(bezier1, bezier2)
        local segments = 20
        local bezier1Segments = bezier1:toSegments(segments)
        local bezier2Segments = bezier2:toSegments(segments)
        local intersectionPoints = {}
        local hasIntersection = false

        for _, seg1 in ipairs(bezier1Segments) do
            for _, seg2 in ipairs(bezier2Segments) do
                local intersect, points = ShapeIntersector.segmentToSegment(seg1, seg2)
                if intersect and points then
                    hasIntersection = true
                    for _, p in ipairs(points) do
                        intersectionPoints[#intersectionPoints + 1] = p
                    end
                end
            end
        end

        if hasIntersection then
            return true, ShapeIntersector.getUniquePoints(intersectionPoints)
        else
            return false, nil
        end
    end

    ---贝塞尔曲线与贝塞尔曲线相交检查
    ---@param bezier1 foundation.shape.BezierCurve
    ---@param bezier2 foundation.shape.BezierCurve
    ---@return boolean
    function ShapeIntersector.bezierCurveHasIntersectionWithBezierCurve(bezier1, bezier2)
        local segments = 20
        local bezier1Segments = bezier1:toSegments(segments)
        local bezier2Segments = bezier2:toSegments(segments)

        for _, seg1 in ipairs(bezier1Segments) do
            for _, seg2 in ipairs(bezier2Segments) do
                if ShapeIntersector.segmentHasIntersectionWithSegment(seg1, seg2) then
                    return true
                end
            end
        end

        return false
    end
end