---=====================================
---luastg input
---=====================================

----------------------------------------
---按键状态更新

KeyState = {}
KeyStatePre = {}

---刷新输入
function GetInput()
    for k, v in pairs(setting.keys) do
        KeyStatePre[k] = KeyState[k]
        KeyState[k] = GetKeyState(v)
    end
end

---是否按下
function KeyIsDown(key)
    return KeyState[key]
end

---是否在当前帧按下
function KeyIsPressed(key)
    --于javastage中重载
    return KeyState[key] and (not KeyStatePre[key])
end

---兼容
KeyPress = KeyIsDown
KeyTrigger = KeyIsPressed

---将按键二进制码转换为字面值，用于设置界面
function KeyCodeToName()
    local key2name = {}
    -- 按键code（参见launch和微软文档）作为索引，名称为值
    for k, v in pairs(lstg.Input.Keyboard or KEY) do
        if type(v) == "number" then
            key2name[v] = k
        end
    end
    -- 没有名字的就给个默认名字
    for i = 0, 255 do
        key2name[i] = key2name[i] or string.format("0x%X", i)
    end
    return key2name
end
