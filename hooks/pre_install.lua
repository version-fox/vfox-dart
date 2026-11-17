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

local util = require("util")
local http = require("http")
local json = require("json")
--- Returns some pre-installed information, such as version number, download address, local files, etc.
--- If checksum is provided, vfox will automatically check it for you.
--- @param ctx table Context information; ctx.version is the user-input version
--- @return table? Version information, or nil for an unknown version
function PLUGIN:PreInstall(ctx)
    local arg = ctx.version
    local type = util:getOsTypeAndArch()
    if arg == "stable" or arg == "dev" or arg == "beta" then
        local resp, err = http.get({
            url = util.LatestVersionURL:format(arg),
        })
        if err ~= nil or resp.status_code ~= 200 then
            error("get version failed" .. err)
        end
        local latestVersion = json.decode(resp.body)
        local version = latestVersion.version
        local sha256Url = util.SHA256URL:format(arg, version, type.osType, type.archType)
        local r = {
            version = version,
            url = util.DownloadURL:format(arg, version, type.osType, type.archType),
            sha256 = util:extractChecksum(sha256Url),
        }
        return r
    else
        local releases = self:Available({})
        for _, info in ipairs(releases) do
            if info.version == arg then
                return {
                    version = info.version,
                    url = info.url,
                    sha256 = util:extractChecksum(info.sha256),
                }
            end
        end
    end
    return nil
end
