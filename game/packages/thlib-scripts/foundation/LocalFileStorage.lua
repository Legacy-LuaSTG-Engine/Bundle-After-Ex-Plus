---@class foundation.LocalFileStorage
local M = {}

local dir_root     = "userdata"
local dir_snapshot = dir_root .. "/snapshot"
local dir_replay   = dir_root .. "/replay"
local dir_save     = dir_root .. "/save"

--- 创建所有预设文件夹  
function M.createDirectories()
    lstg.FileManager.CreateDirectory(dir_root)
    lstg.FileManager.CreateDirectory(dir_snapshot)
    lstg.FileManager.CreateDirectory(dir_replay)
    lstg.FileManager.CreateDirectory(dir_save)
end

--- 本地文件储存根目录  
---@return string
function M.getRootDirectory()
    return dir_root
end

--- 获取截图文件夹  
---@return string
function M.getSnapshotDirectory()
    return dir_snapshot
end

--- 获取回放数据文件夹，即存放所谓的 replay 文件  
---@return string
function M.getReplayDirectory()
    return dir_replay
end

--- 获取数据储存文件夹，一般用于存放游戏存档  
---@return string
function M.getDataStorageDirectory()
    return dir_save
end

--- 辅助函数，截图  
--- 为了正确截取画面，必须在 `FrameFunc` 中的 `lstg.EndScene` 之后调用  
function M.snapshot()
    local file_name = string.format("%s/%s.jpg", M.getSnapshotDirectory(), os.date("%Y-%m-%d-%H-%M-%S"))
    lstg.Snapshot(file_name)
end

return M
