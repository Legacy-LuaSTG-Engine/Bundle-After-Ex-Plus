--- 注意：这些设置项已弃用，目前仅处于兼容性考虑保留  
--- 注意：按键码由输入系统定期覆盖，请不要尝试修改它
---@deprecated
---@class legacy.default_setting.player_keys
local p1 = {
	--- 注意：这些设置项已弃用，目前仅处于兼容性考虑保留  
	--- 注意：按键码由输入系统定期覆盖，请不要尝试修改它
	---@deprecated
	up = 0,
	--- 注意：这些设置项已弃用，目前仅处于兼容性考虑保留  
	--- 注意：按键码由输入系统定期覆盖，请不要尝试修改它
	---@deprecated
	down = 0,
	--- 注意：这些设置项已弃用，目前仅处于兼容性考虑保留  
	--- 注意：按键码由输入系统定期覆盖，请不要尝试修改它
	---@deprecated
	left = 0,
	--- 注意：这些设置项已弃用，目前仅处于兼容性考虑保留  
	--- 注意：按键码由输入系统定期覆盖，请不要尝试修改它
	---@deprecated
	right = 0,
	--- 注意：这些设置项已弃用，目前仅处于兼容性考虑保留  
	--- 注意：按键码由输入系统定期覆盖，请不要尝试修改它
	---@deprecated
	slow = 0,
	--- 注意：这些设置项已弃用，目前仅处于兼容性考虑保留  
	--- 注意：按键码由输入系统定期覆盖，请不要尝试修改它
	---@deprecated
	shoot = 0,
		--- 注意：这些设置项已弃用，目前仅处于兼容性考虑保留  
	--- 注意：按键码由输入系统定期覆盖，请不要尝试修改它
	---@deprecated
	spell = 0,
	--- 注意：这些设置项已弃用，目前仅处于兼容性考虑保留  
	--- 注意：按键码由输入系统定期覆盖，请不要尝试修改它
	---@deprecated
	special = 0,
}

--- 注意：这些设置项已弃用，目前仅处于兼容性考虑保留  
--- 注意：按键码由输入系统定期覆盖，请不要尝试修改它
---@deprecated
---@class legacy.default_setting.system_keys
local sys = {
	--- 注意：这些设置项已弃用，目前仅处于兼容性考虑保留  
	--- 注意：按键码由输入系统定期覆盖，请不要尝试修改它
	---@deprecated
	repfast = 0,
	--- 注意：这些设置项已弃用，目前仅处于兼容性考虑保留  
	--- 注意：按键码由输入系统定期覆盖，请不要尝试修改它
	---@deprecated
	repslow = 0,
	--- 注意：这些设置项已弃用，目前仅处于兼容性考虑保留  
	--- 注意：按键码由输入系统定期覆盖，请不要尝试修改它
	---@deprecated
	menu = 0,
	--- 注意：这些设置项已弃用，目前仅处于兼容性考虑保留  
	--- 注意：按键码由输入系统定期覆盖，请不要尝试修改它
	---@deprecated
	snapshot = 0,
	--- 注意：这些设置项已弃用，目前仅处于兼容性考虑保留  
	--- 注意：按键码由输入系统定期覆盖，请不要尝试修改它
	---@deprecated
	retry = 0,
}

---@generic T
---@param t T
---@return T t
local function copy(t)
	local r = {}
	for k, v in pairs(t) do
		r[k] = v
	end
	return r
end

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

	--- 注意：这些设置项已弃用，目前仅处于兼容性考虑保留  
	--- 注意：按键码由输入系统定期覆盖，请不要尝试修改它
	---@deprecated
	---@type legacy.default_setting.player_keys
	keys = p1,
	--- 注意：这些设置项已弃用，目前仅处于兼容性考虑保留  
	--- 注意：按键码由输入系统定期覆盖，请不要尝试修改它  
	---@deprecated
	---@type legacy.default_setting.player_keys
	keys2 = copy(p1),
	--- 注意：这些设置项已弃用，目前仅处于兼容性考虑保留  
	--- 注意：按键码由输入系统定期覆盖，请不要尝试修改它  
	---@deprecated
	keysys = sys,
}

return default_setting
