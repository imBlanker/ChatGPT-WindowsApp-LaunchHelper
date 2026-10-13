# 发版操作

基本规则以 [ADR 0001](docs/adr/0001-branch-pr-tag-release.md) 为准。

1. 从最新 main 建立 release/v<version> 或其他独立分支。软件、文档与许可变更必须经过该分支的 PR。
2. 更新 VERSION、CHANGELOG.md；核对三语 README 和需要调整的 ADR/LICENSE。运行 build.ps1 完成测试与隐私白名单打包。
3. 推送分支、创建 PR，审阅变更并等待检查通过。维护者或明确获授权的代理合并 PR；不直接把版本代码推到 main。
4. 同步 main，在对应 PR 的合并提交创建带注释 tag。软件采用 SemVer，首个正式版本为 v1.0.0；beta/rc 标记 prerelease。
5. tag 注释完整取自 CHANGELOG.md 的本版记录，示例：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\Get-ReleaseNotes.ps1 -OutputPath .\dist\RELEASE-NOTES.md
git tag -a v1.0.0 --cleanup=verbatim -F .\dist\RELEASE-NOTES.md
git push origin v1.0.0
```

6. Release 工作流验证该 tag 是带注释 tag、版本相符、注释包含本版 changelog，且提交属于 main 并对应已合并 PR；随后构建白名单附件并创建草稿 Release。正式版没有 prerelease 标记，预发布版有。

`--cleanup=verbatim` 保留 Markdown 标题；Git 默认注释清理可能删除以 `#` 开头的行，不能用于本流程的 changelog 注释。
7. 审阅草稿的源码、提交、文件清单和 SHA-256；Release 正文使用相同本版 changelog。添加实际 PR 链接和验证结果后发布。

可运行 scripts/Verify-Release.ps1 -Tag v1.0.0 -RequireMergedPr 手动重验；该联网检查使用 GitHub 认证，不能用无法核实的结果跳过检查。已发布 tag 不覆盖，修复通过新的分支、PR 和版本完成。

## 附件和隐私

只上传构建生成并在清单中列出的 Windows 脚本 ZIP、干净源码 ZIP、SHA256SUMS.txt、release-inventory.json 和 RELEASE-NOTES.md。不得把整个工作目录、ChatGPT 本体、私人 config.json、登录状态、日志、数据库、编辑器目录或 .git 上传。

工作流使用仓库提供的 GITHUB_TOKEN，不在代码里填写个人令牌。Git 提交使用维护者公开用户名及 GitHub noreply 地址，不发布私人邮箱。

源码采用根目录 LICENSE 所载的项目专用非商业署名许可。软件版本和许可条款版本独立编号；语言 README 是同内容翻译。授权要求及依据见 [ADR 0002](docs/adr/0002-noncommercial-license-and-language-versions.md)。
