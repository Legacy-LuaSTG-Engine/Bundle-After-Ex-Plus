local lstg = require("lstg")
local Keyboard = lstg.Input.Keyboard

---@class legacy.default_setting.player_keys
local p1 = {
	up = Keyboard.Up,
	down = Keyboard.Down,
	left = Keyboard.Left,
	right = Keyboard.Right,
	slow = Keyboard.LeftShift,
	shoot = Keyboard.Z,
	spell = Keyboard.X,
	special = Keyboard.C,
}

---@type legacy.default_setting.player_keys
local p2 = {
	up = Keyboard.NumPad5,
	down = Keyboard.NumPad2,
	left = Keyboard.NumPad1,
	right = Keyboard.NumPad3,
	slow = Keyboard.A,
	shoot = Keyboard.S,
	spell = Keyboard.D,
	special = Keyboard.F,
}

---@class legacy.default_setting.system_keys
local sys = {
	repfast = Keyboard.LeftControl,
	repslow = Keyboard.LeftShift,
	menu = Keyboard.Escape,
	snapshot = Keyboard.P,
	retry = Keyboard.R,
}

---@class legacy.default_setting
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
	keys = p1,
	keys2 = p2,
	keysys = sys,
}

return default_setting
