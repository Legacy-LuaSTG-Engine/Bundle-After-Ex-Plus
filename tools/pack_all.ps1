# 自动化打包

Set-Location -Path ($PSScriptRoot + "\..")
[string] $WorkSpace = Get-Location
[string] $GameInput  = $WorkSpace + "\game"
[string] $GameOutput = $WorkSpace + "\build\game"
[string] $DocInput   = $WorkSpace + "\document"
[string] $DocOutput  = $WorkSpace + "\build\document"
[string] $BuildRoot  = $WorkSpace + "\build"
[string] $ToolInput  = $WorkSpace + "\tools"
[string] $ToolOutput = $WorkSpace + "\build\tools"
[string] $Zip        = $WorkSpace + "\tools\7z\7z.exe"

# 版本信息

[string] $VersionJsonText = Get-Content -Path ($ToolInput + "\version.json") -Raw
$VersionInfo = ConvertFrom-Json $VersionJsonText
[string] $BuildTimestamp = "$(Get-Date -Format "yyyyMMddHHmmss")"
[string] $ArchiveName = "$($VersionInfo.name -replace " ", "-")-v$($VersionInfo.major).$($VersionInfo.minor).$($VersionInfo.patch)"
if ($VersionInfo.pre_release.Length -gt 0) {
    $ArchiveName = $ArchiveName + "-$($VersionInfo.pre_release)"
}
if ($VersionInfo.has_build_info) {
    $ArchiveName = $ArchiveName + "+$($BuildTimestamp)"
}
Write-Output "输出包名：$($ArchiveName)"

# 基础函数库

function New-Directory-If-Not-Exist {
    param (
        [string] $Path
    )
    [bool] $Exist = Test-Path -Path $Path
    if ($Exist -eq $false) {
        New-Item -Path $Path -ItemType Directory
    }
}

function Remove-File-If-Exist {
    param (
        [string] $Path
    )
    [bool] $Exist = Test-Path -Path $Path
    if ($Exist -eq $true) {
        Remove-Item -Path $Path
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

function Remove-Directory-If-Exist {
    param (
        [string] $Path
    )
    [bool] $Exist = Test-Path -Path $Path
    if ($Exist -eq $true) {
        Remove-Item -Path $Path -Recurse
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

function Copy-Directory-And-Remove-Old {
    param (
        [string] $SourcePath,
        [string] $TargetPath
    )
    Remove-Directory-If-Exist -Path $TargetPath
    Copy-Item -Path $SourcePath -Destination $TargetPath -Recurse -Exclude ".git"
}

function Rename-File-And-Remove-Old {
    param (
        [string] $SourcePath,
        [string] $TargetPath
    )
    Remove-File-If-Exist -Path $TargetPath
    Rename-Item -Path $SourcePath -NewName $TargetPath
}

function Remove-Game-UserData {
    param (
        [string] $GamePath
    )
    Remove-File-If-Exist      -Path ($GamePath + "\engine.log")
    Remove-Directory-If-Exist -Path ($GamePath + "\userdata"  )
}

# 打包过程

Write-Output ("当前工作目录：" + $WorkSpace)
Remove-Directory-If-Exist                                                       -Path       ($GameOutput)
New-Directory-If-Not-Exist                                                      -Path       ($GameOutput)
# 复制引擎
    Copy-File-And-Remove-Old      -SourcePath ($GameInput + "\xaudio2_9redist.dll") -TargetPath ($GameOutput + "\xaudio2_9redist.dll")
    Copy-File-And-Remove-Old      -SourcePath ($GameInput + "\d3dcompiler_47.dll" ) -TargetPath ($GameOutput + "\d3dcompiler_47.dll" )
    Copy-File-And-Remove-Old      -SourcePath ($GameInput + "\LuaSTGSub.exe"      ) -TargetPath ($GameOutput + "\LuaSTGSub.exe"      )
# 复制配置脚本
    Copy-File-And-Remove-Old      -SourcePath ($GameInput + "\launch"             ) -TargetPath ($GameOutput + "\launch"             )
    Copy-File-And-Remove-Old      -SourcePath ($GameInput + "\config.json"        ) -TargetPath ($GameOutput + "\config.json"        )
# 复制包
    New-Directory-If-Not-Exist                                                            -Path       ($GameOutput + "\packages"                 )
    Copy-Directory-And-Remove-Old -SourcePath ($GameInput + "\packages\thlib-resources" ) -TargetPath ($GameOutput + "\packages\thlib-resources" )
    Copy-Directory-And-Remove-Old -SourcePath ($GameInput + "\packages\thlib-scripts"   ) -TargetPath ($GameOutput + "\packages\thlib-scripts"   )
    Copy-Directory-And-Remove-Old -SourcePath ($GameInput + "\packages\thlib-scripts-v2") -TargetPath ($GameOutput + "\packages\thlib-scripts-v2")
# 生成内容
    $AutoConfig = Get-Content -Path ($ToolInput + "\gconfig_auto.lua") -Raw
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
    Set-Content -Path ($GameOutput + "\packages\thlib-scripts\gconfig_auto.lua") -Value $AutoConfig
# 复制插件
    New-Directory-If-Not-Exist                                                                          -Path       ($GameOutput + "\plugins"                                )
    Copy-Directory-And-Remove-Old -SourcePath ($GameInput + "\plugins\ColliderShapeDebugger"          ) -TargetPath ($GameOutput + "\plugins\ColliderShapeDebugger"          )
    Copy-Directory-And-Remove-Old -SourcePath ($GameInput + "\plugins\PlayerExtensions"               ) -TargetPath ($GameOutput + "\plugins\PlayerExtensions"               )
    Copy-Directory-And-Remove-Old -SourcePath ($GameInput + "\plugins\StageBackgroundExtensions"      ) -TargetPath ($GameOutput + "\plugins\StageBackgroundExtensions"      )
    Copy-Directory-And-Remove-Old -SourcePath ($GameInput + "\plugins\thlib-legacy-bullet-definitions") -TargetPath ($GameOutput + "\plugins\thlib-legacy-bullet-definitions")
# 创建空白文件夹
    New-Directory-If-Not-Exist                                                      -Path       ($GameOutput + "\mod")
    New-Directory-If-Not-Exist                                                      -Path       ($GameOutput + "\userdata")
# 复制文档
    Remove-Directory-If-Exist                                                       -Path       ($DocOutput)
    Copy-Directory-And-Remove-Old -SourcePath ($DocInput)                           -TargetPath ($DocOutput)
    Copy-File-And-Remove-Old      -SourcePath ($WorkSpace + "\使用说明（必读）.txt")          -TargetPath ($BuildRoot + "\使用说明（必读）.txt")
    Copy-File-And-Remove-Old      -SourcePath ($GameInput + "\mod\模组安装说明（必读）.txt")  -TargetPath ($GameOutput + "\mod\模组安装说明（必读）.txt")
    #Remove-File-Force                                                               -Path       ($DocOutput + "\.git")
# 工具
    Remove-Directory-If-Exist                                                       -Path       ($ToolOutput)
    Copy-Directory-And-Remove-Old -SourcePath ($ToolInput)                          -TargetPath ($ToolOutput)
    Remove-File-If-Exist                                                            -Path       ($ToolOutput + "\pack_all.ps1")
    Remove-File-If-Exist                                                            -Path       ($ToolOutput + "\HGE粒子编辑器\particleed.log")
    Remove-File-If-Exist                                                            -Path       ($ToolOutput + "\HGE纹理字体生成器\fonted.log")
    #Remove-File-If-Exist                                                            -Path       ($ToolOutput + "\外部设置工具\config.json")
    Remove-Directory-If-Exist                                                       -Path       ($ToolOutput + "\外部设置工具")
# 打包
    Remove-File-If-Exist -Path $ArchivePath
    Set-Location -Path $BuildRoot
    $ArchivePath = "$($WorkSpace)\$($ArchiveName).zip"
    & $Zip a $ArchivePath .\ -tzip -mmt=on -mcu=on -mx9
    Set-Location -Path $WorkSpace
