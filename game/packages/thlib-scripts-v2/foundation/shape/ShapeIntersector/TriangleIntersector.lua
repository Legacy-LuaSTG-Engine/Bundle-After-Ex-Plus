---@param ShapeIntersector foundation.shape.ShapeIntersector
return function(ShapeIntersector)
    local ipairs = ipairs

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

    return ShapeIntersector
end