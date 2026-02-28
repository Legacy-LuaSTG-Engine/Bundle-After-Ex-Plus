$EngineVersion = "0.21.129"
$EngineReleaseUrl = "https://github.com/Legacy-LuaSTG-Engine/LuaSTG-Sub/releases/download/v$EngineVersion/LuaSTG-Sub-v$EngineVersion.zip"
$EngineReleaseDir = $PSScriptRoot + "/.engine"
$EngineReleaseArchiveFilePath = $EngineReleaseDir + "/LuaSTG-Sub-v$EngineVersion.zip"
$EngineReleaseArchiveFileHash = "82d1f8565a89b1e193814b2a50b96eda5bd8d1de494b45db210f57bed1970cf5"

function Get-EngineReleaseArchive {
    Write-Host "正在下载文件..."
    New-Item -Path $EngineReleaseDir -ItemType Directory -Force
    Invoke-WebRequest -Uri $EngineReleaseUrl -OutFile $EngineReleaseArchiveFilePath
    $FileHash = Get-FileHash -Path $EngineReleaseArchiveFilePath -Algorithm SHA256
    if ($EngineReleaseArchiveFileHash.ToUpper() -ne $FileHash.Hash.ToUpper()) {
        Write-Error "下载文件失败，校验值不匹配"
        exit 1
    }
}

if (-not (Test-Path -Path $EngineReleaseArchiveFilePath -PathType Leaf)) {
    Get-EngineReleaseArchive
} else {
    $FileHash = Get-FileHash -Path $EngineReleaseArchiveFilePath -Algorithm SHA256
    if ($EngineReleaseArchiveFileHash.ToUpper() -ne $FileHash.Hash.ToUpper()) {
        Remove-Item -Path $EngineReleaseArchiveFilePath
        Write-Warning ("缓存文件校验值不匹配，将重新下载：" + $EngineReleaseArchiveFilePath)
        Get-EngineReleaseArchive
    } else {
        Write-Host ("使用已缓存的文件：" + $EngineReleaseArchiveFilePath)
    }
}

$EngineDir = $EngineReleaseDir + "/LuaSTG-Sub-v$EngineVersion"

Write-Host "正在解压文件..."
Remove-Item -Path $EngineDir -Recurse -Force
Expand-Archive -Path $EngineReleaseArchiveFilePath -DestinationPath $EngineReleaseDir

Write-Host "正在替换引擎可执行文件..."

$GameDir = $PSScriptRoot + "/game"
$EngineExecutableManifest = @(
    [PSCustomObject]@{ Src = "$EngineDir/LuaSTGSub.exe"      ; Dst = "$GameDir/LuaSTGSub.exe"       }
    [PSCustomObject]@{ Src = "$EngineDir/d3dcompiler_47.dll" ; Dst = "$GameDir/d3dcompiler_47.dll"  }
    [PSCustomObject]@{ Src = "$EngineDir/xaudio2_9redist.dll"; Dst = "$GameDir/xaudio2_9redist.dll" }
)

foreach ($manifest in $EngineExecutableManifest) {
    Copy-Item -Path $manifest.Src -Destination $manifest.Dst -Force
}

Write-Host "正在替换引擎 API 文档..."

$DocPathSrc = "$EngineDir/doc"
$DocPathDst = "$PSScriptRoot/document/engine"

if (Test-Path -Path $DocPathDst -PathType Leaf) {
    Remove-Item -Path $DocPathDst -Recurse -Force
}
Copy-Item -Path $DocPathSrc -Destination $DocPathDst -Recurse
