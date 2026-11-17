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

local json = require("json")
local http = require("http")
local util = {}

util.VersionURL =
    "https://storage.googleapis.com/storage/v1/b/dart-archive/o?delimiter=/&prefix=channels/%s/release/&alt=json"
util.DownloadURL = "https://storage.googleapis.com/dart-archive/channels/%s/release/%s/sdk/dartsdk-%s-%s-release.zip"
util.SHA256URL =
    "https://storage.googleapis.com/dart-archive/channels/%s/release/%s/sdk/dartsdk-%s-%s-release.zip.sha256sum"
util.LatestVersionURL = "https://storage.googleapis.com/dart-archive/channels/%s/release/latest/VERSION"

function util:extractChecksum(url)
    local resp, err = http.get({
        url = url,
    })
    if err ~= nil or resp.status_code ~= 200 then
        error("get checksum failed" .. err)
    end
    local checksum = resp.body:match("^(%w+)%s")
    return checksum
end

function util:parseReleases(devType, resultArr)
    local type = util:getOsTypeAndArch()
    local resp, err = http.get({
        url = util.VersionURL:format(devType),
    })
    if err ~= nil or resp.status_code ~= 200 then
        error("get version failed" .. err)
    end
    local body = json.decode(resp.body)
    for _, info in ipairs(body.prefixes) do
        local version = util:extractVersions(info)
        if version ~= nil then
            table.insert(resultArr, {
                version = version,
                url = util.DownloadURL:format(devType, version, type.osType, type.archType),
                sha256 = util.SHA256URL:format(devType, version, type.osType, type.archType),
                note = devType,
            })
        end
    end
end

function util:extractVersions(str)
    local version = str:match(".*/(.-)/$")
    if version and not version:match("^%d+$") and version ~= "latest" then
        return version
    end
    return nil
end

--- Split a Dart version into its numeric release components and pre-release
--- identifiers. `3.9.0-95.0.dev` becomes { 3, 9, 0 } and { "95", "0", "dev" }.
local function splitVersion(version)
    local core, pre = version:match("^([^%-]+)%-(.+)$")
    if not core then
        core, pre = version, nil
    end
    local numbers = {}
    for number in core:gmatch("%d+") do
        table.insert(numbers, tonumber(number))
    end
    local identifiers = {}
    if pre then
        for identifier in pre:gmatch("[^%.%-]+") do
            table.insert(identifiers, identifier)
        end
    end
    return numbers, identifiers
end

--- Compare two Dart versions by precedence, returning -1, 0 or 1.
--- Numeric components are compared as numbers, so 3.14.0 is newer than 3.9.4;
--- a release outranks its own pre-releases (3.15.0 > 3.15.0-dev.1).
--- @param a string First version
--- @param b string Second version
--- @return number -1 when a is older, 0 when equal, 1 when a is newer
function util:compareVersions(a, b)
    local an, ai = splitVersion(a)
    local bn, bi = splitVersion(b)
    for i = 1, math.max(#an, #bn) do
        local av, bv = an[i] or 0, bn[i] or 0
        if av ~= bv then
            return av < bv and -1 or 1
        end
    end
    if #ai == 0 and #bi == 0 then
        return 0
    end
    if #ai == 0 then
        return 1
    end
    if #bi == 0 then
        return -1
    end
    for i = 1, math.max(#ai, #bi) do
        local x, y = ai[i], bi[i]
        if not x then
            return -1
        end
        if not y then
            return 1
        end
        local xn, yn = tonumber(x), tonumber(y)
        if xn and yn then
            if xn ~= yn then
                return xn < yn and -1 or 1
            end
        elseif xn then
            -- Numeric identifiers have lower precedence than non-numeric ones.
            return -1
        elseif yn then
            return 1
        elseif x ~= y then
            return x < y and -1 or 1
        end
    end
    return 0
end

function util:getOsTypeAndArch()
    local osType = RUNTIME.osType
    local archType = RUNTIME.archType
    if RUNTIME.osType == "darwin" then
        osType = "macos"
    end
    if RUNTIME.archType == "amd64" then
        archType = "x64"
    elseif RUNTIME.archType == "386" then
        archType = "ia32"
    else
        error("dart does not support" .. RUNTIME.archType .. "architecture")
    end
    return {
        osType = osType,
        archType = archType,
    }
end

return util
