-- hooks/pre_install.lua
-- Returns download info { version, url, sha256 } for the current platform.
--
-- mise's Rust core performs the actual HTTP download and SHA-256 verification
-- using what this hook returns, so no curl / jq / sha256sum is needed.
--
-- Asset naming (from versions.json):
--   passCliVersions.urls.<os>.<arch> = { url, hash }
--   <os>   in { macos, linux, windows }   (Windows asset is a .zip)
--   <arch> in { x86_64, aarch64 }
--
-- Docs: https://mise.jdx.dev/tool-plugin-development.html#preinstall-hook

--- @param ctx { version: string }
--- @return table { version, url, sha256, note }
function PLUGIN:PreInstall(ctx)
    local http = require("http")
    local json = require("json")

    -- Fetch the manifest fresh so we always return the correct URL+hash pair.
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
    local pv = manifest.passCliVersions
    if type(pv) ~= "table" or pv.version == nil then
        error("pass-cli: manifest has no passCliVersions.version")
    end
    local latest = tostring(pv.version)

    -- ctx.version is whatever mise resolved (from Available): "latest" or a
    -- concrete version. Reject anything that is not the one published version.
    local requested = ctx.version
    if requested ~= nil and requested ~= "latest" and tostring(requested) ~= latest then
        error(
            "pass-cli: Proton only publishes version '"
                .. latest
                .. "' (via versions.json). Requested '"
                .. tostring(requested)
                .. "' is not available. Historical versions are not published by Proton."
        )
    end

    -- Map mise RUNTIME -> Proton platform keys.
    local os_name
    if RUNTIME.osType == "darwin" then
        os_name = "macos"
    elseif RUNTIME.osType == "linux" then
        os_name = "linux"
    elseif RUNTIME.osType == "windows" then
        os_name = "windows"
    end

    local arch
    if RUNTIME.archType == "amd64" or RUNTIME.archType == "x86_64" then
        arch = "x86_64"
    elseif RUNTIME.archType == "arm64" or RUNTIME.archType == "aarch64" then
        arch = "aarch64"
    end

    if os_name == nil or arch == nil then
        error(
            "pass-cli: unsupported platform (os="
                .. tostring(RUNTIME.osType)
                .. ", arch="
                .. tostring(RUNTIME.archType)
                .. "). Supported: Linux/macOS/Windows on x86_64/aarch64."
        )
    end

    local entry = pv.urls and pv.urls[os_name] and pv.urls[os_name][arch]
    if type(entry) ~= "table" or entry.url == nil or entry.hash == nil then
        error(
            "pass-cli: no binary asset for "
                .. os_name
                .. "/"
                .. arch
                .. " in manifest. Proton may not publish this combination."
        )
    end

    return {
        version = latest,
        url = entry.url,
        sha256 = entry.hash,
        note = "Downloading Proton Pass CLI " .. latest .. " (" .. os_name .. "/" .. arch .. ")",
    }
end
