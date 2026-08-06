# Brew Tool Standardization Design

## Goal

Standardize `git`, `python3`, and `jq` on Homebrew instead of Apple's bundled
(Xcode Command Line Tools / system) binaries, for consistent tool management
and freshness. Fix the PATH ordering bug that currently lets system binaries
shadow Homebrew's, and automate the migration in `setup.sh`. Bash only — zsh
and fish are out of scope.

## Current State (from investigation)

- `/opt/homebrew/bin` comes *after* `/usr/bin` in `$PATH`
  (`/usr/local/bin:...:/usr/bin:/bin:...:/opt/homebrew/bin:...`), so even
  installing a Homebrew formula for a tool that also exists system-side
  doesn't make Homebrew's version win.
- Tool resolution today: `git` → `/usr/bin/git` (Xcode CLT), `python3`/`pip3`
  → `/usr/bin/python3` (Apple system Python), `jq` → `/usr/bin/jq` (Apple
  system). Everything else already used in this repo's `.bashrc`/`setup.sh`
  (node, npm, docker, kubectl, aws, terraform, helm, colima, cosign,
  limactl, rg, gh, starship, opencode) already resolves to
  `/opt/homebrew/bin`.
- zsh already gets PATH ordering right via `.zprofile`'s
  `eval "$(/opt/homebrew/bin/brew shellenv zsh)"` (untracked in this repo —
  out of scope per decision below). bash has no equivalent, so it's the
  one platform where this bug bites.
- Verified: `jq` completion already works today with the *system* jq —
  `bash-completion@2` bundles `completions-core/jq.bash`, looked up by
  command name, not install path. `pip3` completion already works via the
  existing dynamic `eval "$(pip3 completion --bash)"` block in `.bashrc`.
  Neither tool's completion is blocked on migrating to Homebrew.
- `git` completion *was* broken (fixed in the prior bash-completion work by
  sourcing whichever `git-completion.bash` the resolved `git` binary ships
  with — Xcode CLT's, at `$(xcode-select -p)/usr/share/git-core/`). That
  fix's guard (`! declare -F _git`) is stale: modern git-completion.bash
  defines `__git_main`/`__git_wrap__git_main`, never a bare `_git` function,
  so the guard never actually detects "already loaded" and would
  unconditionally re-source (and thus override) Homebrew's own
  version-matched completion once git is migrated.
- Homebrew's `git` formula (verified via formula source) installs
  `contrib/completion/git-completion.bash` into
  `#{HOMEBREW_PREFIX}/etc/bash_completion.d/git-completion.bash` — a
  directory already eagerly sourced in full by the `bash-completion@2` line
  added previously. No new completion wiring is needed for git once
  Homebrew-managed; the fallback just needs to stop overriding it.
- `curl`'s Homebrew formula is keg-only by default (not linked onto PATH)
  because of macOS system/TLS assumptions — out of scope per decision below.
- `vim` has no bash-completion story either way (no standard argument
  completion script) — out of scope per decision below.

## Design

### 1. PATH fix (`.bashrc`)

Add, guarded by `command -v brew` (no-op without Homebrew, e.g. plain
Ubuntu):

```bash
if command -v brew &>/dev/null; then
  eval "$(brew shellenv)"
fi
```

Placed in the interactive-shell section of `.bashrc`, before the
completion-loading block (completion loading and the dynamic tool checks
further down depend on `git`/`jq`/`python3` resolving to the intended
binary). Mirrors what `.zprofile` already does for zsh.

### 2. `setup.sh` — automated install step

New step, same guard and `[OK]/[SKIP]/[FAIL]` reporting convention as the
existing `bash-completion@2` step (macOS + Homebrew only; no-op on Linux,
where apt-managed git/python3/jq already resolve correctly and aren't
touched):

```bash
for formula in git python3 jq; do
    if brew list "$formula" &>/dev/null; then
        echo "  [SKIP] $formula already installed"
    else
        brew install "$formula" && echo "  [OK] $formula installed" \
            || echo "  [FAIL] brew install $formula"
    fi
done
```

### 3. Fix the git-completion fallback guard (`.bashrc`)

Only fall back to the CLT completion script when the resolved `git` binary
is *not* under the Homebrew prefix, so Homebrew's own (version-matched)
completion is authoritative once git is migrated, while machines that keep
system git are still covered:

```bash
if command -v git &>/dev/null && { ! command -v brew &>/dev/null || [[ "$(command -v git)" != "$(brew --prefix)"/* ]]; }; then
  clt_git_completion="$(xcode-select -p 2>/dev/null)/usr/share/git-core/git-completion.bash"
  if [ -r "$clt_git_completion" ]; then
    . "$clt_git_completion"
  fi
  unset clt_git_completion
fi
```

### 4. No changes needed for jq / pip3 completions

Confirmed already working regardless of which binary provides the tool
(see Current State). Migrating jq and python3 to Homebrew is purely for
tooling consistency/freshness, not a completions fix.

## Risks / Caveats

- PATH reordering makes `git`/`python3`/`jq` resolve to Homebrew on every
  interactive bash shell. Nothing that invokes these by full path (e.g.
  Xcode build scripts calling `/usr/bin/git` directly) is affected — system
  binaries are not removed, only shadowed for interactive PATH lookup.
- `brew shellenv` also sets `MANPATH`/`INFOPATH` — standard Homebrew
  behavior, not expected to cause issues.
- Homebrew's `python3` formula gets version-bumped/unlinked periodically;
  accepted as a tradeoff per decision below (plain `brew install python3`,
  no version manager).

## Decisions Log

| Decision | Choice |
|----------|--------|
| Shell scope | Bash only — zsh (`.zshrc`/`.zprofile`, untracked in this repo) and fish (stale Linux-path config) out of scope |
| Tools to migrate | `git`, `python3` (+ bundled `pip3`), `jq` |
| Python strategy | Plain `brew install python3`, no version manager (pyenv) |
| PATH fix mechanism | `eval "$(brew shellenv)"` in `.bashrc`, guarded by `command -v brew` |
| `curl` | Out of scope — Homebrew's formula is keg-only by design; forcing it onto PATH risks breaking system TLS/cert assumptions |
| `vim` | Out of scope — no bash-completion payoff either way |
| jq / pip3 completions | No changes needed — already work today regardless of install source |
| git-completion fallback | Tightened to skip when `git` resolves under the Homebrew prefix, so Homebrew's own completion isn't overridden post-migration |
| Automation | `setup.sh` gets a new idempotent install step (macOS + Homebrew only), matching the existing `bash-completion@2` step's pattern |
| Cross-platform | No-op on Linux; apt-managed git/python3/jq untouched |
