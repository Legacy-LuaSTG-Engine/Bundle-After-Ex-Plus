--------------------------------------------------------------------------------
--- 遗留的存档系统，非常恐怖的全局变量 
--------------------------------------------------------------------------------

local DataStorage = require("foundation.DataStorage")
local LocalFileStorage = require("foundation.LocalFileStorage")

-- 用户名里虽然能塞各种奇怪的字符，但路径不允许

local path_replace = {
    ["<"] = "[_less_than_]",
    [">"] = "[_greater_than_]",
    [":"] = "[_colon_]",
    ["\""] = "[_double_quote_]",
    ["/"] = "[_slash_]",
    ["\\"] = "[_backslash_]",
    ["|"] = "[_vertical_bar_]",
    ["?"] = "[_question_mark_]",
    ["*"] = "[_asterisk_]",
}
setmetatable(path_replace, { __index = function(_, k) return k end })

local function getSafeUserName()
    ---@type string
    local str = setting.username
    ---@type string[]
    local span = {}
    for i = 1, str:len() do
        span[i] = path_replace[str:sub(i, i)]
    end
    return table.concat(span)
end

local function getFileName()
    local path = LocalFileStorage.getDataStorageDirectory() .. "/" .. setting.mod
    lstg.FileManager.CreateDirectory(path)
    return path .. "/" .. getSafeUserName() .. ".json"
end

---@type foundation.DataStorage
local global_data_storage

---@class legacy.scoredata
scoredata = nil -- TODO: 铲掉这个屎山

function SaveScoreData()
    if global_data_storage then
        global_data_storage:save()
    end
end

function InitScoreData()
    global_data_storage = DataStorage.open(getFileName())
    ---@type legacy.scoredata
    local root = global_data_storage:root()
    assert(type(root) == "table", "scoredata root is not a table")
    ---@diagnostic disable-next-line: lowercase-global
    scoredata = root
end

function Serialize(o)
	if type(o) == 'table' then
		o = DataStorage._visit(o)
	end
	return cjson.encode(o)
end

function DeSerialize(s)
	return cjson.decode(s)
end
