# SPDX-License-Identifier: LicenseRef-ChatGPT-WALH-NC-1.0
# Copyright (c) 2026 imBlanker
#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$repository = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $repository 'scripts\ReleasePolicy.psm1') -Force
Assert-ReadmeParity $repository
Write-Host 'PASS Three README language versions have identical commands, links and shared facts'
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('launch-helper-release-policy-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixture | Out-Null
try {
    $changelog = Join-Path $fixture 'CHANGELOG.md'
    $utf8 = New-Object Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($changelog, "# Changes`n`n## [1.0.0] - test`n`n- Current version change. 本版本变更。`n`n## [0.9.0] - test`n`n- Older version change.`n", $utf8)
    $notes = Get-VersionReleaseNotes $changelog '1.0.0'
    if ($notes -notmatch 'Current version change' -or $notes -match 'Older version change') { throw 'Version changelog extraction failed.' }
    Write-Host 'PASS Release notes contain exactly the selected version'
    $missingRejected = $false
    try { Get-VersionReleaseNotes $changelog '9.9.9' | Out-Null } catch { $missingRejected = $true }
    if (-not $missingRejected) { throw 'Missing changelog was accepted.' }
    Write-Host 'PASS Missing version changelog is rejected'
    & git -C $fixture init -q
    & git -C $fixture config user.name 'Release policy fixture'
    & git -C $fixture config user.email 'fixture@example.invalid'
    & git -C $fixture -c commit.gpgsign=false commit -q --allow-empty -m 'fixture'
    if ($LASTEXITCODE -ne 0) { throw 'Could not create tag policy fixture.' }
    & git -C $fixture -c tag.gpgsign=false tag v1.0.0
    $lightweightRejected = $false
    try { Assert-AnnotatedReleaseTag $fixture 'v1.0.0' '1.0.0' $notes | Out-Null } catch { $lightweightRejected = $true }
    if (-not $lightweightRejected) { throw 'Lightweight release tag was accepted.' }
    Write-Host 'PASS Lightweight tags cannot be released'
    & git -C $fixture tag -d v1.0.0 | Out-Null
    & git -C $fixture -c tag.gpgsign=false tag -a v1.0.0 -m 'Missing changelog'
    $emptyRejected = $false
    try { Assert-AnnotatedReleaseTag $fixture 'v1.0.0' '1.0.0' $notes | Out-Null } catch { $emptyRejected = $true }
    if (-not $emptyRejected) { throw 'Annotated tag without changelog was accepted.' }
    Write-Host 'PASS Annotated tags without their changelog cannot be released'
    & git -C $fixture tag -d v1.0.0 | Out-Null
    [IO.File]::WriteAllText((Join-Path $fixture 'notes.md'), $notes, $utf8)
    & git -C $fixture -c tag.gpgsign=false tag -a v1.0.0 --cleanup=verbatim -F (Join-Path $fixture 'notes.md')
    $commit = Assert-AnnotatedReleaseTag $fixture 'v1.0.0' '1.0.0' $notes
    if ($commit -notmatch '^[a-f0-9]{40}$') { throw 'A valid annotated tag did not resolve.' }
    Write-Host 'PASS Annotated tags with the exact changelog resolve to their commit'
} finally {
    $resolved = [IO.Path]::GetFullPath($fixture)
    $temporaryRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + [IO.Path]::DirectorySeparatorChar
    if ($resolved.StartsWith($temporaryRoot, [StringComparison]::OrdinalIgnoreCase) -and (Split-Path $resolved -Leaf) -like 'launch-helper-release-policy-*') {
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
