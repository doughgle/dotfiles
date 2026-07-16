# Dotfiles Backup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Clean cache/state data from the dotfiles repo and add/update portable configuration files with a setup.sh bootstrap script.

**Architecture:** Single repo with XDG-compatible layout. setup.sh copies files from repo to home dir, prompting before overwriting existing files.

**Tech Stack:** Bash (setup.sh), JSON (VS Code config), YAML (gh config), TOML (starship), shell scripts.

---

## File Structure

| Action | Path | Purpose |
|--------|------|---------|
| DELETE | `.k3d/` | Secrets (kubeconfigs) |
| DELETE | `.vscode/` | Extension binaries (1.1G) |
| DELETE | `.fonts/.uuid` | Fontconfig cache marker |
| DELETE | `~35 cache dirs under .config/` | Browser/app caches, state |
| CREATE | `.gitignore` | Prevent future secret commits |
| REWRITE | `.bashrc` | Aliases + completions only |
| REWRITE | `.gitconfig` | Strip identity/secrets |
| EDIT | `.profile` | Drop cargo line |
| CREATE | `.config/gh/config.yml` | gh CLI config |
| CREATE | `.config/gh-copilot/config.yml` | Copilot CLI config |
| CREATE | `.config/opencode/opencode.jsonc` | OpenCode config |
| REWRITE | `.config/Code/User/settings.json` | Curated portable VS Code settings |
| REWRITE | `.config/Code/User/keybindings.json` | Curated portable VS Code keybindings |
| REWRITE | `setup.sh` | Copy-based bootstrap script |

---

### Task 1: Remove cache/state/secrets directories from repo

**Files:**
- Delete: `.k3d/`
- Delete: `.vscode/`
- Delete: `.fonts/.uuid`
- Delete: `.config/google-chrome/`
- Delete: `.config/Code/` (keep `User/` subdir — will rewrite contents separately)
- Delete: `.config/Code - Insiders/` (keep `User/` subdir — will rewrite contents separately)
- Delete: all remaining `.config/*` dirs EXCEPT: `starship.toml`, `fish/`, `gh/`, `gh-copilot/`, `opencode/`, `Code/User/`

Full list of `.config/` dirs to delete:

```
autostart/       cef_user_data/       com.psiexams.psi-bridge-secure-browser/
configstore/     copyq/               dconf/               enchant/
eog/             evince/              evolution/           gedit/
GIMP/            gnome-session/       goa-1.0/             google-chrome/
gtk-2.0/         gtk-3.0/             guake/               hardhat-nodejs/
helm/            ibus/                k3d/                 libreoffice/
md-publisher/    menus/               Microsoft/           Microsoft Teams - Preview/
nautilus/        procps/              PSI Bridge Secure Browser/
pulse/           Rygel/               sh.loft.devpod/      teams/
update-notifier/ wireshark/           yelp/
```

Inside `Code/` and `Code - Insiders/`: delete everything except `User/`:
```
Backups/         blob_storage/        Cache/               CachedConfigurations/
CachedData/      CachedExtensions/    CachedExtensionVSIXs/
CachedProfilesData/  Code Cache/      Crashpad/            databases/
DawnCache/       Dictionaries/        GPUCache/            IndexedDB/
Local Storage/   logs/                Service Worker/      Session Storage/
Shared Dictionary/  WebStorage/       Workspaces/
```

- [ ] **Step 1: Remove .k3d/**

```bash
git rm -r .k3d/
```

- [ ] **Step 2: Remove .vscode/**

```bash
git rm -r .vscode/
```

- [ ] **Step 3: Remove .fonts/.uuid**

```bash
git rm .fonts/.uuid
```

- [ ] **Step 4: Remove all cache dirs under .config/**

```bash
# Remove everything except keep-list
cd /home/dough/repos/exercises/dotfiles/.config
KEEP_DIRS="starship.toml fish gh gh-copilot opencode Code/User"
for d in */; do
  dname="${d%/}"
  keep=false
  for k in $KEEP_DIRS; do
    if [ "$dname" = "$k" ] || [ "$dname" = "Code" ] || [ "$dname" = "Code - Insiders" ]; then
      keep=true; break
    fi
  done
  if [ "$keep" = false ]; then
    git rm -r "$d"
  fi
done
```

- [ ] **Step 5: Clean Code/ and Code - Insiders/ subdirs (keep only User/)**

```bash
cd /home/dough/repos/exercises/dotfiles/.config/Code
for d in */; do
  dname="${d%/}"
  if [ "$dname" != "User" ]; then
    git rm -rf "$d"
  fi
done

cd /home/dough/repos/exercises/dotfiles/.config/Code\ -\ Insiders
for d in */; do
  dname="${d%/}"
  if [ "$dname" != "User" ]; then
    git rm -rf "$d"
  fi
done
```

- [ ] **Step 6: Verify deletions with git status**

```bash
cd /home/dough/repos/exercises/dotfiles
git status
git diff --cached --stat | tail -20
```

- [ ] **Step 7: Commit**

```bash
git commit -m "chore: remove cache data, secrets, and stale files from repo

Remove .k3d/ (kubeconfigs), .vscode/ (extension binaries),
.fonts/.uuid (fontconfig cache marker), and ~35 cache/state
directories under .config/ (browser profiles, app caches,
runtime state). Keep only User/ within Code/ and Code - Insiders/."
```

---

### Task 2: Write .gitignore

**Files:**
- Create: `.gitignore`

- [ ] **Step 1: Create .gitignore**

```gitignore
*.pem
*.env
*.key
*kubeconfig*
*secret*
*credential*
*token*
.k3d/
```

Write to `/home/dough/repos/exercises/dotfiles/.gitignore`.

- [ ] **Step 2: Commit**

```bash
cd /home/dough/repos/exercises/dotfiles
git add .gitignore
git commit -m "chore: add .gitignore with secret file patterns

Patterns: *.pem, *.env, *.key, *kubeconfig*, *secret*,
*credential*, *token*, .k3d/"
```

---

### Task 3: Rewrite .bashrc

**Files:**
- Modify: `.bashrc`

- [ ] **Step 1: Write new .bashrc**

Contents: generic bash plumbing (HISTCONTROL, HISTSIZE, histappend, checkwinsize, lesspipe, color prompt with conditionals, programmable completion boilerplate) plus these custom additions at the bottom:

```bash
export REPOS=/home/dough/repos

eval "$(starship init bash)"
eval "$(gh copilot alias -- bash)"

alias k=kubectl
complete -o default -F __start_kubectl k
```

Write to `/home/dough/repos/exercises/dotfiles/.bashrc`.

- [ ] **Step 2: Verify diff from current repo version**

```bash
cd /home/dough/repos/exercises/dotfiles
git diff .bashrc
```

Confirm that machine-specific lines (REPOS=/media/dough/Storage/repos, PATH exports, OTEL vars, cargo, copilotv, sonarqube, opencode PATH) are removed.

- [ ] **Step 3: Commit**

```bash
cd /home/dough/repos/exercises/dotfiles
git add .bashrc
git commit -m "chore: update .bashrc with portable aliases and completions

Strip machine-specific env vars (PATH, OTEL, cargo, sonarqube,
opencode). Keep generic bash plumbing, ll/la/l/k aliases,
starship init, gh copilot hook, kubectl autocomplete."
```

---

### Task 4: Rewrite .gitconfig

**Files:**
- Modify: `.gitconfig`

- [ ] **Step 1: Write new .gitconfig**

```ini
[alias]
	st = status
	co = checkout
	br = branch
	lg = log --oneline --graph
[core]
	excludesfile = $HOME/.gitignore_global
	editor = vim
	sshCommand = ssh -i ~/.ssh/github -F /dev/null
[pull]
	rebase = true
```

Write to `/home/dough/repos/exercises/dotfiles/.gitconfig`.

- [ ] **Step 2: Verify diff**

```bash
cd /home/dough/repos/exercises/dotfiles
git diff .gitconfig
```

Confirm [user], [sendemail], [credential], [safe] sections are removed.

- [ ] **Step 3: Commit**

```bash
cd /home/dough/repos/exercises/dotfiles
git add .gitconfig
git commit -m "chore: update .gitconfig stripped of identity and secrets

Keep [alias], [core], [pull] only. Remove [user] (name, email,
signingkey), [sendemail] (SMTP creds), [credential] (libsecret,
not macOS-compatible), [safe] (machine-specific paths)."
```

---

### Task 5: Edit .profile

**Files:**
- Modify: `.profile`

- [ ] **Step 1: Remove the `. "$HOME/.cargo/env"` line**

Current line 28 in live `.profile` (but NOT in repo's `.profile` — verify it's absent first):

```bash
cd /home/dough/repos/exercises/dotfiles
grep -n 'cargo' .profile
```

If it's not there (likely), no change needed. If it is, remove it. The repo's `.profile` should be 27 lines ending with the `.local/bin` PATH block.

- [ ] **Step 2: Commit (if changed)**

```bash
cd /home/dough/repos/exercises/dotfiles
git add .profile
git commit -m "chore: clean .profile (drop cargo env line)"
```

If no change was needed, skip this step.

---

### Task 6: Create gh/config.yml

**Files:**
- Create: `.config/gh/config.yml`

- [ ] **Step 1: Write gh/config.yml**

```yaml
# The current version of the config schema
version: 1
# What protocol to use when performing git operations. Supported values: ssh, https
git_protocol: https
# What editor gh should run when creating issues, pull requests, etc. If blank, will refer to environment.
editor:
# When to interactively prompt. This is a global config that cannot be overridden by hostname. Supported values: enabled, disabled
prompt: enabled
# A pager program to send command output to, e.g. "less". If blank, will refer to environment. Set the value to "cat" to disable the pager.
pager:
# Aliases allow you to create nicknames for gh commands
aliases:
    co: pr checkout
# The path to a unix socket through which send HTTP connections. If blank, HTTP traffic will be handled by net/http.DefaultTransport.
http_unix_socket:
# What web browser gh should use when opening URLs. If blank, will refer to environment.
browser:
```

Write to `/home/dough/repos/exercises/dotfiles/.config/gh/config.yml`.

- [ ] **Step 2: Commit**

```bash
cd /home/dough/repos/exercises/dotfiles
git add .config/gh/config.yml
git commit -m "chore: add gh CLI config"
```

---

### Task 7: Create gh-copilot/config.yml

**Files:**
- Create: `.config/gh-copilot/config.yml`

- [ ] **Step 1: Write gh-copilot/config.yml**

```yaml
optional_analytics: true
suggest_execute_confirm_default: false
```

Write to `/home/dough/repos/exercises/dotfiles/.config/gh-copilot/config.yml`.

- [ ] **Step 2: Commit**

```bash
cd /home/dough/repos/exercises/dotfiles
git add .config/gh-copilot/config.yml
git commit -m "chore: add gh-copilot CLI config"
```

---

### Task 8: Create opencode/opencode.jsonc

**Files:**
- Create: `.config/opencode/opencode.jsonc`

- [ ] **Step 1: Ensure directory exists**

```bash
mkdir -p /home/dough/repos/exercises/dotfiles/.config/opencode
```

- [ ] **Step 2: Write opencode.jsonc**

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": ["~/.copilot/instructions/*.instructions.md"],
  "skills": {
    "paths": [
      "~/.copilot/skills/commit-atomically",
      "~/.copilot/skills/find-docs",
      "~/.copilot/skills/how-to-guide",
      "~/.copilot/skills/write-explainer",
      "~/.copilot/skills/write-tutorial",
      "~/.copilot/skills/screenshot-chrome-tab",
      "~/.copilot/skills/screenshot-flameshot",
      "~/.copilot/skills/sre-postmortem",
      "~/.copilot/skills/system-architecture-explainer",
      "~/.copilot/installed-plugins/anthropic-agent-skills/example-skills/skills/skill-creator",
      "~/.copilot/skills/developing-bpftrace-scripts"
    ]
  },
  "plugin": [
    "superpowers@git+https://github.com/obra/superpowers.git",
    "opencode-history-search"
  ],
  "mcp": {
    "agent-o11y-feedback-mcp-grafana-test": {
      "type": "remote",
      "url": "http://localhost:18000/mcp",
      "enabled": false,
    }
  }
}
```

Write to `/home/dough/repos/exercises/dotfiles/.config/opencode/opencode.jsonc`.

- [ ] **Step 3: Commit**

```bash
cd /home/dough/repos/exercises/dotfiles
git add .config/opencode/opencode.jsonc
git commit -m "chore: add opencode config"
```

---

### Task 9: Create curated VS Code settings.json

**Files:**
- Modify: `.config/Code/User/settings.json`

- [ ] **Step 1: Write curated portable settings.json**

Portable subset from union of Stable + Insiders, machine paths stripped:

```json
{
    "editor.minimap.enabled": false,
    "editor.mouseWheelZoom": true,
    "files.autoSave": "afterDelay",
    "files.exclude": {
        "**/.trunk/*out": true,
        "**/.trunk/*out/": true,
        "**/.trunk/*actions/": true,
        "**/.trunk/*logs/": true,
        "**/.trunk/*plugins/": true,
        "**/.trunk/*notifications/": true
    },
    "files.watcherExclude": {
        "**/.trunk/*out": true,
        "**/.trunk/*out/": true,
        "**/.trunk/*actions/": true,
        "**/.trunk/*logs/": true,
        "**/.trunk/*plugins/": true,
        "**/.trunk/*notifications/": true
    },
    "workbench.colorTheme": "Default Dark+",
    "window.customTitleBarVisibility": "auto",
    "explorer.confirmDragAndDrop": false,
    "diffEditor.ignoreTrimWhitespace": false,
    "diffEditor.hideUnchangedRegions.enabled": true,
    "editor.mouseWheelZoom": true,
    "git.confirmSync": false,
    "git.autofetch": true,
    "git.openRepositoryInParentFolders": "never",
    "git.blame.editorDecoration.enabled": false,
    "git.blame.statusBarItem.enabled": true,
    "github.copilot.enable": {
        "*": true,
        "plaintext": false,
        "markdown": true,
        "scminput": false,
        "python": false
    },
    "github.copilot.advanced": {
        "debug.overrideLogLevels": {
           "*": "DEBUG"
        }
    },
    "github.copilot.nextEditSuggestions.enabled": true,
    "github.copilot.chat.copilotMemory.enabled": true,
    "chat.agent.maxRequests": 28,
    "chat.mcp.gallery.enabled": true,
    "chat.mcp.autostart": "never",
    "chat.useAgentSkills": true,
    "chat.tools.terminal.autoApprove": {
        "chmod": { "approve": true, "matchCommandLine": true },
        "git status": true,
        "pytest": true,
        "uv sync": true
    },
    "chat.tools.urls.autoApprove": {
        "https://github.com": { "approveRequest": false, "approveResponse": true },
        "https://opentelemetry.io": true
    },
    "chat.viewSessions.orientation": "stacked",
    "terminal.integrated.fontSize": 14,
    "terminal.integrated.fontFamily": "Hasklug Nerd Font",
    "terminal.integrated.stickyScroll.enabled": false,
    "terminal.integrated.scrollback": 10000,
    "terminal.integrated.shellIntegration.history": 1000,
    "terminal.integrated.suggest.enabled": false,
    "terminal.integrated.suggest.providers": { "vscode.terminal-suggest": false },
    "terminal.integrated.suggest.suggestOnTriggerCharacters": false,
    "debug.onTaskErrors": "debugAnyway",
    "debug.disassemblyView.showSourceCode": false,
    "cSpell.userWords": [
        "behaviour",
        "doughgle",
        "douglashellinger",
        "Hellinger"
    ],
    "markdown.marp.exportType": "html",
    "markdown.marp.enableHtml": true,
    "python.analysis.typeCheckingMode": "basic",
    "python.terminal.activateEnvInCurrentTerminal": true,
    "yaml.schemas": {
        "http://schema.cloudcustodian.io/v0/custodian.json": "query*.yml",
        "https://json.schemastore.org/bamboo-spec.json": "bamboo-spec"
    },
    "[python]": {
        "editor.defaultFormatter": "ms-python.python",
        "editor.formatOnType": true
    },
    "[yaml]": {
        "editor.defaultFormatter": "redhat.vscode-yaml"
    },
    "[jsonc]": {
        "editor.defaultFormatter": "vscode.json-language-features"
    },
    "[json]": {
        "editor.defaultFormatter": "vscode.json-language-features"
    },
    "[html]": {
        "editor.defaultFormatter": "vscode.html-language-features"
    },
    "[terraform]": {},
    "files.associations": {
        "*.md": "markdown"
    },
    "settingsSync.ignoredExtensions": [
        "trunk.io"
    ],
    "outline.collapseItems": "alwaysCollapse",
    "docker.images.sortBy": "Size",
    "containers.images.sortBy": "Size",
    "remote.containers.logLevel": "trace",
    "hediet.vscode-drawio.appearance": "automatic",
    "hediet.vscode-drawio.codeLinkActivated": false,
    "accessibility.verbosity.inlineChat": false,
    "inlineChat.holdToSpeech": false,
    "inlineChat.experimental.textButtons": true,
    "inlineChat.experimental.enableZoneToolbar": true
}
```

Write to `/home/dough/repos/exercises/dotfiles/.config/Code/User/settings.json`.

- [ ] **Step 2: Verify no machine-specific paths remain**

```bash
cd /home/dough/repos/exercises/dotfiles
rg 'shellcheck|trivy\.binaryPath|condaPath|defaultInterpreterPath|crash-reporter|zoomLevel|profiles\.osx' .config/Code/User/settings.json || echo "Clean - no machine paths found"
```

- [ ] **Step 3: Commit**

```bash
cd /home/dough/repos/exercises/dotfiles
git add .config/Code/User/settings.json
git commit -m "chore: add curated VS Code settings (portable subset)

Union of Stable + Insiders. Machine paths stripped (shellcheck,
conda, trivy, profiles.osx, zoomLevel, crash-reporter)."
```

---

### Task 10: Create curated VS Code keybindings.json

**Files:**
- Modify: `.config/Code/User/keybindings.json`

- [ ] **Step 1: Write curated portable keybindings.json**

Union of Stable + Insiders keybindings:

```json
// Place your key bindings in this file to override the defaults
[
    {
        "key": "shift+enter",
        "command": "workbench.action.terminal.sendSequence",
        "when": "terminalFocus",
        "args": {
            "text": "\u001b\r"
        }
    },
    {
        "key": "ctrl+shift+alt+c",
        "command": "cmantic.updateSignature",
        "when": "editorTextFocus"
    },
    {
        "key": "meta+.",
        "command": "emojisense.quickEmoji",
        "when": "editorTextFocus"
    },
    {
        "key": "ctrl+i",
        "command": "-emojisense.quickEmoji",
        "when": "editorTextFocus"
    },
    {
        "key": "alt+shift+e",
        "command": "extension.eclipseKeymap",
        "when": "editorTextFocus"
    },
    {
        "key": "ctrl+shift+t",
        "command": "-workbench.action.reopenClosedEditor"
    },
    {
        "key": "ctrl+shift+o",
        "command": "outlineEclipsed.focus"
    },
    {
        "key": "ctrl+i",
        "command": "-markdown.extension.editing.toggleItalic",
        "when": "editorTextFocus && !editorReadonly && editorLangId =~ /^markdown$|^rmd$|^quarto$/"
    },
    {
        "key": "ctrl+p",
        "command": "-workbench.action.quickOpenNavigateNextInFilePicker",
        "when": "inFilesPicker && inQuickOpen"
    },
    {
        "key": "ctrl+p",
        "command": "-workbench.action.quickOpenNavigateNextInFilePicker",
        "when": "inFilesPicker && inQuickOpen"
    }
]
```

Write to `/home/dough/repos/exercises/dotfiles/.config/Code/User/keybindings.json`.

- [ ] **Step 2: Commit**

```bash
cd /home/dough/repos/exercises/dotfiles
git add .config/Code/User/keybindings.json
git commit -m "chore: add curated VS Code keybindings (portable subset)

Union of Stable + Insiders keybindings."
```

---

### Task 11: Rewrite setup.sh

**Files:**
- Modify: `setup.sh`

- [ ] **Step 1: Write setup.sh**

```bash
#!/bin/bash
set -euo pipefail

# ============================================================================
# Dotfiles Setup — copy-based bootstrap for fresh Ubuntu/macOS machines
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME="${HOME:-$HOME}"
OK=0
SKIP=0
FAIL=0

detect_os() {
    case "$(uname -s)" in
        Linux*)  echo "linux" ;;
        Darwin*) echo "darwin" ;;
        *)       echo "unknown" ;;
    esac
}

copy_file() {
    local src="$1" dst="$2"
    if [ ! -f "$src" ] && [ ! -d "$src" ]; then
        echo "  [FAIL] Source not found: $src"
        FAIL=$((FAIL + 1))
        return
    fi
    if [ -e "$dst" ]; then
        if diff -q "$src" "$dst" >/dev/null 2>&1; then
            echo "  [SKIP] $dst (identical)"
            SKIP=$((SKIP + 1))
            return
        fi
        echo "  Overwrite $dst? [y/N] "
        read -r response
        case "$response" in
            y|Y|yes|Yes) ;;
            *)
                echo "  [SKIP] $dst"
                SKIP=$((SKIP + 1))
                return
                ;;
        esac
    fi
    mkdir -p "$(dirname "$dst")"
    if cp -r "$src" "$dst"; then
        echo "  [OK] $dst"
        OK=$((OK + 1))
    else
        echo "  [FAIL] cp $src -> $dst"
        FAIL=$((FAIL + 1))
    fi
}

OS="$(detect_os)"
echo "Detected OS: $OS"
echo ""

# Dotfiles at repo root
echo "--- Installing dotfiles ---"
copy_file "$SCRIPT_DIR/.bashrc"         "$HOME/.bashrc"
copy_file "$SCRIPT_DIR/.gitconfig"      "$HOME/.gitconfig"
copy_file "$SCRIPT_DIR/.profile"        "$HOME/.profile"
copy_file "$SCRIPT_DIR/.vale.ini"       "$HOME/.vale.ini"
copy_file "$SCRIPT_DIR/.vale"           "$HOME/.vale"

# .config tool configs
echo "--- Installing tool configs ---"
copy_file "$SCRIPT_DIR/.config/starship.toml"       "$HOME/.config/starship.toml"
copy_file "$SCRIPT_DIR/.config/fish/config.fish"    "$HOME/.config/fish/config.fish"
copy_file "$SCRIPT_DIR/.config/gh/config.yml"       "$HOME/.config/gh/config.yml"
copy_file "$SCRIPT_DIR/.config/gh-copilot/config.yml" "$HOME/.config/gh-copilot/config.yml"
copy_file "$SCRIPT_DIR/.config/opencode"            "$HOME/.config/opencode"
copy_file "$SCRIPT_DIR/.config/Code/User/settings.json"  "$HOME/.config/Code/User/settings.json"
copy_file "$SCRIPT_DIR/.config/Code/User/keybindings.json" "$HOME/.config/Code/User/keybindings.json"

# Fonts
echo "--- Installing fonts ---"
copy_file "$SCRIPT_DIR/.fonts" "$HOME/.fonts"

# Clone personal-agent-stdlib (non-blocking)
echo "--- Setting up agent stdlib ---"
if [ -d "$HOME/.copilot" ]; then
    echo "  [SKIP] ~/.copilot already exists"
    SKIP=$((SKIP + 1))
else
    echo "  Cloning personal-agent-stdlib to ~/.copilot ..."
    if git clone https://github.com/doughgle/personal-agent-stdlib.git "$HOME/.copilot" 2>/dev/null; then
        echo "  [OK] Cloned personal-agent-stdlib"
        OK=$((OK + 1))
    else
        echo "  [WARN] Could not clone personal-agent-stdlib (network? access?)"
        echo "         Clone manually: git clone https://github.com/doughgle/personal-agent-stdlib.git ~/.copilot"
    fi
fi

echo ""
echo "============================================"
echo " Setup complete: $OK copied, $SKIP skipped, $FAIL failed"
echo "============================================"
```

Write to `/home/dough/repos/exercises/dotfiles/setup.sh`. Make executable:

```bash
chmod +x /home/dough/repos/exercises/dotfiles/setup.sh
```

- [ ] **Step 2: Commit**

```bash
cd /home/dough/repos/exercises/dotfiles
git add setup.sh
git commit -m "feat: add copy-based setup.sh bootstrap script

Detects OS (linux/darwin), copies files to XDG locations,
prompts before overwriting existing files, tries cloning
personal-agent-stdlib (non-blocking). Prints [OK]/[SKIP]/[FAIL]/[WARN]
per action."
```

---

### Task 12: Final verification

- [ ] **Step 1: Verify tracked file listing**

```bash
cd /home/dough/repos/exercises/dotfiles
git ls-files | sort
```

Expected tree:

```
.bashrc
.config/Code/User/keybindings.json
.config/Code/User/settings.json
.config/fish/config.fish
.config/gh-copilot/config.yml
.config/gh/config.yml
.config/opencode/opencode.jsonc
.config/starship.toml
.devcontainer.json
.fonts/Hasklug-Black-Italic-Nerd-Font-Complete-Mono-Windows-Compatible.otf
.fonts/LICENSE.md
.fonts/readme.md
.gitconfig
.gitignore
.profile
.vale/styles/...
.vale.ini
LICENSE
setup.sh
```

No `.k3d/`, no `.vscode/`, no cache dirs, no `.fonts/.uuid`.

- [ ] **Step 2: Verify no secrets in tracked files**

```bash
cd /home/dough/repos/exercises/dotfiles
# Check for leaked secrets. Expected: only git_protocol: https from gh/config.yml is benign.
# The gitconfig should NOT have [user] or [sendemail] sections.
grep -n '^\[user\]\|^\[sendemail\]\|@\|signingkey\|smtp\|password' \
  .gitconfig .config/gh/config.yml .config/gh-copilot/config.yml \
  .config/opencode/opencode.jsonc || echo "Clean — no secrets found in tracked configs"
```

Expected: only `git_protocol: https` from gh/config.yml (benign).

- [ ] **Step 3: Verify setup.sh is executable**

```bash
test -x setup.sh && echo "setup.sh is executable"
```
