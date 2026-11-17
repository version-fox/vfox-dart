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

--- Finds Dart SDKs already on the machine for `vfox link --detect dart`.
---
--- A result's path is the SDK home, the same directory EnvKeys expects as
--- ctx.path, so vfox can adopt it without downloading another copy. A home is
--- identified by reading files only: its `version` file names the version and
--- a `dart` (`dart.exe` on Windows) in `bin` proves it is runnable. Nothing
--- inside the installations is executed. Flutter's bundled SDK is included,
--- since most Dart SDKs on a machine come with Flutter.
---
--- vfox's own installations are never reported. This hook is optional and
--- needs vfox 1.1.0 or later; an older vfox simply never loads the file.

local function onWindows()
    return RUNTIME ~= nil and RUNTIME.osType == "windows"
end

local function trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

--- Returns true when a path is inside the SDK directory vfox itself manages.
local function isVfoxManaged(path)
    local normalized = (path or ""):gsub("\\", "/")
    local vfoxHome = (os.getenv("VFOX_HOME") or ""):gsub("\\", "/")
    if vfoxHome ~= "" and (normalized == vfoxHome or normalized:find(vfoxHome .. "/", 1, true) == 1) then
        return true
    end
    local home = (os.getenv("HOME") or os.getenv("USERPROFILE") or ""):gsub("\\", "/")
    return home ~= "" and normalized:find(home .. "/.vfox/", 1, true) == 1
end

--- Lists the children of a directory as full paths. Missing or unreadable
--- directories give an empty list instead of an error.
local function listChildren(dir)
    if dir == nil or dir == "" then
        return {}
    end
    local command
    if onWindows() then
        command = 'dir /b "' .. dir:gsub('"', "") .. '" 2>nul'
    else
        command = 'ls -1 "' .. dir:gsub('"', "") .. '" 2>/dev/null'
    end
    -- Not every platform offers the same io.popen handle (on Windows vfox
    -- replaces it). A failed listing only means fewer candidates; the direct
    -- file checks below still find SDKs pointed at by DART_SDK or PATH.
    local ok, entries = pcall(function()
        local handle = io.popen(command, "r")
        if handle == nil or type(handle.lines) ~= "function" then
            return {}
        end
        local result = {}
        for line in handle:lines() do
            line = trim(line)
            if line ~= "" and line ~= "." and line ~= ".." then
                result[#result + 1] = dir .. "/" .. line
            end
        end
        handle:close()
        return result
    end)
    if not ok or type(entries) ~= "table" then
        return {}
    end
    return entries
end

--- Reads the version from a Dart SDK's `version` file. Returns nil when there
--- is no usable version. The name must stay linkable: vfox accepts only
--- letters, digits, '.', '_', '+' and '-', and never the name `latest`.
local function readVersion(dir)
    local file = io.open(dir .. "/version", "r")
    if file == nil then
        return nil
    end
    local line = file:read("*l")
    file:close()
    if line == nil then
        return nil
    end
    line = trim(line)
    if line ~= "" and line ~= "latest" and line:match("^[A-Za-z0-9][A-Za-z0-9._+%-]*$") then
        return line
    end
    return nil
end

--- Checks for the launcher with io.open rather than a directory listing: it
--- works the same on every platform and needs no child process.
local function dartExecutable(dir)
    local names = { "dart" }
    if onWindows() then
        names = { "dart.exe", "dart.bat", "dart.cmd" }
    end
    for _, name in ipairs(names) do
        local file = io.open(dir .. "/bin/" .. name, "r")
        if file ~= nil then
            file:close()
            return true
        end
    end
    return false
end

--- If dir is a Dart SDK home, returns its version and home. The nested
--- `dart-sdk` and `libexec` layouts cover asdf/mise entries and Homebrew kegs.
local function probeSdk(dir)
    for _, candidate in ipairs({ dir, dir .. "/dart-sdk", dir .. "/libexec" }) do
        local version = readVersion(candidate)
        if version ~= nil and dartExecutable(candidate) then
            return version, candidate
        end
    end
    return nil, nil
end

function PLUGIN:Detect(ctx)
    local found = {}
    local seenPaths = {}
    local seenVersions = {}

    local function addOne(dir, note)
        if dir == nil or dir == "" then
            return
        end
        dir = dir:gsub("[/\\]+$", "")
        if dir == "" or seenPaths[dir] or isVfoxManaged(dir) then
            return
        end
        seenPaths[dir] = true
        local version, home = probeSdk(dir)
        if version ~= nil and home ~= nil and not seenVersions[version] then
            seenVersions[version] = true
            seenPaths[home] = true
            found[#found + 1] = { version = version, path = home, note = note }
        end
    end

    local function addChildren(parent, note, namePattern)
        for _, child in ipairs(listChildren(parent)) do
            local name = child:match("([^/\\]+)$") or child
            if namePattern == nil or name:match(namePattern) then
                addOne(child, note)
            end
        end
    end

    --- Flutter keeps its SDK at <flutter>/bin/cache/dart-sdk.
    local function addFlutter(root, note)
        if root == nil or root == "" then
            return
        end
        addOne(root:gsub("[/\\]+$", "") .. "/bin/cache/dart-sdk", note)
    end

    -- The SDK selected in the environment, if any.
    addOne(os.getenv("DART_SDK"), "active DART_SDK from the environment")
    addOne(os.getenv("DART_HOME"), "active DART_HOME from the environment")
    addFlutter(os.getenv("FLUTTER_HOME"), "bundled with Flutter (FLUTTER_HOME)")

    -- PATH entries catch hand-unpacked SDKs, whose bin holds dart, and
    -- Flutter's shim, whose bin/cache holds its bundled SDK.
    local pathValue = os.getenv("PATH") or ""
    local pathSep = onWindows() and ";" or ":"
    for entry in (pathValue .. pathSep):gmatch("([^" .. pathSep .. "]+)" .. pathSep) do
        entry = trim(entry):gsub('^"', ""):gsub('"$', "")
        local normalized = entry:gsub("\\", "/")
        if normalized:match("/[Bb]in/?$") then
            addOne(entry:gsub("[/\\][Bb]in/?$", ""), "found on PATH")
            addOne(entry:gsub("[/\\]+$", "") .. "/cache/dart-sdk", "bundled with Flutter (on PATH)")
        else
            addOne(entry, "found on PATH")
        end
    end

    local home = os.getenv("HOME") or os.getenv("USERPROFILE") or ""

    -- asdf keeps <data>/installs/dart/<version> and mise the same layout.
    local asdfData = os.getenv("ASDF_DATA_DIR") or ""
    if asdfData == "" and home ~= "" then
        asdfData = home .. "/.asdf"
    end
    addChildren(asdfData .. "/installs/dart", "installed by asdf")
    local miseData = os.getenv("MISE_DATA_DIR") or ""
    if miseData == "" then
        local xdg = os.getenv("XDG_DATA_HOME") or ""
        if xdg ~= "" then
            miseData = xdg .. "/mise"
        elseif home ~= "" then
            miseData = home .. "/.local/share/mise"
        end
    end
    addChildren(miseData .. "/installs/dart", "installed by mise")

    if onWindows() then
        local localAppData = os.getenv("LOCALAPPDATA") or ""
        addChildren(localAppData .. "/mise/installs/dart", "installed by mise")
        if home ~= "" then
            addOne(home .. "/scoop/apps/dart-sdk/current", "installed by Scoop")
        end
        addChildren((os.getenv("ProgramFiles") or "") .. "/Dart", "system Dart SDK")
        addChildren((os.getenv("ProgramData") or "") .. "/chocolatey/lib/dart-sdk/tools", "installed by Chocolatey")
        return found
    end

    -- Unix: system packages, manual unzip, Homebrew and common Flutter roots.
    addOne("/usr/lib/dart", "installed by the system package manager")
    addOne("/opt/dart-sdk", "found in /opt")
    if home ~= "" then
        addOne(home .. "/dart-sdk", "unpacked in the home directory")
        addFlutter(home .. "/flutter", "bundled with Flutter")
    end
    addFlutter("/opt/flutter", "bundled with Flutter")
    addFlutter("/usr/local/flutter", "bundled with Flutter")
    addOne("/opt/homebrew/opt/dart/libexec", "installed by Homebrew")
    addOne("/usr/local/opt/dart/libexec", "installed by Homebrew")
    addChildren("/opt/homebrew/Cellar/dart", "installed by Homebrew")
    addChildren("/usr/local/Cellar/dart", "installed by Homebrew")
    addChildren("/opt", "found in /opt", "^dart")
    return found
end
