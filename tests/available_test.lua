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

-- Offline test for the Available hook (vfox search): versions from all three
-- channels, newest first, with the channel as the note. vfox decodes the
-- result of a hook, so only the fields vfox keeps (version, note) are
-- asserted here; the download and checksum URLs are checked in
-- pre_install_test.lua and exercised in the container E2E suite.

local json = require("json")
local test = require("vfox.test")
local plugin = test.load({
    os = "linux",
    arch = "amd64",
    http = function(request)
        local channel = request.url:match("prefix=channels/(%a+)/release/")
        assert(channel, "unexpected version request: " .. request.url)
        local versions = {
            stable = { "3.13.0", "3.14.0", "latest" },
            beta = { "3.15.0-beta.1", "latest" },
            dev = { "3.15.0-dev.1", "latest" },
        }
        local prefixes = {}
        for _, version in ipairs(versions[channel]) do
            table.insert(prefixes, "channels/" .. channel .. "/release/" .. version .. "/")
        end
        return { status_code = 200, body = json.encode({ prefixes = prefixes }) }
    end,
})

local result = plugin:Available({})
assert(#result == 4, "expected 4 versions, got " .. #result)

local want = {
    { version = "3.15.0-dev.1", note = "dev" },
    { version = "3.15.0-beta.1", note = "beta" },
    { version = "3.14.0", note = "stable" },
    { version = "3.13.0", note = "stable" },
}
for i, expected in ipairs(want) do
    local got = result[i]
    assert(got.version == expected.version, i .. ": expected " .. expected.version .. ", got " .. tostring(got.version))
    assert(
        got.note == expected.note,
        expected.version .. ": expected note " .. expected.note .. ", got " .. tostring(got.note)
    )
end

print("PASS: Available listed " .. #result .. " versions in newest-first order with channel notes")
