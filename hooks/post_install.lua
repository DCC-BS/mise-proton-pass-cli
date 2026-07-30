-- hooks/post_install.lua
-- Places the downloaded raw binary at bin/pass-cli and verifies it runs.
--
-- mise downloads the asset (a bare executable, NOT an archive) and drops it in
-- the install root. Its exact filename depends on the mise/vfox version
-- (either the plugin name "pass-cli", or the URL basename like
-- "pass-cli-linux-x86_64"), so we locate it defensively, move it into bin/,
-- chmod +x, and assert `pass-cli --version`.
--
-- Docs: https://mise.jdx.dev/tool-plugin-development.html#postinstall-hook

--- @param ctx { sdkInfo: table }
function PLUGIN:PostInstall(ctx)
    local path = ctx.sdkInfo[PLUGIN.name].path

    -- One POSIX sh script so we don't depend on io.popen or shell quoting libs.
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
