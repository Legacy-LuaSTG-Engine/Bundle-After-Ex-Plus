---=====================================
---luastg scoredata
---=====================================

----------------------------------------
---scoredata

local function make_scoredata_table(t) end

local function scoredata_mt_newindex(t, k, v)
    if type(k) ~= "string" and type(k) ~= "number" then
        error("Invalid key type \"" .. type(k) .. "\"")
    end
    if type(v) == "function" or type(v) == "userdata" or type(v) == "thread" then
        error("Invalid value type \"" .. type(v) .. "\"")
    end
    if type(v) == "table" then
        make_scoredata_table(v)
    end
    getmetatable(t).data[k] = v
    SaveScoreData()
end

local function scoredata_mt_index(t, k)
    return getmetatable(t).data[k]
end

local function new_scoredata_table()
    local t = {}
    setmetatable(t, { __newindex = scoredata_mt_newindex, __index = scoredata_mt_index, data = {} })
    return t
end

function make_scoredata_table(t)
    if type(t) ~= "table" then
        error("t must be a table")
    end
    Serialize(t)
    setmetatable(t, { __newindex = scoredata_mt_newindex, __index = scoredata_mt_index, data = {} })
    for k, v in pairs(t) do
        if type(v) == "table" then
            make_scoredata_table(v)
        end
        getmetatable(t).data[k] = v
        t[k] = nil
    end
end

local function DefineDefaultScoreData(t)
    scoredata = t
end

-- 想不到吧，用户名里虽然能塞各种奇怪的字符，但是路径可是不允许的

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

local function get_safe_username()
    ---@type string
    local str = setting.username
    ---@type string[]
    local span = {}
    for i = 1, str:len() do
        span[i] = path_replace[str:sub(i, i)]
    end
    return table.concat(span)
end

local function get_file_name()
    local path = lstg.LocalUserData.GetDatabaseDirectory() .. "/" .. setting.mod
    lstg.FileManager.CreateDirectory(path)
    return path .. "/" .. get_safe_username() .. ".json"
end

function SaveScoreData()
    local score_data_file = assert(io.open(get_file_name(), "w"))
    local s = Serialize(scoredata)
    score_data_file:write(string.format_json(s))
    score_data_file:close()
end

function InitScoreData()
    local file = get_file_name()
    if lstg.FileManager.FileExist(file) then
        local scoredata_file = assert(io.open(file, "r"))
        scoredata = DeSerialize(scoredata_file:read("*a"))
        scoredata_file:close()
    else
        if scoredata == nil then
            scoredata = {}
        end
        if type(scoredata) ~= "table" then
            error("scoredata must be a Lua table.")
        end
    end
    make_scoredata_table(scoredata)
end

local function visitTable(t)
	local ret = {}
	if getmetatable(t) and getmetatable(t).data then
		t = getmetatable(t).data
	end
	for k, v in pairs(t) do
		if type(v) == 'table' then
			ret[k] = visitTable(v)
		else
			ret[k] = v
		end
	end
	return ret
end

function Serialize(o)
	if type(o) == 'table' then
		-- 特殊处理：lstg中部分表将数据保存在metatable的data域中，因此对于table必须重新生成一个干净的table进行序列化操作
		o = visitTable(o)
	end
	return cjson.encode(o)
end

function DeSerialize(s)
	return cjson.decode(s)
end
