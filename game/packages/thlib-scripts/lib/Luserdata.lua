
---@class lstg.LocalUserData
local M = {}
lstg.LocalUserData = M

local dir_root     = "userdata"
local dir_snapshot = dir_root .. "/snapshot"
local dir_replay   = dir_root .. "/replay"
local dir_database = dir_root .. "/database"

function M.CreateDirectories()
    lstg.FileManager.CreateDirectory(dir_root)
    lstg.FileManager.CreateDirectory(dir_snapshot)
    lstg.FileManager.CreateDirectory(dir_replay)
    lstg.FileManager.CreateDirectory(dir_database)
end

---@return string
function M.GetRootDirectory()
    return dir_root
end

---@return string
function M.GetSnapshotDirectory()
    return dir_snapshot
end

---@return string
function M.GetReplayDirectory()
    return dir_replay
end

---@return string
function M.GetDatabaseDirectory()
    return dir_database
end

function M.Snapshot()
    local file_name = string.format("%s/%s.jpg", dir_snapshot, os.date("%Y-%m-%d-%H-%M-%S"))
    lstg.Snapshot(file_name)
end

M.CreateDirectories()
