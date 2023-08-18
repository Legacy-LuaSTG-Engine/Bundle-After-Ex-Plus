default_setting = {
	username = 'User',
	locale = "zh_cn",
	timezone = 8,
	resx = 640,
	resy = 480,
	windowed = true,
	vsync = false,
	sevolume = 100,
	bgmvolume = 100,
	keys = {
		up = KEY.UP,
		down = KEY.DOWN,
		left = KEY.LEFT,
		right = KEY.RIGHT,
		slow = KEY.SHIFT,
		shoot = KEY.Z,
		spell = KEY.X,
		special = KEY.C,
	},
	keys2 = {
		up = KEY.NUMPAD5,
		down = KEY.NUMPAD2,
		left = KEY.NUMPAD1,
		right = KEY.NUMPAD3,
		slow = KEY.A,
		shoot = KEY.S,
		spell = KEY.D,
		special = KEY.F,
	},
	keysys = {
		repfast = KEY.CTRL,
		repslow = KEY.SHIFT,
		menu = KEY.ESCAPE,
		snapshot = KEY.HOME,
		retry = KEY.R,
	},
}

---@param str string
---@return string
local function format_json(str)
	local ret = ''
	local indent = '	'
	local level = 0
	local in_string = false
	for i = 1, #str do
		local s = string.sub(str, i, i)
		if s == '{' and (not in_string) then
			level = level + 1
			ret = ret .. '{\n' .. string.rep(indent, level)
		elseif s == '}' and (not in_string) then
			level = level - 1
			ret = string.format(
				'%s\n%s}', ret, string.rep(indent, level))
		elseif s == '"' then
			in_string = not in_string
			ret = ret .. '"'
		elseif s == ':' and (not in_string) then
			ret = ret .. ': '
		elseif s == ',' and (not in_string) then
			ret = ret .. ',\n'
			ret = ret .. string.rep(indent, level)
		elseif s == '[' and (not in_string) then
			level = level + 1
			ret = ret .. '[\n' .. string.rep(indent, level)
		elseif s == ']' and (not in_string) then
			level = level - 1
			ret = string.format(
				'%s\n%s]', ret, string.rep(indent, level))
		else
			ret = ret .. s
		end
	end
	return ret
end

string.format_json = format_json

local function get_file_name()
	return lstg.LocalUserData.GetRootDirectory() .. "/setting.json"
end

local function safe_encode_json(t)
	local r, e = pcall(cjson.encode, t)
	if r then
		return e
	else
		lstg.Log(4, "encode table to json failed: " .. tostring(e))
		return cjson.encode(default_setting)
	end
end

local function safe_decode_json(s)
	local r, e = pcall(cjson.decode, s)
	if r then
		return e
	else
		lstg.Log(4, "decode json to table failed: " .. tostring(e))
		return cjson.decode(cjson.encode(s)) -- copy
	end
end

function loadConfigure()
	local f, msg
	f, msg = io.open(get_file_name(), 'r')
	if f == nil then
		setting = safe_decode_json(safe_encode_json(default_setting))
	else
		setting = safe_decode_json(f:read('*a'))
		f:close()
	end
end

function saveConfigure()
	local f, msg
	f, msg = io.open(get_file_name(), 'w')
	if f == nil then
		error(msg)
	else
		f:write(format_json(safe_encode_json(setting)))
		f:close()
	end
end

function loadConfigureTable()
	local f, msg
	f, msg = io.open(get_file_name(), 'r')
	if f == nil then
		local t = safe_decode_json(safe_encode_json(default_setting))
		return t
	else
		local t = safe_decode_json(f:read('*a'))
		f:close()
		return t
	end
end

function saveConfigureTable(t)
	local f, msg
	f, msg = io.open(get_file_name(), 'w')
	if f == nil then
		error(msg)
	else
		f:write(format_json(safe_encode_json(t)))
		f:close()
	end
end

loadConfigure() -- 先加载一次配置
