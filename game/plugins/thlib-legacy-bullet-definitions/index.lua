LoadTexture('bullet1', 'THlib/bullet/bullet1.png', true) -- TODO: 杀杀杀

lstg.plugin.RegisterEvent("afterTHlib", "thlib-legacy-bullet-definitions", 0, function()
    lstg.DoFile("THlib/bullet/legacy_bullet.lua")
end)