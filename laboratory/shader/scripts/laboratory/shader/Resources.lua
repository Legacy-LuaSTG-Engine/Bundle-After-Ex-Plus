local lstg = require("lstg")

---@class laboratory.shader.Resources
local Resources = {}

---@param name string
---@param path string
---@param mipmap boolean?
function Resources.loadSprite(name, path, mipmap)
    lstg.LoadTexture(name, path, mipmap)
    local width, height = lstg.GetTextureSize(name)
    lstg.LoadImage(name, name, 0, 0, width, height)
end

return Resources
