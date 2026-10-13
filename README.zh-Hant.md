# ChatGPT Windows App Launch Helper

[简体中文](README.md) · [繁體中文](README.zh-Hant.md) · [English](README.en.md)

<!-- README-CONTENT-ID: 1.0.0 -->

一個獨立、無圖形介面的 Windows 啟動輔助工具：先確認連線就緒，再開啟電腦上已經安裝的 ChatGPT 桌面版，讓介面和登入後端使用一致的代理。

**不包含 ChatGPT 本體、個人設定、憑證或歷史診斷資料；不新增開機啟動項。** 本專案不是 OpenAI 官方產品，採用要求署名、禁止商用的專案專用原始碼可用授權條款。

## 功能

- 自動偵測新版和 Classic，從套件資訊清單讀取實際執行檔；更新後重新偵測，不綁定使用者名稱、磁碟機代號、版本或 CPU 路徑。
- 跟隨 Windows 系統代理、指定 HTTP/HTTPS/SOCKS5 位址，或直接連線；相容網路層 VPN/TUN。
- 公開驗證探索端點連續兩次回應成功後啟動，預設最多等待 180 秒；失敗時保留現有憑證。
- 僅為新的應用程式處理程序設定代理，保留本機 OAuth 回呼繞過；不改系統代理或全域環境變數。
- 可選目前使用者安裝、開始功能表捷徑與可回復解除安裝；沒有啟動器圖形設定介面。

## 支援範圍

| 項目 | 支援情況 |
| --- | --- |
| 系統 | Windows 10/11，內建 Windows PowerShell 5.1 與 curl.exe |
| 應用程式 | OpenAI.Codex 新版、OpenAI.ChatGPT-Desktop Classic；其他位置可用 -ExePath |
| 架構 | 腳本不綁定 CPU；32 位元入口選擇原生系統工具 |
| 實測 | x64 上兩種應用程式偵測、連線和隔離測試已驗證；ARM64 未實機驗證 |

本工具不能讓官方應用程式執行於其本身不支援的系統。系統模式嘗試解析驗證端點的 PAC/WPAD 路由；複雜逐網域策略可能需要指定代理。SOCKS5 登入後端的可用性取決於桌面版本身。

## 快速使用

1. 自行安裝官方 ChatGPT Windows 桌面版。
2. 在 [Releases](https://github.com/imBlanker/ChatGPT-WindowsApp-LaunchHelper/releases) 下載 `ChatGPT-WindowsApp-LaunchHelper-<version>-windows.zip` 並完整解壓縮。
3. 按兩下 `Start-ChatGPT.cmd`；檢查時會出現短暫命令視窗，隨後開啟 ChatGPT。
4. 可選按兩下 `Install.cmd`，只為目前使用者新增 **ChatGPT Stable Launcher** 開始功能表入口，不替換原 ChatGPT 入口，不需要系統管理員權限。
5. 按兩下 `Uninstall.cmd` 移除工具；使用者修改的檔案、設定、日誌和 ChatGPT 保留。

## 設定與命令

將 `config.example.json` 複製為同目錄的 `config.json` 後按需填寫；範本路徑和代理位址為空。命令參數優先於設定檔。`-TimeoutSeconds` 控制等待時間，`-Quiet` 隱藏一般輸出，`-Language en` 選擇英文執行提示。

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

## 隱私與行為邊界

- 不讀取、複製、修改或上傳 ChatGPT 的權杖、Cookie、帳戶資訊或聊天紀錄。
- 不修改 Codex 設定、同步規則、系統代理、全域環境變數、開機項或排程工作。
- 本機日誌只包含時間、連線狀態、路由類別、應用程式類型、版本及處理程序編號，儲存於 `%LOCALAPPDATA%\ChatGPTStableLauncher\data`，不自動上傳。
- 安裝與打包均按明確檔案白名單操作，不帶入 `config.json`、憑證、舊診斷歷史、資料庫或 `.git`。
- 只在授權署名和 GitHub 提交中使用維護者公開身分 `imBlanker`，不發布本機使用者名稱或私人電子郵件地址。

## 已知限制

工具改善啟動連線時序與代理一致性，不承諾登入永不過期；伺服器故障、帳戶到期、組織策略、憑證限制和代理故障仍需處理。若 ChatGPT 已在背景執行，新啟動器無法改寫既有處理程序的代理；請從應用程式功能表**結束應用程式**後重試，不必按「登出」。

## 更新與發版

遵循 [ADR 0001](docs/adr/0001-branch-pr-tag-release.md)：新分支及 PR → 檢查和合併 → 含本版 changelog 的帶註解 tag → 含同一 changelog 的 Release。只發布從已合併 PR 對應提交建置的白名單附件。

軟體使用 SemVer，公開首版為 `1.0.0`；beta/rc 版本標記 prerelease，正式版本不帶該標記。語言版本是同一文件的翻譯；授權條款版本單獨為 `1.0`。詳情見 [RELEASING.md](RELEASING.md) 和 [ADR 0002](docs/adr/0002-noncommercial-license-and-language-versions.md)。

## 授權條款與許可

以英文 [LICENSE](LICENSE) 完整文字為準，識別碼為 `LicenseRef-ChatGPT-WALH-NC-1.0`：

- 允許非商業使用、學習、修改、借鑑受保護內容及再散布；分享或改編時，須保留著作權聲明、完整授權條款、原專案名稱、原作者 **imBlanker**、[原專案連結](https://github.com/imBlanker/ChatGPT-WindowsApp-LaunchHelper) 並說明實質變更。
- 不授予商用許可；商業產品或服務整合、出售及收費再散布需另行書面授權。僅個人訂閱付費 ChatGPT 不會自動使輔助工具的個人使用成為商用。
- OpenAI、其關聯實體及為其整合工作的受託方，若將受保護內容整合、隨附或改編到 ChatGPT Windows 桌面版或產品功能中，須事先聯絡 imBlanker 並取得明確書面同意，包括內部整合原型。一般個人執行獨立外部助手不等於官方產品整合。
- 不限制無需本授權條款許可的思想、方法、獨立實作或法定例外；不追溯改變其他授權條款有效授予的權利。此授權不符合 OSI 開源定義，準確分類是**原始碼可用**。

授權申請請透過 [GitHub Issue](https://github.com/imBlanker/ChatGPT-WindowsApp-LaunchHelper/issues/new) 聯絡；發出請求、引用專案或未獲回覆不代表同意。勿在公開 Issue 中提交私密資料。

## 驗證與建置

在原始碼包或倉庫目錄中執行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\build.ps1
```

建置執行離線迴歸測試、三語文件／發布說明檢查和隱私白名單檢查；`dist` 產生 Windows 腳本包、乾淨原始碼包、SHA-256 校驗和發布清單。不含桌面版本體；只有通用 Windows 腳本包，不宣稱提供未經實測的不同架構程式。

參考：[官方 Windows 部署](https://learn.chatgpt.com/docs/enterprise/windows-deployment)、[Electron 代理參數](https://www.electronjs.org/docs/latest/api/command-line-switches)。
