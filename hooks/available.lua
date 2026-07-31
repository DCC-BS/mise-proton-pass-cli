-- hooks/available.lua
-- Lists the versions of Proton Pass CLI that mise can install.
--
-- Proton's versions.json publishes exactly ONE version (the current latest),
-- so this hook returns a single entry. mise then resolves:
--   pass-cli@latest, pass-cli@<ver>, pass-cli@<prefix> -> the current version
--   pass-cli@<older> -> a clean "no matching version" error (see pre_install)
--
-- Manifest: https://proton.me/download/pass-cli/versions.json
-- Docs: https://mise.jdx.dev/tool-plugin-development.html#available-hook

--- @param ctx table unused (kept for signature clarity)
--- @return table[] list of { version, note }
function PLUGIN:Available(ctx) -- luacheck: ignore ctx
    local http = require("http")
    local json = require("json")

    local resp, err = http.get({
        url = "https://proton.me/download/pass-cli/versions.json",
    })
    if err ~= nil then
        error("pass-cli: failed to fetch versions.json: " .. tostring(err))
    end
    if resp.status_code ~= 200 then
        error("pass-cli: versions.json returned HTTP " .. tostring(resp.status_code))
    end

    local manifest, perr = json.decode(resp.body)
    if perr ~= nil or type(manifest) ~= "table" then
        error("pass-cli: versions.json is not valid JSON")
    end
    if tostring(manifest.formatVersion) ~= "1" then
        error(
            "pass-cli: unsupported manifest formatVersion '"
                .. tostring(manifest.formatVersion)
                .. "' - the plugin may need updating"
        )
    end

    local pv = manifest.passCliVersions
    if type(pv) ~= "table" or pv.version == nil then
        error("pass-cli: manifest has no passCliVersions.version")
    end

    return {
        {
            version = tostring(pv.version),
            note = "latest",
        },
    }
end
