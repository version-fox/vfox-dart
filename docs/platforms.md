# Platform support

[中文](zh-CN/platforms.md) | [English](platforms.md)

The plugin maps vfox's runtime platform to the naming used by the official Dart SDK archive at `https://storage.googleapis.com/dart-archive/` and downloads `dartsdk-<os>-<arch>-release.zip`. `RUNTIME.osType` of `darwin` becomes `macos` in the URL; `linux` and `windows` pass through. `RUNTIME.archType` of `amd64` becomes `x64`, and `386` becomes `ia32`.

| OS (`osType`) | x64 (`amd64` → `x64`) | ia32 (`386` → `ia32`) |
| --- | --- | --- |
| Linux (`linux`) | `dartsdk-linux-x64-release.zip` | `dartsdk-linux-ia32-release.zip` |
| macOS (`darwin` → `macos`) | `dartsdk-macos-x64-release.zip` | `dartsdk-macos-ia32-release.zip` |
| Windows (`windows`) | `dartsdk-windows-x64-release.zip` | `dartsdk-windows-ia32-release.zip` |

The supported combinations are therefore Linux, macOS and Windows on x64 or ia32. Each download is verified against the sibling `.sha256sum` file. After unpacking, the install root holds `bin/dart`, `bin/dartaotruntime`, and so on, and `EnvKeys` sets `PATH` to that `bin` directory.

## arm64 is not supported

Only `amd64` and `386` are mapped in `lib/util.lua`. For any other architecture — including `arm64` on Apple silicon, ARM Windows or ARM Linux — the mapping calls Lua's `error(...)` with a message naming the architecture (for example `dart does not supportarm64architecture`). As a result `vfox search` and `vfox install` fail on those platforms instead of installing an SDK that does not match. There is no arm64 build support, fallback or emulation in this plugin.

See [development.md](development.md) for the mapping in the code and [versions.md](versions.md) for how versions are chosen within a supported platform.
