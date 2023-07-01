                            说明

这个文件夹里储存着用于 LuaSTG Plus、LuaSTG Ex Plus 的屏幕后处理特效。

由于 LuaSTG Sub 改为使用 Direct3D 11，这些特效已经无法使用，仅作留档。

未来这些文件会彻底删除。

屏幕后处理特效列表：
    boss_distortion_old.fx
        功能：LuaSTG er+ 时期的扭曲特效
        状态：不作移植，已被取代
    boss_distortion.fx
        功能：LuaSTG ex+ 时期的扭曲特效
        状态：已移植（有缺陷！）
    texture_BoxBlur9.fx
        功能：3x3 均值模糊
        状态：已移植
    texture_BoxBlur25.fx
        功能：5x5 均值模糊
        状态：已移植
    texture_BoxBlur49.fx
        功能：7x7 均值模糊
        状态：已移植
    texture_hue.fx
        功能：色相、饱和度、明度变换
        状态：未移植
    texture_mask.fx
        功能：遮罩
        状态：已移植
    texture_mosaic.fx
        功能：马赛克化
        状态：未移植
    texture_overlay.fx
        功能：叠加（overlay）混合模式，来自 PhotoShop
        状态：未移植
    texture_threshold.fx
        功能：阈值遮罩
        状态：未移植
    world_rotate.fx
        功能：游戏区域（world）画面旋转
        状态：弃用，因为不依赖屏幕后处理特效也能实现
