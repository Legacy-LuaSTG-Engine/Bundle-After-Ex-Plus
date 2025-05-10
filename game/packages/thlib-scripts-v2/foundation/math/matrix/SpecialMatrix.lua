local ipairs = ipairs
local error = error
local math = math

local Matrix = require("foundation.math.matrix.Matrix")

---@class foundation.math.matrix.SpecialMatrix
local SpecialMatrix = {}

---创建一个对角矩阵
---@param diag table 对角线上的值
---@return foundation.math.Matrix 对角矩阵
function SpecialMatrix.diagonal(diag)
    local size = #diag
    local matrix = Matrix.create(size, size, 0)
    
    for i = 1, size do
        matrix:set(i, i, diag[i])
    end
    
    return matrix
end

---创建一个三对角矩阵
---@param main table 主对角线上的值
---@param upper table 上对角线上的值
---@param lower table 下对角线上的值
---@return foundation.math.Matrix 三对角矩阵
function SpecialMatrix.tridiagonal(main, upper, lower)
    local size = #main
    
    if #upper ~= size - 1 or #lower ~= size - 1 then
        error("Invalid dimensions for tridiagonal matrix")
    end
    
    local matrix = Matrix.create(size, size, 0)
    
    for i = 1, size do
        matrix:set(i, i, main[i])
    end
    
    for i = 1, size - 1 do
        matrix:set(i, i + 1, upper[i])
        matrix:set(i + 1, i, lower[i])
    end
    
    return matrix
end

---创建一个Toeplitz矩阵（每一条从左上到右下的对角线上的元素相同）
---@param first_row table 第一行的元素
---@param first_col table 第一列的元素（第一个元素应与first_row[1]相同）
---@return foundation.math.Matrix Toeplitz矩阵
function SpecialMatrix.toeplitz(first_row, first_col)
    if first_row[1] ~= first_col[1] then
        error("First element of row and column must be the same")
    end
    
    local rows = #first_col
    local cols = #first_row
    
    local matrix = Matrix.create(rows, cols)
    
    for i = 1, rows do
        for j = 1, cols do
            if j >= i then
                matrix:set(i, j, first_row[j - i + 1])
            else
                matrix:set(i, j, first_col[i - j + 1])
            end
        end
    end
    
    return matrix
end

---创建一个Vandermonde矩阵
---@param points table 用于生成矩阵的点
---@param order number|nil 多项式阶数（默认为points的长度）
---@return foundation.math.Matrix Vandermonde矩阵
function SpecialMatrix.vandermonde(points, order)
    local n = #points
    order = order or n
    
    local matrix = Matrix.create(n, order)
    
    for i = 1, n do
        matrix:set(i, 1, 1)
        for j = 2, order do
            matrix:set(i, j, matrix:get(i, j - 1) * points[i])
        end
    end
    
    return matrix
end

---创建一个Hilbert矩阵 (H[i,j] = 1/(i+j-1))
---@param size number 矩阵大小
---@return foundation.math.Matrix Hilbert矩阵
function SpecialMatrix.hilbert(size)
    local matrix = Matrix.create(size, size)
    
    for i = 1, size do
        for j = 1, size do
            matrix:set(i, j, 1 / (i + j - 1))
        end
    end
    
    return matrix
end

---创建一个循环矩阵（第一行的循环位移构成后续行）
---@param first_row table 第一行的元素
---@return foundation.math.Matrix 循环矩阵
function SpecialMatrix.circulant(first_row)
    local size = #first_row
    local matrix = Matrix.create(size, size)
    
    for i = 1, size do
        for j = 1, size do
            local index = ((j - i) % size) + 1
            if index <= 0 then
                index = index + size
            end
            matrix:set(i, j, first_row[index])
        end
    end
    
    return matrix
end

---创建一个具有指定块的分块对角矩阵
---@param blocks table 块矩阵数组
---@return foundation.math.Matrix 分块对角矩阵
function SpecialMatrix.blockDiagonal(blocks)
    local totalRows = 0
    local totalCols = 0

    for _, block in ipairs(blocks) do
        totalRows = totalRows + block.rows
        totalCols = totalCols + block.cols
    end
    
    local matrix = Matrix.create(totalRows, totalCols, 0)
    
    local rowOffset = 0
    local colOffset = 0
    
    for _, block in ipairs(blocks) do
        for i = 1, block.rows do
            for j = 1, block.cols do
                matrix:set(rowOffset + i, colOffset + j, block:get(i, j))
            end
        end
        
        rowOffset = rowOffset + block.rows
        colOffset = colOffset + block.cols
    end
    
    return matrix
end

---创建上三角矩阵
---@param values table 上三角部分的值（按行优先顺序排列的一维数组）
---@param size number 矩阵大小
---@return foundation.math.Matrix 上三角矩阵
function SpecialMatrix.upperTriangular(values, size)
    local matrix = Matrix.create(size, size, 0)
    local index = 1
    
    for i = 1, size do
        for j = i, size do
            matrix:set(i, j, values[index])
            index = index + 1
        end
    end
    
    return matrix
end

---创建下三角矩阵
---@param values table 下三角部分的值（按行优先顺序排列的一维数组）
---@param size number 矩阵大小
---@return foundation.math.Matrix 下三角矩阵
function SpecialMatrix.lowerTriangular(values, size)
    local matrix = Matrix.create(size, size, 0)
    local index = 1
    
    for i = 1, size do
        for j = 1, i do
            matrix:set(i, j, values[index])
            index = index + 1
        end
    end
    
    return matrix
end

---创建一个对称矩阵
---@param values table 上三角部分的值（包括对角线，按行优先顺序排列）
---@param size number 矩阵大小
---@return foundation.math.Matrix 对称矩阵
function SpecialMatrix.symmetric(values, size)
    local matrix = Matrix.create(size, size)
    local index = 1
    
    for i = 1, size do
        for j = i, size do
            matrix:set(i, j, values[index])
            if i ~= j then
                matrix:set(j, i, values[index])
            end
            index = index + 1
        end
    end
    
    return matrix
end

---创建一个反对称矩阵（A^T = -A）
---@param values table 上三角部分的值（不包括对角线，按行优先顺序排列）
---@param size number 矩阵大小
---@return foundation.math.Matrix 反对称矩阵
function SpecialMatrix.skewSymmetric(values, size)
    local matrix = Matrix.create(size, size, 0)
    local index = 1
    
    for i = 1, size do
        for j = i + 1, size do
            matrix:set(i, j, values[index])
            matrix:set(j, i, -values[index])
            index = index + 1
        end
    end
    
    return matrix
end

---创建一个Hadamard矩阵（若存在）
---@param size number 矩阵大小（必须是1，2或4的倍数以便存在）
---@return foundation.math.Matrix|nil Hadamard矩阵，若不存在则返回nil
function SpecialMatrix.hadamard(size)
    if size <= 0 then
        return nil
    elseif size == 1 then
        return Matrix.create(1, 1, 1)
    elseif size == 2 then
        return Matrix.fromArray({
            {1, 1},
            {1, -1}
        })
    end

    if size % 4 ~= 0 then
        return nil
    end

    local halfSize = size / 2
    local h = SpecialMatrix.hadamard(halfSize)
    if not h then
        return nil
    end
    
    local result = Matrix.create(size, size)
    
    for i = 1, halfSize do
        for j = 1, halfSize do
            result:set(i, j, h:get(i, j))
            result:set(i, j + halfSize, h:get(i, j))
            result:set(i + halfSize, j, h:get(i, j))
            result:set(i + halfSize, j + halfSize, -h:get(i, j))
        end
    end
    
    return result
end

---创建一个二次型矩阵 f(x) = x^T A x
---@param coef table 二次型的系数
---@param vars number 变量个数
---@return foundation.math.Matrix 二次型矩阵
function SpecialMatrix.quadratic(coef, vars)
    local matrix = Matrix.create(vars, vars, 0)
    
    local index = 1
    for i = 1, vars do
        for j = i, vars do
            if i == j then
                matrix:set(i, j, coef[index])
            else
                matrix:set(i, j, coef[index] / 2)
                matrix:set(j, i, coef[index] / 2)
            end
            index = index + 1
        end
    end
    
    return matrix
end

---QR分解（使用Gram-Schmidt正交化）
---@param matrix foundation.math.Matrix 待分解的矩阵
---@return foundation.math.Matrix Q 正交矩阵Q
---@return foundation.math.Matrix R 上三角矩阵R
function SpecialMatrix.qrDecomposition(matrix)
    local m = matrix.rows
    local n = matrix.cols
    
    local Q = Matrix.create(m, n)
    local R = Matrix.create(n, n, 0)

    local columns = {}
    for j = 1, n do
        columns[j] = {}
        for i = 1, m do
            columns[j][i] = matrix:get(i, j)
        end
    end

    for j = 1, n do
        local q = {}
        for i = 1, m do
            q[i] = columns[j][i]
        end

        for k = 1, j - 1 do
            local dot = 0
            for i = 1, m do
                dot = dot + columns[j][i] * Q:get(i, k)
            end
            R:set(k, j, dot)

            for i = 1, m do
                q[i] = q[i] - dot * Q:get(i, k)
            end
        end

        local norm = 0
        for i = 1, m do
            norm = norm + q[i] * q[i]
        end
        norm = math.sqrt(norm)
        
        if norm < 1e-10 then
            error("Matrix columns are linearly dependent")
        end
        
        R:set(j, j, norm)
        
        for i = 1, m do
            Q:set(i, j, q[i] / norm)
        end
    end
    
    return Q, R
end

---特征值分解（仅适用于对称矩阵，使用幂法计算最大特征值）
---@param matrix foundation.math.Matrix 待分解的矩阵
---@param maxIterations number|nil 最大迭代次数（默认100）
---@param tolerance number|nil 收敛容差（默认1e-6）
---@return number 最大特征值
---@return table 对应特征向量
function SpecialMatrix.powerMethod(matrix, maxIterations, tolerance)
    if matrix.rows ~= matrix.cols then
        error("Matrix must be square for eigenvalue computation")
    end
    
    maxIterations = maxIterations or 100
    tolerance = tolerance or 1e-6
    
    local n = matrix.rows

    local x = {}
    for i = 1, n do
        x[i] = math.random()
    end

    local norm = 0
    for i = 1, n do
        norm = norm + x[i] * x[i]
    end
    norm = math.sqrt(norm)
    
    for i = 1, n do
        x[i] = x[i] / norm
    end
    
    local eigenvalue = 0
    local prevEigenvalue = 0

    for _ = 1, maxIterations do
        local y = {}
        for i = 1, n do
            y[i] = 0
            for j = 1, n do
                y[i] = y[i] + matrix:get(i, j) * x[j]
            end
        end

        local rayleigh = 0
        for i = 1, n do
            rayleigh = rayleigh + x[i] * y[i]
        end
        
        eigenvalue = rayleigh

        if math.abs(eigenvalue - prevEigenvalue) < tolerance then
            break
        end
        
        prevEigenvalue = eigenvalue

        norm = 0
        for i = 1, n do
            norm = norm + y[i] * y[i]
        end
        norm = math.sqrt(norm)
        
        for i = 1, n do
            x[i] = y[i] / norm
        end
    end
    
    return eigenvalue, x
end

return SpecialMatrix