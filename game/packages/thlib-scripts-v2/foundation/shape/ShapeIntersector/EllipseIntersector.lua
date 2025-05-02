---@param ShapeIntersector foundation.shape.ShapeIntersector
return function(ShapeIntersector)
    local math = math
    local ipairs = ipairs
    local require = require

    local Vector2 = require("foundation.math.Vector2")
    local Segment

    ---椭圆与椭圆相交检测
    ---@param ellipse1 foundation.shape.Ellipse 椭圆1
    ---@param ellipse2 foundation.shape.Ellipse 椭圆2
    ---@return boolean, foundation.math.Vector2[]|nil
    function ShapeIntersector.ellipseToEllipse(ellipse1, ellipse2)
        local segments = 36
        local points = {}

        local ellipse2Points = ellipse2:discretize(segments)

        for i = 1, #ellipse2Points - 1 do
            Segment = Segment or require("foundation.shape.Segment")
            local segment = Segment.create(ellipse2Points[i], ellipse2Points[i + 1])
            local success, edge_points = ShapeIntersector.ellipseToSegment(ellipse1, segment)
            if success then
                for _, p in ipairs(edge_points) do
                    points[#points + 1] = p
                end
            end
        end

        Segment = Segment or require("foundation.shape.Segment")
        local lastSegment = Segment.create(ellipse2Points[#ellipse2Points], ellipse2Points[1])
        local success, edge_points = ShapeIntersector.ellipseToSegment(ellipse1, lastSegment)
        if success then
            for _, p in ipairs(edge_points) do
                points[#points + 1] = p
            end
        end

        if ellipse1:contains(ellipse2.center) then
            points[#points + 1] = ellipse2.center:clone()
        end

        if ellipse2:contains(ellipse1.center) then
            points[#points + 1] = ellipse1.center:clone()
        end

        local unique_points = ShapeIntersector.getUniquePoints(points)

        if #unique_points == 0 then
            return false, nil
        end
        return true, unique_points
    end

    ---椭圆与椭圆相交检测（仅判断是否相交）
    ---@param ellipse1 foundation.shape.Ellipse 椭圆1
    ---@param ellipse2 foundation.shape.Ellipse 椭圆2
    ---@return boolean
    function ShapeIntersector.ellipseHasIntersectionWithEllipse(ellipse1, ellipse2)
        if ellipse1:contains(ellipse2.center) then
            return true
        end

        if ellipse2:contains(ellipse1.center) then
            return true
        end

        local segments = 18
        local ellipse2Points = ellipse2:discretize(segments)

        for _, p in ipairs(ellipse2Points) do
            if ellipse1:contains(p) then
                return true
            end
        end

        local ellipse1Points = ellipse1:discretize(segments)
        for _, p in ipairs(ellipse1Points) do
            if ellipse2:contains(p) then
                return true
            end
        end

        return false
    end

    ---椭圆与圆相交检测
    ---@param ellipse foundation.shape.Ellipse 椭圆
    ---@param circle foundation.shape.Circle 圆
    ---@return boolean, foundation.math.Vector2[]|nil
    function ShapeIntersector.ellipseToCircle(ellipse, circle)
        Segment = Segment or require("foundation.shape.Segment")

        local segments = 36
        local points = {}
        local circlePoints = circle:discretize(segments)

        for i = 1, #circlePoints - 1 do
            local segment = Segment.create(circlePoints[i], circlePoints[i + 1])
            local success, edge_points = ShapeIntersector.ellipseToSegment(ellipse, segment)
            if success then
                for _, p in ipairs(edge_points) do
                    points[#points + 1] = p
                end
            end
        end

        local lastSegment = Segment.create(circlePoints[#circlePoints], circlePoints[1])
        local success, edge_points = ShapeIntersector.ellipseToSegment(ellipse, lastSegment)
        if success then
            for _, p in ipairs(edge_points) do
                points[#points + 1] = p
            end
        end

        if ellipse:contains(circle.center) then
            points[#points + 1] = circle.center:clone()
        end

        if circle:contains(ellipse.center) then
            points[#points + 1] = ellipse.center:clone()
        end

        local unique_points = ShapeIntersector.getUniquePoints(points)

        if #unique_points == 0 then
            return false, nil
        end
        return true, unique_points
    end

    ---椭圆与圆相交检测（仅判断是否相交）
    ---@param ellipse foundation.shape.Ellipse 椭圆
    ---@param circle foundation.shape.Circle 圆
    ---@return boolean
    function ShapeIntersector.ellipseHasIntersectionWithCircle(ellipse, circle)
        if ellipse:contains(circle.center) then
            return true
        end

        if circle:contains(ellipse.center) then
            return true
        end

        local segments = 18
        local circlePoints = circle:discretize(segments)

        for _, p in ipairs(circlePoints) do
            if ellipse:contains(p) then
                return true
            end
        end

        Segment = Segment or require("foundation.shape.Segment")

        for i = 1, #circlePoints - 1 do
            local segment = Segment.create(circlePoints[i], circlePoints[i + 1])
            if ShapeIntersector.ellipseHasIntersectionWithSegment(ellipse, segment) then
                return true
            end
        end

        local lastSegment = Segment.create(circlePoints[#circlePoints], circlePoints[1])
        return ShapeIntersector.ellipseHasIntersectionWithSegment(ellipse, lastSegment)
    end

    ---椭圆与矩形相交检测
    ---@param ellipse foundation.shape.Ellipse 椭圆
    ---@param rectangle foundation.shape.Rectangle 矩形
    ---@return boolean, foundation.math.Vector2[]|nil
    function ShapeIntersector.ellipseToRectangle(ellipse, rectangle)
        local points = {}

        local edges = rectangle:getEdges()
        for _, edge in ipairs(edges) do
            local success, edge_points = ShapeIntersector.ellipseToSegment(ellipse, edge)
            if success then
                for _, p in ipairs(edge_points) do
                    points[#points + 1] = p
                end
            end
        end

        local vertices = rectangle:getVertices()
        for _, vertex in ipairs(vertices) do
            if ellipse:contains(vertex) then
                points[#points + 1] = vertex:clone()
            end
        end

        if rectangle:contains(ellipse.center) then
            points[#points + 1] = ellipse.center:clone()
        end

        local unique_points = ShapeIntersector.getUniquePoints(points)

        if #unique_points == 0 then
            return false, nil
        end
        return true, unique_points
    end

    ---椭圆与矩形相交检测（仅判断是否相交）
    ---@param ellipse foundation.shape.Ellipse 椭圆
    ---@param rectangle foundation.shape.Rectangle 矩形
    ---@return boolean
    function ShapeIntersector.ellipseHasIntersectionWithRectangle(ellipse, rectangle)
        local vertices = rectangle:getVertices()
        for _, vertex in ipairs(vertices) do
            if ellipse:contains(vertex) then
                return true
            end
        end

        if rectangle:contains(ellipse.center) then
            return true
        end

        local edges = rectangle:getEdges()
        for _, edge in ipairs(edges) do
            if ShapeIntersector.ellipseHasIntersectionWithSegment(ellipse, edge) then
                return true
            end
        end

        return false
    end

    ---椭圆与三角形相交检测
    ---@param ellipse foundation.shape.Ellipse 椭圆
    ---@param triangle foundation.shape.Triangle 三角形
    ---@return boolean, foundation.math.Vector2[]|nil
    function ShapeIntersector.ellipseToTriangle(ellipse, triangle)
        local points = {}

        local edges = triangle:getEdges()
        for _, edge in ipairs(edges) do
            local success, edge_points = ShapeIntersector.ellipseToSegment(ellipse, edge)
            if success then
                for _, p in ipairs(edge_points) do
                    points[#points + 1] = p
                end
            end
        end

        local vertices = triangle:getVertices()
        for _, vertex in ipairs(vertices) do
            if ellipse:contains(vertex) then
                points[#points + 1] = vertex:clone()
            end
        end

        if ShapeIntersector.triangleContainsPoint(triangle, ellipse.center) then
            points[#points + 1] = ellipse.center:clone()
        end

        local unique_points = ShapeIntersector.getUniquePoints(points)

        if #unique_points == 0 then
            return false, nil
        end
        return true, unique_points
    end

    ---椭圆与三角形相交检测（仅判断是否相交）
    ---@param ellipse foundation.shape.Ellipse 椭圆
    ---@param triangle foundation.shape.Triangle 三角形
    ---@return boolean
    function ShapeIntersector.ellipseHasIntersectionWithTriangle(ellipse, triangle)
        local vertices = triangle:getVertices()
        for _, vertex in ipairs(vertices) do
            if ellipse:contains(vertex) then
                return true
            end
        end

        if ShapeIntersector.triangleContainsPoint(triangle, ellipse.center) then
            return true
        end

        local edges = triangle:getEdges()
        for _, edge in ipairs(edges) do
            if ShapeIntersector.ellipseHasIntersectionWithSegment(ellipse, edge) then
                return true
            end
        end

        return false
    end

    ---椭圆与多边形相交检测
    ---@param ellipse foundation.shape.Ellipse 椭圆
    ---@param polygon foundation.shape.Polygon 多边形
    ---@return boolean, foundation.math.Vector2[]|nil
    function ShapeIntersector.ellipseToPolygon(ellipse, polygon)
        local points = {}

        local edges = polygon:getEdges()
        for _, edge in ipairs(edges) do
            local success, edge_points = ShapeIntersector.ellipseToSegment(ellipse, edge)
            if success then
                for _, p in ipairs(edge_points) do
                    points[#points + 1] = p
                end
            end
        end

        local vertices = polygon:getVertices()
        for _, vertex in ipairs(vertices) do
            if ellipse:contains(vertex) then
                points[#points + 1] = vertex:clone()
            end
        end

        if ShapeIntersector.polygonContainsPoint(polygon, ellipse.center) then
            points[#points + 1] = ellipse.center:clone()
        end

        local unique_points = ShapeIntersector.getUniquePoints(points)

        if #unique_points == 0 then
            return false, nil
        end
        return true, unique_points
    end

    ---椭圆与多边形相交检测（仅判断是否相交）
    ---@param ellipse foundation.shape.Ellipse 椭圆
    ---@param polygon foundation.shape.Polygon 多边形
    ---@return boolean
    function ShapeIntersector.ellipseHasIntersectionWithPolygon(ellipse, polygon)
        local vertices = polygon:getVertices()
        for _, vertex in ipairs(vertices) do
            if ellipse:contains(vertex) then
                return true
            end
        end

        if ShapeIntersector.polygonContainsPoint(polygon, ellipse.center) then
            return true
        end

        local edges = polygon:getEdges()
        for _, edge in ipairs(edges) do
            if ShapeIntersector.ellipseHasIntersectionWithSegment(ellipse, edge) then
                return true
            end
        end

        return false
    end

    ---椭圆与线段相交检测
    ---@param ellipse foundation.shape.Ellipse 椭圆
    ---@param segment foundation.shape.Segment 线段
    ---@return boolean, foundation.math.Vector2[]|nil
    function ShapeIntersector.ellipseToSegment(ellipse, segment)
        local points = {}

        local p1 = segment.point1 - ellipse.center
        local p2 = segment.point2 - ellipse.center

        local baseAngle = ellipse.direction:angle()
        local cos_rotation = math.cos(-baseAngle)
        local sin_rotation = math.sin(-baseAngle)

        local x1 = cos_rotation * p1.x - sin_rotation * p1.y
        local y1 = sin_rotation * p1.x + cos_rotation * p1.y

        local x2 = cos_rotation * p2.x - sin_rotation * p2.y
        local y2 = sin_rotation * p2.x + cos_rotation * p2.y

        x1 = x1 / ellipse.rx
        y1 = y1 / ellipse.ry

        x2 = x2 / ellipse.rx
        y2 = y2 / ellipse.ry

        local dx = x2 - x1
        local dy = y2 - y1

        local a = dx * dx + dy * dy
        local b = 2 * (x1 * dx + y1 * dy)
        local c = x1 * x1 + y1 * y1 - 1

        local discriminant = b * b - 4 * a * c

        if discriminant < 0 then
            return false, nil
        end

        local sqrt_discriminant = math.sqrt(discriminant)
        local t1 = (-b - sqrt_discriminant) / (2 * a)
        local t2 = (-b + sqrt_discriminant) / (2 * a)

        if (t1 >= 0 and t1 <= 1) then
            local x = x1 + t1 * dx
            local y = y1 + t1 * dy

            x = x * ellipse.rx
            y = y * ellipse.ry

            local px = cos_rotation * x + sin_rotation * y + ellipse.center.x
            local py = -sin_rotation * x + cos_rotation * y + ellipse.center.y

            points[#points + 1] = Vector2.create(px, py)
        end

        if (t2 >= 0 and t2 <= 1 and math.abs(t1 - t2) > 1e-10) then
            local x = x1 + t2 * dx
            local y = y1 + t2 * dy

            x = x * ellipse.rx
            y = y * ellipse.ry

            local px = cos_rotation * x + sin_rotation * y + ellipse.center.x
            local py = -sin_rotation * x + cos_rotation * y + ellipse.center.y

            points[#points + 1] = Vector2.create(px, py)
        end

        if #points == 0 then
            return false, nil
        end
        return true, points
    end

    ---椭圆与线段相交检测（仅判断是否相交）
    ---@param ellipse foundation.shape.Ellipse 椭圆
    ---@param segment foundation.shape.Segment 线段
    ---@return boolean
    function ShapeIntersector.ellipseHasIntersectionWithSegment(ellipse, segment)
        if ellipse:contains(segment.point1) or ellipse:contains(segment.point2) then
            return true
        end

        local p1 = segment.point1 - ellipse.center
        local p2 = segment.point2 - ellipse.center

        local baseAngle = ellipse.direction:angle()
        local cos_rotation = math.cos(-baseAngle)
        local sin_rotation = math.sin(-baseAngle)

        local x1 = cos_rotation * p1.x - sin_rotation * p1.y
        local y1 = sin_rotation * p1.x + cos_rotation * p1.y

        local x2 = cos_rotation * p2.x - sin_rotation * p2.y
        local y2 = sin_rotation * p2.x + cos_rotation * p2.y

        x1 = x1 / ellipse.rx
        y1 = y1 / ellipse.ry
        x2 = x2 / ellipse.rx
        y2 = y2 / ellipse.ry

        local dx = x2 - x1
        local dy = y2 - y1

        local a = dx * dx + dy * dy
        local b = 2 * (x1 * dx + y1 * dy)
        local c = x1 * x1 + y1 * y1 - 1

        local discriminant = b * b - 4 * a * c

        if discriminant < 0 then
            return false
        end

        local sqrt_discriminant = math.sqrt(discriminant)
        local t1 = (-b - sqrt_discriminant) / (2 * a)
        local t2 = (-b + sqrt_discriminant) / (2 * a)

        return (t1 >= 0 and t1 <= 1) or (t2 >= 0 and t2 <= 1)
    end

    ---椭圆与射线相交检测
    ---@param ellipse foundation.shape.Ellipse 椭圆
    ---@param ray foundation.shape.Ray 射线
    ---@return boolean, foundation.math.Vector2[]|nil
    function ShapeIntersector.ellipseToRay(ellipse, ray)
        local points = {}

        local rayPoint = ray.point - ellipse.center
        local rayDir = ray.direction:clone()

        local baseAngle = ellipse.direction:angle()
        local cos_rotation = math.cos(-baseAngle)
        local sin_rotation = math.sin(-baseAngle)

        local x0 = cos_rotation * rayPoint.x - sin_rotation * rayPoint.y
        local y0 = sin_rotation * rayPoint.x + cos_rotation * rayPoint.y

        local dx = cos_rotation * rayDir.x - sin_rotation * rayDir.y
        local dy = sin_rotation * rayDir.x + cos_rotation * rayDir.y

        x0 = x0 / ellipse.rx
        y0 = y0 / ellipse.ry
        dx = dx / ellipse.rx
        dy = dy / ellipse.ry

        local a = dx * dx + dy * dy
        local b = 2 * (x0 * dx + y0 * dy)
        local c = x0 * x0 + y0 * y0 - 1

        local discriminant = b * b - 4 * a * c

        if discriminant < 0 then
            return false, nil
        end

        local sqrt_discriminant = math.sqrt(discriminant)
        local t1 = (-b - sqrt_discriminant) / (2 * a)
        local t2 = (-b + sqrt_discriminant) / (2 * a)

        if t1 >= 0 then
            local x1 = x0 + t1 * dx
            local y1 = y0 + t1 * dy

            x1 = x1 * ellipse.rx
            y1 = y1 * ellipse.ry

            local px1 = cos_rotation * x1 + sin_rotation * y1 + ellipse.center.x
            local py1 = -sin_rotation * x1 + cos_rotation * y1 + ellipse.center.y

            points[#points + 1] = Vector2.create(px1, py1)
        end

        if t2 >= 0 and math.abs(t1 - t2) > 1e-10 then
            local x2 = x0 + t2 * dx
            local y2 = y0 + t2 * dy

            x2 = x2 * ellipse.rx
            y2 = y2 * ellipse.ry

            local px2 = cos_rotation * x2 + sin_rotation * y2 + ellipse.center.x
            local py2 = -sin_rotation * x2 + cos_rotation * y2 + ellipse.center.y

            points[#points + 1] = Vector2.create(px2, py2)
        end

        if #points == 0 then
            return false, nil
        end
        return true, points
    end

    ---椭圆与射线相交检测（仅判断是否相交）
    ---@param ellipse foundation.shape.Ellipse 椭圆
    ---@param ray foundation.shape.Ray 射线
    ---@return boolean
    function ShapeIntersector.ellipseHasIntersectionWithRay(ellipse, ray)
        if ellipse:contains(ray.point) then
            return true
        end

        local rayPoint = ray.point - ellipse.center
        local rayDir = ray.direction:clone()

        local baseAngle = ellipse.direction:angle()
        local cos_rotation = math.cos(-baseAngle)
        local sin_rotation = math.sin(-baseAngle)

        local x0 = cos_rotation * rayPoint.x - sin_rotation * rayPoint.y
        local y0 = sin_rotation * rayPoint.x + cos_rotation * rayPoint.y

        local dx = cos_rotation * rayDir.x - sin_rotation * rayDir.y
        local dy = sin_rotation * rayDir.x + cos_rotation * rayDir.y

        x0 = x0 / ellipse.rx
        y0 = y0 / ellipse.ry
        dx = dx / ellipse.rx
        dy = dy / ellipse.ry

        local a = dx * dx + dy * dy
        local b = 2 * (x0 * dx + y0 * dy)
        local c = x0 * x0 + y0 * y0 - 1

        local discriminant = b * b - 4 * a * c

        if discriminant < 0 then
            return false
        end

        local sqrt_discriminant = math.sqrt(discriminant)
        local t1 = (-b - sqrt_discriminant) / (2 * a)
        local t2 = (-b + sqrt_discriminant) / (2 * a)

        return t1 >= 0 or t2 >= 0
    end

    ---椭圆与线相交检测
    ---@param ellipse foundation.shape.Ellipse 椭圆
    ---@param line foundation.shape.Line 线
    ---@return boolean, foundation.math.Vector2[]|nil
    function ShapeIntersector.ellipseToLine(ellipse, line)
        local points = {}

        local linePoint = line.point - ellipse.center
        local lineDir = line.direction:clone()

        local baseAngle = ellipse.direction:angle()
        local cos_rotation = math.cos(-baseAngle)
        local sin_rotation = math.sin(-baseAngle)

        local x0 = cos_rotation * linePoint.x - sin_rotation * linePoint.y
        local y0 = sin_rotation * linePoint.x + cos_rotation * linePoint.y

        local dx = cos_rotation * lineDir.x - sin_rotation * lineDir.y
        local dy = sin_rotation * lineDir.x + cos_rotation * lineDir.y

        x0 = x0 / ellipse.rx
        y0 = y0 / ellipse.ry
        dx = dx / ellipse.rx
        dy = dy / ellipse.ry

        local a = dx * dx + dy * dy
        local b = 2 * (x0 * dx + y0 * dy)
        local c = x0 * x0 + y0 * y0 - 1

        local discriminant = b * b - 4 * a * c

        if discriminant < 0 then
            return false, nil
        end

        local sqrt_discriminant = math.sqrt(discriminant)
        local t1 = (-b - sqrt_discriminant) / (2 * a)
        local t2 = (-b + sqrt_discriminant) / (2 * a)

        local x1 = x0 + t1 * dx
        local y1 = y0 + t1 * dy

        x1 = x1 * ellipse.rx
        y1 = y1 * ellipse.ry

        local px1 = cos_rotation * x1 + sin_rotation * y1 + ellipse.center.x
        local py1 = -sin_rotation * x1 + cos_rotation * y1 + ellipse.center.y

        points[#points + 1] = Vector2.create(px1, py1)

        if math.abs(discriminant) > 1e-10 then
            local x2 = x0 + t2 * dx
            local y2 = y0 + t2 * dy

            x2 = x2 * ellipse.rx
            y2 = y2 * ellipse.ry

            local px2 = cos_rotation * x2 + sin_rotation * y2 + ellipse.center.x
            local py2 = -sin_rotation * x2 + cos_rotation * y2 + ellipse.center.y

            points[#points + 1] = Vector2.create(px2, py2)
        end

        return true, points
    end

    ---椭圆与线相交检测（仅判断是否相交）
    ---@param ellipse foundation.shape.Ellipse 椭圆
    ---@param line foundation.shape.Line 线
    ---@return boolean
    function ShapeIntersector.ellipseHasIntersectionWithLine(ellipse, line)
        if ellipse:contains(line.point) then
            return true
        end

        local linePoint = line.point - ellipse.center
        local lineDir = line.direction:clone()

        local baseAngle = ellipse.direction:angle()
        local cos_rotation = math.cos(-baseAngle)
        local sin_rotation = math.sin(-baseAngle)

        local x0 = cos_rotation * linePoint.x - sin_rotation * linePoint.y
        local y0 = sin_rotation * linePoint.x + cos_rotation * linePoint.y

        local dx = cos_rotation * lineDir.x - sin_rotation * lineDir.y
        local dy = sin_rotation * lineDir.x + cos_rotation * lineDir.y

        x0 = x0 / ellipse.rx
        y0 = y0 / ellipse.ry
        dx = dx / ellipse.rx
        dy = dy / ellipse.ry

        local a = dx * dx + dy * dy
        local b = 2 * (x0 * dx + y0 * dy)
        local c = x0 * x0 + y0 * y0 - 1

        local discriminant = b * b - 4 * a * c

        return discriminant >= 0
    end

    ---椭圆与扇形相交检测
    ---@param ellipse foundation.shape.Ellipse 椭圆
    ---@param sector foundation.shape.Sector 扇形
    ---@return boolean, foundation.math.Vector2[]|nil
    function ShapeIntersector.ellipseToSector(ellipse, sector)
        Segment = Segment or require("foundation.shape.Segment")
        local points = {}

        if math.abs(sector.range) >= 1 then
            ---@diagnostic disable-next-line: param-type-mismatch
            return ShapeIntersector.ellipseToCircle(ellipse, sector)
        end

        ---@diagnostic disable-next-line: param-type-mismatch
        local success, circle_points = ShapeIntersector.ellipseToCircle(ellipse, sector)
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

        local success1, edge_points1 = ShapeIntersector.ellipseToSegment(ellipse, startSegment)
        if success1 then
            for _, p in ipairs(edge_points1) do
                points[#points + 1] = p
            end
        end

        local success2, edge_points2 = ShapeIntersector.ellipseToSegment(ellipse, endSegment)
        if success2 then
            for _, p in ipairs(edge_points2) do
                points[#points + 1] = p
            end
        end

        if ShapeIntersector.sectorContainsPoint(sector, ellipse.center) then
            points[#points + 1] = ellipse.center:clone()
        end

        if ellipse:contains(sector.center) then
            points[#points + 1] = sector.center:clone()
        end

        local unique_points = ShapeIntersector.getUniquePoints(points)

        if #unique_points == 0 then
            return false, nil
        end
        return true, unique_points
    end

    ---椭圆与扇形相交检测（仅判断是否相交）
    ---@param ellipse foundation.shape.Ellipse 椭圆
    ---@param sector foundation.shape.Sector 扇形
    ---@return boolean
    function ShapeIntersector.ellipseHasIntersectionWithSector(ellipse, sector)
        Segment = Segment or require("foundation.shape.Segment")

        if math.abs(sector.range) >= 1 then
            ---@diagnostic disable-next-line: param-type-mismatch
            return ShapeIntersector.ellipseHasIntersectionWithCircle(ellipse, sector)
        end

        if ShapeIntersector.sectorContainsPoint(sector, ellipse.center) then
            return true
        end

        if ellipse:contains(sector.center) then
            return true
        end

        local startDir = sector.direction
        local endDir = sector.direction:rotated(sector.range * 2 * math.pi)
        local startPoint = sector.center + startDir * sector.radius
        local endPoint = sector.center + endDir * sector.radius

        local startSegment = Segment.create(sector.center, startPoint)
        local endSegment = Segment.create(sector.center, endPoint)

        if ShapeIntersector.ellipseHasIntersectionWithSegment(ellipse, startSegment) or
                ShapeIntersector.ellipseHasIntersectionWithSegment(ellipse, endSegment) then
            return true
        end

        local segments = 18
        local arcPoints = sector:discretize(segments)

        for i = 1, #arcPoints - 1 do
            local segment = Segment.create(arcPoints[i], arcPoints[i + 1])
            if ShapeIntersector.ellipseHasIntersectionWithSegment(ellipse, segment) then
                return true
            end
        end

        return false
    end

    return ShapeIntersector
end