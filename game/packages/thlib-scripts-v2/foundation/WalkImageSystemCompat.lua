local type = type
local setmetatable = setmetatable
local abs = abs or math.abs

local WalkImageSystem = require("foundation.WalkImageSystem")

local GetTextureSize = lstg and lstg.GetTextureSize or GetTextureSize

---缓动函数：easeInOutQuad
---@param t number @进度 [0, 1]
---@return number @缓动值 [0, 1]
local function easeInOutQuad(t)
    if t < 0.5 then
        return 2 * t * t
    else
        return 1 - 2 * (1 - t) * (1 - t)
    end
end

---构建帧数据列表（内部辅助函数）
---将帧 ID 列表转换为带前缀的完整帧 ID 列表
---@param prefix string @帧 ID 前缀（如 "idle_", "move_right_"）
---@param ids number[] @帧 ID 数字列表（如 {1, 2, 3}）
---@return string[] @完整的帧 ID 列表（如 {"idle_1", "idle_2", "idle_3"}）
local function buildFrameData(prefix, ids)
    local result = {}
    for i = 1, #ids do
        result[i] = prefix .. ids[i]
    end
    return result
end

---@class foundation.WalkImageSystemCompat
local M = {}
M.__index = M

---初始化行走图系统（兼容接口）
---@param obj table @绑定的渲染对象
---@param texture string|nil @默认纹理名称
---@return foundation.WalkImageSystemCompat
function M:init(obj, texture)
    -- 创建内部的行走图系统
    self.walkSystem = WalkImageSystem.new(obj, texture)

    -- 保存对象引用
    self.obj = obj

    -- 初始化 cast 相关变量
    self.obj.cast = self.obj.cast or 0
    self.obj.cast_t = self.obj.cast_t or 0

    return self
end

---设置标准行走状态机（包含移动、施法、漂浮等默认行为）
---
--- 需要的动画名称：
--- - idle_left, idle_right: 静止动画（必需，循环）
--- - move_left_loop, move_right_loop: 移动循环动画（必需，循环）
--- - move_left_enter, move_right_enter: 开始移动动画（可选，非循环）
--- - move_left_exit, move_right_exit: 停止移动动画（可选，非循环）
---
--- 施法动画（可选，如果需要施法功能）：
--- - cast_loop: 施法循环动画（通用，循环）
--- - cast_enter: 施法开始动画（可选，非循环）
--- - cast_exit: 施法结束动画（可选，非循环）
--- 或带方向版本（系统会优先尝试带方向的动画）：
--- - cast_left_loop, cast_right_loop
--- - cast_left_enter, cast_right_enter
--- - cast_left_exit, cast_right_exit
---
--- 触发条件：
--- - 移动：obj.dx 的绝对值超过 moveThreshold
--- - 施法：obj.cast > 0
---
--- 面向记录：
--- - 系统会自动记录角色的面向（ctx.facing: "left" 或 "right"）
--- - 从施法等状态退出时，会根据记录的面向回到对应的静止状态
---
--- 状态变量：
--- - 所有状态变量都存储在状态机的 context 中
--- - 浮动效果：ctx.floatTimer, ctx.floatOffsetX, ctx.floatOffsetY
--- - 渲染偏移：ctx.renderOffsetX, ctx.renderOffsetY
--- - 面向：ctx.facing
--- - 状态标志：ctx.moveEntering, ctx.moveExiting, ctx.castEntering, ctx.castExiting
---
---@param options table|nil @配置选项 {moveThreshold = 0.5, floatReturnSpeed = 0.3}
function M:setupDefaultStates(options)
    options = options or {}
    local moveThreshold = options.moveThreshold or 0.5
    local floatReturnSpeed = options.floatReturnSpeed or 0.3

    local sm = self.walkSystem.stateMachine

    -- 根据移动方向更新面向
    local function updateFacing(ctx)
        local dx = ctx.owner.obj.dx or 0
        if dx < -moveThreshold then
            ctx.facing = "left"
        elseif dx > moveThreshold then
            ctx.facing = "right"
        end
    end

    -- 漂浮效果更新函数
    local function updateFloating(ctx, dt, enabled)
        dt = dt or 1

        if not enabled then
            local dx = ctx.floatOffsetX or 0
            local dy = ctx.floatOffsetY or 0

            if abs(dx) < 0.01 and abs(dy) < 0.01 then
                ctx.floatOffsetX = 0
                ctx.floatOffsetY = 0
            else
                local factor = floatReturnSpeed
                ctx.floatOffsetX = dx * (1 - factor)
                ctx.floatOffsetY = dy * (1 - factor)
            end
        else
            ctx.floatTimer = (ctx.floatTimer or 0) + dt
            local timer = ctx.floatTimer
            local dy = 0

            if timer < 70 then
                dy = easeInOutQuad(timer / 70) * -3
            else
                timer = timer % 140
                if timer < 70 then
                    dy = 3 - easeInOutQuad(timer / 70) * 6
                else
                    dy = -3 + easeInOutQuad((timer - 70) / 70) * 6
                end
            end

            ctx.floatOffsetX = 0
            ctx.floatOffsetY = dy
        end

        ctx.renderOffsetX = ctx.floatOffsetX or 0
        ctx.renderOffsetY = ctx.floatOffsetY or 0
    end

    -- 静止状态（面向左）
    sm:registerState("idle_left", {
        onEnter = function(ctx)
            ctx.owner:playAnimation("idle_left")
            ctx.facing = "left"
        end,
        onUpdate = function(ctx, dt)
            ctx.owner:updateAnimation(dt)
            updateFloating(ctx, dt, true)
        end
    })

    -- 静止状态（面向右）
    sm:registerState("idle_right", {
        onEnter = function(ctx)
            ctx.owner:playAnimation("idle_right")
            ctx.facing = "right"
        end,
        onUpdate = function(ctx, dt)
            ctx.owner:updateAnimation(dt)
            updateFloating(ctx, dt, true)
        end
    })

    -- 左移动进入
    sm:registerState("move_left_enter", {
        onEnter = function(ctx)
            if ctx.owner:playAnimation("move_left_enter") then
                ctx.moveEntering = true
            else
                ctx.owner.stateMachine:setState("move_left_loop")
            end
        end,
        onUpdate = function(ctx, dt)
            ctx.owner:updateAnimation(dt)
            updateFloating(ctx, dt, false)
        end,
        onExit = function(ctx)
            ctx.moveEntering = false
        end
    })

    -- 左移动循环
    sm:registerState("move_left_loop", {
        onEnter = function(ctx)
            ctx.owner:playAnimation("move_left_loop")
            ctx.facing = "left"
        end,
        onUpdate = function(ctx, dt)
            ctx.owner:updateAnimation(dt)
            updateFloating(ctx, dt, false)
        end
    })

    -- 左移动退出
    sm:registerState("move_left_exit", {
        onEnter = function(ctx)
            if ctx.owner:playAnimation("move_left_exit") then
                ctx.moveExiting = true
            else
                ctx.owner.stateMachine:setState("idle_left")
            end
        end,
        onUpdate = function(ctx, dt)
            ctx.owner:updateAnimation(dt)
            updateFloating(ctx, dt, false)
        end,
        onExit = function(ctx)
            ctx.moveExiting = false
        end
    })

    -- 右移动进入
    sm:registerState("move_right_enter", {
        onEnter = function(ctx)
            if ctx.owner:playAnimation("move_right_enter") then
                ctx.moveEntering = true
            else
                ctx.owner.stateMachine:setState("move_right_loop")
            end
        end,
        onUpdate = function(ctx, dt)
            ctx.owner:updateAnimation(dt)
            updateFloating(ctx, dt, false)
        end,
        onExit = function(ctx)
            ctx.moveEntering = false
        end
    })

    -- 右移动循环
    sm:registerState("move_right_loop", {
        onEnter = function(ctx)
            ctx.owner:playAnimation("move_right_loop")
            ctx.facing = "right"
        end,
        onUpdate = function(ctx, dt)
            ctx.owner:updateAnimation(dt)
            updateFloating(ctx, dt, false)
        end
    })

    -- 右移动退出
    sm:registerState("move_right_exit", {
        onEnter = function(ctx)
            if ctx.owner:playAnimation("move_right_exit") then
                ctx.moveExiting = true
            else
                ctx.owner.stateMachine:setState("idle_right")
            end
        end,
        onUpdate = function(ctx, dt)
            ctx.owner:updateAnimation(dt)
            updateFloating(ctx, dt, false)
        end,
        onExit = function(ctx)
            ctx.moveExiting = false
        end
    })

    -- 施法进入
    sm:registerState("cast_enter", {
        onEnter = function(ctx)
            local animName = "cast_" .. (ctx.facing or "right") .. "_enter"
            local success = ctx.owner:playAnimation(animName)
            if not success then
                success = ctx.owner:playAnimation("cast_enter")
            end

            if success then
                ctx.castEntering = true
            else
                ctx.owner.stateMachine:setState("cast_loop")
            end
        end,
        onUpdate = function(ctx, dt)
            ctx.owner:updateAnimation(dt)
            updateFloating(ctx, dt, false)
            updateFacing(ctx)
        end,
        onExit = function(ctx)
            ctx.castEntering = false
        end
    })

    -- 施法循环
    sm:registerState("cast_loop", {
        onEnter = function(ctx)
            local animName = "cast_" .. (ctx.facing or "right") .. "_loop"
            local success = ctx.owner:playAnimation(animName)
            if not success then
                ctx.owner:playAnimation("cast_loop")
            end
        end,
        onUpdate = function(ctx, dt)
            ctx.owner:updateAnimation(dt)
            updateFloating(ctx, dt, false)
            updateFacing(ctx)
        end
    })

    -- 施法退出
    sm:registerState("cast_exit", {
        onEnter = function(ctx)
            local animName = "cast_" .. (ctx.facing or "right") .. "_exit"
            local success = ctx.owner:playAnimation(animName)
            if not success then
                success = ctx.owner:playAnimation("cast_exit")
            end

            if success then
                ctx.castExiting = true
            else
                local idleState = ctx.facing == "left" and "idle_left" or "idle_right"
                ctx.owner.stateMachine:setState(idleState)
            end
        end,
        onUpdate = function(ctx, dt)
            ctx.owner:updateAnimation(dt)
            updateFloating(ctx, dt, false)
            updateFacing(ctx)
        end,
        onExit = function(ctx)
            ctx.castExiting = false
        end
    })

    -- === 左侧静止 -> 左移动 ===
    sm:addTransition("idle_left", "move_left_enter", function(ctx)
        local dx = ctx.owner.obj.dx or 0
        local cast = ctx.owner.obj.cast or 0
        return dx < -moveThreshold and cast <= 0
    end)

    -- === 右侧静止 -> 右移动 ===
    sm:addTransition("idle_right", "move_right_enter", function(ctx)
        local dx = ctx.owner.obj.dx or 0
        local cast = ctx.owner.obj.cast or 0
        return dx > moveThreshold and cast <= 0
    end)

    -- === 左移动进入 -> 左移动循环 ===
    sm:addTransition("move_left_enter", "move_left_loop", function(ctx)
        if not ctx.moveEntering then
            return false
        end
        local anim = ctx.owner.currentAnimation
        if not anim or anim.loop then
            return true
        end
        return ctx.owner.animationFinished
    end)

    -- === 左移动循环 -> 左移动退出 ===
    sm:addTransition("move_left_loop", "move_left_exit", function(ctx)
        local dx = ctx.owner.obj.dx or 0
        return dx >= -moveThreshold
    end)

    -- === 左移动退出 -> 左侧静止 ===
    sm:addTransition("move_left_exit", "idle_left", function(ctx)
        if not ctx.moveExiting then
            return false
        end
        local anim = ctx.owner.currentAnimation
        if not anim or anim.loop then
            return true
        end
        return ctx.owner.animationFinished
    end)

    -- === 右移动进入 -> 右移动循环 ===
    sm:addTransition("move_right_enter", "move_right_loop", function(ctx)
        if not ctx.moveEntering then
            return false
        end
        local anim = ctx.owner.currentAnimation
        if not anim or anim.loop then
            return true
        end
        return ctx.owner.animationFinished
    end)

    -- === 右移动循环 -> 右移动退出 ===
    sm:addTransition("move_right_loop", "move_right_exit", function(ctx)
        local dx = ctx.owner.obj.dx or 0
        return dx <= moveThreshold
    end)

    -- === 右移动退出 -> 右侧静止 ===
    sm:addTransition("move_right_exit", "idle_right", function(ctx)
        if not ctx.moveExiting then
            return false
        end
        local anim = ctx.owner.currentAnimation
        if not anim or anim.loop then
            return true
        end
        return ctx.owner.animationFinished
    end)

    -- === 方向切换 ===
    sm:addTransition("idle_left", "move_right_enter", function(ctx)
        local dx = ctx.owner.obj.dx or 0
        local cast = ctx.owner.obj.cast or 0
        return dx > moveThreshold and cast <= 0
    end)

    sm:addTransition("idle_right", "move_left_enter", function(ctx)
        local dx = ctx.owner.obj.dx or 0
        local cast = ctx.owner.obj.cast or 0
        return dx < -moveThreshold and cast <= 0
    end)

    -- === 施法状态转换 ===

    sm:addTransition("idle_left", "cast_enter", function(ctx)
        local cast = ctx.owner.obj.cast or 0
        return cast > 0
    end)

    sm:addTransition("idle_right", "cast_enter", function(ctx)
        local cast = ctx.owner.obj.cast or 0
        return cast > 0
    end)

    sm:addTransition("cast_enter", "cast_loop", function(ctx)
        if not ctx.castEntering then
            return false
        end
        local anim = ctx.owner.currentAnimation
        if not anim or anim.loop then
            return true
        end
        return ctx.owner.animationFinished
    end)

    sm:addTransition("cast_loop", "cast_exit", function(ctx)
        local cast = ctx.owner.obj.cast or 0
        return cast <= 0
    end)

    sm:addTransition("cast_exit", "idle_left", function(ctx)
        if not ctx.castExiting then
            return false
        end
        local anim = ctx.owner.currentAnimation
        local animDone = not anim or anim.loop or ctx.owner.animationFinished
        return animDone and ctx.facing == "left"
    end)

    sm:addTransition("cast_exit", "idle_right", function(ctx)
        if not ctx.castExiting then
            return false
        end
        local anim = ctx.owner.currentAnimation
        local animDone = not anim or anim.loop or ctx.owner.animationFinished
        return animDone and ctx.facing == "right"
    end)

    -- 设置初始状态
    local initialDx = self.obj.dx or 0
    if initialDx < 0 then
        sm:setState("idle_left")
    else
        sm:setState("idle_right")
    end
end

---设置传统行走图（兼容旧版接口）
---自动根据纹理布局注册帧、动画并初始化状态机
---
---@param texture string @纹理名称
---@param nRow number @纹理行数（1-4）
---@param nCol number @纹理列数（用于计算单帧尺寸，取所有行中的最大列数）
---@param images number[] @每行的帧数列表，如 {9, 5, 5, 10} 表示第1行9帧、第2行5帧等
---@param anis number[] @每行循环帧数列表（从第2行开始），如 {3, 3, 4} 表示第2行最后3帧循环、第3行最后3帧循环等
---@param interval number @帧间隔
---@param a number|nil @碰撞盒半径 a（可选）
---@param b number|nil @碰撞盒半径 b（可选，默认等于 a）
---
--- 支持的布局模式：
--- - 1 行：idle（静止动画，复制为左右）
--- - 2 行：idle、move（所有动画都会镜像为左右）
--- - 3 行：idle、move、cast（所有动画都会镜像为左右）
--- - 4 行：idle、move_right、move_left、cast（idle复制但不镜像，move左右独立，cast通用）
---
--- 动画命名规则：
--- - idle: idle_left, idle_right
--- - move: move_left_enter/loop/exit, move_right_enter/loop/exit
--- - cast: cast_enter/loop/exit (4行) 或 cast_left_enter/loop/exit, cast_right_enter/loop/exit (3行)
---
--- anis 参数说明：
--- - 表示该行最后多少帧作为循环部分
--- - 如果值为 0 或大于等于该行帧数，则整行都是循环
--- - 如果值小于帧数，则前面的帧作为 enter，后面的帧作为 loop，enter 倒放作为 exit
---
--- 使用示例：
--- ```lua
--- -- 4 行布局：idle(9帧), move_right(5帧,后3帧循环), move_left(5帧,后3帧循环), cast(10帧,后4帧循环)
--- wisys:setupLegacyWalkImage("texture", 4, 10, {9, 5, 5, 10}, {3, 3, 4}, 6)
--- ```
function M:setupLegacyWalkImage(texture, nRow, nCol, images, anis, interval, a, b)
    if a then
        b = b or a
        self.obj.a = a
        self.obj.b = b
    end

    local texW, texH = GetTextureSize(texture)
    if texW == 0 or texH == 0 then
        return
    end

    if nRow < 1 or nCol < 1 then
        return
    end

    local frameW = texW / nCol
    local frameH = texH / nRow

    if nRow == 1 then
        -- 只有 idle
        local idleFrames = images[1]
        self:registerFrameGroup("idle_", 0, 0, frameW, frameH, idleFrames, 1, texture)

        local idleIds = {}
        for i = 1, idleFrames do
            idleIds[i] = i
        end
        self:registerAnimation("idle_left", buildFrameData("idle_", idleIds), interval, true)
        self:copyAnimation("idle_left", "idle_right")

    elseif nRow == 2 then
        -- idle、move_right
        local idleFrames = images[1]
        local moveFrames = images[2]
        local moveLoop = anis[1]

        self:registerFrameGroup("idle_", 0, 0, frameW, frameH, idleFrames, 1, texture)
        self:registerFrameGroup("move_right_", 0, frameH, frameW, frameH, moveFrames, 1, texture)

        -- idle 动画（镜像）
        local idleIds = {}
        for i = 1, idleFrames do
            idleIds[i] = i
        end
        self:registerAnimation("idle_right", buildFrameData("idle_", idleIds), interval, true)
        self:copyAnimation("idle_right", "idle_left", false, true)

        -- move_right 动画
        if moveLoop > 0 and moveLoop < moveFrames then
            local enterIds = {}
            for i = 1, moveFrames - moveLoop do
                enterIds[i] = i
            end
            local loopIds = {}
            for i = moveFrames - moveLoop + 1, moveFrames do
                loopIds[#loopIds + 1] = i
            end

            self:registerAnimation("move_right_enter", buildFrameData("move_right_", enterIds), interval, false)
            self:registerAnimation("move_right_loop", buildFrameData("move_right_", loopIds), interval, true)
            self:copyAnimation("move_right_enter", "move_left_enter", false, true)
            self:copyAnimation("move_right_loop", "move_left_loop", false, true)
            self:copyAnimation("move_right_enter", "move_right_exit", true)
            self:copyAnimation("move_left_enter", "move_left_exit", true)
        else
            local loopIds = {}
            for i = 1, moveFrames do
                loopIds[i] = i
            end
            self:registerAnimation("move_right_loop", buildFrameData("move_right_", loopIds), interval, true)
            self:copyAnimation("move_right_loop", "move_left_loop", false, true)
        end

    elseif nRow == 3 then
        -- idle、move_right、cast
        local idleFrames = images[1]
        local moveFrames = images[2]
        local castFrames = images[3]
        local moveLoop = anis[1]
        local castLoop = anis[2]

        self:registerFrameGroup("idle_", 0, 0, frameW, frameH, idleFrames, 1, texture)
        self:registerFrameGroup("move_right_", 0, frameH, frameW, frameH, moveFrames, 1, texture)
        self:registerFrameGroup("cast_", 0, frameH * 2, frameW, frameH, castFrames, 1, texture)

        -- idle 动画（镜像）
        local idleIds = {}
        for i = 1, idleFrames do
            idleIds[i] = i
        end
        self:registerAnimation("idle_right", buildFrameData("idle_", idleIds), interval, true)
        self:copyAnimation("idle_right", "idle_left", false, true)

        -- move 动画（镜像）
        if moveLoop > 0 and moveLoop < moveFrames then
            local enterIds = {}
            for i = 1, moveFrames - moveLoop do
                enterIds[i] = i
            end
            local loopIds = {}
            for i = moveFrames - moveLoop + 1, moveFrames do
                loopIds[#loopIds + 1] = i
            end

            self:registerAnimation("move_right_enter", buildFrameData("move_right_", enterIds), interval, false)
            self:registerAnimation("move_right_loop", buildFrameData("move_right_", loopIds), interval, true)
            self:copyAnimation("move_right_enter", "move_left_enter", false, true)
            self:copyAnimation("move_right_loop", "move_left_loop", false, true)
            self:copyAnimation("move_right_enter", "move_right_exit", true)
            self:copyAnimation("move_left_enter", "move_left_exit", true)
        else
            local loopIds = {}
            for i = 1, moveFrames do
                loopIds[i] = i
            end
            self:registerAnimation("move_right_loop", buildFrameData("move_right_", loopIds), interval, true)
            self:copyAnimation("move_right_loop", "move_left_loop", false, true)
        end

        -- cast 动画（镜像，保持和移动方向一致）
        if castLoop > 0 and castLoop < castFrames then
            local enterIds = {}
            for i = 1, castFrames - castLoop do
                enterIds[i] = i
            end
            local loopIds = {}
            for i = castFrames - castLoop + 1, castFrames do
                loopIds[#loopIds + 1] = i
            end

            self:registerAnimation("cast_right_enter", buildFrameData("cast_", enterIds), interval, false)
            self:registerAnimation("cast_right_loop", buildFrameData("cast_", loopIds), interval, true)
            self:copyAnimation("cast_right_enter", "cast_left_enter", false, true)
            self:copyAnimation("cast_right_loop", "cast_left_loop", false, true)
            self:copyAnimation("cast_right_enter", "cast_right_exit", true)
            self:copyAnimation("cast_left_enter", "cast_left_exit", true)
        else
            local loopIds = {}
            for i = 1, castFrames do
                loopIds[i] = i
            end
            self:registerAnimation("cast_right_loop", buildFrameData("cast_", loopIds), interval, true)
            self:copyAnimation("cast_right_loop", "cast_left_loop", false, true)
        end

    elseif nRow >= 4 then
        -- idle、move_right、move_left、cast
        local idleFrames = images[1]
        local moveRightFrames = images[2]
        local moveLeftFrames = images[3]
        local castFrames = images[4]
        local moveRightLoop = anis[1]
        local moveLeftLoop = anis[2]
        local castLoop = anis[3]

        self:registerFrameGroup("idle_", 0, 0, frameW, frameH, idleFrames, 1, texture)
        self:registerFrameGroup("move_right_", 0, frameH, frameW, frameH, moveRightFrames, 1, texture)
        self:registerFrameGroup("move_left_", 0, frameH * 2, frameW, frameH, moveLeftFrames, 1, texture)
        self:registerFrameGroup("cast_", 0, frameH * 3, frameW, frameH, castFrames, 1, texture)

        -- idle 动画（复制）
        local idleIds = {}
        for i = 1, idleFrames do
            idleIds[i] = i
        end
        self:registerAnimation("idle_left", buildFrameData("idle_", idleIds), interval, true)
        self:copyAnimation("idle_left", "idle_right")

        -- move_right 动画
        if moveRightLoop > 0 and moveRightLoop < moveRightFrames then
            local enterIds = {}
            for i = 1, moveRightFrames - moveRightLoop do
                enterIds[i] = i
            end
            local loopIds = {}
            for i = moveRightFrames - moveRightLoop + 1, moveRightFrames do
                loopIds[#loopIds + 1] = i
            end

            self:registerAnimation("move_right_enter", buildFrameData("move_right_", enterIds), interval)
            self:registerAnimation("move_right_loop", buildFrameData("move_right_", loopIds), interval, true)
            self:copyAnimation("move_right_enter", "move_right_exit", true)
        else
            local loopIds = {}
            for i = 1, moveRightFrames do
                loopIds[i] = i
            end
            self:registerAnimation("move_right_loop", buildFrameData("move_right_", loopIds), interval, true)
        end

        -- move_left 动画
        if moveLeftLoop > 0 and moveLeftLoop < moveLeftFrames then
            local enterIds = {}
            for i = 1, moveLeftFrames - moveLeftLoop do
                enterIds[i] = i
            end
            local loopIds = {}
            for i = moveLeftFrames - moveLeftLoop + 1, moveLeftFrames do
                loopIds[#loopIds + 1] = i
            end

            self:registerAnimation("move_left_enter", buildFrameData("move_left_", enterIds), interval)
            self:registerAnimation("move_left_loop", buildFrameData("move_left_", loopIds), interval, true)
            self:copyAnimation("move_left_enter", "move_left_exit", true)
        else
            local loopIds = {}
            for i = 1, moveLeftFrames do
                loopIds[i] = i
            end
            self:registerAnimation("move_left_loop", buildFrameData("move_left_", loopIds), interval, true)
        end

        -- cast 动画
        if castLoop > 0 and castLoop < castFrames then
            local enterIds = {}
            for i = 1, castFrames - castLoop do
                enterIds[i] = i
            end
            local loopIds = {}
            for i = castFrames - castLoop + 1, castFrames do
                loopIds[#loopIds + 1] = i
            end

            self:registerAnimation("cast_enter", buildFrameData("cast_", enterIds), interval)
            self:registerAnimation("cast_loop", buildFrameData("cast_", loopIds), interval, true)
            self:copyAnimation("cast_enter", "cast_exit", true)
        else
            local loopIds = {}
            for i = 1, castFrames do
                loopIds[i] = i
            end
            self:registerAnimation("cast_loop", buildFrameData("cast_", loopIds), interval, true)
        end
    end

    self:setupDefaultStates()
end

---注册图像帧
---@param id string|number @帧 ID
---@param x number @纹理 X 坐标
---@param y number @纹理 Y 坐标
---@param w number @图像宽度
---@param h number @图像高度
---@param texture string|nil @纹理名称（可选）
function M:registerFrame(id, x, y, w, h, texture)
    self.walkSystem:registerFrame(id, x, y, w, h, texture)
end

---注册一组连续的图像帧
---@param idPrefix string @帧 ID 前缀
---@param startX number @起始纹理 X 坐标
---@param startY number @起始纹理 Y 坐标
---@param w number @单帧宽度
---@param h number @单帧高度
---@param cols number @列数
---@param rows number|nil @行数（默认 1）
---@param texture string|nil @纹理名称（可选）
function M:registerFrameGroup(idPrefix, startX, startY, w, h, cols, rows, texture)
    self.walkSystem:registerFrameGroup(idPrefix, startX, startY, w, h, cols, rows, texture)
end

---注册动画
---@param name string @动画名称
---@param frameData (string|number|table)[] @帧数据列表
---@param interval number|nil @帧间隔（默认 8）
---@param loop boolean|nil @是否循环（默认 false）
function M:registerAnimation(name, frameData, interval, loop)
    self.walkSystem:registerAnimation(name, frameData, interval, loop)
end

---复制动画
---@param sourceName string @源动画名称
---@param targetName string @目标动画名称
---@param reverse boolean|nil @是否倒序（默认 false）
---@param mirror boolean|nil @是否镜像（默认 false）
---@return boolean @是否复制成功
function M:copyAnimation(sourceName, targetName, reverse, mirror)
    return self.walkSystem:copyAnimation(sourceName, targetName, reverse, mirror)
end

---设置混合模式
---@param blend string @混合模式
function M:setBlend(blend)
    self.walkSystem:setBlend(blend)
end

---设置颜色
---@param a number|userdata @不透明度或颜色对象
---@param r number|nil @红色
---@param g number|nil @绿色
---@param b number|nil @蓝色
function M:setColor(a, r, g, b)
    self.walkSystem:setColor(a, r, g, b)
end

---开始施法
---@param duration number|nil @持续帧数（如果为 nil 则需要手动设置 cast_t = 0 来停止）
function M:startCast(duration)
    if duration ~= nil then
        self.obj.cast_t = duration
    else
        self.obj.cast_t = 1
    end
    self.obj.cast = 1
end

---停止施法
function M:stopCast()
    self.obj.cast_t = 0
    self.obj.cast = 0
end

---帧更新（兼容接口）
function M:frame()
    local obj = self.obj
    -- 更新 cast 值
    if obj.cast_t > 0 then
        obj.cast_t = obj.cast_t - 1
        if obj.cast_t > 0 then
            obj.cast = obj.cast + 1
        else
            -- cast_t 减到 0，停止施法
            obj.cast = 0
        end
    elseif obj.cast_t == 0 then
        -- cast_t 为 0，确保停止施法
        obj.cast = 0
    elseif obj.cast_t < 0 then
        -- 异常情况，重置
        obj.cast = 0
        obj.cast_t = 0
    end

    -- 更新行走图系统
    self.walkSystem:update(1)

    if type(obj.A) == 'number' and type(obj.B) == 'number' then
        obj.a = obj.A;
        obj.b = obj.B
    end
end

---渲染（兼容接口）
---@param damageTime number|nil @受击时间
---@param damageTimeMax number|nil @受击最大时间
function M:render(damageTime, damageTimeMax)
    self.walkSystem:render(damageTime, damageTimeMax)
end

---获取当前状态名称
---@return string|nil
function M:getCurrentState()
    return self.walkSystem:getCurrentState()
end

---切换到指定状态
---@param stateName string @状态名称
---@return boolean
function M:setState(stateName)
    return self.walkSystem:setState(stateName)
end

---创建一个新的兼容行走图系统实例
---@param obj table @绑定的渲染对象
---@param texture string|nil @默认纹理名称
---@return foundation.WalkImageSystemCompat
function M.new(obj, texture)
    ---@type foundation.WalkImageSystemCompat
    local instance = setmetatable({}, M)
    instance:init(obj, texture)
    return instance
end

return M

