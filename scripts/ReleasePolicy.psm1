# SPDX-License-Identifier: LicenseRef-ChatGPT-WALH-NC-1.0
# Copyright (c) 2026 imBlanker
#Requires -Version 5.1
Set-StrictMode -Version 2.0
function Get-VersionReleaseNotes {
    param([string]$ChangelogPath, [string]$Version)
    $text = [IO.File]::ReadAllText($ChangelogPath).Replace("`r`n", "`n")
    $pattern = '(?ms)^## \[' + [regex]::Escape($Version) + '\][^\n]*\n.*?(?=^## \[|\z)'
    $match = [regex]::Match($text, $pattern)
    if (-not $match.Success -or $match.Value -notmatch '(?m)^- ') { throw 'This version requires a nonempty changelog section.' }
    return $match.Value.Trim()
}
function Assert-ReadmeParity {
    param([string]$RepositoryRoot)
    $referenceCommands = ''; $referenceLinks = ''; $referenceHeadings = 0; $referenceMarker = ''
    foreach ($name in @('README.md', 'README.zh-Hant.md', 'README.en.md')) {
        $text = [IO.File]::ReadAllText((Join-Path $RepositoryRoot $name)).Replace("`r`n", "`n")
        $marker = [regex]::Match($text, '<!-- README-CONTENT-ID: ([^ ]+) -->').Value
        if (-not $marker) { throw ('Missing documentation sync marker: ' + $name) }
        $commands = (@([regex]::Matches($text, '(?s)```powershell\n(.*?)```') | ForEach-Object { $_.Groups[1].Value.Trim() })) -join "`n---`n"
        $links = (@([regex]::Matches($text, '\]\(([^)]+)\)') | ForEach-Object { $_.Groups[1].Value } | Sort-Object)) -join "`n"
        $headings = [regex]::Matches($text, '(?m)^## ').Count
        foreach ($term in @('LicenseRef-ChatGPT-WALH-NC-1.0', 'imBlanker', 'OpenAI', 'ARM64', 'SemVer', 'PAC/WPAD', '180')) {
            if (-not $text.Contains($term)) { throw ('Missing shared documentation fact in ' + $name) }
        }
        if ($name -eq 'README.md') { $referenceCommands = $commands; $referenceLinks = $links; $referenceHeadings = $headings; $referenceMarker = $marker }
        elseif ($commands -ne $referenceCommands -or $links -ne $referenceLinks -or $headings -ne $referenceHeadings -or $marker -ne $referenceMarker) { throw ('README language parity failed: ' + $name) }
    }
}
function Assert-AnnotatedReleaseTag {
    param([string]$RepositoryRoot, [string]$Tag, [string]$Version, [string]$Notes)
    if ($Tag -ne ('v' + $Version)) { throw 'Tag and VERSION differ.' }
    $type = & git -C $RepositoryRoot cat-file -t ('refs/tags/' + $Tag) 2>$null
    if ($LASTEXITCODE -ne 0 -or $type -ne 'tag') { throw 'An annotated tag is required; lightweight tags are not releases.' }
    $previousEncoding = [Console]::OutputEncoding
    [Console]::OutputEncoding = New-Object Text.UTF8Encoding($false)
    try { $tagContents = (& git -C $RepositoryRoot for-each-ref ('refs/tags/' + $Tag) '--format=%(contents)') -join "`n" }
    finally { [Console]::OutputEncoding = $previousEncoding }
    if (-not $tagContents.Replace("`r`n", "`n").Contains($Notes.Trim())) { throw 'Tag annotation must contain the complete version changelog.' }
    $commit = & git -C $RepositoryRoot rev-parse ('refs/tags/' + $Tag + '^{commit}')
    if ($LASTEXITCODE -ne 0) { throw 'Could not resolve the release commit.' }
    return $commit.Trim()
}
Export-ModuleMember -Function Get-VersionReleaseNotes, Assert-ReadmeParity, Assert-AnnotatedReleaseTag
