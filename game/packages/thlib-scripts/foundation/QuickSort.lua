local assert = assert
local floor = math.floor
local type = type

---@generic V
---@alias data_array table<number, V> | V[]
---@alias comp_func fun(a:V, b:V):boolean

---@param a number
---@param b number
---@return boolean
local function default_comp(a, b)
    return a < b
end

---@param t data_array
---@param i number
---@param j number
---@param i_val any
---@param j_val any
local function set2(t, i, j, i_val, j_val)
    t[i] = i_val
    t[j] = j_val
end

---@param t data_array
---@param l number
---@param u number
---@param sort_comp comp_func
local function aux_sort(t, l, u, sort_comp)
    while l < u do
        do
            local a = t[l]
            local b = t[u]
            if sort_comp(b, a) then
                set2(t, l, u, b, a)
            end
        end
        if u - l == 1 then
            break
        end
        local i = floor((l + u) / 2)
        do
            local a = t[i]
            local b = t[l]
            if sort_comp(a, b) then
                set2(t, i, l, b, a)
            else
                b = t[u]
                if sort_comp(b, a) then
                    set2(t, i, u, b, a)
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
            set2(t, i, j, b, a)
            i = l
        end
        while true do
            i = i + 1
            local a = t[i]
            while sort_comp(a, P) do
                i = i + 1
                a = t[i]
            end
            j = j - 1
            local b = t[j]
            while sort_comp(P, b) do
                j = j - 1
                b = t[j]
            end
            if j < i then
                break
            end
            set2(t, i, j, b, a)
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
        aux_sort(t, j, i, sort_comp)
    end
end

---@param t data_array
---@param comp comp_func
---@overload fun(t:data_array)
local function sort(t, comp)
    assert(type(t) == "table")
    if comp then
        assert(type(comp) == "function")
    end
    aux_sort(t, 1, #t, comp or default_comp)
end

return sort