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

-- Offline test for EnvKeys, PostInstall and PreUse. Dart's SDK layout is the
-- same on every platform: vfox strips the archive's single dart-sdk folder,
-- so the install root holds bin/dart and PATH is the only variable needed.

local test = require("vfox.test")
local plugin = test.load({ os = "linux", arch = "amd64" })

local cases = 0
for _, path in ipairs({ "/sdks/dart-3.14.0", "C:\\sdks\\dart-3.14.0" }) do
    local keys = plugin:EnvKeys({ path = path })
    assert(#keys == 1, "expected one env key, got " .. #keys)
    assert(keys[1].key == "PATH", "expected PATH, got " .. tostring(keys[1].key))
    assert(keys[1].value == path .. "/bin", "unexpected PATH " .. tostring(keys[1].value))
    cases = cases + 1
end

-- These hooks are intentionally no-ops: they must not fail or change the
-- install when called.
assert(plugin:PostInstall({}) == nil, "PostInstall must do nothing")
assert(plugin:PreUse({}) == nil, "PreUse must do nothing")

print("PASS: EnvKeys sets only PATH (" .. cases .. " layouts); PostInstall and PreUse are no-ops")
