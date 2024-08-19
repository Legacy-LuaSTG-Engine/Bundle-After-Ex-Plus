----------------------------------------
--- core stage system
--- rewrite by 璀境石
----------------------------------------

local SceneManager = require("foundation.SceneManager")

---@generic T
---@param C T
---@return T
local function make_instance(C)
    local I = {}
    setmetatable(I, { __index = C })
    return I
end

----------------------------------------
--- class stage.Stage

---@class stage.Stage
local S = {}

S.stage_name = "__default__"

S.is_menu = true

function S:init() end

function S:frame() end

function S:render() end

function S:del() end

----------------------------------------
--- stage system

---@class stage
local M = {}

M.stages = {}

---@type stage.Stage
M.current_stage = S

---@type stage.Stage
M.next_stage = S

M.preserve_res = false

---@param stage_name string
---@param as_entrance boolean
---@param is_menu boolean
---@return stage.Stage
---@overload fun(stage_name:string): stage.Stage
---@overload fun(stage_name:string, as_entrance:boolean): stage.Stage
function M.New(stage_name, as_entrance, is_menu)
    assert(type(stage_name) == "string", "stage name must be a string")
    ---@type stage.Stage
    local result = {
        init = S.init,
        del = S.del,
        render = S.render,
        frame = S.frame,
        stage_name = stage_name,
        is_menu = is_menu,
    }
    M.stages[stage_name] = result
    if as_entrance then
        M.next_stage = result
    end
    return result
end

--- 加载 THlib 后，会被重载以适应 replay 系统
---@param stage_name string
function M.Set(stage_name)
    assert(type(stage_name) == "string", "stage name must be a string")
    M.next_stage = M.stages[stage_name]
    assert(M.next_stage, "stage does not exist")
    -- TODO: 这个是干什么的？
    KeyStatePre = {}
end

function M.NextStageExist()
    return (not (not M.next_stage))
end

function M.Change()
    M.DestroyCurrentStage()
    M.CreateNextStage()
end

function M.DestroyCurrentStage()
    M.current_stage:del()
    lstg.ResetPool()
    if M.preserve_res then
        M.preserve_res = false
    else
        lstg.RemoveResource("stage")
    end
end

function M.CreateNextStage()
    local next_stage = M.next_stage
    M.next_stage = nil
    assert(next_stage, "next stage is nil")
    M.current_stage = make_instance(next_stage)
    M.current_stage.timer = 0
    M.current_stage:init()
end

function M.Update()
    -- TODO: 这个东西好烦，为了兼容性没法去掉，但是留着它又不好自行控制 task 更新的位置
    task.Do(M.current_stage)
    M.current_stage:frame()
    M.current_stage.timer = M.current_stage.timer + 1
end

----------------------------------------
--- other method

---@deprecated
function M.SetTimer(t)
    M.current_stage.timer = t - 1
end

function M.QuitGame()
    lstg.quit_flag = true
    SceneManager.setExitSignal(true)
end

----------------------------------------
--- initialize

M.stages[S.stage_name] = S
M.Set(S.stage_name)
M.Change()

----------------------------------------
--- known global

stage = M

return M
