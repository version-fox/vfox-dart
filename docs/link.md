# Using SDKs that are already on the machine

[中文](zh-CN/link.md) | [English](link.md)

If a Dart SDK is already on the machine — unpacked by hand, bundled with Flutter, or installed by another tool such as Scoop, Homebrew, a system package manager, asdf or mise — `vfox link --detect dart` adopts it instead of downloading another copy. It needs vfox 1.1.0 or later (`vfox --version`); an older vfox ignores the hook and leaves the SDK alone.

```bash
vfox link --detect dart
```

vfox lists what the plugin found and links what you pick. To link everything without being asked:

```bash
vfox link --detect -y dart
```

Afterwards `vfox use dart@...` works as usual, and `vfox list dart` marks linked versions with `(linked → <path>)`. Detection itself only reads files: it never executes anything inside an SDK.

## What it finds

A directory counts as a Dart SDK home when its `version` file names a linkable version and its `bin` holds a `dart` executable (`dart.exe`, `dart.bat` or `dart.cmd` on Windows). The hook also recognises nested `dart-sdk` and `libexec` layouts, which is how asdf/mise entries and Homebrew kegs are covered. It looks in:

- The `DART_SDK` and `DART_HOME` environment variables.
- Flutter's bundled SDK (`FLUTTER_HOME/bin/cache/dart-sdk`), plus Flutter roots found on `PATH` (`.../bin/cache/dart-sdk`).
- Every `PATH` entry: a trailing `.../bin` is stripped to check the SDK home, and a Flutter `.../bin/cache/dart-sdk` there is checked too.
- asdf (`$ASDF_DATA_DIR/installs/dart`, default `~/.asdf/installs/dart`) and mise (`$MISE_DATA_DIR/installs/dart`, default `$XDG_DATA_HOME/mise/installs/dart` when `XDG_DATA_HOME` is set and `~/.local/share/mise/installs/dart` otherwise; on Windows also `%LOCALAPPDATA%\mise\installs\dart`).
- On Windows: Scoop (`~/scoop/apps/dart-sdk/current`), the children of `Program Files\Dart`, and Chocolatey (`%ProgramData%\chocolatey\lib\dart-sdk\tools`).
- On Unix: `/usr/lib/dart`, `/opt/dart-sdk`, `~/dart-sdk`, the Flutter roots `~/flutter`, `/opt/flutter` and `/usr/local/flutter`, Homebrew (`/opt/homebrew/opt/dart/libexec`, `/usr/local/opt/dart/libexec` and their Cellar versions), and `/opt/dart*`.

Each entry carries a note saying where it came from, so you can tell an active `DART_SDK` from an SDK found on `PATH` or installed by mise. vfox's own installs (under `~/.vfox` or `$VFOX_HOME`) are never reported. Duplicate paths and duplicate versions are skipped, so the first match by priority wins. Broken or half-removed directories simply do not appear.

## Version names

A found SDK is named with the bare version from its `version` file, for example `3.13.0` — the same name you would pass to `vfox install dart@3.13.0`. The name must stay linkable: only letters, digits, `.`, `_`, `+` and `-` are allowed, and `latest` is never accepted, so an unreadable or placeholder version file is ignored. Versions already installed or linked in vfox are skipped too.

## Automatic links on install

Dart has no such opt-in feature: installing a Dart SDK never writes a link into another tool's directories (unlike the JDK plugin's `VFOX_JAVA_JDKS_LINKS`). There is no environment variable to set for Dart. Detection only adopts SDKs into vfox, and only when you explicitly run `vfox link --detect dart`.

## Linking by hand

Where `--detect` does not look, point at the directory by hand. It is the SDK home itself — the directory holding the `version` file and `bin/dart`. vfox validates the directory through `EnvKeys`, so an SDK without `bin/dart` cannot be linked:

```bash
vfox link dart@3.13.0 /path/to/dart-sdk
vfox use dart@3.13.0
```

You can choose any version name you like for a manual link; it does not have to match the SDK's `version` file. For example, to give an unpacked SDK a local name:

```bash
vfox link dart@local /opt/dart-sdk
vfox use dart@local
vfox current dart
```

## What uninstall does

`vfox uninstall dart@<version>` removes only the vfox link. The underlying SDK stays exactly where it was: it can still be used directly or linked again, and nothing inside it is changed. Once linked, an SDK found by detection is no different from a downloaded one.

## See also

- [Versions and channels](versions.md) — installing and uninstalling SDKs.
- [Development](development.md) — the Detect hook's contract and tests.
