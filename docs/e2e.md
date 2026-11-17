# E2E

[中文](zh-CN/e2e.md) | [English](e2e.md)

The offline Lua hook tests (`tests/*_test.lua` under `vfox plugin test`) run in the **Test Plugin** workflow. The end-to-end suite runs in containers against real vfox on Linux and Windows; each combination gets its own throwaway container, driven from Go through the Docker CLI. The target images — Ubuntu on Linux, Windows Server Core on Windows — carry no Dart, so Dart can only come from what vfox installs.

## Prerequisites

- Docker, with Linux containers on Linux and Windows-container mode on Windows.
- Go 1.25 or later.

The Go module in `tests/e2e` uses only the standard library, so there are no third-party Go dependencies to fetch. The suite drives Docker directly from Go and terminates every container explicitly, so no testcontainers/Ryuk helper is needed.

## Environment knobs

| Variable | Default | Meaning |
| --- | --- | --- |
| `VFOX_VERSION` | `latest` | vfox release to install in each container |
| `CHANNEL` | `stable` | release channel to exercise (`stable`, `dev`, `beta`) |
| `DART_VERSION` | `3.14.0` | exact version the suite installs and verifies |
| `E2E_MAX_JOBS` | `2` | containers to run in parallel |

`go test -short ./...` skips the container suites; use it for a quick local check.

## Linux

On a Linux host with Docker and Go available:

```bash
cd tests/e2e
go test -v -run TestE2E ./linux
```

CI uses the same test with an explicit timeout: `go test -v -timeout 55m -run TestE2E ./linux`.

## Windows

Windows container images only run on a Windows host with Docker in Windows-container mode, so CI runs this job on `windows-latest`; local Windows-container runs need a Windows host too. There is no Ryuk or Compose helper to configure — the Go test starts and stops its own containers.

```bash
cd tests/e2e
go test -v -run TestE2E ./windows
```

CI uses `go test -v -timeout 55m -run TestE2E ./windows`.

## What the suite verifies

Each combination runs the same flow:

1. vfox is installed from the pinned release and the local `dart` plugin is registered from this checkout.
2. `vfox info dart` prints notes that link to the README.
3. `vfox search dart` lists versions.
4. A pinned exact version (`DART_VERSION`, default 3.14.0) installs.
5. `vfox use --global` is run and `dart --version` reports that version.
6. `PATH` points at the installed SDK's `bin` directory.
7. `vfox current dart` matches the version in use.
8. An obviously missing version fails to install.

## CI jobs

The **E2E** workflow runs on pull requests and pushes to `main`:

- `e2e-linux` on `ubuntu-latest` runs `go test -v -timeout 55m -run TestE2E ./linux`.
- `e2e-windows` on `windows-latest` runs `go test -v -timeout 55m -run TestE2E ./windows`.

## Local checks

These mirror the checks in the Lint, License, Test Plugin and E2E workflows. Run them from the repository root unless noted:

```bash
# Lint (.github/workflows/lint.yml)
stylua --check .
lua-language-server --check . --checklevel=Warning

# Offline hook tests (.github/workflows/test.yml)
vfox plugin test .

# Go checks from tests/e2e
cd tests/e2e
go test -short ./...
gofmt -l .
go vet ./...
```

Header checks with Apache SkyWalking Eyes (.github/workflows/license.yml), as native tool or as the same container CI uses:

```bash
license-eye header check
license-eye header fix

docker run --rm -v "$PWD:/work" -w /work apache/skywalking-eyes:0.9.0 header check
docker run --rm -v "$PWD:/work" -w /work apache/skywalking-eyes:0.9.0 header fix
```

There is no PowerShell license step: the Dart plugin has no `.ps1` files.

To work on the plugin itself, see [development.md](development.md).
