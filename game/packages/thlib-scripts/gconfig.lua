--- 全局配置信息  
--- 
--- Global configurations  
---@class gconfig
gconfig = {}

--- 备注：请参考语义化版本号（https://semver.org/lang/zh-CN/）  
--- 主要版本号  
--- 
--- NOTE: Please refer to Semantic Versioning (https://semver.org/)  
--- Major version  
gconfig.bundle_version_major = 0

--- 备注：请参考语义化版本号（https://semver.org/lang/zh-CN/）  
--- 次要版本号  
--- NOTE: Please refer to Semantic Versioning (https://semver.org/)  
--- Minor version  
gconfig.bundle_version_minor = 9

--- 备注：请参考语义化版本号（https://semver.org/lang/zh-CN/）  
--- 补丁版本号  
--- 
--- NOTE: Please refer to Semantic Versioning (https://semver.org/)  
--- Patch version  
gconfig.bundle_version_patch = 0

--- 备注：请参考语义化版本号（https://semver.org/lang/zh-CN/）  
--- 先行版本号  
--- 
--- NOTE: Please refer to Semantic Versioning (https://semver.org/)  
--- Pre-Release version  
gconfig.bundle_version_pre_release = "-alpha.7"

--- 备注：请参考语义化版本号（https://semver.org/lang/zh-CN/）  
--- 构建信息  
--- 
--- NOTE: Please refer to Semantic Versioning (https://semver.org/)  
--- Build info  
gconfig.bundle_version_build_info = ""

--- 备注：请参考语义化版本号（https://semver.org/lang/zh-CN/）  
--- 版本信息  
--- 
--- NOTE: Please refer to Semantic Versioning (https://semver.org/)  
--- Version info  
gconfig.bundle_version = ""
    .. gconfig.bundle_version_major
    .. "." .. gconfig.bundle_version_minor
    .. "." .. gconfig.bundle_version_patch
    .. gconfig.bundle_version_pre_release
    .. gconfig.bundle_version_build_info

--- 开发框架名称  
--- 
--- Name of development framework  
gconfig.bundle_name = "LuaSTG aex+"

--- 默认窗口标题  
--- 
--- Default window title  
gconfig.window_title = gconfig.bundle_name .. " v" .. gconfig.bundle_version

return gconfig
