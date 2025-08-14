--------------------------------------------------------------------------------
--- SPDX-License-Identifier: MIT
--- description: XInput 额外功能库
--- version: 2.0.0
--- author: 璀境石
--- detail: 该功能库最初是为《东方远空界》开发的，用于简化 XInput 的使用
--------------------------------------------------------------------------------

local xinput = require("xinput")

--------------------------------------------------------------------------------
--- 用例

local function example()
    --- aex+: 将 foundation 文件夹复制到 game/data 文件夹中
    --- ex+0.83b: 将 foundation 文件夹复制到 game/data 文件夹中

    local xinput = require("xinput")
    ---@type foundation.input.adapter.XInput
    local xinput_ex = require("foundation.input.adapter.Xinput")

    --- 一般写在 FrameFunc 开头
    local function on_update()
        xinput.update()
        for i = 1, 4 do -- xinput 最多支持 4 个设备
            if xinput.isConnected(i) then
                local state = xinput_ex.mapKeyStateFromIndex(i)
                if xinput_ex.getKeyState(state, xinput_ex.Key.LeftThumbPositiveX) then
                    -- 做点什么
                end
            end
        end
    end
end

--------------------------------------------------------------------------------
--- 主体

---@class foundation.input.adapter.XInput
local M = {}

---@class foundation.input.adapter.XInput.Key
local Key = {
    --- 仅用于兼容
    Null = xinput.Null,
    --- 手柄方向键，上
    Up = xinput.Up,
    --- 手柄方向键，下
    Down = xinput.Down,
    --- 手柄方向键，左
    Left = xinput.Left,
    --- 手柄方向键，右
    Right = xinput.Right,
    --- 手柄 start 按键（一般作为菜单键使用）
    Start = xinput.Start,
    --- 手柄 back 按键（一般作为返回键使用）
    Back = xinput.Back,
    --- 手柄左摇杆按键（按压摇杆）
    LeftThumb = xinput.LeftThumb,
    --- 手柄右摇杆按键（按压摇杆）
    RightThumb = xinput.RightThumb,
    --- 手柄左肩键
    LeftShoulder = xinput.LeftShoulder,
    --- 手柄右肩键
    RightShoulder = xinput.RightShoulder,
    --- 手柄 A 按键
    A = xinput.A,
    --- 手柄 B 按键
    B = xinput.B,
    --- 手柄 X 按键
    X = xinput.X,
    --- 手柄 Y 按键
    Y = xinput.Y,
    --- 手柄左扳机（在左肩键旁边），有的手柄可能没有
    LeftTrigger  = 0x0400,
    --- 手柄右扳机（在右肩键旁边），有的手柄可能没有
    RightTrigger = 0x0800,

    LeftThumbPositiveX = 0x10000,
    LeftThumbPositiveY = 0x20000,
    RightThumbPositiveX = 0x40000,
    RightThumbPositiveY = 0x80000,
    LeftThumbNegativeX = 0x100000,
    LeftThumbNegativeY = 0x200000,
    RightThumbNegativeX = 0x400000,
    RightThumbNegativeY = 0x800000,
}
M.Key = Key

---@alias foundation.input.adapter.XInput.KeyState table<number, boolean>

--- 按键集，真实存在的按键，不是从轴映射而来
local button_set = {
    Up = xinput.Up,
    Down = xinput.Down,
    Left = xinput.Left,
    Right = xinput.Right,
    Start = xinput.Start,
    Back = xinput.Back,
    LeftThumb = xinput.LeftThumb,
    RightThumb = xinput.RightThumb,
    LeftShoulder = xinput.LeftShoulder,
    RightShoulder = xinput.RightShoulder,
    A = xinput.A,
    B = xinput.B,
    X = xinput.X,
    Y = xinput.Y,
}

---@param v number
---@param minv number
---@param maxv number
---@param threshold number
---@return boolean
---@return boolean
local function map_axis(v, minv, maxv, threshold)
    if minv == maxv then
        return false, false
    end
    local center = (minv + maxv) / 2
    if v > center then
        local value = (v - center) / (maxv - center)
        return false, value >= threshold
    else
        local value = (v - center) / (center - minv)
        return value <= -threshold, false
    end
end

--- 将索引为 device_index 的设备的原始数据映射为按键  
--- threshold 是轴映射为按键的检测阈值，默认为 0.5  
---@param device_index number
---@param threshold number
---@return foundation.input.adapter.XInput.KeyState
---@overload fun(device_index:number):foundation.input.adapter.XInput.KeyState
function M.mapKeyStateFromIndex(device_index, threshold)
    threshold = threshold or 0.5
    local ret = {}

    -- 映射按键部分
    for _, v in pairs(button_set) do
        if xinput.getKeyState(device_index, v) then
            ret[v] = true
        end
    end

    -- 映射左右扳机
    if xinput.getLeftTrigger(device_index) >= threshold then
        ret[Key.LeftTrigger] = true
    end
    if xinput.getRightTrigger(device_index) >= threshold then
        ret[Key.RightTrigger] = true
    end

    -- 映射左右摇杆

    local lx = xinput.getLeftThumbX(device_index)
    local ly = xinput.getLeftThumbY(device_index)
    ret[Key.LeftThumbNegativeX], ret[Key.LeftThumbPositiveX] = map_axis(lx , -1.0, 1.0, threshold)
    ret[Key.LeftThumbNegativeY], ret[Key.LeftThumbPositiveY] = map_axis(ly , -1.0, 1.0, threshold)
    local rx = xinput.getRightThumbX(device_index)
    local ry = xinput.getRightThumbY(device_index)
    ret[Key.RightThumbNegativeX], ret[Key.RightThumbPositiveX] = map_axis(rx, -1.0, 1.0, threshold)
    ret[Key.RightThumbNegativeY], ret[Key.RightThumbPositiveY] = map_axis(ry, -1.0, 1.0, threshold)

    return ret
end

--- 根据 foundation.input.adapter.XInput.Key 中的按键码  
--- 获取设备按键状态  
--- state_map 可从 mapKeyState 获取  
---@param state_map foundation.input.adapter.XInput.KeyState
---@param k number
function M.getKeyState(state_map, k)
    if state_map[k] then
        return true
    end
    return false
end

--- 检查是否有任何按键按下（无关先后顺序）  
--- 返回 foundation.input.adapter.XInput.Key 中的按键码  
--- 以及该按键的友好（其实也没有多友好）名称  
--- state_map 可从 mapKeyState 获取  
--- 一般用于按键设置菜单，设置按键时的按键检测  
---@param state_map foundation.input.adapter.XInput.KeyState
---@return number, string
function M.isAnyKeyDown(state_map)
    for k, v in pairs(Key) do
        if M.getKeyState(state_map, v) then
            return v, k
        end
    end
    return 0, "Null"
end

--- 获取按键码到友好名称的映射  
--- 一般用于按键设置菜单的显示文本  
---@return table<number, string>
function M.getKeyNameMap()
    -- 这里必须复制一份新的，防止出事
    local ret = {}
    for k, v in pairs(Key) do
        ret[v] = k
    end
    setmetatable(ret, {
        __index = function(_, _)
            return "Null"
        end
    })
    return ret
end

return M
