# E2E

[中文](e2e.md) | [English](../e2e.md)

离线的 Lua 钩子测试（`tests/*_test.lua`，由 `vfox plugin test` 运行）在 **Test Plugin** 工作流里运行。端到端套件在容器里针对真实的 vfox 运行，覆盖 Linux 和 Windows；每个组合都有自己独立的一次性容器，由 Go 通过 Docker CLI 驱动。目标镜像（Linux 上是 Ubuntu，Windows 上是 Windows Server Core）里没有装 Dart，所以 Dart 只能来自 vfox 安装的内容。

## 前置条件

- Docker：Linux 上使用 Linux 容器，Windows 上使用 Windows 容器模式。
- Go 1.25 或更高版本。

`tests/e2e` 里的 Go 模块只依赖标准库，所以没有第三方 Go 依赖要下载。套件直接用 Go 驱动 Docker，并显式终止每个容器，因此不需要 testcontainers/Ryuk 之类的辅助工具。

## 环境变量

| 变量 | 默认值 | 含义 |
| --- | --- | --- |
| `VFOX_VERSION` | `latest` | 每个容器里安装的 vfox 版本 |
| `CHANNEL` | `stable` | 要测试的发布渠道（`stable`、`dev`、`beta`） |
| `DART_VERSION` | `3.14.0` | 套件安装并校验的确切版本 |
| `E2E_MAX_JOBS` | `2` | 并行运行的容器数 |

`go test -short ./...` 会跳过容器套件，适合快速本地检查。

## Linux

在装有 Docker 和 Go 的 Linux 宿主上：

```bash
cd tests/e2e
go test -v -run TestE2E ./linux
```

CI 用同一个测试，并显式指定超时：`go test -v -timeout 55m -run TestE2E ./linux`。

## Windows

Windows 容器镜像只能在开启了 Windows 容器模式的 Windows 宿主上运行，所以 CI 把这个任务跑在 `windows-latest` 上；本地跑 Windows 容器也需要 Windows 宿主。这里不需要配置 Ryuk 或 Compose 之类的辅助工具——Go 测试会自己启动和停止容器。

```bash
cd tests/e2e
go test -v -run TestE2E ./windows
```

CI 使用 `go test -v -timeout 55m -run TestE2E ./windows`。

## 套件验证什么

每个组合都运行同样的流程：

1. 从固定版本安装 vfox，并从当前检出注册本地的 `dart` 插件。
2. `vfox info dart` 打印的 Notes 里有指向 README 的链接。
3. `vfox search dart` 能列出版本。
4. 安装一个固定的确切版本（`DART_VERSION`，默认 3.14.0）。
5. 运行 `vfox use --global`，然后 `dart --version` 报告该版本。
6. `PATH` 指向已安装 SDK 的 `bin` 目录。
7. `vfox current dart` 与使用中的版本一致。
8. 一个明显不存在的版本会安装失败。

## CI 任务

**E2E** 工作流在拉取请求和推送到 `main` 时运行：

- `e2e-linux` 在 `ubuntu-latest` 上运行 `go test -v -timeout 55m -run TestE2E ./linux`。
- `e2e-windows` 在 `windows-latest` 上运行 `go test -v -timeout 55m -run TestE2E ./windows`。

## 本地检查

这些检查对应 Lint、License、Test Plugin 和 E2E 工作流。除特别说明外，都在仓库根目录执行：

```bash
# 格式检查（.github/workflows/lint.yml）
stylua --check .
lua-language-server --check . --checklevel=Warning

# 离线钩子测试（.github/workflows/test.yml）
vfox plugin test .

# 在 tests/e2e 里做 Go 检查
cd tests/e2e
go test -short ./...
gofmt -l .
go vet ./...
```

许可证头检查使用 Apache SkyWalking Eyes（.github/workflows/license.yml），可以用本地工具，也可以用和 CI 相同的容器：

```bash
license-eye header check
license-eye header fix

docker run --rm -v "$PWD:/work" -w /work apache/skywalking-eyes:0.9.0 header check
docker run --rm -v "$PWD:/work" -w /work apache/skywalking-eyes:0.9.0 header fix
```

没有 PowerShell 许可证检查这一步：Dart 插件里没有 `.ps1` 文件。

要修改插件本身，见 [development.md](development.md)。
