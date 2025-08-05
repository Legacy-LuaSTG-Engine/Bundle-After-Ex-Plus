---@class foundation.input.config.manager
local M = {}

local keyboard = lstg.Input.Keyboard
local mouse = lstg.Input.Mouse
local xinput_ex = require("foundation.input.adapter.Xinput")
local dinput_ex = require("foundation.input.adapter.DirectInput")

---@alias foundation.input.config.category "game" | "ui" | "replay" | "default"
---@alias foundation.input.config.adapter_type "keyboard_map" | "mouse_map" | "controller_map" | "hid_map"

---@type table<foundation.input.config.category, table<foundation.input.config.adapter_type, table<string, any> > >
M.configs = {
    default = {
        keyboard_map = {
            enable = true,
            boolean = {
                -- 基本单元
                up = { keyboard.Up },
                down = { keyboard.Down },
                left = { keyboard.Left },
                right = { keyboard.Right },
                shoot = { keyboard.Z },
                spell = { keyboard.X },
                -- 自机
                slow = { keyboard.LeftShift },
                special = { keyboard.C },
                -- replay
                repfast = { keyboard.LeftControl },
                repslow = { keyboard.LeftShift },
                -- 菜单
                menu = { keyboard.Escape },
                snapshot = { keyboard.Home },
                retry = { keyboard.R },
                -- 新增加
                skip = { keyboard.LeftControl }
            },
            scalar = {},
            vector2 = {
                move = {
                    x_positive = {keyboard.Right},
                    x_negative = {keyboard.Left},
                    y_positive = {keyboard.Up},
                    y_negative = {keyboard.Down},
                    component_scalar = 1
                }
            },
        },
        mouse_map = {
            enable = false,
            boolean = {
                -- 基本单元
                up = { mouse.None },
                down = { mouse.None },
                left = { mouse.None },
                right = { mouse.None },
                shoot = { mouse.Left },
                spell = { mouse.Right },
                -- 自机
                slow = { mouse.None },
                special = { mouse.None },
                -- replay
                repfast = { mouse.None },
                repslow = { mouse.None },
                -- 菜单
                menu = { mouse.Middle },
                snapshot = { mouse.None },
                retry = { mouse.None },
                skip = { mouse.None }
            },
            scalar = {},
            vector2 = {
                cursor = true
            },
        },
        controller_map = {
            enable = true,
            device_index = 0, -- 填 0 代表自动选择，在 xinput 中，最多支持 4 个设备，也就是 1 到 4
            boolean = {
                -- 基本单元
                up = {
                    xinput_ex.Key.Up,
                    xinput_ex.Key.LeftThumbPositiveY,
                    --xinput_ex.Key.RightThumbPositiveY,
                },
                down = {
                    xinput_ex.Key.Down,
                    xinput_ex.Key.LeftThumbNegativeY,
                    --xinput_ex.Key.RightThumbNegativeY,
                },
                left = {
                    xinput_ex.Key.Left,
                    xinput_ex.Key.LeftThumbNegativeX,
                    --xinput_ex.Key.RightThumbNegativeX,
                },
                right = {
                    xinput_ex.Key.Right,
                    xinput_ex.Key.LeftThumbPositiveX,
                    --xinput_ex.Key.RightThumbPositiveX,
                },
                shoot = { xinput_ex.Key.A },
                spell = { xinput_ex.Key.B },
                -- 自机
                slow = { xinput_ex.Key.LeftShoulder },
                special = { xinput_ex.Key.X },
                -- replay
                repfast = { xinput_ex.Key.LeftTrigger },
                repslow = { xinput_ex.Key.LeftShoulder },
                -- 菜单
                menu = { xinput_ex.Key.Start },
                snapshot = { xinput_ex.Key.RightTrigger },
                retry = { xinput_ex.Key.Back },
                skip = { xinput_ex.Key.LeftTrigger }
            },
            scalar = {},
            vector2 = {
                move = { 1 }, -- 1 代表左摇杆，2代表右摇杆
            },
        },
        hid_map = {
            enable = true,
            device_index = 0, -- 填 0 代表自动选择
            boolean = {
                -- 基本单元
                up = { dinput_ex.Key.NegativeAxisY },
                down = { dinput_ex.Key.PositiveAxisY },
                left = { dinput_ex.Key.NegativeAxisX },
                right = { dinput_ex.Key.PositiveAxisX },
                shoot = { dinput_ex.Key.Button2 },
                spell = { dinput_ex.Key.Button3 },
                -- 自机
                slow = { dinput_ex.Key.Button5 },
                special = { dinput_ex.Key.Button1 },
                -- replay
                repfast = { dinput_ex.Key.Null },
                repslow = { dinput_ex.Key.Null },
                -- 菜单
                menu = { dinput_ex.Key.Button4 },
                snapshot = { dinput_ex.Key.Null },
                retry = { dinput_ex.Key.Null },
                skip = { dinput_ex.Key.Null }
            },
            scalar = {},
            vector2 = {},
        }
    },
    ui = {
        keyboard_map = {
            enable = true,
            boolean = {
                -- 基本单元
                up = { keyboard.Up },
                down = { keyboard.Down },
                left = { keyboard.Left },
                right = { keyboard.Right },
                shoot = { keyboard.Z },
                spell = { keyboard.X },
                -- 自机
                slow = { keyboard.LeftShift },
                special = { keyboard.C },
                -- 菜单
                menu = { keyboard.Escape },
                snapshot = { keyboard.Home },
                retry = { keyboard.R },
                -- 新增加
                skip = { keyboard.LeftControl }
            },
            scalar = {},
            vector2 = {},
        },
        mouse_map = {
            enable = false,
            boolean = {
                -- 基本单元
                up = { mouse.None },
                down = { mouse.None },
                left = { mouse.None },
                right = { mouse.None },
                shoot = { mouse.Left },
                spell = { mouse.Right },
                -- 自机
                slow = { mouse.None },
                special = { mouse.None },
                -- 菜单
                menu = { mouse.Middle },
                snapshot = { mouse.None },
                retry = { mouse.None },
                skip = { mouse.None }
            },
            scalar = {},
            vector2 = {
                cursor = true
            },
        },
        controller_map = {
            enable = true,
            device_index = 0, -- 填 0 代表自动选择，在 xinput 中，最多支持 4 个设备，也就是 1 到 4
            boolean = {
                -- 基本单元
                up = {
                    xinput_ex.Key.Up,
                    xinput_ex.Key.LeftThumbPositiveY,
                    --xinput_ex.Key.RightThumbPositiveY,
                },
                down = {
                    xinput_ex.Key.Down,
                    xinput_ex.Key.LeftThumbNegativeY,
                    --xinput_ex.Key.RightThumbNegativeY,
                },
                left = {
                    xinput_ex.Key.Left,
                    xinput_ex.Key.LeftThumbNegativeX,
                    --xinput_ex.Key.RightThumbNegativeX,
                },
                right = {
                    xinput_ex.Key.Right,
                    xinput_ex.Key.LeftThumbPositiveX,
                    --xinput_ex.Key.RightThumbPositiveX,
                },
                shoot = { xinput_ex.Key.A },
                spell = { xinput_ex.Key.B },
                -- 自机
                slow = { xinput_ex.Key.LeftShoulder },
                special = { xinput_ex.Key.X },
                -- 菜单
                menu = { xinput_ex.Key.Start },
                snapshot = { xinput_ex.Key.RightTrigger },
                retry = { xinput_ex.Key.Back },
                skip = { xinput_ex.Key.LeftTrigger }
            },
            scalar = {},
            vector2 = {
            },
        },
        hid_map = {
            enable = true,
            device_index = 0, -- 填 0 代表自动选择
            boolean = {
                -- 基本单元
                up = { dinput_ex.Key.NegativeAxisY },
                down = { dinput_ex.Key.PositiveAxisY },
                left = { dinput_ex.Key.NegativeAxisX },
                right = { dinput_ex.Key.PositiveAxisX },
                shoot = { dinput_ex.Key.Button2 },
                spell = { dinput_ex.Key.Button3 },
                -- 自机
                slow = { dinput_ex.Key.Button5 },
                special = { dinput_ex.Key.Button1 },
                -- 菜单
                menu = { dinput_ex.Key.Button4 },
                snapshot = { dinput_ex.Key.Null },
                retry = { dinput_ex.Key.Null },
                skip = { dinput_ex.Key.Null }
            },
            scalar = {},
            vector2 = {},
        }
    },
    game = {
        keyboard_map = {
            enable = true,
            boolean = {
                -- 基本单元
                shoot = { keyboard.Z },
                spell = { keyboard.X },
                -- 自机
                slow = { keyboard.LeftShift },
                special = { keyboard.C },
                -- 菜单
                menu = { keyboard.Escape },
                snapshot = { keyboard.Home },
                -- 新增加
                skip = { keyboard.LeftControl }
            },
            scalar = {},
            vector2 = {
                move = {
                    x_positive = {keyboard.Right},
                    x_negative = {keyboard.Left},
                    y_positive = {keyboard.Up},
                    y_negative = {keyboard.Down},
                    component_scalar = 1
                }
            },
        },
        mouse_map = {
            enable = false,
            boolean = {
                -- 基本单元
                shoot = { mouse.Left },
                spell = { mouse.Right },
                -- 自机
                slow = { mouse.None },
                special = { mouse.None },
                -- 菜单
                menu = { mouse.Middle },
                snapshot = { mouse.None },
                skip = { mouse.None }
            },
            scalar = {},
            vector2 = {
                cursor = true
            },
        },
        controller_map = {
            enable = true,
            device_index = 0, -- 填 0 代表自动选择，在 xinput 中，最多支持 4 个设备，也就是 1 到 4
            boolean = {
                -- 基本单元
                shoot = { xinput_ex.Key.A },
                spell = { xinput_ex.Key.B },
                -- 自机
                slow = { xinput_ex.Key.LeftShoulder },
                special = { xinput_ex.Key.X },
                -- 菜单
                menu = { xinput_ex.Key.Start },
                snapshot = { xinput_ex.Key.RightTrigger },
                skip = { xinput_ex.Key.LeftTrigger }
            },
            scalar = {},
            vector2 = {
                move = { 1 }, -- 1 代表左摇杆，2代表右摇杆
            },
        },
        hid_map = {
            enable = true,
            device_index = 0, -- 填 0 代表自动选择
            boolean = {
                shoot = { dinput_ex.Key.Button2 },
                spell = { dinput_ex.Key.Button3 },
                -- 自机
                slow = { dinput_ex.Key.Button5 },
                special = { dinput_ex.Key.Button1 },
                -- 菜单
                menu = { dinput_ex.Key.Button4 },
                snapshot = { dinput_ex.Key.Null },
                skip = { dinput_ex.Key.Null }
            },
            scalar = {},
            vector2 = {},
        }
    },
    replay = {
        keyboard_map = {
            enable = true,
            boolean = {
                -- replay
                repfast = { keyboard.LeftControl },
                repslow = { keyboard.LeftShift },
                -- 菜单
                menu = { keyboard.Escape },
                snapshot = { keyboard.Home },
            },
            scalar = {},
            vector2 = {},
        },
        mouse_map = {
            enable = false,
            boolean = {
                -- replay
                repfast = { mouse.None },
                repslow = { mouse.None },
                -- 菜单
                menu = { mouse.Middle },
                snapshot = { mouse.None },
            },
            scalar = {},
            vector2 = {
                cursor = true
            },
        },
        controller_map = {
            enable = true,
            device_index = 0, -- 填 0 代表自动选择，在 xinput 中，最多支持 4 个设备，也就是 1 到 4
            boolean = {
                -- replay
                repfast = { xinput_ex.Key.LeftTrigger },
                repslow = { xinput_ex.Key.LeftShoulder },
                -- 菜单
                menu = { xinput_ex.Key.Start },
                snapshot = { xinput_ex.Key.RightTrigger },
            },
            scalar = {},
            vector2 = {},
        },
        hid_map = {
            enable = true,
            device_index = 0, -- 填 0 代表自动选择
            boolean = {
                -- replay
                repfast = { dinput_ex.Key.Null },
                repslow = { dinput_ex.Key.Null },
                -- 菜单
                menu = { dinput_ex.Key.Button4 },
                snapshot = { dinput_ex.Key.Null },
            },
            scalar = {},
            vector2 = {},
        }
    }
}

---@type foundation.input.config.category
M.current_config = "default"

---@type table<foundation.input.config.category, table<string, string[]>>
M.conflict_check = {
    game = {
        boolean = { "shoot", "spell", "slow", "special", "menu", "snapshot", "skip" },
        vector2 = { "move" }
    },
    ui = {
        boolean = { "up", "down", "left", "right", "shoot", "spell", "slow", "special", "menu", "snapshot", "retry", "skip" },
    },
    replay = {
        boolean = { "repfast", "repslow", "menu", "snapshot"}
    }
}

---@param s_config_category foundation.input.config.category
function M.switch_config(s_config_category)
    if not M.configs[s_config_category] then
        error("config \"" .. s_config_category .. "\" not found")
    end
    M.current_config = s_config_category
end

function M.get_current_config()
    return M.configs[M.current_config]
end

---@param config_category foundation.input.config.category
function M.get_config(config_category)
    if not M.configs[config_category] then
        error("config \"" .. config_category .. "\" not found")
    end
    local lookup = {}
    local function deep_copy(t)
        if type(t) ~= 'table' then
            return t
        elseif lookup[t] then
            return lookup[t]
        end
        local ref = {}
        lookup[t] = ref
        for k, v in pairs(t) do
            ref[deep_copy(k)] = deep_copy(v)
        end
        return setmetatable(ref, getmetatable(t))
    end
    return deep_copy(M.configs[config_category])
end

---@param config table
---@param adapter_type foundation.input.config.adapter_type
---@param category foundation.input.config.category
function M.check_conflict(config, adapter_type, category)
    if not M.conflict_check[category] then
        error("category \"" .. category .. "\" not found")
    end
    local is_conflict = {}
    local conflict_result = {}
    local conflict_checklist = M.conflict_check[category]
    if adapter_type == "keyboard_map" then
        for _, key in ipairs(conflict_checklist.boolean) do
            for _, keycode in ipairs(config["boolean"][key]) do
                if keycode ~= keyboard.None then
                    if not is_conflict[keycode] then
                        is_conflict[keycode] = true
                    else
                        table.insert(conflict_result, keycode)
                    end
                end
            end
        end
        local vector2_check = {"x_positive", "x_negative", "y_positive", "y_negative"}
        if type(conflict_checklist.vector2) == "table" then
            for _, key in ipairs(conflict_checklist.vector2) do
                for _, index in ipairs(vector2_check) do
                    for _, keycode in ipairs(config["vector2"][key][index]) do
                        if keycode ~= keyboard.None then
                            if not is_conflict[keycode] then
                                is_conflict[keycode] = true
                            else
                                table.insert(conflict_result, keycode)
                            end
                        end
                    end
                end
            end
        end
        return conflict_result
    else
        -- todo:dinput的向量检测
        for _, key in ipairs(conflict_checklist.boolean) do
            for _, keycode in ipairs(config["boolean"][key]) do
                if keycode ~= 0 then
                    if not is_conflict[keycode] then
                        is_conflict[keycode] = true
                    else
                        table.insert(conflict_result, keycode)
                    end
                end
            end
        end
        return conflict_result
    end
end

---@param config table
---@param category foundation.input.config.category
function M.set_config(config, category)
    local lookup = {}
    local function deep_copy(t)
        if type(t) ~= 'table' then
            return t
        elseif lookup[t] then
            return lookup[t]
        end
        local ref = {}
        lookup[t] = ref
        for k, v in pairs(t) do
            ref[deep_copy(k)] = deep_copy(v)
        end
        return setmetatable(ref, getmetatable(t))
    end
    assert(M.configs[category], "Invalid category.")
    assert(category ~= "default", "Default config catnot be modified.")
    M.configs[category] = deep_copy(config)
end

return M