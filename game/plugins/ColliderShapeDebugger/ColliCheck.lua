LoadTexture("Collision_render", "render_colli.png")
LoadImage("collision_rect", "Collision_render", 0, 0, 128, 128)
LoadImage("collision_rect1", "Collision_render", 0, 0, 32, 128)
LoadImage("collision_rect2", "Collision_render", 32, 0, 64, 128)
LoadImage("collision_rect3", "Collision_render", 96, 0, 32, 128)
LoadImage("collision_ring", "Collision_render", 130, 0, 128, 128)

local function match_base(class, match)
    if class == match then
        return true
    elseif class.base then
        return match_base(class.base, match)
    end
end

local toggle, KeyDown192, KeyDown123, img,
        l1, l2, l3, l, w,
        x, y, tx, ty, dx, dy, wx, wy,
        x1, y1, x2, y2, x3, y3, x4, y4
Collision_Checker = {}
Collision_Checker.list = {
    {GROUP_PLAYER, Color(255, 50, 255, 50)},
    {GROUP_PLAYER_BULLET, Color(255, 127, 127, 192)},
    {GROUP_SPELL, Color(255, 255, 50, 255)},
    {GROUP_NONTJT, Color(255, 128, 255, 255)},
    {GROUP_ENEMY, Color(255, 255, 255, 128)},
    {GROUP_ENEMY_BULLET, Color(255, 255, 50, 50)},
    {GROUP_INDES, Color(255, 255, 165, 10)},
}
function Collision_Checker.init()
    toggle = false
    KeyDown192 = false
    KeyDown123 = false
end
function Collision_Checker.render()
    if GetKeyState(192) then
        if not KeyDown192 then
            KeyDown192 = true
            if toggle == true then
                toggle = false
            else
                toggle = true
            end
        end
    else
        KeyDown192 = false
    end
    if GetKeyState(123) then
        if not KeyDown123 then
            KeyDown123 = true
            cheat = not(cheat)
        end
    else
        KeyDown123 = false
    end
    if toggle == true then
        for i = 1, #Collision_Checker.list do
            local c = Collision_Checker.list[i][2]
            SetImageState("collision_rect", "", c)
            SetImageState("collision_rect1", "", c)
            SetImageState("collision_rect2", "", c)
            SetImageState("collision_rect3", "", c)
            SetImageState("collision_ring", "", c)
            local bc = lstg.Color(c.a * 0.6, c.r, c.b, c.g)
            for _, unit in ObjList(Collision_Checker.list[i][1]) do
                if unit.colli then
                    if match_base(unit.class, laser) and unit.alpha > 0.999 then
                        l1 = unit.l1 or 0
                        l2 = unit.l2 or 0
                        l3 = unit.l3 or 0
                        l = l1 + l2 + l3
                        w = (unit.w or 0) / 2 -- 半宽
                        x, y = unit.x, unit.y
                        dx, dy = cos(unit.rot), sin(unit.rot)
                        tx, ty = x + l * dx, y + l * dy
                        wx, wy = w * cos(unit.rot + 90), w * sin(unit.rot + 90)
                        x1, y1 = x + l1 * dx + wx, y + l1 * dy + wy
                        x2, y2 = x + l1 * dx - wx, y + l1 * dy - wy
                        x3, y3 = x + (l1 + l2) * dx + wx, y + (l1 + l2) * dy + wy
                        x4, y4 = x + (l1 + l2) * dx - wx, y + (l1 + l2) * dy - wy
                        Render4V("collision_rect1",
                                x, y, 0.5, x1, y1, 0.5,
                                x2, y2, 0.5, x, y, 0.5)
                        Render4V("collision_rect2",
                                x1, y1, 0.5, x3, y3, 0.5,
                                x4, y4, 0.5, x2, y2, 0.5)
                        Render4V("collision_rect3",
                                x3, y3, 0.5, tx, ty, 0.5,
                                tx, ty, 0.5, x4, y4, 0.5)
                    elseif match_base(unit.class, laser_bent) and unit.alpha > 0.999 and unit._colli then
                        unit.data:RenderCollider(bc)
                    else
                        if unit.rect == true then
                            img = "collision_rect"
                        else
                            img = "collision_ring"
                        end
                        Render(img, unit.x, unit.y, unit.rot,
                                unit.a / 64, unit.b / 64)
                    end
                end
            end
        end
    end
    --if cheat then
        --SetFontState('item','',Color(0xFFFFFF00))
        --RenderText('item', "Cheat", lstg.world.r - 8, lstg.world.b + 32, 1, "right", "bottom")
    --end
    -- 渲染作弊指示器（一圈黄框）
    if cheat and (not (stage.current_stage and stage.current_stage.is_menu)) and lstg.CheckRes(2, "white") then
        lstg.SetImageState("white", "", lstg.Color(255, 255, 255, 0))
        local w = 1.01
        lstg.RenderRect("white", lstg.world.l, lstg.world.l + w, lstg.world.b, lstg.world.t)
        lstg.RenderRect("white", lstg.world.r - w, lstg.world.r, lstg.world.b, lstg.world.t)
        lstg.RenderRect("white", lstg.world.l, lstg.world.r, lstg.world.b, lstg.world.b + w)
        lstg.RenderRect("white", lstg.world.l, lstg.world.r, lstg.world.t - w, lstg.world.t)
    end
end

Collision_Checker.init()