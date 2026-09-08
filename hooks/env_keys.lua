-- hooks/env_keys.lua
-- Exposes the install's bin/ directory on PATH so `pass-cli` resolves.
-- Docs: https://mise.jdx.dev/tool-plugin-development.html#envkeys-hook

--- @param ctx { path: string }
--- @return table[] list of { key, value }
function PLUGIN:EnvKeys(ctx)
    local file = require("file")
    local bin = RUNTIME.osType == "windows" and ctx.path or file.join_path(ctx.path, "bin")
    return {
        {
            key = "PATH",
            value = bin,
        },
    }
end
