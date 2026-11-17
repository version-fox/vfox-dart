# vfox-dart

[中文](README_CN.md) | [English](README.md)

Dart plugin for [vfox](https://vfox.dev/). It installs the official Dart SDK from Google's [Dart SDK archive](https://storage.googleapis.com/dart-archive/) and selects it for your shells, so that `dart` and `dartaotruntime` are on your `PATH`.

## Install

After installing [vfox](https://github.com/version-fox/vfox), add the plugin, then install and select an SDK:

```bash
vfox add dart
vfox install dart@stable
vfox use --global dart@stable
dart --version
```

`dart --version` reports the SDK you selected. For `dart` to be on your `PATH`, vfox has to be hooked into your shell — see the [quick start](https://vfox.dev/guides/quick-start.html). The plugin sets only `PATH` (to `<install-root>/bin`); it sets no other environment variable.

## Versions and channels

There are three release channels: `stable`, `dev` and `beta`. A channel name installs the newest version published on that channel:

```bash
vfox install dart@stable      # newest stable, 3.14.0 released 2026-11-04
vfox install dart@dev         # newest dev build
vfox install dart@beta        # newest beta build
```

An exact version works too, and the same names work with `use`:

```bash
vfox install dart@3.14.0
vfox use --global dart@3.14.0
vfox current dart             # selected version in this scope
vfox list dart                # installed SDKs
vfox uninstall dart@3.14.0
```

`vfox search dart` lists the versions from all three channels, newest first; the note on each entry is the channel it came from (`stable`, `dev` or `beta`). See [versions.md](docs/versions.md).

## Already installed SDKs

If a Dart SDK is already on the machine — unpacked by hand, bundled with Flutter, or installed by another tool — `vfox link --detect dart` finds it (needs vfox 1.1.0 or later) and links it without downloading another copy. vfox lists what it found and links what you pick; `vfox link --detect -y dart` links everything. SDKs already installed or linked in vfox are skipped.

```bash
vfox link --detect dart
```

See [Using SDKs already on the machine](docs/link.md) for what is searched and how manual linking works.

## Platforms

The plugin supports x64 and ia32 (32-bit x86) on Linux, macOS and Windows. SDK archives are named after the platform, for example `dartsdk-linux-x64-release.zip`.

| OS | x64 (`amd64` → `x64`) | ia32 (`386` → `ia32`) | arm64 |
| --- | --- | --- | --- |
| Linux | `dartsdk-linux-x64-release.zip` | `dartsdk-linux-ia32-release.zip` | not supported |
| macOS | `dartsdk-macos-x64-release.zip` | `dartsdk-macos-ia32-release.zip` | not supported |
| Windows | `dartsdk-windows-x64-release.zip` | `dartsdk-windows-ia32-release.zip` | not supported |

**arm64 is not supported.** On any other architecture the plugin raises an error instead of installing a mismatched SDK. See [platforms.md](docs/platforms.md).

## How it works

The plugin reads version listings from the official Dart SDK archive on Google Cloud Storage. `Available` lists versions from the `stable`, `dev` and `beta` channels; `PreInstall` resolves a channel to its latest version (from `latest/VERSION`) or matches an exact version, then returns the SDK ZIP URL and its SHA-256 checksum from the archive's `.sha256sum` file; `EnvKeys` puts `<install-root>/bin` on `PATH`. `Detect` finds Dart SDKs already on the machine for `vfox link --detect dart` (vfox 1.1.0+). `PostInstall` and `PreUse` do nothing. There is no legacy-file parsing or mirror support. See [development.md](docs/development.md).

## Documentation

- [Versions and channels](docs/versions.md) — channels, exact versions, searching and uninstalling ([中文](docs/zh-CN/versions.md))
- [Using SDKs already on the machine](docs/link.md) — adopt Dart SDKs found on this machine ([中文](docs/zh-CN/link.md))
- [Platform support](docs/platforms.md) — supported OS and architecture combinations ([中文](docs/zh-CN/platforms.md))
- [Install from source](docs/install-from-source.md) — build the plugin from a checkout ([中文](docs/zh-CN/install-from-source.md))
- [Development](docs/development.md) — layout, hooks, contracts and tests ([中文](docs/zh-CN/development.md))
- [E2E tests](docs/e2e.md) — the Linux and Windows container suites ([中文](docs/zh-CN/e2e.md))
- [Changes](docs/changes.md) — changelog ([中文](docs/zh-CN/changes.md))

## Releasing this plugin

Maintainers publish from **Actions → Plugin → Run workflow** on the default branch, entering a stable plugin version without the `v` prefix. The shared [plugin-manifest-action](https://github.com/version-fox/plugin-manifest-action) updates `metadata.lua`, creates the version commit and tag, and publishes the ZIP and manifest in this repository. No local tag or extra release token is needed. Pull requests run checks only; PR titles no longer trigger publication.

Existing version-tag pushes are supported when `PLUGIN.version` already matches the tag. If publication fails, re-run the original failed job to resume it. The workflow follows the shared `@v1` release-tool version; updating the tool does not release this plugin. See the [shared workflow documentation](https://github.com/version-fox/plugin-manifest-action) for the package contract and first-rollout requirements. After a release, `plugins/dart.json` in [vfox-plugins](https://github.com/version-fox/vfox-plugins) shows the new version.

## Thanks and links

- [vfox](https://vfox.dev/) and [vfox-plugins](https://github.com/version-fox/vfox-plugins)
- [Dart](https://dart.dev/) and the [official SDK archive](https://storage.googleapis.com/dart-archive/)
- [plugin-manifest-action](https://github.com/version-fox/plugin-manifest-action), which powers releases

Licensed under the Apache License 2.0; see [LICENSE](LICENSE).
