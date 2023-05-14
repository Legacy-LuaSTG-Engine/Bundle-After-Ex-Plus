# 自动化打包

Set-Location -Path $PSScriptRoot
[string] $WorkSpace = Get-Location
[string] $GameInput  = $WorkSpace + "\game"
[string] $GameOutput = $WorkSpace + "\build\game"
[string] $DocInput   = $WorkSpace + "\doc"
[string] $DocOutput  = $WorkSpace + "\build\doc"
[string] $BuildRoot  = $WorkSpace + "\build"
[string] $Zip        = $WorkSpace + "\7z.exe"

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
    Copy-Item -Path $SourcePath -Destination $TargetPath -Recurse
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
    Remove-File-If-Exist      -Path ($GamePath + "\imgui.ini" )
    Remove-Directory-If-Exist -Path ($GamePath + "\userdata"  )
}

# 打包过程

Remove-Directory-If-Exist  -Path $GameOutput
New-Directory-If-Not-Exist -Path $GameOutput
Copy-File-And-Remove-Old      -SourcePath ($GameInput + "\xaudio2_9redist.dll") -TargetPath ($GameOutput + "\xaudio2_9redist.dll")
Copy-File-And-Remove-Old      -SourcePath ($GameInput + "\d3dcompiler_47.dll" ) -TargetPath ($GameOutput + "\d3dcompiler_47.dll" )
Copy-File-And-Remove-Old      -SourcePath ($GameInput + "\LuaSTGSub.exe"      ) -TargetPath ($GameOutput + "\LuaSTGSub.exe"      )
Copy-File-And-Remove-Old      -SourcePath ($GameInput + "\launch"             ) -TargetPath ($GameOutput + "\launch"             )
Copy-Directory-And-Remove-Old -SourcePath ($GameInput + "\packages"           ) -TargetPath ($GameOutput + "\packages"           )
Copy-Directory-And-Remove-Old -SourcePath ($GameInput + "\plugins"            ) -TargetPath ($GameOutput + "\plugins"            )
Remove-File-If-Exist       -Path ($GameOutput + "\plugins\plugins.json"     )
Remove-Directory-If-Exist  -Path ($GameOutput + "\plugins\JyuSeoiJanPlayer")
New-Directory-If-Not-Exist -Path ($GameOutput + "\mod")
if ((Test-Path -Path ($DocInput + "\.git")) -eq $true) {
    Remove-Item -Path ($DocInput + "\.git") -Force
}
Copy-Directory-And-Remove-Old -SourcePath $DocInput                     -TargetPath $DocOutput
Copy-File-And-Remove-Old      -SourcePath ($WorkSpace + "\更新日志.txt") -TargetPath ($DocOutput + "\更新日志.txt")

Set-Location -Path $BuildRoot
Remove-File-If-Exist -Path ($WorkSpace + "\cache.zip")
& $Zip a ($WorkSpace + "\cache.zip") .\ -tzip -mmt=on -mcu=on -mx9
Set-Location -Path $WorkSpace
