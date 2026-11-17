// Copyright 2026 Han Li and contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Package windows is the Windows container E2E suite. TestE2E builds
// tests/e2e/windows/Dockerfile once, then drives one long-lived container
// per combination through setup -> install -> verify with the Docker CLI.
//
// Windows containers need a Windows daemon, so CI runs this on windows-latest
// and local runs need Docker in Windows-container mode.
package windows

import (
	"path/filepath"
	"runtime"
	"strings"
	"testing"
	"time"

	"github.com/version-fox/vfox-dart/tests/e2e/common"
)

const pwsh = "C:\\Program Files\\PowerShell\\7\\pwsh.exe"

// pwshPrelude enforces strict error handling: without it pwsh exits 0 even
// when a native command fails, and execOK would pass silently.
const pwshPrelude = "$ErrorActionPreference = 'Stop'; $PSNativeCommandUseErrorActionPreference = $true;"

// TestE2E is skipped in short mode and on non-Windows hosts, where Windows
// containers cannot run.
func TestE2E(t *testing.T) {
	if testing.Short() {
		t.Skip("skip container E2E in short mode")
	}
	if runtime.GOOS != "windows" {
		t.Skipf("Windows containers need a Windows host (running on %s)", runtime.GOOS)
	}

	here, err := filepath.Abs(".")
	if err != nil {
		t.Fatal(err)
	}
	repoRoot := filepath.Join(here, "..", "..", "..")
	image := "vfox-dart-e2e:windows-amd64"

	dockerfile := filepath.Join(repoRoot, "tests", "e2e", "windows", "Dockerfile")
	common.DockerOK(t, "build", "-f", dockerfile, "-t", image, repoRoot)

	combos, err := common.Matrix()
	if err != nil {
		t.Fatal(err)
	}
	sem := make(chan struct{}, common.MaxJobs())
	for _, combo := range combos {
		combo := combo
		t.Run(combo.Slug(), func(t *testing.T) {
			t.Parallel()
			sem <- struct{}{}
			defer func() { <-sem }()
			runOne(t, image, combo)
		})
	}
}

func runOne(t *testing.T, image string, combo common.Combo) {
	t.Helper()
	name := common.ContainerName(combo.Slug())
	common.DockerOK(t, "run", "--detach", "--name", name,
		"--env", "VFOX_VERSION="+combo.Vfox, image)
	t.Cleanup(func() {
		_, _ = common.Docker("rm", "--force", name)
	})

	t.Logf("=== vfox %s / dart channel %s ===", combo.Vfox, combo.Channel)
	setupVfox(t, name)
	checkNotes(t, name)
	checkSearch(t, name, combo.Version)
	installDart(t, name, combo.Version)
	useAndVerify(t, name, combo.Version)
	checkMissingVersionRejected(t, name)
	checkDetectAndLink(t, name)
}

// execRun runs a script through pwsh in the container and returns its exit
// code and combined output.
func execRun(t *testing.T, container, script string) (int, string) {
	t.Helper()
	out, err := common.Docker("exec", container, pwsh, "-NoProfile", "-Command", pwshPrelude+" "+script)
	if err != nil {
		return 1, out
	}
	return 0, out
}

func execOK(t *testing.T, container, script string) string {
	t.Helper()
	code, out := execRun(t, container, script)
	if code != 0 {
		t.Fatalf("exec exited with code %d\n--- script ---\n%s\n--- output ---\n%s", code, script, out)
	}
	return out
}

func execRetry(t *testing.T, container, label, script string) string {
	t.Helper()
	var last string
	for attempt := 1; attempt <= 3; attempt++ {
		code, out := execRun(t, container, script)
		if code == 0 && strings.TrimSpace(out) != "" {
			return out
		}
		last = out
		t.Logf("retry %d/3 for %s (exit %d): %s", attempt, label, code, strings.TrimSpace(out))
		time.Sleep(5 * time.Second)
	}
	t.Fatalf("%s failed after 3 attempts\n--- output ---\n%s", label, last)
	return ""
}

// activated returns the vfox activation and, after a version is selected,
// the env export. Each exec is a fresh process, so both must be re-applied.
func activated(script string) string {
	return `$a = vfox activate pwsh | Out-String; if ($a.Trim()) { Invoke-Expression -Command $a }; ` +
		`$e = vfox env -s pwsh | Out-String; if ($e.Trim()) { Invoke-Expression -Command $e }; ` + script
}

func psQuote(s string) string {
	return "'" + strings.ReplaceAll(s, "'", "''") + "'"
}

func setupVfox(t *testing.T, container string) {
	t.Helper()
	script := `
New-Item -ItemType Directory -Force -Path 'C:\work' | Out-Null
if ($env:VFOX_VERSION -eq 'latest') {
  $effective = & curl.exe -fsSLI -o NUL -w '%{url_effective}' https://github.com/version-fox/vfox/releases/latest
  $tag = ($effective -split '/')[-1].Trim()
  $version = $tag.TrimStart('v')
} else {
  $version = $env:VFOX_VERSION
}
& curl.exe -fsSL --retry 3 --retry-delay 5 --retry-all-errors -o 'C:\work\vfox.zip' "https://github.com/version-fox/vfox/releases/download/v${version}/vfox_${version}_windows_x86_64.zip"
tar.exe -xf 'C:\work\vfox.zip' -C 'C:\work'
$exe = Get-ChildItem -Path 'C:\work' -Recurse -Filter 'vfox.exe' | Select-Object -First 1
if (-not $exe) { throw 'vfox.exe not found in the release zip' }
Copy-Item -Path $exe.FullName -Destination 'C:\Windows\System32\vfox.exe'
tar.exe -a -cf 'C:\work\dart.zip' -C 'C:\e2e' metadata.lua hooks lib
vfox add dart --source 'C:\work\dart.zip'
vfox --version
`
	common.Contains(t, execOK(t, container, script), "vfox", "install vfox and register the local plugin")
	t.Log("PASS vfox installed and the local dart plugin registered")
}

func checkNotes(t *testing.T, container string) {
	t.Helper()
	common.Contains(t, execOK(t, container, "vfox info dart"), common.ReadmeURL, "vfox info dart notes")
	t.Logf("PASS the notes of vfox info dart point to %s", common.ReadmeURL)
}

func checkSearch(t *testing.T, container, version string) {
	t.Helper()
	out := execRetry(t, container, "vfox search dart", "vfox search dart")
	common.Contains(t, out, version, "vfox search dart")
	t.Logf("PASS vfox search dart lists %s", version)
}

func installDart(t *testing.T, container, version string) {
	t.Helper()
	script := "vfox install dart@" + psQuote(version)
	out := execRetry(t, container, "vfox install dart@"+version, script)
	common.Contains(t, out, version, "vfox install dart")
	common.Contains(t, out, "Verifying checksum", "vfox install verifies the checksum")
	t.Logf("PASS dart@%s installed and verified", version)
}

func useAndVerify(t *testing.T, container, version string) {
	t.Helper()
	execOK(t, container, activated("vfox use --global dart@"+psQuote(version)))

	out := execOK(t, container, activated("dart --version"))
	common.Contains(t, out, version, "dart --version")
	common.Contains(t, out, "(stable)", "dart --version channel")
	t.Logf("PASS dart --version reports %s", version)

	out = execOK(t, container, activated("vfox current dart"))
	common.Contains(t, out, version, "vfox current dart")
	t.Log("PASS the installed SDK is selected")
}

func checkMissingVersionRejected(t *testing.T, container string) {
	t.Helper()
	code, out := execRun(t, container, "vfox install dart@0.0.0-does-not-exist")
	if code == 0 {
		t.Fatalf("an unpublished version must fail to install\n--- output ---\n%s", out)
	}
	t.Log("PASS an unpublished version is rejected")
}

// checkDetectAndLink adopts a Dart SDK outside vfox's directories through
// `vfox link --detect -y`. The fake SDK only needs a version file and a
// dart.exe for Detect and vfox's EnvKeys validation; it is not executed.
func checkDetectAndLink(t *testing.T, container string) {
	t.Helper()
	script := `
New-Item -ItemType Directory -Force -Path 'C:\fake-dart-sdk\bin' | Out-Null
'9.9.9' | Set-Content 'C:\fake-dart-sdk\version'
Copy-Item -Path 'C:\Windows\System32\cmd.exe' -Destination 'C:\fake-dart-sdk\bin\dart.exe'
$env:DART_SDK = 'C:\fake-dart-sdk'
$a = vfox activate pwsh | Out-String; if ($a.Trim()) { Invoke-Expression -Command $a }
vfox link --detect -y dart
vfox list dart
`
	out := execOK(t, container, script)
	common.Contains(t, out, "Linked", "vfox link --detect links the SDK")
	common.Contains(t, out, "9.9.9", "vfox list shows the linked version")
	common.Contains(t, out, "linked", "vfox list marks the version as linked")
	t.Log("PASS vfox link --detect adopted a Dart SDK already on the machine")
}
