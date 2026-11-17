# Versions and channels

[中文](zh-CN/versions.md) | [English](versions.md)

The part after `dart@` in `vfox install` and `vfox use` is either a release channel or an exact version.

## Channels

There are three release channels: `stable`, `dev` and `beta`. A channel name resolves to the newest version published on that channel:

```bash
vfox install dart@stable
vfox install dart@dev
vfox install dart@beta
```

`PreInstall` resolves a channel by reading `https://storage.googleapis.com/dart-archive/channels/<channel>/release/latest/VERSION`. That file is JSON with three fields:

```json
{
  "date": "2026-11-04",
  "version": "3.14.0",
  "revision": "a1b2c3d4e5"
}
```

`version` is the value installed; `date` is the release date and `revision` the upstream revision. For example, the latest stable as of 2026-11-17 is **3.14.0**, released **2026-11-04**. A channel is resolved at install time, so installing `@stable` again later can pick up a newer version; the SDK is then stored under that resolved version number.

## Exact versions

A published version can be named directly:

```bash
vfox install dart@3.14.0
vfox use --global dart@3.14.0
```

`PreInstall` matches an exact version against the versions `Available` collects from all three channels. A version that is not published on any channel fails to install. The installed name is the exact version, which is also the name used by `vfox list`, `vfox current` and `vfox uninstall`.

## Searching

```bash
vfox search dart
```

`Available` reads the `channels/<channel>/release/` prefixes for each of the three channels, collects the versions and sorts them newest first. Each listed version can be passed to `vfox install`; the note on an entry is the channel it came from:

```
$ vfox search dart
Available versions:
  - 3.14.0 (stable)
  - 3.14.0 (dev)
  - 3.13.0 (beta)
  ...
```

The output is illustrative. A version can appear more than once when it is published on several channels — the note tells you which entry is which. vfox may cache the available list, so a freshly published version can take a while to appear.

## Using, listing and uninstalling

`vfox use` selects an installed version without downloading anything:

```bash
vfox use --global dart@3.14.0
vfox current dart                # selected version in the current scope
vfox list dart                   # installed SDKs
vfox uninstall dart@3.14.0
```

`vfox uninstall` needs the exact installed version, as shown by `vfox list dart`. See [platforms.md](platforms.md) for which SDK archives the plugin can download and [development.md](development.md) for how versions are resolved.
