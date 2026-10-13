---
status: accepted
date: 2026-10-13
---

# 非商业源码许可和同内容三语文档

维护者允许编辑、借鉴受保护内容及非商业再分发，要求引用原项目和作者，禁止商用，并保留 OpenAI 将受保护内容集成到 ChatGPT Windows 桌面版前须联系 imBlanker、取得明确书面同意的权利。我们采用原创项目专用 `LicenseRef-ChatGPT-WALH-NC-1.0`，不继续使用先前本地样包中的 MIT，也不将修改后的条款冒称为某个标准许可证。

## 许可证种类与范围

- MIT、BSD、Apache 和 GPL 都允许商业使用，不能满足本项目的禁止商用要求。
- CC BY-NC 4.0 表达了署名与非商业意图，但 Creative Commons [官方 FAQ](https://creativecommons.org/faq/#can-i-apply-a-creative-commons-license-to-software) 不建议把 CC 许可证用于软件；另外擅改 CC 条款后不能仍称其为官方 CC 许可证。
- 商业用途限制以及针对 OpenAI 集成的特别许可保留不满足 [OSI 开源定义](https://opensource.org/osd)，因此本仓库准确称为**源码可用 / source-available**，而非 OSI 意义上的开源软件。自定义标识使用 SPDX 的 `LicenseRef-` 形式。
- 完整、具有优先解释地位的文本放在根目录 `LICENSE`，许可证条款版本为 `1.0`；三语 README 仅提供同含义摘要。作者使用维护者明确要求的公开 GitHub 身份 `imBlanker`，不公布本机用户名、真实姓名或私人邮箱。
- 个人使用本辅助工具不会因为订阅了付费 ChatGPT 而自动成为本项目的商业使用。借鉴不受著作权保护的思想、方法或独立实现、法定例外不被错误声称纳入独占控制。此前按其他许可证授予的权利不追溯撤销。

## 文档种类

默认 `README.md` 为简体中文，`README.zh-Hant.md` 为繁体中文，`README.en.md` 为英文；使用文字系统与语言标识，而不是把繁体中文误限定为单一地区。三个版本拥有相同的功能、命令示例、支持范围、隐私边界、发版规则和许可条件，并互相链接。`.gitignore` 是全项目共享的配置文件，不制作语言版本；它忽略私人配置、凭据、日志、编辑器文件和构建产物，但保留可发布的空白配置模板。
