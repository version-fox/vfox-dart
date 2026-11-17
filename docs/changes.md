# Changes

[中文](zh-CN/changes.md) | [English](changes.md)

What changed in each release, as a user notices it.

## Unreleased

- Full bilingual documentation: English and Simplified Chinese READMEs (`README.md`, `README_CN.md`) plus documentation pages in both languages under `docs/` and `docs/zh-CN/`.
- A changelog (this page).
- Lua lint and format checks in the **Lint** workflow: `stylua --check .` and `lua-language-server --check . --checklevel=Warning`.
- Apache-2.0 license header checks with Apache SkyWalking Eyes (`.licenserc.yaml`, `.license.tpl`) in the **License** workflow.
- Offline hook tests (`tests/*_test.lua`) run by `vfox plugin test .` in the **Test Plugin** workflow.
- Linux and Windows container E2E suites (`tests/e2e/`) and the **E2E** workflow.
- Repository infrastructure: `stylua.toml`, `.luarc.json`, `.gitattributes` (LF on all checkouts), `.dockerignore`, `.github/actionlint.yaml`, and `opencode.jsonc` (lets OpenCode agent sessions run `git push *`, `gh pr create *` and `gh pr comment *` without asking).
- Detect Dart SDKs already on the machine through `vfox link --detect dart` (needs vfox 1.1.0), including Flutter's bundled SDK; `docs/link.md` documents it.
- Offline Detect tests and detection checks in the Linux and Windows E2E suites.

## 0.1.1

- Maintenance release.

## 0.1.0

- First release of the Dart plugin: installs the official Dart SDK from the Dart archive for the `stable`, `dev` and `beta` channels and for exact versions, on Linux, macOS and Windows x64/ia32.
