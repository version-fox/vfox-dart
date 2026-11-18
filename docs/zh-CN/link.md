# 使用本机已有的 SDK

[中文](link.md) | [English](../link.md)

如果本机已经有 Dart SDK——手工解压的、Flutter 自带的，或者由 Scoop、Homebrew、系统包管理器、asdf、mise 等其他工具安装的——`vfox link --detect dart` 会直接采用它，而不必再下载一份。这需要 vfox 1.1.0 或更高版本（`vfox --version` 查看）；较旧的 vfox 会忽略这个钩子，也不会动那个 SDK。

```bash
vfox link --detect dart
```

vfox 会列出插件找到的 SDK，选中哪个就链接哪个。要不再逐个确认、全部链接，用：

```bash
vfox link --detect -y dart
```

之后 `vfox use dart@...` 和往常一样用，`vfox list dart` 会把链接进来的版本标成 `(linked → <路径>)`。检测过程只读取文件，绝不会执行 SDK 里的任何东西。

## 会找到哪些地方

一个目录只要满足两个条件就算 Dart SDK 主目录：它的 `version` 文件里写着一个可链接的版本号，并且 `bin` 里有 `dart` 可执行文件（Windows 上是 `dart.exe`、`dart.bat` 或 `dart.cmd`）。钩子还能识别嵌套的 `dart-sdk` 和 `libexec` 布局，asdf/mise 安装的条目和 Homebrew 的 keg 就是这么覆盖到的。它会查找：

- `DART_SDK` 和 `DART_HOME` 环境变量。
- Flutter 自带的 SDK（`FLUTTER_HOME/bin/cache/dart-sdk`），以及 `PATH` 上 Flutter 目录中的 SDK（`.../bin/cache/dart-sdk`）。
- `PATH` 里的每一项：结尾是 `.../bin` 时会去掉 `bin` 再检查 SDK 主目录，同时也会检查那里的 Flutter `.../bin/cache/dart-sdk`。
- asdf（`${ASDF_DATA_DIR}/installs/dart`，默认 `~/.asdf/installs/dart`）和 mise（`${MISE_DATA_DIR}/installs/dart`，默认在设置了 `XDG_DATA_HOME` 时为 `${XDG_DATA_HOME}/mise/installs/dart`，否则为 `~/.local/share/mise/installs/dart`；Windows 上还有 `%LOCALAPPDATA%\mise\installs\dart`）。
- Windows 上还有：Scoop（`~/scoop/apps/dart-sdk/current`）、`Program Files\Dart` 下的子目录，以及 Chocolatey（`%ProgramData%\chocolatey\lib\dart-sdk\tools`）。
- Unix 上还有：`/usr/lib/dart`、`/opt/dart-sdk`、`~/dart-sdk`，常见 Flutter 根目录 `~/flutter`、`/opt/flutter`、`/usr/local/flutter`，Homebrew（`/opt/homebrew/opt/dart/libexec`、`/usr/local/opt/dart/libexec` 及其 Cellar 版本），以及 `/opt/dart*`。

每条结果都带一个说明，指出它是从哪里找到的，因此你能分清它是生效中的 `DART_SDK`、`PATH` 上找到的，还是 mise 装的。vfox 自己安装的内容（位于 `~/.vfox` 或 `$VFOX_HOME` 下）永远不会被报告。重复的路径和重复的版本会被跳过，因此按优先级先匹配到的那条胜出。损坏或删了一半的目录则根本不会出现。

## 版本名

找到的 SDK 用它的 `version` 文件里那个裸版本号命名，例如 `3.13.0`——和传给 `vfox install dart@3.13.0` 的名字一样。名字必须可用于链接：只能包含字母、数字、`.`、`_`、`+` 和 `-`，而且绝不接受 `latest`，所以读不出内容的或占位的 version 文件会被忽略。vfox 里已经安装或链接过的版本也会被跳过。

## 安装时自动建链接

Dart 没有这样的可选功能：安装 Dart SDK 时绝不会往别的工具目录里写链接（和 JDK 插件的 `VFOX_JAVA_JDKS_LINKS` 不同）。Dart 也没有可供设置的相应环境变量。检测只会在你显式执行 `vfox link --detect dart` 时把 SDK 接进 vfox。

## 手动链接

`--detect` 没扫到的地方，可以手工指定目录。它就是 SDK 主目录本身，也就是装着 `version` 文件和 `bin/dart` 的那一层。vfox 会通过 `EnvKeys` 校验这个目录，所以没有 `bin/dart` 的 SDK 无法被链接：

```bash
vfox link dart@3.13.0 /path/to/dart-sdk
vfox use dart@3.13.0
```

手动链接时版本号可以随意取，不必和 SDK 里 `version` 文件的内容一致。例如，给一个手工解压的 SDK 起个本地名字：

```bash
vfox link dart@local /opt/dart-sdk
vfox use dart@local
vfox current dart
```

## 卸载做了什么

`vfox uninstall dart@<版本>` 只删除 vfox 里的这个链接。底层 SDK 原封不动地留在原地：你仍可以直接使用它，也可以再次链接它，SDK 里面的任何东西都不会被改动。链接之后，检测发现的 SDK 和下载安装的 SDK 没有任何区别。

## 另见

- [版本与渠道](versions.md)：安装和卸载 SDK。
- [开发](development.md)：Detect 钩子的约定和测试。
