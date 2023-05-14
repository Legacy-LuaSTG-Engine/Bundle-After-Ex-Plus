---@class test.tester
local M = {}

---@param e string
---@return string
local function traceback(e)
    return debug.traceback(e, 2)
end

local test_module_name = "default"

---@param name string
function M.set_module_name(name)
    test_module_name = name
end

---@param name string
---@param f fun()
---@return boolean
function M.case(name, f)
    local head = string.format("[test] [%s] [%s]", test_module_name, name)
    local ret, err = xpcall(f, traceback)
    if ret then
        print(("%-64s pass"):format(head))
        return true
    else
        print(("%-64s failed\n%s"):format(head, err))
        return false
    end
end

return M
