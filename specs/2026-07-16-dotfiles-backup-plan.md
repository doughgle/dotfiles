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
| CREATE | `.config/copyq/copyq.conf` | CopyQ settings, theme, shortcuts, plugins |
| CREATE | `.config/copyq/copyq-commands.ini` | CopyQ user commands (pin, tag, image sort) |
| CREATE | `.config/copyq/copyq_tabs.ini` | CopyQ tab layout (4 tabs) |
| CREATE | `.config/copyq/prompts.txt`              | 5 prompts exported from CopyQ, plaintext |
| REWRITE | `.config/Code/User/settings.json` | Curated portable VS Code settings |
| REWRITE | `.config/Code/User/keybindings.json` | Curated portable VS Code keybindings |
| REWRITE | `setup.sh` | Copy-based bootstrap script |

---

### Task 1: Remove cache/state/secrets directories from repo

**Files:**
- Delete: `.k3d/` (tracked: `k3d-default.yaml`; rest untracked)
- Delete: `.vscode/` (entirely untracked)
- Delete: `.fonts/.uuid` (untracked)
- Delete: `.config/google-chrome/` (untracked)
- Delete: `.config/Code/` cache subdirs (untracked — keep `User/`)
- Delete: `.config/Code - Insiders/` cache subdirs (untracked — keep `User/`)
- Delete: all remaining `.config/*` cache dirs (untracked) EXCEPT: `starship.toml`, `fish/`, `gh/`, `gh-copilot/`, `opencode/`, `copyq/`, `Code/User/`

Full list of `.config/` dirs to delete:

```
autostart/       cef_user_data/       com.psiexams.psi-bridge-secure-browser/
configstore/     copyq/               dconf/               enchant/
eog/             evince/              evolution/           gedit/
GIMP/            gnome-session/       goa-1.0/             google-chrome/
gtk-2.0/         gtk-3.0/             guake/               hardhat-nodejs/
helm/            ibus/                libreoffice/
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

**Phase A — Delete untracked cache dirs (`rm -rf`, no git involvement)**
Working tree is >6 GB with millions of cache files. `rm -rf` avoids git scanning the tree and triggering OOM.

- [x] **Step 1: Remove .k3d/ (disk cleanup — any untracked files)**

```bash
rm -rf .k3d/
```

- [x] **Step 2: Remove .vscode/ (1.1G — untracked)**

```bash
rm -rf .vscode/
```

- [x] **Step 3: Remove .fonts/.uuid (untracked)**

```bash
rm -rf .fonts/.uuid
```

- [x] **Step 4: Remove .config/google-chrome/ (3.1G — untracked)**

```bash
rm -rf .config/google-chrome/
```

- [x] **Step 5: Remove cache subdirs inside .config/Code/ (untracked — one per line)**

```bash
rm -rf .config/Code/Backups
rm -rf .config/Code/blob_storage
rm -rf .config/Code/Cache
rm -rf .config/Code/CachedConfigurations
rm -rf .config/Code/CachedData
rm -rf .config/Code/CachedExtensionVSIXs
rm -rf .config/Code/CachedExtensions
rm -rf .config/Code/CachedProfilesData
rm -rf .config/Code/Code\ Cache
rm -rf .config/Code/Crashpad
rm -rf .config/Code/databases
rm -rf .config/Code/DawnCache
rm -rf .config/Code/Dictionaries
rm -rf .config/Code/GPUCache
rm -rf .config/Code/IndexedDB
rm -rf .config/Code/Local\ Storage
rm -rf .config/Code/logs
rm -rf .config/Code/Service\ Worker
rm -rf .config/Code/Session\ Storage
rm -rf .config/Code/Shared\ Dictionary
rm -rf .config/Code/WebStorage
rm -rf .config/Code/Workspaces
```

- [x] **Step 6: Remove cache subdirs inside .config/Code - Insiders/ (untracked — one per line)**

```bash
rm -rf .config/Code\ -\ Insiders/Backups
rm -rf .config/Code\ -\ Insiders/blob_storage
rm -rf .config/Code\ -\ Insiders/Cache
rm -rf .config/Code\ -\ Insiders/CachedConfigurations
rm -rf .config/Code\ -\ Insiders/CachedData
rm -rf .config/Code\ -\ Insiders/CachedExtensionVSIXs
rm -rf .config/Code\ -\ Insiders/CachedExtensions
rm -rf .config/Code\ -\ Insiders/CachedProfilesData
rm -rf .config/Code\ -\ Insiders/Code\ Cache
rm -rf .config/Code\ -\ Insiders/Crashpad
rm -rf .config/Code\ -\ Insiders/databases
rm -rf .config/Code\ -\ Insiders/DawnCache
rm -rf .config/Code\ -\ Insiders/Dictionaries
rm -rf .config/Code\ -\ Insiders/GPUCache
rm -rf .config/Code\ -\ Insiders/IndexedDB
rm -rf .config/Code\ -\ Insiders/Local\ Storage
rm -rf .config/Code\ -\ Insiders/logs
rm -rf .config/Code\ -\ Insiders/Service\ Worker
rm -rf .config/Code\ -\ Insiders/Session\ Storage
rm -rf .config/Code\ -\ Insiders/Shared\ Dictionary
rm -rf .config/Code\ -\ Insiders/WebStorage
rm -rf .config/Code\ -\ Insiders/Workspaces
```

- [x] **Step 7: Remove remaining untracked cache dirs under .config/**

```bash
rm -rf .config/autostart/
rm -rf .config/cef_user_data/
rm -rf .config/com.psiexams.psi-bridge-secure-browser/
rm -rf .config/configstore/
rm -f .config/copyq/copyq_tab_*.dat   # clipboard history (secrets)
rm -f .config/copyq/copyq.lock        # runtime lock
rm -f .config/copyq/.copyq_s          # IPC socket
rm -f .config/copyq/copyq.pub         # encryption key
rm -rf .config/dconf/
rm -rf .config/enchant/
rm -rf .config/eog/
rm -rf .config/evince/
rm -rf .config/evolution/
rm -rf .config/gedit/
rm -rf .config/GIMP/
rm -rf .config/gnome-session/
rm -rf .config/goa-1.0/
rm -rf .config/gtk-2.0/
rm -rf .config/gtk-3.0/
rm -rf .config/guake/
rm -rf .config/hardhat-nodejs/
rm -rf .config/helm/
rm -rf .config/ibus/
rm -rf .config/libreoffice/
rm -rf .config/md-publisher/
rm -rf .config/menus/
rm -rf .config/Microsoft/
rm -rf .config/Microsoft\ Teams\ -\ Preview/
rm -rf .config/nautilus/
rm -rf .config/procps/
rm -rf .config/PSI\ Bridge\ Secure\ Browser/
rm -rf .config/pulse/
rm -rf .config/Rygel/
rm -rf .config/sh.loft.devpod/
rm -rf .config/teams/
rm -rf .config/update-notifier/
rm -rf .config/wireshark/
rm -rf .config/yelp/
```

**Phase B — Remove tracked files from git (working tree is now small, safe)**

- [x] **Step 8: Remove tracked .k3d/k3d-default.yaml from git**

```bash
cd /home/dough/repos/exercises/dotfiles
git rm .k3d/k3d-default.yaml
```

Note: if `.k3d/` was already deleted from disk and the deletion staged, this step is already complete.

**Phase C — Verify and commit**

- [x] **Step 9: Verify deletions**

```bash
cd /home/dough/repos/exercises/dotfiles
git status
git diff --cached --stat | tail -20
```

Confirm no cache directories remain on disk and the index reflects all intended deletions.

- [x] **Step 10: Commit**

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

- [x] **Step 1: Create .gitignore**

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

- [x] **Step 2: Commit**

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

- [x] **Step 1: Write new .bashrc**

Contents: generic bash plumbing (HISTCONTROL, HISTSIZE, histappend, checkwinsize, lesspipe, color prompt with conditionals, programmable completion boilerplate) plus these custom additions at the bottom:

```bash
export REPOS=/home/dough/repos

eval "$(starship init bash)"
eval "$(gh copilot alias -- bash)"

alias k=kubectl
complete -o default -F __start_kubectl k
```

Write to `/home/dough/repos/exercises/dotfiles/.bashrc`.

- [x] **Step 2: Verify diff from current repo version**

```bash
cd /home/dough/repos/exercises/dotfiles
git diff .bashrc
```

Confirm that machine-specific lines (REPOS=/media/dough/Storage/repos, PATH exports, OTEL vars, cargo, copilotv, sonarqube, opencode PATH) are removed.

- [x] **Step 3: Commit**

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

- [x] **Step 1: Write new .gitconfig**

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

- [x] **Step 2: Verify diff**

```bash
cd /home/dough/repos/exercises/dotfiles
git diff .gitconfig
```

Confirm [user], [sendemail], [credential], [safe] sections are removed.

- [x] **Step 3: Commit**

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

- [x] **Step 1: Remove the `. "$HOME/.cargo/env"` line**

Current line 28 in live `.profile` (but NOT in repo's `.profile` — verify it's absent first):

```bash
cd /home/dough/repos/exercises/dotfiles
grep -n 'cargo' .profile
```

If it's not there (likely), no change needed. If it is, remove it. The repo's `.profile` should be 27 lines ending with the `.local/bin` PATH block.

- [x] **Step 2: Commit (if changed) — skipped, no cargo line found**

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

- [x] **Step 1: Write gh/config.yml**

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

- [x] **Step 2: Commit**

```bash
cd /home/dough/repos/exercises/dotfiles
git add .config/gh/config.yml
git commit -m "chore: add gh CLI config"
```

---

### Task 7: Create gh-copilot/config.yml

**Files:**
- Create: `.config/gh-copilot/config.yml`

- [x] **Step 1: Write gh-copilot/config.yml**

```yaml
optional_analytics: true
suggest_execute_confirm_default: false
```

Write to `/home/dough/repos/exercises/dotfiles/.config/gh-copilot/config.yml`.

- [x] **Step 2: Commit**

```bash
cd /home/dough/repos/exercises/dotfiles
git add .config/gh-copilot/config.yml
git commit -m "chore: add gh-copilot CLI config"
```

---

### Task 8: Create opencode/opencode.jsonc

**Files:**
- Create: `.config/opencode/opencode.jsonc`

- [x] **Step 1: Ensure directory exists**

```bash
mkdir -p /home/dough/repos/exercises/dotfiles/.config/opencode
```

- [x] **Step 2: Write opencode.jsonc**

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

- [x] **Step 3: Commit**

```bash
cd /home/dough/repos/exercises/dotfiles
git add .config/opencode/opencode.jsonc
git commit -m "chore: add opencode config"
```

---

### Task 9: Create curated VS Code settings.json

**Files:**
- Modify: `.config/Code/User/settings.json`

- [x] **Step 1: Write curated portable settings.json**

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

- [x] **Step 2: Verify no machine-specific paths remain**

```bash
cd /home/dough/repos/exercises/dotfiles
rg 'shellcheck|trivy\.binaryPath|condaPath|defaultInterpreterPath|crash-reporter|zoomLevel|profiles\.osx' .config/Code/User/settings.json || echo "Clean - no machine paths found"
```

- [x] **Step 3: Commit**

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

- [x] **Step 1: Write curated portable keybindings.json**

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

- [x] **Step 2: Commit**

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

- [x] **Step 1: Write setup.sh**

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
copy_file "$SCRIPT_DIR/.config/copyq/copyq.conf"         "$HOME/.config/copyq/copyq.conf"
copy_file "$SCRIPT_DIR/.config/copyq/copyq-commands.ini" "$HOME/.config/copyq/copyq-commands.ini"
copy_file "$SCRIPT_DIR/.config/copyq/copyq_tabs.ini"     "$HOME/.config/copyq/copyq_tabs.ini"
copy_file "$SCRIPT_DIR/.config/Code/User/settings.json"  "$HOME/.config/Code/User/settings.json"
copy_file "$SCRIPT_DIR/.config/Code/User/keybindings.json" "$HOME/.config/Code/User/keybindings.json"

# Fonts
echo "--- Installing fonts ---"
copy_file "$SCRIPT_DIR/.fonts" "$HOME/.fonts"

# CopyQ prompts import (requires CopyQ to be running)
echo "--- Importing CopyQ prompts ---"
if command -v copyq &>/dev/null; then
    PROMPTS_FILE="$SCRIPT_DIR/.config/copyq/prompts.txt"
    if [ -f "$PROMPTS_FILE" ]; then
        COUNT=$(copyq "tab('prompts'); count()" 2>/dev/null || echo 0)
        if [ "$COUNT" -gt 0 ]; then
            echo "  [SKIP] CopyQ 'prompts' tab already has $COUNT items"
            SKIP=$((SKIP + 1))
        else
            awk 'BEGIN{i=0} /^=====$/ {i++; next} {print > "/tmp/copyq_prompt_" i ".txt"}' "$PROMPTS_FILE"
            IMP=0
            for f in /tmp/copyq_prompt_*.txt; do
                content=$(cat "$f")
                if [ -n "$content" ] && copyq "tab('prompts'); add('$content')" 2>/dev/null; then
                    IMP=$((IMP + 1))
                fi
            done
            rm -f /tmp/copyq_prompt_*.txt
            echo "  [OK] Imported $IMP prompts into CopyQ 'prompts' tab"
            OK=$((OK + IMP))
        fi
    else
        echo "  [SKIP] prompts.txt not found"
        SKIP=$((SKIP + 1))
    fi
else
    echo "  [WARN] copyq CLI not found — skip prompt import"
fi

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

- [x] **Step 2: Commit**

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

- [x] **Step 1: Verify tracked file listing**

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
.config/copyq/copyq.conf
.config/copyq/copyq-commands.ini
.config/copyq/copyq_tabs.ini
.config/copyq/prompts.txt
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

- [x] **Step 2: Verify no secrets in tracked files**

```bash
cd /home/dough/repos/exercises/dotfiles
# Check for leaked secrets. Expected: only git_protocol: https from gh/config.yml is benign.
# The gitconfig should NOT have [user] or [sendemail] sections.
grep -n '^\[user\]\|^\[sendemail\]\|@\|signingkey\|smtp\|password' \
  .gitconfig .config/gh/config.yml .config/gh-copilot/config.yml \
  .config/opencode/opencode.jsonc .config/copyq/copyq.conf \
  .config/copyq/copyq-commands.ini || echo "Clean — no secrets found in tracked configs"
```

Expected: only `git_protocol: https` from gh/config.yml (benign).

- [x] **Step 3: Verify setup.sh is executable**

```bash
test -x setup.sh && echo "setup.sh is executable"
```

---

### Task 13: Create CopyQ portable config and exported prompts

**Files:**
- Create: `.config/copyq/copyq.conf`
- Create: `.config/copyq/copyq-commands.ini`
- Create: `.config/copyq/copyq_tabs.ini`
- Create: `.config/copyq/prompts.txt`

- [ ] **Step 1: Ensure dirs exist**

```bash
mkdir -p /home/dough/repos/exercises/dotfiles/.config/copyq
```

- [ ] **Step 2: Write copyq.conf**

Contents from `~/.config/copyq/copyq.conf` (247 lines). Portable — no machine paths or secrets.

- [ ] **Step 3: Write copyq-commands.ini**

Contents from `~/.config/copyq/copyq-commands.ini` (53 lines). 10 user commands: Pin/Unpin, Tag/Untag, Move Images to "&Images" tab, Show window via `Alt+Shift+C`.

- [ ] **Step 4: Write copyq_tabs.ini**

Contents from `~/.config/copyq/copyq_tabs.ini` (3 lines). Tab widget state.

- [ ] **Step 5: Export prompts tab items as plaintext**

```bash
cd /home/dough/repos/exercises/dotfiles
count=$(copyq "tab('prompts'); count()")
> .config/copyq/prompts.txt
for i in $(seq 0 $((count - 1))); do
    copyq "tab('prompts'); read($i)" >> .config/copyq/prompts.txt
    echo "" >> .config/copyq/prompts.txt
    echo "=====" >> .config/copyq/prompts.txt
done
```

- [ ] **Step 6: Verify no secrets in tracked files**

```bash
rg 'sk-or|ghp_|token|password|secret|key' .config/copyq/ || echo "Clean — no secrets"
```

- [ ] **Step 7: Commit**

```bash
cd /home/dough/repos/exercises/dotfiles
git add .config/copyq/
git commit -m "chore: add CopyQ portable config and plaintext prompt exports"
```
