-- metadata.lua
-- mise/vfox tool plugin metadata for Proton Pass CLI.
-- Docs: https://mise.jdx.dev/tool-plugin-development.html#metadata-lua
--
-- No `depends` or `systemDependencies`: mise's Rust core performs the HTTP
-- download and SHA-256 verification, so the hooks need no external tools
-- (no curl, jq, or sha256sum).

PLUGIN = { -- luacheck: ignore
    name = "pass-cli",
    version = "1.0.0",
    description = "Proton Pass CLI - manage Proton Pass vaults, items, and secrets from the terminal",
    author = "DCC-BS",
    updateUrl = "https://github.com/DCC-BS/mise-proton-pass-cli",
    minRuntimeVersion = "0.2.0",
}
