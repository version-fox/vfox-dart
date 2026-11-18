# 开发

[中文](development.md) | [English](../development.md)

## 目录结构

```
metadata.lua                    插件名、版本、主页、manifest 地址
hooks/available.lua             vfox search：列出三个渠道的版本
hooks/pre_install.lua           vfox install：解析渠道或确切版本，返回地址 + sha256
hooks/post_install.lua          空操作
hooks/pre_use.lua               空操作
hooks/env_keys.lua              PATH = <安装根目录>/bin
hooks/detect.lua                vfox link --detect dart：列出本机已有的 Dart SDK
lib/util.lua                    归档地址、版本列表、校验和提取、平台映射
tests/*_test.lua                离线钩子测试，由 vfox plugin test 运行
tests/e2e/                      容器测试，见 e2e.md
Injection.lua                   vfox 注入对象的类型提示，不会被加载
README.md, README_CN.md, docs/  文档；docs/zh-CN/ 是中文版
stylua.toml, .luarc.json        Lua 格式化与语言服务器配置
.licenserc.yaml, .license.tpl   Apache-2.0 许可证头检查配置
.gitattributes, .dockerignore,
.github/actionlint.yaml         仓库辅助配置
opencode.jsonc                  让本仓库里的 OpenCode 智能体会话不必确认就能执行 git push、gh pr create 和 gh pr comment
.github/workflows/              Lint、License、Test Plugin、E2E 和 Plugin（发布）工作流
```

vfox 加载 `metadata.lua`，命令需要时调用相应的钩子，并向钩子提供全局变量 `PLUGIN` 和 `RUNTIME`（`osType`、`archType`、`version`）。`osType` 和 `archType` 来自 vfox 二进制的运行环境。

插件安装时只有一个上游：Google Cloud Storage 上的 Dart SDK 官方归档 `https://storage.googleapis.com/dart-archive/`。它不解析旧版配置文件，不使用镜像，除了归档里 `.sha256sum` 文件中的 SHA-256 之外也没有别的校验算法。可选的 Detect 钩子只读取本机已有的 SDK，不下载任何东西。

## 一条命令会执行什么

| 你执行 | 调用的钩子 |
| --- | --- |
| `vfox search dart` | `Available` 列出 `stable`、`dev`、`beta` 三个渠道的版本，从新到旧 |
| `vfox link --detect dart` | `Detect` 列出本机已有的 Dart SDK |
| `vfox install dart@stable`（`@dev`、`@beta`） | `PreInstall` 读取 `latest/VERSION`，返回解析出的版本对应的地址和 sha256；vfox 下载解压后调用 `PostInstall`（空操作） |
| `vfox install dart@3.14.0` | `PreInstall` 在 `Available` 里找到这个确切版本，返回其地址和 sha256；vfox 下载解压并调用 `PostInstall` |
| `vfox use --global dart@stable`（或任意版本） | `PreUse`（空操作）；`EnvKeys` 提供 `PATH` |
| `vfox uninstall dart@3.14.0` | vfox 移除该安装；没有自定义的卸载钩子 |

## 约定

- **渠道别名解析。** 对 `stable`、`dev` 和 `beta`，`PreInstall` 读取 `channels/<channel>/release/latest/VERSION`，这是一个含 `date`、`version` 和 `revision` 三个字段的 JSON 对象，其中 `version` 作为安装的版本。渠道在安装时才解析。
- **列表读取。** `Available` 会读取每个渠道 `channels/<channel>/release/` 列表的每一页，跟随 `nextPageToken`（归档每页最多返回 1000 个前缀），并按版本优先级排序。任何一次请求出现 HTTP 或传输错误都会让命令失败，绝不返回残缺的列表。
- **确切版本。** 确切版本必须出现在 `Available` 从三个渠道的 `channels/<channel>/release/` 前缀收集到的列表里，否则安装失败。安装后的名字就是这个确切版本。
- **下载与校验。** SDK 是归档里的 `dartsdk-<os>-<arch>-release.zip`，用同名的 `.sha256sum` 文件校验。ZIP 里只有一个顶层 `dart-sdk/` 目录，vfox 会去掉它，所以安装根目录里是 `bin/dart`、`bin/dartaotruntime` 等。
- **环境变量。** `EnvKeys` 在所有平台上返回 `PATH = <安装根目录>/bin`，不设置其他变量。
- **Detect。** `Detect`（需要 vfox 1.1.0+）为 `vfox link --detect dart` 查找本机已有的 Dart SDK。只通过读文件来认定 SDK 主目录：`version` 文件里有一个可链接的版本号，且 `bin` 里有 `dart` 可执行文件（Windows 上是 `dart.exe`／`dart.bat`／`dart.cmd`）；绝不会执行 SDK 里的任何东西。返回的 `path` 就是 SDK 主目录本身——也正是 `EnvKeys` 收到的 `ctx.path`——所以 vfox 无需下载就能链接它。vfox 自己安装的内容会被排除，重复的路径和版本会被跳过，按优先级先匹配到的那条胜出。见 [link.md](link.md)。
- **平台映射。** `darwin` 变成 `macos`；`linux` 和 `windows` 原样传递。`amd64` 变成 `x64`，`386` 变成 `ia32`。其他架构（例如 `arm64`）会让 `lib/util.lua` 调用 `error(...)`，因此不受支持。见 [platforms.md](platforms.md)。

## 测试

离线钩子测试在 `vfox plugin test` 下运行，vfox 1.0.13 及更高版本提供这个命令。在仓库根目录执行：

```bash
vfox plugin test .
```

测试文件先调用一次 `vfox.test` 里的 `test.load()`，再通过它返回的对象调用真正的钩子。HTTP 用假响应替身，所以不需要网络。`tests/detect_test.lua` 用替身的目录列表和版本文件覆盖检测逻辑（生效的 `DART_SDK`、`PATH`、Flutter 自带 SDK、asdf、mise、排除 vfox 自己安装的内容、损坏的目录，以及 Windows 上的 `dart.exe`）；在低于 1.1.0 的 vfox 上会跳过。`tests/releases_test.lua` 覆盖版本列表：每一页都会读取，重复的 `nextPageToken` 会报错，失败的请求会报告所在步骤和 HTTP 状态。vfox 会自动发现每个 `tests/**/*_test.lua`，新增测试文件不需要在任何地方登记。见 vfox 的[测试与调试插件](https://vfox.dev/zh-hans/plugins/create/testing.html)。

`tests/e2e` 里的 Go 模块只依赖标准库；短模式会跳过容器套件，足够快，适合本地检查：

```bash
cd tests/e2e && go test -short ./...
```

格式检查、许可证头和容器测试见 [e2e.md](e2e.md#本地检查)。

## 发布

维护者在默认分支上从 **Actions → Plugin → Run workflow** 发布，填入不带 `v` 前缀的稳定插件版本号。共享的 [plugin-manifest-action](https://github.com/version-fox/plugin-manifest-action) 会更新 `metadata.lua`、创建版本提交和标签，并在这个仓库里发布 ZIP 和 manifest。不需要本地打标签，也不需要额外的发布令牌；拉取请求只运行检查。如果 `PLUGIN.version` 已经和标签一致，推送版本标签也能发布。如果发布失败，重新运行失败的任务即可续跑。这套流程使用共享的 `@v1` 发布工具版本；更新这个工具本身不会发布本插件。包的约定和首次接入的要求见[共享工作流文档](https://github.com/version-fox/plugin-manifest-action)。发布之后，[vfox-plugins](https://github.com/version-fox/vfox-plugins) 里的 `plugins/dart.json` 会显示新版本。

## 编写文档

英文页面在 `docs/`，中文页面在 `docs/zh-CN/` 下使用相同的文件名（中文 README 是 `README_CN.md`），每个页面开头都有到另一种语言的链接。新增页面要加进两份 README 的文档列表里。各钩子的约定写在 [versions.md](versions.md)、[platforms.md](platforms.md) 和 [link.md](link.md)（Detect）里。CI 不检查文档内容，所以你新增的命令要自己跑一遍确认。
