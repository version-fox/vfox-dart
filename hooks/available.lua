local util = require("util")

--- Return all available versions provided by this plugin
--- @param ctx table Empty table used as context, for future extension
--- @return table Descriptions of available versions and accompanying tool descriptions
function PLUGIN:Available(ctx)
    local result = {}
    util:parseReleases("stable", result)
    util:parseReleases("dev", result)
    util:parseReleases("beta", result)
    table.sort(result, function(a, b)
        return a.version > b.version
    end)
    return result
end