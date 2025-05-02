local ffi = require("ffi")

local type = type
local error = error
local rawset = rawset
local setmetatable = setmetatable
local math = math
local table = table
local string = string

ffi.cdef [[
typedef struct {
    double* data;
    int rows;
    int cols;
} foundation_math_Matrix;
]]

---@class foundation.math.Matrix
---@field data userdata 矩阵数据指针
---@field rows number 矩阵行数
---@field cols number 矩阵列数
local Matrix = {}
Matrix.__type = "foundation.math.Matrix"

---创建一个新的矩阵
---@param rows number 行数
---@param cols number 列数
---@param initialValue number|nil 初始值，默认为0
---@return foundation.math.Matrix 新创建的矩阵
function Matrix.create(rows, cols, initialValue)
    if rows <= 0 or cols <= 0 then
        error("Matrix dimensions must be positive")
    end

    initialValue = initialValue or 0

    local matrix_data = ffi.new("foundation_math_Matrix")
    matrix_data.rows = rows
    matrix_data.cols = cols
    matrix_data.data = ffi.new("double[?]", rows * cols)

    for i = 0, rows * cols - 1 do
        matrix_data.data[i] = initialValue
    end
    
    local matrix = {
        __data = matrix_data,
        __data_array_ref = matrix_data.data
    }
    
    return setmetatable(matrix, Matrix)
end

---@param self foundation.math.Matrix
---@param key any
---@return any
function Matrix.__index(self, key)
    if key == "data" then
        return self.__data.data
    elseif key == "rows" then
        return self.__data.rows
    elseif key == "cols" then
        return self.__data.cols
    end
    return Matrix[key]
end

---@param self foundation.math.Matrix
---@param key any
---@param value any
function Matrix.__newindex(self, key, value)
    if key == "data" then
        error("Cannot modify data directly")
    elseif key == "rows" or key == "cols" then
        error("Cannot modify dimensions directly")
    else
        rawset(self, key, value)
    end
end

---获取指定位置的线性索引
---@param i number 行索引 (1-based)
---@param j number 列索引 (1-based)
---@return number 线性索引 (0-based)
local function getLinearIndex(matrix, i, j)
    return (i - 1) * matrix.cols + (j - 1)
end

---创建一个方阵（行列数相等的矩阵）
---@param size number 矩阵大小
---@param initialValue number|nil 初始值，默认为0
---@return foundation.math.Matrix 新创建的方阵
function Matrix.createSquare(size, initialValue)
    return Matrix.create(size, size, initialValue)
end

---创建一个单位矩阵
---@param size number 矩阵大小
---@return foundation.math.Matrix 新创建的单位矩阵
function Matrix.identity(size)
    local matrix = Matrix.create(size, size, 0)
    for i = 1, size do
        matrix:set(i, i, 1)
    end
    return matrix
end

---从二维数组创建矩阵
---@param arr table 二维数组
---@return foundation.math.Matrix 新创建的矩阵
function Matrix.fromArray(arr)
    if not arr or #arr == 0 then
        error("Input array cannot be empty")
    end

    local rows = #arr
    local cols = #arr[1]

    for i = 2, rows do
        if #arr[i] ~= cols then
            error("All rows must have the same number of columns")
        end
    end

    local matrix = Matrix.create(rows, cols)
    for i = 1, rows do
        for j = 1, cols do
            matrix:set(i, j, arr[i][j])
        end
    end

    return matrix
end

---矩阵加法运算符重载
---@param a foundation.math.Matrix|number 第一个操作数
---@param b foundation.math.Matrix|number 第二个操作数
---@return foundation.math.Matrix 相加后的结果
function Matrix.__add(a, b)
    if type(a) == "number" then
        local result = Matrix.create(b.rows, b.cols)
        for i = 1, b.rows do
            for j = 1, b.cols do
                result:set(i, j, a + b:get(i, j))
            end
        end
        return result
    elseif type(b) == "number" then
        local result = Matrix.create(a.rows, a.cols)
        for i = 1, a.rows do
            for j = 1, a.cols do
                result:set(i, j, a:get(i, j) + b)
            end
        end
        return result
    else
        if a.rows ~= b.rows or a.cols ~= b.cols then
            error("Matrix dimensions must match for addition")
        end

        local result = Matrix.create(a.rows, a.cols)
        for i = 1, a.rows do
            for j = 1, a.cols do
                result:set(i, j, a:get(i, j) + b:get(i, j))
            end
        end
        return result
    end
end

---矩阵减法运算符重载
---@param a foundation.math.Matrix|number 第一个操作数
---@param b foundation.math.Matrix|number 第二个操作数
---@return foundation.math.Matrix 相减后的结果
function Matrix.__sub(a, b)
    if type(a) == "number" then
        local result = Matrix.create(b.rows, b.cols)
        for i = 1, b.rows do
            for j = 1, b.cols do
                result:set(i, j, a - b:get(i, j))
            end
        end
        return result
    elseif type(b) == "number" then
        local result = Matrix.create(a.rows, a.cols)
        for i = 1, a.rows do
            for j = 1, a.cols do
                result:set(i, j, a:get(i, j) - b)
            end
        end
        return result
    else
        if a.rows ~= b.rows or a.cols ~= b.cols then
            error("Matrix dimensions must match for subtraction")
        end

        local result = Matrix.create(a.rows, a.cols)
        for i = 1, a.rows do
            for j = 1, a.cols do
                result:set(i, j, a:get(i, j) - b:get(i, j))
            end
        end
        return result
    end
end

---矩阵乘法运算符重载
---@param a foundation.math.Matrix|number 第一个操作数
---@param b foundation.math.Matrix|number 第二个操作数
---@return foundation.math.Matrix 相乘后的结果
function Matrix.__mul(a, b)
    if type(a) == "number" then
        local result = Matrix.create(b.rows, b.cols)
        for i = 1, b.rows do
            for j = 1, b.cols do
                result:set(i, j, a * b:get(i, j))
            end
        end
        return result
    elseif type(b) == "number" then
        local result = Matrix.create(a.rows, a.cols)
        for i = 1, a.rows do
            for j = 1, a.cols do
                result:set(i, j, a:get(i, j) * b)
            end
        end
        return result
    else
        if a.cols ~= b.rows then
            error("Inner matrix dimensions must match for multiplication")
        end

        local result = Matrix.create(a.rows, b.cols)
        for i = 1, a.rows do
            for j = 1, b.cols do
                local sum = 0
                for k = 1, a.cols do
                    sum = sum + a:get(i, k) * b:get(k, j)
                end
                result:set(i, j, sum)
            end
        end
        return result
    end
end

---矩阵取负运算符重载
---@param m foundation.math.Matrix 操作数
---@return foundation.math.Matrix 取反后的矩阵
function Matrix.__unm(m)
    local result = Matrix.create(m.rows, m.cols)
    for i = 1, m.rows do
        for j = 1, m.cols do
            result:set(i, j, -m:get(i, j))
        end
    end
    return result
end

---矩阵相等性比较运算符重载
---@param a foundation.math.Matrix 第一个操作数
---@param b foundation.math.Matrix 第二个操作数
---@return boolean 两个矩阵是否相等
function Matrix.__eq(a, b)
    if a.rows ~= b.rows or a.cols ~= b.cols then
        return false
    end

    for i = 1, a.rows do
        for j = 1, a.cols do
            if math.abs(a:get(i, j) - b:get(i, j)) > 1e-10 then
                return false
            end
        end
    end

    return true
end

---矩阵字符串表示
---@param m foundation.math.Matrix 操作数
---@return string 矩阵的字符串表示
function Matrix.__tostring(m)
    local lines = {}
    for i = 1, m.rows do
        local row = {}
        for j = 1, m.cols do
            row[j] = string.format("%f", m:get(i, j))
        end
        lines[i] = "[" .. table.concat(row, ", ") .. "]"
    end
    return "[" .. table.concat(lines, "") .. "]"
end

---获取矩阵元素值
---@param i number 行索引
---@param j number 列索引
---@return number 指定位置的值
function Matrix:get(i, j)
    if i < 1 or i > self.rows or j < 1 or j > self.cols then
        error("Matrix index out of bounds")
    end
    local idx = getLinearIndex(self, i, j)
    return self.data[idx]
end

---设置矩阵元素值
---@param i number 行索引
---@param j number 列索引
---@param value number 要设置的值
function Matrix:set(i, j, value)
    if i < 1 or i > self.rows or j < 1 or j > self.cols then
        error("Matrix index out of bounds")
    end
    local idx = getLinearIndex(self, i, j)
    self.data[idx] = value
end

---获取矩阵的副本
---@return foundation.math.Matrix 矩阵的副本
function Matrix:clone()
    local result = Matrix.create(self.rows, self.cols)
    for i = 1, self.rows do
        for j = 1, self.cols do
            result:set(i, j, self:get(i, j))
        end
    end
    return result
end

---转置矩阵
---@return foundation.math.Matrix 转置后的矩阵
function Matrix:transpose()
    local result = Matrix.create(self.cols, self.rows)
    for i = 1, self.rows do
        for j = 1, self.cols do
            result:set(j, i, self:get(i, j))
        end
    end
    return result
end

---计算矩阵的行列式（仅适用于方阵）
---@return number 行列式的值
function Matrix:determinant()
    if self.rows ~= self.cols then
        error("Determinant can only be calculated for square matrices")
    end

    local n = self.rows
    if n == 1 then
        return self:get(1, 1)
    elseif n == 2 then
        return self:get(1, 1) * self:get(2, 2) - self:get(1, 2) * self:get(2, 1)
    else
        local det = 0
        for j = 1, n do
            det = det + self:cofactor(1, j) * self:get(1, j)
        end
        return det
    end
end

---计算矩阵元素的代数余子式
---@param row number 行索引
---@param col number 列索引
---@return number 代数余子式的值
function Matrix:cofactor(row, col)
    local sign = ((row + col) % 2 == 0) and 1 or -1
    return sign * self:minor(row, col)
end

---计算矩阵元素的余子式
---@param row number 行索引
---@param col number 列索引
---@return number 余子式的值
function Matrix:minor(row, col)
    local subMatrix = self:subMatrix(row, col)
    return subMatrix:determinant()
end

---获取去掉指定行列的子矩阵
---@param row number 要去掉的行索引
---@param col number 要去掉的列索引
---@return foundation.math.Matrix 子矩阵
function Matrix:subMatrix(row, col)
    local result = Matrix.create(self.rows - 1, self.cols - 1)
    local r = 1
    for i = 1, self.rows do
        if i ~= row then
            local c = 1
            for j = 1, self.cols do
                if j ~= col then
                    result:set(r, c, self:get(i, j))
                    c = c + 1
                end
            end
            r = r + 1
        end
    end
    return result
end

---计算矩阵的伴随矩阵
---@return foundation.math.Matrix 伴随矩阵
function Matrix:adjugate()
    if self.rows ~= self.cols then
        error("Adjugate can only be calculated for square matrices")
    end

    local n = self.rows
    local result = Matrix.create(n, n)

    for i = 1, n do
        for j = 1, n do
            result:set(j, i, self:cofactor(i, j))
        end
    end

    return result
end

---计算矩阵的逆（仅适用于方阵）
---@return foundation.math.Matrix|nil 逆矩阵，若不可逆则返回nil
function Matrix:inverse()
    if self.rows ~= self.cols then
        error("Inverse can only be calculated for square matrices")
    end

    local det = self:determinant()
    if math.abs(det) < 1e-10 then
        return nil
    end

    local adjugate = self:adjugate()
    return adjugate * (1 / det)
end

---获取矩阵的迹（仅适用于方阵）
---@return number 矩阵的迹
function Matrix:trace()
    if self.rows ~= self.cols then
        error("Trace can only be calculated for square matrices")
    end

    local sum = 0
    for i = 1, self.rows do
        sum = sum + self:get(i, i)
    end

    return sum
end

---将矩阵扩充为增广矩阵
---@param other foundation.math.Matrix 要扩充的矩阵
---@return foundation.math.Matrix 扩充后的矩阵
function Matrix:augment(other)
    if self.rows ~= other.rows then
        error("Matrices must have the same number of rows for augmentation")
    end

    local result = Matrix.create(self.rows, self.cols + other.cols)

    for i = 1, self.rows do
        for j = 1, self.cols do
            result:set(i, j, self:get(i, j))
        end

        for j = 1, other.cols do
            result:set(i, self.cols + j, other:get(i, j))
        end
    end

    return result
end

---获取矩阵的指定子矩阵
---@param startRow number 起始行索引
---@param endRow number 结束行索引
---@param startCol number 起始列索引
---@param endCol number 结束列索引
---@return foundation.math.Matrix 子矩阵
function Matrix:getSubMatrix(startRow, endRow, startCol, endCol)
    if startRow < 1 or endRow > self.rows or startCol < 1 or endCol > self.cols then
        error("Submatrix indices out of bounds")
    end

    if startRow > endRow or startCol > endCol then
        error("Invalid submatrix indices")
    end

    local rows = endRow - startRow + 1
    local cols = endCol - startCol + 1
    local result = Matrix.create(rows, cols)

    for i = 1, rows do
        for j = 1, cols do
            result:set(i, j, self:get(startRow + i - 1, startCol + j - 1))
        end
    end

    return result
end

---高斯消元法求解线性方程组 Ax = b
---@param b foundation.math.Matrix 常数向量
---@return foundation.math.Matrix|nil 解向量，若无解则返回nil
function Matrix:solve(b)
    if self.rows ~= self.cols then
        error("Coefficient matrix must be square")
    end

    if self.rows ~= b.rows or b.cols ~= 1 then
        error("Dimensions of right-hand side vector do not match")
    end

    local augmented = self:augment(b)
    local n = self.rows

    for i = 1, n do
        local maxVal = math.abs(augmented:get(i, i))
        local maxRow = i

        for k = i + 1, n do
            if math.abs(augmented:get(k, i)) > maxVal then
                maxVal = math.abs(augmented:get(k, i))
                maxRow = k
            end
        end

        if maxVal < 1e-10 then
            return nil
        end

        if maxRow ~= i then
            for j = i, n + 1 do
                local temp = augmented:get(i, j)
                augmented:set(i, j, augmented:get(maxRow, j))
                augmented:set(maxRow, j, temp)
            end
        end

        for k = i + 1, n do
            local factor = augmented:get(k, i) / augmented:get(i, i)
            augmented:set(k, i, 0)

            for j = i + 1, n + 1 do
                augmented:set(k, j, augmented:get(k, j) - factor * augmented:get(i, j))
            end
        end
    end

    local solution = Matrix.create(n, 1)
    for i = n, 1, -1 do
        local sum = 0
        for j = i + 1, n do
            sum = sum + augmented:get(i, j) * solution:get(j, 1)
        end
        solution:set(i, 1, (augmented:get(i, n + 1) - sum) / augmented:get(i, i))
    end

    return solution
end

---计算两个矩阵的哈达玛积（逐元素乘积）
---@param other foundation.math.Matrix 另一个矩阵
---@return foundation.math.Matrix 哈达玛积结果
function Matrix:hadamard(other)
    if self.rows ~= other.rows or self.cols ~= other.cols then
        error("Matrix dimensions must match for Hadamard product")
    end

    local result = Matrix.create(self.rows, self.cols)
    for i = 1, self.rows do
        for j = 1, self.cols do
            result:set(i, j, self:get(i, j) * other:get(i, j))
        end
    end

    return result
end

---计算矩阵的Frobenius范数
---@return number Frobenius范数
function Matrix:normFrobenius()
    local sum = 0
    for i = 1, self.rows do
        for j = 1, self.cols do
            local val = self:get(i, j)
            sum = sum + val * val
        end
    end
    return math.sqrt(sum)
end

---检查矩阵是否为对称矩阵
---@return boolean 是否为对称矩阵
function Matrix:isSymmetric()
    if self.rows ~= self.cols then
        return false
    end

    for i = 1, self.rows do
        for j = i + 1, self.cols do
            if math.abs(self:get(i, j) - self:get(j, i)) > 1e-10 then
                return false
            end
        end
    end

    return true
end

---将矩阵转换为数组
---@return table 包含矩阵元素的二维数组
function Matrix:toArray()
    local result = {}
    for i = 1, self.rows do
        result[i] = {}
        for j = 1, self.cols do
            result[i][j] = self:get(i, j)
        end
    end
    return result
end

---将矩阵转换为扁平数组（按行优先顺序）
---@return table 包含矩阵元素的一维数组
function Matrix:toFlatArray()
    local result = {}
    local index = 1
    for i = 1, self.rows do
        for j = 1, self.cols do
            result[index] = self:get(i, j)
            index = index + 1
        end
    end
    return result
end

---从扁平数组创建矩阵（按行优先顺序）
---@param arr table 一维数组
---@param rows number 行数
---@param cols number 列数
---@return foundation.math.Matrix 创建的矩阵
function Matrix.fromFlatArray(arr, rows, cols)
    if #arr ~= rows * cols then
        error("Array length does not match matrix dimensions")
    end

    local matrix = Matrix.create(rows, cols)
    local index = 1
    for i = 1, rows do
        for j = 1, cols do
            matrix:set(i, j, arr[index])
            index = index + 1
        end
    end

    return matrix
end

return Matrix