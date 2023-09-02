local LocalFileStorage = require("foundation.LocalFileStorage")

local M = {}
lstg.LocalUserData = M

---@deprecated
---@return string
function M.GetRootDirectory()
    return LocalFileStorage.getRootDirectory()
end

---@deprecated
---@return string
function M.GetSnapshotDirectory()
    return LocalFileStorage.getSnapshotDirectory()
end

---@deprecated
---@return string
function M.GetReplayDirectory()
    return LocalFileStorage.getReplayDirectory()
end

---@deprecated
---@return string
function M.GetDatabaseDirectory()
    return LocalFileStorage.getDataStorageDirectory()
end

---@deprecated
function M.Snapshot()
    return LocalFileStorage.snapshot()
end

LocalFileStorage.createDirectories()

return M
