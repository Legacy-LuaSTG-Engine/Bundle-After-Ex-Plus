local default_setting = require("foundation.legacy.default_setting")
local LocalFileStorage = require("foundation.LocalFileStorage")
local DataStorage = require("foundation.DataStorage")

local input_config = require("foundation.input.config.Manager")
local default_keymap = {
	game = input_config.get_config("game"),
	ui = input_config.get_config("ui"),
	replay = input_config.get_config("replay")
}

local function getSettingPath()
	return LocalFileStorage.getRootDirectory() .. "/setting.json"
end

local function getLaunchConfigPath()
	return LocalFileStorage.getRootDirectory() .. "/config.launch.json"
end

local function getKeymapPath()
	return LocalFileStorage.getRootDirectory() .. "/setting.keymap.json"
end

---@type foundation.DataStorage
local setting_storage

---@type foundation.DataStorage
local launch_config_storage

---@type foundation.DataStorage
local keymap_storage

---@class legacy.setting : legacy.default_setting
setting = nil

---@class legacy.launch_config
local default_launch_config = {
	graphics_system = {
		width = default_setting.resx,
		height = default_setting.resy,
		fullscreen = not default_setting.windowed,
		vsync = default_setting.vsync,
	},
	audio_system = {
		sound_effect_volume = default_setting.sevolume / 100.0,
		music_volume = default_setting.bgmvolume / 100.0,
	},
}

---@type legacy.launch_config
local launch_config

---@diagnostic disable-next-line: lowercase-global
function loadConfigure()
	setting_storage = DataStorage.open(getSettingPath(), default_setting, true)
	---@diagnostic disable-next-line: lowercase-global
	setting = setting_storage:root()
	launch_config_storage = DataStorage.open(getLaunchConfigPath(), default_launch_config, true)
	launch_config = launch_config_storage:root()
	
	keymap_storage = DataStorage.open(getKeymapPath(), default_keymap, true)
end

---@diagnostic disable-next-line: lowercase-global
function saveConfigure()
	setting_storage:save(true, true)
	launch_config.graphics_system.width = setting.resx
	launch_config.graphics_system.height = setting.resy
	launch_config.graphics_system.fullscreen = not setting.windowed
	launch_config.graphics_system.vsync = setting.vsync
	launch_config.audio_system.sound_effect_volume = setting.sevolume / 100.0
	launch_config.audio_system.music_volume = setting.bgmvolume / 100.0
	launch_config_storage:save(true, true)
end

loadConfigure() -- 先加载一次配置
