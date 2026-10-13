---
status: accepted
date: 2026-10-13
---

# 通过分支、PR、带注释 tag 和 Release 发版

项目每次更新发版都先建立独立分支及对应 PR，再从通过检查并合入默认分支的提交建立带注释 tag，最后发布 GitHub Release。tag 注释与 Release 正文均必须包含本版本的 changelog，使审阅记录、源码版本和用户附件对应同一提交。

本决定将维护者的要求落实为长期基本规则：

> 在 https://github.com/imBlanker/ChatGPT-WindowsApp-LaunchHelper 发版，新建 branch 和其上的 PR，通过 tag + release 发版，tag 和 release 中都有 changelog 说明。

## 规则

1. 从最新 `main` 建立 `release/v<version>` 或目的明确的新分支；所有软件、文档和许可变更都经该分支的 PR 审阅与检查，禁止直接提交版本更新到 `main`。
2. PR 同时更新 `VERSION`、`CHANGELOG.md`、三语 README 及需要变更的 ADR/许可证；不影响某文件内容时无需制造无意义改动。三语 README 的功能、命令、限制、许可和发布说明必须一致。
3. 测试、文档一致性检查和发布包隐私检查通过后，由有权限的维护者或其明确授权的代理合入 PR。初次发布的空仓库可先建立一个**不含文件的空提交**作为 `main` 基线，只用于使分支和 PR 可创建。
4. 在 PR 的合并提交上创建 `v<version>` **带注释 tag**，完整注释取自 `CHANGELOG.md` 对应版本的内容；使用 `--cleanup=verbatim` 保留 Markdown 标题。允许在此基础上签名；不使用无说明的轻量 tag，不覆盖已发布 tag。
5. Release 使用同一 tag，正文包含同一 changelog；可补充 PR 链接、验证结果、已知限制和升级方式。先生成草稿，核对附件及提交后发布。工作流必须验证 tag 已在 `main` 历史中并且对应已合并 PR。
6. 只分发明确白名单中的 Windows 脚本包、源码包、SHA-256 校验文件、发布清单和本版发布说明。ChatGPT 本体、个人配置、凭据、诊断历史及 `.git` 不得进入附件。

## 版本种类

软件使用 SemVer：不兼容接口或行为变更提升 MAJOR，兼容新功能提升 MINOR，兼容修复提升 PATCH。首个公开、通过现有测试的功能版本为 `1.0.0`；候选版本可用 `1.1.0-beta.1`、`1.1.0-rc.1` 等并标记 GitHub prerelease，正式版本不带该标记。仅有验证脚本与通用 Windows 脚本包，不制造未经单独实测的架构安装包。

`LICENSE` 的条款版本单独编号；README 的简体中文、繁体中文和英文是同一文档的语言版本，不是不同功能版本。许可证选择见 [ADR 0002](0002-noncommercial-license-and-language-versions.md)。

## 取舍

比直接上传 ZIP 或在默认分支随手打 tag 多一步 PR 审阅，但能够明确谁审查了哪次变更、每个附件由哪个提交产生，避免无 changelog 的不可追溯发版。只有空仓库的无文件基线是初始化例外，不是绕过后续规则的入口。
