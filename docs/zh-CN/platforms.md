# 平台支持

[中文](platforms.md) | [English](../platforms.md)

插件把 vfox 的运行平台映射成 Dart SDK 官方归档 `https://storage.googleapis.com/dart-archive/` 使用的命名，然后下载 `dartsdk-<os>-<arch>-release.zip`。`RUNTIME.osType` 为 `darwin` 时在地址里变成 `macos`；`linux` 和 `windows` 原样传递。`RUNTIME.archType` 为 `amd64` 时变成 `x64`，为 `386` 时变成 `ia32`。

| 操作系统（`osType`） | x64（`amd64` → `x64`） | ia32（`386` → `ia32`） |
| --- | --- | --- |
| Linux（`linux`） | `dartsdk-linux-x64-release.zip` | `dartsdk-linux-ia32-release.zip` |
| macOS（`darwin` → `macos`） | `dartsdk-macos-x64-release.zip` | `dartsdk-macos-ia32-release.zip` |
| Windows（`windows`） | `dartsdk-windows-x64-release.zip` | `dartsdk-windows-ia32-release.zip` |

因此支持的组合是 Linux、macOS 和 Windows 上的 x64 或 ia32。每个下载都会用同名的 `.sha256sum` 文件校验。解压后，安装根目录里是 `bin/dart`、`bin/dartaotruntime` 等，`EnvKeys` 把 `PATH` 指向那个 `bin` 目录。

## 不支持 arm64

`lib/util.lua` 里只映射了 `amd64` 和 `386`。对于其他任何架构——包括 Apple silicon、ARM Windows 或 ARM Linux 上的 `arm64`——映射都会调用 Lua 的 `error(...)`，并带上架构名（例如 `dart does not support arm64 architecture`）。因此 `vfox search` 和 `vfox install` 在这些平台上会失败，而不会装上一个不匹配的 SDK。这个插件不提供 arm64 构建支持、回退或模拟。

代码里的映射见 [development.md](development.md)；在受支持平台上如何选择版本见 [versions.md](versions.md)。
