# SPDX-License-Identifier: LicenseRef-ChatGPT-WALH-NC-1.0
# Copyright (c) 2026 imBlanker
#Requires -Version 5.1
[CmdletBinding()]
param([string]$InstallDirectory = (Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'ChatGPTStableLauncher\app'))
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath($InstallDirectory).TrimEnd('\', '/')
$marker = Join-Path $root '.launcher-install.json'
if (-not (Test-Path -LiteralPath $marker)) { throw 'No launcher-owned installation was found.' }
$state = Get-Content -LiteralPath $marker -Raw -Encoding UTF8 | ConvertFrom-Json
if ($state.Owner -ne 'chatgpt-stable-launcher') { throw 'The installation directory is not owned by this launcher.' }
$allowed = @('Start-ChatGPT.cmd', 'Start-ChatGPT.ps1', 'ChatGPTLauncher.psm1', 'Install.cmd', 'Install.ps1',
    'Uninstall.cmd', 'Uninstall.ps1', 'config.example.json', 'VERSION', 'README.md', 'README.zh-Hant.md', 'README.en.md', 'LICENSE', 'CHANGELOG.md', 'RELEASING.md')
foreach ($record in $state.Files) {
    if ($record.Name -notin $allowed -or [IO.Path]::GetFileName($record.Name) -ne $record.Name) { throw 'Unexpected file in the installation manifest.' }
    $target = [IO.Path]::GetFullPath((Join-Path $root $record.Name))
    if ([IO.Path]::GetDirectoryName($target) -ne $root) { throw 'Unexpected uninstall path.' }
    if (Test-Path -LiteralPath $target) {
        if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash -eq $record.SHA256) { Remove-Item -LiteralPath $target }
        else { Write-Host ('Preserved modified file: ' + $record.Name) }
    }
}
if ($state.Shortcut -and (Test-Path -LiteralPath $state.Shortcut)) {
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($state.Shortcut)
    if ($shortcut.TargetPath -eq (Join-Path $root 'Start-ChatGPT.cmd')) { Remove-Item -LiteralPath $state.Shortcut }
}
# Only remove the directory when it contains nothing but our ownership marker.
$remaining = @(Get-ChildItem -LiteralPath $root -Force | Where-Object { $_.Name -ne '.launcher-install.json' })
if (-not $remaining.Count) { Remove-Item -LiteralPath $marker; Remove-Item -LiteralPath $root }
Write-Host 'Launcher uninstalled. Modified files, user configuration, logs and ChatGPT were preserved.'
