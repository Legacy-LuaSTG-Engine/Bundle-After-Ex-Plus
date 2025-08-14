--------------------------------------------------------------------------------
--- SPDX-License-Identifier: MIT
--- description: 输入辅助库
--- version: 0.2.2
--- author: 璀境石
--- detail: 一些实用函数
--------------------------------------------------------------------------------

---@param y number
---@param x number
---@return number
local function atan(y, x)
    if math.atan2 then
        return math.atan2(y, x)
    else
        ---@diagnostic disable-next-line: redundant-parameter
        return math.atan(y, x)
    end
end

---@class foundation.input.helper
local M = {}

---@param max_length number
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
---@return number
function M.compositeVector2(max_length, x1, y1, x2, y2)
    local x = x1 + x2
    local y = y1 + y2
    local a = atan(y, x)
    local r = math.min(math.sqrt(x * x + y * y), max_length)
    return r * math.cos(a), r * math.sin(a)
end

return M
