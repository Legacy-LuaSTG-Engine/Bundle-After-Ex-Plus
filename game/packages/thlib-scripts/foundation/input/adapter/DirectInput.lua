--------------------------------------------------------------------------------
--- SPDX-License-Identifier: MIT
--- description: DirectInput 额外功能库
--- version: 1.0.0
--- author: 璀境石
--- detail: 该功能库最初是为《东方远空界》开发的，用于支持 DirectInput 设备
--------------------------------------------------------------------------------

local dinput = require("dinput")

--------------------------------------------------------------------------------
--- 用例

local function example()
    --- aex+: 将 foundation 文件夹复制到 game/data 文件夹中
    --- ex+0.83b: 将 foundation 文件夹复制到 game/data 文件夹中

    local dinput = require("dinput")
    local dinput_ex = require("foundation.input.adapter.DirectInput")

    --- 一般写在 FrameFunc 开头
    local function on_update()
        dinput.update()
        for i = 1, dinput.count() do
            local state = dinput_ex.mapKeyStateFromIndex(i)
            if dinput_ex.getKeyState(state, dinput_ex.Key.Button1) then
                -- 做点什么
            end
        end
    end
end

--------------------------------------------------------------------------------
--- 主体

---@class foundation.input.adapter.DirectInput
local M = {}

---@class foundation.input.adapter.DirectInput.Key
local Key = {
    -- 仅用于表示没有按键按下
    Null = 0,
    -- 按键部分
    Button1 = 1,
    Button2 = 2,
    Button3 = 3,
    Button4 = 4,
    Button5 = 5,
    Button6 = 6,
    Button7 = 7,
    Button8 = 8,
    Button9 = 9,
    Button10 = 10,
    Button11 = 11,
    Button12 = 12,
    Button13 = 13,
    Button14 = 14,
    Button15 = 15,
    Button16 = 16,
    Button17 = 17,
    Button18 = 18,
    Button19 = 19,
    Button20 = 20,
    Button21 = 21,
    Button22 = 22,
    Button23 = 23,
    Button24 = 24,
    Button25 = 25,
    Button26 = 26,
    Button27 = 27,
    Button28 = 28,
    Button29 = 29,
    Button30 = 30,
    Button31 = 31,
    Button32 = 32,
    -- 轴部分
    PositiveAxisX = 65,
    PositiveAxisY = 66,
    PositiveAxisZ = 67,
    PositiveAxisRX = 68,
    PositiveAxisRY = 69,
    PositiveAxisRZ = 70,
    NegativeAxisX = 71,
    NegativeAxisY = 72,
    NegativeAxisZ = 73,
    NegativeAxisRX = 74,
    NegativeAxisRY = 75,
    NegativeAxisRZ = 76,
    -- 两个额外轴
    PositiveAxisU = 77,
    PositiveAxisV = 78,
    NegativeAxisU = 79,
    NegativeAxisV = 80,
    -- 视角轮盘部分
    Pov1Up = 129,
    Pov1Right = 130,
    Pov1Down = 131,
    Pov1Left = 132,
    Pov2Up = 133,
    Pov2Right = 134,
    Pov2Down = 135,
    Pov2Left = 136,
    Pov3Up = 137,
    Pov3Right = 138,
    Pov3Down = 139,
    Pov3Left = 140,
    Pov4Up = 141,
    Pov4Right = 142,
    Pov4Down = 143,
    Pov4Left = 144,
}
M.Key = Key

---@alias foundation.input.adapter.DirectInput.KeyState table<number, boolean>

--- 将获取的原始数据映射为按键  
--- threshold 是轴映射为按键的检测阈值，默认为 0.5  
---@param r dinput.AxisRange
---@param t dinput.RawState
---@param threshold number
---@return foundation.input.adapter.DirectInput.KeyState
---@overload fun(r:dinput.AxisRange, t:dinput.RawState):foundation.input.adapter.DirectInput.KeyState
function M.mapKeyState(r, t, threshold)
    threshold = threshold or 0.5
    local ret = {}

    for i = Key.Button1, Key.Button32 do
        ret[i] = t.rgbButtons[i]
    end

    local function map_axis(v, minv, maxv)
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

    ret[Key.NegativeAxisX], ret[Key.PositiveAxisX] = map_axis(t.lX, r.XMin, r.XMax)
    ret[Key.NegativeAxisY], ret[Key.PositiveAxisY] = map_axis(t.lY, r.YMin, r.YMax)
    ret[Key.NegativeAxisZ], ret[Key.PositiveAxisZ] = map_axis(t.lZ, r.ZMin, r.ZMax)
    ret[Key.NegativeAxisRX], ret[Key.PositiveAxisRX] = map_axis(t.lRx, r.RxMin, r.RxMax)
    ret[Key.NegativeAxisRY], ret[Key.PositiveAxisRY] = map_axis(t.lRy, r.RyMin, r.RyMax)
    ret[Key.NegativeAxisRZ], ret[Key.PositiveAxisRZ] = map_axis(t.lRz, r.RzMin, r.RzMax)
    ret[Key.NegativeAxisU], ret[Key.PositiveAxisU] = map_axis(t.rglSlider[1], r.Slider0Min, r.Slider0Max)
    ret[Key.NegativeAxisV], ret[Key.PositiveAxisV] = map_axis(t.rglSlider[2], r.Slider1Min, r.Slider1Max)

    ---@param Pov number
    ---@return boolean, boolean, boolean, boolean
    local function map_pov(Pov)
        local PovUp, PovRight, PovDown, PovLeft = false, false, false, false
        if Pov >= 0 and Pov <= 36000 then
            Pov = Pov * 0.01 -- 转为浮点角度值
            if ((Pov >= 0) and (Pov <= 22.5)) or ((Pov >= 337.5) and (Pov < 360)) then
                PovUp = true
            elseif ((Pov > 67.5) and (Pov < 112.5)) then
                PovRight = true
            elseif ((Pov > 157.5) and (Pov < 202.5)) then
                PovDown = true
            elseif ((Pov > 247.5) and (Pov < 292.5)) then
                PovLeft = true
            elseif (Pov > 22.5) and (Pov < 67.5) then
                PovUp = true
                PovRight = true
            elseif (Pov > 112.5) and (Pov < 157.5) then
                PovRight = true
                PovDown = true
            elseif (Pov > 202.5) and (Pov < 247.5) then
                PovDown = true
                PovLeft = true
            elseif (Pov > 292.5) and (Pov < 337.5) then
                PovLeft = true
                PovUp = true
            end
        end
        return PovUp, PovRight, PovDown, PovLeft
    end

    ret[Key.Pov1Up], ret[Key.Pov1Right], ret[Key.Pov1Down], ret[Key.Pov1Left] = map_pov(t.rgdwPOV[1])
    ret[Key.Pov2Up], ret[Key.Pov2Right], ret[Key.Pov2Down], ret[Key.Pov2Left] = map_pov(t.rgdwPOV[2])
    ret[Key.Pov3Up], ret[Key.Pov3Right], ret[Key.Pov3Down], ret[Key.Pov3Left] = map_pov(t.rgdwPOV[3])
    ret[Key.Pov4Up], ret[Key.Pov4Right], ret[Key.Pov4Down], ret[Key.Pov4Left] = map_pov(t.rgdwPOV[4])

    return ret
end

--- 将索引为 device_index 的 DirectInput 设备的原始数据映射为按键  
--- threshold 是轴映射为按键的检测阈值，默认为 0.5  
---@param device_index number
---@param threshold number
---@return foundation.input.adapter.DirectInput.KeyState
---@overload fun(device_index:number):foundation.input.adapter.DirectInput.KeyState
function M.mapKeyStateFromIndex(device_index, threshold)
    local axis_ranges = dinput.getAxisRange(device_index)
    local raw_state = dinput.getRawState(device_index)
    return M.mapKeyState(axis_ranges, raw_state, threshold)
end

--- 根据 foundation.input.adapter.DirectInput.Key 中的按键码  
--- 获取 DirectInput 设备按键状态  
--- state_map 可从 mapKeyState 获取  
---@param state_map foundation.input.adapter.DirectInput.KeyState
---@param k number
function M.getKeyState(state_map, k)
    if state_map[k] then
        return true
    end
    return false
end

--- 检查 DirectInput 是否有任何按键按下（无关先后顺序）  
--- 返回 foundation.input.adapter.DirectInput.Key 中的按键码  
--- 以及该按键的友好（其实也没有多友好）名称  
--- state_map 可从 mapKeyState 获取  
--- 一般用于按键设置菜单，设置按键时的按键检测  
---@param state_map foundation.input.adapter.DirectInput.KeyState
---@return number, string
function M.isAnyKeyDown(state_map)
    for k, v in pairs(Key) do
        if M.getKeyState(state_map, v) then
            return v, k
        end
    end
    return 0, "Null"
end

--- 获取 foundation.input.adapter.DirectInput.Key 中的按键码到友好名称的映射  
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
