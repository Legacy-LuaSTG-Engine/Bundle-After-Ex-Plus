local LocalFileStorage = require("foundation.LocalFileStorage")

local M = {}
lstg.LocalUserData = M

function M.CreateDirectories()
    return LocalFileStorage.createDirectories()
end

---@return string
function M.GetRootDirectory()
    return LocalFileStorage.getRootDirectory()
end

---@return string
function M.GetSnapshotDirectory()
    return LocalFileStorage.getSnapshotDirectory()
end

---@return string
function M.GetReplayDirectory()
    return LocalFileStorage.getReplayDirectory()
end

---@return string
function M.GetDatabaseDirectory()
    return LocalFileStorage.getDataStorageDirectory()
end

function M.Snapshot()
    return LocalFileStorage.snapshot()
end

LocalFileStorage.createDirectories()

return M
