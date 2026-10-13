# Changelog

## [1.0.0] — 2026-10-13

### 新增 / Added

- 首个公开正式版本：无图形界面的 Windows 启动辅助工具，不包含 ChatGPT 桌面版本体。
- 自动识别新版与 Classic；基于包清单发现路径，支持手动路径、系统代理、自定义代理、直连及 VPN/TUN。
- 连续连接成功后启动，采用进程级代理与本机回调绕过；保留现有凭据，不创建开机项。
- 当前用户安装及所有权感知卸载；白名单 Windows/源码 ZIP、SHA-256 和发布清单。
- 同内容的简体中文、繁体中文和英文 README，以及忽略私人配置、凭据和构建产物的 .gitignore。
- ADR 0001 固定新分支 → PR → 合并 → 带注释 tag → Release，tag 与 Release 均携带本版 changelog。
- ADR 0002 记录许可证和语言版本选择；项目专用 LicenseRef-ChatGPT-WALH-NC-1.0 允许非商业编辑、引用与再分发，要求署名，商业使用需另行书面授权。
- OpenAI 及相关集成方将受保护内容用于 ChatGPT Windows 桌面版产品集成前，须联系 imBlanker 并取得明确书面同意。

### 验证 / Validation

- Windows PowerShell 5.1 离线回归套件、三语文档一致性、tag/changelog 策略和发布白名单隐私检查。
- x64 上实际检测新版/Classic，并以不含账号凭据的公开端点请求验证连接。

### 限制 / Limitations

- ARM64 尚未实机验证；工具不能保证账号永久有效，也不能绕过服务端、组织或证书策略。
- 无商用许可；这是源码可用许可证，不是 OSI 批准的开源许可证。
