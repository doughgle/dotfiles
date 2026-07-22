# Bash Autocomplete Design

## Goal

Enable bash tab-completion for CLI tools in the user's Homebrew-managed "user
local bin" (`/opt/homebrew/bin`) on macOS, while keeping `.bashrc` cross-platform
(Ubuntu fallback untouched). Fix the underlying reasons completion currently
doesn't work at all in bash on this Mac.

## Current State (from investigation)

- `~/bin` and `~/.local/bin` don't exist; `/usr/local/bin` only holds
  root-owned MDM/agent binaries. The only real "user local bin" is Homebrew's
  `/opt/homebrew/bin` (120 binaries).
- `.bashrc`'s completion-loading block only checks Linux paths
  (`/usr/share/bash-completion/...`) — none exist on macOS, so **no bash
  completion loads at all today**.
- Homebrew has already silently installed 13 static completion scripts into
  `/opt/homebrew/etc/bash_completion.d/`: aws-sso, awscli (aws), brew, colima,
  cosign, docker, gh, helm, kubectl, limactl, npm, rg, starship.
- `bash-completion@2` (the Homebrew package that sources that directory +
  lazy-loads v2-style completions) is not installed.
- Even in a real login shell, plain `bash` resolves to macOS's bundled
  `/bin/bash` 3.2.57, not Homebrew's bash 5.3.15 (`brew shellenv` is only
  wired into `.zprofile` for zsh; `path_helper` re-orders `/usr/bin` ahead of
  `/opt/homebrew/bin` for bash). `bash-completion@2` requires bash ≥ 4.2.
- Three tools have no static completion file and need dynamic setup:
  - `opencode` — generates a shell script based on the `$SHELL` env var (not
    an argument); its bash script uses `mapfile` (bash 4+ only).
  - `pip3` — has `pip completion --bash`.
  - `terraform` — no generated script; just needs
    `complete -C terraform terraform` registered.
- `gh`'s self-generated completion (`gh completion -s bash`) is byte-identical
  to the static file Homebrew already installs — no extra work needed.
- Out of scope (no usable bash completion / not selected): `code`,
  `docker-compose`, `lima`, `karabiner_cli`, `tree`, and library-helper
  binaries (`lz4`/`xz`/`zstd`/`gettext`/etc.).

## Design

### 1. Re-exec guard (new, top of `.bashrc`, right after the existing
"return if not interactive" check)

Detect bash < 4 and Homebrew's bash present; `exec` into it once, guarded by
a sentinel env var to prevent recursion. Fixes both the bash-completion@2
version requirement and opencode's `mapfile` dependency. No-op on Linux or
once Apple ships a newer bash.

### 2. Extend the existing completion-loading block (Linux paths preserved)

Add an `elif command -v brew` branch that sources
`$(brew --prefix)/etc/profile.d/bash_completion.sh` (provided by
`bash-completion@2`). That one line pulls in all 13 already-installed static
completions, and lazy-loads anything future formulas add to
`share/bash-completion/completions/`. This also finally activates the
existing `alias k=kubectl` / `complete -F __start_kubectl k` lines at the
bottom of the file, which have been silently broken until now.

### 3. Dynamic completions block (new, for tools with no static file)

Three guarded blocks, each only running if the tool is installed:

- `opencode`: `eval "$(SHELL=/bin/bash opencode completion 2>/dev/null)"` —
  the `SHELL=/bin/bash` override is required because the login shell is zsh,
  so `$SHELL` would otherwise cause opencode to emit its zsh completion
  instead of bash.
- `pip3`: `eval "$(pip3 completion --bash 2>/dev/null)"`.
- `terraform`: `complete -C "$(command -v terraform)" terraform`.

### 4. `setup.sh` — install `bash-completion@2` automatically

New step: on macOS with Homebrew present, `brew install bash-completion@2`
if not already installed, following the existing `[OK]/[SKIP]/[FAIL]`
reporting convention used elsewhere in the script.

## Decisions Log

| Decision | Choice |
|----------|--------|
| Scope of "user local bin" | `/opt/homebrew/bin` (only real user-writable bin dir on this machine) |
| Tools to wire up | aws, aws-sso, brew, colima, cosign, docker, gh, helm, kubectl, limactl, npm, rg, starship (all via existing static files), plus opencode, pip3, terraform (dynamic) |
| bash-completion loading mechanism | Install `bash-completion@2` via brew; source its `profile.d/bash_completion.sh` |
| bash < 4 problem | Re-exec `.bashrc` into Homebrew's bash 5.3 for interactive sessions, guarded by sentinel env var |
| opencode/pip3/terraform completions | Generate/register at shell startup (`eval`/`complete -C`), not pre-generated files — stays in sync with installed tool version, avoids stale committed scripts |
| Cross-platform | Keep existing Linux `/etc/bash_completion` / `/usr/share/bash-completion` fallback; add Homebrew branch guarded by `command -v brew` |
| `bash-completion@2` install | Automate in `setup.sh` (macOS + Homebrew only), not a manual step |
| Out of scope | code, docker-compose, lima, karabiner_cli, tree, library-helper binaries (lz4/xz/zstd/gettext/etc.) |
