# 版本与渠道

[中文](versions.md) | [English](../versions.md)

`vfox install` 和 `vfox use` 里 `dart@` 后面的部分，要么是发布渠道，要么是一个确切版本。

## 渠道

共有三个发布渠道：`stable`、`dev` 和 `beta`。写渠道名会解析成该渠道上发布的最新版本：

```bash
vfox install dart@stable
vfox install dart@dev
vfox install dart@beta
```

`PreInstall` 读取 `https://storage.googleapis.com/dart-archive/channels/<channel>/release/latest/VERSION` 来解析渠道。这个文件是 JSON，含三个字段：

```json
{
  "date": "2026-11-17",
  "version": "3.14.1",
  "revision": "c8a0db5978a68d4037f7e5294ffc79867935c8c2"
}
```

其中 `version` 是安装的值，`date` 是发布日期，`revision` 是上游的修订号。例如，截至 2026-11-18，最新的 stable 是 **3.14.1**，发布于 **2026-11-17**。渠道在安装时才解析，所以以后再次安装 `@stable` 可能会装上更新的版本；安装后的 SDK 以解析出的版本号命名。

## 确切版本

已经发布的版本可以直接写出来：

```bash
vfox install dart@3.14.0
vfox use --global dart@3.14.0
```

`PreInstall` 会把确切版本和 `Available` 从三个渠道收集到的版本做匹配。任何渠道都没有发布的版本会安装失败。安装后的名字就是那个确切版本，`vfox list`、`vfox current` 和 `vfox uninstall` 用的也是这个名字。

## 搜索

```bash
vfox search dart
```

`Available` 读取三个渠道各自的 `channels/<channel>/release/` 前缀，收集版本并按从新到旧排序。列出的每个版本都能传给 `vfox install`；每条后面的备注是它来自哪个渠道：

```
$ vfox search dart
Available versions:
  - 3.15.0-148.0.dev (dev)
  - 3.15.0-118.1.beta (beta)
  - 3.14.1 (stable)
  ...
```

上面的输出只是示意。一个版本在多个渠道都发布时可能出现多次——备注能告诉你每一条对应哪个渠道。vfox 可能缓存可用列表，所以刚发布的版本可能要过一会儿才会出现。

## 使用、列出与卸载

`vfox use` 只是选中一个已安装的版本，不会下载任何东西：

```bash
vfox use --global dart@3.14.0
vfox current dart                # 当前作用域选中的版本
vfox list dart                   # 已安装的 SDK
vfox uninstall dart@3.14.0
```

`vfox uninstall` 需要的是确切的安装版本，也就是 `vfox list dart` 显示的名字。插件能下载哪些 SDK 归档见 [platforms.md](platforms.md)；版本如何解析见 [development.md](development.md)。
