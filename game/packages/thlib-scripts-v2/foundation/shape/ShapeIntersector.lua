local tostring = tostring
local ipairs = ipairs
local require = require

---@class foundation.shape.ShapeIntersector
local ShapeIntersector = {}

local ShapeIntersectorList = {
    "ContainPoint",
    "CircleIntersector",
    "EllipseIntersector",
    "LineIntersector",
    "PolygonIntersector",
    "RectangleIntersector",
    "SectorIntersector",
    "TriangleIntersector",
    "SegmentIntersector",
    "RayIntersector",
    "BezierCurveIntersector",
}
for _, moduleName in ipairs(ShapeIntersectorList) do
    local module = require(string.format("foundation.shape.ShapeIntersector.%s", moduleName))
    module(ShapeIntersector)
end

---整理相交点，去除重复点
---@param points foundation.math.Vector2[] 原始点列表
---@return foundation.math.Vector2[] 去重后的点列表
function ShapeIntersector.getUniquePoints(points)
    local unique_points = {}
    local seen = {}
    for _, p in ipairs(points) do
        local key = tostring(p.x) .. "," .. tostring(p.y)
        if not seen[key] then
            seen[key] = true
            unique_points[#unique_points + 1] = p
        end
    end
    return unique_points
end

---@type table<string, table<string, fun(shape1: any, shape2: any): boolean, foundation.math.Vector2[] | nil>>
local intersectionMap = {
    ["foundation.shape.BezierCurve"] = {
        ["foundation.shape.BezierCurve"] = ShapeIntersector.bezierCurveToBezierCurve,
        ["foundation.shape.Polygon"] = ShapeIntersector.bezierCurveToPolygon,
        ["foundation.shape.Segment"] = ShapeIntersector.bezierCurveToSegment,
        ["foundation.shape.Circle"] = ShapeIntersector.bezierCurveToCircle,
        ["foundation.shape.Rectangle"] = ShapeIntersector.bezierCurveToRectangle,
        ["foundation.shape.Triangle"] = ShapeIntersector.bezierCurveToTriangle,
        ["foundation.shape.Line"] = ShapeIntersector.bezierCurveToLine,
        ["foundation.shape.Ray"] = ShapeIntersector.bezierCurveToRay,
        ["foundation.shape.Sector"] = ShapeIntersector.bezierCurveToSector,
        ["foundation.shape.Ellipse"] = ShapeIntersector.bezierCurveToEllipse,
    },
    ["foundation.shape.Ellipse"] = {
        ["foundation.shape.Ellipse"] = ShapeIntersector.ellipseToEllipse,
        ["foundation.shape.Polygon"] = ShapeIntersector.ellipseToPolygon,
        ["foundation.shape.Segment"] = ShapeIntersector.ellipseToSegment,
        ["foundation.shape.Circle"] = ShapeIntersector.ellipseToCircle,
        ["foundation.shape.Rectangle"] = ShapeIntersector.ellipseToRectangle,
        ["foundation.shape.Triangle"] = ShapeIntersector.ellipseToTriangle,
        ["foundation.shape.Line"] = ShapeIntersector.ellipseToLine,
        ["foundation.shape.Ray"] = ShapeIntersector.ellipseToRay,
        ["foundation.shape.Sector"] = ShapeIntersector.ellipseToSector,
    },
    ["foundation.shape.Polygon"] = {
        ["foundation.shape.Polygon"] = ShapeIntersector.polygonToPolygon,
        ["foundation.shape.Triangle"] = ShapeIntersector.polygonToTriangle,
        ["foundation.shape.Rectangle"] = ShapeIntersector.polygonToRectangle,
        ["foundation.shape.Circle"] = ShapeIntersector.polygonToCircle,
        ["foundation.shape.Line"] = ShapeIntersector.polygonToLine,
        ["foundation.shape.Ray"] = ShapeIntersector.polygonToRay,
        ["foundation.shape.Segment"] = ShapeIntersector.polygonToSegment,
        ["foundation.shape.Sector"] = ShapeIntersector.polygonToSector,
    },
    ["foundation.shape.Sector"] = {
        ["foundation.shape.Sector"] = ShapeIntersector.sectorToSector,
        ["foundation.shape.Rectangle"] = ShapeIntersector.sectorToRectangle,
        ["foundation.shape.Triangle"] = ShapeIntersector.sectorToTriangle,
        ["foundation.shape.Circle"] = ShapeIntersector.sectorToCircle,
        ["foundation.shape.Line"] = ShapeIntersector.sectorToLine,
        ["foundation.shape.Ray"] = ShapeIntersector.sectorToRay,
        ["foundation.shape.Segment"] = ShapeIntersector.sectorToSegment,
    },
    ["foundation.shape.Rectangle"] = {
        ["foundation.shape.Rectangle"] = ShapeIntersector.rectangleToRectangle,
        ["foundation.shape.Triangle"] = ShapeIntersector.rectangleToTriangle,
        ["foundation.shape.Circle"] = ShapeIntersector.rectangleToCircle,
        ["foundation.shape.Line"] = ShapeIntersector.rectangleToLine,
        ["foundation.shape.Ray"] = ShapeIntersector.rectangleToRay,
        ["foundation.shape.Segment"] = ShapeIntersector.rectangleToSegment,
    },
    ["foundation.shape.Triangle"] = {
        ["foundation.shape.Triangle"] = ShapeIntersector.triangleToTriangle,
        ["foundation.shape.Circle"] = ShapeIntersector.triangleToCircle,
        ["foundation.shape.Line"] = ShapeIntersector.triangleToLine,
        ["foundation.shape.Ray"] = ShapeIntersector.triangleToRay,
        ["foundation.shape.Segment"] = ShapeIntersector.triangleToSegment,
    },
    ["foundation.shape.Line"] = {
        ["foundation.shape.Line"] = ShapeIntersector.lineToLine,
        ["foundation.shape.Ray"] = ShapeIntersector.lineToRay,
        ["foundation.shape.Segment"] = ShapeIntersector.lineToSegment,
        ["foundation.shape.Circle"] = ShapeIntersector.lineToCircle,
    },
    ["foundation.shape.Ray"] = {
        ["foundation.shape.Ray"] = ShapeIntersector.rayToRay,
        ["foundation.shape.Segment"] = ShapeIntersector.rayToSegment,
        ["foundation.shape.Circle"] = ShapeIntersector.rayToCircle,
    },
    ["foundation.shape.Circle"] = {
        ["foundation.shape.Circle"] = ShapeIntersector.circleToCircle,
        ["foundation.shape.Segment"] = ShapeIntersector.circleToSegment,
    },
    ["foundation.shape.Segment"] = {
        ["foundation.shape.Segment"] = ShapeIntersector.segmentToSegment,
    },
}

---@type table<string, table<string, fun(shape1: any, shape2: any): boolean>>
local hasIntersectionMap = {
    ["foundation.shape.BezierCurve"] = {
        ["foundation.shape.BezierCurve"] = ShapeIntersector.bezierCurveHasIntersectionWithBezierCurve,
        ["foundation.shape.Polygon"] = ShapeIntersector.bezierCurveHasIntersectionWithPolygon,
        ["foundation.shape.Segment"] = ShapeIntersector.bezierCurveHasIntersectionWithSegment,
        ["foundation.shape.Circle"] = ShapeIntersector.bezierCurveHasIntersectionWithCircle,
        ["foundation.shape.Rectangle"] = ShapeIntersector.bezierCurveHasIntersectionWithRectangle,
        ["foundation.shape.Triangle"] = ShapeIntersector.bezierCurveHasIntersectionWithTriangle,
        ["foundation.shape.Line"] = ShapeIntersector.bezierCurveHasIntersectionWithLine,
        ["foundation.shape.Ray"] = ShapeIntersector.bezierCurveHasIntersectionWithRay,
        ["foundation.shape.Sector"] = ShapeIntersector.bezierCurveHasIntersectionWithSector,
        ["foundation.shape.Ellipse"] = ShapeIntersector.bezierCurveHasIntersectionWithEllipse,
    },
    ["foundation.shape.Ellipse"] = {
        ["foundation.shape.Ellipse"] = ShapeIntersector.ellipseHasIntersectionWithEllipse,
        ["foundation.shape.Polygon"] = ShapeIntersector.ellipseHasIntersectionWithPolygon,
        ["foundation.shape.Segment"] = ShapeIntersector.ellipseHasIntersectionWithSegment,
        ["foundation.shape.Circle"] = ShapeIntersector.ellipseHasIntersectionWithCircle,
        ["foundation.shape.Rectangle"] = ShapeIntersector.ellipseHasIntersectionWithRectangle,
        ["foundation.shape.Triangle"] = ShapeIntersector.ellipseHasIntersectionWithTriangle,
        ["foundation.shape.Line"] = ShapeIntersector.ellipseHasIntersectionWithLine,
        ["foundation.shape.Ray"] = ShapeIntersector.ellipseHasIntersectionWithRay,
        ["foundation.shape.Sector"] = ShapeIntersector.ellipseHasIntersectionWithSector,
    },
    ["foundation.shape.Polygon"] = {
        ["foundation.shape.Polygon"] = ShapeIntersector.polygonHasIntersectionWithPolygon,
        ["foundation.shape.Triangle"] = ShapeIntersector.polygonHasIntersectionWithTriangle,
        ["foundation.shape.Rectangle"] = ShapeIntersector.polygonHasIntersectionWithRectangle,
        ["foundation.shape.Circle"] = ShapeIntersector.polygonHasIntersectionWithCircle,
        ["foundation.shape.Line"] = ShapeIntersector.polygonHasIntersectionWithLine,
        ["foundation.shape.Ray"] = ShapeIntersector.polygonHasIntersectionWithRay,
        ["foundation.shape.Segment"] = ShapeIntersector.polygonHasIntersectionWithSegment,
        ["foundation.shape.Sector"] = ShapeIntersector.polygonHasIntersectionWithSector,
    },
    ["foundation.shape.Sector"] = {
        ["foundation.shape.Sector"] = ShapeIntersector.sectorHasIntersectionWithSector,
        ["foundation.shape.Rectangle"] = ShapeIntersector.sectorHasIntersectionWithRectangle,
        ["foundation.shape.Triangle"] = ShapeIntersector.sectorHasIntersectionWithTriangle,
        ["foundation.shape.Circle"] = ShapeIntersector.sectorHasIntersectionWithCircle,
        ["foundation.shape.Line"] = ShapeIntersector.sectorHasIntersectionWithLine,
        ["foundation.shape.Ray"] = ShapeIntersector.sectorHasIntersectionWithRay,
        ["foundation.shape.Segment"] = ShapeIntersector.sectorHasIntersectionWithSegment,
    },
    ["foundation.shape.Rectangle"] = {
        ["foundation.shape.Rectangle"] = ShapeIntersector.rectangleHasIntersectionWithRectangle,
        ["foundation.shape.Triangle"] = ShapeIntersector.rectangleHasIntersectionWithTriangle,
        ["foundation.shape.Circle"] = ShapeIntersector.rectangleHasIntersectionWithCircle,
        ["foundation.shape.Line"] = ShapeIntersector.rectangleHasIntersectionWithLine,
        ["foundation.shape.Ray"] = ShapeIntersector.rectangleHasIntersectionWithRay,
        ["foundation.shape.Segment"] = ShapeIntersector.rectangleHasIntersectionWithSegment,
    },
    ["foundation.shape.Triangle"] = {
        ["foundation.shape.Triangle"] = ShapeIntersector.triangleHasIntersectionWithTriangle,
        ["foundation.shape.Circle"] = ShapeIntersector.triangleHasIntersectionWithCircle,
        ["foundation.shape.Line"] = ShapeIntersector.triangleHasIntersectionWithLine,
        ["foundation.shape.Ray"] = ShapeIntersector.triangleHasIntersectionWithRay,
        ["foundation.shape.Segment"] = ShapeIntersector.triangleHasIntersectionWithSegment,
    },
    ["foundation.shape.Line"] = {
        ["foundation.shape.Line"] = ShapeIntersector.lineHasIntersectionWithLine,
        ["foundation.shape.Ray"] = ShapeIntersector.lineHasIntersectionWithRay,
        ["foundation.shape.Segment"] = ShapeIntersector.lineHasIntersectionWithSegment,
        ["foundation.shape.Circle"] = ShapeIntersector.lineHasIntersectionWithCircle,
    },
    ["foundation.shape.Ray"] = {
        ["foundation.shape.Ray"] = ShapeIntersector.rayHasIntersectionWithRay,
        ["foundation.shape.Segment"] = ShapeIntersector.rayHasIntersectionWithSegment,
        ["foundation.shape.Circle"] = ShapeIntersector.rayHasIntersectionWithCircle,
    },
    ["foundation.shape.Circle"] = {
        ["foundation.shape.Circle"] = ShapeIntersector.circleHasIntersectionWithCircle,
        ["foundation.shape.Segment"] = ShapeIntersector.circleHasIntersectionWithSegment,
    },
    ["foundation.shape.Segment"] = {
        ["foundation.shape.Segment"] = ShapeIntersector.segmentHasIntersectionWithSegment,
    },
}

---检查与其他形状的相交
---@param shape1 any 第一个形状
---@param shape2 any 第二个形状
---@return boolean, foundation.math.Vector2[] | nil
function ShapeIntersector.intersect(shape1, shape2)
    local type1 = shape1.__type
    local type2 = shape2.__type

    local intersectionFunc = intersectionMap[type1] and intersectionMap[type1][type2]
    if intersectionFunc then
        return intersectionFunc(shape1, shape2)
    end

    intersectionFunc = intersectionMap[type2] and intersectionMap[type2][type1]
    if intersectionFunc then
        return intersectionFunc(shape2, shape1)
    end

    return false, nil
end

---只检查是否与其他形状相交
---@param shape1 any 第一个形状
---@param shape2 any 第二个形状
---@return boolean
function ShapeIntersector.hasIntersection(shape1, shape2)
    local type1 = shape1.__type
    local type2 = shape2.__type

    local intersectionFunc = hasIntersectionMap[type1] and hasIntersectionMap[type1][type2]
    if intersectionFunc then
        return intersectionFunc(shape1, shape2)
    end

    intersectionFunc = hasIntersectionMap[type2] and hasIntersectionMap[type2][type1]
    if intersectionFunc then
        return intersectionFunc(shape2, shape1)
    end

    return false
end

function ShapeIntersector.checkMissingIntersection()
    local keys = {}
    for k, _ in pairs(intersectionMap) do
        keys[#keys + 1] = k
    end

    local missing = {}
    for i = 1, #keys do
        local key1 = keys[i]
        for j = i, #keys do
            local key2 = keys[j]
            if not intersectionMap[key1][key2] and not intersectionMap[key2][key1] then
                missing[#missing + 1] = { key1, key2 }
            end
        end
    end

    if #missing > 0 then
        print("Missing intersections:")
        for _, pair in ipairs(missing) do
            print(pair[1], pair[2])
        end
    else
        print("No missing intersections found.")
    end

    local hasIntersectionKeys = {}
    for k, _ in pairs(hasIntersectionMap) do
        hasIntersectionKeys[#hasIntersectionKeys + 1] = k
    end

    local missingHasIntersection = {}
    for i = 1, #hasIntersectionKeys do
        local key1 = hasIntersectionKeys[i]
        for j = i, #hasIntersectionKeys do
            local key2 = hasIntersectionKeys[j]
            if not hasIntersectionMap[key1][key2] and not hasIntersectionMap[key2][key1] then
                missingHasIntersection[#missingHasIntersection + 1] = { key1, key2 }
            end
        end
    end

    if #missingHasIntersection > 0 then
        print("Missing hasIntersection:")
        for _, pair in ipairs(missingHasIntersection) do
            print(pair[1], pair[2])
        end
    else
        print("No missing hasIntersection found.")
    end
end

ShapeIntersector.checkMissingIntersection()

return ShapeIntersector