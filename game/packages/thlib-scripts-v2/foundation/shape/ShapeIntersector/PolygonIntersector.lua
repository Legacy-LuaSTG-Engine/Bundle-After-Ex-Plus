---@param ShapeIntersector foundation.shape.ShapeIntersector
return function(ShapeIntersector)
    local ipairs = ipairs

    ---检查多边形与线段的相交
    ---@param polygon foundation.shape.Polygon 多边形
    ---@param segment foundation.shape.Segment 线段
    ---@return boolean, foundation.math.Vector2[] | nil
    function ShapeIntersector.polygonToSegment(polygon, segment)
        local points = {}
        local edges = polygon:getEdges()

        for _, edge in ipairs(edges) do
            local success, edge_points = ShapeIntersector.segmentToSegment(edge, segment)
            if success then
                for _, p in ipairs(edge_points) do
                    points[#points + 1] = p
                end
            end
        end

        if ShapeIntersector.polygonContainsPoint(polygon, segment.point1) then
            points[#points + 1] = segment.point1:clone()
        end

        if segment.point1 ~= segment.point2 and ShapeIntersector.polygonContainsPoint(polygon, segment.point2) then
            points[#points + 1] = segment.point2:clone()
        end

        local unique_points = ShapeIntersector.getUniquePoints(points)

        if #unique_points == 0 then
            return false, nil
        end
        return true, unique_points
    end

    ---仅检查多边形是否与线段相交
    ---@param polygon foundation.shape.Polygon 多边形
    ---@param segment foundation.shape.Segment 线段
    ---@return boolean
    function ShapeIntersector.polygonHasIntersectionWithSegment(polygon, segment)
        local edges = polygon:getEdges()

        for _, edge in ipairs(edges) do
            if ShapeIntersector.segmentHasIntersectionWithSegment(edge, segment) then
                return true
            end
        end

        return ShapeIntersector.polygonContainsPoint(polygon, segment.point1) or
                ShapeIntersector.polygonContainsPoint(polygon, segment.point2)
    end

    ---检查多边形与线的相交
    ---@param polygon foundation.shape.Polygon 多边形
    ---@param line foundation.shape.Line 线
    ---@return boolean, foundation.math.Vector2[] | nil
    function ShapeIntersector.polygonToLine(polygon, line)
        local points = {}
        local edges = polygon:getEdges()

        for _, edge in ipairs(edges) do
            local success, edge_points = ShapeIntersector.lineToSegment(line, edge)
            if success then
                for _, p in ipairs(edge_points) do
                    points[#points + 1] = p
                end
            end
        end

        if ShapeIntersector.polygonContainsPoint(polygon, line.point) then
            points[#points + 1] = line.point:clone()
        end

        local unique_points = ShapeIntersector.getUniquePoints(points)

        if #unique_points == 0 then
            return false, nil
        end
        return true, unique_points
    end

    ---仅检查多边形是否与线相交
    ---@param polygon foundation.shape.Polygon 多边形
    ---@param line foundation.shape.Line 线
    ---@return boolean
    function ShapeIntersector.polygonHasIntersectionWithLine(polygon, line)
        local edges = polygon:getEdges()

        for _, edge in ipairs(edges) do
            if ShapeIntersector.lineHasIntersectionWithSegment(line, edge) then
                return true
            end
        end

        return ShapeIntersector.polygonContainsPoint(polygon, line.point)
    end

    ---检查多边形与射线的相交
    ---@param polygon foundation.shape.Polygon 多边形
    ---@param ray foundation.shape.Ray 射线
    ---@return boolean, foundation.math.Vector2[] | nil
    function ShapeIntersector.polygonToRay(polygon, ray)
        local points = {}
        local edges = polygon:getEdges()

        for _, edge in ipairs(edges) do
            local success, edge_points = ShapeIntersector.rayToSegment(ray, edge)
            if success then
                for _, p in ipairs(edge_points) do
                    points[#points + 1] = p
                end
            end
        end

        if ShapeIntersector.polygonContainsPoint(polygon, ray.point) then
            points[#points + 1] = ray.point:clone()
        end

        local unique_points = ShapeIntersector.getUniquePoints(points)

        if #unique_points == 0 then
            return false, nil
        end
        return true, unique_points
    end

    ---仅检查多边形是否与射线相交
    ---@param polygon foundation.shape.Polygon 多边形
    ---@param ray foundation.shape.Ray 射线
    ---@return boolean
    function ShapeIntersector.polygonHasIntersectionWithRay(polygon, ray)
        local edges = polygon:getEdges()

        for _, edge in ipairs(edges) do
            if ShapeIntersector.rayHasIntersectionWithSegment(ray, edge) then
                return true
            end
        end

        return ShapeIntersector.polygonContainsPoint(polygon, ray.point)
    end

    ---检查多边形与圆的相交
    ---@param polygon foundation.shape.Polygon 多边形
    ---@param circle foundation.shape.Circle 圆
    ---@return boolean, foundation.math.Vector2[] | nil
    function ShapeIntersector.polygonToCircle(polygon, circle)
        local points = {}
        local edges = polygon:getEdges()

        for _, edge in ipairs(edges) do
            local success, edge_points = ShapeIntersector.circleToSegment(circle, edge)
            if success then
                for _, p in ipairs(edge_points) do
                    points[#points + 1] = p
                end
            end
        end

        local vertices = polygon:getVertices()
        for _, vertex in ipairs(vertices) do
            if circle:contains(vertex) then
                points[#points + 1] = vertex
            end
        end

        if ShapeIntersector.polygonContainsPoint(polygon, circle.center) then
            points[#points + 1] = circle.center:clone()
        end

        local unique_points = ShapeIntersector.getUniquePoints(points)

        if #unique_points == 0 then
            return false, nil
        end
        return true, unique_points
    end

    ---仅检查多边形是否与圆相交
    ---@param polygon foundation.shape.Polygon 多边形
    ---@param circle foundation.shape.Circle 圆
    ---@return boolean
    function ShapeIntersector.polygonHasIntersectionWithCircle(polygon, circle)
        if ShapeIntersector.polygonContainsPoint(polygon, circle.center) then
            return true
        end

        local edges = polygon:getEdges()
        for _, edge in ipairs(edges) do
            if ShapeIntersector.circleHasIntersectionWithSegment(circle, edge) then
                return true
            end
        end

        local vertices = polygon:getVertices()
        for _, vertex in ipairs(vertices) do
            if circle:contains(vertex) then
                return true
            end
        end

        return false
    end

    ---检查多边形与三角形的相交
    ---@param polygon foundation.shape.Polygon 多边形
    ---@param triangle foundation.shape.Triangle 三角形
    ---@return boolean, foundation.math.Vector2[] | nil
    function ShapeIntersector.polygonToTriangle(polygon, triangle)
        local points = {}
        local edges1 = polygon:getEdges()
        local edges2 = triangle:getEdges()

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

        local vertices = triangle:getVertices()
        for _, vertex in ipairs(vertices) do
            if ShapeIntersector.polygonContainsPoint(polygon, vertex) then
                points[#points + 1] = vertex
            end
        end

        vertices = polygon:getVertices()
        for _, vertex in ipairs(vertices) do
            if ShapeIntersector.triangleContainsPoint(triangle, vertex) then
                points[#points + 1] = vertex
            end
        end

        local unique_points = ShapeIntersector.getUniquePoints(points)

        if #unique_points == 0 then
            return false, nil
        end
        return true, unique_points
    end

    ---仅检查多边形是否与三角形相交
    ---@param polygon foundation.shape.Polygon 多边形
    ---@param triangle foundation.shape.Triangle 三角形
    ---@return boolean
    function ShapeIntersector.polygonHasIntersectionWithTriangle(polygon, triangle)
        local edges1 = polygon:getEdges()
        local edges2 = triangle:getEdges()

        for _, edge1 in ipairs(edges1) do
            for _, edge2 in ipairs(edges2) do
                if ShapeIntersector.segmentHasIntersectionWithSegment(edge1, edge2) then
                    return true
                end
            end
        end

        local vertices = triangle:getVertices()
        for _, vertex in ipairs(vertices) do
            if ShapeIntersector.polygonContainsPoint(polygon, vertex) then
                return true
            end
        end

        vertices = polygon:getVertices()
        for _, vertex in ipairs(vertices) do
            if ShapeIntersector.triangleContainsPoint(triangle, vertex) then
                return true
            end
        end

        return false
    end

    ---检查多边形与矩形的相交
    ---@param polygon foundation.shape.Polygon 多边形
    ---@param rectangle foundation.shape.Rectangle 矩形
    ---@return boolean, foundation.math.Vector2[] | nil
    function ShapeIntersector.polygonToRectangle(polygon, rectangle)
        local points = {}
        local edges1 = polygon:getEdges()
        local edges2 = rectangle:getEdges()

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

        local vertices = rectangle:getVertices()
        for _, vertex in ipairs(vertices) do
            if ShapeIntersector.polygonContainsPoint(polygon, vertex) then
                points[#points + 1] = vertex
            end
        end

        vertices = polygon:getVertices()
        for _, vertex in ipairs(vertices) do
            if ShapeIntersector.rectangleContainsPoint(rectangle, vertex) then
                points[#points + 1] = vertex
            end
        end

        local unique_points = ShapeIntersector.getUniquePoints(points)

        if #unique_points == 0 then
            return false, nil
        end
        return true, unique_points
    end

    ---仅检查多边形是否与矩形相交
    ---@param polygon foundation.shape.Polygon 多边形
    ---@param rectangle foundation.shape.Rectangle 矩形
    ---@return boolean
    function ShapeIntersector.polygonHasIntersectionWithRectangle(polygon, rectangle)
        local edges1 = polygon:getEdges()
        local edges2 = rectangle:getEdges()

        for _, edge1 in ipairs(edges1) do
            for _, edge2 in ipairs(edges2) do
                if ShapeIntersector.segmentHasIntersectionWithSegment(edge1, edge2) then
                    return true
                end
            end
        end

        local vertices = rectangle:getVertices()
        for _, vertex in ipairs(vertices) do
            if ShapeIntersector.polygonContainsPoint(polygon, vertex) then
                return true
            end
        end

        vertices = polygon:getVertices()
        for _, vertex in ipairs(vertices) do
            if ShapeIntersector.rectangleContainsPoint(rectangle, vertex) then
                return true
            end
        end

        return false
    end

    ---检查多边形与多边形的相交
    ---@param polygon1 foundation.shape.Polygon 第一个多边形
    ---@param polygon2 foundation.shape.Polygon 第二个多边形
    ---@return boolean, foundation.math.Vector2[] | nil
    function ShapeIntersector.polygonToPolygon(polygon1, polygon2)
        local points = {}
        local edges1 = polygon1:getEdges()
        local edges2 = polygon2:getEdges()

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

        local vertices = polygon2:getVertices()
        for _, vertex in ipairs(vertices) do
            if ShapeIntersector.polygonContainsPoint(polygon1, vertex) then
                points[#points + 1] = vertex
            end
        end

        vertices = polygon1:getVertices()
        for _, vertex in ipairs(vertices) do
            if ShapeIntersector.polygonContainsPoint(polygon2, vertex) then
                points[#points + 1] = vertex
            end
        end

        local unique_points = ShapeIntersector.getUniquePoints(points)

        if #unique_points == 0 then
            return false, nil
        end
        return true, unique_points
    end

    ---仅检查多边形是否与多边形相交
    ---@param polygon1 foundation.shape.Polygon 第一个多边形
    ---@param polygon2 foundation.shape.Polygon 第二个多边形
    ---@return boolean
    function ShapeIntersector.polygonHasIntersectionWithPolygon(polygon1, polygon2)
        local edges1 = polygon1:getEdges()
        local edges2 = polygon2:getEdges()

        for _, edge1 in ipairs(edges1) do
            for _, edge2 in ipairs(edges2) do
                if ShapeIntersector.segmentHasIntersectionWithSegment(edge1, edge2) then
                    return true
                end
            end
        end

        local vertices = polygon2:getVertices()
        for _, vertex in ipairs(vertices) do
            if ShapeIntersector.polygonContainsPoint(polygon1, vertex) then
                return true
            end
        end

        vertices = polygon1:getVertices()
        for _, vertex in ipairs(vertices) do
            if ShapeIntersector.polygonContainsPoint(polygon2, vertex) then
                return true
            end
        end

        return false
    end

    ---检查多边形与扇形的相交
    ---@param polygon foundation.shape.Polygon 多边形
    ---@param sector foundation.shape.Sector 扇形
    ---@return boolean, foundation.math.Vector2[] | nil
    function ShapeIntersector.polygonToSector(polygon, sector)
        local points = {}
        local edges = polygon:getEdges()

        for _, edge in ipairs(edges) do
            local success, edge_points = ShapeIntersector.sectorToSegment(sector, edge)
            if success then
                for _, p in ipairs(edge_points) do
                    points[#points + 1] = p
                end
            end
        end

        local vertices = polygon:getVertices()
        for _, vertex in ipairs(vertices) do
            if ShapeIntersector.sectorContainsPoint(sector, vertex) then
                points[#points + 1] = vertex
            end
        end

        if ShapeIntersector.polygonContainsPoint(polygon, sector.center) then
            points[#points + 1] = sector.center:clone()
        end

        local unique_points = ShapeIntersector.getUniquePoints(points)

        if #unique_points == 0 then
            return false, nil
        end
        return true, unique_points
    end

    ---仅检查多边形是否与扇形相交
    ---@param polygon foundation.shape.Polygon 多边形
    ---@param sector foundation.shape.Sector 扇形
    ---@return boolean
    function ShapeIntersector.polygonHasIntersectionWithSector(polygon, sector)
        local edges = polygon:getEdges()

        for _, edge in ipairs(edges) do
            if ShapeIntersector.sectorHasIntersectionWithSegment(sector, edge) then
                return true
            end
        end

        local vertices = polygon:getVertices()
        for _, vertex in ipairs(vertices) do
            if ShapeIntersector.sectorContainsPoint(sector, vertex) then
                return true
            end
        end

        return ShapeIntersector.polygonContainsPoint(polygon, sector.center)
    end

    return ShapeIntersector
end