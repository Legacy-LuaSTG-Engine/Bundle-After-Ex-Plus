--------------------------------------------------------------------------------
--- Sample

--[[

local effect = require("lib.posteffect")

local obj_cls = Class(object)
function obj_cls:init()
    lstg.CreateRenderTarget("rt:bg")
    lstg.CreateRenderTarget("rt:mask")
end
function obj_cls:render()
    lstg.PushRenderTarget("rt:bg")
    lstg.RenderClear(lstg.Color(0, 0, 0, 0))
    -- draw something
    lstg.PopRenderTarget()

    lstg.PushRenderTarget("rt:mask")
    lstg.RenderClear(lstg.Color(255, 255, 255, 255))
    -- draw mask
    lstg.PopRenderTarget()

    effect.drawMaskEffect("rt:bg", "rt:mask")
end

--]]

--------------------------------------------------------------------------------
--- Post Effect

---@class posteffect
local posteffect = {}

---@param rendertarget_name string
---@param mask_rendertarget_name string
function posteffect.drawMaskEffect(rendertarget_name, mask_rendertarget_name)
    if not lstg.CheckRes(9, "$fx:alpha-mask") then
        lstg.LoadFX("$fx:alpha-mask", "shader/alpha_mask.hlsl")
    end
    lstg.PostEffect(
        -- 着色器资源名称
        "$fx:alpha-mask",
        -- 屏幕渲染目标，采样器类型
        rendertarget_name, 6,
        -- 混合模式
        "mul+alpha",
        -- 浮点参数
        {},
        -- 纹理与采样器类型参数
        {
            { mask_rendertarget_name, 6 },
        }
    )
end

---@param rendertarget_name string
---@param blend lstg.BlendMode
---@param radius number
function posteffect.drawBoxBlur3x3(rendertarget_name, blend, radius)
    if not lstg.CheckRes(9, "$fx:boxblur3x3") then
        lstg.LoadFX("$fx:boxblur3x3", "shader/boxblur3x3.hlsl")
    end
    if screen and screen.scale then
        radius = radius * screen.scale -- 确保模糊半径不和窗口大小相关
    end
    lstg.PostEffect(
        -- 着色器资源名称
        "$fx:boxblur3x3",
        -- 屏幕渲染目标，采样器类型
        rendertarget_name, 6,
        -- 混合模式
        blend,
        -- 浮点参数
        {
            { radius, 0.0, 0.0, 0.0 },
        },
        -- 纹理与采样器类型参数
        {}
    )
end

---@param rendertarget_name string
---@param blend lstg.BlendMode
---@param radius number
function posteffect.drawBoxBlur5x5(rendertarget_name, blend, radius)
    if not lstg.CheckRes(9, "$fx:boxblur5x5") then
        lstg.LoadFX("$fx:boxblur5x5", "shader/boxblur5x5.hlsl")
    end
    if screen and screen.scale then
        radius = radius * screen.scale -- 确保模糊半径不和窗口大小相关
    end
    lstg.PostEffect(
        -- 着色器资源名称
        "$fx:boxblur5x5",
        -- 屏幕渲染目标，采样器类型
        rendertarget_name, 6,
        -- 混合模式
        blend,
        -- 浮点参数
        {
            { radius, 0.0, 0.0, 0.0 },
        },
        -- 纹理与采样器类型参数
        {}
    )
end

---@param rendertarget_name string
---@param blend lstg.BlendMode
---@param radius number
function posteffect.drawBoxBlur7x7(rendertarget_name, blend, radius)
    if not lstg.CheckRes(9, "$fx:boxblur7x7") then
        lstg.LoadFX("$fx:boxblur7x7", "shader/boxblur7x7.hlsl")
    end
    if screen and screen.scale then
        radius = radius * screen.scale -- 确保模糊半径不和窗口大小相关
    end
    lstg.PostEffect(
        -- 着色器资源名称
        "$fx:boxblur7x7",
        -- 屏幕渲染目标，采样器类型
        rendertarget_name, 6,
        -- 混合模式
        blend,
        -- 浮点参数
        {
            { radius, 0.0, 0.0, 0.0 },
        },
        -- 纹理与采样器类型参数
        {}
    )
end

return posteffect
