#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  Dotfiles Installer                                             ║
# ║                                                                 ║
# ║  Detects OS, selects profile, backs up existing configs,        ║
# ║  installs packages, and creates symlinks.                       ║
# ║                                                                 ║
# ║  Non-interactive mode: DOTFILES_UPDATE=1 ./install.sh           ║
# ╚══════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ─── Config ───────────────────────────────────────────────────────

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"
OS="$(uname -s)"
INTERACTIVE="${DOTFILES_UPDATE:-0}"
# INTERACTIVE: 0 = interactive (default), 1 = non-interactive (update mode)

# ─── Colors ───────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}●${NC} $1"; }
success() { echo -e "${GREEN}✔${NC} $1"; }
warn()    { echo -e "${YELLOW}⚠${NC} $1"; }
error()   { echo -e "${RED}✖${NC} $1"; }

# ─── Helpers ──────────────────────────────────────────────────────

ask() {
    # Usage: ask "question" "default"
    # In non-interactive mode, returns the default
    local question="$1"
    local default="${2:-}"
    if [[ "$INTERACTIVE" == "1" ]]; then
        echo "$default"
        return
    fi
    local answer
    read -rp "$(echo -e "${CYAN}?${NC} ${question} ")" answer
    echo "${answer:-$default}"
}

ask_yn() {
    # Usage: ask_yn "question" "y/n"
    local question="$1"
    local default="${2:-y}"
    if [[ "$INTERACTIVE" == "1" ]]; then
        echo "$default"
        return
    fi
    local hint="[Y/n]"
    [[ "$default" == "n" ]] && hint="[y/N]"
    local answer
    read -rp "$(echo -e "${CYAN}?${NC} ${question} ${hint} ")" answer
    answer="${answer:-$default}"
    echo "${answer,,}"  # lowercase
}

backup_and_link() {
    local source="$1"
    local target="$2"
    local target_dir
    target_dir="$(dirname "$target")"

    # Create parent directory if needed
    if [[ ! -d "$target_dir" ]]; then
        mkdir -p "$target_dir"
    fi

    # Skip if already correctly linked
    if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
        info "Already linked: $(basename "$target")"
        return
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

install_package() {
    local name="$1"
    local brew_name="${2:-$1}"
    local apt_name="${3:-$1}"
    local dnf_name="${4:-$1}"

    if command -v "$name" &>/dev/null; then
        info "$name already installed"
        return
    fi

    info "Installing $name..."
    if [[ "$OS" == "Darwin" ]] && command -v brew &>/dev/null; then
        brew install "$brew_name" 2>/dev/null && success "Installed $name via Homebrew" || warn "Failed to install $name"
    elif command -v apt-get &>/dev/null; then
        sudo apt-get install -y "$apt_name" -qq && success "Installed $name via apt" || warn "Failed to install $name"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y "$dnf_name" -q && success "Installed $name via dnf" || warn "Failed to install $name"
    else
        warn "Could not install $name — install manually"
    fi
}

# ─── Detect OS ────────────────────────────────────────────────────

detect_distro() {
    if [[ "$OS" == "Darwin" ]]; then
        echo "macOS"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "${ID:-linux}"
    else
        echo "linux"
    fi
}

DISTRO="$(detect_distro)"

# ─── Header ───────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}🏠 Dotfiles Installer${NC}"
echo -e "   OS:     ${BOLD}$OS${NC} (${DISTRO})"
echo -e "   Source: ${BOLD}$DOTFILES_DIR${NC}"
echo ""

# ─── Profile Selection ───────────────────────────────────────────

PROFILE="${DOTFILES_PROFILE:-}"
TERMINAL="${DOTFILES_TERMINAL:-}"
INSTALL_BREW="${DOTFILES_BREW:-}"

if [[ "$INTERACTIVE" != "1" ]]; then
    if [[ -z "$PROFILE" ]]; then
        echo -e "${BOLD}── Profile Selection ──${NC}"
        echo ""
        echo -e "  ${BOLD}1)${NC} Workstation  — GUI tools, terminal emulator, full setup"
        echo -e "  ${BOLD}2)${NC} Server       — CLI only, no GUI tools"
        echo ""
        PROFILE_CHOICE="$(ask "Select profile [1/2]:" "1")"
        case "$PROFILE_CHOICE" in
            2|server|Server) PROFILE="server" ;;
            *)               PROFILE="workstation" ;;
        esac
    fi
    echo -e "  Profile: ${BOLD}${PROFILE}${NC}"
    echo ""
else
    # Non-interactive defaults
    PROFILE="${PROFILE:-workstation}"
fi

# ─── Homebrew ────────────────────────────────────────────────────

if [[ "$OS" == "Darwin" ]] || [[ "$PROFILE" == "workstation" ]]; then
    echo -e "${BOLD}── Homebrew ──${NC}"

    if command -v brew &>/dev/null; then
        info "Homebrew already installed"
        if [[ "$INTERACTIVE" != "1" ]] && [[ -z "$INSTALL_BREW" ]]; then
            INSTALL_BREW="$(ask_yn "Update Homebrew and install packages from Brewfile?" "y")"
        fi
        INSTALL_BREW="${INSTALL_BREW:-y}"
        if [[ "$INSTALL_BREW" =~ ^[Yy] ]]; then
            if [[ -f "$DOTFILES_DIR/Brewfile" ]]; then
                info "Installing packages from Brewfile..."
                brew bundle --file="$DOTFILES_DIR/Brewfile" 2>/dev/null && \
                    success "All Homebrew packages installed" || \
                    warn "Some packages may have failed — check output above"
            fi
        fi
    elif [[ "$OS" == "Darwin" ]]; then
        if [[ "$INTERACTIVE" != "1" ]]; then
            INSTALL_BREW="$(ask_yn "Homebrew not found. Install it?" "y")"
        fi
        INSTALL_BREW="${INSTALL_BREW:-y}"
        if [[ "$INSTALL_BREW" =~ ^[Yy] ]]; then
            info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            eval "$(/opt/homebrew/bin/brew shellenv)"
            success "Homebrew installed"
            if [[ -f "$DOTFILES_DIR/Brewfile" ]]; then
                info "Installing packages from Brewfile..."
                brew bundle --file="$DOTFILES_DIR/Brewfile" 2>/dev/null || true
            fi
        fi
    fi

    echo ""
fi

# ─── Terminal Emulator (Workstation only) ────────────────────────

if [[ "$PROFILE" == "workstation" ]] && [[ "$INTERACTIVE" != "1" ]]; then
    if [[ -z "$TERMINAL" ]]; then
        echo -e "${BOLD}── Terminal Emulator ──${NC}"
        echo ""
        echo -e "  ${BOLD}1)${NC} Ghostty     — native, fast, modern"
        echo -e "  ${BOLD}2)${NC} iTerm2      — feature-rich macOS terminal"
        echo -e "  ${BOLD}3)${NC} Alacritty   — GPU-accelerated, cross-platform"
        echo -e "  ${BOLD}4)${NC} All         — install all available terminals"
        echo -e "  ${BOLD}5)${NC} Skip        — don't install a terminal"
        echo ""
        TERM_CHOICE="$(ask "Select terminal [1-5]:" "1")"
        case "$TERM_CHOICE" in
            1|ghostty|Ghostty)     TERMINAL="ghostty" ;;
            2|iterm|iterm2|iTerm2) TERMINAL="iterm2" ;;
            3|alacritty|Alacritty) TERMINAL="alacritty" ;;
            4|all|All)             TERMINAL="all" ;;
            *)                     TERMINAL="skip" ;;
        esac
        echo ""
    fi
elif [[ "$INTERACTIVE" == "1" ]]; then
    TERMINAL="${TERMINAL:-all}"
fi

# ─── Core CLI Tools (if not already via Brewfile) ────────────────

echo -e "${BOLD}── Core Tools ──${NC}"

# Update apt cache once on Debian/Ubuntu
if command -v apt-get &>/dev/null && [[ "$OS" != "Darwin" ]]; then
    sudo apt-get update -qq 2>/dev/null || true
fi

install_package "starship" "starship" "starship" "starship"
install_package "tmux"     "tmux"     "tmux"     "tmux"
install_package "fzf"      "fzf"      "fzf"      "fzf"
install_package "rg"       "ripgrep"  "ripgrep"  "ripgrep"
install_package "zoxide"   "zoxide"   "zoxide"   "zoxide"
install_package "delta"    "git-delta" "git-delta" "git-delta"

# fd has different binary names on different distros
if ! command -v fd &>/dev/null && ! command -v fdfind &>/dev/null; then
    install_package "fd" "fd" "fd-find" "fd-find"
fi

# bat has different binary names on Debian/Ubuntu
if ! command -v bat &>/dev/null && ! command -v batcat &>/dev/null; then
    install_package "bat" "bat" "bat" "bat"
fi

if command -v eza &>/dev/null; then
    info "eza already installed"
else
    install_package "eza" "eza" "eza" "eza"
fi

# tealdeer (tldr)
if command -v tldr &>/dev/null; then
    info "tldr already installed"
else
    install_package "tldr" "tealdeer" "tealdeer" "tealdeer"
fi

echo ""

# ─── Shell Configs ────────────────────────────────────────────────

echo -e "${BOLD}── Shell ──${NC}"

# Zsh configs
backup_and_link "$DOTFILES_DIR/zsh/.zshrc"      "$HOME/.zshrc"
backup_and_link "$DOTFILES_DIR/zsh/.zshenv"      "$HOME/.zshenv"
backup_and_link "$DOTFILES_DIR/zsh/.zprofile"    "$HOME/.zprofile"

# Bash configs
backup_and_link "$DOTFILES_DIR/shell/bashrc"        "$HOME/.bashrc"
backup_and_link "$DOTFILES_DIR/shell/bash_profile"  "$HOME/.bash_profile"

# Shared aliases & functions (sourced by both zsh and bash)
backup_and_link "$DOTFILES_DIR/shell/aliases"       "$HOME/.aliases"
backup_and_link "$DOTFILES_DIR/shell/functions"     "$HOME/.functions"

echo ""

# ─── Git Config ───────────────────────────────────────────────────

echo -e "${BOLD}── Git ──${NC}"

backup_and_link "$DOTFILES_DIR/git/.gitconfig"       "$HOME/.gitconfig"
backup_and_link "$DOTFILES_DIR/git/.gitignore_global" "$HOME/.gitignore_global"

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

# ─── Terminal Emulator Install & Config ─────────────────────────

if [[ "$TERMINAL" == "ghostty" || "$TERMINAL" == "all" ]]; then
    echo -e "${BOLD}── Ghostty ──${NC}"

    # Install Ghostty if not present
    if command -v ghostty &>/dev/null || [[ -d "/Applications/Ghostty.app" ]]; then
        info "Ghostty already installed"
    elif [[ "$OS" == "Darwin" ]] && command -v brew &>/dev/null; then
        info "Installing Ghostty..."
        brew install --cask ghostty 2>/dev/null && \
            success "Installed Ghostty via Homebrew" || \
            warn "Ghostty install failed — install manually: https://ghostty.org"
    else
        warn "Ghostty not found — install manually: https://ghostty.org"
    fi

    # Link config
    mkdir -p "$HOME/.config/ghostty"
    backup_and_link "$DOTFILES_DIR/config/ghostty/config" "$HOME/.config/ghostty/config"
    echo ""
fi

if [[ "$TERMINAL" == "iterm2" || "$TERMINAL" == "all" ]]; then
    echo -e "${BOLD}── iTerm2 ──${NC}"

    # Install iTerm2 if not present (macOS only)
    if [[ -d "/Applications/iTerm.app" ]]; then
        info "iTerm2 already installed"
    elif [[ "$OS" == "Darwin" ]] && command -v brew &>/dev/null; then
        info "Installing iTerm2..."
        brew install --cask iterm2 2>/dev/null && \
            success "Installed iTerm2 via Homebrew" || \
            warn "iTerm2 install failed — install manually: https://iterm2.com"
    elif [[ "$OS" == "Darwin" ]]; then
        warn "iTerm2 not found — install via Homebrew or https://iterm2.com"
    else
        info "iTerm2 is macOS only — skipping on Linux"
    fi

    echo ""
fi

if [[ "$TERMINAL" == "alacritty" || "$TERMINAL" == "all" ]]; then
    echo -e "${BOLD}── Alacritty ──${NC}"

    # Install Alacritty if not present
    if command -v alacritty &>/dev/null || [[ -d "/Applications/Alacritty.app" ]]; then
        info "Alacritty already installed"
    elif [[ "$OS" == "Darwin" ]] && command -v brew &>/dev/null; then
        info "Installing Alacritty..."
        brew install --cask alacritty 2>/dev/null && \
            success "Installed Alacritty via Homebrew" || \
            warn "Alacritty install failed — install manually: https://alacritty.org"
    elif command -v apt-get &>/dev/null; then
        info "Installing Alacritty..."
        sudo apt-get install -y alacritty -qq 2>/dev/null && \
            success "Installed Alacritty via apt" || \
            warn "Alacritty install failed — install manually: https://alacritty.org"
    elif command -v dnf &>/dev/null; then
        info "Installing Alacritty..."
        sudo dnf install -y alacritty -q 2>/dev/null && \
            success "Installed Alacritty via dnf" || \
            warn "Alacritty install failed — install manually: https://alacritty.org"
    else
        warn "Alacritty not found — install manually: https://alacritty.org"
    fi

    # Link config
    mkdir -p "$HOME/.config/alacritty"
    if [[ "$OS" == "Darwin" ]]; then
        backup_and_link "$DOTFILES_DIR/config/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
    else
        backup_and_link "$DOTFILES_DIR/config/alacritty/alacritty-linux.toml" "$HOME/.config/alacritty/alacritty.toml"
    fi
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
            brew install --cask font-jetbrains-mono-nerd-font 2>/dev/null && \
                success "Installed JetBrainsMono Nerd Font" || \
                warn "Font already exists or install failed — skipping"
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

mkdir -p "$HOME/.config"
backup_and_link "$DOTFILES_DIR/config/starship.toml" "$HOME/.config/starship.toml"

echo ""

# ─── Tmux ───────────────────────────────────────────────────────

echo -e "${BOLD}── Tmux ──${NC}"

backup_and_link "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"

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

# ─── Nano (Linux server) ────────────────────────────────────────

if [[ "$OS" != "Darwin" ]] && [[ -f "$DOTFILES_DIR/nano/nanorc-linux" ]]; then
    echo -e "${BOLD}── Nano ──${NC}"
    backup_and_link "$DOTFILES_DIR/nano/nanorc-linux" "$HOME/.nanorc"
    echo ""
fi

# ─── xbar + Mac-Mux (macOS workstation only) ────────────────────

if [[ "$OS" == "Darwin" ]] && [[ "$PROFILE" == "workstation" ]]; then
    echo -e "${BOLD}── xbar (Mac-Mux) ──${NC}"

    if command -v brew &>/dev/null; then
        if brew list --cask xbar &>/dev/null 2>&1; then
            info "xbar already installed"
        else
            info "Installing xbar..."
            brew install --cask xbar 2>/dev/null && success "Installed xbar" || warn "xbar install failed"
        fi
    fi

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

# ─── tldr Custom Pages ──────────────────────────────────────────

if command -v tldr &>/dev/null; then
    echo -e "${BOLD}── tldr Custom Pages ──${NC}"
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
    echo ""
fi

# ─── Zsh Plugins ─────────────────────────────────────────────────

if command -v zsh &>/dev/null; then
    echo -e "${BOLD}── Zsh Plugins ──${NC}"

    install_zsh_plugin() {
        local name="$1"
        local repo="$2"
        local plugin_dir="$HOME/.zsh/$name"

        for check in \
            "/opt/homebrew/share/$name/$name.zsh" \
            "/usr/local/share/$name/$name.zsh" \
            "/usr/share/$name/$name.zsh"; do
            if [[ -f "$check" ]]; then
                info "$name (system: $(dirname "$check"))"
                return
            fi
        done

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

# ─── Set Zsh as Default Shell ────────────────────────────────────

echo -e "${BOLD}── Default Shell ──${NC}"

CURRENT_SHELL="$(basename "${SHELL:-}")"
if [[ "$CURRENT_SHELL" == "zsh" ]]; then
    info "Zsh is already the default shell"
elif command -v zsh &>/dev/null; then
    ZSH_PATH="$(command -v zsh)"
    # Ensure zsh is in /etc/shells
    if ! grep -qx "$ZSH_PATH" /etc/shells 2>/dev/null; then
        info "Adding $ZSH_PATH to /etc/shells..."
        echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
    fi
    if [[ "$INTERACTIVE" != "1" ]]; then
        SET_ZSH="$(ask_yn "Set zsh as default shell?" "y")"
        if [[ "$SET_ZSH" =~ ^[Yy] ]]; then
            chsh -s "$ZSH_PATH"
            success "Default shell changed to zsh (restart terminal to take effect)"
        fi
    else
        info "Run 'chsh -s $(command -v zsh)' to set zsh as default"
    fi
else
    warn "Zsh not found — install it first"
fi

echo ""

# ─── Create Local Override Files ─────────────────────────────────

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

create_local_if_missing "$HOME/.zshrc.local"     "# Local zsh overrides (not tracked by git)"
create_local_if_missing "$HOME/.bashrc.local"    "# Local bash overrides (not tracked by git)"
create_local_if_missing "$HOME/.gitconfig.local" "# Local git overrides (not tracked by git)"
create_local_if_missing "$HOME/.tmux.conf.local" "# Local tmux overrides (not tracked by git)"

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
echo -e "  Profile:  ${BOLD}$PROFILE${NC}"
[[ -n "${TERMINAL:-}" && "$TERMINAL" != "skip" ]] && echo -e "  Terminal: ${BOLD}$TERMINAL${NC}"
if [[ -d "$BACKUP_DIR" ]]; then
    echo -e "  Backups:  ${YELLOW}$BACKUP_DIR${NC}"
fi
echo -e "  Add machine-specific settings to the ${BOLD}.local${NC} files"
echo ""
