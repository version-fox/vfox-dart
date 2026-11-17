# 从源码安装

[中文](install-from-source.md) | [English](../install-from-source.md)

`vfox add dart` 安装的是最新版本。想在下一个版本发布之前用上 `main`，或者测试你正在改的内容，可以从源码构建插件。插件就是 `metadata.lua` 加上 `hooks` 和 `lib` 目录，vfox 从这些文件打成的 zip 里添加插件。

## Ubuntu

在 Bash 里执行：

```bash
sudo apt install --assume-yes git zip
git clone --depth 1 https://github.com/version-fox/vfox-dart.git
cd ./vfox-dart/
zip -qr ./dart.zip metadata.lua hooks lib
vfox add dart --source ./dart.zip
rm ./dart.zip
```

macOS 上的做法一样，用系统自带的 `git` 和 `zip` 即可。

## Windows 11

假设已经安装 PowerShell 7。在 PowerShell 7 里执行：

```powershell
winget install --id Git.Git --source winget --exact
git clone --depth 1 https://github.com/version-fox/vfox-dart.git
cd ./vfox-dart/
tar -a -cf ./dart.zip metadata.lua hooks lib
vfox add dart --source ./dart.zip
Remove-Item ./dart.zip
```

## 检查

```bash
vfox install dart@stable
vfox use --global dart@stable
dart --version
```

`vfox install dart@stable` 会下载最新的 stable Dart SDK。插件把 `PATH` 设置到 SDK 的 `bin` 目录，不设置其他环境变量——没有需要配置的 `DART_HOME`。要让新开的 Shell 能找到 `dart`，必须把 vfox 挂载到你的 Shell；见[快速入门](https://vfox.dev/zh-hans/guides/quick-start.html)。

## 已经添加过 dart 时

`vfox add` 会报 `plugin named dart already exists` 而拒绝。你可以替换掉插件，也可以把源码版本和它并存。

要替换，先执行 `vfox remove dart`。vfox 在询问之前会告诉你这也会删掉通过该插件安装的 SDK；之后再重新安装它们。

要两者并存，给新插件起一个别名：

```bash
vfox add dart --source ./dart.zip --alias dart-dev
vfox install dart-dev@stable
vfox remove -y dart-dev            # 只删除 dart-dev 及它安装的内容
```

别名有自己独立的已安装 SDK 列表。由于 `PATH` 是插件设置的，而不是靠一个固定的 home 变量，每个作用域里只从两个插件中选一个版本：先执行 `vfox unuse --global dart`，再执行 `vfox use --global dart-dev@...`，或者反过来。

## 更新

拉取新代码，重新打 zip 并再次添加。以原名添加的插件必须先删除，而这会删掉已安装的 SDK，所以经常更新的话用别名更省事：

```bash
vfox remove -y dart-dev
vfox add dart --source ./dart.zip --alias dart-dev
```

`vfox update dart` 会比较 `metadata.lua` 里的版本和仓库里的版本；在比它更新的版本发布之前，它不会动源码安装的版本。

要修改插件本身，见 [development.md](development.md)。
