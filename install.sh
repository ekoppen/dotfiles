#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  Dotfiles Installer                                             ║
# ║  Detects OS, backs up existing configs, creates symlinks        ║
# ╚══════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ─── Config ───────────────────────────────────────────────────────

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"
OS="$(uname -s)"

# ─── Colors ───────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}●${NC} $1"; }
success() { echo -e "${GREEN}✔${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC} $1"; }
error()   { echo -e "${RED}✖${NC} $1"; }

# ─── Helpers ──────────────────────────────────────────────────────

backup_and_link() {
    local source="$1"
    local target="$2"
    local target_dir
    target_dir="$(dirname "$target")"

    # Create parent directory if needed
    if [[ ! -d "$target_dir" ]]; then
        mkdir -p "$target_dir"
        info "Created directory: $target_dir"
    fi

    # Back up existing file/symlink
    if [[ -e "$target" || -L "$target" ]]; then
        mkdir -p "$BACKUP_DIR"
        local backup_path="$BACKUP_DIR/$(basename "$target")"
        cp -rL "$target" "$backup_path" 2>/dev/null || true
        rm -rf "$target"
        warn "Backed up existing $(basename "$target") → $BACKUP_DIR/"
    fi

    # Create symlink
    ln -sf "$source" "$target"
    success "Linked $(basename "$target") → $source"
}

# ─── Header ───────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}🏠 Dotfiles Installer${NC}"
echo -e "   OS detected: ${BOLD}$OS${NC}"
echo -e "   Source:       ${BOLD}$DOTFILES_DIR${NC}"
echo ""

# ─── Shell Configs ────────────────────────────────────────────────

echo -e "${BOLD}── Shell ──${NC}"

backup_and_link "$DOTFILES_DIR/shell/zshrc"         "$HOME/.zshrc"
backup_and_link "$DOTFILES_DIR/shell/bashrc"        "$HOME/.bashrc"
backup_and_link "$DOTFILES_DIR/shell/bash_profile"  "$HOME/.bash_profile"
backup_and_link "$DOTFILES_DIR/shell/aliases"       "$HOME/.aliases"
backup_and_link "$DOTFILES_DIR/shell/functions"     "$HOME/.functions"

echo ""

# ─── Git Config ───────────────────────────────────────────────────

echo -e "${BOLD}── Git ──${NC}"

backup_and_link "$DOTFILES_DIR/git/gitconfig"   "$HOME/.gitconfig"
backup_and_link "$DOTFILES_DIR/git/gitignore"   "$HOME/.gitignore_global"

echo ""

# ─── SSH Config ───────────────────────────────────────────────────

echo -e "${BOLD}── SSH ──${NC}"

mkdir -p "$HOME/.ssh/config.d"
chmod 700 "$HOME/.ssh"

backup_and_link "$DOTFILES_DIR/ssh/config"              "$HOME/.ssh/config"
backup_and_link "$DOTFILES_DIR/ssh/config.d/00-defaults" "$HOME/.ssh/config.d/00-defaults"
backup_and_link "$DOTFILES_DIR/ssh/config.d/homelab"    "$HOME/.ssh/config.d/homelab"

chmod 600 "$HOME/.ssh/config"
chmod 600 "$HOME/.ssh/config.d/"* 2>/dev/null || true

echo ""

# ─── Alacritty (macOS only) ──────────────────────────────────────

if [[ "$OS" == "Darwin" ]]; then
    echo -e "${BOLD}── Alacritty (macOS) ──${NC}"

    mkdir -p "$HOME/.config/alacritty"
    backup_and_link "$DOTFILES_DIR/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"

    echo ""
fi

# ─── Starship Prompt ─────────────────────────────────────────────

echo -e "${BOLD}── Starship ──${NC}"

if command -v starship &>/dev/null; then
    info "Starship already installed"
else
    info "Installing Starship..."
    if [[ "$OS" == "Darwin" ]] && command -v brew &>/dev/null; then
        brew install starship
        success "Installed Starship via Homebrew"
    elif command -v curl &>/dev/null; then
        mkdir -p "$HOME/.local/bin"
        if curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir "$HOME/.local/bin" -y; then
            success "Installed Starship to ~/.local/bin"
        else
            warn "Starship installation failed — install manually: https://starship.rs"
        fi
    else
        warn "Could not install Starship (curl not found) — install manually: https://starship.rs"
    fi
fi

mkdir -p "$HOME/.config"
backup_and_link "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

echo ""

# ─── Zsh Plugins ─────────────────────────────────────────────────

if command -v zsh &>/dev/null; then
    echo -e "${BOLD}── Zsh Plugins ──${NC}"

    install_zsh_plugin() {
        local name="$1"
        local repo="$2"
        local plugin_dir="$HOME/.zsh/$name"

        # Check if already available system-wide
        for check in \
            "/opt/homebrew/share/$name/$name.zsh" \
            "/usr/local/share/$name/$name.zsh" \
            "/usr/share/$name/$name.zsh"; do
            if [[ -f "$check" ]]; then
                info "$name (system: $(dirname "$check"))"
                return
            fi
        done

        # Clone to ~/.zsh/ if not present
        if [[ -d "$plugin_dir" ]]; then
            info "$name already installed"
        else
            if command -v git &>/dev/null; then
                git clone --depth 1 "$repo" "$plugin_dir" 2>/dev/null
                success "Installed $name"
            else
                warn "git not found — skipping $name"
            fi
        fi
    }

    install_zsh_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions.git"
    install_zsh_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"

    echo ""
fi

# ─── Create local override files if they don't exist ─────────────

echo -e "${BOLD}── Local Overrides ──${NC}"

create_local_if_missing() {
    local file="$1"
    local comment="$2"
    if [[ ! -f "$file" ]]; then
        echo "$comment" > "$file"
        echo "# Add your machine-specific settings below" >> "$file"
        echo "" >> "$file"
        success "Created $file"
    else
        info "Already exists: $file"
    fi
}

create_local_if_missing "$HOME/.zshrc.local"    "# Local zsh overrides (not tracked by git)"
create_local_if_missing "$HOME/.bashrc.local"   "# Local bash overrides (not tracked by git)"
create_local_if_missing "$HOME/.gitconfig.local" "# Local git overrides (not tracked by git)"

if [[ ! -f "$HOME/.ssh/config.d/local" ]]; then
    touch "$HOME/.ssh/config.d/local"
    chmod 600 "$HOME/.ssh/config.d/local"
    success "Created ~/.ssh/config.d/local"
else
    info "Already exists: ~/.ssh/config.d/local"
fi

echo ""

# ─── Summary ─────────────────────────────────────────────────────

echo -e "${BOLD}${GREEN}✔ Done!${NC}"
if [[ -d "$BACKUP_DIR" ]]; then
    echo -e "  Backups saved to: ${YELLOW}$BACKUP_DIR${NC}"
fi
echo -e "  Add machine-specific settings to the ${BOLD}.local${NC} files"
echo ""
