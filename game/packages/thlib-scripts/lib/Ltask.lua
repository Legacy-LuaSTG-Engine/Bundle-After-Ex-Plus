--------------------------------------------------------------------------------
--- lua coroutine wrapper
--- task system
--------------------------------------------------------------------------------

local max = math.max
local floor = math.floor
local rawget = rawget
local rawset = rawset
local ipairs = ipairs
local insert = table.insert
local create = coroutine.create
local status = coroutine.status
local resume = coroutine.resume
local yield = coroutine.yield

--------------------------------------------------------------------------------
--- task core

---@class task
local task = {}

local field = "task"
local target_stack = {}
local target_stack_n = 0
---@type thread[]
local co_stack = {}
local co_stack_n = 0

---@param target any
---@param f fun()
---@return thread
function task.New(target, f)
    ---@type thread[]?
    local tasks = rawget(target, field)
    if not tasks then
        tasks = {}
        ---@cast tasks -thread[]?, +thread[]
        rawset(target, field, tasks)
    end
    local co = create(f)
    insert(tasks, co)
    return co
end

---@param target any
function task.Do(target)
    ---@type thread[]?
    local tasks = rawget(target, field)
    if tasks then
        for _, co in ipairs(tasks) do
            if status(co) ~= "dead" then
                target_stack_n = target_stack_n + 1
                target_stack[target_stack_n] = target
                co_stack_n = co_stack_n + 1
                co_stack[co_stack_n] = co
                local result, errmsg = resume(co)
                if not result then
                    error(
                        tostring(errmsg)
                        .. "\n========== coroutine traceback ==========\n"
                        .. debug.traceback(co)
                        .. "\n========== C traceback =========="
                    )
                end
                co_stack[co_stack_n] = nil
                co_stack_n = co_stack_n - 1
                target_stack[target_stack_n] = nil
                target_stack_n = target_stack_n - 1
            end
        end
    end
end

---@param target any
---@param reserve_current boolean?
function task.Clear(target, reserve_current)
    if reserve_current then
        local co_current = co_stack[co_stack_n]
        ---@type thread?
        local co_reserved
        for i = 1, co_stack_n do
            if co_stack[i] == co_current then
                co_reserved = co_current
                break
            end
        end
        if co_reserved then
            rawset(target, field, { co_reserved })
        else
            rawset(target, field, nil)
        end
    else
        rawset(target, field, nil)
    end
end

---@param frames number?
function task.Wait(frames)
    frames = frames or 1
    frames = max(1, floor(frames))
    for _ = 1, frames do
        yield()
    end
end

--------------------------------------------------------------------------------
--- task legacy

--- Note: avoid to use it  
function task.GetSelf()
    if target_stack_n > 0 then
        return target_stack[target_stack_n]
    else
        return nil
    end
end

--- Warn: requires current target has a "timer" number property  
--- Note: avoid to use it  
---@deprecated
---@param t number
function task.Until(t)
    t = floor(t)
    ---@type any
    local target = task.GetSelf()
    while target.timer < t do
        yield()
    end
end

return task
