# SPDX-License-Identifier: LicenseRef-ChatGPT-WALH-NC-1.0
# Copyright (c) 2026 imBlanker
#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$InstallDirectory = (Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'ChatGPTStableLauncher\app'),
    [string]$ShortcutDirectory = ([Environment]::GetFolderPath('Programs')),
    [switch]$NoShortcut,
    [switch]$OverwriteModifiedFiles
)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'ChatGPTLauncher.psm1') -Force
$owner = 'chatgpt-stable-launcher'
$root = [IO.Path]::GetFullPath($InstallDirectory).TrimEnd('\', '/')
if (-not [IO.Path]::GetDirectoryName($root) -or $root -eq [IO.Path]::GetPathRoot($root).TrimEnd('\', '/') -or
    $root -in @([Environment]::GetFolderPath('UserProfile'), [Environment]::GetFolderPath('Windows'), [Environment]::GetFolderPath('LocalApplicationData'), [Environment]::GetFolderPath('Programs'))) {
    throw 'Choose a dedicated installation directory.'
}
$marker = Join-Path $root '.launcher-install.json'
$previous = $null
if (Test-Path -LiteralPath $marker) {
    $previous = Get-Content -LiteralPath $marker -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($previous.Owner -ne $owner) { throw 'This directory belongs to another application.' }
} elseif ((Test-Path -LiteralPath $root) -and @(Get-ChildItem -LiteralPath $root -Force).Count) {
    throw 'This directory is not empty and is not owned by the launcher.'
}
$shortcutPath = if ($NoShortcut) { '' } else { Join-Path ([IO.Path]::GetFullPath($ShortcutDirectory)) 'ChatGPT Stable Launcher.lnk' }
$shell = $null
if ($shortcutPath -and (Test-Path -LiteralPath $shortcutPath)) {
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    if ($shortcut.TargetPath -ne (Join-Path $root 'Start-ChatGPT.cmd')) { throw 'An unrelated shortcut has the same name; it was not overwritten.' }
}
$payload = @(Get-LauncherPayloadFiles)
foreach ($name in $payload) {
    $source = Join-Path $PSScriptRoot $name
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw ('Missing release file: ' + $name) }
    $destination = Join-Path $root $name
    if ($previous -and (Test-Path -LiteralPath $destination)) {
        $record = @($previous.Files | Where-Object { $_.Name -eq $name })
        if (-not $OverwriteModifiedFiles -and (-not $record.Count -or (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash -ne $record[0].SHA256)) {
            throw ('Installed file was modified and was preserved: ' + $name)
        }
    }
}
New-Item -ItemType Directory -Path $root -Force | Out-Null
$records = @()
foreach ($name in $payload) {
    $source = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot $name))
    $destination = Join-Path $root $name
    if ($source -ne $destination) { Copy-Item -LiteralPath $source -Destination $destination -Force }
    $records += [pscustomobject]@{ Name = $name; SHA256 = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash }
}
if ($shortcutPath) {
    New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($shortcutPath)) -Force | Out-Null
    if (-not $shell) { $shell = New-Object -ComObject WScript.Shell }
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = Join-Path $root 'Start-ChatGPT.cmd'
    $shortcut.WorkingDirectory = $root
    $shortcut.Description = 'ChatGPT Stable Launcher - manual launch only'
    $shortcut.Save()
}
[pscustomobject]@{ Owner = $owner; Version = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw).Trim(); Files = $records; Shortcut = $shortcutPath } |
    ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $marker -Encoding UTF8
Write-Host 'Installed for the current user. No startup item or scheduled task was created.'
Write-Host 'ChatGPT files, login credentials and system settings were not changed.'
