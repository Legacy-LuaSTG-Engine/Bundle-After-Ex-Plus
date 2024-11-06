local table = require("table")
local math = require("math")
local lstg = require("lstg")

--------------------------------------------------------------------------------
--- 常量，具体数值由 LuaSTG 引擎的版本决定

local FIRST_GROUP = 0
local LAST_GROUP = 15

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
--- 类

---@alias foundation.IntersectionDetectionManager.KnownScope
---| '"global"'
---| '"stage"'

---@generic T
---@param s T
---@return boolean
local function isKnownScope(s)
    return s == "global" or s == "stage"
end

--- 碰撞组对管理和代理执行 `lstg.CollisionCheck`
---@class foundation.IntersectionDetectionManager
local IntersectionDetectionManager = {}

--------------------------------------------------------------------------------
--- 碰撞组管理

---@class foundation.IntersectionDetectionManager.Group
---@field uid integer
---@field id string
---@field group integer
---@field scope foundation.IntersectionDetectionManager.KnownScope

local group_counter = 0

---@type table<string, foundation.IntersectionDetectionManager.Group>
local groups = {}

---@generic T
---@param g T
---@return boolean
local function isValidGroup(g)
    -- 碰撞组是整数，不能直接用 g >= FIRST_GROUP and g <= LAST_GROUP 判断
    for i = FIRST_GROUP, LAST_GROUP do
        if g == i then
            return true
        end
    end
    return false
end

---@generic T
---@param g T
---@return boolean
local function isGroupRegistered(g)
    for _, v in pairs(groups) do
        if v.group == g then
            return true
        end
    end
    return false
end

--- 注册碰撞组，通过该方法注册的碰撞组只能是全局（"global"）范围  
---@param id string
---@param group number
function IntersectionDetectionManager.registerGroup(id, group)
    assertArgumentType(id, "string", 1, "registerGroup")
    assertArgumentType(group, "number", 2, "registerGroup")
    assertTrue(1, "registerGroup", isNotBlank(id), "'id' cannot be empty")
    assertTrue(2, "registerGroup", isValidGroup(group), "'group' must be in the range 0 to 15")
    assert(not groups[id], ("'id' ('%s') already exists"):format(id))
    for _, v in pairs(groups) do
        if v.group == group then
            error(("'group' ('%d') already registered"):format(group))
        end
    end
    group_counter = group_counter + 1
    groups[id] = {
        uid = group_counter,
        id = id,
        group = math.floor(group),
        scope = "global",
    }
end

--- 分配碰撞组，通过该方法得到的碰撞组只能是关卡（"stage"）范围，离开关卡后自动清理  
---@return string id
---@return number group
function IntersectionDetectionManager.allocateGroup()
    ---@type boolean[]
    local allocated = {}
    for _, v in pairs(groups) do
        allocated[v.group] = true
    end
    local group = FIRST_GROUP - 1
    for i = FIRST_GROUP, LAST_GROUP do
        if not allocated[i] then
            group = i
            break
        end
    end
    if group < FIRST_GROUP then
        error("allocate group failed")
    end
    group_counter = group_counter + 1
    local id = "foundation:auto-" .. group_counter
    groups[id] = {
        uid = group_counter,
        id = id,
        group = group,
        scope = "stage",
    }
    return id, group
end

--- 取消注册碰撞组  
---@param id string
function IntersectionDetectionManager.unregisterGroup(id)
    assertArgumentType(id, "string", 1, "unregisterGroup")
    assertTrue(1, "unregisterGroup", isNotBlank(id), "'id' cannot be empty")
    groups[id] = nil
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
        local k = v.group1 * 10000 + v.group2
        if not pair_set[k] then
            pair_set[k] = true
            table.insert(merged, { v.group1, v.group2 })
        end
    end
end

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
    if type(id) == "number" and type(group1) == "number" and group2 == nil and scope == nil then
        -- 二参数版本
        ---@cast id -string, +number
        ---@cast group2 -number, +nil
        ---@cast scope -foundation.IntersectionDetectionManager.KnownScope?, +nil
        return add(id, group1)
    else
        -- 四参数版本
        assertArgumentType(id, "string", 1, "add")
        assertArgumentType(group1, "number", 2, "add")
        assertArgumentType(group2, "number", 3, "add")
        if scope ~= nil then
            assertArgumentType(scope, "string", 4, "add")
        end
        assertTrue(1, "add", isNotBlank(id), "'id' cannot be empty")
        assertTrue(2, "add", isGroupRegistered(group1), "'group1' is not registered")
        assertTrue(3, "add", isGroupRegistered(group2), "'group2' is not registered")
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

--------------------------------------------------------------------------------
--- 调试

function IntersectionDetectionManager.print()
    local function log(fmt, ...)
        lstg.Log(2, fmt:format(...))
    end
    log("foundation.IntersectionDetectionManager")
    log("    groups:")
    do
        ---@type foundation.IntersectionDetectionManager.Group[]
        local list = {}
        for _, v in pairs(groups) do
            table.insert(list, v)
        end
        table.sort(list, function(a, b)
            return a.uid < b.uid
        end)
        for i, v in ipairs(list) do
            log("        %d. id   : '%s' (uid = %d)", i, v.id, v.uid)
            log("            group: (%d - %d)", v.group)
            log("            scope: '%s'", v.scope)
        end
    end
    log("    entries:")
    do
        ---@type foundation.IntersectionDetectionManager.Entry[]
        local list = {}
        for _, v in pairs(entries) do
            table.insert(list, v)
        end
        table.sort(list, function(a, b)
            return a.uid < b.uid
        end)
        for i, v in ipairs(list) do
            log("        %d. id    : '%s' (uid = %d)", i, v.id, v.uid)
            log("            groups: (%d - %d)", v.group1, v.group2)
            log("            scope : '%s'", v.scope)
        end
    end
    log("    merged:")
    for i, v in ipairs(merged) do
        log("        %d. groups: (%d - %d)", i, v[1], v[2])
    end
end

return IntersectionDetectionManager
