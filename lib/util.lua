local json = require("json")
local http = require("http")
local util = {}

util.VersionURL =
"https://storage.googleapis.com/storage/v1/b/dart-archive/o?delimiter=/&prefix=channels/%s/release/&alt=json"
util.DownloadURL = "https://storage.googleapis.com/dart-archive/channels/%s/release/%s/sdk/dartsdk-%s-%s-release.zip"
util.SHA256URL = "https://storage.googleapis.com/dart-archive/channels/%s/release/%s/sdk/dartsdk-%s-%s-release.zip.sha256sum"
util.LatestVersionURL = "https://storage.googleapis.com/dart-archive/channels/%s/release/latest/VERSION"

function util:extractChecksum(url)
    local resp, err = http.get({
        url = url
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
        url = util.VersionURL:format(devType)
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
        osType = osType, archType = archType
    }
end

return util