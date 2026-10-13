# SPDX-License-Identifier: LicenseRef-ChatGPT-WALH-NC-1.0
# Copyright (c) 2026 imBlanker
#Requires -Version 5.1
Set-StrictMode -Version 2.0
$script:ProbeUrl = 'https://auth.openai.com/.well-known/openid-configuration'

function Get-LauncherText {
    param([string]$Chinese, [string]$English, [string]$Language = 'auto')
    if ($Language -eq 'zh' -or ($Language -eq 'auto' -and [Globalization.CultureInfo]::CurrentUICulture.Name -like 'zh*')) { return $Chinese }
    return $English
}

function Get-LauncherDataDirectory {
    return Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'ChatGPTStableLauncher\data'
}

function Write-LauncherLog {
    param([string]$Path, [string]$Message)
    if (-not $Path) { return }
    try {
        $directory = [IO.Path]::GetDirectoryName([IO.Path]::GetFullPath($Path))
        if (-not (Test-Path -LiteralPath $directory)) { New-Item -ItemType Directory -Path $directory -Force | Out-Null }
        if ((Test-Path -LiteralPath $Path) -and (Get-Item -LiteralPath $Path).Length -gt 1MB) {
            $previous = $Path + '.previous'
            if (Test-Path -LiteralPath $previous) { Remove-Item -LiteralPath $previous }
            Move-Item -LiteralPath $Path -Destination $previous
        }
        Add-Content -LiteralPath $Path -Value ((Get-Date -Format o) + ' ' + $Message) -Encoding UTF8
    } catch { }
}

function Get-NativeSystemTool {
    param([string]$RelativePath)
    $systemFolder = if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) { 'Sysnative' } else { 'System32' }
    return Join-Path (Join-Path ([Environment]::GetFolderPath('Windows')) $systemFolder) $RelativePath
}

function ConvertTo-NativeArgument {
    param([AllowEmptyString()][string]$Value)
    # Windows CommandLineToArgvW-compatible escaping; never pass values through cmd.exe.
    return '"' + [regex]::Replace([regex]::Replace($Value, '(\\*)"', '$1$1\"'), '(\\+)$', '$1$1') + '"'
}

function ConvertTo-ProxyUrl {
    param([string]$Address)
    if ([string]::IsNullOrWhiteSpace($Address)) { throw 'A proxy address is required.' }
    $value = $Address.Trim()
    if ($value -notmatch '^[A-Za-z][A-Za-z0-9+.-]*://') { $value = 'http://' + $value }
    $uri = $null
    if (-not [Uri]::TryCreate($value, [UriKind]::Absolute, [ref]$uri) -or
        $uri.Scheme -notin @('http', 'https', 'socks5', 'socks5h') -or -not $uri.Host -or
        $uri.UserInfo -or $uri.AbsolutePath -notin @('', '/') -or $uri.Query -or $uri.Fragment) {
        throw 'Use an HTTP, HTTPS or SOCKS5 proxy URL without a username, password or path.'
    }
    return $uri.GetLeftPart([UriPartial]::Authority)
}

function ConvertFrom-WindowsProxy {
    param([string]$ProxyServer)
    if (-not $ProxyServer) { return [pscustomobject]@{ Http = ''; Https = ''; Key = 'direct'; IsDirect = $true } }
    if ($ProxyServer.Contains('=')) {
        $map = @{}
        foreach ($part in $ProxyServer.Split(';')) {
            $pair = $part.Split('=', 2)
            if ($pair.Count -eq 2) { $map[$pair[0].Trim().ToLowerInvariant()] = $pair[1].Trim() }
        }
        $http = $map['http']; $https = $map['https']
        if (-not $http) { $http = $https }
        if (-not $https) { $https = $http }
        if (-not $https -and $map['socks']) { $http = $https = 'socks5h://' + $map['socks'] }
        if (-not $https) { throw 'The Windows proxy has no HTTP, HTTPS or SOCKS endpoint.' }
    } else { $http = $https = $ProxyServer.Trim() }
    $http = ConvertTo-ProxyUrl $http; $https = ConvertTo-ProxyUrl $https
    return [pscustomobject]@{ Http = $http; Https = $https; Key = $http + '|' + $https; IsDirect = $false }
}

function Get-LauncherProxy {
    param([ValidateSet('system', 'direct', 'custom')][string]$Mode = 'system', [string]$ProxyUrl = '')
    if ($Mode -eq 'direct') { return ConvertFrom-WindowsProxy '' }
    if ($Mode -eq 'custom') { return ConvertFrom-WindowsProxy (ConvertTo-ProxyUrl $ProxyUrl) }
    $settings = Get-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
    $autoConfig = $settings.PSObject.Properties['AutoConfigURL']
    $enabled = $settings.PSObject.Properties['ProxyEnable']
    $server = $settings.PSObject.Properties['ProxyServer']
    if ($enabled -and $enabled.Value -eq 1 -and $server -and (-not $autoConfig -or -not $autoConfig.Value)) {
        return ConvertFrom-WindowsProxy ([string]$server.Value)
    }
    # Resolve PAC/WPAD for the public authentication endpoint using Windows.
    $target = [Uri]$script:ProbeUrl
    $systemProxy = [Net.WebRequest]::GetSystemWebProxy()
    $resolved = $systemProxy.GetProxy($target)
    if (-not $resolved -or $resolved -eq $target -or $systemProxy.IsBypassed($target)) { return ConvertFrom-WindowsProxy '' }
    return ConvertFrom-WindowsProxy $resolved.AbsoluteUri
}

function Resolve-ChatGPTPackage {
    param($Package, [xml]$Manifest)
    $root = [IO.Path]::GetFullPath([string]$Package.InstallLocation).TrimEnd('\', '/')
    foreach ($application in @($Manifest.Package.Applications.Application)) {
        $relative = $application.GetAttribute('Executable')
        if (-not $relative -or [IO.Path]::GetFileName($relative) -notmatch '^(ChatGPT(?: Classic)?|Codex)\.exe$') { continue }
        $exe = [IO.Path]::GetFullPath((Join-Path $root $relative))
        if (-not $exe.StartsWith($root + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { continue }
        if (-not (Test-Path -LiteralPath $exe -PathType Leaf)) { continue }
        $kind = if ($Package.Name -match 'ChatGPT-Desktop') { 'classic' } else { 'modern' }
        return [pscustomobject]@{ Kind = $kind; Family = [string]$Package.PackageFamilyName; Version = [string]$Package.Version; Exe = $exe; AppId = $application.GetAttribute('Id') }
    }
}

function Get-ChatGPTApplications {
    # Current user only. Package names are generic; versions, usernames and CPU architectures are discovered.
    $applications = @()
    foreach ($package in @(Get-AppxPackage -ErrorAction Stop | Where-Object { -not $_.IsFramework -and $_.Name -match '^OpenAI\.(Codex|ChatGPT)' })) {
        try {
            $app = Resolve-ChatGPTPackage $package (Get-AppxPackageManifest -Package $package -ErrorAction Stop)
            if ($app) { $applications += $app }
        } catch { }
    }
    return $applications | Sort-Object @{ Expression = { if ($_.Kind -eq 'modern') { 0 } else { 1 } } }
}

function Select-ChatGPTApplication {
    param([ValidateSet('auto', 'modern', 'classic')][string]$App = 'auto', [string]$ExePath = '')
    if ($ExePath) {
        $exe = [IO.Path]::GetFullPath($ExePath)
        if (-not (Test-Path -LiteralPath $exe -PathType Leaf) -or [IO.Path]::GetExtension($exe) -ne '.exe') { throw 'The selected ChatGPT executable was not found.' }
        return [pscustomobject]@{ Kind = 'custom'; Family = ''; Version = ''; Exe = $exe; AppId = '' }
    }
    $apps = @(Get-ChatGPTApplications)
    if ($App -ne 'auto') { $apps = @($apps | Where-Object { $_.Kind -eq $App }) }
    if (-not $apps.Count) { throw 'No matching ChatGPT desktop app was found. Install the official app, or specify -ExePath.' }
    return $apps[0]
}

function Invoke-LauncherProbe {
    param($Route, [double]$LimitSeconds, [string]$ProbeUrl = $script:ProbeUrl)
    $curl = Get-NativeSystemTool 'curl.exe'
    if (-not (Test-Path -LiteralPath $curl)) { throw 'Windows curl.exe is required. Use an up-to-date Windows 10 or Windows 11 installation.' }
    $arguments = @('--silent', '--output', 'NUL', '--write-out', '%{http_code}', '--connect-timeout', '3',
        '--max-time', $LimitSeconds.ToString('0.###', [Globalization.CultureInfo]::InvariantCulture),
        '--noproxy', $(if ($Route.IsDirect) { '*' } else { 'localhost,127.0.0.1,::1' }))
    if (-not $Route.IsDirect) { $arguments += @('--proxy', $Route.Https) }
    $arguments += $ProbeUrl
    $start = New-Object Diagnostics.ProcessStartInfo
    $start.FileName = $curl
    $start.Arguments = ($arguments | ForEach-Object { ConvertTo-NativeArgument $_ }) -join ' '
    $start.UseShellExecute = $false; $start.CreateNoWindow = $true
    $start.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
    $start.RedirectStandardOutput = $true; $start.RedirectStandardError = $true
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $start
    try {
        [void]$process.Start()
        $stdout = $process.StandardOutput.ReadToEndAsync(); $stderr = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit([int]([Math]::Ceiling($LimitSeconds * 1000) + 500))) {
            try { $process.Kill() } catch { }
            return [pscustomobject]@{ Status = 0; ExitCode = 28; Ready = $false }
        }
        $code = $process.ExitCode
        $status = 0; [void][int]::TryParse($stdout.Result.Trim(), [ref]$status)
        # Never print curl stderr, proxy URLs, OAuth codes or command lines.
        return [pscustomobject]@{ Status = $status; ExitCode = $code; Ready = ($code -eq 0 -and $status -eq 200) }
    } finally { $process.Dispose() }
}

function Wait-LauncherConnection {
    param([scriptblock]$ResolveRoute, [double]$TimeoutSeconds = 180, [string]$LogPath = '', [switch]$Quiet,
        [scriptblock]$Probe = { param($Route, $Limit) Invoke-LauncherProbe $Route $Limit }, [double]$RetrySeconds = 1)
    $watch = [Diagnostics.Stopwatch]::StartNew()
    $consecutive = 0; $lastRoute = ''; $attempt = 0
    while ($watch.Elapsed.TotalSeconds -lt $TimeoutSeconds) {
        $route = & $ResolveRoute
        if ($route.Key -ne $lastRoute) { $consecutive = 0; $lastRoute = $route.Key }
        $remaining = $TimeoutSeconds - $watch.Elapsed.TotalSeconds
        if ($remaining -le 0) { break }
        $result = & $Probe $route ([Math]::Min(6, $remaining))
        if ($watch.Elapsed.TotalSeconds -ge $TimeoutSeconds) { break }
        $attempt++
        $message = 'probe=' + $attempt + ' route=' + $(if ($route.IsDirect) { 'direct' } else { 'proxy' }) + ' http=' + $result.Status + ' exit=' + $result.ExitCode
        Write-LauncherLog $LogPath $message
        if (-not $Quiet) { Write-Host $message }
        if ($result.Ready) { $consecutive++ } else { $consecutive = 0 }
        if ($consecutive -ge 2) { return $route }
        $remaining = $TimeoutSeconds - $watch.Elapsed.TotalSeconds
        if ($remaining -gt 0 -and $RetrySeconds -gt 0) { Start-Sleep -Milliseconds ([int]([Math]::Min($remaining, $RetrySeconds) * 1000)) }
    }
    throw 'The connection is not ready. Connect your network or proxy and try again. Existing login credentials are preserved.'
}

function Set-LauncherChildEnvironment {
    param([Collections.Specialized.StringDictionary]$Environment, $Route)
    $originalBypass = [string]$Environment['NO_PROXY']
    foreach ($key in @($Environment.Keys)) {
        if ($key.ToUpperInvariant() -in @('HTTP_PROXY', 'HTTPS_PROXY', 'ALL_PROXY', 'NO_PROXY')) { $Environment.Remove($key) }
    }
    if ($Route.IsDirect) { $Environment['NO_PROXY'] = '*' }
    else {
        $Environment['HTTP_PROXY'] = $Route.Http; $Environment['HTTPS_PROXY'] = $Route.Https
        $bypass = @('localhost', '127.0.0.1', '::1')
        if ($originalBypass -and $originalBypass -ne '*') { $bypass += $originalBypass }
        $Environment['NO_PROXY'] = $bypass -join ','
    }
}

function Start-LauncherApplication {
    param($Application, $Route)
    $start = New-Object Diagnostics.ProcessStartInfo
    $start.FileName = $Application.Exe; $start.WorkingDirectory = [IO.Path]::GetDirectoryName($Application.Exe)
    $start.UseShellExecute = $false
    Set-LauncherChildEnvironment $start.EnvironmentVariables $Route
    $arguments = @()
    if ($Route.IsDirect) { $arguments += '--no-proxy-server' }
    else {
        # Both official Windows variants use Electron. Keep browser requests and the login backend on the same route.
        $chromiumProxy = $Route.Https -replace '^socks5h:', 'socks5:'
        $arguments += '--proxy-server=' + $chromiumProxy
        $arguments += '--proxy-bypass-list=localhost;127.0.0.1;[::1]'
    }
    $start.Arguments = ($arguments | ForEach-Object { ConvertTo-NativeArgument $_ }) -join ' '
    $process = [Diagnostics.Process]::Start($start)
    try { return $process.Id } finally { $process.Dispose() }
}

function Get-LauncherPayloadFiles {
    return @('Start-ChatGPT.cmd', 'Start-ChatGPT.ps1', 'ChatGPTLauncher.psm1', 'Install.cmd', 'Install.ps1',
        'Uninstall.cmd', 'Uninstall.ps1', 'config.example.json', 'VERSION', 'README.md', 'README.zh-Hant.md', 'README.en.md', 'LICENSE', 'CHANGELOG.md', 'RELEASING.md')
}

Export-ModuleMember -Function Get-LauncherText, Get-LauncherDataDirectory, Write-LauncherLog, Get-NativeSystemTool,
    ConvertTo-NativeArgument, ConvertTo-ProxyUrl, ConvertFrom-WindowsProxy, Get-LauncherProxy, Resolve-ChatGPTPackage,
    Get-ChatGPTApplications, Select-ChatGPTApplication, Invoke-LauncherProbe, Wait-LauncherConnection,
    Set-LauncherChildEnvironment, Start-LauncherApplication, Get-LauncherPayloadFiles
