local lstg = require("lstg")
local Keyboard = lstg.Input.Keyboard
local io = io
local math = math
local string = string
local table = table
local type = type
local pairs = pairs
local setmetatable = setmetatable
local getmetatable = getmetatable
local unpack = unpack or table.unpack
local pcall = pcall
local require = require
local tostring = tostring
local localFileStorage = require("foundation.LocalFileStorage")

lstg.LoadTexture("Collision_render", "render_colli.png")
lstg.LoadImage("collision_rect", "Collision_render", 0, 0, 128, 128)
lstg.LoadImage("collision_rect1", "Collision_render", 0, 0, 32, 128)
lstg.LoadImage("collision_rect2", "Collision_render", 32, 0, 64, 128)
lstg.LoadImage("collision_rect3", "Collision_render", 96, 0, 32, 128)
lstg.LoadImage("collision_ring", "Collision_render", 130, 0, 128, 128)

---@return boolean
local function match_base(class, match)
    if class == match then
        return true
    elseif class.base then
        return match_base(class.base, match)
    end
end

---@return string
local function getStoragePath()
    local dir = localFileStorage.getRootDirectory()
    local path = dir .. "/plugins/collider-shape-debugger"
    if not (lstg.FileManager.DirectoryExist(path)) then
        lstg.FileManager.CreateDirectory(path)
    end
    return path
end

local function copy(t, all)
    if all then
        local lookup = {}
        local function _copy(_t)
            if type(_t) ~= 'table' then
                return _t
            elseif lookup[_t] then
                return lookup[_t]
            end
            local ref = {}
            lookup[_t] = ref
            for k, v in pairs(_t) do
                ref[_copy(k)] = _copy(v)
            end
            return setmetatable(ref, getmetatable(_t))
        end
        return _copy(t)
    else
        local ref = {}
        for k, v in pairs(t) do
            ref[k] = v
        end
        return setmetatable(ref, getmetatable(t))
    end
end

local KEY_COLLIDER = Keyboard.Tilde -- `~
local KEY_CHEAT = Keyboard.F12

local toggleColliderRender, keyDownCollider, keyDownCheat

local class = {}

class.list_default = {
    { GROUP_PLAYER, { 255, 50, 255, 50 } },
    { GROUP_PLAYER_BULLET, { 255, 127, 127, 192 } },
    { GROUP_SPELL, { 255, 255, 50, 255 } },
    { GROUP_NONTJT, { 255, 128, 255, 255 } },
    { GROUP_ENEMY, { 255, 255, 255, 128 } },
    { GROUP_ENEMY_BULLET, { 255, 255, 50, 50 } },
    { GROUP_INDES, { 255, 255, 165, 10 } },
}

local known_group_values = {
    GROUP_GHOST = 0,
    GROUP_ENEMY_BULLET = 1,
    GROUP_ENEMY = 2,
    GROUP_PLAYER_BULLET = 3,
    GROUP_PLAYER = 4,
    GROUP_INDES = 5,
    GROUP_ITEM = 6,
    GROUP_NONTJT = 7,
    GROUP_SPELL = 8,
    GROUP_CPLAYER = 9,
}
for k, v in pairs(known_group_values) do
    known_group_values[v] = k
end
class.group_enum = {}
for i = 0, GROUP_ALL - 1 do
    if known_group_values[i] then
        class.group_enum[i] = known_group_values[i]
    else
        class.group_enum[i] = string.format("UNKNOWN_GROUP_%d", i)
    end
end

function class.init()
    toggleColliderRender = false
    keyDownCollider = false
    keyDownCheat = false

    class.storage_path = getStoragePath()
    class.storage_file = class.storage_path .. "/config.json"

    local data
    if lstg.FileManager.FileExist(class.storage_file) then
        local f, e = io.open(class.storage_file, "rb")
        if f then
            local s = f:read("*a")
            f:close()
            local r, t = pcall(cjson.decode, s)
            if r then
                data = t
            else
                lstg.Log(4, string.format("decode data storage file '%s' failed: %s", class.storage_file, tostring(t)))
            end
        else
            lstg.Log(4, string.format("open data storage file '%s' failed: %s", class.storage_file, tostring(e)))
        end
    else
        lstg.Log(2, string.format("data storage file '%s' not exist", class.storage_file))
    end
    if not data then
        data = copy(class.list_default, true)
    end
    class.list = data
end

function class.reload()
    local f, e = io.open(class.storage_file, "rb")
    if f then
        local s = f:read("*a")
        f:close()
        local r, t = pcall(cjson.decode, s)
        if r then
            class.list = t
        else
            lstg.Log(4, string.format("decode data storage file '%s' failed: %s", class.storage_file, tostring(t)))
            return false
        end
    else
        lstg.Log(4, string.format("open data storage file '%s' failed: %s", class.storage_file, tostring(e)))
        return false
    end
    return true
end

function class.save()
    local f, e = io.open(class.storage_file, "wb")
    if f then
        local r, s = pcall(cjson.encode, copy(class.list))
        if r then
            f:write(s)
            f:close()
        else
            lstg.Log(4, string.format("encode data storage file '%s' failed: %s", class.storage_file, tostring(s)))
        end
    else
        lstg.Log(4, string.format("write data storage file '%s' failed: %s", class.storage_file, tostring(e)))
    end
end

function class.resetToDefault()
    class.list = copy(class.list_default, true)
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
    if toggleColliderRender then
        for i = 1, #class.list do
            local c = lstg.Color(unpack(class.list[i][2]))
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
local ImGui = imgui.ImGui

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

function colliderShapeDebugger:layoutTable()
    local list = class.list
    if ImGui.BeginTable("##ColliderShapeDebugger##ListColumns", 9, imgui.ImGuiTableFlags.Borders) then
        ImGui.TableSetupColumn("Group ID", imgui.ImGuiTableColumnFlags.WidthStretch, 400)
        ImGui.TableSetupColumn("Color", imgui.ImGuiTableColumnFlags.WidthFixed, 60)
        ImGui.TableSetupColumn("Color A", imgui.ImGuiTableColumnFlags.WidthStretch, 200)
        ImGui.TableSetupColumn("Color R", imgui.ImGuiTableColumnFlags.WidthStretch, 200)
        ImGui.TableSetupColumn("Color G", imgui.ImGuiTableColumnFlags.WidthStretch, 200)
        ImGui.TableSetupColumn("Color B", imgui.ImGuiTableColumnFlags.WidthStretch, 200)
        ImGui.TableSetupColumn("Action", imgui.ImGuiTableColumnFlags.WidthStretch, 200)
        ImGui.TableSetupColumn("/\\", imgui.ImGuiTableColumnFlags.WidthFixed, 40)
        ImGui.TableSetupColumn("\\/", imgui.ImGuiTableColumnFlags.WidthFixed, 40)
        ImGui.TableHeadersRow()
        ImGui.TableNextRow()
        local need_delete = {}
        for i = 1, #list do
            local item = list[i]
            local label = "##item_" .. i
            local group_name = class.group_enum[item[1]]
            if group_name then
                group_name = group_name:match("^%s*GROUP_%s*(.+)$")
            end
            if group_name and not group_name:match("%S") then
                group_name = nil
            end
            ImGui.TableNextColumn()
            ImGui.Text(group_name or tostring(i))
            ImGui.TableNextColumn()
            local a, r, g, b = unpack(item[2])
            ImGui.ColorButton("##ColliderShapeDebugger##ColorBtn" .. label, imgui.ImVec4(r / 255, g / 255, b / 255, a / 255))
            ImGui.TableNextColumn()
            local ret, value
            ImGui.PushItemWidth(-1)
            ret, value = ImGui.DragInt("##ColliderShapeDebugger##A" .. label, a, 1, 0, 255)
            if ret then
                item[2][1] = value
            end
            ImGui.PopItemWidth()
            ImGui.TableNextColumn()
            ImGui.PushItemWidth(-1)
            ret, value = ImGui.DragInt("##ColliderShapeDebugger##R" .. label, r, 1, 0, 255)
            if ret then
                item[2][2] = value
            end
            ImGui.PopItemWidth()
            ImGui.TableNextColumn()
            ImGui.PushItemWidth(-1)
            ret, value = ImGui.DragInt("##ColliderShapeDebugger##G" .. label, g, 1, 0, 255)
            if ret then
                item[2][3] = value
            end
            ImGui.PopItemWidth()
            ImGui.TableNextColumn()
            ImGui.PushItemWidth(-1)
            ret, value = ImGui.DragInt("##ColliderShapeDebugger##B" .. label, b, 1, 0, 255)
            if ret then
                item[2][4] = value
            end
            ImGui.PopItemWidth()
            ImGui.TableNextColumn()
            if ImGui.Button("Delete##ColliderShapeDebugger##BtnDelete" .. label) then
                table.insert(need_delete, i)
            end
            ImGui.TableNextColumn()
            if i > 1 and ImGui.Button("/\\##ColliderShapeDebugger##BtnUp" .. label) then
                local tmp = list[i - 1]
                list[i - 1] = list[i]
                list[i] = tmp
            end
            ImGui.TableNextColumn()
            if i < #list and ImGui.Button("\\/##ColliderShapeDebugger##BtnDown" .. label) then
                local tmp = list[i + 1]
                list[i + 1] = list[i]
                list[i] = tmp
            end
            ImGui.TableNextRow()
        end
        for i = #need_delete, 1, -1 do
            table.remove(list, need_delete[i])
        end
        local id = self._user_add[1] or 0
        local a, r, g, b = self._user_add[2] or 255, self._user_add[3] or 255, self._user_add[4] or 255,
        self._user_add[5] or 255
        local ret, value, changed
        ImGui.TableNextColumn()
        ImGui.PushItemWidth(-1)
        ret, value = ImGui.Combo("##ColliderShapeDebugger##GroupID", id, class.group_enum, #class.group_enum)
        if ret then
            changed = true
            id = value
        end
        ImGui.PopItemWidth()
        ImGui.TableNextColumn()
        ImGui.ColorButton("##ColliderShapeDebugger##ColorBtn", imgui.ImVec4(r / 255, g / 255, b / 255, a / 255))
        ImGui.TableNextColumn()
        ImGui.PushItemWidth(-1)
        ret, value = ImGui.DragInt("##ColliderShapeDebugger##ColorA", a, 1, 0, 255)
        if ret then
            changed = true
            a = value
        end
        ImGui.PopItemWidth()
        ImGui.TableNextColumn()
        ImGui.PushItemWidth(-1)
        ret, value = ImGui.DragInt("##ColliderShapeDebugger##ColorR", r, 1, 0, 255)
        if ret then
            changed = true
            r = value
        end
        ImGui.PopItemWidth()
        ImGui.TableNextColumn()
        ImGui.PushItemWidth(-1)
        ret, value = ImGui.DragInt("##ColliderShapeDebugger##ColorG", g, 1, 0, 255)
        if ret then
            changed = true
            g = value
        end
        ImGui.PopItemWidth()
        ImGui.TableNextColumn()
        ImGui.PushItemWidth(-1)
        ret, value = ImGui.DragInt("##ColliderShapeDebugger##ColorB", b, 1, 0, 255)
        if ret then
            changed = true
            b = value
        end
        ImGui.PopItemWidth()
        ImGui.TableNextColumn()
        if changed then
            self._user_add = { id, a, r, g, b }
        end
        ImGui.PushItemWidth(-1)
        if ImGui.Button("Add##ColliderShapeDebugger##NewGroup") then
            table.insert(list,
                    { self._user_add[1], { self._user_add[2], self._user_add[3], self._user_add[4], self._user_add[5] } })
            self._user_add = { 0, 255, 255, 255, 255 }
        end
        ImGui.PopItemWidth()
        ImGui.EndTable()
    end
end

function colliderShapeDebugger:layoutTableChild()
    local remainHeight = ImGui.GetContentRegionAvail().y
    if ImGui.BeginChild("##ColliderShapeDebugger##ListColumnsArea", imgui.ImVec2(0, math.max(0, remainHeight - 80))) then
        self:layoutTable()
    end
    ImGui.EndChild()
end

function colliderShapeDebugger:layout()
    if ImGui.BeginChild("##ColliderShapeDebugger##List", imgui.ImVec2(0, 0)) then
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
        self:layoutTableChild()
        if ImGui.Button("Save##ColliderShapeDebugger##Save") then
            class.save()
        end
        ImGui.SameLine()
        if ImGui.Button("Reload##ColliderShapeDebugger##Reload") then
            class.reload()
        end
        ImGui.SameLine()
        if ImGui.Button("Reset to default##ColliderShapeDebugger##Reset") then
            class.resetToDefault()
        end
    end
    ImGui.EndChild()
end

lstg_debug.addView("lstg.debug.ColliderShapeDebugger", colliderShapeDebugger)
