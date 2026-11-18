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

-- Offline tests for the channel listing. The archive returns at most 1000
-- prefixes per page, so every page must be read; a repeated nextPageToken is an
-- error; and each failed request names its step and HTTP status. No network is
-- used.

local json = require("json")
local test = require("vfox.test")

local DIGEST = string.rep("b", 64)
local LATEST = { stable = "3.14.0", dev = "3.15.0-dev.1", beta = "3.15.0-beta.1" }

-- Mutable state lives in this table, not in locals: in vfox's Lua runtime a local
-- that is reassigned after a pcall has caught an error is no longer seen by the
-- closures that captured it.
local state = {
    -- The answer to the next request; each case sets it.
    handler = nil,
    -- Every URL the plugin requested in the current case.
    requests = {},
    cases = 0,
}

local plugin = test.load({
    os = "linux",
    arch = "amd64",
    http = function(request)
        table.insert(state.requests, request.url)
        return state.handler(request)
    end,
})
local util = require("util")

-- Counts the requests whose URL contains fragment.
local function count(fragment)
    local n = 0
    for _, url in ipairs(state.requests) do
        if url:find(fragment, 1, true) then
            n = n + 1
        end
    end
    return n
end

-- Runs fn, which must fail with an error that contains each of the given texts.
local function expectError(fn, ...)
    local ok, err = pcall(fn)
    assert(not ok, "expected an error, got none")
    for _, want in ipairs({ ... }) do
        assert(tostring(err):find(want, 1, true), "error should contain '" .. want .. "', got: " .. tostring(err))
    end
    state.cases = state.cases + 1
end

-- One listing page with the given prefixes and, when given, the next page's token.
local function listing(channel, names, nextToken)
    local prefixes = {}
    for _, name in ipairs(names) do
        table.insert(prefixes, "channels/" .. channel .. "/release/" .. name .. "/")
    end
    return { status_code = 200, body = json.encode({ prefixes = prefixes, nextPageToken = nextToken }) }
end

-- Answers the version files and checksums, and serves stable and beta with one
-- page each. The dev listing comes from devPages, keyed by the pageToken as it
-- appears in the request URL ("" for the first page), so the encoding of tokens
-- is checked as well.
local function serve(devPages)
    return function(request)
        local url = request.url
        local channel = url:match("channels/(%a+)/release/latest/VERSION$")
        if channel then
            return { status_code = 200, body = json.encode({ version = LATEST[channel] }) }
        end
        if url:find("/sdk/dartsdk-linux-x64-release.zip.sha256sum", 1, true) then
            return { status_code = 200, body = DIGEST .. "  dartsdk-linux-x64-release.zip\n" }
        end
        channel = url:match("prefix=channels/(%a+)/release/")
        if channel == "dev" then
            local token = url:match("pageToken=([^&]*)") or ""
            assert(devPages[token], "no dev page for pageToken '" .. token .. "'")
            return devPages[token]
        end
        if channel then
            return listing(channel, { LATEST[channel], "latest" })
        end
        error("unexpected request: " .. url)
    end
end

-- The dev listing has three pages. Each request after the first carries the
-- previous nextPageToken, percent-encoded because tokens can contain "+", "/" and "=".
local threePages = {
    [""] = listing("dev", { "3.14.0-dev.1", "1234" }, "t+1"),
    ["t%2B1"] = listing("dev", { "3.14.0-dev.2" }, "a/b=="),
    ["a%2Fb%3D%3D"] = listing("dev", { "3.15.0-dev.1", "latest" }),
}

state.handler = serve(threePages)
state.requests = {}
local releases = {}
util:parseReleases("dev", releases)
local versions = {}
for _, release in ipairs(releases) do
    table.insert(versions, release.version)
end
assert(
    table.concat(versions, ",") == "3.14.0-dev.1,3.14.0-dev.2,3.15.0-dev.1",
    "every page should be read, got: " .. table.concat(versions, ",")
)
assert(
    count("prefix=channels/dev/release/") == 3,
    "expected 3 dev listing requests, got " .. count("prefix=channels/dev/release/")
)
state.cases = state.cases + 1

-- A version that is only on a later page is found by an install.
state.handler = serve(threePages)
local info = plugin:PreInstall({ version = "3.15.0-dev.1" })
assert(info ~= nil and info.version == "3.15.0-dev.1", "3.15.0-dev.1 is on the last page and must be found")
assert(info.sha256 == DIGEST, "unexpected checksum " .. tostring(info.sha256))
assert(
    info.url
        == "https://storage.googleapis.com/dart-archive/channels/dev/release/3.15.0-dev.1/sdk/dartsdk-linux-x64-release.zip",
    "unexpected download URL " .. tostring(info.url)
)
state.cases = state.cases + 1

-- A page that repeats a token already seen would loop forever, so it is an error.
state.handler = serve({
    [""] = listing("dev", { "3.14.0-dev.1" }, "t1"),
    ["t1"] = listing("dev", { "3.14.0-dev.2" }, "t1"),
})
expectError(function()
    util:parseReleases("dev", {})
end, "nextPageToken repeated for dev")

-- A page without a prefixes field adds nothing and ends the listing when it has no token.
state.handler = serve({
    [""] = listing("dev", { "3.14.0-dev.1" }, "t1"),
    ["t1"] = { status_code = 200, body = json.encode({ kind = "storage#objects" }) },
})
local sparse = {}
util:parseReleases("dev", sparse)
assert(#sparse == 1 and sparse[1].version == "3.14.0-dev.1", "expected only the first page's version, got " .. #sparse)
state.cases = state.cases + 1

-- Each failed request names its step and its status, or the transport error.
state.handler = function()
    return { status_code = 503, body = "unavailable" }
end
expectError(function()
    util:parseReleases("dev", {})
end, "get version failed: HTTP 503")

state.handler = function()
    return { status_code = 503, body = "unavailable" }
end
expectError(function()
    util:extractChecksum("https://storage.googleapis.com/dart-archive/x.zip.sha256sum")
end, "get checksum failed: HTTP 503")

state.handler = function()
    return nil, "connection refused"
end
expectError(function()
    util:parseReleases("dev", {})
end, "get version failed: ", "connection refused")

state.handler = function()
    return { status_code = 503, body = "unavailable" }
end
expectError(function()
    plugin:PreInstall({ version = "stable" })
end, "get version failed: HTTP 503")

state.handler = function(request)
    if request.url:find("/latest/VERSION", 1, true) then
        return { status_code = 200, body = json.encode({ version = LATEST.stable }) }
    end
    return { status_code = 503, body = "unavailable" }
end
expectError(function()
    plugin:PreInstall({ version = "stable" })
end, "get checksum failed: HTTP 503")

-- The unsupported-architecture message has its spaces.
RUNTIME.archType = "arm64"
expectError(function()
    util:getOsTypeAndArch()
end, "dart does not support arm64 architecture")
RUNTIME.archType = "amd64"

print(
    "PASS: "
        .. state.cases
        .. " listing cases: every page read, repeated token rejected, HTTP and transport errors named"
)
