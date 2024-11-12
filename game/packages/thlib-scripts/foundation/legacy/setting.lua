local cjson_util = require("cjson.util")
local default_setting = require("foundation.legacy.default_setting")
local LocalFileStorage = require("foundation.LocalFileStorage")

local function get_file_name()
	return LocalFileStorage.getRootDirectory() .. "/setting.json"
end

local function get_file_name_launch()
	return LocalFileStorage.getRootDirectory() .. "/launch.json"
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

local function write_file(path, content)
	local f = assert(io.open(path, "w"))
	f:write(content)
	f:close()
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
	local content = cjson_util.format_json(safe_encode_json(setting))
	write_file(get_file_name(), content)
	local content_launch = cjson_util.format_json(safe_encode_json({
		initialize = {
			graphics_system = {
				width = setting.resx,
				height = setting.resy,
				fullscreen = not setting.windowed,
				vsync = setting.vsync,
			},
			audio_system = {
				sound_effect_volume = setting.sevolume / 100.0,
				music_volume = setting.bgmvolume / 100.0,
			},
		},
	}))
	write_file(get_file_name_launch(), content_launch)
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
	local content = cjson_util.format_json(safe_encode_json(t))
	write_file(get_file_name(), content)
end

loadConfigure() -- 先加载一次配置
