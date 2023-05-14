-------------------------------------------------- file system

---@param path string
---@return boolean
function plus.DirectoryExists(path)
    return lstg.FileManager.DirectoryExist(path)
end

---@param path string
function plus.CreateDirectory(path)
    return lstg.FileManager.CreateDirectory(path)
end

---@class plus.DirectoryEntry
local _ = {
    isDirectory = false,
    name = "abc.txt",
    -- NOT IMPL
    lastAccessTime = 0,
    -- NOT IMPL
    size = 0,
}

---@param path string
---@return plus.DirectoryEntry[]
function plus.EnumFiles(path)
    local len = string.len(path)
    if len > 0 then
        local c = string.sub(path, len, len)
        if c ~= "/" or c ~= "\\" then
            path = path .. "/"
            len = len + 1
        end
    end
    local list = lstg.FileManager.EnumFiles(path)
    for _, v in ipairs(list) do
        v.isDirectory = v[2]
        v.name = string.sub(v[1], string.len(path) + 1)
        if v.isDirectory then
            v.name = string.sub(v.name, 1, -2)
        end
        v.lastAccessTime = 0 -- TODO
        v.size = 0 -- TODO
    end
    return list
end

---@param path string
---@return string, string
function plus.SplitPath(path)
    local pos = 0
    while true do
        local p = string.find(path, "[/\\]", pos + 1)
        if p then
            pos = p
        else
            break
        end
    end
    return string.sub(path, 1, pos), string.sub(path, pos + 1)
end

---@deprecated
function __UTF8ToANSI(str) return str end
