local table = require("table")
local math = require("math")
local lstg = require("lstg")

--------------------------------------------------------------------------------
--- 断言

---@generic T
---@param argument T
---@param required_type type
---@param index integer
---@param function_name string
local function assertArgumentType(argument, required_type, index, function_name)
    local t = type(argument)
    if t ~= required_type then
        error(("bad argument #%d to '%s' (%s expected, got %s)"):format(index, function_name, required_type, t), 3)
    end
end

---@param index integer
---@param function_name string
---@param condition boolean
---@param message string
local function assertTrue(index, function_name, condition, message)
    if not condition then
        error(("bad argument #%d to '%s' (%s)"):format(index, function_name, message), 3)
    end
end

---@param s string
---@return boolean
local function isNotBlank(s)
    if type(s) ~= "string" then
        return false
    end
    local l = s:len()
    if l == 0 then
        return false
    end
    for i = 1, l do
        local c = s:sub(i, i)
        if c == ' ' then
            return false
        end
    end
    return true
end

--------------------------------------------------------------------------------
--- 组

---@generic T
---@param g T
---@return boolean
local function isKnownGroup(g)
    -- 碰撞组是整数，不能直接用 g >= 0 and g <= 15 判断
    for i = 0, 15 do
        if g == i then
            return true
        end
    end
    return false
end

--------------------------------------------------------------------------------
--- 范围

---@alias foundation.IntersectionDetectionManager.KnownScope
---| '"global"'
---| '"stage"'

---@generic T
---@param s T
---@return boolean
local function isKnownScope(s)
    return s == "global" or s == "stage"
end

--------------------------------------------------------------------------------
--- 碰撞组对管理和代理执行

---@class foundation.IntersectionDetectionManager.Entry
---@field uid integer
---@field id string
---@field group1 integer
---@field group2 integer
---@field scope foundation.IntersectionDetectionManager.KnownScope

local counter = 0

---@type table<string, foundation.IntersectionDetectionManager.Entry>
local entries = {}

---@type { [1]: integer, [2]: integer }[]
local merged = {}

--- 合并碰撞组对  
local function merge()
    ---@type foundation.IntersectionDetectionManager.Entry[]
    local list = {}
    for _, v in pairs(entries) do
        table.insert(list, v)
    end
    table.sort(list, function(a, b)
        return a.uid < b.uid
    end)
    ---@type table<integer, boolean>
    local pair_set = {}
    merged = {}
    for _, v in ipairs(list) do
        local k = v.group1 * 100 + v.group2
        if not pair_set[k] then
            pair_set[k] = true
            table.insert(merged, { v.group1, v.group2 })
        end
    end
end

--- 碰撞组对管理和代理执行 `lstg.CollisionCheck`
---@class foundation.IntersectionDetectionManager
local IntersectionDetectionManager = {}

--- 添加碰撞组对，id 由管理器自动生成  
--- 只能添加到 "stage" 范围，离开关卡后自动清理  
---@param group1 number
---@param group2 number
---@diagnostic disable-next-line: duplicate-set-field
function IntersectionDetectionManager.add(group1, group2)
end

---@param group1 number
---@param group2 number
local function add(group1, group2)
    counter = counter + 1
    local id = "foundation:auto-" .. counter
    entries[id] = {
        uid = counter,
        id = id,
        group1 = math.floor(group1),
        group2 = math.floor(group2),
        scope = "stage",
    }
    merge()
end

--- 添加碰撞组对，不填写范围（scope）时默认添加到关卡（"stage"）范围，离开关卡后自动清理  
--- 如果需要添加到全局，范围（scope）需填写 "global"（全局）  
--- 如果 id 重复，将抛出错误  
---@param id string
---@param group1 number
---@param group2 number
---@param scope foundation.IntersectionDetectionManager.KnownScope?
---@diagnostic disable-next-line: duplicate-set-field
function IntersectionDetectionManager.add(id, group1, group2, scope)
    -- 二参数版本
    if type(id) == "number" and type(group1) == "number" and group2 == nil and scope == nil then
        ---@cast id -string, +number
        ---@cast group2 -number, +nil
        ---@cast scope -foundation.IntersectionDetectionManager.KnownScope?, +nil
        return add(id, group1)
    end
    -- 四参数版本
    assertArgumentType(id, "string", 1, "add")
    assertArgumentType(group1, "number", 2, "add")
    assertArgumentType(group2, "number", 3, "add")
    if scope ~= nil then
        assertArgumentType(scope, "string", 4, "add")
    end
    assertTrue(1, "add", isNotBlank(id), "'id' cannot be empty")
    assertTrue(2, "add", isKnownGroup(group1), "'group1' must be in the range 0 to 15")
    assertTrue(3, "add", isKnownGroup(group2), "'group2' must be in the range 0 to 15")
    if scope ~= nil then
        assertTrue(4, "add", isKnownScope(scope), ("unknown scope '%s'"):format(scope))
    end
    assert(not entries[id], ("'id' ('%s') already exists"):format(id))
    counter = counter + 1
    entries[id] = {
        uid = counter,
        id = id,
        group1 = math.floor(group1),
        group2 = math.floor(group2),
        scope = scope or "stage",
    }
    merge()
end

--- 移除碰撞组对  
---@param id string
function IntersectionDetectionManager.removeById(id)
    assertArgumentType(id, "string", 1, "removeById")
    assertTrue(1, "removeById", isNotBlank(id), "'id' cannot be empty")
    entries[id] = nil
    merge()
end

--- 根据范围移除所有相符的碰撞组对  
---@param scope foundation.IntersectionDetectionManager.KnownScope
function IntersectionDetectionManager.removeAllByScope(scope)
    assertArgumentType(scope, "string", 1, "removeAllByScope")
    assertTrue(1, "removeAllByScope", isKnownScope(scope), ("unknown scope '%s'"):format(scope))
    ---@type string[]
    local ids = {}
    for _, v in pairs(entries) do
        if v.scope == scope then
            table.insert(ids, v.id)
        end
    end
    for _, s in ipairs(ids) do
        entries[s] = nil
    end
    merge()
end

--- 代理执行 `lstg.CollisionCheck`  
function IntersectionDetectionManager.execute()
    -- TODO: 等 API 文档更新后，去除下一行的禁用警告
    ---@diagnostic disable-next-line: param-type-mismatch, missing-parameter
    lstg.CollisionCheck(merged)
end

return IntersectionDetectionManager
