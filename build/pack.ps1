# 发明项目：自动化打包
# 发明人：璀境石

#--------------------------------------------------------------------------------
# 函数库

function New-Directory-If-Not-Exist {
    param (
        [string] $Path
    )
    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -ItemType Directory
    }
}

function Remove-Directory-If-Exist {
    param (
        [string] $Path
    )
    if (Test-Path -Path $Path) {
        Remove-Item -Path $Path -Recurse
    }
}

function Copy-Directory-And-Remove-Old {
    param (
        [string] $SourcePath,
        [string] $TargetPath
    )
    Remove-Directory-If-Exist -Path $TargetPath
    Copy-Item -Path $SourcePath -Destination $TargetPath -Recurse
}

function Remove-File-If-Exist {
    param (
        [string] $Path
    )
    if (Test-Path -Path $Path) {
        Remove-Item -Path $Path -Force
    }
}

function Remove-File-Force {
    param (
        [string] $Path
    )
    [bool] $Exist = Test-Path -Path $Path
    if ($Exist -eq $true) {
        Remove-Item -Path $Path -Force
    }
}

function Copy-File-And-Remove-Old {
    param (
        [string] $SourcePath,
        [string] $TargetPath
    )
    Remove-File-If-Exist -Path $TargetPath
    Copy-Item -Path $SourcePath -Destination $TargetPath
}

#--------------------------------------------------------------------------------
# 前期准备

Write-Output "Environment:"

# 进入项目根目录

Set-Location -Path "$($PSScriptRoot)/.."
[string] $ProjectRoot = Get-Location
Write-Output "    ProjectRoot   : $($ProjectRoot)"

# 配置基础变量

[string] $DocumentRoot  = "$($ProjectRoot)/document"
[string] $GameRoot      = "$($ProjectRoot)/game"
[string] $GameModRoot   = "$($ProjectRoot)/game/mod"
[string] $ToolRoot      = "$($ProjectRoot)/tools"
[string] $BuildRoot     = "$($ProjectRoot)/build"
[string] $Zip           = "$($ToolRoot)/7z/7z.exe"
Write-Output "    DocumentRoot  : $($DocumentRoot)"
Write-Output "    GameRoot      : $($GameRoot)"
Write-Output "    GameModRoot   : $($GameModRoot)"
Write-Output "    ToolRoot      : $($ToolRoot)"
Write-Output "    BuildRoot     : $($BuildRoot)"
Write-Output "    Zip           : $($Zip)"

# 读取版本信息

$VersionInfo = Get-Content -Path "$($BuildRoot)/version.json" -Raw | ConvertFrom-Json
[string] $BuildTimestamp = "$(Get-Date -Format "yyyyMMddHHmmss")"
[string] $ArchiveName = "$($VersionInfo.name -replace " ", "-")-v$($VersionInfo.major).$($VersionInfo.minor).$($VersionInfo.patch)"
if ($VersionInfo.pre_release.Length -gt 0) {
    $ArchiveName = $ArchiveName + "-$($VersionInfo.pre_release)"
}
if ($VersionInfo.has_build_info) {
    $ArchiveName = $ArchiveName + "+$($BuildTimestamp)"
}
Write-Output "    Timestamp     : $($BuildTimestamp)"
Write-Output "    ArchiveName   : $($ArchiveName)"

# 输出目录

[string] $OutputRoot     = "$($BuildRoot)/archive_cache"
[string] $BundleOutput   = "$($OutputRoot)/$($ArchiveName)"
[string] $DocumentOutput = "$($BundleOutput)/document"
[string] $GameOutput     = "$($BundleOutput)/game"
[string] $GameModOutput  = "$($GameOutput)/mod"
[string] $ToolOutput     = "$($BundleOutput)/tools"
Write-Output "    OutputRoot    : $($OutputRoot)"
Write-Output "    BundleOutput  : $($BundleOutput)"
Write-Output "    DocumentOutput: $($DocumentOutput)"
Write-Output "    GameOutput    : $($GameOutput)"
Write-Output "    GameModOutput : $($GameModOutput)"
Write-Output "    ToolOutput    : $($ToolOutput)"

# 清理

Remove-Directory-If-Exist  -Path $OutputRoot

New-Directory-If-Not-Exist -Path $DocumentOutput
New-Directory-If-Not-Exist -Path $GameOutput
New-Directory-If-Not-Exist -Path $ToolOutput

#--------------------------------------------------------------------------------
# 复制文档

[string] $ReadmeAll = "使用说明（必读）.txt"
[string] $ReadmeMod = "模组安装说明（必读）.txt"

New-Directory-If-Not-Exist -Path $GameModOutput

Copy-Directory-And-Remove-Old -SourcePath "$($DocumentRoot)"               -TargetPath "$($DocumentOutput)"
Copy-File-And-Remove-Old      -SourcePath "$($ProjectRoot)/$($ReadmeAll)"  -TargetPath "$($BundleOutput)/$($ReadmeAll)"
Copy-File-And-Remove-Old      -SourcePath "$($GameModRoot)/$($ReadmeMod)"  -TargetPath "$($GameModOutput)/$($ReadmeMod)"

Remove-File-If-Exist -Path "$($DocumentOutput)/engine/.git"

#--------------------------------------------------------------------------------
# 复制工具

[string[]] $ToolNameList = @(
    '7z'
    'Fancy2D纹理字体生成器'
    'HGE粒子编辑器'
    'HGE纹理字体生成器'
    '半透明PNG边缘优化工具'
    'SimpleGifEncoder'
)

foreach ($ToolName in $ToolNameList) {
    Copy-Directory-And-Remove-Old -SourcePath "$($ToolRoot)/$($ToolName)" -TargetPath "$($ToolOutput)/$($ToolName)"
}

#--------------------------------------------------------------------------------
# 复制游戏引擎

[string[]] $EngineFileNameList = @(
    'LuaSTGSub.exe'
    'xaudio2_9redist.dll'
    'd3dcompiler_47.dll'
    'config.json'
)

foreach ($EngineFileName in $EngineFileNameList) {
    Copy-File-And-Remove-Old -SourcePath "$($GameRoot)/$($EngineFileName)" -TargetPath "$($GameOutput)/$($EngineFileName)"
}

#--------------------------------------------------------------------------------
# 复制包

[string[]] $PackageNameList = @(
    'thlib-resources'
    'thlib-scripts'
    'thlib-scripts-v2'
)

New-Directory-If-Not-Exist -Path "$($GameOutput)/packages"
foreach ($PackageName in $PackageNameList) {
    Copy-Directory-And-Remove-Old -SourcePath "$($GameRoot)/packages/$($PackageName)" -TargetPath "$($GameOutput)/packages/$($PackageName)"
    Remove-File-If-Exist -Path "$($GameOutput)/packages/$($PackageName)/.git"
}

[string[]] $PluginNameList = @(
    'ColliderShapeDebugger'
    'PlayerExtensions'
    'StageBackgroundExtensions'
    'thlib-legacy-bullet-definitions'
    'danmaku-recorder'
)

New-Directory-If-Not-Exist -Path "$($GameOutput)/plugins"
foreach ($PluginName in $PluginNameList) {
    Copy-Directory-And-Remove-Old -SourcePath "$($GameRoot)/plugins/$($PluginName)" -TargetPath "$($GameOutput)/plugins/$($PluginName)"
    Remove-File-If-Exist -Path "$($GameOutput)/plugins/$($PluginName)/.git"
}

#--------------------------------------------------------------------------------
# 自动生成版本信息

[string] $AutoConfig = Get-Content -Path "$($BuildRoot)/gconfig_auto.lua" -Raw

$AutoConfig = $AutoConfig -replace "{VERSION_MAJOR}", $VersionInfo.major
$AutoConfig = $AutoConfig -replace "{VERSION_MINOR}", $VersionInfo.minor
$AutoConfig = $AutoConfig -replace "{VERSION_PATCH}", $VersionInfo.patch
if ($VersionInfo.pre_release.Length -gt 0) {
    $AutoConfig = $AutoConfig -replace "{VERSION_PRE_RELEASE}", "-$($VersionInfo.pre_release)"
} else {
    $AutoConfig = $AutoConfig -replace "{VERSION_PRE_RELEASE}", ""
}
if ($VersionInfo.has_build_info) {
    $AutoConfig = $AutoConfig -replace "{VERSION_BUILD_TIMESTAMP}", "+$($BuildTimestamp)"
} else {
    $AutoConfig = $AutoConfig -replace "{VERSION_BUILD_TIMESTAMP}", ""
}
$AutoConfig = $AutoConfig -replace "{NAME}", $VersionInfo.short_name

Set-Content -Path "$($GameOutput)/packages/thlib-scripts/gconfig_auto.lua" -Value $AutoConfig

#--------------------------------------------------------------------------------
# 其他

# 创建空白存档文件夹

New-Directory-If-Not-Exist -Path "$($GameOutput)/userdata"

#--------------------------------------------------------------------------------
# 打包

[string] $ArchiveOutputFirectory = "$($BuildRoot)/output"
[string] $ArchiveOutputPath = "$($ArchiveOutputFirectory)/$($ArchiveName).zip"

New-Directory-If-Not-Exist -Path $ArchiveOutputFirectory

Set-Location -Path $OutputRoot
& $Zip a $ArchiveOutputPath .\ -tzip -mmt=on -mcu=on -mx9
Set-Location -Path $ProjectRoot

#--------------------------------------------------------------------------------
# 清理

Remove-Directory-If-Exist  -Path $OutputRoot
