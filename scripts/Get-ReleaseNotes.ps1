# SPDX-License-Identifier: LicenseRef-ChatGPT-WALH-NC-1.0
# Copyright (c) 2026 imBlanker
#Requires -Version 5.1
param([string]$Version = '', [string]$OutputPath = '')
$ErrorActionPreference = 'Stop'
$repository = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $PSScriptRoot 'ReleasePolicy.psm1') -Force
if (-not $Version) { $Version = (Get-Content -LiteralPath (Join-Path $repository 'VERSION') -Raw).Trim() }
$notes = Get-VersionReleaseNotes -ChangelogPath (Join-Path $repository 'CHANGELOG.md') -Version $Version
if ($OutputPath) { [IO.File]::WriteAllText([IO.Path]::GetFullPath($OutputPath), $notes + "`n", (New-Object Text.UTF8Encoding($false))) }
else { Write-Output $notes }
