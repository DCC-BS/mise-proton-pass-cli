-- hooks/post_install.lua
-- Places the downloaded binary where it can run and verifies it.
--
-- mise downloads the asset and, for archives, extracts it into the install
-- root. Layout differs by platform:
--   Unix:    a bare executable (pass-cli or pass-cli-<os>-<arch>) -> bin/pass-cli
--   Windows: a .zip extracting to pass-cli.exe + libcrypto-3-x64.dll at the
--            install root (the DLL must stay next to the exe)
--
-- Docs: https://mise.jdx.dev/tool-plugin-development.html#postinstall-hook

--- @param ctx { sdkInfo: table }
function PLUGIN:PostInstall(ctx)
    local path = ctx.sdkInfo[PLUGIN.name].path

    if RUNTIME.osType == "windows" then
        -- Keep pass-cli.exe and its DLL together at the install root.
        local exe = path .. "\\pass-cli.exe"
        local rc = os.execute('"' .. exe .. '" --version >NUL 2>&1')
        if rc ~= 0 then
            error("pass-cli: --version verification failed (is pass-cli.exe present?)")
        end
        return
    end

    -- Unix: locate the downloaded binary and place it in bin/.
    -- path is a mise-controlled dir with no spaces or special chars.
    local script = ([[
set -e
mkdir -p "%s/bin"
src=""
for f in "%s"/pass-cli*; do
  [ -f "$f" ] || continue
  b=$(basename "$f")
  if [ "$b" = "pass-cli" ]; then src="$f"; break; fi
  case "$b" in pass-cli-*) src="$f";; esac
done
if [ -z "$src" ]; then
  echo "pass-cli: downloaded binary not found under %s" >&2
  exit 1
fi
mv -f "$src" "%s/bin/pass-cli"
chmod +x "%s/bin/pass-cli"
if ! "%s/bin/pass-cli" --version >/dev/null 2>&1; then
  echo "pass-cli: --version verification failed" >&2
  exit 1
fi
]]):format(path, path, path, path, path, path)

    local rc = os.execute(script)
    if rc ~= 0 then
        error("pass-cli: post-install step failed (see messages above)")
    end
end
