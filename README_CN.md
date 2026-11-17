# vfox-dart

[中文](README_CN.md) | [English](README.md)

[vfox](https://vfox.dev/) 的 Dart 插件。它从 Google 的 [Dart SDK 官方归档](https://storage.googleapis.com/dart-archive/)安装官方 Dart SDK，并为你当前的 Shell 选中它，让 `dart` 和 `dartaotruntime` 出现在 `PATH` 里。

## 安装

先安装 [vfox](https://github.com/version-fox/vfox)，然后添加插件，安装并选中一个 SDK：

```bash
vfox add dart
vfox install dart@stable
vfox use --global dart@stable
dart --version
```

`dart --version` 会显示当前选中的 SDK。要让 `dart` 出现在 `PATH` 里，需要先把 vfox 挂载到你的 Shell，见[快速入门](https://vfox.dev/zh-hans/guides/quick-start.html)。插件只设置 `PATH`（指向 `<安装根目录>/bin`），不设置其他环境变量。

## 版本与渠道

共有三个发布渠道：`stable`、`dev` 和 `beta`。写渠道名会安装该渠道上最新的版本：

```bash
vfox install dart@stable      # 最新的 stable，3.14.0，发布于 2026-11-04
vfox install dart@dev         # 最新的 dev 构建
vfox install dart@beta        # 最新的 beta 构建
```

也可以直接写确切版本号，`use` 同样接受这些写法：

```bash
vfox install dart@3.14.0
vfox use --global dart@3.14.0
vfox current dart             # 当前作用域选中的版本
vfox list dart                # 已安装的 SDK
vfox uninstall dart@3.14.0
```

`vfox search dart` 会列出三个渠道里的所有版本，按从新到旧排列；每一条后面的备注就是它所属的渠道（`stable`、`dev` 或 `beta`）。详见 [docs/zh-CN/versions.md](docs/zh-CN/versions.md)。

## 平台

插件支持 Linux、macOS 和 Windows 上的 x64 与 ia32（32 位 x86）。SDK 压缩包按平台命名，例如 `dartsdk-linux-x64-release.zip`。

| 操作系统 | x64（`amd64` → `x64`） | ia32（`386` → `ia32`） | arm64 |
| --- | --- | --- | --- |
| Linux | `dartsdk-linux-x64-release.zip` | `dartsdk-linux-ia32-release.zip` | 不支持 |
| macOS | `dartsdk-macos-x64-release.zip` | `dartsdk-macos-ia32-release.zip` | 不支持 |
| Windows | `dartsdk-windows-x64-release.zip` | `dartsdk-windows-ia32-release.zip` | 不支持 |

**不支持 arm64。** 在任何其他架构上，插件会直接报错，而不会装上一个不匹配的 SDK。详见 [docs/zh-CN/platforms.md](docs/zh-CN/platforms.md)。

## 工作原理

插件从 Google Cloud Storage 上的 Dart SDK 官方归档读取版本列表。`Available` 列出 `stable`、`dev` 和 `beta` 三个渠道的版本；`PreInstall` 把渠道名解析成最新版本（读取 `latest/VERSION`），或者匹配一个确切版本，然后返回 SDK 的 ZIP 地址和从归档里 `.sha256sum` 文件取出的 SHA-256 校验和；`EnvKeys` 把 `<安装根目录>/bin` 加到 `PATH` 上。`PostInstall` 和 `PreUse` 目前什么都不做。插件没有 Detect 钩子，也不解析旧版配置文件或使用镜像。详见 [docs/zh-CN/development.md](docs/zh-CN/development.md)。

## 文档

- [版本与渠道](docs/zh-CN/versions.md)：渠道、确切版本、搜索和卸载（[English](docs/versions.md)）
- [平台支持](docs/zh-CN/platforms.md)：支持的操作系统与架构组合（[English](docs/platforms.md)）
- [从源码安装](docs/zh-CN/install-from-source.md)：从检出的代码构建插件（[English](docs/install-from-source.md)）
- [开发](docs/zh-CN/development.md)：目录结构、钩子、约定和测试（[English](docs/development.md)）
- [E2E 测试](docs/zh-CN/e2e.md)：Linux 与 Windows 容器测试套件（[English](docs/e2e.md)）
- [变更记录](docs/zh-CN/changes.md)：更新日志（[English](docs/changes.md)）

## 发布这个插件

维护者在默认分支上从 **Actions → Plugin → Run workflow** 发布，填入不带 `v` 前缀的稳定插件版本号。共享的 [plugin-manifest-action](https://github.com/version-fox/plugin-manifest-action) 会更新 `metadata.lua`、创建版本提交和标签，并在这个仓库里发布 ZIP 和 manifest。不需要本地打标签，也不需要额外的发布令牌。拉取请求只运行检查；PR 标题不再触发发布。

如果 `PLUGIN.version` 已经和标签一致，推送已有的版本标签也能发布。如果发布失败，重新运行原来失败的任务即可续跑。这套流程使用共享的 `@v1` 发布工具版本；更新这个工具本身不会发布本插件。包的约定和首次接入的要求见[共享工作流文档](https://github.com/version-fox/plugin-manifest-action)。发布之后，[vfox-plugins](https://github.com/version-fox/vfox-plugins) 里的 `plugins/dart.json` 会显示新版本。

## 致谢与链接

- [vfox](https://vfox.dev/) 和 [vfox-plugins](https://github.com/version-fox/vfox-plugins)
- [Dart](https://dart.dev/) 以及 [SDK 官方归档](https://storage.googleapis.com/dart-archive/)
- [plugin-manifest-action](https://github.com/version-fox/plugin-manifest-action)，发布流程由它驱动

本项目使用 Apache License 2.0 授权，见 [LICENSE](LICENSE)。
