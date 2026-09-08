# mise-proton-pass-cli

A [mise](https://mise.jdx.dev) **tool plugin** that installs the
[Proton Pass CLI](https://proton.me/blog/proton-pass-cli) (`pass-cli`).

```bash
mise use -g pass-cli@latest
pass-cli --version
```

The plugin installs entirely inside mise-managed directories. It does **not**
modify your shell rc files and does **not** write to `/usr/local/bin`,
`~/.local/bin`, or anywhere outside mise's install root.

---

## How it works

The `PreInstall` hook reads Proton's
[`versions.json`](https://proton.me/download/pass-cli/versions.json), selects
the asset for your OS/arch, and returns its URL + SHA-256. mise's Rust core
then performs the HTTP download and verifies the checksum. `PostInstall` moves
the binary to `bin/pass-cli`, marks it executable, and asserts
`pass-cli --version`.

**No `curl`, `jq`, or `sha256sum` are required** at install time — mise does
the fetching and verification itself.

## Supported platforms

| OS | Arch | Supported |
| --- | --- | --- |
| Linux | x86_64, aarch64 | yes |
| macOS | x86_64 (Intel), arm64 (Apple Silicon) | yes |
| Windows | x86_64 | yes (asset is a `.zip`; extracted to the install root) |

## Versions

`versions.json` publishes **exactly one** version — the current latest (e.g.
`2.2.3`). As a result:

- `pass-cli@latest` — resolves to the current published version.
- `pass-cli@2.2.3` / `@2.2` / `@2` — prefix-matched against the current version.
- `pass-cli@2.2.0` (any older) — **fails with a clear message**; Proton does
  not publish historical versions.

This is a limitation of Proton's distribution, not the plugin.

## Install (from GitHub)

```bash
mise plugins install pass-cli https://github.com/DCC-BS/mise-proton-pass-cli
mise install pass-cli@latest
```

Or in one step:

```bash
mise use -g pass-cli@latest
```

## Usage

```bash
pass-cli --version
pass-cli --help
pass-cli login
```

See the [Proton Pass CLI documentation](https://protonpass.github.io/pass-cli/)
for the full command reference.

## Local development

```bash
git clone https://github.com/DCC-BS/mise-proton-pass-cli
cd mise-proton-pass-cli

# link the plugin from this checkout (the name must be "pass-cli")
mise plugins link pass-cli .

# what version does mise discover?
mise ls-remote pass-cli

# install + verify
mise install pass-cli@latest
mise exec pass-cli@latest -- pass-cli --version

# set globally
mise use -g pass-cli@latest
pass-cli --version
```

To iterate on a hook, re-run the install:

```bash
mise plugins uninstall pass-cli@<version>   # or: mise uninstall pass-cli@<version>
mise --debug install pass-cli@latest
```

Lint / smoke test (stylua is auto-provided by this repo's `mise.toml`):

```bash
mise install      # installs stylua
mise run lint     # stylua --check .
mise run test     # lint + link + install + --version
```

### Negative test (version not published)

```bash
mise install pass-cli@2.2.0   # expect: Proton only publishes version '<current>'
```

## Troubleshooting

- **`unsupported platform`** — you are on an unsupported OS/arch. Supported:
  Linux/macOS/Windows on x86_64/aarch64.
- **`versions.json returned HTTP <n>`** — network/proxy issue reaching
  `proton.me`. Check connectivity and retry.
- **`--version verification failed`** — the downloaded binary did not run.
  Re-run with `mise --debug install pass-cli@latest`. mise verifies the SHA-256
  before this step, so a failure here usually indicates a platform/arch
  mismatch.
- **Stale version list** — mise caches the version list briefly; if you just
  published/expect a new version, re-link the plugin or wait for the cache to
  expire.

## Design notes — why not the official installer?

Proton ships an official `install.sh` that respects
`PROTON_PASS_CLI_INSTALL_DIR`. This plugin deliberately does **not** use it:

- `install.sh` duplicates exactly what this plugin does (read `versions.json`,
  download, SHA-256-verify, copy the binary) and additionally requires `curl`
  **and** `jq` at install time.
- mise's Rust core already downloads and verifies SHA-256, so the hooks need
  **zero** shell dependencies and stay fully within mise's install root.

Net result: fewer moving parts, fewer dependencies, identical integrity
guarantees, and no writes outside mise-managed paths.

## Publishing

1. Push the repo to `https://github.com/DCC-BS/mise-proton-pass-cli`.
2. Tag plugin releases (e.g. `v1.0.0`); bump `version` in `metadata.lua`.
3. Users install via
   `mise plugins install pass-cli https://github.com/DCC-BS/mise-proton-pass-cli`.
4. (Optional) submit to the [mise registry](https://mise.jdx.dev/registry.html)
   so `pass-cli` resolves without a URL.

## License

MIT — see [LICENSE](LICENSE).
