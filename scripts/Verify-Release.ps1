# SPDX-License-Identifier: LicenseRef-ChatGPT-WALH-NC-1.0
# Copyright (c) 2026 imBlanker
#Requires -Version 5.1
param([string]$Tag = '', [switch]$RequireMergedPr)
$ErrorActionPreference = 'Stop'
$repository = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $PSScriptRoot 'ReleasePolicy.psm1') -Force
$version = (Get-Content -LiteralPath (Join-Path $repository 'VERSION') -Raw).Trim()
if ($version -notmatch '^\d+\.\d+\.\d+(?:-[A-Za-z0-9.-]+)?$') { throw 'Invalid software SemVer.' }
Assert-ReadmeParity $repository
$notes = Get-VersionReleaseNotes -ChangelogPath (Join-Path $repository 'CHANGELOG.md') -Version $version
$license = [regex]::Replace([IO.File]::ReadAllText((Join-Path $repository 'LICENSE')), '\s+', ' ')
foreach ($required in @('LicenseRef-ChatGPT-WALH-NC-1.0', 'No permission for Commercial Use', 'explicit written authorization', 'ChatGPT Windows desktop application')) {
    if (-not $license.Contains($required)) { throw 'The project license does not contain the required policy.' }
}
if ($Tag) {
    $commit = Assert-AnnotatedReleaseTag $repository $Tag $version $notes
    if ($RequireMergedPr) {
        & git -C $repository merge-base --is-ancestor $commit origin/main
        if ($LASTEXITCODE -ne 0) { throw 'Release commit is not on the default branch.' }
        $pulls = @((& gh api ('repos/imBlanker/ChatGPT-WindowsApp-LaunchHelper/commits/' + $commit + '/pulls') | ConvertFrom-Json))
        if ($LASTEXITCODE -ne 0) { throw 'Could not verify the associated PR.' }
        $merged = @($pulls | Where-Object { $_.merged_at -and $_.base.ref -eq 'main' -and $_.merge_commit_sha -eq $commit })
        if (-not $merged.Count) { throw 'The tag must point to the commit of a merged PR.' }
        Write-Host ('Merged PR verified: #' + $merged[0].number)
    }
    Write-Host ('Annotated tag verified: ' + $Tag)
}
Write-Host 'Three README languages, license policy and version changelog verified.'
