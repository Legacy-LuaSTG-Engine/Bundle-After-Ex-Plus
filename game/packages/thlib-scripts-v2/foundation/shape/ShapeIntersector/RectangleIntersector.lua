---@param ShapeIntersector foundation.shape.ShapeIntersector
return function(ShapeIntersector)
    local ipairs = ipairs

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

    return ShapeIntersector
end