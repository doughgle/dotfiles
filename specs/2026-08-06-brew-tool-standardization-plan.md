# Brew Tool Standardization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Standardize `git`, `python3`, and `jq` on Homebrew instead of
Apple's system binaries by fixing bash's PATH ordering (`brew shellenv`),
automating the installs in `setup.sh`, and tightening the git-completion
fallback so it doesn't override Homebrew's own (version-matched) completion
once git is migrated.

**Architecture:** Edits to the two existing repo-tracked files (`.bashrc`,
`setup.sh`); no new files. Builds on the prior bash-completion work
(`2026-07-22-bash-completion-*`).

**Tech Stack:** Bash, Homebrew.

---

## File Structure

| Action | Path | Purpose |
|--------|------|---------|
| EDIT | `.bashrc` | Add `brew shellenv` PATH fix; tighten git-completion fallback guard |
| EDIT | `setup.sh` | Install `git`, `python3`, `jq` via Homebrew on macOS |

---

### Task 1: Add `brew shellenv` PATH fix to `.bashrc`

**Files:** Modify `.bashrc`

- [x] **Step 1: Insert PATH fix before the programmable-completion block**

Old (around the existing completion-loading block):
```bash
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
```

New:
```bash
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# Homebrew's bin dir comes after /usr/bin in the default PATH, so system
# binaries (git, python3, jq, ...) shadow Homebrew's even when installed.
# `brew shellenv` prepends Homebrew's paths and sets MANPATH/INFOPATH.
# Mirrors what .zprofile already does for zsh.
if command -v brew &>/dev/null; then
  eval "$(brew shellenv)"
fi

# enable programmable completion features (you don't need to enable
```

- [x] **Step 2: Verify diff**
```bash
cd /Users/dhellinger/repos/lib/dotfiles
git diff .bashrc
```

- [x] **Step 3: Commit**
```bash
cd /Users/dhellinger/repos/lib/dotfiles
git add .bashrc
git commit -m "feat(bashrc): fix PATH order so Homebrew wins over system binaries

/opt/homebrew/bin currently sits after /usr/bin in PATH, so system
git/python3/jq shadow their Homebrew equivalents even when installed.
eval \"\$(brew shellenv)\" prepends Homebrew's paths, matching what
.zprofile already does for zsh. No-op without Homebrew (e.g. Ubuntu)."
```

---

### Task 2: Tighten the git-completion fallback guard in `.bashrc`

**Files:** Modify `.bashrc`

- [x] **Step 1: Replace the guard condition**

Old:
```bash
# git completion when git itself isn't Homebrew-managed (e.g. macOS's Xcode
# Command Line Tools git). bash-completion@2 only scans Homebrew's completion
# directories, so CLT git's bundled git-completion.bash is otherwise never
# sourced and `git <TAB>` silently does nothing.
if ! declare -F _git &>/dev/null && command -v git &>/dev/null; then
  clt_git_completion="$(xcode-select -p 2>/dev/null)/usr/share/git-core/git-completion.bash"
  if [ -r "$clt_git_completion" ]; then
    . "$clt_git_completion"
  fi
  unset clt_git_completion
fi
```

New:
```bash
# git completion when git itself isn't Homebrew-managed (e.g. macOS's Xcode
# Command Line Tools git). bash-completion@2 only scans Homebrew's completion
# directories, so CLT git's bundled git-completion.bash is otherwise never
# sourced and `git <TAB>` silently does nothing. Skipped when git resolves
# under the Homebrew prefix: Homebrew's own git formula installs a
# version-matched git-completion.bash into the already-eagerly-sourced
# bash_completion.d, and this fallback's old guard (checking for a bare
# `_git` function) never actually detects that — modern git-completion.bash
# only defines `__git_main` — so it would otherwise re-source and override
# Homebrew's completion with the (possibly older) CLT one.
if command -v git &>/dev/null && { ! command -v brew &>/dev/null || [[ "$(command -v git)" != "$(brew --prefix)"/* ]]; }; then
  clt_git_completion="$(xcode-select -p 2>/dev/null)/usr/share/git-core/git-completion.bash"
  if [ -r "$clt_git_completion" ]; then
    . "$clt_git_completion"
  fi
  unset clt_git_completion
fi
```

- [x] **Step 2: Verify diff**
```bash
cd /Users/dhellinger/repos/lib/dotfiles
git diff .bashrc
```

- [x] **Step 3: Commit**
```bash
cd /Users/dhellinger/repos/lib/dotfiles
git add .bashrc
git commit -m "fix(bashrc): don't let CLT git completion override Homebrew's

The fallback's guard (! declare -F _git) never actually detects an
already-loaded completion: modern git-completion.bash defines
__git_main, never a bare _git function. Once git is Homebrew-managed,
Homebrew's own version-matched git-completion.bash is already sourced
via bash_completion.d, so the fallback must skip re-sourcing the (out
of sync) CLT version. Guard now checks whether the resolved git binary
is under the Homebrew prefix instead."
```

---

### Task 3: Install `git`, `python3`, `jq` via Homebrew in `setup.sh`

**Files:** Modify `setup.sh`

- [x] **Step 1: Add install loop after the existing `bash-completion@2` step**

Old (end of the bash-completion block):
```bash
else
    echo "  [SKIP] Not macOS/Homebrew"
    SKIP=$((SKIP + 1))
fi

# Dotfiles at repo root
```

New:
```bash
else
    echo "  [SKIP] Not macOS/Homebrew"
    SKIP=$((SKIP + 1))
fi

# Standardize on Homebrew for these tools (macOS only — Linux distros use
# apt-managed git/python3/jq, which already resolve correctly)
echo "--- Installing brew-managed CLI tools ---"
if [ "$OS" = "darwin" ] && command -v brew &>/dev/null; then
    for formula in git python3 jq; do
        if brew list "$formula" &>/dev/null; then
            echo "  [SKIP] $formula already installed"
            SKIP=$((SKIP + 1))
        else
            echo "  Installing $formula..."
            if brew install "$formula"; then
                echo "  [OK] $formula installed"
                OK=$((OK + 1))
            else
                echo "  [FAIL] brew install $formula"
                FAIL=$((FAIL + 1))
            fi
        fi
    done
else
    echo "  [SKIP] Not macOS/Homebrew"
    SKIP=$((SKIP + 1))
fi

# Dotfiles at repo root
```

- [x] **Step 2: Verify diff**
```bash
cd /Users/dhellinger/repos/lib/dotfiles
git diff setup.sh
```

- [x] **Step 3: Commit**
```bash
cd /Users/dhellinger/repos/lib/dotfiles
git add setup.sh
git commit -m "feat(setup): auto-install git/python3/jq via Homebrew on macOS

Standardizes tool management on Homebrew instead of Apple's system
binaries, for consistent versions across machines. No-op on Linux
(apt-managed) and if brew isn't present. Combined with the .bashrc
PATH fix, Homebrew's versions now take precedence on PATH."
```

---

### Task 4: Run `setup.sh` and verify end-to-end

- [x] **Step 1: Run setup.sh**
```bash
cd /Users/dhellinger/repos/lib/dotfiles
./setup.sh
```
Confirm `git`, `python3`, `jq` install (or are skipped if already present)
and `.bashrc` is copied to `$HOME/.bashrc` (accept the overwrite prompt —
the live `.bashrc` predates these changes).

- [x] **Step 2: Open a fresh bash shell and verify tool resolution**
```bash
bash -ic 'for t in git python3 pip3 jq; do command -v "$t"; done'
```
Expect all four to resolve under `/opt/homebrew/bin` (or
`/opt/homebrew/opt/.../libexec/bin` for pip3, depending on the formula's
symlink layout) rather than `/usr/bin`.

- [x] **Step 3: Verify git completion still works and is Homebrew's**
```bash
bash -ic 'complete -p git'
readlink -f "$(command -v git)"
```
Confirm a completion spec is registered for `git`, and that `command -v git`
resolves under the Homebrew prefix (`/opt/homebrew/...`).

- [x] **Step 4: Verify jq and pip3 completions are unaffected**
```bash
bash -ic 'complete -p jq pip3'
```
Both should still show registered completion specs (these were never
broken, but confirm the migration didn't regress them).

- [x] **Step 5: Spot-check actual tab completion behavior**

Manually, in an interactive bash shell:
- `git che<TAB>` → completes to `checkout`, `cherry`, `cherry-pick`
- `jq -<TAB>` → shows jq's option flags
- `pip3 in<TAB>` → completes to `install`, `inspect`

- [x] **Step 6: Confirm no startup errors**
```bash
bash -ic 'exit' 2>&1
```
Expect no output (no warnings/errors printed during `.bashrc` sourcing).

---

### Task 5: Final review

- [x] **Step 1: Review full diff across all three commits**
```bash
cd /Users/dhellinger/repos/lib/dotfiles
git log --oneline -5
git diff HEAD~3 -- .bashrc setup.sh
```

- [x] **Step 2: Confirm cross-platform safety on Linux path (code review only, no Linux machine available)**

Verify by inspection that:
- `eval "$(brew shellenv)"` is guarded by `command -v brew` and is a no-op
  where Homebrew isn't installed.
- The `setup.sh` brew-tools step is skipped entirely when `$OS != darwin`
  or brew isn't present, leaving apt-managed git/python3/jq untouched.
- The tightened git-completion guard still falls back to the CLT script
  correctly on machines without Homebrew at all (`! command -v brew`
  short-circuits to true).
