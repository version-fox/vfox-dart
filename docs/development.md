# Development

[中文](zh-CN/development.md) | [English](development.md)

## Layout

```
metadata.lua                    plugin name, version, homepage, manifest URL
hooks/available.lua             vfox search: list versions from all three channels
hooks/pre_install.lua           vfox install: resolve a channel or exact version, return URL + sha256
hooks/post_install.lua          no-op
hooks/pre_use.lua               no-op
hooks/env_keys.lua              PATH = <install-root>/bin
lib/util.lua                    archive URLs, channel listing, checksum extraction, platform mapping
tests/*_test.lua                offline hook tests, run by vfox plugin test
tests/e2e/                      container tests, see e2e.md
Injection.lua                   type hints for what vfox injects, never loaded
README.md, README_CN.md, docs/  documentation; docs/zh-CN/ is the Chinese version
stylua.toml, .luarc.json        Lua formatting and language-server config
.licenserc.yaml, .license.tpl   Apache-2.0 header check config
.gitattributes, .dockerignore,
.github/actionlint.yaml         repository housekeeping
opencode.jsonc                  lets OpenCode agent sessions run git push, gh pr create and gh pr comment without asking
.github/workflows/              Lint, License, Test Plugin, E2E and Plugin (publish) workflows
```

vfox loads `metadata.lua`, calls a hook when a command needs it, and puts `PLUGIN` and `RUNTIME` (`osType`, `archType`, `version`) in scope. `osType` and `archType` come from the vfox binary's runtime environment.

The plugin has a single upstream: the official Dart SDK archive on Google Cloud Storage, `https://storage.googleapis.com/dart-archive/`. It has no Detect hook, no legacy-file parsing, no mirrors and no checksum algorithms beyond the SHA-256 in the archive's `.sha256sum` files.

## What runs for a command

| You run | Hooks |
| --- | --- |
| `vfox search dart` | `Available` lists versions from the `stable`, `dev` and `beta` channels, newest first |
| `vfox install dart@stable` (`@dev`, `@beta`) | `PreInstall` reads `latest/VERSION`, returns the resolved version's URL and sha256; vfox downloads and unpacks, then calls `PostInstall` (no-op) |
| `vfox install dart@3.14.0` | `PreInstall` finds the exact version in `Available`, returns its URL and sha256; vfox downloads, unpacks and calls `PostInstall` |
| `vfox use --global dart@stable` (or any version) | `PreUse` (no-op); `EnvKeys` provides `PATH` |
| `vfox uninstall dart@3.14.0` | vfox removes the install; there is no custom uninstall hook |

## Contracts

- **Channel alias resolution.** For `stable`, `dev` and `beta`, `PreInstall` fetches `channels/<channel>/release/latest/VERSION`, a JSON object with `date`, `version` and `revision`, and uses `version` as the installed version. A channel is resolved at install time.
- **Exact versions.** An exact version must appear in the list `Available` builds from the `channels/<channel>/release/` prefixes of all three channels; otherwise the install fails. The installed name is that exact version.
- **Download and checksum.** The SDK is `dartsdk-<os>-<arch>-release.zip` from the official archive, verified against the sibling `.sha256sum` file. The ZIP contains one top-level `dart-sdk/` directory, which vfox strips, so the install root holds `bin/dart`, `bin/dartaotruntime`, and so on.
- **Environment.** `EnvKeys` returns `PATH = <install-root>/bin` on every platform and sets no other variable.
- **Platform mapping.** `darwin` becomes `macos`; `linux` and `windows` pass through. `amd64` becomes `x64`, `386` becomes `ia32`. Any other architecture (for example `arm64`) makes `lib/util.lua` call `error(...)`, so those platforms are unsupported. See [platforms.md](platforms.md).

## Tests

The offline hook tests run under `vfox plugin test`, which vfox 1.0.13 and later has. Run it from the repository root:

```bash
vfox plugin test .
```

A test file calls `test.load()` from `vfox.test` once, then calls the real hooks through what it returns. HTTP is stubbed with fake responses, so no network is used. vfox discovers every `tests/**/*_test.lua` automatically, so a new test file needs no entry anywhere. See vfox's [Test and debug a plugin](https://vfox.dev/plugins/create/testing.html).

The Go module in `tests/e2e` is standard-library only; the short mode skips the container suites and is quick enough for local checks:

```bash
cd tests/e2e && go test -short ./...
```

Lint, license headers and the container tests are in [e2e.md](e2e.md#local-checks).

## Releasing

A maintainer publishes from **Actions → Plugin → Run workflow** on the default branch, entering a stable plugin version without the `v` prefix. The shared [plugin-manifest-action](https://github.com/version-fox/plugin-manifest-action) updates `metadata.lua`, creates the version commit and tag, and publishes the ZIP and manifest in this repository. No local tag or extra release token is needed; pull requests run checks only. Pushing a version tag publishes too when `PLUGIN.version` already matches it. If publication fails, re-run the failed job to resume it. See the [shared workflow documentation](https://github.com/version-fox/plugin-manifest-action) for the package contract and first-rollout requirements.

### After a release

Documentation marks what is newer than the last release with "Unreleased" ("未发布" in Chinese). Once the release is out:

1. Move those entries in [changes.md](changes.md) under the new version, with the release date, in both languages, and remove the remarks. Check with `grep -rn -i -e unreleased -e 未发布 docs README*`.
2. Update the dated example version in [versions.md](versions.md) (3.14.0, released 2026-11-04) when the latest stable changes.

## Writing the docs

English pages are in `docs/`, the Chinese ones in `docs/zh-CN/` under the same names (the Chinese README is `README_CN.md`), and each page starts with a link to the other language. A new page goes into the Documentation list of both READMEs. Nothing in CI checks the docs, so run any command you add yourself.
