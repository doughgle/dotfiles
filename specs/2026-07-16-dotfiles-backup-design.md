# Dotfiles Backup Design

## Goal

Export a portable subset of `~` dotfiles and `~/.config/` tool configs into the existing
`/home/dough/repos/exercises/dotfiles` repo so they can be copied onto fresh Ubuntu or macOS
machines. No secrets, no personal accounts, no cache/state data. Repo cleanup only — home
directory untouched.

## Repo Layout (XDG-compatible, keep current structure)

```
.bashrc                  # aliases + completions only (no machine-specific env vars)
.gitconfig                # [alias], [core], [pull] only (no [user], [sendemail], [safe], [credential])
.profile                  # keep, drop cargo line
.gitignore (NEW)          # secret file patterns
setup.sh (REWRITE)        # copy-based bootstrap

.config/
├── starship.toml         # keep (already in sync)
├── fish/config.fish      # keep
├── gh/config.yml         (NEW) — gh CLI aliases + protocol
├── gh-copilot/config.yml (NEW) — copilot CLI prefs
├── opencode/opencode.jsonc  (NEW) — opencode config
├── copyq/
│   ├── copyq.conf          (NEW) — settings, theme, shortcuts, plugins
│   ├── copyq-commands.ini  (NEW) — user commands (pin, tag, image sort)
│   ├── copyq_tabs.ini      (NEW) — tab layout state
│       └── prompts.txt         (NEW) — 5 prompts combined, plaintext, `=====` sep
└── Code/User/
    ├── settings.json     (NEW) — curated portable subset (Stable+Insiders union, machine paths stripped)
    └── keybindings.json  (NEW) — curated portable subset

.fonts/
├── Hasklug-Black-Italic-Nerd-Font-Complete-Mono-Windows-Compatible.otf
├── ... (56 Nerd Font OTF files total)
├── LICENSE.md
└── readme.md

.vale.ini, .vale/, .devcontainer.json, LICENSE   # keep as-is
```

## Files to REMOVE from repo (cache/state/secrets — 41 entries, ~6.6GB)

All exist as stale data from original commit. Home dir is untouched.

| Path | Reason |
|------|--------|
| `.k3d/` | Kubeconfigs (secrets) |
| `.vscode/` | Extension binaries (1.1G) |
| `.fonts/.uuid` | Fontconfig cache marker |
| `.config/google-chrome/` | Full Chrome browser profile (3.1G) |
| `.config/Code/` (keep `User/` only) | VS Code caches/blobs/extensions (1.4G) |
| `.config/Code - Insiders/` (keep `User/` only) | VS Code Insiders caches (1.2G) |
| `.config/com.psiexams.psi-bridge-secure-browser/` | Exam browser data |
| `.config/Microsoft/` | Teams/Edge data |
| `.config/PSI Bridge Secure Browser/` | Exam browser |
| `.config/libreoffice/`, `.config/GIMP/`, `.config/wireshark/` | App config+state |
| `.config/copyq/` (keep `copyq.conf`, `copyq-commands.ini`, `copyq_tabs.ini`, `prompts.txt`; remove `*_tab_*.dat`, `copyq.pub`, `copyq.lock`, `.copyq_s`) | Clipboard runtime state; config + prompts tracked separately |
| `.config/pulse/` | Audio runtime state |
| `.config/teams/` | Teams config |
| `.config/evolution/` | Email config (may contain accounts) |
| `.config/dconf/` | GNOME binary database |
| `.config/ibus/` | Input bus state |
| `.config/evince/`, `.config/nautilus/`, `.config/menus/` | App state/cache |
| `.config/guake/` | Terminal config |
| `.config/gtk-3.0/`, `.config/gtk-2.0/` | GTK settings |
| `.config/goa-1.0/` | Online accounts |
| `.config/gedit/`, `.config/eog/` | App config |
| `.config/configstore/`, `.config/Rygel/` | Node/media config |
| `.config/sh.loft.devpod/`, `.config/hardhat-nodejs/` | Dev env config |
| `.config/md-publisher/`, `.config/helm/` | App config |
| `.config/autostart/` | Desktop autostart (GNOME-specific) |
| `.config/cef_user_data/`, `.config/gnome-session/` | Empty |
| `.config/enchant/`, `.config/update-notifier/` | Empty |
| `.config/procps/`, `.config/Microsoft Teams - Preview/` | Empty |
| `.config/yelp/` | Empty |

## File Contents

### `.bashrc` — aliases + completions only

Generic bash plumbing (HISTCONTROL, HISTSIZE, histappend, checkwinsize,
lesspipe, color prompt with conditionals, programmable completion boilerplate).

Aliases: `ll='ls -alF'`, `la='ls -A'`, `l='ls -CF'`, `ls='ls --color=auto'`,
`grep`/`fgrep`/`egrep` color, `alert`, `k=kubectl`.

Hooks: `eval "$(starship init bash)"`, `eval "$(gh copilot alias -- bash)"`.
Autocomplete: `complete -o default -F __start_kubectl k`.

Removed from live: REPOS path, PATH exports (cargo, sonarqube, opencode,
.local/bin), OTEL env vars, `copilotv` alias, `. "$HOME/.cargo/env"`.

### `.gitconfig` — stripped

```
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

Removed from live: `[user]` (name, email, signingkey), `[sendemail]` (SMTP),
`[credential]` (libsecret — macOS incompatible), `[safe]` (machine paths).

### `.profile`

Keep repo version (27 lines). Just drop the `. "$HOME/.cargo/env"` line
that exists in live but not in repo.

### `.gitignore` — new

```
*.pem
*.env
*.key
*kubeconfig*
*secret*
*credential*
*token*
.k3d/
```

### VS Code `settings.json` — curated portable subset

Union of Stable (280 lines) and Insiders (216 lines), machine paths stripped.

**Include:** theme, mouseWheelZoom, autoSave, fontSize, minimap, scrollback,
copilot settings (enable, chat, nextEditSuggestions, copilotMemory),
chat settings (agent.maxRequests, mcp.gallery, useAgentSkills, autoApprove),
diffEditor, editor prefs, files.autoSave, git, cSpell.userWords,
debug, markdown.marp, python.analysis.typeCheckingMode,
terminal.integrated.fontSize, yaml.schemas, workbench.colorTheme.

**Exclude:** bashIde.shellcheckPath, python.condaPath,
python.defaultInterpreterPath, trivy.binaryPath, vs-kubernetes,
terminal.integrated.profiles.osx, window.zoomLevel, comments.

### VS Code `keybindings.json` — curated portable subset

Union of Stable (43 lines) and Insiders (25 lines). All entries portable.

### `.config/gh/config.yml`

```yaml
git_protocol: https
aliases:
  co: pr checkout
```

### `.config/gh-copilot/config.yml`

```yaml
optional_analytics: true
suggest_execute_confirm_default: false
```

### `.config/opencode/opencode.jsonc`

Live config. Disabled MCP server for mcp-grafana-test (port 18000,
devcontainer-bound) kept as-is. Skill paths resolve to `~/.copilot/`.

### `.config/copyq/` — portable config + exported prompts

**Include (config):** `copyq.conf` (247 lines — all settings, theme, shortcuts, tabs,
plugin config; no machine paths, no secrets), `copyq-commands.ini` (10 user commands:
Pin/Unpin, Tag/Untag, Move Images to "&Images" tab, Show window under cursor via
`Alt+Shift+C`), `copyq_tabs.ini` (tab widget layout: `&clipboard`, `urls`, `prompts`,
`&Images`).

**Include (prompts):** `prompts.txt` — 5 plaintext items exported from the `prompts`
clipboard tab via CopyQ CLI. Safe reusable AI coding prompts (implementation queries,
debugging checklist, GitHub issue feedback, joke curator). No secrets.

**Exclude:** All `*_tab_*.dat` (binary clipboard history — contains API keys, tokens,
passwords), `copyq.lock` (transient PID lock), `.copyq_s` (IPC socket), `copyq.pub`
(encryption plugin public key), `~/.local/share/copyq/` (raw item blob store, 13 MB).

### `setup.sh` — copy-based bootstrap

```
1. Detect OS (uname → linux|darwin)
2. For each tracked file:
   - If target does NOT exist in ~: copy silently, print [OK]
   - If target exists AND differs: prompt [y/N], print [OK] or [SKIP]
   - If copy fails: print [FAIL] <reason>
3. Copy sequence:
   .bashrc → ~/.bashrc
   .gitconfig → ~/.gitconfig
   .profile → ~/.profile
   .config/{gh,gh-copilot,opencode,copyq,Code/User,starship.toml,fish} → ~/.config/
   .fonts/ → ~/.fonts/
   .vale.ini + .vale/ → ~/
4. Import CopyQ prompts from prompts.txt into CopyQ's prompts tab via copyq CLI
   (skips if tab already has items, warns if copyq not installed) [non-blocking]
5. Try git clone https://github.com/doughgle/personal-agent-stdlib.git ~/.copilot
   [OK] on success, [WARN] on failure (non-blocking)
6. Print summary: "N copied, N skipped, N failed"
```

## Decisions Log

| Decision | Choice |
|----------|--------|
| Gitconfig scope | Strip [user], [sendemail], [safe], [credential] |
| gh/hosts.yml | Skip |
| VS Code strategy | Curated portable superset from Stable+Insiders |
| Bashrc scope | Aliases + completions only (no copilotv alias) |
| Config dirs scope | Dev tools only |
| Agent-stdlib repo | Try clone, non-blocking |
| Setup mechanism | Copy-based, not symlinks/chezmoi |
| Platform handling | OS detection in setup.sh |
| Repo structure | Keep current XDG layout |
| Credential helper | Drop (platform-incompatible) |
| Overwrite behavior | Prompt only if target exists and differs |
| Cache cleanup | Repo only, home dir untouched |
| Setup.sh failures | Explicit [OK]/[WARN]/[FAIL] per action |
| Fonts | Track all 56 OTF files + docs, remove .uuid |
| CopyQ config scope | Include copyq.conf, copyq-commands.ini, copyq_tabs.ini (no clipboard history); export prompts tab as combined plaintext prompts.txt, import via copyq CLI in setup.sh |
