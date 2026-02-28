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

# ─── Brewfile (macOS) ───────────────────────────────────────────

if [[ "$OS" == "Darwin" ]] && command -v brew &>/dev/null; then
    echo -e "${BOLD}── Homebrew Bundle ──${NC}"
    if [[ -f "$DOTFILES_DIR/Brewfile" ]]; then
        info "Installing packages from Brewfile..."
        if brew bundle --file="$DOTFILES_DIR/Brewfile" 2>/dev/null; then
            success "All Homebrew packages installed"
        else
            warn "Some packages may have failed — check output above"
        fi
    fi
    echo ""
fi

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

# ─── Terminal Emulators (macOS only) ─────────────────────────────

if [[ "$OS" == "Darwin" ]]; then
    echo -e "${BOLD}── Alacritty (macOS) ──${NC}"

    mkdir -p "$HOME/.config/alacritty"
    backup_and_link "$DOTFILES_DIR/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"

    echo ""

    echo -e "${BOLD}── Ghostty (macOS) ──${NC}"

    mkdir -p "$HOME/.config/ghostty"
    backup_and_link "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/config"

    echo ""
fi

# ─── Nerd Font ───────────────────────────────────────────────────

echo -e "${BOLD}── Nerd Font (JetBrainsMono) ──${NC}"

if [[ "$OS" == "Darwin" ]]; then
    if command -v brew &>/dev/null; then
        if brew list --cask font-jetbrains-mono-nerd-font &>/dev/null 2>&1; then
            info "JetBrainsMono Nerd Font already installed"
        else
            info "Installing JetBrainsMono Nerd Font via Homebrew..."
            if brew install --cask font-jetbrains-mono-nerd-font 2>/dev/null; then
                success "Installed JetBrainsMono Nerd Font"
            else
                warn "Font already exists or install failed — skipping"
            fi
        fi
    else
        warn "Homebrew not found — install JetBrainsMono Nerd Font manually: https://www.nerdfonts.com"
    fi
else
    NERD_FONT_DIR="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
    if ls "$NERD_FONT_DIR"/*.ttf &>/dev/null 2>&1; then
        info "JetBrainsMono Nerd Font already installed"
    elif command -v curl &>/dev/null && command -v unzip &>/dev/null; then
        info "Downloading JetBrainsMono Nerd Font..."
        NERD_FONT_ZIP="/tmp/JetBrainsMono-NerdFont.zip"
        if curl -sL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" -o "$NERD_FONT_ZIP"; then
            mkdir -p "$NERD_FONT_DIR"
            unzip -qo "$NERD_FONT_ZIP" -d "$NERD_FONT_DIR"
            rm -f "$NERD_FONT_ZIP"
            fc-cache -f 2>/dev/null || true
            success "Installed JetBrainsMono Nerd Font to $NERD_FONT_DIR"
        else
            warn "Font download failed — install manually: https://www.nerdfonts.com"
        fi
    else
        warn "curl/unzip not found — install JetBrainsMono Nerd Font manually: https://www.nerdfonts.com"
    fi
fi

echo ""

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

# ─── fzf + companions ───────────────────────────────────────────

echo -e "${BOLD}── fzf (Fuzzy Finder) ──${NC}"

if command -v fzf &>/dev/null; then
    info "fzf already installed ($(fzf --version | awk '{print $1}'))"
else
    info "Installing fzf..."
    if [[ "$OS" == "Darwin" ]] && command -v brew &>/dev/null; then
        brew install fzf
        success "Installed fzf via Homebrew"
    elif command -v apt-get &>/dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y fzf
        success "Installed fzf via apt"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y fzf
        success "Installed fzf via dnf"
    else
        warn "Could not install fzf — install manually: https://github.com/junegunn/fzf"
    fi
fi

# fd — fast find alternative (used by fzf for file/dir searching)
if command -v fd &>/dev/null || command -v fdfind &>/dev/null; then
    info "fd already installed"
else
    info "Installing fd (fast find, used by fzf)..."
    if [[ "$OS" == "Darwin" ]] && command -v brew &>/dev/null; then
        brew install fd
        success "Installed fd via Homebrew"
    elif command -v apt-get &>/dev/null; then
        sudo apt-get install -y fd-find
        success "Installed fd via apt"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y fd-find
        success "Installed fd via dnf"
    else
        warn "Could not install fd — install manually: https://github.com/sharkdp/fd"
    fi
fi

# bat — syntax-highlighted cat (used by fzf for file preview)
if command -v bat &>/dev/null || command -v batcat &>/dev/null; then
    info "bat already installed"
else
    info "Installing bat (syntax-highlighted preview, used by fzf)..."
    if [[ "$OS" == "Darwin" ]] && command -v brew &>/dev/null; then
        brew install bat
        success "Installed bat via Homebrew"
    elif command -v apt-get &>/dev/null; then
        sudo apt-get install -y bat
        success "Installed bat via apt"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y bat
        success "Installed bat via dnf"
    else
        warn "Could not install bat — install manually: https://github.com/sharkdp/bat"
    fi
fi

echo ""

# ─── ripgrep ────────────────────────────────────────────────────

echo -e "${BOLD}── ripgrep ──${NC}"

if command -v rg &>/dev/null; then
    info "ripgrep already installed ($(rg --version | head -1 | awk '{print $2}'))"
else
    info "Installing ripgrep..."
    if [[ "$OS" == "Darwin" ]] && command -v brew &>/dev/null; then
        brew install ripgrep
        success "Installed ripgrep via Homebrew"
    elif command -v apt-get &>/dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y ripgrep
        success "Installed ripgrep via apt"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y ripgrep
        success "Installed ripgrep via dnf"
    else
        warn "Could not install ripgrep — install manually: https://github.com/BurntSushi/ripgrep"
    fi
fi

echo ""

# ─── zoxide ─────────────────────────────────────────────────────

echo -e "${BOLD}── zoxide ──${NC}"

if command -v zoxide &>/dev/null; then
    info "zoxide already installed"
else
    info "Installing zoxide (smart cd)..."
    if [[ "$OS" == "Darwin" ]] && command -v brew &>/dev/null; then
        brew install zoxide
        success "Installed zoxide via Homebrew"
    elif command -v apt-get &>/dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y zoxide
        success "Installed zoxide via apt"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y zoxide
        success "Installed zoxide via dnf"
    else
        warn "Could not install zoxide — install manually: https://github.com/ajeetdsouza/zoxide"
    fi
fi

echo ""

# ─── delta (git pager) ─────────────────────────────────────────

echo -e "${BOLD}── delta ──${NC}"

if command -v delta &>/dev/null; then
    info "delta already installed"
else
    info "Installing delta (syntax-highlighted git diffs)..."
    if [[ "$OS" == "Darwin" ]] && command -v brew &>/dev/null; then
        brew install git-delta
        success "Installed delta via Homebrew"
    elif command -v apt-get &>/dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y git-delta
        success "Installed delta via apt"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y git-delta
        success "Installed delta via dnf"
    else
        warn "Could not install delta — install manually: https://github.com/dandavison/delta"
    fi
fi

echo ""

# ─── tldr (tealdeer) ───────────────────────────────────────────

echo -e "${BOLD}── tldr (tealdeer) ──${NC}"

if command -v tldr &>/dev/null; then
    info "tldr already installed"
else
    info "Installing tealdeer (fast tldr client)..."
    if [[ "$OS" == "Darwin" ]] && command -v brew &>/dev/null; then
        brew install tealdeer
        success "Installed tealdeer via Homebrew"
    elif command -v apt-get &>/dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y tealdeer
        success "Installed tealdeer via apt"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y tealdeer
        success "Installed tealdeer via dnf"
    else
        warn "Could not install tealdeer — install manually: https://github.com/dbrgn/tealdeer"
    fi
fi

# Symlink custom tldr pages for personal setup hints
if command -v tldr &>/dev/null; then
    if [[ "$OS" == "Darwin" ]]; then
        TLDR_CUSTOM_DIR="$HOME/Library/Application Support/tealdeer/pages"
    else
        TLDR_CUSTOM_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/tealdeer/pages"
    fi
    mkdir -p "$TLDR_CUSTOM_DIR"
    for page in "$DOTFILES_DIR"/tldr/pages/*.page.md; do
        [[ -f "$page" ]] || continue
        backup_and_link "$page" "$TLDR_CUSTOM_DIR/$(basename "$page")"
    done
    # Update tldr cache if empty
    if ! tldr --list &>/dev/null 2>&1; then
        info "Updating tldr cache..."
        tldr --update >/dev/null 2>&1 && success "tldr cache updated" || true
    fi
fi

echo ""

# ─── Tmux ───────────────────────────────────────────────────────

echo -e "${BOLD}── Tmux ──${NC}"

if command -v tmux &>/dev/null; then
    info "tmux already installed ($(tmux -V))"
else
    info "Installing tmux..."
    if [[ "$OS" == "Darwin" ]] && command -v brew &>/dev/null; then
        brew install tmux
        success "Installed tmux via Homebrew"
    elif command -v apt-get &>/dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y tmux xclip
        success "Installed tmux + xclip via apt"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y tmux xclip
        success "Installed tmux + xclip via dnf"
    else
        warn "Could not install tmux — install manually"
    fi
fi

backup_and_link "$DOTFILES_DIR/tmux/tmux.conf" "$HOME/.tmux.conf"

echo ""

# ─── TPM (Tmux Plugin Manager) ─────────────────────────────────

echo -e "${BOLD}── TPM (Tmux Plugin Manager) ──${NC}"

TPM_DIR="$HOME/.tmux/plugins/tpm"

if [[ -d "$TPM_DIR" ]]; then
    info "TPM already installed"
else
    if command -v git &>/dev/null; then
        git clone --depth 1 https://github.com/tmux-plugins/tpm "$TPM_DIR" 2>/dev/null
        success "Installed TPM"
    else
        warn "git not found — skipping TPM installation"
    fi
fi

# Auto-install plugins (headless, no tmux server needed)
if command -v tmux &>/dev/null && [[ -x "$TPM_DIR/bin/install_plugins" ]]; then
    info "Installing tmux plugins..."
    "$TPM_DIR/bin/install_plugins" >/dev/null 2>&1
    success "Tmux plugins installed"
fi

echo ""

# ─── xbar + Mac-Mux (macOS only) ───────────────────────────────

if [[ "$OS" == "Darwin" ]]; then
    echo -e "${BOLD}── xbar (Mac-Mux) ──${NC}"

    if command -v brew &>/dev/null; then
        if brew list --cask xbar &>/dev/null 2>&1; then
            info "xbar already installed"
        else
            info "Installing xbar..."
            brew install --cask xbar
            success "Installed xbar"
        fi
    else
        warn "Homebrew not found — install xbar manually: https://xbarapp.com"
    fi

    # Symlink Mac-Mux plugin into xbar plugins directory
    XBAR_PLUGINS="$HOME/Library/Application Support/xbar/plugins"
    mkdir -p "$XBAR_PLUGINS"
    backup_and_link "$DOTFILES_DIR/tmux/mac-mux.10s.sh" "$XBAR_PLUGINS/mac-mux.10s.sh"

    echo ""
fi

# ─── Claude Code ─────────────────────────────────────────────────

echo -e "${BOLD}── Claude Code ──${NC}"

mkdir -p "$HOME/.claude"
backup_and_link "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
backup_and_link "$DOTFILES_DIR/claude/statusline.sh" "$HOME/.claude/statusline.sh"
chmod +x "$HOME/.claude/statusline.sh"

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
create_local_if_missing "$HOME/.tmux.conf.local"  "# Local tmux overrides (not tracked by git)"

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
