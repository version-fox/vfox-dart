# Install from source

[中文](zh-CN/install-from-source.md) | [English](install-from-source.md)

`vfox add dart` installs the latest release. To try `main` before its next release, or a change you are working on, build the plugin from source. A plugin is `metadata.lua` plus the `hooks` and `lib` directories, and vfox adds one from a zip of them.

## Ubuntu

Execute in Bash:

```bash
sudo apt install --assume-yes git zip
git clone --depth 1 https://github.com/version-fox/vfox-dart.git
cd ./vfox-dart/
zip -qr ./dart.zip metadata.lua hooks lib
vfox add dart --source ./dart.zip
rm ./dart.zip
```

macOS is the same, with the `git` and `zip` that come with the system.

## Windows 11

Assume PowerShell 7 is already installed. Execute in PowerShell 7:

```powershell
winget install --id Git.Git --source winget --exact
git clone --depth 1 https://github.com/version-fox/vfox-dart.git
cd ./vfox-dart/
tar -a -cf ./dart.zip metadata.lua hooks lib
vfox add dart --source ./dart.zip
Remove-Item ./dart.zip
```

## Check it

```bash
vfox install dart@stable
vfox use --global dart@stable
dart --version
```

`vfox install dart@stable` downloads the newest stable Dart SDK. The plugin sets `PATH` to the SDK's `bin` directory and sets no other environment variable — there is no `DART_HOME` to configure. For `dart` to be found in new shells, vfox must be hooked into your shell; see the [quick start](https://vfox.dev/guides/quick-start.html).

## When dart is already added

`vfox add` refuses with `plugin named dart already exists`. You can replace the plugin or add the source build next to it.

To replace it, run `vfox remove dart` first. vfox tells you before it asks that this also removes the SDKs installed through the plugin; reinstall them afterwards.

To keep both, give the new one another name:

```bash
vfox add dart --source ./dart.zip --alias dart-dev
vfox install dart-dev@stable
vfox remove -y dart-dev            # removes only dart-dev and what it installed
```

The alias has its own list of installed SDKs. Because `PATH` is set by the plugin rather than by a fixed home variable, select a version from only one of the two plugins per scope: run `vfox unuse --global dart` before `vfox use --global dart-dev@...`, or the other way round.

## Updating

Pull, build the zip again and add it again. A plugin added under its own name has to be removed first, which also removes the installed SDKs, so the alias is the easier route when you update often:

```bash
vfox remove -y dart-dev
vfox add dart --source ./dart.zip --alias dart-dev
```

`vfox update dart` compares the version in `metadata.lua` with the registry's and leaves a source build alone until a release newer than that version is published.

To work on the plugin, see [development.md](development.md).
