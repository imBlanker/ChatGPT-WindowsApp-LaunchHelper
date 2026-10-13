# SPDX-License-Identifier: LicenseRef-ChatGPT-WALH-NC-1.0
# Copyright (c) 2026 imBlanker
#Requires -Version 5.1
[CmdletBinding()]
param(
    [ValidateSet('auto', 'modern', 'classic')][string]$App = 'auto',
    [string]$ExePath = '',
    [ValidateSet('system', 'direct', 'custom')][string]$ProxyMode = 'system',
    [string]$ProxyUrl = '',
    [ValidateRange(1, 600)][int]$TimeoutSeconds = 180,
    [string]$ConfigPath = '',
    [string]$LogPath = '',
    [ValidateSet('auto', 'zh', 'en')][string]$Language = 'auto',
    [switch]$CheckOnly,
    [switch]$ListApps,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'ChatGPTLauncher.psm1') -Force
$mutex = $null; $owned = $false
try {
    if (-not $ConfigPath) { $ConfigPath = Join-Path $PSScriptRoot 'config.json' }
    if (Test-Path -LiteralPath $ConfigPath) {
        $config = Get-Content -LiteralPath $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json
        foreach ($name in @('App', 'ExePath', 'ProxyMode', 'ProxyUrl', 'TimeoutSeconds', 'Language')) {
            if (-not $PSBoundParameters.ContainsKey($name) -and $config.PSObject.Properties[$name]) { Set-Variable -Name $name -Value $config.$name }
        }
    }
    if ($App -notin @('auto', 'modern', 'classic') -or $ProxyMode -notin @('system', 'direct', 'custom') -or
        $Language -notin @('auto', 'zh', 'en') -or $TimeoutSeconds -lt 1 -or $TimeoutSeconds -gt 600) { throw 'Invalid launcher configuration.' }
    if (-not $LogPath) { $LogPath = Join-Path (Get-LauncherDataDirectory) 'launcher.log' }
    if ($ListApps) {
        # Diagnostic output deliberately excludes machine-specific executable paths.
        ConvertTo-Json -InputObject @(Get-ChatGPTApplications | Select-Object Kind, Family, Version, AppId) -Compress
        exit 0
    }
    $sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    $mutex = New-Object Threading.Mutex($false, ('Local\ChatGPTStableLauncher.' + $sid))
    try { $owned = $mutex.WaitOne(0) } catch [Threading.AbandonedMutexException] { $owned = $true }
    if (-not $owned) {
        if (-not $Quiet) { Write-Host (Get-LauncherText '另一个启动器正在等待连接。' 'Another launcher is already waiting for the connection.' $Language) }
        exit 0
    }
    $application = $null
    if (-not $CheckOnly) { $application = Select-ChatGPTApplication -App $App -ExePath $ExePath }
    if (-not $Quiet) { Write-Host (Get-LauncherText '等待连接就绪…' 'Waiting for the connection…' $Language) }
    $route = Wait-LauncherConnection -ResolveRoute { Get-LauncherProxy -Mode $ProxyMode -ProxyUrl $ProxyUrl } -TimeoutSeconds $TimeoutSeconds -LogPath $LogPath -Quiet:$Quiet
    if ($CheckOnly) {
        if (-not $Quiet) { Write-Host (Get-LauncherText '连接检查通过，未启动 ChatGPT。' 'Connection check passed. ChatGPT was not started.' $Language) }
        exit 0
    }
    # Re-resolve after a long wait so app updates cannot leave a stale version path.
    $application = Select-ChatGPTApplication -App $App -ExePath $ExePath
    $running = @(Get-Process -Name ([IO.Path]::GetFileNameWithoutExtension($application.Exe)) -ErrorAction SilentlyContinue | Where-Object {
        try { $_.Path -eq $application.Exe } catch { $false }
    })
    $launchedPid = Start-LauncherApplication $application $route
    Write-LauncherLog $LogPath ('started kind=' + $application.Kind + ' version=' + $application.Version + ' pid=' + $launchedPid)
    if (-not $Quiet) {
        Write-Host (Get-LauncherText 'ChatGPT 已打开。' 'ChatGPT opened.' $Language)
        if ($running.Count) { Write-Host (Get-LauncherText '应用原来已在运行。若要应用新的代理设置，请从 ChatGPT 菜单完全退出后重试。' 'The app was already running. To apply new proxy settings, quit ChatGPT completely and retry.' $Language) }
    }
} catch {
    Write-LauncherLog $LogPath ('operation failed type=' + $_.Exception.GetType().Name)
    Write-Error $_.Exception.Message -ErrorAction Continue
    exit 1
} finally {
    if ($owned -and $mutex) { $mutex.ReleaseMutex() }
    if ($mutex) { $mutex.Dispose() }
}
