local classCreater
classCreater = function(instance, class, ...)
    local ctor = rawget(class, "init")
    if ctor then
        ctor(instance, ...)  -- 在有构造函数的情况下直接调用
    else
        -- 在没有构造函数的情况下去调用基类的构造函数
        local super = rawget(class, "super")
        if super then
            classCreater(instance, super, ...)
        end
    end
end

--! @brief 声明一个类
--! @param base 基类
function plus.Class(base)
    local class = { _mbc = {}, super = base }

    local function new(t, ...)
        local instance = {}
        setmetatable(instance, { __index = t })
        classCreater(instance, t, ...)
        return instance
    end

    local function indexer(t, k)
        local member = t._mbc[k]
        if member == nil then
            if base then
                member = base[k]
                t._mbc[k] = member
            end
        end
        return member
    end

    setmetatable(class, {
        __call = new,
        __index = indexer
    })

    return class
end

do
    local type = type
    local concat = table.concat
    local unpack = table.unpack or unpack
    local select = select
    local assert = assert
    local xpcall = xpcall
    local traceback = debug.traceback
    local error = error

    ---@class plus.TryCatch.Data
    ---@field try function @尝试执行
    ---@field catch function | nil @错误捕获
    ---@field finally function | nil @结束行为
    local _ = {
        try = function()
        end,
        ---@param err string @错误信息
        catch = function(err)
        end,
        finally = function()
        end
    }

    ---基础错误回调
    ---@param err string @错误信息
    ---@return string
    local function innerFunc(err)
        return concat({
            err or "unknown exception",
            "<=== inner traceback ===>",
            traceback(),
            "<=======================>",
        }, "\n")
    end

    ---捕获仍然错误回调
    ---@param err string @错误信息
    ---@return string
    local function innerCatchFunc(err)
        return concat({
            "error in catch block: ",
            err or "unknown exception",
            "<=== inner traceback ===>",
            traceback(),
            "<=======================>"
        }, "\n")
    end

    ---捕获所有返回值
    ---@return number, table
    local function packageResult(...)
        return select("#", ...), { ... }
    end

    ---```
    ---模拟TryCatch块
    ---执行一个try..catch..finally块
    ---当try语句中出现错误时，将把错误信息发送到catch语句块，否则返回try函数结果
    ---当catch语句块被执行时，若发生错误将重新抛出，否则返回catch函数结果
    ---finally块总是会保证在try或者catch后被执行
    ---```
    ---@param data plus.TryCatch.Data @条件上下文
    local function tryCatch(data, ...)
        local try, catch, finally = data.try, data.catch, data.finally
        assert(type(try) == "function", "invalid argument(try).")
        assert(type(catch) == "function" or type(catch) == "nil", "invalid argument(catch).")
        assert(type(finally) == "function" or type(finally) == "nil", "invalid argument(finally).")
        local num, result = packageResult(xpcall(try, innerFunc, ...))
        if result[1] then
            if finally then
                finally()
            end
            return unpack(result, 2, num)
        else
            if catch then
                num, result = packageResult(xpcall(catch, innerCatchFunc, result[2]))
            end
            if finally then
                finally()
            end
            if not (catch) then
                error("unhandled error: " .. result[2], 2)
            elseif result[1] then
                return unpack(result, 2, num)
            else
                error(result[2], 2)
            end
        end
    end
    plus.TryCatch = tryCatch
end

local BIT_NUMBERS = {
    2147483648,
    1073741824,
    536870912,
    268435456,
    134217728,
    67108864,
    33554432,
    16777216,
    8388608,
    4194304,
    2097152,
    1048576,
    524288,
    262144,
    131072,
    65536,
    32768,
    16384,
    8192,
    4096,
    2048,
    1024,
    512,
    256,
    128,
    64,
    32,
    16,
    8,
    4,
    2,
    1
}

--! @brief 对两个二进制数进行按位与
--! @param a 第一个参数，十进制表示
--! @param b 第二个参数，十进制表示
--! @return 返回布尔值，真则这两个二进制数按位与为真
function plus.BAND(a, b)
    assert(a >= 0 and a < 4294967296 and b >= 0 and b < 4294967296, "invalid argument.")

    local ret = 0
    for i = 1, 32 do
        local w = BIT_NUMBERS[i]
        local flag1 = a >= w
        local flag2 = b >= w
        if flag1 then
            a = a - w
        end
        if flag2 then
            b = b - w
        end
        if flag1 and flag2 then
            ret = ret + w
        end
    end
    return ret
end
