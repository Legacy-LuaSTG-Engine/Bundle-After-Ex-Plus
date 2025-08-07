local lfs = require("lfs")
local lstg = require("lstg")

local function warn(fmt, ...)
    lstg.Log(3, string.format(fmt, ...))
end

local function error(fmt, ...)
    lstg.Log(4, string.format(fmt, ...))
end

--- 提供一些快捷的文件读写操作（部分功能受到 `java.nio.file.Files` 启发）  
---@class foundation.Files
local M = {}

--- 辅助函数，将文本内容保存到文件  
---@param path string
---@param content string
---@return boolean result
---@return string? message
function M.writeString(path, content)
    assert(type(path) == "string", "parameter 'path' must be a string")
    assert(type(content) == "string", "parameter 'content' must be a string")
    local f, msg = io.open(path, "wb");
    if not f then
        error("open file '%s' failed (%s)", path, tostring(msg))
        return false, msg
    end
    f, msg = f:write(content)
    if not f then
        error("write to file '%s' failed (%s)", path, tostring(msg))
        return false, msg
    end
    f:close()
    return true, nil
end

local backup_suffix = ".bak"
local temporary_suffix = ".tmp"

--- 辅助函数，将文本内容保存到文件，具体步骤如下：  
--- 1. 保存文本内容到临时文件  
--- 2. 如果原始文件存在，备份原始文件  
--- 3. 将临时文件重命名为目标文件  
---@param path string
---@param content string
---@return boolean result
---@return string? message
function M.writeStringWithBackup(path, content)
    assert(type(path) == "string", "parameter 'path' must be a string")
    assert(type(content) == "string", "parameter 'content' must be a string")
    local path_tmp = path .. temporary_suffix
    local path_bak = path .. backup_suffix
    local r, msg = M.writeString(path_tmp, content)
    if not r then
        return r, msg
    end
    if lfs.attributes(path, "mode") == "file" then
        if lfs.attributes(path_bak, "mode") == "file" then
            r, msg = os.remove(path_bak)
            if not r then
                warn("remove file '%s' failed (%s)", path_bak, tostring(msg))
            end
        end
        r, msg = os.rename(path, path_bak)
        if not r then
            error("rename file '%s' to '%s' failed (%s)", path, path_bak, tostring(msg))
            return r, msg
        end
    end
    r, msg = os.rename(path_tmp, path)
    if not r then
        error("rename file '%s' to '%s' failed (%s)", path_tmp, path, tostring(msg))
        return r, msg
    end
    return true, nil
end

return M
