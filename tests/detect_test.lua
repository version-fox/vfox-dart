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

-- Detect finds Dart SDKs already on the machine for `vfox link --detect dart`.
-- The test VM disables io.popen, so both the directory listings and the
-- `version` files are stubbed below; no real filesystem is touched.

local test = require("vfox.test")
local plugin = test.load()

if plugin.Detect == nil then
    -- An older vfox never loads hooks/detect.lua. The Test Plugin workflow
    -- pins a release that has `vfox link --detect`.
    print("SKIP: the Detect hook needs vfox 1.1.0 or later")
    return
end

local files = {}
local dirs = {}

local function norm(path)
    return (path or ""):gsub("\\", "/")
end

local function addSdk(home, version, binNames)
    local root = norm(home)
    files[root .. "/version"] = version .. "\n"
    dirs[root .. "/bin"] = binNames
    for _, name in ipairs(binNames) do
        files[root .. "/bin/" .. name] = ""
    end
    local parent = root:match("^(.*)/[^/]+$")
    if parent then
        local base = root:match("/([^/]+)$")
        dirs[parent] = dirs[parent] or {}
        local seen = false
        for _, child in ipairs(dirs[parent]) do
            if child == base then
                seen = true
            end
        end
        if not seen then
            table.insert(dirs[parent], base)
        end
    end
end

io.open = function(path, mode)
    if mode == "r" then
        local content = files[norm(path)]
        if content == nil then
            return nil
        end
        return {
            read = function()
                return content:match("^([^\r\n]*)")
            end,
            close = function()
                return true
            end,
        }
    end
    return nil
end

local seenCommands = {}
io.popen = function(command)
    seenCommands[#seenCommands + 1] = command
    local dir = command:match('^ls %-1 "(.-)"') or command:match('^dir /b "(.-)"')
    local names = (dir and dirs[norm(dir)]) or {}
    local index = 0
    return {
        lines = function()
            return function()
                index = index + 1
                return names[index]
            end
        end,
        close = function()
            return true
        end,
    }
end

local fakeEnv = {}
local realGetenv = os.getenv
os.getenv = function(name)
    local value = fakeEnv[name]
    if value ~= nil then
        return value
    end
    return realGetenv(name)
end

local function detect()
    local found = {}
    for _, item in ipairs(plugin:Detect({})) do
        assert(
            type(item.version) == "string"
                and item.version:match("^[A-Za-z0-9][A-Za-z0-9._+%-]*$")
                and item.version ~= "latest",
            "bad version " .. tostring(item.version)
        )
        assert(type(item.path) == "string" and item.path ~= "", "path missing")
        assert(type(item.note) == "string" and item.note ~= "", "note missing")
        found[item.version .. "\0" .. norm(item.path)] = true
    end
    return found
end

local function expect(found, version, path)
    assert(found[version .. "\0" .. norm(path)], "missing " .. version .. " at " .. path)
end

-- Linux: the active DART_SDK, a hand-unpacked SDK on PATH, Flutter's bundled
-- SDK (also on PATH), asdf and mise. A directory under VFOX_HOME, one with no
-- version file and one with no dart binary are all skipped.
files = {}
dirs = {}
addSdk("/fake/active", "3.13.0", { "dart" })
addSdk("/fake/manual", "3.12.0", { "dart" })
addSdk("/fake/flutter/bin/cache/dart-sdk", "3.11.0", { "dart" })
addSdk("/fake/asdf/installs/dart/3.10.0", "3.10.0", { "dart" })
addSdk("/fake/mise/installs/dart/3.9.0", "3.9.0", { "dart" })
addSdk("/fake/.vfox/sdks/dart", "3.8.0", { "dart" })
files["/fake/broken/version"] = "3.7.0\n"
dirs["/fake/broken/bin"] = {}
dirs["/fake/noversion/bin"] = { "dart" }
dirs["/fake/asdf/installs/dart"] = { "3.10.0" }
dirs["/fake/mise/installs/dart"] = { "3.9.0" }

RUNTIME.osType = "linux"
fakeEnv = {
    DART_SDK = "/fake/active",
    DART_HOME = "/fake/broken",
    FLUTTER_HOME = "/fake/flutter",
    PATH = "/fake/manual/bin:/fake/flutter/bin:/fake/.vfox/sdks/dart/bin:/fake/noversion/bin:/fake/broken/bin:/usr/bin",
    ASDF_DATA_DIR = "/fake/asdf",
    MISE_DATA_DIR = "/fake/mise",
    VFOX_HOME = "/fake/.vfox",
}
local found = detect()
expect(found, "3.13.0", "/fake/active")
expect(found, "3.12.0", "/fake/manual")
expect(found, "3.11.0", "/fake/flutter/bin/cache/dart-sdk")
expect(found, "3.10.0", "/fake/asdf/installs/dart/3.10.0")
expect(found, "3.9.0", "/fake/mise/installs/dart/3.9.0")
assert(found["3.8.0\0/fake/.vfox/sdks/dart"] == nil, "a vfox-managed SDK must not be reported")
assert(found["3.7.0\0/fake/broken"] == nil, "a directory without dart must not be reported")
for key in pairs(found) do
    assert(key:find("noversion", 1, true) == nil, "a directory without a version file must not be reported")
end
assert(seenCommands[1]:sub(1, 7) == 'ls -1 "', "linux must list directories with ls")

-- Windows: dart.exe is required, a PATH entry in a scoop app is stripped of
-- its bin, and the Unix fixtures (bin/dart, no .exe) are not reported.
seenCommands = {}
RUNTIME.osType = "windows"
fakeEnv = {
    USERPROFILE = "C:\\fake\\home",
    DART_SDK = "C:\\fake\\active",
    PATH = "C:\\fake\\scoop\\apps\\dart-sdk\\current\\bin;C:\\Windows",
    LOCALAPPDATA = "C:\\fake\\appdata",
    ASDF_DATA_DIR = "C:\\fake\\asdf",
    MISE_DATA_DIR = "C:\\fake\\mise",
}
addSdk("C:\\fake\\active", "3.6.0", { "dart.exe" })
addSdk("C:\\fake\\scoop\\apps\\dart-sdk\\current", "3.5.0", { "dart.exe" })
addSdk("C:\\fake\\appdata\\mise\\installs\\dart\\3.4.0", "3.4.0", { "dart.exe" })
dirs["C:/fake/appdata/mise/installs/dart"] = { "3.4.0" }
local winFound = detect()
expect(winFound, "3.6.0", "C:\\fake\\active")
expect(winFound, "3.5.0", "C:\\fake\\scoop\\apps\\dart-sdk\\current")
expect(winFound, "3.4.0", "C:\\fake\\appdata\\mise\\installs\\dart\\3.4.0")
assert(winFound["3.13.0\0/fake/active"] == nil, "a Unix bin/dart is not a Windows SDK")
local sawDir = false
for _, command in ipairs(seenCommands) do
    if command:sub(1, 8) == 'dir /b "' then
        sawDir = true
    end
end
assert(sawDir, "windows must list directories with dir /b")

print("PASS: Detect found the active SDK, PATH, Flutter, asdf and mise entries on both platforms")
