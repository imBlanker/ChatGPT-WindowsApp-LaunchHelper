# SPDX-License-Identifier: LicenseRef-ChatGPT-WALH-NC-1.0
# Copyright (c) 2026 imBlanker
#Requires -Version 5.1
[CmdletBinding()]
param([switch]$SkipTests)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'ChatGPTLauncher.psm1') -Force
if (-not $SkipTests) {
    & (Join-Path $PSScriptRoot 'tests\Test-Launcher.ps1')
    & (Join-Path $PSScriptRoot 'tests\Test-ReleasePolicy.ps1')
}
& (Join-Path $PSScriptRoot 'scripts\Verify-Release.ps1')
$version = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'VERSION') -Raw).Trim()
if ($version -notmatch '^\d+\.\d+\.\d+(?:-[A-Za-z0-9.-]+)?$') { throw 'Invalid release version.' }
$payload = @(Get-LauncherPayloadFiles)
$sourceFiles = @($payload + @('build.ps1', 'tests/Test-Launcher.ps1', 'tests/Test-ReleasePolicy.ps1', '.gitignore', '.gitattributes', 'CONTEXT.md',
    'docs/adr/0001-branch-pr-tag-release.md', 'docs/adr/0002-noncommercial-license-and-language-versions.md',
    'scripts/ReleasePolicy.psm1', 'scripts/Get-ReleaseNotes.ps1', 'scripts/Verify-Release.ps1',
    '.github/workflows/ci.yml', '.github/workflows/release.yml')) | Select-Object -Unique
$identityDenylist = @([Environment]::GetEnvironmentVariable('USERNAME'), [Environment]::MachineName,
    [Environment]::GetFolderPath('UserProfile'), [IO.Path]::GetFullPath($PSScriptRoot)) |
    Where-Object { $_ -and $_.Length -ge 4 -and $_ -notin @('user', 'admin', 'administrator', 'runner', 'test', 'developer', 'imBlanker') }
$secretPattern = 'eyJ[A-Za-z0-9_-]{16,}\.[A-Za-z0-9_-]{16,}\.[A-Za-z0-9_-]{16,}|sk-(?:proj-)?[A-Za-z0-9_-]{24,}|-----BEGIN (?:[A-Z ]+ )?PRIVATE KEY-----'
foreach ($relative in $sourceFiles) {
    $path = Join-Path $PSScriptRoot $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw ('Missing public source file: ' + $relative) }
    if ((Get-Item -LiteralPath $path -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw ('Linked source file refused: ' + $relative) }
    $content = [IO.File]::ReadAllText($path)
    foreach ($identity in $identityDenylist) {
        if ($content.IndexOf($identity, [StringComparison]::OrdinalIgnoreCase) -ge 0) { throw ('Machine-specific content found in ' + $relative) }
    }
    if ($content -match $secretPattern) { throw ('Credential-like content found in ' + $relative) }
}
$dist = Join-Path $PSScriptRoot 'dist'
New-Item -ItemType Directory -Path $dist -Force | Out-Null
Add-Type -AssemblyName System.IO.Compression
function Write-AllowlistedArchive([string]$Name, [string[]]$Files) {
    $target = Join-Path $dist $Name
    $stream = [IO.File]::Open($target, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None)
    $archive = New-Object IO.Compression.ZipArchive($stream, [IO.Compression.ZipArchiveMode]::Create, $false)
    try {
        foreach ($relative in @($Files | Sort-Object)) {
            $entry = $archive.CreateEntry('ChatGPT-WindowsApp-LaunchHelper/' + $relative.Replace('\', '/'), [IO.Compression.CompressionLevel]::Optimal)
            # Fixed timestamps; ZIPs contain no filesystem owner or local absolute path metadata.
            $entry.LastWriteTime = [DateTimeOffset]::Parse('2026-01-01T00:00:00+00:00')
            $entryStream = $entry.Open()
            try {
                $bytes = [IO.File]::ReadAllBytes((Join-Path $PSScriptRoot $relative))
                $entryStream.Write($bytes, 0, $bytes.Length)
            } finally { $entryStream.Dispose() }
        }
    } finally { $archive.Dispose(); $stream.Dispose() }
    return $target
}
$runtimeArchive = Write-AllowlistedArchive ('ChatGPT-WindowsApp-LaunchHelper-' + $version + '-windows.zip') $payload
$sourceArchive = Write-AllowlistedArchive ('ChatGPT-WindowsApp-LaunchHelper-' + $version + '-source.zip') $sourceFiles
& (Join-Path $PSScriptRoot 'scripts\Get-ReleaseNotes.ps1') -Version $version -OutputPath (Join-Path $dist 'RELEASE-NOTES.md')
[pscustomobject]@{
    Version = $version
    License = 'LicenseRef-ChatGPT-WALH-NC-1.0'
    ReadmeLanguages = @('zh-Hans', 'zh-Hant', 'en')
    RuntimeFiles = $payload
    SourceFiles = $sourceFiles
    Packaging = 'Explicit file allowlists; no user directories copied'
    Checks = @('Machine identifiers absent', 'Credential-like strings absent', 'No application binaries', 'No personal config, logs, database or credential files')
} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $dist 'release-inventory.json') -Encoding UTF8
$checksums = foreach ($path in @($runtimeArchive, $sourceArchive, (Join-Path $dist 'release-inventory.json'), (Join-Path $dist 'RELEASE-NOTES.md'))) {
    (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() + '  ' + [IO.Path]::GetFileName($path)
}
$checksums | Set-Content -LiteralPath (Join-Path $dist 'SHA256SUMS.txt') -Encoding ASCII
Write-Host ('Release built: ' + [IO.Path]::GetFileName($runtimeArchive))
Write-Host ('Source built: ' + [IO.Path]::GetFileName($sourceArchive))
