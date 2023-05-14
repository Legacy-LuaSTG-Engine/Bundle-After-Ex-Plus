---=====================================
---luastg user global value
---=====================================

----------------------------------------
---user  global value

---退出游戏
lstg.quit_flag = false

---暂停
lstg.paused = false

---跨关全局变量表
---@type table
lstg.var = { username = setting.username }

---关卡内全局变量表
---@type table
lstg.tmpvar = {}

---播放录像时用来临时保存lstg.var的表，默认为nil
---@type nil|table
lstg.nextvar = nil

---设置一个全局变量
---@param k number|string
---@param v any
function lstg.SetGlobal(k, v)
    lstg.var[k] = v
end

---获取一个全局变量
---@param k number|string
---@return any
function lstg.GetGlobal(k)
    return lstg.var[k]
end

SetGlobal = lstg.SetGlobal
GetGlobal = lstg.GetGlobal

---重置关卡内全局变量表
function lstg.ResetLstgtmpvar()
    lstg.tmpvar = {}
end
