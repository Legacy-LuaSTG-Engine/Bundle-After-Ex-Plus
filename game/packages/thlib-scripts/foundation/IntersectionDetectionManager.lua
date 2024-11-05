local table = require("table")
local lstg = require("lstg")

---@alias foundation.IntersectionDetectionManager.KnownTag
---| '"global"'
---| '"stage"'

---@class foundation.IntersectionDetectionManager
local IntersectionDetectionManager = {}

--- { group1, group2, tag }
---@type { [1]:number, [2]:number, tag:string }[]
local pairs = {}

---@param group1 number
---@param group2 number
---@return boolean
function IntersectionDetectionManager.hasPair(group1, group2)
    for _, pair in ipairs(pairs) do
        if pair[1] == group1 and pair[2] == group2 then
            return true
        end
    end
    return false
end

---@param group1 number
---@param group2 number
---@param tag foundation.IntersectionDetectionManager.KnownTag?
---@return boolean
function IntersectionDetectionManager.addPair(group1, group2, tag)
    if IntersectionDetectionManager.hasPair(group1, group2) then
        return false
    end
    table.insert(pairs, { group1, group2; tag = tag or "global" })
    return true
end

---@param group1 number
---@param group2 number
---@return boolean
function IntersectionDetectionManager.removePair(group1, group2)
    for i, pair in ipairs(pairs) do
        if pair[1] == group1 and pair[2] == group2 then
            table.remove(pairs, i)
            return true
        end
    end
    return false
end

---@param tag foundation.IntersectionDetectionManager.KnownTag
function IntersectionDetectionManager.removeAllByTag(tag)
    for i = #pairs, 1, -1 do
        if pairs[i].tag == tag then
            table.remove(pairs, i)
        end
    end
end

function IntersectionDetectionManager.removeAll()
    pairs = {}
end

function IntersectionDetectionManager.execute()
    -- TODO: 等 API 文档更新后，去除下一行的禁用警告
    ---@diagnostic disable-next-line: param-type-mismatch, missing-parameter
    lstg.CollisionCheck(pairs)
end

return IntersectionDetectionManager
