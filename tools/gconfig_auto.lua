-- 全局配置信息
-- 注：由打包器自动生成

local gconfig = require("gconfig")
gconfig.bundle_version_build_info = "+{BUILD_TIMESTAMP}"
gconfig.bundle_version = ""
    .. gconfig.bundle_version_major
    .. "." .. gconfig.bundle_version_minor
    .. "." .. gconfig.bundle_version_patch
    .. gconfig.bundle_version_pre_release
    .. gconfig.bundle_version_build_info
