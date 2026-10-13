# SPDX-License-Identifier: LicenseRef-ChatGPT-WALH-NC-1.0
# Copyright (c) 2026 imBlanker
#Requires -Version 5.1
param()
$ErrorActionPreference = 'Stop'
$project = Split-Path $PSScriptRoot -Parent
Import-Module (Join-Path $project 'ChatGPTLauncher.psm1') -Force
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('chatgpt-launcher-tests-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixture | Out-Null
$script:passed = 0
function Assert-True([bool]$Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
function Run-Test([string]$Name, [scriptblock]$Body) { & $Body; $script:passed++; Write-Host ('PASS ' + $Name) }
try {
    Run-Test 'All PowerShell source parses on the built-in host' {
        foreach ($file in @(Get-ChildItem -LiteralPath $project -File -Recurse | Where-Object { $_.Extension -in @('.ps1', '.psm1') -and $_.FullName -notmatch '[\\/]dist[\\/]' })) {
            $tokens = $null; $errors = $null
            [Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors) | Out-Null
            Assert-True (-not $errors.Count) ('Parser error in ' + $file.Name)
        }
    }
    Run-Test 'Proxy protocol map, IPv6 and SOCKS' {
        $route = ConvertFrom-WindowsProxy 'https=[::1]:8802;http=127.0.0.1:8801'
        $ipv6 = [Uri]$route.Https
        Assert-True ($route.Http -eq 'http://127.0.0.1:8801' -and $ipv6.Port -eq 8802 -and
            [Net.IPAddress]::Parse($ipv6.Host.Trim('[', ']')).Equals([Net.IPAddress]::IPv6Loopback)) 'Incorrect proxy map.'
        Assert-True ((ConvertTo-ProxyUrl 'socks5h://localhost:1080') -eq 'socks5h://localhost:1080') 'SOCKS URL changed.'
    }
    Run-Test 'Credential-bearing and malformed proxy URLs rejected' {
        foreach ($value in @('file:///tmp/x', 'http://user:password@localhost:1234', 'http://localhost:1234/path')) {
            $rejected = $false; try { ConvertTo-ProxyUrl $value | Out-Null } catch { $rejected = $true }
            Assert-True $rejected 'Invalid proxy URL was accepted.'
        }
    }
    Run-Test 'Both package layouts resolve using a Unicode path with spaces' {
        $root = Join-Path $fixture "example 用户's directory"
        New-Item -ItemType Directory -Path (Join-Path $root 'app') -Force | Out-Null
        foreach ($variant in @(@('OpenAI.Codex', 'ChatGPT.exe', 'modern'), @('OpenAI.ChatGPT-Desktop', 'ChatGPT Classic.exe', 'classic'))) {
            Set-Content -LiteralPath (Join-Path $root ('app\' + $variant[1])) -Value 'fixture'
            $package = [pscustomobject]@{ Name = $variant[0]; InstallLocation = $root; PackageFamilyName = 'fixture'; Version = '9.9.9' }
            [xml]$manifest = '<Package><Applications><Application Id="App" Executable="app\' + $variant[1] + '" /></Applications></Package>'
            $resolved = Resolve-ChatGPTPackage $package $manifest
            Assert-True ($resolved.Kind -eq $variant[2] -and (Test-Path -LiteralPath $resolved.Exe)) 'Package executable not resolved.'
        }
    }
    Run-Test 'Manifest path traversal is rejected' {
        $root = Join-Path $fixture 'package'; New-Item -ItemType Directory -Path $root -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $fixture 'ChatGPT.exe') -Value 'outside'
        $package = [pscustomobject]@{ Name = 'OpenAI.Codex'; InstallLocation = $root; PackageFamilyName = 'fixture'; Version = '1' }
        [xml]$manifest = '<Package><Applications><Application Id="App" Executable="..\ChatGPT.exe" /></Applications></Package>'
        Assert-True (-not (Resolve-ChatGPTPackage $package $manifest)) 'Manifest escaped package directory.'
    }
    Run-Test 'Transient failure requires two fresh consecutive successes' {
        $state = @{ Calls = 0; Statuses = @(503, 200, 503, 200, 200) }
        $probe = { param($route, $limit) $status = $state.Statuses[$state.Calls]; $state.Calls++; [pscustomobject]@{ Status = $status; ExitCode = 0; Ready = ($status -eq 200) } }.GetNewClosure()
        Wait-LauncherConnection -ResolveRoute { ConvertFrom-WindowsProxy '' } -Probe $probe -TimeoutSeconds 2 -RetrySeconds 0 -Quiet | Out-Null
        Assert-True ($state.Calls -eq 5) 'Accepted an isolated response.'
    }
    Run-Test 'Proxy change resets readiness' {
        $state = @{ Resolutions = 0; Calls = 0 }
        $resolver = { $state.Resolutions++; if ($state.Resolutions -eq 1) { ConvertFrom-WindowsProxy '' } else { ConvertFrom-WindowsProxy 'localhost:8080' } }.GetNewClosure()
        $probe = { param($route, $limit) $state.Calls++; [pscustomobject]@{ Status = 200; ExitCode = 0; Ready = $true } }.GetNewClosure()
        Wait-LauncherConnection -ResolveRoute $resolver -Probe $probe -TimeoutSeconds 2 -RetrySeconds 0 -Quiet | Out-Null
        Assert-True ($state.Calls -eq 3) 'Mixed two proxy routes.'
    }
    Run-Test 'Unavailable connection times out and preserves a credential fixture' {
        $credentialFixture = Join-Path $fixture 'auth.json'; Set-Content -LiteralPath $credentialFixture -Value 'synthetic test data, not a credential'
        $before = (Get-FileHash -LiteralPath $credentialFixture).Hash
        $probe = { param($route, $limit) [pscustomobject]@{ Status = 0; ExitCode = 7; Ready = $false } }
        $failed = $false
        try { Wait-LauncherConnection -ResolveRoute { ConvertFrom-WindowsProxy '' } -Probe $probe -TimeoutSeconds 0.1 -RetrySeconds 0.01 -Quiet | Out-Null } catch { $failed = $true }
        Assert-True ($failed -and (Get-FileHash -LiteralPath $credentialFixture).Hash -eq $before) 'Timeout altered the fixture.'
    }
    Run-Test 'Proxy settings affect only the child environment; direct really bypasses proxies' {
        $start = New-Object Diagnostics.ProcessStartInfo
        $start.EnvironmentVariables['ALL_PROXY'] = 'http://old.invalid:1'; $start.EnvironmentVariables['NO_PROXY'] = '*'
        $parentValue = [Environment]::GetEnvironmentVariable('HTTPS_PROXY', 'Process')
        Set-LauncherChildEnvironment $start.EnvironmentVariables (ConvertFrom-WindowsProxy 'localhost:8080')
        Assert-True ($start.EnvironmentVariables['HTTPS_PROXY'] -eq 'http://localhost:8080' -and -not $start.EnvironmentVariables.ContainsKey('ALL_PROXY') -and $start.EnvironmentVariables['NO_PROXY'] -ne '*') 'Stale inherited route survived.'
        Set-LauncherChildEnvironment $start.EnvironmentVariables (ConvertFrom-WindowsProxy '')
        Assert-True ($start.EnvironmentVariables['NO_PROXY'] -eq '*' -and -not $start.EnvironmentVariables.ContainsKey('HTTPS_PROXY')) 'Direct mode still used an explicit proxy.'
        Assert-True ([Environment]::GetEnvironmentVariable('HTTPS_PROXY', 'Process') -eq $parentValue) 'Changed the parent environment.'
    }
    Run-Test 'Install/uninstall roundtrip keeps custom user files' {
        $root = Join-Path $fixture 'install'; $programs = Join-Path $fixture 'programs'
        & (Join-Path $project 'Install.ps1') -InstallDirectory $root -ShortcutDirectory $programs
        $custom = Join-Path $root 'config.json'; Set-Content -LiteralPath $custom -Value '{"TimeoutSeconds":42}'
        & (Join-Path $project 'Uninstall.ps1') -InstallDirectory $root
        Assert-True ((Test-Path -LiteralPath $custom) -and -not (Test-Path -LiteralPath (Join-Path $root 'Start-ChatGPT.ps1')) -and
            -not (Test-Path -LiteralPath (Join-Path $programs 'ChatGPT Stable Launcher.lnk'))) 'Uninstall removed custom data or left its shortcut.'
    }
    Run-Test 'An unrelated shortcut cannot be overwritten' {
        $root = Join-Path $fixture 'second-install'; $programs = Join-Path $fixture 'foreign-programs'
        New-Item -ItemType Directory -Path $programs -Force | Out-Null
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut((Join-Path $programs 'ChatGPT Stable Launcher.lnk'))
        $shortcut.TargetPath = Join-Path $fixture 'unrelated.exe'; $shortcut.Save()
        $failed = $false; try { & (Join-Path $project 'Install.ps1') -InstallDirectory $root -ShortcutDirectory $programs } catch { $failed = $true }
        Assert-True ($failed -and -not (Test-Path -LiteralPath $root)) 'Overwrote an unrelated shortcut.'
    }
    Write-Host ('Passed ' + $script:passed + ' offline tests.')
} finally {
    $resolved = [IO.Path]::GetFullPath($fixture)
    $temporaryRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + [IO.Path]::DirectorySeparatorChar
    if ($resolved.StartsWith($temporaryRoot, [StringComparison]::OrdinalIgnoreCase) -and (Split-Path $resolved -Leaf) -like 'chatgpt-launcher-tests-*') {
        Remove-Item -LiteralPath $resolved -Recurse -Force
    }
}
