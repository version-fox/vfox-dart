-- Copyright 2026 Han Li and contributors
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--   http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- Offline tests for lib/util.lua: platform naming, version extraction and
-- checksum parsing. They run under `vfox plugin test .` with no network.

local test = require("vfox.test")
test.load({ os = "linux", arch = "amd64" })
local util = require("util")

local cases = 0

local function eq(got, want, message)
    assert(got == want, message .. ": expected " .. tostring(want) .. ", got " .. tostring(got))
    cases = cases + 1
end

-- Platform names in the download URL: vfox's Go GOOS/GOARCH become the names
-- the Dart archive uses.
local platform = util:getOsTypeAndArch()
eq(platform.osType, "linux", "linux osType")
eq(platform.archType, "x64", "amd64 archType")

RUNTIME.osType = "darwin"
RUNTIME.archType = "amd64"
platform = util:getOsTypeAndArch()
eq(platform.osType, "macos", "darwin is macos in the URL")
eq(platform.archType, "x64", "darwin amd64 archType")

RUNTIME.osType = "windows"
RUNTIME.archType = "386"
platform = util:getOsTypeAndArch()
eq(platform.osType, "windows", "windows osType")
eq(platform.archType, "ia32", "386 archType")

RUNTIME.osType = "linux"
RUNTIME.archType = "arm64"
local ok, err = pcall(util.getOsTypeAndArch, util)
assert(not ok and tostring(err):find("arm64", 1, true), "arm64 must be rejected: " .. tostring(err))
cases = cases + 1

-- The archive lists versions as `channels/stable/release/<version>/`; only
-- real versions are kept, not the `latest` pointer or numeric-only prefixes.
eq(util:extractVersions("channels/stable/release/3.14.0/"), "3.14.0", "stable version")
eq(util:extractVersions("channels/dev/release/3.15.0-dev.1/"), "3.15.0-dev.1", "dev version")
eq(util:extractVersions("channels/beta/release/latest/"), nil, "latest is skipped")
eq(util:extractVersions("channels/stable/release/123/"), nil, "numeric-only prefix is skipped")

print("PASS: " .. cases .. " util cases")
