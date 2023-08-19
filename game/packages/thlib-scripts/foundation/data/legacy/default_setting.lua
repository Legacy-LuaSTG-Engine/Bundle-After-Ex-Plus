
---@class legacy.default_setting.player_keys
local p1 = {
	up = KEY.UP,
	down = KEY.DOWN,
	left = KEY.LEFT,
	right = KEY.RIGHT,
	slow = KEY.SHIFT,
	shoot = KEY.Z,
	spell = KEY.X,
	special = KEY.C,
}

---@type legacy.default_setting.player_keys
local p2 = {
	up = KEY.NUMPAD5,
	down = KEY.NUMPAD2,
	left = KEY.NUMPAD1,
	right = KEY.NUMPAD3,
	slow = KEY.A,
	shoot = KEY.S,
	spell = KEY.D,
	special = KEY.F,
}

---@class legacy.default_setting.system_keys
local sys = {
	repfast = KEY.CTRL,
	repslow = KEY.SHIFT,
	menu = KEY.ESCAPE,
	snapshot = KEY.HOME,
	retry = KEY.R,
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
