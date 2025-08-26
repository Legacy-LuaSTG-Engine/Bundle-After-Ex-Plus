local default_setting = require("foundation.legacy.default_setting")
local LocalFileStorage = require("foundation.LocalFileStorage")
local DataStorage = require("foundation.DataStorage")

local function getSettingPath()
	return LocalFileStorage.getRootDirectory() .. "/setting.json"
end

local function getLaunchConfigPath()
	return LocalFileStorage.getRootDirectory() .. "/config.launch.json"
end

---@type foundation.DataStorage
local setting_storage

---@type foundation.DataStorage
local launch_config_storage

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

---@generic T
---@param t T
local function fillZero(t)
	for k, _ in pairs(t) do
		t[k] = 0
	end
end

---@diagnostic disable-next-line: lowercase-global
function loadConfigure()
	setting_storage = DataStorage.open(getSettingPath(), default_setting, true)
	---@type legacy.setting
	local setting_root = setting_storage:root()
	fillZero(setting_root.keys) ---@diagnostic disable-line: deprecated
	fillZero(setting_root.keys2) ---@diagnostic disable-line: deprecated
	fillZero(setting_root.keysys) ---@diagnostic disable-line: deprecated
	setting = setting_storage:root() ---@diagnostic disable-line: lowercase-global

	launch_config_storage = DataStorage.open(getLaunchConfigPath(), default_launch_config, true)
	launch_config = launch_config_storage:root()
end

---@diagnostic disable-next-line: lowercase-global
function saveConfigure()
	---@type legacy.setting
	local setting_root = setting_storage:root()
	local keys = setting_root.keys ---@diagnostic disable-line: deprecated
	local keys2 = setting_root.keys2 ---@diagnostic disable-line: deprecated
	local sys_keys = setting_root.keysys ---@diagnostic disable-line: deprecated
	setting_root.keys = nil ---@diagnostic disable-line: deprecated
	setting_root.keys2 = nil ---@diagnostic disable-line: deprecated
	setting_root.keysys = nil ---@diagnostic disable-line: deprecated

	setting_storage:save(true, true)

	setting_root.keys = keys ---@diagnostic disable-line: deprecated
	setting_root.keys2 = keys2 ---@diagnostic disable-line: deprecated
	setting_root.keysys = sys_keys ---@diagnostic disable-line: deprecated

	launch_config.graphics_system.width = setting.resx
	launch_config.graphics_system.height = setting.resy
	launch_config.graphics_system.fullscreen = not setting.windowed
	launch_config.graphics_system.vsync = setting.vsync
	launch_config.audio_system.sound_effect_volume = setting.sevolume / 100.0
	launch_config.audio_system.music_volume = setting.bgmvolume / 100.0
	launch_config_storage:save(true, true)
end

loadConfigure() -- 先加载一次配置
