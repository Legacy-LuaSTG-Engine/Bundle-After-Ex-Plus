--------------------------------------------------------------------------------
--- plugin manager
--- by 璀境石
--------------------------------------------------------------------------------

local cjson_util = require("cjson.util")
local table_sort = require("foundation.QuickSort")

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

local PLUGIN_PATH = "plugins/"            -- 插件路径
local ENTRY_POINT_SCRIPT = "__init__.lua" -- 入口点文件
local MANIFEST_NAME = "package.json"      -- 清单文件

---@param path string
---@return string? text
---@return string message
local function readTextFile(path)
    assert(type(path) == "string", "invalid parameter type")
    local f, e = io.open(path, "r")
    if f then
        local s = f:read("*a")
        f:close()
        return s, "success"
    else
        return nil, tostring(e)
    end
end

---@param archive_name string
---@param path string
---@return string? text
---@return string message
local function readArchiveTextFile(archive_name, path)
    local archive = lstg.FileManager.GetArchive(archive_name)
    if not archive:FileExist(path) then
        return nil, ("file '%s' in '%s' not found"):format(path, archive_name)
    end
    local s = lstg.LoadTextFile(path, archive_name)
    if type(s) == "string" then
        return s, "success"
    else
        return nil, ("read file '%s' in '%s' failed"):format(path, archive_name)
    end
end

---@param root_path string
---@return lstg.plugin.Config.Entry?
local function processLegacyModelPlugin(root_path)
    local name = string.sub(root_path, string.len(PLUGIN_PATH) + 1, string.len(root_path) - 1)
    ---@type lstg.plugin.Config.Entry
    local entry = {
        name = name,
        description = name,
        path = root_path,
        model_type = "legacy",
        directory_mode = true,
        enable = true,
    }
    return entry
end

---@return boolean result
---@return string message
local function verifyManifest(t)
    if t.name == nil then
        return false, "invalid plugin manifest file: 'name' is required"
    end
    if type(t.name) ~= "string" then
        return false, "invalid plugin manifest file: 'name' must be a string"
    end

    if t.version == nil then
        return false, "invalid plugin manifest file: 'version' is required"
    end
    if type(t.version) ~= "string" then
        return false, "invalid plugin manifest file: 'version' must be a string"
    end

    if t.main ~= nil then
        if type(t.main) ~= "string" then
            return false, "invalid plugin manifest file: 'main' must be a string"
        end
    end

    if t.description then
        if type(t.description) ~= "string" then
            return false, "invalid plugin manifest file: 'description' must be a string"
        end
    end

    return true, "ok"
end

---@param root_path string
---@return lstg.plugin.Config.Entry?
local function processManifestModelPlugin(root_path)
    assert(type(root_path) == "string", "invalid parameter type")
    local package_json_path = root_path .. MANIFEST_NAME
    local package_json_text, read_file_error = readTextFile(package_json_path)
    if not package_json_text then
        lstg.Log(4, ("failed to read file '%s': %s"):format(package_json_path, read_file_error))
        return
    end
    local decode_result, package_json = pcall(cjson.decode, package_json_text)
    if not decode_result then
        lstg.Log(4, ("invalid plugin file '%s': %s"):format(package_json_path, tostring(package_json)))
        return
    end
    local verify_result, verify_error = verifyManifest(package_json)
    if not verify_result then
        lstg.Log(4, verify_error)
        return
    end
    if package_json.main then
        local main_lua_path = root_path .. package_json.main
        if not lstg.FileManager.FileExist(main_lua_path) then
            lstg.Log(4, ("invalid plugin '%s' ('%s'): main script '%s' not found"):format(package_json.name, root_path, main_lua_path))
            return
        end
    end
    ---@type lstg.plugin.Config.Entry
    local entry = {
        name = package_json.name,
        description = package_json.description,
        main = package_json.main,
        path = root_path,
        model_type = "manifest",
        directory_mode = true,
        enable = true,
    }
    return entry
end

---@param archive_path string
---@return lstg.plugin.Config.Entry?
local function processManifestModelPluginArchive(archive_path)
    assert(type(archive_path) == "string", "invalid parameter type")
    local package_json_path = MANIFEST_NAME
    local package_json_text, read_file_error = readArchiveTextFile(archive_path, package_json_path)
    if not package_json_text then
        lstg.Log(4, ("failed to read file '%s' in '%s': %s"):format(package_json_path, archive_path, read_file_error))
        return
    end
    local decode_result, package_json = pcall(cjson.decode, package_json_text)
    if not decode_result then
        lstg.Log(4, ("invalid plugin file '%s' in '%s': %s"):format(package_json_path, archive_path, tostring(package_json)))
        return
    end
    local verify_result, verify_error = verifyManifest(package_json)
    if not verify_result then
        lstg.Log(4, verify_error)
        return
    end
    if package_json.main then
        local main_lua_path = package_json.main
        local archive = lstg.FileManager.GetArchive(archive_path)
        if not archive:FileExist(main_lua_path) then
            lstg.Log(4, ("invalid plugin '%s' ('%s'): main script '%s' not found"):format(package_json.name, archive_path, main_lua_path))
            return
        end
    end
    ---@type lstg.plugin.Config.Entry
    local entry = {
        name = package_json.name,
        description = package_json.description,
        main = package_json.main,
        path = archive_path,
        model_type = "manifest",
        directory_mode = false,
        enable = true,
    }
    return entry
end

--- 列出插件目录下所有有效的插件（即包含入口点文件）  
---@return lstg.plugin.Config.Entry[]
function lstg.plugin.ListPlugins()
    local list = lstg.FileManager.EnumFiles(PLUGIN_PATH)
    local result = {}
    for _, v in ipairs(list) do
        if v[2] then
            -- 文件夹模式
            if lstg.FileManager.FileExist(v[1] .. MANIFEST_NAME) then
                -- 清单文件模式（新）
                local entry = processManifestModelPlugin(v[1])
                if entry then
                    table.insert(result, entry)
                end
            elseif lstg.FileManager.FileExist(v[1] .. ENTRY_POINT_SCRIPT) then
                -- 传统模式（旧）
                local entry = processLegacyModelPlugin(v[1])
                if entry then
                    table.insert(result, entry)
                end
            end
        elseif isFileNameZip(v[1]) then
            -- 压缩包模式
            lstg.LoadPack(v[1])
            local archive = lstg.FileManager.GetArchive(v[1])
            local has_init = archive:FileExist(ENTRY_POINT_SCRIPT)
            local has_manifest = archive:FileExist(MANIFEST_NAME)
            if has_manifest then
                -- 清单文件模式（新）
                local entry = processManifestModelPluginArchive(v[1])
                if entry then
                    table.insert(result, entry)
                end
            elseif has_init then
                -- 传统模式（旧）
                local name = string.sub(v[1], string.len(PLUGIN_PATH) + 1, string.len(v[1]) - 4)
                table.insert(result, {
                    name = name,
                    description = name,
                    path = v[1],
                    model_type = "legacy",
                    directory_mode = false,
                    enable = true, -- 默认启用
                })
            end
            lstg.UnloadPack(v[1])
        end
    end
    return result
end

--- 装载一个插件包，然后执行入口点脚本  
--- 失败则返回 false  
---@param entry lstg.plugin.Config.Entry
---@return boolean
function lstg.plugin.LoadPlugin(entry)
    if entry.model_type == "manifest" then
        if entry.directory_mode then
            lstg.FileManager.AddSearchPath(entry.path)
            if entry.main then
                lstg.DoFile(entry.path .. entry.main)
            end
        else
            lstg.LoadPack(entry.path)
            if entry.main then
                lstg.DoFile(entry.main, entry.path)
            end
        end
    else -- legacy model type
        if entry.directory_mode then
            lstg.FileManager.AddSearchPath(entry.path)
            lstg.DoFile(entry.path .. ENTRY_POINT_SCRIPT)
        else
            lstg.LoadPack(entry.path)
            lstg.DoFile(ENTRY_POINT_SCRIPT, entry.path)
        end
    end
    return true
end

--------------------------------------------------------------------------------
--- 配置文件

local CONFIG_FILE = "plugins.json"

---@class lstg.plugin.Config.Entry
local _ = {
    name = "",
    description = "",
    path = "",
    ---@type string?
    main = "",
    ---@type '"legacy"' | '"manifest"'
    model_type = "legacy",
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
        if ret and type(val) == "table" then
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
    table_sort(lst, function(a, b)
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
