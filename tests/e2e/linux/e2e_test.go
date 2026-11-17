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

// Package linux is the Ubuntu container E2E suite. TestE2E builds
// tests/e2e/linux/Dockerfile once, then drives one long-lived container per
// combination through setup -> install -> verify with the Docker CLI.
package linux

import (
	"fmt"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
	"time"

	"github.com/version-fox/vfox-dart/tests/e2e/common"
)

// TestE2E is skipped in short mode (the lint workflow runs `go test -short`).
// Locally scope it down with VFOX_VERSION / CHANNEL / DART_VERSION and
// E2E_MAX_JOBS=1.
func TestE2E(t *testing.T) {
	if testing.Short() {
		t.Skip("skip container E2E in short mode")
	}
	// The plugin only maps amd64 -> x64 and 386 -> ia32; other architectures
	// raise an error. There is nothing to verify on an arm64 host.
	if runtime.GOARCH != "amd64" {
		t.Skipf("the dart plugin does not support %s", runtime.GOARCH)
	}

	here, err := filepath.Abs(".")
	if err != nil {
		t.Fatal(err)
	}
	repoRoot := filepath.Join(here, "..", "..", "..")
	image := "vfox-dart-e2e:linux-amd64"

	dockerfile := filepath.Join(repoRoot, "tests", "e2e", "linux", "Dockerfile")
	common.DockerOK(t, "build", "--pull",
		"-f", dockerfile, "-t", image, repoRoot)

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

// runOne performs the full flow in one throwaway container.
func runOne(t *testing.T, image string, combo common.Combo) {
	t.Helper()
	name := common.ContainerName(combo.Slug())
	common.DockerOK(t, "run", "--detach", "--name", name,
		"--env", "VFOX_VERSION="+combo.Vfox, image)
	t.Cleanup(func() {
		_, _ = common.Docker("rm", "--force", name)
	})

	ctx := fmt.Sprintf("vfox %s / dart channel %s", combo.Vfox, combo.Channel)
	t.Logf("=== %s ===", ctx)

	setupVfox(t, name)
	checkNotes(t, name)
	checkSearch(t, name, combo.Version)
	installDart(t, name, combo.Version)
	useAndVerify(t, name, combo.Version)
	checkMissingVersionRejected(t, name)
}

// execRun runs a script with bash -c in the container, returning its exit
// code and combined output.
func execRun(t *testing.T, container, script string) (int, string) {
	t.Helper()
	out, err := common.Docker("exec", container, "bash", "-c", script)
	if err != nil {
		// A non-zero exit is reported through err; the output still tells us
		// why, so callers that expect failure use this function directly.
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

// execRetry runs a network-touching command up to three times. vfox search
// and install hit the Dart archive, which can be briefly unavailable.
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

// activated prefixes a script with vfox's shell activation. Each exec is a
// fresh shell, so activation cannot persist between calls.
func activated(script string) string {
	return `eval "$(vfox activate bash)"; ` + script
}

func shQuote(s string) string {
	return "'" + strings.ReplaceAll(s, "'", `'\''`) + "'"
}

func setupVfox(t *testing.T, container string) {
	t.Helper()
	script := `set -euo pipefail
if [ "$VFOX_VERSION" = "latest" ]; then
  tag=$(curl --fail --silent --show-error --location --output /dev/null --write-out '%{url_effective}' https://github.com/version-fox/vfox/releases/latest | sed 's|.*/||')
  version=${tag#v}
else
  version="$VFOX_VERSION"
fi
archive=/tmp/vfox.tar.gz
curl --fail --silent --show-error --location --retry 3 --retry-delay 5 --retry-all-errors \
  --output "$archive" "https://github.com/version-fox/vfox/releases/download/v${version}/vfox_${version}_linux_x86_64.tar.gz"
tar --extract --gzip --file "$archive" --directory /usr/local/bin --strip-components=1 "vfox_${version}_linux_x86_64/vfox"
(cd /e2e && zip -qr /tmp/dart.zip metadata.lua hooks lib)
vfox add dart --source /tmp/dart.zip
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
	out := execRetry(t, container, "vfox install dart@"+version, "vfox install dart@"+shQuote(version))
	common.Contains(t, out, version, "vfox install dart")
	// vfox prints this when it verifies the download against the .sha256sum
	// file next to the SDK in the Dart archive.
	common.Contains(t, out, "Verifying checksum", "vfox install verifies the checksum")
	t.Logf("PASS dart@%s installed and verified", version)
}

func useAndVerify(t *testing.T, container, version string) {
	t.Helper()
	execOK(t, container, activated("vfox use --global dart@"+shQuote(version)))

	out := execOK(t, container, activated("dart --version"))
	common.Contains(t, out, version, "dart --version")
	common.Contains(t, out, "(stable)", "dart --version channel")
	t.Logf("PASS dart --version reports %s", version)

	out = execOK(t, container, activated("vfox current dart"))
	common.Contains(t, out, version, "vfox current dart")

	out = execOK(t, container, activated("command -v dart"))
	common.Contains(t, out, "/sdks/dart/bin", "PATH points at the installed SDK")
	t.Log("PASS the installed SDK is selected on PATH")
}

func checkMissingVersionRejected(t *testing.T, container string) {
	t.Helper()
	code, out := execRun(t, container, "vfox install dart@0.0.0-does-not-exist")
	if code == 0 {
		t.Fatalf("an unpublished version must fail to install\n--- output ---\n%s", out)
	}
	t.Log("PASS an unpublished version is rejected")
}
