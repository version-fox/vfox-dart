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

-- Offline test for the PreInstall hook: a channel alias resolves through
-- latest/VERSION, an exact version comes from the archive listing, and the
-- checksum is read from the .sha256sum file. No network is used.

local json = require("json")

local LATEST = {
    stable = "3.14.0",
    dev = "3.15.0-dev.1",
    beta = "3.15.0-beta.1",
}
local PREFIXES = {
    stable = { "3.13.0", "3.14.0", "latest" },
    dev = { "3.15.0-dev.1", "latest" },
    beta = { "3.15.0-beta.1", "latest" },
}
local DIGEST = string.rep("b", 64)

local requests = {}
local function answer(request)
    table.insert(requests, request.url)
    local url = request.url

    local version = url:match("channels/(%a+)/release/latest/VERSION$")
    if version then
        return {
            status_code = 200,
            body = json.encode({ date = "2026-11-04", version = LATEST[version], revision = "abc123" }),
        }
    end

    local listed = url:match("prefix=channels/(%a+)/release/")
    if listed then
        local prefixes = {}
        for _, v in ipairs(PREFIXES[listed]) do
            table.insert(prefixes, "channels/" .. listed .. "/release/" .. v .. "/")
        end
        return { status_code = 200, body = json.encode({ prefixes = prefixes }) }
    end

    local channel, release =
        url:match("channels/(%a+)/release/([^/]+)/sdk/dartsdk%-linux%-x64%-release%.zip%.sha256sum$")
    if channel and release then
        return { status_code = 200, body = DIGEST .. "  dartsdk-linux-x64-release.zip\n" }
    end

    error("unexpected request: " .. url)
end

local test = require("vfox.test")
local plugin = test.load({ os = "linux", arch = "amd64", http = answer })

local function check(input, channel, version)
    requests = {}
    local result = plugin:PreInstall({ version = input })
    assert(result ~= nil, input .. ": no result")
    assert(result.version == version, input .. ": expected " .. version .. ", got " .. tostring(result.version))
    local base = "https://storage.googleapis.com/dart-archive/channels/"
        .. channel
        .. "/release/"
        .. version
        .. "/sdk/dartsdk-linux-x64-release"
    assert(result.url == base .. ".zip", input .. ": unexpected URL " .. tostring(result.url))
    assert(
        result.sha256 == DIGEST,
        input .. ": expected the checksum from the archive, got " .. tostring(result.sha256)
    )
    -- Every install asks the checksum endpoint at least once.
    local asked = false
    for _, url in ipairs(requests) do
        if url:sub(-10) == ".sha256sum" then
            asked = true
        end
    end
    assert(asked, input .. ": the .sha256sum file was never fetched")
end

check("stable", "stable", "3.14.0")
check("dev", "dev", "3.15.0-dev.1")
check("beta", "beta", "3.15.0-beta.1")
check("3.13.0", "stable", "3.13.0")
check("3.15.0-beta.1", "beta", "3.15.0-beta.1")

-- A version no channel publishes yields no install information; vfox then
-- reports it as not found instead of downloading something else.
requests = {}
local missing = plugin:PreInstall({ version = "0.0.0-does-not-exist" })
assert(missing == nil, "an unknown version must not install: " .. tostring(missing))

print("PASS: PreInstall resolved 3 channel aliases, 2 exact versions, the checksum and an unknown version")
