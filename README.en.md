# ChatGPT Windows App Launch Helper

[简体中文](README.md) · [繁體中文](README.zh-Hant.md) · [English](README.en.md)

<!-- README-CONTENT-ID: 1.0.0 -->

An independent, headless Windows launch helper: it waits for connectivity, then opens your already-installed ChatGPT desktop app with a consistent proxy route for the interface and login backend.

**No ChatGPT application, personal configuration, credentials or diagnostic history is bundled; no startup item is added.** This is not an official OpenAI product. It uses a project-specific source-available license requiring attribution and prohibiting commercial use.

## Features

- Detects modern and Classic apps from their package manifests; rediscovery after updates avoids fixed usernames, drives, versions or CPU-specific paths.
- Follows the Windows system proxy, accepts HTTP/HTTPS/SOCKS5 endpoints, or connects directly; network-level VPN/TUN routing also works.
- Starts after two consecutive successful responses from the public authentication discovery endpoint, waiting up to 180 seconds by default; failures preserve existing credentials.
- Sets the proxy only for the new application process and bypasses local OAuth callbacks; system proxy and global environment settings are unchanged.
- Optional current-user installation, Start menu shortcut and reversible uninstall; no graphical launcher settings window.

## Supported environments

| Item | Support |
| --- | --- |
| System | Windows 10/11 with built-in Windows PowerShell 5.1 and curl.exe |
| App | Modern OpenAI.Codex and OpenAI.ChatGPT-Desktop Classic; other locations use -ExePath |
| Architecture | Scripts have no fixed CPU target; a 32-bit entry selects native system tools |
| Tested | Both app detections, connectivity and isolated tests verified on x64; ARM64 not verified on physical hardware |

The helper cannot enable the official app on an otherwise unsupported system. System mode attempts PAC/WPAD resolution for the authentication endpoint; complex per-domain policies may need a custom proxy. Login-backend SOCKS5 support depends on the desktop app itself.

## Quick start

1. Separately install the official ChatGPT Windows desktop app.
2. Download `ChatGPT-WindowsApp-LaunchHelper-<version>-windows.zip` from [Releases](https://github.com/imBlanker/ChatGPT-WindowsApp-LaunchHelper/releases) and extract it completely.
3. Double-click `Start-ChatGPT.cmd`; a short-lived command window performs the checks and opens ChatGPT.
4. Optionally double-click `Install.cmd` to add **ChatGPT Stable Launcher** to the current user's Start menu; it does not replace the original ChatGPT entry or require administrator access.
5. Double-click `Uninstall.cmd` to remove the helper; modified files, user configuration, logs and ChatGPT are preserved.

## Configuration and commands

Copy `config.example.json` to `config.json` in the same directory and edit it as needed; template paths and proxy addresses are empty. Command parameters override configuration. `-TimeoutSeconds` sets the wait, `-Quiet` suppresses routine output, and `-Language en` selects English runtime messages.

```powershell
# Check connection only
powershell -NoProfile -ExecutionPolicy Bypass -File .\Start-ChatGPT.ps1 -CheckOnly
# List installed variants
powershell -NoProfile -ExecutionPolicy Bypass -File .\Start-ChatGPT.ps1 -ListApps
# Choose Classic
powershell -NoProfile -ExecutionPolicy Bypass -File .\Start-ChatGPT.ps1 -App classic
# Custom proxy (example address)
powershell -NoProfile -ExecutionPolicy Bypass -File .\Start-ChatGPT.ps1 -ProxyMode custom -ProxyUrl http://127.0.0.1:8080
# Direct connection / VPN / TUN
powershell -NoProfile -ExecutionPolicy Bypass -File .\Start-ChatGPT.ps1 -ProxyMode direct
# Nonstandard installation (replace the example path)
powershell -NoProfile -ExecutionPolicy Bypass -File .\Start-ChatGPT.ps1 -ExePath 'D:\Applications\ChatGPT\ChatGPT.exe'
```

## Privacy and behavior boundaries

- Does not read, copy, modify or upload ChatGPT tokens, cookies, account details or chat history.
- Does not modify Codex configuration, sync rules, system proxy, global environment variables, startup entries or scheduled tasks.
- Local logs contain only time, connectivity status, route category, app kind, version and process ID, stored in `%LOCALAPPDATA%\ChatGPTStableLauncher\data` and never uploaded automatically.
- Installation and packaging use explicit file allowlists, excluding `config.json`, credentials, old diagnostic history, databases and `.git`.
- Only the maintainer's explicitly public identity `imBlanker` is used for attribution and GitHub commits; no local username or private email is published.

## Known limitations

The helper improves startup timing and proxy consistency; it does not promise perpetual login. Server outages, account expiry, organization policy, certificate restrictions and proxy failures still need handling. If ChatGPT is already running in the background, a new launcher cannot change that process's proxy; **quit the application** through its menu and retry, without choosing Sign out.

## License and permission

The complete English [LICENSE](LICENSE) controls, identified as `LicenseRef-ChatGPT-WALH-NC-1.0`:

- Noncommercial use, study, modification, reuse of protected material and redistribution are allowed; when sharing or adapting, retain copyright notices, the complete license, original project name, original author **imBlanker**, [original project link](https://github.com/imBlanker/ChatGPT-WindowsApp-LaunchHelper), and a notice of material changes.
- Commercial permission is not granted; commercial product or service integration, sale and paid redistribution require separate written authorization. A personal paid ChatGPT subscription does not alone make personal use of the helper commercial.
- OpenAI, affiliated entities and integration contractors must first contact imBlanker and obtain explicit written consent before integrating, bundling or adapting protected material into the ChatGPT Windows desktop app or product features, including internal integration prototypes. An individual's separate external helper use is not official product integration.
- Ideas, methods, independent implementations and statutory exceptions that need no license permission remain unrestricted; valid rights granted under another license are not changed retroactively. This license is not OSI open source; its accurate category is **source-available**.

Request authorization through a [GitHub Issue](https://github.com/imBlanker/ChatGPT-WindowsApp-LaunchHelper/issues/new). A request, citation or unanswered message is not consent. Do not put private information in public issues.

## Verification and build

Run in the source archive or repository directory:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1
```

The build runs offline regression tests, three-language documentation/release-note checks and privacy allowlist checks. `dist` contains a Windows script archive, clean source archive, SHA-256 checksums and release inventory. No desktop app is included; only one general Windows script package is provided, without claiming separately tested architecture-specific programs.

References: [official Windows deployment](https://learn.chatgpt.com/docs/enterprise/windows-deployment), [Electron proxy switches](https://www.electronjs.org/docs/latest/api/command-line-switches).

---

## LINUX DO Community

Thanks to the [Linux.do](https://linux.do/) community for its support and contributions!
