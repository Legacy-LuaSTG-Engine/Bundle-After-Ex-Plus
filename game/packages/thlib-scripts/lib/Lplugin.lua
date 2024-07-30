--------------------------------------------------------------------------------
--- plugin manager
--- by 璀境石
--------------------------------------------------------------------------------

local cjson_util = require("cjson.util")

--------------------------------------------------------------------------------
--- 工具

---@param file_path string
---@return boolean
local function isFileNameZip(file_path)
    if string.len(file_path) < 4 then
        return false
    end
    return string.sub(file_path, string.len(file_path) - 3) == ".zip"
end

---@param cfg lstg.plugin.Config.Entry[]
local function printConfigList(cfg)
    lstg.Print("========== plugin ==========")
    for i, v in ipairs(cfg) do
        lstg.Print(tostring(i), v.name, v.path, v.directory_mode)
    end
    lstg.Print("============================")
end

--------------------------------------------------------------------------------
--- 枚举和加载

---@class plugin @插件包辅助
lstg.plugin = {}

local PLUGIN_PATH = "plugins/"    --插件路径
local ENTRY_POINT_SCRIPT = "__init__.lua"   --入口点文件

--- 列出插件目录下所有有效的插件（即包含入口点文件）  
---@return lstg.plugin.Config.Entry[]
function lstg.plugin.ListPlugins()
    local list = lstg.FileManager.EnumFiles(PLUGIN_PATH)
    local result = {}
    for _, v in ipairs(list) do
        if v[2] then
            -- 文件夹模式
            if lstg.FileManager.FileExist(v[1] .. ENTRY_POINT_SCRIPT) then
                -- 有入口点文件
                table.insert(result, {
                    name = string.sub(v[1], string.len(PLUGIN_PATH) + 1, string.len(v[1]) - 1),
                    path = v[1],
                    directory_mode = true,
                    enable = true, -- 默认启用
                })
            end
        elseif isFileNameZip(v[1]) then
            -- 压缩包模式
            lstg.LoadPack(v[1])
            local file_exist = lstg.FileManager.GetArchive(v[1]):FileExist(ENTRY_POINT_SCRIPT)
            lstg.UnloadPack(v[1])
            if file_exist then
                -- 有入口点文件
                table.insert(result, {
                    name = string.sub(v[1], string.len(PLUGIN_PATH) + 1, string.len(v[1]) - 4),
                    path = v[1],
                    directory_mode = false,
                    enable = true, -- 默认启用
                })
            end
        end
    end
    return result
end

--- 装载一个插件包，然后执行入口点脚本  
--- 失败则返回 false  
---@param entry lstg.plugin.Config.Entry
---@return boolean
function lstg.plugin.LoadPlugin(entry)
    if entry.directory_mode then
        lstg.FileManager.AddSearchPath(entry.path)
        lstg.DoFile(entry.path .. ENTRY_POINT_SCRIPT)
    else
        lstg.LoadPack(entry.path)
        lstg.DoFile(ENTRY_POINT_SCRIPT, entry.path)
    end
    return true
end

--------------------------------------------------------------------------------
--- 配置文件

local CONFIG_FILE = "plugins.json"

---@class lstg.plugin.Config.Entry
local _ = {
    name = "",
    path = "",
    directory_mode = false,
    enable = false,
}

--- 检查目录是否存在，不存在则创建
local function checkDirectory()
    lstg.FileManager.CreateDirectory(PLUGIN_PATH)
end

--- 加载配置文件
---@return lstg.plugin.Config.Entry[]
function lstg.plugin.LoadConfig()
    checkDirectory()
    local f = io.open(PLUGIN_PATH .. CONFIG_FILE, "rb")
    if f then
        local src = f:read('*a')
        f:close()
        local ret, val = pcall(cjson.decode, src)
        if ret then
            return val
        else
            lstg.Log(4, string.format("load json '%s' failed: %s", PLUGIN_PATH .. CONFIG_FILE, val))
            return {}
        end
    else
        return {}
    end
end

--- 保存配置文件
---@param cfg lstg.plugin.Config.Entry[]
function lstg.plugin.SaveConfig(cfg)
    checkDirectory()
    local f, msg
    f, msg = io.open(PLUGIN_PATH .. CONFIG_FILE, "wb")
    if f then
        f:write(cjson_util.format_json(cjson.encode(cfg)))
        f:close()
    else
        error(msg)
    end
end

--- 遍历插件目录下所有的插件，来获得一个配置表  
--- 如果传入了一个配置表，则对传入的配置表进行刷新  
---@param cfg lstg.plugin.Config.Entry[]
---@return lstg.plugin.Config.Entry[]
function lstg.plugin.FreshConfig(cfg)
    local new_cfg = lstg.plugin.ListPlugins()
    if type(cfg) == "table" then
        -- 复制 enable 的值
        for _, v in ipairs(cfg) do
            for _, new_v in ipairs(new_cfg) do
                if v.name == new_v.name and v.path == new_v.path and v.directory_mode == new_v.directory_mode then
                    new_v.enable = v.enable
                    break
                end
            end
        end
    end
    return new_cfg
end

--- 根据一个配置表，按照顺序加载插件  
---@param cfg lstg.plugin.Config.Entry[]
function lstg.plugin.LoadPluginsByConfig(cfg)
    for _, v in ipairs(cfg) do
        if v.enable then
            lstg.plugin.LoadPlugin(v)
        end
    end
end

--------------------------------------------------------------------------------
--- 插件事件

---@class lstg.plugin.Event.Entry
local _ = {
    name = "",
    priority = 0,
    callback = function() end,
}

local _event = {
    ---@type lstg.plugin.Event.Entry[]
    beforeTHlib = {},
    ---@type lstg.plugin.Event.Entry[]
    afterTHlib = {},
    ---@type lstg.plugin.Event.Entry[]
    afterMod = {},
}

---@param lst lstg.plugin.Event.Entry[]
local function sortEvent(lst)
    table.sort(lst, function(a, b)
        return a.priority > b.priority
    end)
end

---@param type '"beforeTHlib"' | '"afterTHlib"' | '"afterMod"'
---@param name string
---@param priority number
---@param callback fun()
function lstg.plugin.RegisterEvent(type, name, priority, callback)
    assert(_event[type], "invalid event type")
    local lst = _event[type]
    -- 先找找看是否存在
    local flag = false
    for i, v in ipairs(lst) do
        if v.name == name then
            -- 覆盖
            lst[i].priority = priority
            lst[i].callback = callback
            flag = true
            break
        end
    end
    -- 否则插入新的
    if not flag then
        table.insert(lst, {
            name = name,
            priority = priority,
            callback = callback,
        })
    end
    -- 重新排序
    sortEvent(lst)
end

---@param type '"beforeTHlib"' | '"afterTHlib"' | '"afterMod"'
function lstg.plugin.DispatchEvent(type)
    assert(_event[type], "invalid event type")
    for _, v in ipairs(_event[type]) do
        v.callback()
    end
end

--------------------------------------------------------------------------------
--- 接口

--- 加载所有插件包
function lstg.plugin.LoadPlugins()
    local cfg = lstg.plugin.LoadConfig()
    local new_cfg = lstg.plugin.FreshConfig(cfg)
    lstg.plugin.SaveConfig(new_cfg)
    lstg.plugin.LoadPluginsByConfig(new_cfg)
end
