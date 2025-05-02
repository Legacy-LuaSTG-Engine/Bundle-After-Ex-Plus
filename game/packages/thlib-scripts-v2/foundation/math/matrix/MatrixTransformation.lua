local Matrix = require("foundation.math.matrix.Matrix")
local Vector2 = require("foundation.math.Vector2")
local Vector3 = require("foundation.math.Vector3")

local math = math
local error = error

---@class foundation.math.matrix.MatrixTransformation
local MatrixTransformation = {}

---创建2D平移矩阵
---@param x number X方向平移量
---@param y number Y方向平移量
---@return foundation.math.Matrix 平移矩阵
function MatrixTransformation.translation2D(x, y)
    local m = Matrix.identity(3)
    m:set(1, 3, x)
    m:set(2, 3, y)
    return m
end

---创建2D缩放矩阵
---@param sx number X方向缩放因子
---@param sy number|nil Y方向缩放因子，如果为nil则使用sx
---@return foundation.math.Matrix 缩放矩阵
function MatrixTransformation.scaling2D(sx, sy)
    sy = sy or sx
    local m = Matrix.identity(3)
    m:set(1, 1, sx)
    m:set(2, 2, sy)
    return m
end

---创建2D旋转矩阵（弧度）
---@param rad number 旋转角度（弧度）
---@return foundation.math.Matrix 旋转矩阵
function MatrixTransformation.rotation2D(rad)
    local c = math.cos(rad)
    local s = math.sin(rad)
    local m = Matrix.identity(3)
    m:set(1, 1, c)
    m:set(1, 2, -s)
    m:set(2, 1, s)
    m:set(2, 2, c)
    return m
end

---创建2D旋转矩阵（角度）
---@param angle number 旋转角度（度）
---@return foundation.math.Matrix 旋转矩阵
function MatrixTransformation.degreeRotation2D(angle)
    return MatrixTransformation.rotation2D(math.rad(angle))
end

---创建2D切变矩阵
---@param shx number X方向切变系数
---@param shy number Y方向切变系数
---@return foundation.math.Matrix 切变矩阵
function MatrixTransformation.shear2D(shx, shy)
    local m = Matrix.identity(3)
    m:set(1, 2, shy)
    m:set(2, 1, shx)
    return m
end

---创建3D平移矩阵
---@param x number X方向平移量
---@param y number Y方向平移量
---@param z number Z方向平移量
---@return foundation.math.Matrix 平移矩阵
function MatrixTransformation.translation3D(x, y, z)
    local m = Matrix.identity(4)
    m:set(1, 4, x)
    m:set(2, 4, y)
    m:set(3, 4, z)
    return m
end

---创建3D缩放矩阵
---@param sx number X方向缩放因子
---@param sy number|nil Y方向缩放因子，如果为nil则使用sx
---@param sz number|nil Z方向缩放因子，如果为nil则使用sx
---@return foundation.math.Matrix 缩放矩阵
function MatrixTransformation.scaling3D(sx, sy, sz)
    sy = sy or sx
    sz = sz or sx
    local m = Matrix.identity(4)
    m:set(1, 1, sx)
    m:set(2, 2, sy)
    m:set(3, 3, sz)
    return m
end

---创建绕X轴旋转的3D旋转矩阵（弧度）
---@param rad number 旋转角度（弧度）
---@return foundation.math.Matrix 旋转矩阵
function MatrixTransformation.rotationX(rad)
    local c = math.cos(rad)
    local s = math.sin(rad)
    local m = Matrix.identity(4)
    m:set(2, 2, c)
    m:set(2, 3, -s)
    m:set(3, 2, s)
    m:set(3, 3, c)
    return m
end

---创建绕Y轴旋转的3D旋转矩阵（弧度）
---@param rad number 旋转角度（弧度）
---@return foundation.math.Matrix 旋转矩阵
function MatrixTransformation.rotationY(rad)
    local c = math.cos(rad)
    local s = math.sin(rad)
    local m = Matrix.identity(4)
    m:set(1, 1, c)
    m:set(1, 3, s)
    m:set(3, 1, -s)
    m:set(3, 3, c)
    return m
end

---创建绕Z轴旋转的3D旋转矩阵（弧度）
---@param rad number 旋转角度（弧度）
---@return foundation.math.Matrix 旋转矩阵
function MatrixTransformation.rotationZ(rad)
    local c = math.cos(rad)
    local s = math.sin(rad)
    local m = Matrix.identity(4)
    m:set(1, 1, c)
    m:set(1, 2, -s)
    m:set(2, 1, s)
    m:set(2, 2, c)
    return m
end

---创建绕任意轴旋转的3D旋转矩阵（弧度）
---@param x number 轴的X分量
---@param y number 轴的Y分量
---@param z number 轴的Z分量
---@param rad number 旋转角度（弧度）
---@return foundation.math.Matrix 旋转矩阵
function MatrixTransformation.rotationAxis(x, y, z, rad)
    local length = math.sqrt(x * x + y * y + z * z)
    if length < 1e-10 then
        return Matrix.identity(4)
    end

    x = x / length
    y = y / length
    z = z / length

    local c = math.cos(rad)
    local s = math.sin(rad)
    local t = 1 - c

    local m = Matrix.identity(4)
    m:set(1, 1, t * x * x + c)
    m:set(1, 2, t * x * y - s * z)
    m:set(1, 3, t * x * z + s * y)

    m:set(2, 1, t * x * y + s * z)
    m:set(2, 2, t * y * y + c)
    m:set(2, 3, t * y * z - s * x)

    m:set(3, 1, t * x * z - s * y)
    m:set(3, 2, t * y * z + s * x)
    m:set(3, 3, t * z * z + c)

    return m
end

---创建视图矩阵
---@param eyeX number 视点X坐标
---@param eyeY number 视点Y坐标
---@param eyeZ number 视点Z坐标
---@param centerX number 目标点X坐标
---@param centerY number 目标点Y坐标
---@param centerZ number 目标点Z坐标
---@param upX number 上向量X分量
---@param upY number 上向量Y分量
---@param upZ number 上向量Z分量
---@return foundation.math.Matrix 视图矩阵
function MatrixTransformation.lookAt(eyeX, eyeY, eyeZ, centerX, centerY, centerZ, upX, upY, upZ)
    local zx = eyeX - centerX
    local zy = eyeY - centerY
    local zz = eyeZ - centerZ

    local zLen = math.sqrt(zx * zx + zy * zy + zz * zz)
    if zLen < 1e-10 then
        return Matrix.identity(4)
    end
    zx = zx / zLen
    zy = zy / zLen
    zz = zz / zLen

    local xx = upY * zz - upZ * zy
    local xy = upZ * zx - upX * zz
    local xz = upX * zy - upY * zx

    local xLen = math.sqrt(xx * xx + xy * xy + xz * xz)
    if xLen < 1e-10 then
        upX, upY, upZ = 0, 1, 0
        if math.abs(zy) > 0.9 then
            upX, upY, upZ = 1, 0, 0
        end
        xx = upY * zz - upZ * zy
        xy = upZ * zx - upX * zz
        xz = upX * zy - upY * zx
        xLen = math.sqrt(xx * xx + xy * xy + xz * xz)
    end
    xx = xx / xLen
    xy = xy / xLen
    xz = xz / xLen

    local yx = zy * xz - zz * xy
    local yy = zz * xx - zx * xz
    local yz = zx * xy - zy * xx

    local m = Matrix.identity(4)
    m:set(1, 1, xx)
    m:set(1, 2, xy)
    m:set(1, 3, xz)
    m:set(2, 1, yx)
    m:set(2, 2, yy)
    m:set(2, 3, yz)
    m:set(3, 1, zx)
    m:set(3, 2, zy)
    m:set(3, 3, zz)

    m:set(1, 4, -(xx * eyeX + xy * eyeY + xz * eyeZ))
    m:set(2, 4, -(yx * eyeX + yy * eyeY + yz * eyeZ))
    m:set(3, 4, -(zx * eyeX + zy * eyeY + zz * eyeZ))

    return m
end

---创建正交投影矩阵
---@param left number 左平面
---@param right number 右平面
---@param bottom number 底平面
---@param top number 顶平面
---@param near number 近平面
---@param far number 远平面
---@return foundation.math.Matrix 正交投影矩阵
function MatrixTransformation.orthographic(left, right, bottom, top, near, far)
    if math.abs(right - left) < 1e-10 or math.abs(top - bottom) < 1e-10 or math.abs(far - near) < 1e-10 then
        error("Invalid orthographic projection parameters")
    end

    local m = Matrix.identity(4)
    m:set(1, 1, 2 / (right - left))
    m:set(2, 2, 2 / (top - bottom))
    m:set(3, 3, -2 / (far - near))
    m:set(1, 4, -(right + left) / (right - left))
    m:set(2, 4, -(top + bottom) / (top - bottom))
    m:set(3, 4, -(far + near) / (far - near))

    return m
end

---创建透视投影矩阵
---@param fovy number 垂直视野角度（弧度）
---@param aspect number 宽高比
---@param near number 近平面
---@param far number 远平面
---@return foundation.math.Matrix 透视投影矩阵
function MatrixTransformation.perspective(fovy, aspect, near, far)
    if math.abs(aspect) < 1e-10 or math.abs(far - near) < 1e-10 then
        error("Invalid perspective projection parameters")
    end

    local f = 1 / math.tan(fovy / 2)

    local m = Matrix.create(4, 4, 0)
    m:set(1, 1, f / aspect)
    m:set(2, 2, f)
    m:set(3, 3, (far + near) / (near - far))
    m:set(3, 4, (2 * far * near) / (near - far))
    m:set(4, 3, -1)

    return m
end

---将Vector2应用矩阵变换（假设为2D变换，使用3x3矩阵）
---@param matrix foundation.math.Matrix 变换矩阵
---@param vector foundation.math.Vector2 待变换向量
---@return foundation.math.Vector2 变换后的向量
function MatrixTransformation.transformVector2(matrix, vector)
    if matrix.rows ~= 3 or matrix.cols ~= 3 then
        error("Expected 3x3 matrix for 2D transformation")
    end

    local x = matrix:get(1, 1) * vector.x + matrix:get(1, 2) * vector.y + matrix:get(1, 3)
    local y = matrix:get(2, 1) * vector.x + matrix:get(2, 2) * vector.y + matrix:get(2, 3)
    local w = matrix:get(3, 1) * vector.x + matrix:get(3, 2) * vector.y + matrix:get(3, 3)

    if math.abs(w) > 1e-10 then
        return Vector2.create(x / w, y / w)
    else
        return Vector2.create(x, y)
    end
end

---将Vector3应用矩阵变换
---@param matrix foundation.math.Matrix 变换矩阵
---@param vector foundation.math.Vector3 待变换向量
---@return foundation.math.Vector3 变换后的向量
function MatrixTransformation.transformVector3(matrix, vector)
    if matrix.rows ~= 4 or matrix.cols ~= 4 then
        error("Expected 4x4 matrix for 3D transformation")
    end

    local x = matrix:get(1, 1) * vector.x + matrix:get(1, 2) * vector.y + matrix:get(1, 3) * vector.z + matrix:get(1, 4)
    local y = matrix:get(2, 1) * vector.x + matrix:get(2, 2) * vector.y + matrix:get(2, 3) * vector.z + matrix:get(2, 4)
    local z = matrix:get(3, 1) * vector.x + matrix:get(3, 2) * vector.y + matrix:get(3, 3) * vector.z + matrix:get(3, 4)
    local w = matrix:get(4, 1) * vector.x + matrix:get(4, 2) * vector.y + matrix:get(4, 3) * vector.z + matrix:get(4, 4)

    if math.abs(w) > 1e-10 then
        return Vector3.create(x / w, y / w, z / w)
    else
        return Vector3.create(x, y, z)
    end
end

return MatrixTransformation