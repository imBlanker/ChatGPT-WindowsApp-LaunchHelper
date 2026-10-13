# ChatGPT Windows App Launch Helper

[简体中文](README.md) · [繁體中文](README.zh-Hant.md) · [English](README.en.md)

<!-- README-CONTENT-ID: 1.0.0 -->

一个独立、无图形界面的 Windows 启动辅助工具：先确认连接就绪，再打开电脑上已经安装的 ChatGPT 桌面版，让界面和登录后台使用一致的代理。

**不包含 ChatGPT 本体、个人配置、凭据或历史诊断数据；不新增开机启动项。** 本项目不是 OpenAI 官方产品，采用要求署名、禁止商用的项目专用源码可用许可证。

## 功能

- 自动检测新版和 Classic，从包清单读取实际执行文件；更新后重新检测，不绑定用户名、盘符、版本或 CPU 路径。
- 跟随 Windows 系统代理、指定 HTTP/HTTPS/SOCKS5 地址，或直连；兼容网络层 VPN/TUN。
- 公开认证发现接口连续两次响应成功后启动，默认最多等待 180 秒；失败时保留现有凭据。
- 仅为新应用进程设置代理，保留本机 OAuth 回调绕过；不改系统代理或全局环境变量。
- 可选当前用户安装、开始菜单快捷方式与可回退卸载；没有启动器图形设置界面。

## 支持范围

| 项目 | 支持情况 |
| --- | --- |
| 系统 | Windows 10/11，自带 Windows PowerShell 5.1 与 curl.exe |
| 应用 | OpenAI.Codex 新版、OpenAI.ChatGPT-Desktop Classic；其他位置可用 -ExePath |
| 架构 | 脚本不绑定 CPU；32 位入口选择原生系统工具 |
| 实测 | x64 上两种应用检测、连接和隔离测试已验证；ARM64 未实机验证 |

本工具不能让官方应用运行在其自身不支持的系统上。系统模式尝试解析认证接口的 PAC/WPAD 路由；复杂逐域策略可能需要指定代理。SOCKS5 登录后台的可用性取决于桌面版本身。

## 快速使用

1. 自行安装官方 ChatGPT Windows 桌面版。
2. 在 [Releases](https://github.com/imBlanker/ChatGPT-WindowsApp-LaunchHelper/releases) 下载 `ChatGPT-WindowsApp-LaunchHelper-<version>-windows.zip` 并完整解压。
3. 双击 `Start-ChatGPT.cmd`；检查时会出现短暂命令窗口，随后打开 ChatGPT。
4. 可选双击 `Install.cmd`，只为当前用户添加 **ChatGPT Stable Launcher** 开始菜单入口，不替换原 ChatGPT 入口，不需要管理员权限。
5. 双击 `Uninstall.cmd` 移除工具；用户修改的文件、配置、日志和 ChatGPT 保留。

## 配置与命令

将 `config.example.json` 复制为同目录的 `config.json` 后按需填写；模板路径和代理地址为空。命令参数优先于配置文件。`-TimeoutSeconds` 控制等待时间，`-Quiet` 隐藏常规输出，`-Language en` 选择英文运行提示。

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

## 隐私与行为边界

- 不读取、复制、修改或上传 ChatGPT 的令牌、Cookie、账户信息或聊天记录。
- 不修改 Codex 配置、同步规则、系统代理、全局环境变量、开机项或计划任务。
- 本地日志只包含时间、连接状态、路由类别、应用类型、版本及进程号，保存在 `%LOCALAPPDATA%\ChatGPTStableLauncher\data`，不自动上传。
- 安装与打包均按明确文件白名单操作，不带入 `config.json`、凭据、旧诊断历史、数据库或 `.git`。
- 只在许可署名和 GitHub 提交中使用维护者公开身份 `imBlanker`，不发布本机用户名或私人邮箱。

## 已知限制

工具改善启动连接时序与代理一致性，不承诺登录永不过期；服务器故障、账户到期、组织策略、证书限制和代理故障仍需处理。若 ChatGPT 已在后台运行，新启动器无法改写既有进程的代理；请从应用菜单**退出应用**后重试，不必点击“退出登录”。

## 更新与发版

遵循 [ADR 0001](docs/adr/0001-branch-pr-tag-release.md)：新分支及 PR → 检查和合并 → 含本版 changelog 的带注释 tag → 含同一 changelog 的 Release。只发布从已合并 PR 对应提交构建的白名单附件。

软件使用 SemVer，公开首版为 `1.0.0`；beta/rc 版本标记 prerelease，正式版本不带该标记。语言版本是同一文档的翻译；许可证条款版本单独为 `1.0`。详情见 [RELEASING.md](RELEASING.md) 和 [ADR 0002](docs/adr/0002-noncommercial-license-and-language-versions.md)。

## 许可证与授权

以英文 [LICENSE](LICENSE) 完整文本为准，标识为 `LicenseRef-ChatGPT-WALH-NC-1.0`：

- 允许非商业使用、学习、修改、借鉴受保护内容及再分发；分享或改编时，须保留版权声明、完整许可证、原项目名称、原作者 **imBlanker**、[原项目链接](https://github.com/imBlanker/ChatGPT-WindowsApp-LaunchHelper) 并说明实质改动。
- 不授予商用许可；商业产品或服务集成、出售及收费再分发需另行书面授权。仅个人订阅付费 ChatGPT 不会自动使辅助工具的个人使用成为商用。
- OpenAI、其关联实体及为其集成工作的受托方，若将受保护内容集成、随附或改编到 ChatGPT Windows 桌面版或产品功能中，须事先联系 imBlanker 并获得明确书面同意，包括内部集成原型。普通个人运行独立外部助手不等于官方产品集成。
- 不限制无需本许可证授权的思想、方法、独立实现或法定例外；不追溯改变其他许可证有效授予的权利。该许可不符合 OSI 开源定义，准确分类是**源码可用**。

授权申请请通过 [GitHub Issue](https://github.com/imBlanker/ChatGPT-WindowsApp-LaunchHelper/issues/new) 联系；发出请求、引用项目或未获回复不代表同意。勿在公开 Issue 中提交私密资料。

## 验证与构建

在源码包或仓库目录中运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1
```

构建运行离线回归测试、三语文档/发布说明检查和隐私白名单检查；`dist` 生成 Windows 脚本包、干净源码包、SHA-256 校验和发布清单。不含桌面版本体；只有通用 Windows 脚本包，不声称提供未经实测的不同架构程序。

参考：[官方 Windows 部署](https://learn.chatgpt.com/docs/enterprise/windows-deployment)、[Electron 代理参数](https://www.electronjs.org/docs/latest/api/command-line-switches)。
