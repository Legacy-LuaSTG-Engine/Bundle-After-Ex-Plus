---@param ShapeIntersector foundation.shape.ShapeIntersector
return function(ShapeIntersector)
    local math = math

    local ipairs = ipairs
    local require = require

    local Segment

    ---检查扇形与线段的相交
    ---@param sector foundation.shape.Sector 扇形
    ---@param segment foundation.shape.Segment 线段
    ---@return boolean, foundation.math.Vector2[] | nil
    function ShapeIntersector.sectorToSegment(sector, segment)
        Segment = Segment or require("foundation.shape.Segment")
        local points = {}
        if math.abs(sector.range) >= 1 then
            return ShapeIntersector.circleToSegment(sector, segment)
        end
        local success, circle_points = ShapeIntersector.circleToSegment(sector, segment)
        if success then
            local n = 0
            for _, p in ipairs(circle_points) do
                if ShapeIntersector.sectorContainsPoint(sector, p) then
                    n = n + 1
                    points[#points + 1] = p
                end
            end
        end
        local startDir = sector.direction
        local endDir = sector.direction:rotated(sector.range * 2 * math.pi)
        local startPoint = sector.center + startDir * sector.radius
        local endPoint = sector.center + endDir * sector.radius
        local startSegment = Segment.create(sector.center, startPoint)
        local endSegment = Segment.create(sector.center, endPoint)
        local success1, edge_points1 = ShapeIntersector.segmentToSegment(startSegment, segment)
        if success1 then
            for _, p in ipairs(edge_points1) do
                points[#points + 1] = p
            end
        end
        local success2, edge_points2 = ShapeIntersector.segmentToSegment(endSegment, segment)
        if success2 then
            for _, p in ipairs(edge_points2) do
                points[#points + 1] = p
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
        Segment = Segment or require("foundation.shape.Segment")
        if math.abs(sector.range) >= 1 then
            return ShapeIntersector.circleHasIntersectionWithSegment(sector, segment)
        end
        if ShapeIntersector.sectorContainsPoint(sector, segment.point1) or
                ShapeIntersector.sectorContainsPoint(sector, segment.point2) then
            return true
        end
        local success, circle_points = ShapeIntersector.circleToSegment(sector, segment)
        if success then
            for _, p in ipairs(circle_points) do
                if ShapeIntersector.sectorContainsPoint(sector, p) then
                    return true
                end
            end
        end
        local startDir = sector.direction
        local endDir = sector.direction:rotated(sector.range * 2 * math.pi)
        local startPoint = sector.center + startDir * sector.radius
        local endPoint = sector.center + endDir * sector.radius
        local startSegment = Segment.create(sector.center, startPoint)
        local endSegment = Segment.create(sector.center, endPoint)
        if ShapeIntersector.segmentHasIntersectionWithSegment(startSegment, segment) or
                ShapeIntersector.segmentHasIntersectionWithSegment(endSegment, segment) then
            return true
        end
        return false
    end

    ---检查扇形与直线的相交
    ---@param sector foundation.shape.Sector 扇形
    ---@param line foundation.shape.Line 直线
    ---@return boolean, foundation.math.Vector2[] | nil
    function ShapeIntersector.sectorToLine(sector, line)
        Segment = Segment or require("foundation.shape.Segment")
        local points = {}
        if math.abs(sector.range) >= 1 then
            return ShapeIntersector.lineToCircle(line, sector)
        end
        local success, circle_points = ShapeIntersector.lineToCircle(line, sector)
        if success then
            for _, p in ipairs(circle_points) do
                if ShapeIntersector.sectorContainsPoint(sector, p) then
                    points[#points + 1] = p
                end
            end
        end
        local startDir = sector.direction
        local endDir = sector.direction:rotated(sector.range * 2 * math.pi)
        local startPoint = sector.center + startDir * sector.radius
        local endPoint = sector.center + endDir * sector.radius
        local startSegment = Segment.create(sector.center, startPoint)
        local endSegment = Segment.create(sector.center, endPoint)
        local success1, edge_points1 = ShapeIntersector.lineToSegment(line, startSegment)
        if success1 then
            for _, p in ipairs(edge_points1) do
                points[#points + 1] = p
            end
        end
        local success2, edge_points2 = ShapeIntersector.lineToSegment(line, endSegment)
        if success2 then
            for _, p in ipairs(edge_points2) do
                points[#points + 1] = p
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
        Segment = Segment or require("foundation.shape.Segment")
        if math.abs(sector.range) >= 1 then
            return ShapeIntersector.lineHasIntersectionWithCircle(line, sector)
        end
        local success, circle_points = ShapeIntersector.lineToCircle(line, sector)
        if success then
            for _, p in ipairs(circle_points) do
                if ShapeIntersector.sectorContainsPoint(sector, p) then
                    return true
                end
            end
        end
        local startDir = sector.direction
        local endDir = sector.direction:rotated(sector.range * 2 * math.pi)
        local startPoint = sector.center + startDir * sector.radius
        local endPoint = sector.center + endDir * sector.radius
        local startSegment = Segment.create(sector.center, startPoint)
        local endSegment = Segment.create(sector.center, endPoint)
        if ShapeIntersector.lineHasIntersectionWithSegment(line, startSegment) or
                ShapeIntersector.lineHasIntersectionWithSegment(line, endSegment) then
            return true
        end
        return false
    end

    ---检查扇形与射线的相交
    ---@param sector foundation.shape.Sector 扇形
    ---@param ray foundation.shape.Ray 射线
    ---@return boolean, foundation.math.Vector2[] | nil
    function ShapeIntersector.sectorToRay(sector, ray)
        Segment = Segment or require("foundation.shape.Segment")
        local points = {}
        if math.abs(sector.range) >= 1 then
            return ShapeIntersector.rayToCircle(ray, sector)
        end
        local success, circle_points = ShapeIntersector.rayToCircle(ray, sector)
        if success then
            for _, p in ipairs(circle_points) do
                if ShapeIntersector.sectorContainsPoint(sector, p) then
                    points[#points + 1] = p
                end
            end
        end
        local startDir = sector.direction
        local endDir = sector.direction:rotated(sector.range * 2 * math.pi)
        local startPoint = sector.center + startDir * sector.radius
        local endPoint = sector.center + endDir * sector.radius
        local startSegment = Segment.create(sector.center, startPoint)
        local endSegment = Segment.create(sector.center, endPoint)
        local success1, edge_points1 = ShapeIntersector.rayToSegment(ray, startSegment)
        if success1 then
            for _, p in ipairs(edge_points1) do
                points[#points + 1] = p
            end
        end
        local success2, edge_points2 = ShapeIntersector.rayToSegment(ray, endSegment)
        if success2 then
            for _, p in ipairs(edge_points2) do
                points[#points + 1] = p
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
        Segment = Segment or require("foundation.shape.Segment")
        if math.abs(sector.range) >= 1 then
            return ShapeIntersector.rayHasIntersectionWithCircle(ray, sector)
        end
        if ShapeIntersector.sectorContainsPoint(sector, ray.point) then
            return true
        end
        local success, circle_points = ShapeIntersector.rayToCircle(ray, sector)
        if success then
            for _, p in ipairs(circle_points) do
                if ShapeIntersector.sectorContainsPoint(sector, p) then
                    return true
                end
            end
        end
        local startDir = sector.direction
        local endDir = sector.direction:rotated(sector.range * 2 * math.pi)
        local startPoint = sector.center + startDir * sector.radius
        local endPoint = sector.center + endDir * sector.radius
        local startSegment = Segment.create(sector.center, startPoint)
        local endSegment = Segment.create(sector.center, endPoint)
        if ShapeIntersector.rayHasIntersectionWithSegment(ray, startSegment) or
                ShapeIntersector.rayHasIntersectionWithSegment(ray, endSegment) then
            return true
        end
        return false
    end

    ---检查扇形与三角形的相交
    ---@param sector foundation.shape.Sector 扇形
    ---@param triangle foundation.shape.Triangle 三角形
    ---@return boolean, foundation.math.Vector2[] | nil
    function ShapeIntersector.sectorToTriangle(sector, triangle)
        local points = {}
        if math.abs(sector.range) >= 1 then
            return ShapeIntersector.triangleToCircle(triangle, sector)
        end
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
        if math.abs(sector.range) >= 1 then
            return ShapeIntersector.triangleHasIntersectionWithCircle(triangle, sector)
        end
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
        Segment = Segment or require("foundation.shape.Segment")
        local points = {}
        if math.abs(sector.range) >= 1 then
            return ShapeIntersector.circleToCircle(sector, circle)
        end
        local success, circle_points = ShapeIntersector.circleToCircle(sector, circle)
        if success then
            for _, p in ipairs(circle_points) do
                if ShapeIntersector.sectorContainsPoint(sector, p) then
                    points[#points + 1] = p
                end
            end
        end
        local startDir = sector.direction
        local endDir = sector.direction:rotated(sector.range * 2 * math.pi)
        local startPoint = sector.center + startDir * sector.radius
        local endPoint = sector.center + endDir * sector.radius
        local startSegment = Segment.create(sector.center, startPoint)
        local endSegment = Segment.create(sector.center, endPoint)
        local success1, edge_points1 = ShapeIntersector.circleToSegment(circle, startSegment)
        if success1 then
            for _, p in ipairs(edge_points1) do
                points[#points + 1] = p
            end
        end
        local success2, edge_points2 = ShapeIntersector.circleToSegment(circle, endSegment)
        if success2 then
            for _, p in ipairs(edge_points2) do
                points[#points + 1] = p
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
        Segment = Segment or require("foundation.shape.Segment")
        if math.abs(sector.range) >= 1 then
            return ShapeIntersector.circleHasIntersectionWithCircle(sector, circle)
        end
        if ShapeIntersector.sectorContainsPoint(sector, circle.center) then
            return true
        end
        local success, circle_points = ShapeIntersector.circleToCircle(sector, circle)
        if success then
            for _, p in ipairs(circle_points) do
                if ShapeIntersector.sectorContainsPoint(sector, p) then
                    return true
                end
            end
        end
        local startDir = sector.direction
        local endDir = sector.direction:rotated(sector.range * 2 * math.pi)
        local startPoint = sector.center + startDir * sector.radius
        local endPoint = sector.center + endDir * sector.radius
        local startSegment = Segment.create(sector.center, startPoint)
        local endSegment = Segment.create(sector.center, endPoint)
        if ShapeIntersector.circleHasIntersectionWithSegment(circle, startSegment) or
                ShapeIntersector.circleHasIntersectionWithSegment(circle, endSegment) then
            return true
        end
        return false
    end

    ---检查扇形与矩形的相交
    ---@param sector foundation.shape.Sector 扇形
    ---@param rectangle foundation.shape.Rectangle 矩形
    ---@return boolean, foundation.math.Vector2[] | nil
    function ShapeIntersector.sectorToRectangle(sector, rectangle)
        local points = {}
        if math.abs(sector.range) >= 1 then
            return ShapeIntersector.rectangleToCircle(rectangle, sector)
        end
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
        if math.abs(sector.range) >= 1 then
            return ShapeIntersector.rectangleHasIntersectionWithCircle(rectangle, sector)
        end
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
        Segment = Segment or require("foundation.shape.Segment")
        local points = {}
        if math.abs(sector1.range) >= 1 and math.abs(sector2.range) >= 1 then
            return ShapeIntersector.circleToCircle(sector1, sector2)
        end
        local success, circle_points = ShapeIntersector.circleToCircle(sector1, sector2)
        if success then
            for _, p in ipairs(circle_points) do
                if ShapeIntersector.sectorContainsPoint(sector1, p) and ShapeIntersector.sectorContainsPoint(sector2, p) then
                    points[#points + 1] = p
                end
            end
        end
        if math.abs(sector1.range) < 1 then
            local startDir1 = sector1.direction
            local endDir1 = sector1.direction:rotated(sector1.range * 2 * math.pi)
            local startPoint1 = sector1.center + startDir1 * sector1.radius
            local endPoint1 = sector1.center + endDir1 * sector1.radius
            local startSegment1 = Segment.create(sector1.center, startPoint1)
            local endSegment1 = Segment.create(sector1.center, endPoint1)
            local success1, edge_points1 = ShapeIntersector.sectorToSegment(sector2, startSegment1)
            if success1 then
                for _, p in ipairs(edge_points1) do
                    points[#points + 1] = p
                end
            end
            local success2, edge_points2 = ShapeIntersector.sectorToSegment(sector2, endSegment1)
            if success2 then
                for _, p in ipairs(edge_points2) do
                    points[#points + 1] = p
                end
            end
        end
        if math.abs(sector2.range) < 1 then
            local startDir2 = sector2.direction
            local endDir2 = sector2.direction:rotated(sector2.range * 2 * math.pi)
            local startPoint2 = sector2.center + startDir2 * sector2.radius
            local endPoint2 = sector2.center + endDir2 * sector2.radius
            local startSegment2 = Segment.create(sector2.center, startPoint2)
            local endSegment2 = Segment.create(sector2.center, endPoint2)
            local success3, edge_points3 = ShapeIntersector.sectorToSegment(sector1, startSegment2)
            if success3 then
                for _, p in ipairs(edge_points3) do
                    points[#points + 1] = p
                end
            end
            local success4, edge_points4 = ShapeIntersector.sectorToSegment(sector1, endSegment2)
            if success4 then
                for _, p in ipairs(edge_points4) do
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
        Segment = Segment or require("foundation.shape.Segment")
        if math.abs(sector1.range) >= 1 and math.abs(sector2.range) >= 1 then
            return ShapeIntersector.circleHasIntersectionWithCircle(sector1, sector2)
        end
        if ShapeIntersector.sectorContainsPoint(sector1, sector2.center) or
                ShapeIntersector.sectorContainsPoint(sector2, sector1.center) then
            return true
        end
        local success, circle_points = ShapeIntersector.circleToCircle(sector1, sector2)
        if success then
            for _, p in ipairs(circle_points) do
                if ShapeIntersector.sectorContainsPoint(sector1, p) and ShapeIntersector.sectorContainsPoint(sector2, p) then
                    return true
                end
            end
        end
        if math.abs(sector1.range) < 1 then
            local startDir1 = sector1.direction
            local endDir1 = sector1.direction:rotated(sector1.range * 2 * math.pi)
            local startPoint1 = sector1.center + startDir1 * sector1.radius
            local endPoint1 = sector1.center + endDir1 * sector1.radius
            local startSegment1 = Segment.create(sector1.center, startPoint1)
            local endSegment1 = Segment.create(sector1.center, endPoint1)
            if ShapeIntersector.sectorHasIntersectionWithSegment(sector2, startSegment1) or
                    ShapeIntersector.sectorHasIntersectionWithSegment(sector2, endSegment1) then
                return true
            end
        end
        if math.abs(sector2.range) < 1 then
            local startDir2 = sector2.direction
            local endDir2 = sector2.direction:rotated(sector2.range * 2 * math.pi)
            local startPoint2 = sector2.center + startDir2 * sector2.radius
            local endPoint2 = sector2.center + endDir2 * sector2.radius
            local startSegment2 = Segment.create(sector2.center, startPoint2)
            local endSegment2 = Segment.create(sector2.center, endPoint2)
            if ShapeIntersector.sectorHasIntersectionWithSegment(sector1, startSegment2) or
                    ShapeIntersector.sectorHasIntersectionWithSegment(sector1, endSegment2) then
                return true
            end
        end
        return false
    end

    return ShapeIntersector
end