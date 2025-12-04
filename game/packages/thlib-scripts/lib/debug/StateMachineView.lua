local require = _G.require
local pcall = _G.pcall
local pairs = _G.pairs
local ipairs = _G.ipairs
local type = _G.type
local tostring = _G.tostring
local string = require("string")

local lstg_debug = require("lib.Ldebug")
local imgui_exist, imgui = pcall(require, "imgui")

---@class lstg.debug.StateMachineView : lstg.debug.View
local StateMachineView = {}

function StateMachineView:getWindowName()
    return "State Machine Debugger"
end

function StateMachineView:getMenuItemName()
    return "State Machine Debugger"
end

function StateMachineView:getMenuGroupName()
    return "Tool"
end

function StateMachineView:getEnable()
    return self.enable
end

---@param v boolean
function StateMachineView:setEnable(v)
    self.enable = v
end

function StateMachineView:initialize()
    ---@type table<integer, {id: integer, name: string, machine: foundation.StateMachine}>
    self.watching_machines = {}
    self.next_id = 1
    self.selected_machine_id = nil
    self.show_callbacks = true
    self.show_state_transitions = true
    self.auto_scroll = true
    self.selected_state = 0
end

---添加要监视的状态机
---@param machine foundation.StateMachine
---@param name string|nil 状态机的显示名称，如果不提供则使用默认名称
---@return integer watch_id 监视ID，可用于后续移除
function StateMachineView:addWatch(machine, name)
    if not machine then
        return -1
    end

    local watch_id = self.next_id
    self.next_id = self.next_id + 1

    local display_name = name or string.format("StateMachine_%d", watch_id)

    self.watching_machines[watch_id] = {
        id = watch_id,
        name = display_name,
        machine = machine
    }

    -- 如果这是第一个添加的状态机，自动选中它
    if not self.selected_machine_id then
        self.selected_machine_id = watch_id
    end

    return watch_id
end

---移除监视的状态机
---@param watch_id integer
---@return boolean success 是否成功移除
function StateMachineView:removeWatch(watch_id)
    if not self.watching_machines[watch_id] then
        return false
    end

    self.watching_machines[watch_id] = nil

    -- 如果移除的是当前选中的状态机，切换到另一个
    if self.selected_machine_id == watch_id then
        self.selected_machine_id = nil
        -- 寻找第一个可用的状态机
        for id, _ in pairs(self.watching_machines) do
            self.selected_machine_id = id
            break
        end
    end

    return true
end

---清除所有监视的状态机
function StateMachineView:clearWatch()
    self.watching_machines = {}
    self.selected_machine_id = nil
    self.selected_state = 0
end

---获取当前监视的状态机数量
---@return integer
function StateMachineView:getWatchCount()
    local count = 0
    for _ in pairs(self.watching_machines) do
        count = count + 1
    end
    return count
end

function StateMachineView:update()
end

function StateMachineView:layout()
    local ImGui = imgui.ImGui

    -- 显示当前监视的状态机数量
    local watch_count = self:getWatchCount()
    ImGui.Text(string.format("监视中的状态机: %d", watch_count))

    if watch_count == 0 then
        ImGui.Separator()
        ImGui.TextColored(imgui.ImVec4(1.0, 0.8, 0.2, 1.0), "未添加任何监视的状态机")
        ImGui.Text("")
        ImGui.Text("使用以下代码添加要监视的状态机：")
        ImGui.TextColored(imgui.ImVec4(0.6, 0.8, 1.0, 1.0), 'local view = require("lib.debug.StateMachineView")')
        ImGui.TextColored(imgui.ImVec4(0.6, 0.8, 1.0, 1.0), 'local id = view:addWatch(your_machine, "显示名称")')
        ImGui.Text("")
        ImGui.Text("移除监视：")
        ImGui.TextColored(imgui.ImVec4(0.6, 0.8, 1.0, 1.0), 'view:removeWatch(id)')
        ImGui.Text("")
        ImGui.Text("清除所有监视：")
        ImGui.TextColored(imgui.ImVec4(0.6, 0.8, 1.0, 1.0), 'view:clearWatch()')
        return
    end

    ImGui.SameLine()

    -- 状态机选择器（使用组合框）
    ImGui.SetNextItemWidth(200)
    if ImGui.BeginCombo("##MachineSelector", self.selected_machine_id and self.watching_machines[self.selected_machine_id] and self.watching_machines[self.selected_machine_id].name or "选择状态机") then
        for id, watch_info in pairs(self.watching_machines) do
            local is_selected = (self.selected_machine_id == id)
            if ImGui.Selectable(watch_info.name, is_selected) then
                self.selected_machine_id = id
                self.selected_state = 0
            end
            if is_selected then
                ImGui.SetItemDefaultFocus()
            end
        end
        ImGui.EndCombo()
    end

    -- 移除按钮
    if self.selected_machine_id then
        ImGui.SameLine()
        if ImGui.Button("移除此监视") then
            self:removeWatch(self.selected_machine_id)
            return
        end
    end

    -- 清除全部按钮
    if watch_count > 0 then
        ImGui.SameLine()
        if ImGui.Button("清除全部") then
            self:clearWatch()
            return
        end
    end

    ImGui.Separator()

    -- 如果没有选中的状态机，提示选择
    if not self.selected_machine_id or not self.watching_machines[self.selected_machine_id] then
        ImGui.Text("请选择一个状态机")
        return
    end

    local machine = self.watching_machines[self.selected_machine_id].machine

    -- 控制选项
    _, self.show_callbacks = ImGui.Checkbox("显示回调函数", self.show_callbacks)
    ImGui.SameLine()
    _, self.show_state_transitions = ImGui.Checkbox("显示状态转换", self.show_state_transitions)
    ImGui.SameLine()
    _, self.auto_scroll = ImGui.Checkbox("自动滚动", self.auto_scroll)

    ImGui.Separator()

    -- 状态机基本信息
    ImGui.Text("状态机信息")
    ImGui.Indent()
    ImGui.Text(string.format("状态总数: %d", machine.stateCount))
    ImGui.Text(string.format("转换总数: %d", machine.transitionCount))

    local currentStateName = machine:getCurrentStateName()
    if currentStateName then
        ImGui.TextColored(imgui.ImVec4(0.2, 1.0, 0.2, 1.0),
                string.format("当前状态: %s (ID: %d)", currentStateName, machine.currentStateId))
    else
        ImGui.TextColored(imgui.ImVec4(1.0, 0.2, 0.2, 1.0), "当前状态: 无")
    end

    local previousStateId = machine:getPreviousStateId()
    if previousStateId > 0 and machine.states[previousStateId] then
        ImGui.Text(string.format("前一状态: %s (ID: %d)", machine.states[previousStateId].name, previousStateId))
    end
    ImGui.Unindent()

    ImGui.Separator()

    -- 使用 TabBar 组织不同的视图
    if ImGui.BeginTabBar("@StateMachineTabBar") then
        -- 状态列表标签页
        if ImGui.BeginTabItem("状态列表") then
            self:layoutStateList(machine)
            ImGui.EndTabItem()
        end

        -- 转换列表标签页
        if ImGui.BeginTabItem("转换列表") then
            self:layoutTransitionList(machine)
            ImGui.EndTabItem()
        end

        -- 上下文数据标签页
        if ImGui.BeginTabItem("上下文数据") then
            self:layoutContextData(machine)
            ImGui.EndTabItem()
        end

        -- 状态图标签页
        if ImGui.BeginTabItem("状态图") then
            self:layoutStateGraph(machine)
            ImGui.EndTabItem()
        end

        ImGui.EndTabBar()
    end
end

function StateMachineView:layoutStateList(machine)
    local ImGui = imgui.ImGui

    ImGui.Text("所有状态:")
    ImGui.Separator()

    -- 使用 -1 作为高度会自动填充剩余空间
    ImGui.BeginChild("StateList", imgui.ImVec2(0, -1))

    for id = 1, machine.stateCount do
        local state = machine.states[id]
        if state then
            local is_current = (id == machine.currentStateId)
            local is_previous = (id == machine.previousStateId)

            -- 当前状态高亮显示
            if is_current then
                ImGui.TextColored(imgui.ImVec4(0.2, 1.0, 0.2, 1.0), string.format("► [%d] %s", id, state.name))
                -- 自动滚动到当前状态
                if self.auto_scroll and machine.currentStateId ~= self.selected_state then
                    self.selected_state = machine.currentStateId
                    ImGui.SetScrollHereY(0.5)
                end
            elseif is_previous then
                ImGui.TextColored(imgui.ImVec4(1.0, 1.0, 0.2, 1.0), string.format("  [%d] %s (前一状态)", id, state.name))
            else
                ImGui.Text(string.format("  [%d] %s", id, state.name))
            end

            -- 显示回调函数信息
            if self.show_callbacks then
                ImGui.Indent()
                local has_callbacks = false
                if state.onEnter then
                    ImGui.TextColored(imgui.ImVec4(0.6, 0.8, 1.0, 1.0), "  ✓ onEnter")
                    has_callbacks = true
                end
                if state.onUpdate then
                    ImGui.TextColored(imgui.ImVec4(0.6, 0.8, 1.0, 1.0), "  ✓ onUpdate")
                    has_callbacks = true
                end
                if state.onExit then
                    ImGui.TextColored(imgui.ImVec4(0.6, 0.8, 1.0, 1.0), "  ✓ onExit")
                    has_callbacks = true
                end
                if not has_callbacks then
                    ImGui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1.0), "  (无回调)")
                end
                ImGui.Unindent()
            end

            -- 显示该状态的转换
            if self.show_state_transitions then
                local transitions = machine.transitionsByState[id]
                if transitions and #transitions > 0 then
                    ImGui.Indent()
                    ImGui.TextColored(imgui.ImVec4(0.8, 0.8, 0.6, 1.0), "  转换:")
                    for _, transition in ipairs(transitions) do
                        local toState = machine.states[transition.to]
                        if toState then
                            local text = "    → " .. toState.name
                            if transition.condition then
                                text = text .. " [有条件]"
                            end
                            ImGui.TextColored(imgui.ImVec4(0.7, 0.7, 0.7, 1.0), text)
                        end
                    end
                    ImGui.Unindent()
                end
            end

            ImGui.Spacing()
        end
    end

    ImGui.EndChild()
end

function StateMachineView:layoutTransitionList(machine)
    local ImGui = imgui.ImGui

    ImGui.Text("所有转换:")
    ImGui.Separator()

    ImGui.BeginChild("TransitionList", imgui.ImVec2(0, -1))

    if machine.transitionCount == 0 then
        ImGui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1.0), "没有定义转换")
    else
        for i = 1, machine.transitionCount do
            local transition = machine.transitions[i]
            if transition then
                local fromState = machine.states[transition.from]
                local toState = machine.states[transition.to]

                if fromState and toState then
                    -- 如果是当前状态的转换，高亮显示
                    local is_from_current = (transition.from == machine.currentStateId)

                    if is_from_current then
                        ImGui.TextColored(imgui.ImVec4(0.2, 1.0, 0.2, 1.0), string.format("[%d] %s → %s",
                                i, fromState.name, toState.name))
                    else
                        ImGui.Text(string.format("[%d] %s → %s",
                                i, fromState.name, toState.name))
                    end

                    ImGui.Indent()
                    if transition.condition then
                        ImGui.TextColored(imgui.ImVec4(0.8, 0.8, 0.2, 1.0), "  条件: 已设置")
                    else
                        ImGui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1.0), "  条件: 无 (总是转换)")
                    end
                    ImGui.Unindent()

                    ImGui.Spacing()
                end
            end
        end
    end

    ImGui.EndChild()
end

function StateMachineView:layoutContextData(machine)
    local ImGui = imgui.ImGui

    ImGui.Text("上下文数据:")
    ImGui.Separator()

    ImGui.BeginChild("ContextData", imgui.ImVec2(0, -1))

    local has_data = false
    for key, value in pairs(machine.context) do
        has_data = true
        local value_str = tostring(value)
        local value_type = type(value)

        ImGui.Text(string.format("[%s]", value_type))
        ImGui.SameLine()
        ImGui.TextColored(imgui.ImVec4(0.8, 0.6, 1.0, 1.0), tostring(key))
        ImGui.SameLine()
        ImGui.Text("=")
        ImGui.SameLine()

        -- 根据类型显示不同颜色
        if value_type == "number" then
            ImGui.TextColored(imgui.ImVec4(0.4, 1.0, 0.4, 1.0), value_str)
        elseif value_type == "string" then
            ImGui.TextColored(imgui.ImVec4(1.0, 0.8, 0.4, 1.0), string.format('"%s"', value_str))
        elseif value_type == "boolean" then
            ImGui.TextColored(imgui.ImVec4(0.4, 0.8, 1.0, 1.0), value_str)
        else
            ImGui.Text(value_str)
        end
    end

    if not has_data then
        ImGui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1.0), "上下文为空")
    end

    ImGui.EndChild()
end

function StateMachineView:layoutStateGraph(machine)
    local ImGui = imgui.ImGui

    ImGui.Text("状态转换图:")
    ImGui.Separator()

    ImGui.BeginChild("StateGraph", imgui.ImVec2(0, -1))

    -- 简单的文本形式状态图
    for id = 1, machine.stateCount do
        local state = machine.states[id]
        if state then
            local is_current = (id == machine.currentStateId)

            -- 显示状态节点
            if is_current then
                ImGui.TextColored(imgui.ImVec4(0.2, 1.0, 0.2, 1.0), string.format("┌─ [%s] ─┐", state.name))
            else
                ImGui.Text(string.format("┌─ [%s] ─┐", state.name))
            end

            -- 显示该状态的所有转换
            local transitions = machine.transitionsByState[id]
            if transitions and #transitions > 0 then
                for i, transition in ipairs(transitions) do
                    local toState = machine.states[transition.to]
                    if toState then
                        local arrow = "├─→ "
                        if i == #transitions then
                            arrow = "└─→ "
                        end

                        if transition.condition then
                            ImGui.TextColored(imgui.ImVec4(0.8, 0.8, 0.2, 1.0), arrow .. toState.name .. " [有条件]")
                        else
                            ImGui.TextColored(imgui.ImVec4(0.6, 0.6, 0.6, 1.0), arrow .. toState.name .. " [无条件]")
                        end
                    end
                end
            else
                ImGui.TextColored(imgui.ImVec4(0.5, 0.5, 0.5, 1.0), "  └─ (无转换)")
            end

            ImGui.Spacing()
        end
    end

    ImGui.EndChild()
end

StateMachineView:initialize()

lstg_debug.addView("lstg.debug.StateMachineView", StateMachineView)

return StateMachineView
