local lstg = require("lstg")
local Keyboard = lstg.Input.Keyboard

---@class foundation.KeyboardAdaptor
local KeyboardAdaptor = {}

---@type table<integer, string>
local names = {}

for k, v in pairs(Keyboard) do
    if type(k) == "string" and type(v) == "number" then
        names[v] = k
    end
end
for code = 0, 255 do
    if not names[code] then
        names[code] = ("Key%d"):format(code)
    end
end

---@param code integer
local function assertCode(code)
    assert(type(code) == "number", "code must be a number")
    assert(math.floor(code) == code, "code must be a integral number")
    if code < 0 or code > 255 then
        -- 这里涉及字符串格式化，所以需要条件不满足时才走该分支
        error(("code '%d' out of range (requirement 0 <= code <= 255)"):format(code))
    end
end

--- 按键是否按下  
---@param code integer
---@return boolean
function KeyboardAdaptor.isKeyDown(code)
    assertCode(code)
    return Keyboard.GetKeyState(code)
end

--- 是否有任何按键按下  
--- 如果有按键按下，返回按键码和唯一的按键名称（可以配合 i18n 使用，不建议直接展示给用户）  
--- 如果没有按键按下，返回 `nil`  
---@return integer? code
---@return string? name
function KeyboardAdaptor.isAnyKeyDown()
    -- 由于 Keyboard.None = 0，这里从 1 开始
    for code = 1, 255 do
        if Keyboard.GetKeyState(code) then
            return code, names[code]
        end
    end
    return nil, nil
end

--- 获取唯一的按键名称（可以配合 i18n 使用，不建议直接展示给用户）  
---@param code integer
---@return string
function KeyboardAdaptor.getKeyName(code)
    assertCode(code)
    return names[code]
end

return KeyboardAdaptor
