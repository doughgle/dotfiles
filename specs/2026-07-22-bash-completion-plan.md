# Bash Autocomplete Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix bash tab-completion on macOS for Homebrew-installed CLI tools by
re-execing into Homebrew's bash, sourcing bash-completion@2, and adding
dynamic completions for opencode/pip3/terraform.

**Architecture:** Edits to the two existing repo-tracked files (`.bashrc`,
`setup.sh`); no new files.

**Tech Stack:** Bash.

---

## File Structure

| Action | Path | Purpose |
|--------|------|---------|
| EDIT | `.bashrc` | Re-exec guard, extended completion block, dynamic completions |
| EDIT | `setup.sh` | Install `bash-completion@2` on macOS |

---

### Task 1: Add bash re-exec guard to `.bashrc`

**Files:** Modify `.bashrc`

- [ ] **Step 1: Insert re-exec guard after the interactive-shell check (after line 9, before line 11)**

Old (lines 5–11):
```bash
# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
```

New:
```bash
# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# Homebrew ships bash 5.3+ but macOS's default /bin/bash (3.2) still wins
# PATH resolution for plain `bash`. bash-completion@2 and some tools'
# completion scripts (e.g. opencode's, which uses `mapfile`) require bash 4+,
# so re-exec into Homebrew's bash if we're not already running it.
if [ -z "${DOTFILES_BASH_REEXEC:-}" ] && [ "${BASH_VERSINFO[0]}" -lt 4 ] \
   && [ -x /opt/homebrew/bin/bash ]; then
    export DOTFILES_BASH_REEXEC=1
    exec /opt/homebrew/bin/bash
fi

# don't put duplicate lines or lines starting with space in the history.
```

- [ ] **Step 2: Verify diff**
```bash
cd /Users/dhellinger/repos/lib/dotfiles
git diff .bashrc
```

- [ ] **Step 3: Commit**
```bash
cd /Users/dhellinger/repos/lib/dotfiles
git add .bashrc
git commit -m "feat(bashrc): re-exec into Homebrew bash when running old system bash

macOS's default /bin/bash (3.2) doesn't support bash-completion@2 or
opencode's mapfile-based completion (both need bash 4+). Guarded by
DOTFILES_BASH_REEXEC to avoid recursion; no-op on Linux."
```

---

### Task 2: Extend the completion-loading block for Homebrew

**Files:** Modify `.bashrc`

- [ ] **Step 1: Extend the existing programmable-completion block**

Old:
```bash
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
```

New:
```bash
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  elif command -v brew &>/dev/null; then
    HOMEBREW_PREFIX="$(brew --prefix)"
    if [ -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ]; then
      . "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
    fi
  fi
fi

# Dynamic completions for tools with no static completion file
if command -v opencode &>/dev/null; then
    # opencode picks bash vs zsh output based on $SHELL, not an argument;
    # login shell here is zsh, so force it explicitly.
    eval "$(SHELL=/bin/bash opencode completion 2>/dev/null)"
fi

if command -v pip3 &>/dev/null; then
    eval "$(pip3 completion --bash 2>/dev/null)"
fi

if command -v terraform &>/dev/null; then
    complete -C "$(command -v terraform)" terraform
fi
```

- [ ] **Step 2: Verify diff**
```bash
cd /Users/dhellinger/repos/lib/dotfiles
git diff .bashrc
```

- [ ] **Step 3: Commit**
```bash
cd /Users/dhellinger/repos/lib/dotfiles
git add .bashrc
git commit -m "feat(bashrc): wire up bash completion for Homebrew tools

Source bash-completion@2's profile.d script on macOS (covers aws,
aws-sso, brew, colima, cosign, docker, gh, helm, kubectl, limactl,
npm, rg, starship via Homebrew's auto-installed static completion
files). Add dynamic completions for opencode, pip3, and terraform,
which have no static file."
```

---

### Task 3: Install `bash-completion@2` in `setup.sh`

**Files:** Modify `setup.sh`

- [ ] **Step 1: Add install step after OS detection (after line 58, before "# Dotfiles at repo root")**

Old (lines 56–61):
```bash
OS="$(detect_os)"
echo "Detected OS: $OS"
echo ""

# Dotfiles at repo root
echo "--- Installing dotfiles ---"
```

New:
```bash
OS="$(detect_os)"
echo "Detected OS: $OS"
echo ""

# bash-completion (macOS/Homebrew only — Linux distros ship it via apt)
echo "--- Installing bash-completion ---"
if [ "$OS" = "darwin" ] && command -v brew &>/dev/null; then
    if brew list bash-completion@2 &>/dev/null; then
        echo "  [SKIP] bash-completion@2 already installed"
        SKIP=$((SKIP + 1))
    else
        echo "  Installing bash-completion@2..."
        if brew install bash-completion@2; then
            echo "  [OK] bash-completion@2 installed"
            OK=$((OK + 1))
        else
            echo "  [FAIL] brew install bash-completion@2"
            FAIL=$((FAIL + 1))
        fi
    fi
else
    echo "  [SKIP] Not macOS/Homebrew"
    SKIP=$((SKIP + 1))
fi

# Dotfiles at repo root
echo "--- Installing dotfiles ---"
```

- [ ] **Step 2: Verify diff**
```bash
cd /Users/dhellinger/repos/lib/dotfiles
git diff setup.sh
```

- [ ] **Step 3: Commit**
```bash
cd /Users/dhellinger/repos/lib/dotfiles
git add setup.sh
git commit -m "feat(setup): auto-install bash-completion@2 on macOS

Required for the new Homebrew completion-loading branch in .bashrc.
No-op on Linux (apt-based distros ship bash-completion separately)
and if brew isn't present."
```

---

### Task 4: Run setup.sh and verify end-to-end

- [ ] **Step 1: Run setup.sh**
```bash
cd /Users/dhellinger/repos/lib/dotfiles
./setup.sh
```
Confirm `bash-completion@2` installs (or is skipped if already present) and
`.bashrc` is copied to `$HOME/.bashrc` (accept the overwrite prompt — current
live `.bashrc` predates this change).

- [ ] **Step 2: Open a fresh bash shell and verify bash version**
```bash
bash -c 'bash --version | head -1'
```
Expect `GNU bash, version 5.3.x` (confirms re-exec worked).

- [ ] **Step 3: Verify completions are registered**
```bash
bash -ic 'complete -p aws docker kubectl helm gh npm rg brew colima cosign limactl aws-sso starship opencode terraform pip3'
```
Every tool should print a `complete -F ...` or `complete -C ...` line, not
`bash: complete: <tool>: no completion specification`.

- [ ] **Step 4: Spot-check actual tab completion behavior**

Manually, in an interactive bash shell:
- `kubectl ge<TAB>` → completes to `get`
- `docker imag<TAB>` → completes to `image`/`images`
- `terraform pl<TAB>` → completes to `plan`
- `opencode ru<TAB>` → completes to `run`

- [ ] **Step 5: Confirm no startup errors**
```bash
bash -ic 'exit' 2>&1
```
Expect no output (no warnings/errors printed during `.bashrc` sourcing).

---

### Task 5: Final review

- [ ] **Step 1: Review full diff across both commits**
```bash
cd /Users/dhellinger/repos/lib/dotfiles
git log --oneline -5
git diff HEAD~3 -- .bashrc setup.sh
```

- [ ] **Step 2: Confirm cross-platform safety on Linux path (code review only, no Linux machine available)**

Verify by inspection that:
- The re-exec guard is a no-op when `/opt/homebrew/bin/bash` doesn't exist.
- The completion block still hits the original `/usr/share/bash-completion`
  or `/etc/bash_completion` branches first, unchanged, before ever reaching
  the new `elif command -v brew` branch.
- The `setup.sh` bash-completion step is skipped entirely when `$OS != darwin`.
