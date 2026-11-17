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

// Package common holds the target-independent pieces of the container E2E
// suite: the matrix of combinations, the environment knobs and the thin
// wrapper around the Docker CLI. The Linux and Windows packages build their
// image and drive each combination with these helpers.
package common

import (
	"fmt"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"testing"
	"time"
)

// ReadmeURL is the link printed by `vfox info dart` through PLUGIN.notes.
const ReadmeURL = "https://github.com/version-fox/vfox-dart/blob/main/README.md"

// Defaults for the environment knobs. Each can be overridden when running
// the suite locally; CI uses the defaults.
const (
	DefaultVfoxVersion = "latest"
	DefaultChannel     = "stable"
	DefaultDartVersion = "3.14.0"
	DefaultMaxJobs     = 2
)

// Combo is one (vfox version x Dart channel) combination. Version is the
// exact Dart release installed and verified in that combination.
type Combo struct {
	Vfox    string
	Channel string
	Version string
}

// Slug is a short, unique-in-a-run name for the combination.
func (c Combo) Slug() string {
	return "vfox-" + c.Vfox + "-" + c.Channel
}

// Matrix expands the space-separated VFOX_VERSION and CHANNEL knobs into
// combinations. DART_VERSION pins the exact release used by every combo,
// so a channel alias and an exact version are both exercised in the suite.
func Matrix() ([]Combo, error) {
	vfox := strings.Fields(envOr("VFOX_VERSION", DefaultVfoxVersion))
	channels := strings.Fields(envOr("CHANNEL", DefaultChannel))
	version := envOr("DART_VERSION", DefaultDartVersion)
	var combos []Combo
	for _, v := range vfox {
		for _, channel := range channels {
			combos = append(combos, Combo{Vfox: v, Channel: channel, Version: version})
		}
	}
	if len(combos) == 0 {
		return nil, fmt.Errorf("empty matrix: check VFOX_VERSION and CHANNEL")
	}
	return combos, nil
}

// MaxJobs is the number of containers a host runs at once.
func MaxJobs() int {
	n, err := strconv.Atoi(envOr("E2E_MAX_JOBS", strconv.Itoa(DefaultMaxJobs)))
	if err != nil || n < 1 {
		return DefaultMaxJobs
	}
	return n
}

// ContainerName returns a fresh name for a throwaway container. The suffix
// keeps parallel and repeated local runs from colliding.
func ContainerName(slug string) string {
	return "vfox-dart-e2e-" + slug + "-" + strconv.FormatInt(time.Now().UnixNano(), 36)
}

// Docker runs `docker` with args, returning its combined output and any
// error. The suites use the CLI rather than a library so the only host
// requirement is Docker itself (and Go), with no reaper or extra service.
func Docker(args ...string) (string, error) {
	cmd := exec.Command("docker", args...)
	out, err := cmd.CombinedOutput()
	return string(out), err
}

// DockerOK runs Docker and fails the test unless it exits 0.
func DockerOK(t *testing.T, args ...string) string {
	t.Helper()
	out, err := Docker(args...)
	if err != nil {
		t.Fatalf("docker %s failed: %v\n--- output ---\n%s", strings.Join(args, " "), err, out)
	}
	return out
}

// Contains fails the test unless out contains want. ANSI colour codes from
// vfox are stripped first so the assertion matches what a user reads.
func Contains(t *testing.T, out, want, label string) {
	t.Helper()
	plain := StripANSI(out)
	if !strings.Contains(plain, want) {
		t.Fatalf("%s: output does not contain %q\n--- output ---\n%s", label, want, plain)
	}
}

// NotContains fails the test if out contains want.
func NotContains(t *testing.T, out, want, label string) {
	t.Helper()
	plain := StripANSI(out)
	if strings.Contains(plain, want) {
		t.Fatalf("%s: output unexpectedly contains %q\n--- output ---\n%s", label, want, plain)
	}
}

// StripANSI removes the SGR colour sequences vfox writes to a terminal.
func StripANSI(s string) string {
	var b strings.Builder
	for i := 0; i < len(s); {
		if i+1 < len(s) && s[i] == '\033' && s[i+1] == '[' {
			i += 2
			for i < len(s) && !((s[i] >= 'A' && s[i] <= 'Z') || (s[i] >= 'a' && s[i] <= 'z')) {
				i++
			}
			if i < len(s) {
				i++
			}
			continue
		}
		b.WriteByte(s[i])
		i++
	}
	return b.String()
}

func envOr(name, fallback string) string {
	if value, ok := os.LookupEnv(name); ok && value != "" {
		return value
	}
	return fallback
}
