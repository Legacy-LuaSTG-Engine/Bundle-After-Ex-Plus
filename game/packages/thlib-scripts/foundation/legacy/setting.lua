local cjson_util = require("cjson.util")
local default_setting = require("foundation.legacy.default_setting")
local LocalFileStorage = require("foundation.LocalFileStorage")

local input_config = require("foundation.input.config.Manager")
local default_keymap = {
	game = input_config.get_config("game"),
	ui = input_config.get_config("ui"),
	replay = input_config.get_config("replay")
}


local function get_file_name()
	return LocalFileStorage.getRootDirectory() .. "/setting.json"
end

local function get_file_name_launch()
	return LocalFileStorage.getRootDirectory() .. "/config.launch.json"
end

local function get_file_name_keymap()
	return LocalFileStorage.getRootDirectory() .. "/setting.keymap.json"
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

	f, msg = io.open(get_file_name_keymap(), 'r')
	local keymap
	if f == nil then
		keymap = safe_decode_json(safe_encode_json(default_keymap))
	else
		keymap = safe_decode_json(f:read('*a'))
		f:close()
		local category_list = {"game", "ui", "replay"}
		local adapter_type_list = {"keyboard_map", "mouse_map", "controller_map", "hid_map"}
		for _, v in ipairs(category_list) do
			if keymap[v] and type(keymap[v]) == "table" then
				local valid = true
				for _, w in ipairs(adapter_type_list) do
					if keymap[v][w] and type(keymap[v][w]) == "table" then
						if #input_config.check_conflict(keymap[v][w], w, v) > 0 then
							valid = false
							break
						end
					end
				end
				if valid then
					input_config.set_config(keymap[v], v)
				end
			end
		end
	end
end

function saveConfigure()
	local content = cjson_util.format_json(safe_encode_json(setting))
	write_file(get_file_name(), content)
	local content_launch = cjson_util.format_json(safe_encode_json({
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
	}))
	write_file(get_file_name_launch(), content_launch)
	local keymap = cjson_util.format_json(safe_encode_json({
		game = input_config.get_config("game"),
		ui = input_config.get_config("ui"),
		replay = input_config.get_config("replay")
	}))
	write_file(get_file_name_keymap(), keymap)
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
