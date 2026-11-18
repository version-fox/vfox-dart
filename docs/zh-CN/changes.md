# 变更记录

[中文](changes.md) | [English](../changes.md)

按发布版本列出用户能感受到的变化。

## 未发布

- 渠道版本列表会读到最后一页。以前某个渠道列表中排在前 1000 项之后的版本会在 `vfox search` 和 `vfox install` 中悄悄缺失。目前没有版本缺失。
- 版本列表、渠道最新版本或校验和的请求失败时，现在会报告 HTTP 状态（例如 `get version failed: HTTP 503`）或传输错误，而不是出现 Lua 对 nil 拼接的错误。
- 不支持的架构的错误信息现在为 `dart does not support arm64 architecture`。

## 0.1.2（2026-11-17）

- 可用版本现在按数字版本号而非字符串顺序排序，`3.14.0` 会排在 `3.9.4` 之前。这也修复了通过 `Available` 解析 `@latest` 的 vfox 版本上的 `vfox install dart@latest`：现在按版本优先级取最高版本，而不是像 `3.9.4` 这样的字符串排序偶然结果。如需最新稳定版请使用 `dart@stable`。
- 完整的中英双语文档：英文和简体中文的 README（`README.md`、`README_CN.md`），以及 `docs/` 和 `docs/zh-CN/` 下的双语文档页面。
- 更新日志（即本页）。
- **Lint** 工作流里的 Lua 格式与静态检查：`stylua --check .` 和 `lua-language-server --check . --checklevel=Warning`。
- **License** 工作流里用 Apache SkyWalking Eyes 检查 Apache-2.0 许可证头（`.licenserc.yaml`、`.license.tpl`）。
- **Test Plugin** 工作流里由 `vfox plugin test .` 运行的离线钩子测试（`tests/*_test.lua`）。
- Linux 与 Windows 容器 E2E 测试套件（`tests/e2e/`）以及 **E2E** 工作流。
- 仓库基础设施：`stylua.toml`、`.luarc.json`、`.gitattributes`（所有检出使用 LF）、`.dockerignore`、`.github/actionlint.yaml`，以及 `opencode.jsonc`（让本仓库里的 OpenCode 智能体会话不必确认就能执行 `git push *`、`gh pr create *` 和 `gh pr comment *`）。
- 通过 `vfox link --detect dart` 发现本机已有的 Dart SDK（需要 vfox 1.1.0），包括 Flutter 自带的 SDK；详见 `docs/zh-CN/link.md`。
- 离线的 Detect 测试，以及 Linux 和 Windows E2E 套件里的检测检查。

## 0.1.1

- 维护版本。

## 0.1.0

- Dart 插件的首个版本：从 Dart 归档安装官方 Dart SDK，支持 `stable`、`dev` 和 `beta` 渠道以及确切版本号，支持 Linux、macOS 和 Windows 的 x64/ia32。
