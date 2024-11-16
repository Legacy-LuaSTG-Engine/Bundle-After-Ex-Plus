-- 全局配置信息
-- 注：由打包器自动生成
local gconfig = require("gconfig")
gconfig.bundle_version_major = math.floor(assert(tonumber("{VERSION_MAJOR}"), "invalid version major number"))
gconfig.bundle_version_minor = math.floor(assert(tonumber("{VERSION_MINOR}"), "invalid version minor number"))
gconfig.bundle_version_patch = math.floor(assert(tonumber("{VERSION_PATCH}"), "invalid version patch number"))
gconfig.bundle_version_pre_release = "{VERSION_PRE_RELEASE}"
gconfig.bundle_version_build_info = "{VERSION_BUILD_TIMESTAMP}"
gconfig.bundle_version = "" .. gconfig.bundle_version_major .. "." .. gconfig.bundle_version_minor .. "." .. gconfig.bundle_version_patch .. gconfig.bundle_version_pre_release .. gconfig.bundle_version_build_info
gconfig.bundle_name = "{NAME}"
gconfig.window_title = gconfig.bundle_name .. " v" .. gconfig.bundle_version
