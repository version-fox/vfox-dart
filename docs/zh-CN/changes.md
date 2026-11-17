# 变更记录

[中文](changes.md) | [English](../changes.md)

按发布版本列出用户能感受到的变化。

## 未发布

- 完整的中英双语文档：英文和简体中文的 README（`README.md`、`README_CN.md`），以及 `docs/` 和 `docs/zh-CN/` 下的双语文档页面。
- 更新日志（即本页）。
- **Lint** 工作流里的 Lua 格式与静态检查：`stylua --check .` 和 `lua-language-server --check . --checklevel=Warning`。
- **License** 工作流里用 Apache SkyWalking Eyes 检查 Apache-2.0 许可证头（`.licenserc.yaml`、`.license.tpl`）。
- **Test Plugin** 工作流里由 `vfox plugin test .` 运行的离线钩子测试（`tests/*_test.lua`）。
- Linux 与 Windows 容器 E2E 测试套件（`tests/e2e/`）以及 **E2E** 工作流。
- 仓库基础设施：`stylua.toml`、`.luarc.json`、`.gitattributes`（所有检出使用 LF）、`.dockerignore`、`.github/actionlint.yaml`，以及 `opencode.jsonc`（让本仓库里的 OpenCode 智能体会话不必确认就能执行 `git push *`、`gh pr create *` 和 `gh pr comment *`）。

## 0.1.1

- 维护版本。

## 0.1.0

- Dart 插件的首个版本：从 Dart 归档安装官方 Dart SDK，支持 `stable`、`dev` 和 `beta` 渠道以及确切版本号，支持 Linux、macOS 和 Windows 的 x64/ia32。
