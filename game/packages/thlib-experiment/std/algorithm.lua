local math = require("math")
local std_assert = require("std.assert")
local math_floor = math.floor

---@class std.algorithm
local algorithm = {}

---@generic T
---@param a T
---@param b T
---@return boolean
local function default_compare(a, b)
    return a < b
end

---@generic T
---@param t T[] | table<number, T> | table<integer, T>
---@param i integer
---@param j integer
local function table_swap(t, i, j)
    t[i], t[j] = t[j], t[i]
end

---@generic T
---@param t T[] | table<number, T> | table<integer, T>
---@param i integer
---@param a T
---@param j integer
---@param b T
local function table_set2(t, i, a, j, b)
    t[i], t[j] = a, b
end

---@generic T
---@param t T[] | table<number, T> | table<integer, T>
---@param l integer
---@param u integer
---@param compare fun(a:T, b:T):boolean
local function sort(t, l, u, compare)
    while l < u do
        do
            local a = t[l]
            local b = t[u]
            if compare(b, a) then
                table_set2(t, l, b, u, a)
            end
        end
        if u - l == 1 then
            break
        end
        local i = math_floor((l + u) / 2)
        do
            local a = t[i]
            local b = t[l]
            if compare(a, b) then
                table_set2(t, i, b, l, a)
            else
                b = t[u]
                if compare(b, a) then
                    table_set2(t, i, b, u, a)
                end
            end
        end
        if u - l == 2 then
            break
        end
        local j = u - 1
        local P = t[i]
        do
            local a = P
            local b = t[j]
            table_set2(t, i, b, j, a)
            i = l
        end
        while true do
            i = i + 1
            local a = t[i]
            while compare(a, P) do
                i = i + 1
                a = t[i]
            end
            j = j - 1
            local b = t[j]
            while compare(P, b) do
                j = j - 1
                b = t[j]
            end
            if j < i then
                break
            end
            table_set2(t, i, b, j, a)
        end
        t[u - 1], t[i] = t[i], t[u - 1]
        if (i - l) < (u - i) then
            j = l;
            i = i - 1;
            l = i + 2;
        else
            j = i + 1;
            i = u;
            u = j - 2;
        end
        sort(t, j, i, compare)
    end
end

---@generic T
---@param t T[] | table<number, T> | table<integer, T>
---@param compare (fun(a:T, b:T):boolean)?
function algorithm.quick_sort(t, compare)
    std_assert.argument_type(t, "table", 1)
    if compare ~= nil then
        std_assert.argument_type(compare, "function", 2)
    end
    sort(t, 1, #t, compare or default_compare)
end

return algorithm
