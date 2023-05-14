sp = {}
sp.logfile = "userdata/sp_log.txt"
do
    lstg.FileManager.CreateDirectory("userdata")
    local f = io.open(sp.logfile, 'w')
    f:close()
end
function sp.logWrite(str)
    local f = io.open(sp.logfile, 'a+')
    f:write(str .. "\n")
    f:close()
end

function sp.Print(...)
    local list = { ... }
    for i, v in ipairs(list) do
        list[i] = tostring(v)
    end
    local str = table.concat(list, "\t")
    Print(str)
    sp.logWrite(str)
end

sp.Print(string.format("[sp] installing"))

--SP+系 boss函数库
Include 'sp/spboss.lua'

--SP+系 math 函数库
Include 'sp/spmath.lua'

--SP+系 misc 函数库
Include 'sp/spmisc.lua'

--SP+系 string 函数库
Include 'sp/spstring.lua'

--SP+系函数
--Unit列表操作
---对一个对象表进行更新，去除无效的luastg object对象
---@param lst table
---@return number @表长度
function sp.UnitListUpdate(lst)
    local n = #lst
    local j = 0
    for i = 1, n do
        local z = lst[i]
        if IsValid(z) then
            j = j + 1
            lst[j] = z;
            if i ~= j then
                lst[i] = nil;
            end
        else
            lst[i] = nil;
        end
    end
    return j
end

---添加一个luastg object对象或者luastg object对象表到已有的对象表上
---@param lst table
---@param obj object|table
---@return number @表长度
function sp.UnitListAppend(lst, obj)
    if IsValid(obj) then
        local n = #lst
        lst[n + 1] = obj
        return n + 1
    elseif IsValid(obj[1]) then
        return sp.UnitListAppendList(lst, obj)
    else
        return #lst
    end
end

---连接两个对象表
---@param lst table
---@param objlist table
---@return number @两个对象表的对象总和
function sp.UnitListAppendList(lst, objlist)
    local n = #lst
    local n2 = #objlist
    for i = 1, n2 do
        lst[n + i] = objlist[i]
    end
    return n + n2
end

---返回指定对象在对象表中的位置
---@param lst table
---@param obj any
---@return number
function sp.UnitListFindUnit(lst, obj)
    local n = #lst
    for i = 1, n do
        local z = lst[i]
        if z == obj then
            return i
        end
    end
    return 0
end

---添加一个luastg object对象或者luastg object对象表到已有的对象表上
---如果已有则返回目标当前的所在位置
---@param lst table
---@param obj object|table
---@return number @表长度
function sp.UnitListInsertEx(lst, obj)
    local l = sp.UnitListFindUnit(lst, obj)
    if l == 0 then
        return sp.UnitListAppend(lst, obj)
    else
        return l
    end
end

---拆解表至同一层级
function sp.GetUnpackList(...)
    local ref, p = {}, { ... }
    for _, v in pairs(p) do
        if type(v) ~= 'table' then
            table.insert(ref, v)
        else
            local tmp = sp.GetUnpackList(unpack(v))
            for _, t in pairs(tmp) do
                table.insert(ref, t)
            end
        end
    end
    return ref
end

---拆解表至同一层级并解包成参数列
function sp.GetUnpack(...)
    return unpack(sp.GetUnpackList(...))
end

---复制表
---@param t table @要复制的表
---@param all boolean @是否深度复制
---@return table
function sp.copy(t, all)
    local lookup = {}
    local function _copy(t)
        if type(t) ~= 'table' then
            return t
        elseif lookup[t] then
            return lookup[t]
        end
        local ref = {}
        lookup[t] = ref
        for k, v in pairs(t) do
            ref[_copy(k)] = _copy(v)
        end
        return setmetatable(ref, getmetatable(t))
    end
    if all then
        return _copy(t)
    else
        local ref = {}
        for k, v in pairs(t) do
            ref[k] = v
        end
        return setmetatable(ref, getmetatable(t))
    end
end

---整理字符串
---@param str string @要处理的字符串
---@param length number @单字符宽度
---@return number, table
function sp.SplitText(str, length)
    local s = 0
    local list = {}
    local len = string.len(str)
    local i = 1
    while i <= len do
        local c = string.byte(str, i)
        local shift = 1
        if c > 0 and c <= 127 then
            shift = 1
            s = s + 1
        elseif (c >= 192 and c <= 223) then
            shift = 2
            s = s + 2
        elseif (c >= 224 and c <= 239) then
            shift = 3
            s = s + 2
        elseif (c >= 240 and c <= 247) then
            shift = 4
            s = s + 2
        end
        local char = string.sub(str, i, i + shift - 1)
        i = i + shift
        table.insert(list, char)
    end
    if length then
        s = s * length
    end
    return s, list
end

---按位置截取信息表
---@param list table @目标表
---@param n number @截取最大长度
---@param pos number @选择位标
---@param s number @锁定位标
---@return table, number
function sp.GetListSection(list, n, pos, s)
    n = int(n or #list)
    s = min(max(int(s or n), 1), n)
    local cut, c, m = {}, #list, pos
    if c <= n then
        cut = list
    elseif pos < s then
        for i = 1, n do
            table.insert(cut, list[i])
        end
    else
        local t = max(min(pos + (n - s), c), pos)
        for i = t - n + 1, t do
            table.insert(cut, list[i])
        end
        m = min(max(n - (t - pos), s), n)
    end
    return cut, m
end

---分割字符串迭代器
---@param input string @要分割的字符串
---@param delimiter string @分割符
---@return fun():(string, number)
function sp.Split(input, delimiter)
    local len = #input
    local pos = 0
    local i = 0
    return function()
        local p1, p2 = string.find(input, delimiter, pos + 1)
        if p1 then
            i = i + 1
            local cut = string.sub(input, pos + 1, p1 - 1)
            pos = p2
            return cut, i
        elseif pos < len then
            i = i + 1
            local cut = string.sub(input, pos + 1, len)
            pos = len
            return cut, i
        end
    end
end

---分割字符串
---@param input string @要分割的字符串
---@param delimiter string @分割符
---@return table @分割好的字符串表
function sp.SplitText(input, delimiter)
    if (delimiter == "") then
        return false
    end
    local pos, arr = 0, {}
    for st, sp in function()
        return string.find(input, delimiter, pos, true)
    end do
        table.insert(arr, string.sub(input, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(input, pos))
    return arr
end

sp.Print(string.format("[sp] install complete"))