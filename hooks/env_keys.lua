-- hooks/env_keys.lua
-- Exposes the install's bin/ directory on PATH so `pass-cli` resolves.
-- Docs: https://mise.jdx.dev/tool-plugin-development.html#envkeys-hook

--- @param ctx { path: string }
--- @return table[] list of { key, value }
function PLUGIN:EnvKeys(ctx)
    return {
        {
            key = "PATH",
            value = ctx.path .. "/bin",
        },
    }
end
