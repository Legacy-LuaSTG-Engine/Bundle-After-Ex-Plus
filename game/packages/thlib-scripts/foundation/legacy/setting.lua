local cjson_util = require("cjson.util")
local default_setting = require("foundation.legacy.default_setting")
local LocalFileStorage = require("foundation.LocalFileStorage")
local DataStorage = require("foundation.DataStorage")

local function get_file_name()
	return LocalFileStorage.getRootDirectory() .. "/setting.json"
end

local function get_file_name_launch()
	return LocalFileStorage.getRootDirectory() .. "/config.launch.json"
end

---@type foundation.DataStorage
local setting_storage, launch_storage

function loadConfigure()
	setting_storage = DataStorage.open(get_file_name(), default_setting)
	setting = setting_storage:root()
end

function saveConfigure()
	setting_storage:save(true, true)

	launch_storage = DataStorage.open(get_file_name_launch())
	local launch_content = launch_storage:root()
	launch_content.graphics_system = {
		width = setting.resx,
		height = setting.resy,
		fullscreen = not setting.windowed,
		vsync = setting.vsync,
	}
	launch_content.audio_system = {
		sound_effect_volume = setting.sevolume / 100.0,
		music_volume = setting.bgmvolume / 100.0,
	}
	launch_storage:save(true, true)
end

loadConfigure() -- 先加载一次配置
