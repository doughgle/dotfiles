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
