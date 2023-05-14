--------------------------------------------------------------------------------
--- i18n 组件
--- code by 璀境石
--------------------------------------------------------------------------------

local cjson = require("cjson")

---@class i18n
local M = {}

---@type table<string, table<string, string>>
local lang_data = {}

---@class i18n.locale.metadata
local _ = {
    id = "",
    name = "",
}

---@type table<string, i18n.locale.metadata>
local lang_metadata = {}

---@param locale_path string
---@return i18n.locale.metadata|nil, string|nil
local function loadMetadata(locale_path)
    local file_path = locale_path .. "metadata.json"
    if lstg.FileManager.FileExist(file_path, true) then
        local src = lstg.LoadTextFile(file_path)
        if src then
            local ok, v1 = pcall(cjson.decode, src)
            if ok then
                ---@type i18n.locale.metadata
                local mt = v1
                if type(mt.id) == "string" and type(mt.name) == "string" then
                    if not lang_metadata[mt.id] then
                        lang_metadata[mt.id] = {}
                        lang_metadata[mt.id].id = mt.id
                        lang_metadata[mt.id].name = mt.name
                    else
                        if lang_metadata[mt.id].name ~= mt.name then
                            lstg.Log(3, string.format("不一致的语言名称 '%s', '%s'", lang_metadata[mt.id].name, mt.name))
                        end
                        lang_metadata[mt.id].name = mt.name
                    end
                    return mt, file_path
                else
                    lstg.Log(4, string.format("解析 JSON 文件 '%s' 时出错：不是有效的 metadata 文件", file_path))
                end
            else
                lstg.Log(4, string.format("解析 JSON 文件 '%s' 时出错：%s", file_path, tostring(v1)))
            end
        else
            lstg.Log(4, string.format("加载 JSON 文件 '%s' 时出错：无法读取文件", file_path))
        end
    else
        lstg.Log(4, string.format("加载 JSON 文件 '%s' 时出错：文件不存在", file_path))
    end
    return nil, nil
end

---@param locale string
---@param json_path string
local function loadLang(locale, json_path)
    if lstg.FileManager.FileExist(json_path, true) then
        local src = lstg.LoadTextFile(json_path)
        if src then
            local ok, v1 = pcall(cjson.decode, src)
            if ok then
                ---@type table<string, string>
                local tab = v1
                for k, v in pairs(tab) do
                    if type(k) == "string" and type(v) == "string" then
                        lang_data[locale][k] = v
                    else
                        lstg.Log(4, string.format("解析 JSON 文件 '%s' 时出错：无效的键值对 key:%s (%s) = value:%s (%s)",
                            json_path, type(k), tostring(k), type(v), tostring(v)))
                        return
                    end
                end
            else
                lstg.Log(4, string.format("解析 JSON 文件 '%s' 时出错：%s", json_path, tostring(v1)))
            end
        else
            lstg.Log(4, string.format("加载 JSON 文件 '%s' 时出错：无法读取文件", json_path))
        end
    else
        lstg.Log(4, string.format("加载 JSON 文件 '%s' 时出错：文件不存在", json_path))
    end
end

---@param locale_path string
local function loadLocale(locale_path)
    local mt, mtl = loadMetadata(locale_path)
    if mt then
        if not lang_data[mt.id] then
            lang_data[mt.id] = {}
        end
        local f = lstg.FileManager.EnumFiles(locale_path, "", true)
        for _, e in ipairs(f) do
            if e[2] then
                -- ignore dir
            elseif e[1] ~= mtl then
                loadLang(mt.id, e[1])
            end
        end
    else
        lstg.Log(4, string.format("'%s' 不是有效的语言文件夹", locale_path))
    end
end

function M.listLocale()
    ---@type i18n.locale.metadata[]
    local ret = {}
    for _, v in pairs(lang_metadata) do
        table.insert(ret, {
            id = v.id,
            name = v.name
        })
    end
    return ret
end

function M.refresh()
    ---@param root_path string
    local function findLang(root_path)
        local f = lstg.FileManager.EnumFiles(root_path, "", true)
        for _, e in ipairs(f) do
            if e[2] then
                loadLocale(e[1])
            end
        end
    end
    ---@type string[]
    local lang_path_list = {
        "assets/lang/",
        "data/assets/lang/",
        "packages/thlib-scripts/assets/lang/",
        "packages/thlib-resources/assets/lang/",
    }
    for _, path in ipairs(lang_path_list) do
        findLang(path)
    end
end

---@type table<string, string[]>
local lang_search = {
    en_us = { "en_us", "zh_cn" },
    zh_cn = { "zh_cn", "en_us" },
    ja_jp = { "ja_jp", "en_us", "zh_cn" },
}
setmetatable(lang_search, { __index = function(_, _) return lang_search.en_us end })

---@return string
local function getSettingLocale()
    local locale = "zh_cn"
    if setting and type(setting.locale) == "string" then
        locale = setting.locale
    end
    return locale
end

local g_locale = getSettingLocale()

---@param locale string
function M.setLocale(locale)
    g_locale = locale
end

---@param key string
---@return string
function M.string(key)
    for _, lc in ipairs(lang_search[g_locale]) do
        if lang_data[lc] and lang_data[lc][key] then
            return lang_data[lc][key]
        end
    end
    return key
end

M.refresh()

return M
