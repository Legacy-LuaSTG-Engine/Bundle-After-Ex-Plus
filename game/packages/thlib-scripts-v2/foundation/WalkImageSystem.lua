local type = type
local setmetatable = setmetatable
local ipairs = ipairs
local cos = cos or math.cos
local sin = sin or math.sin
local pi = math.pi

local StateMachine = require("foundation.StateMachine")

-- 缓存 lstg 函数
local Color = lstg and lstg.Color or Color
local RenderTexture = lstg and lstg.RenderTexture or RenderTexture

---@class foundation.WalkImageSystem.ImageFrame
---@field texture string|nil @纹理名称（如果为 nil 则使用默认纹理）
---@field x number @纹理 X 坐标
---@field y number @纹理 Y 坐标
---@field w number @图像宽度
---@field h number @图像高度

---@class foundation.WalkImageSystem.AnimationFrame
---@field image foundation.WalkImageSystem.ImageFrame @引用的图像帧
---@field dx number @渲染偏移 X
---@field dy number @渲染偏移 Y
---@field hscale number @水平缩放
---@field vscale number @垂直缩放
---@field rot number @旋转角度

---@class foundation.WalkImageSystem.AnimationState
---@field frames foundation.WalkImageSystem.AnimationFrame[] @帧序列
---@field interval number @帧间隔
---@field loop boolean @是否循环

---@class foundation.WalkImageSystem
local M = {}

---@private
function M:initialize(obj, texture)
    self.obj = obj
    self.texture = texture

    self.frames = {}

    self.animations = {}

    -- 当前渲染状态
    self.currentFrame = nil
    self.currentAnimation = nil
    self.animationTimer = 0
    self.animationIndex = 1
    self.animationFinished = false  -- 非循环动画是否播放完毕

    -- 渲染属性
    self.blend = ""
    self.color = Color(0xFFFFFFFF)

    -- 创建状态机
    self.stateMachine = StateMachine.new()

    -- 设置状态机上下文
    self.stateMachine:setContext("owner", self)
end

---注册一个图像帧
---@param id string|number @帧 ID
---@param x number @纹理 X 坐标
---@param y number @纹理 Y 坐标
---@param w number @图像宽度
---@param h number @图像高度
---@param texture string|nil @纹理名称（可选，不指定则使用默认纹理）
function M:registerFrame(id, x, y, w, h, texture)
    self.frames[id] = {
        texture = texture,
        x = x,
        y = y,
        w = w,
        h = h,
    }
end

---注册一组连续的图像帧
---@param idPrefix string @帧 ID 前缀
---@param startX number @起始纹理 X 坐标
---@param startY number @起始纹理 Y 坐标
---@param w number @单帧宽度
---@param h number @单帧高度
---@param cols number @列数
---@param rows number|nil @行数（默认 1）
---@param texture string|nil @纹理名称（可选，不指定则使用默认纹理）
function M:registerFrameGroup(idPrefix, startX, startY, w, h, cols, rows, texture)
    rows = rows or 1
    local index = 1
    for row = 0, rows - 1 do
        for col = 0, cols - 1 do
            local id = idPrefix .. index
            self:registerFrame(
                    id,
                    startX + col * w,
                    startY + row * h,
                    w, h,
                    texture
            )
            index = index + 1
        end
    end
end

---注册一个动画状态
---@param name string @动画名称
---@param frameData (string|number|table)[] @帧数据列表，可以是帧 ID 或包含变换参数的表
---@param interval number|nil @帧间隔（默认 8）
---@param loop boolean|nil @是否循环（默认 false）
---
--- frameData 可以是以下格式之一：
--- 1. 简单格式：{"frame1", "frame2", "frame3"}
--- 2. 完整格式：{
---      {id = "frame1", dx = 0, dy = 0, hscale = 1, vscale = 1, rot = 0},
---      {id = "frame2", dx = 10, dy = 0, hscale = 1, vscale = 1, rot = 45}
---    }
function M:registerAnimation(name, frameData, interval, loop)
    local frames = {}
    local frameIndex = 1

    for i, data in ipairs(frameData) do
        local frameId, dx, dy, hscale, vscale, rot

        if type(data) == "table" then
            frameId = data.id
            dx = data.dx or 0
            dy = data.dy or 0
            hscale = data.hscale or 1
            vscale = data.vscale or 1
            rot = data.rot or 0
        else
            frameId = data
            dx = 0
            dy = 0
            hscale = 1
            vscale = 1
            rot = 0
        end

        local imageFrame = self.frames[frameId]
        if imageFrame then
            frames[frameIndex] = {
                image = imageFrame,
                dx = dx,
                dy = dy,
                hscale = hscale,
                vscale = vscale,
                rot = rot,
            }
            frameIndex = frameIndex + 1
        else
            print(string.format("[WalkImageSystem] 警告: 动画 '%s' 中找不到帧 ID '%s'", name, tostring(frameId)))
        end
    end

    self.animations[name] = {
        frames = frames,
        interval = interval or 8,
        loop = not not loop,
    }
end

---复制动画（将已注册的动画复制为新名称）
---@param sourceName string @源动画名称
---@param targetName string @目标动画名称
---@param reverse boolean|nil @是否倒序（默认 false）
---@param mirror boolean|nil @是否镜像（默认 false）
---@return boolean @是否复制成功
function M:copyAnimation(sourceName, targetName, reverse, mirror)
    local sourceAnim = self.animations[sourceName]
    if not sourceAnim then
        return false
    end

    -- 复制动画数据
    local frames = {}
    if reverse then
        -- 倒序复制
        local frameCount = #sourceAnim.frames
        for i = 1, frameCount do
            local sourceFrame = sourceAnim.frames[frameCount - i + 1]
            if mirror then
                -- 倒序+镜像
                frames[i] = {
                    image = sourceFrame.image,
                    dx = -sourceFrame.dx,
                    dy = sourceFrame.dy,
                    hscale = -sourceFrame.hscale,
                    vscale = sourceFrame.vscale,
                    rot = -sourceFrame.rot,
                }
            else
                frames[i] = sourceFrame
            end
        end
    else
        -- 正序复制
        for i, sourceFrame in ipairs(sourceAnim.frames) do
            if mirror then
                -- 正序+镜像
                frames[i] = {
                    image = sourceFrame.image,
                    dx = -sourceFrame.dx,
                    dy = sourceFrame.dy,
                    hscale = -sourceFrame.hscale,
                    vscale = sourceFrame.vscale,
                    rot = -sourceFrame.rot,
                }
            else
                frames[i] = sourceFrame  -- AnimationFrame 可以共享，因为它们是不可变的
            end
        end
    end

    self.animations[targetName] = {
        frames = frames,
        interval = sourceAnim.interval,
        loop = sourceAnim.loop,
    }

    return true
end

---播放指定动画
---@param name string @动画名称
---@return boolean @是否播放成功
function M:playAnimation(name)
    local anim = self.animations[name]
    if not anim or #anim.frames == 0 then
        return false
    end

    self.currentAnimation = anim
    self.animationTimer = 0
    self.animationIndex = 1
    self.animationFinished = false
    self.currentFrame = anim.frames[1]
    return true
end

---更新动画
---@param deltaTime number|nil @时间增量（默认 1）
---@private
function M:updateAnimation(deltaTime)
    if not self.currentAnimation then
        return
    end

    deltaTime = deltaTime or 1
    local anim = self.currentAnimation
    local interval = anim.interval
    local frameCount = #anim.frames

    -- 非循环动画已经播放完毕，不再更新
    if not anim.loop and self.animationFinished then
        return
    end

    self.animationTimer = self.animationTimer + deltaTime

    if self.animationTimer >= interval then
        self.animationTimer = self.animationTimer - interval

        -- 非循环动画在最后一帧
        if not anim.loop and self.animationIndex >= frameCount then
            -- 最后一帧已经显示够时间了，标记为完成
            self.animationFinished = true
            return
        end

        self.animationIndex = self.animationIndex + 1

        if self.animationIndex > frameCount then
            if anim.loop then
                self.animationIndex = 1
            else
                self.animationIndex = frameCount
            end
        end

        self.currentFrame = anim.frames[self.animationIndex]
    end
end

---设置混合模式
---@param blend string @混合模式
function M:setBlend(blend)
    self.blend = blend or ""
end

---设置颜色
---@param a number|userdata @不透明度或颜色对象
---@param r number|nil @红色
---@param g number|nil @绿色
---@param b number|nil @蓝色
function M:setColor(a, r, g, b)
    if type(a) == "userdata" then
        self.color = a
    elseif r and g and b then
        self.color = Color(a, r, g, b)
    elseif type(a) == "number" then
        self.color = Color(a)
    end
end

---切换到指定状态
---@param stateName string @状态名称
---@return boolean @是否切换成功
function M:setState(stateName)
    return self.stateMachine:setState(stateName)
end

---添加状态转换条件
---@param fromState string @起始状态
---@param toState string @目标状态
---@param condition function|nil @转换条件函数
function M:addTransition(fromState, toState, condition)
    self.stateMachine:addTransition(fromState, toState, condition)
end

---注册自定义状态
---@param name string @状态名称
---@param callbacks table @状态回调 {onEnter, onExit, onUpdate}
function M:registerState(name, callbacks)
    return self.stateMachine:registerState(name, callbacks)
end

---获取旋转后的坐标
---@param cx number @中心 X
---@param cy number @中心 Y
---@param dx number @相对 X
---@param dy number @相对 Y
---@param angle number @角度
---@return number, number
---@private
local function getRotatedPosition(cx, cy, dx, dy, angle)
    local rad = angle * pi / 180
    local cosA = cos(rad)
    local sinA = sin(rad)
    local x = dx * cosA - dy * sinA + cx
    local y = dx * sinA + dy * cosA + cy
    return x, y
end

---帧更新
function M:update(deltaTime)
    deltaTime = deltaTime or 1

    -- 更新状态机
    self.stateMachine:update(deltaTime)
end

---渲染
---@param damageTime number|nil @受击时间
---@param damageTimeMax number|nil @受击最大时间
function M:render(damageTime, damageTimeMax)
    if not self.currentFrame then
        return
    end

    local animFrame = self.currentFrame  -- AnimationFrame
    local imgFrame = animFrame.image     -- ImageFrame
    local obj = self.obj

    -- 使用图像帧指定的纹理，如果没有则使用默认纹理
    local texture = imgFrame.texture or self.texture
    if not texture then
        return
    end

    -- 计算受击效果
    local damageRatio = 0
    if damageTime and damageTimeMax and damageTimeMax > 0 then
        damageRatio = damageTime / damageTimeMax
    end

    -- 获取颜色
    local blend = self.blend
    local color = self.color

    -- 从对象获取自定义颜色
    if obj._blend and obj._a and obj._r and obj._g and obj._b then
        blend = obj._blend
        local a, r, g, b = obj._a, obj._r, obj._g, obj._b
        if damageRatio > 0 then
            r = r - r * damageRatio
            g = g - g * damageRatio
        end
        color = Color(a, r, g, b)
    elseif damageRatio > 0 then
        local a, r, g, b = color:ARGB()
        r = r - r * damageRatio
        g = g - g * damageRatio
        color = Color(a, r, g, b)
    end

    -- 计算位置和缩放（从状态机上下文读取偏移）
    local ctx = self.stateMachine.context
    local offsetX = ctx.renderOffsetX or 0
    local offsetY = ctx.renderOffsetY or 0
    local x = obj.x + animFrame.dx + offsetX
    local y = obj.y + animFrame.dy + offsetY
    local w = imgFrame.w * (obj.hscale or 1) * animFrame.hscale / 2
    local h = imgFrame.h * (obj.vscale or 1) * animFrame.vscale / 2
    local rot = (obj.rot or 0) + animFrame.rot

    -- 计算四个顶点（纹理坐标来自图像帧）
    local tx = imgFrame.x
    local ty = imgFrame.y
    local tw = imgFrame.w
    local th = imgFrame.h

    local px, py
    px, py = getRotatedPosition(x, y, -w, h, rot)
    local p1 = { px, py, 0.5, tx, ty, color }

    px, py = getRotatedPosition(x, y, w, h, rot)
    local p2 = { px, py, 0.5, tx + tw, ty, color }

    px, py = getRotatedPosition(x, y, w, -h, rot)
    local p3 = { px, py, 0.5, tx + tw, ty + th, color }

    px, py = getRotatedPosition(x, y, -w, -h, rot)
    local p4 = { px, py, 0.5, tx, ty + th, color }

    -- 渲染纹理
    RenderTexture(texture, blend, p1, p2, p3, p4)
end

---获取当前状态名称
---@return string|nil
function M:getCurrentState()
    return self.stateMachine:getCurrentStateName()
end

---设置状态机上下文数据
---@param key string @键
---@param value any @值
function M:setContext(key, value)
    self.stateMachine:setContext(key, value)
end

---获取状态机上下文数据
---@param key string @键
---@return any
function M:getContext(key)
    return self.stateMachine:getContext(key)
end

---创建一个新的行走图系统实例
---@param obj table @绑定的渲染对象
---@param texture string|nil @默认纹理名称（可选，也可以在注册帧时指定）
---@return foundation.WalkImageSystem
function M.new(obj, texture)
    ---@type foundation.WalkImageSystem
    local instance = {}
    setmetatable(instance, { __index = M })
    instance:initialize(obj, texture)
    return instance
end

return M

