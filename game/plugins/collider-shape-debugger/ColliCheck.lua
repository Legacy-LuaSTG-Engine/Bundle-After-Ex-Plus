local lstg = lstg
local table = table

lstg.LoadTexture("Collision_render", "render_colli.png")
lstg.LoadImage("collision_rect", "Collision_render", 0, 0, 128, 128)
lstg.LoadImage("collision_rect1", "Collision_render", 0, 0, 32, 128)
lstg.LoadImage("collision_rect2", "Collision_render", 32, 0, 64, 128)
lstg.LoadImage("collision_rect3", "Collision_render", 96, 0, 32, 128)
lstg.LoadImage("collision_ring", "Collision_render", 130, 0, 128, 128)

local function match_base(class, match)
    if class == match then
        return true
    elseif class.base then
        return match_base(class.base, match)
    end
end

local KEY_COLLIDER = KEY.GRAVE
local KEY_CHEAT = KEY.F12

local toggleColliderRender, keyDownCollider, keyDownCheat

local class = {}

class.list = {
    { GROUP_PLAYER,        lstg.Color(255, 50, 255, 50) },
    { GROUP_PLAYER_BULLET, lstg.Color(255, 127, 127, 192) },
    { GROUP_SPELL,         lstg.Color(255, 255, 50, 255) },
    { GROUP_NONTJT,        lstg.Color(255, 128, 255, 255) },
    { GROUP_ENEMY,         lstg.Color(255, 255, 255, 128) },
    { GROUP_ENEMY_BULLET,  lstg.Color(255, 255, 50, 50) },
    { GROUP_INDES,         lstg.Color(255, 255, 165, 10) },
}
function class.init()
    toggleColliderRender = false
    keyDownCollider = false
    keyDownCheat = false
end

function class.render()
    if lstg.GetKeyState(KEY_COLLIDER) then
        if not keyDownCollider then
            keyDownCollider = true
            if toggleColliderRender == true then
                toggleColliderRender = false
            else
                toggleColliderRender = true
            end
        end
    else
        keyDownCollider = false
    end
    if lstg.GetKeyState(KEY_CHEAT) then
        if not keyDownCheat then
            keyDownCheat = true
            cheat = not (cheat)
        end
    else
        keyDownCheat = false
    end
    if toggleColliderRender == true then
        for i = 1, #class.list do
            local c = class.list[i][2]
            lstg.SetImageState("collision_rect", "", c)
            lstg.SetImageState("collision_rect1", "", c)
            lstg.SetImageState("collision_rect2", "", c)
            lstg.SetImageState("collision_rect3", "", c)
            lstg.SetImageState("collision_ring", "", c)
            for _, unit in lstg.ObjList(class.list[i][1]) do
                if unit.colli then
                    local x = lstg.GetAttr(unit, "x")
                    local y = lstg.GetAttr(unit, "y")
                    local rot = lstg.GetAttr(unit, "rot")
                    if match_base(unit.class, laser) and unit.alpha > 0.999 then
                        local l1 = unit.l1 or 0
                        local l2 = unit.l2 or 0
                        local l3 = unit.l3 or 0
                        local l = l1 + l2 + l3
                        local w = (unit.w or 0) / 2 -- 半宽
                        local dx, dy = lstg.cos(unit.rot), lstg.sin(unit.rot)
                        local tx, ty = x + l * dx, y + l * dy
                        local wx, wy = w * lstg.cos(unit.rot + 90), w * lstg.sin(unit.rot + 90)
                        local x1, y1 = x + l1 * dx + wx, y + l1 * dy + wy
                        local x2, y2 = x + l1 * dx - wx, y + l1 * dy - wy
                        local x3, y3 = x + (l1 + l2) * dx + wx, y + (l1 + l2) * dy + wy
                        local x4, y4 = x + (l1 + l2) * dx - wx, y + (l1 + l2) * dy - wy
                        lstg.Render4V("collision_rect1",
                            x, y, 0.5, x1, y1, 0.5,
                            x2, y2, 0.5, x, y, 0.5)
                        lstg.Render4V("collision_rect2",
                            x1, y1, 0.5, x3, y3, 0.5,
                            x4, y4, 0.5, x2, y2, 0.5)
                        lstg.Render4V("collision_rect3",
                            x3, y3, 0.5, tx, ty, 0.5,
                            tx, ty, 0.5, x4, y4, 0.5)
                    elseif match_base(unit.class, laser_bent) and unit.alpha > 0.999 and unit._colli then
                        local bc = lstg.Color(c.a * 0.6, c.r, c.b, c.g)
                        unit.data:RenderCollider(bc)
                    else
                        local img = unit.rect and "collision_rect" or "collision_ring"
                        local a = lstg.GetAttr(unit, "a")
                        local b = lstg.GetAttr(unit, "b")
                        lstg.Render(img, x, y, rot, a / 64, b / 64)
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

class.init()

if lstg.globalEventDispatcher then
    ---@type lstg.GlobalEventDispatcher
    local gameEventDispatcher = lstg.globalEventDispatcher
    gameEventDispatcher:RegisterEvent("GameState.AfterColliderRender", "ColliderShapeDebugger.RenderCollider", 0, class.render)
else
    Collision_Checker = class
end

local lstg_debug = require("lib.Ldebug")
local imgui_exist, imgui = pcall(require, "imgui")

if not imgui_exist then
    return
end

---@class lstg.debug.ColliderShapeDebugger : lstg.debug.View
local colliderShapeDebugger = {
    _user_add = { 0, 255, 255, 255, 255 },
}

function colliderShapeDebugger:getWindowName()
    return "Collider Shape Debugger"
end

function colliderShapeDebugger:getMenuGroupName()
    return "Tool"
end

function colliderShapeDebugger:getMenuItemName()
    return "Collider Shape Debugger"
end

function colliderShapeDebugger:getEnable()
    return self.enable
end

---@param v boolean
function colliderShapeDebugger:setEnable(v)
    self.enable = v
end

function colliderShapeDebugger:update()
end

function colliderShapeDebugger:layout()
    local list = class.list
    local ImGui = imgui.ImGui
    ImGui.BeginChild("##ColliderShapeDebugger##List", imgui.ImVec2(0, 0))
    ImGui.Text("Collider Shape Debugger")
    ImGui.SameLine()
    ImGui.Text("Status: " .. (toggleColliderRender and "Enabled" or "Disabled"))
    ImGui.SameLine()
    if ImGui.Button("Enable##ColliderShapeDebugger##Enable") then
        toggleColliderRender = true
    end
    ImGui.SameLine()
    if ImGui.Button("Disable##ColliderShapeDebugger##Disable") then
        toggleColliderRender = false
    end
    ImGui.Separator()
    ImGui.Columns(7, "##ColliderShapeDebugger##ListColumns", true)
    ImGui.Text("Group ID")
    ImGui.NextColumn()
    ImGui.Text("Color")
    ImGui.NextColumn()
    ImGui.Text("Color A")
    ImGui.NextColumn()
    ImGui.Text("Color R")
    ImGui.NextColumn()
    ImGui.Text("Color G")
    ImGui.NextColumn()
    ImGui.Text("Color B")
    ImGui.NextColumn()
    ImGui.Text("Action")
    ImGui.NextColumn()
    local need_delete = {}
    for i = 1, #list do
        ImGui.Separator()
        local item = list[i]
        local label = "##item_" .. i
        ImGui.Text(tostring(item[1]))
        --给这行加一个颜色块用来显示颜色
        ImGui.NextColumn()
        local a, r, g, b = item[2]:ARGB()
        ImGui.ColorButton("##ColliderShapeDebugger##ColorBtn" .. label, imgui.ImVec4(r / 255, g / 255, b / 255, a / 255))
        ImGui.NextColumn()
        local ret, value, changed
        ImGui.PushItemWidth(-1)
        ret, value = ImGui.DragInt("##ColliderShapeDebugger##A" .. label, a, 1, 0, 255)
        if ret then
            changed = true
            a = value
        end
        ImGui.PopItemWidth()
        ImGui.NextColumn()
        ImGui.PushItemWidth(-1)
        ret, value = ImGui.DragInt("##ColliderShapeDebugger##R" .. label, r, 1, 0, 255)
        if ret then
            changed = true
            r = value
        end
        ImGui.PopItemWidth()
        ImGui.NextColumn()
        ImGui.PushItemWidth(-1)
        ret, value = ImGui.DragInt("##ColliderShapeDebugger##G" .. label, g, 1, 0, 255)
        if ret then
            changed = true
            g = value
        end
        ImGui.PopItemWidth()
        ImGui.NextColumn()
        ImGui.PushItemWidth(-1)
        ret, value = ImGui.DragInt("##ColliderShapeDebugger##B" .. label, b, 1, 0, 255)
        if ret then
            changed = true
            b = value
        end
        ImGui.PopItemWidth()
        ImGui.NextColumn()
        if changed then
            item[2] = lstg.Color(a, r, g, b)
        end
        if ImGui.Button("Delete##ColliderShapeDebugger##BtnDelete" .. label) then
            table.insert(need_delete, i)
        end
        ImGui.NextColumn()
    end
    for i = #need_delete, 1, -1 do
        table.remove(list, need_delete[i])
    end
    ImGui.Columns(1)
    ImGui.Separator()
    ImGui.Text("Add New Group")
    ImGui.Separator()
    ImGui.Columns(7, "##ColliderShapeDebugger##AddColumns", true)
    local id = self._user_add[1] or 0
    local a, r, g, b = self._user_add[2] or 255, self._user_add[3] or 255, self._user_add[4] or 255,
        self._user_add[5] or 255
    local ret, value, changed
    ImGui.PushItemWidth(-1)
    ret, value = ImGui.DragInt("##ColliderShapeDebugger##GroupID", id, 1, 0, 15)
    if ret then
        changed = true
        id = value
    end
    ImGui.PopItemWidth()
    ImGui.NextColumn()
    ImGui.ColorButton("##ColliderShapeDebugger##ColorBtn", imgui.ImVec4(r / 255, g / 255, b / 255, a / 255))
    ImGui.NextColumn()
    ImGui.PushItemWidth(-1)
    ret, value = ImGui.DragInt("##ColliderShapeDebugger##ColorA", a, 1, 0, 255)
    if ret then
        changed = true
        a = value
    end
    ImGui.PopItemWidth()
    ImGui.NextColumn()
    ImGui.PushItemWidth(-1)
    ret, value = ImGui.DragInt("##ColliderShapeDebugger##ColorR", r, 1, 0, 255)
    if ret then
        changed = true
        r = value
    end
    ImGui.PopItemWidth()
    ImGui.NextColumn()
    ImGui.PushItemWidth(-1)
    ret, value = ImGui.DragInt("##ColliderShapeDebugger##ColorG", g, 1, 0, 255)
    if ret then
        changed = true
        g = value
    end
    ImGui.PopItemWidth()
    ImGui.NextColumn()
    ImGui.PushItemWidth(-1)
    ret, value = ImGui.DragInt("##ColliderShapeDebugger##ColorB", b, 1, 0, 255)
    if ret then
        changed = true
        b = value
    end
    ImGui.PopItemWidth()
    ImGui.NextColumn()
    if changed then
        self._user_add = { id, a, r, g, b }
    end
    if ImGui.Button("Add##ColliderShapeDebugger##NewGroup") then
        table.insert(list,
            { self._user_add[1], lstg.Color(self._user_add[2], self._user_add[3], self._user_add[4], self._user_add[5]) })
        self._user_add = { 0, 255, 255, 255, 255 }
    end
    ImGui.Columns(1)
    ImGui.EndChild()
end

lstg_debug.addView("lstg.debug.ColliderShapeDebugger", colliderShapeDebugger)
