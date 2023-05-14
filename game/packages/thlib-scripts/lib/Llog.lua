---=====================================
---luastg simple log system
---=====================================

----------------------------------------
--- Log wrapper

--- 输出一条日志
--- 1, 2, 3, 4, 5, 分别代表 debug, info, warning, error, fatal 共5个级别
---@param level number
---@vararg string
function Log(level, ...)
    local arg = {...}
    for i, v in ipairs(arg) do
        arg[i] = tostring(v)
    end
    local msg = table.concat(arg, "\t")
    lstg.Log(level, msg)
end

----------------------------------------
--- simple MessageBox

--- 简单的警告弹窗
---@param msg string
function lstg.MsgBoxWarn(msg)
    local ret = lstg.MessageBox("程序异常警告", tostring(msg), 1 + 48)
    if ret == 2 then
        stage.QuitGame()
    end
end

--- 简单的错误弹窗
---@param msg string
function lstg.MsgBoxError(msg, title, exit)
    local ret = lstg.MessageBox(title, tostring(msg), 0 + 16)
    if ret == 1 and exit then
        stage.QuitGame()
    end
end
