#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  Dotfiles Installer                                             ║
# ║  Detects OS, backs up existing configs, creates symlinks        ║
# ║                                                                  ║
# ║  Usage: ./install.sh [-n|--dry-run] [-v|--verbose] [-h|--help]  ║
# ╚══════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ─── Argument parsing ────────────────────────────────────────────

DRY_RUN=0
VERBOSE=0

usage() {
    cat <<'USAGE'
Usage: install.sh [OPTIONS]

Detects OS, backs up existing configs, and creates symlinks from this
repo into your home directory.

Options:
  -n, --dry-run    Print what would happen without changing anything
  -v, --verbose    Show extra detail (skipped links, mkdir noise)
  -h, --help       Show this help text
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run) DRY_RUN=1 ;;
        -v|--verbose) VERBOSE=1 ;;
        -h|--help)    usage; exit 0 ;;
        *)            echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

# ─── Config ───────────────────────────────────────────────────────

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"

# OS detection: Termux runs on Android Linux but needs its own bucket
if [[ -n "${TERMUX_VERSION:-}" ]] || [[ "$(uname -o 2>/dev/null)" == "Android" ]]; then
    OS="Termux"
else
    OS="$(uname -s)"
fi

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
verbose() { [[ "$VERBOSE" -eq 1 ]] && echo -e "${BLUE}·${NC} $1" || true; }
plan()    { echo -e "${YELLOW}↪${NC} would $1"; }

# ─── Helpers ──────────────────────────────────────────────────────

run() {
    # Execute a command, or print it (dry-run). Stays quiet otherwise.
    if [[ "$DRY_RUN" -eq 1 ]]; then
        plan "$*"
    else
        "$@"
    fi
}

backup_and_link() {
    local source="$1"
    local target="$2"
    local target_dir
    target_dir="$(dirname "$target")"

    # Create parent directory if needed
    if [[ ! -d "$target_dir" ]]; then
        run mkdir -p "$target_dir"
        verbose "Created directory: $target_dir"
    fi

    # Idempotency: skip if target already points at the right source
    if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
        verbose "Already linked: $(basename "$target")"
        return 0
    fi

    # Back up existing file/symlink
    if [[ -e "$target" || -L "$target" ]]; then
        if [[ "$DRY_RUN" -eq 1 ]]; then
            plan "back up $target → $BACKUP_DIR/"
        else
            mkdir -p "$BACKUP_DIR"
            local backup_path="$BACKUP_DIR/$(basename "$target")"
            cp -rL "$target" "$backup_path" 2>/dev/null || true
            rm -rf "$target"
            warn "Backed up existing $(basename "$target") → $BACKUP_DIR/"
        fi
    fi

    # Create symlink
    run ln -sf "$source" "$target"
    if [[ "$DRY_RUN" -eq 0 ]]; then
        success "Linked $(basename "$target") → $source"
    fi
}

# ─── Header ───────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}🏠 Dotfiles Installer${NC}"
echo -e "   OS detected: ${BOLD}$OS${NC}"
echo -e "   Source:       ${BOLD}$DOTFILES_DIR${NC}"
if [[ "$DRY_RUN" -eq 1 ]]; then
    echo -e "   Mode:         ${BOLD}${YELLOW}DRY RUN${NC} (no changes will be made)"
fi
if [[ "$VERBOSE" -eq 1 ]]; then
    echo -e "   Mode:         ${BOLD}VERBOSE${NC}"
fi
echo ""

# ─── Shell Configs ────────────────────────────────────────────────

echo -e "${BOLD}── Shell ──${NC}"

backup_and_link "$DOTFILES_DIR/shell/zshrc"         "$HOME/.zshrc"
backup_and_link "$DOTFILES_DIR/shell/bashrc"        "$HOME/.bashrc"
backup_and_link "$DOTFILES_DIR/shell/bash_profile"  "$HOME/.bash_profile"
backup_and_link "$DOTFILES_DIR/shell/aliases"       "$HOME/.aliases"
backup_and_link "$DOTFILES_DIR/shell/functions"     "$HOME/.functions"

# Platform-split shell fragments (sourced by zshrc/bashrc)
backup_and_link "$DOTFILES_DIR/shell/common.sh"     "$HOME/.shell/common.sh"
backup_and_link "$DOTFILES_DIR/shell/macos.sh"      "$HOME/.shell/macos.sh"
backup_and_link "$DOTFILES_DIR/shell/linux.sh"      "$HOME/.shell/linux.sh"
backup_and_link "$DOTFILES_DIR/shell/termux.sh"     "$HOME/.shell/termux.sh"

echo ""

# ─── Git Config ───────────────────────────────────────────────────

echo -e "${BOLD}── Git ──${NC}"

backup_and_link "$DOTFILES_DIR/git/gitconfig"   "$HOME/.gitconfig"
backup_and_link "$DOTFILES_DIR/git/gitignore"   "$HOME/.gitignore_global"

echo ""

# ─── SSH Config ───────────────────────────────────────────────────

echo -e "${BOLD}── SSH ──${NC}"

run mkdir -p "$HOME/.ssh/config.d"
run chmod 700 "$HOME/.ssh"

backup_and_link "$DOTFILES_DIR/ssh/config"              "$HOME/.ssh/config"
backup_and_link "$DOTFILES_DIR/ssh/config.d/00-defaults" "$HOME/.ssh/config.d/00-defaults"
backup_and_link "$DOTFILES_DIR/ssh/config.d/homelab"    "$HOME/.ssh/config.d/homelab"

if [[ "$DRY_RUN" -eq 0 ]]; then
    chmod 600 "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config.d/"* 2>/dev/null || true
fi

echo ""

# ─── Alacritty (macOS only) ──────────────────────────────────────

if [[ "$OS" == "Darwin" ]]; then
    echo -e "${BOLD}── Alacritty (macOS) ──${NC}"

    run mkdir -p "$HOME/.config/alacritty"
    backup_and_link "$DOTFILES_DIR/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"

    echo ""
elif [[ "$OS" == "Termux" ]]; then
    verbose "Skipping Alacritty (not relevant on Termux)"
fi

# ─── Termux (Android only) ───────────────────────────────────────

if [[ "$OS" == "Termux" ]]; then
    echo -e "${BOLD}── Termux (Android) ──${NC}"

    run mkdir -p "$HOME/.termux"
    backup_and_link "$DOTFILES_DIR/termux/termux.properties" "$HOME/.termux/termux.properties"
    backup_and_link "$DOTFILES_DIR/termux/colors.properties" "$HOME/.termux/colors.properties"

    # Apply changes without restarting Termux. The command lives in
    # the termux-tools package and may not be installed on a bare
    # bootstrap — fall back silently.
    if [[ "$DRY_RUN" -eq 1 ]]; then
        plan "run termux-reload-settings"
    elif command -v termux-reload-settings &>/dev/null; then
        termux-reload-settings
        success "Reloaded Termux settings"
    else
        warn "termux-reload-settings not found — restart Termux to apply"
    fi

    echo ""
fi

# ─── Starship (cross-platform) ───────────────────────────────────

echo -e "${BOLD}── Starship ──${NC}"

run mkdir -p "$HOME/.config"
backup_and_link "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

echo ""

# ─── Create local override files if they don't exist ─────────────

echo -e "${BOLD}── Local Overrides ──${NC}"

create_local_if_missing() {
    local file="$1"
    local comment="$2"
    if [[ ! -f "$file" ]]; then
        if [[ "$DRY_RUN" -eq 1 ]]; then
            plan "create $file"
        else
            echo "$comment" > "$file"
            echo "# Add your machine-specific settings below" >> "$file"
            echo "" >> "$file"
            success "Created $file"
        fi
    else
        verbose "Already exists: $file"
    fi
}

create_local_if_missing "$HOME/.zshrc.local"    "# Local zsh overrides (not tracked by git)"
create_local_if_missing "$HOME/.bashrc.local"   "# Local bash overrides (not tracked by git)"
create_local_if_missing "$HOME/.gitconfig.local" "# Local git overrides (not tracked by git)"

if [[ ! -f "$HOME/.ssh/config.d/local" ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
        plan "create ~/.ssh/config.d/local (chmod 600)"
    else
        touch "$HOME/.ssh/config.d/local"
        chmod 600 "$HOME/.ssh/config.d/local"
        success "Created ~/.ssh/config.d/local"
    fi
else
    verbose "Already exists: ~/.ssh/config.d/local"
fi

echo ""

# ─── Summary ─────────────────────────────────────────────────────

if [[ "$DRY_RUN" -eq 1 ]]; then
    echo -e "${BOLD}${YELLOW}✔ Dry run complete.${NC} Re-run without --dry-run to apply."
else
    echo -e "${BOLD}${GREEN}✔ Done!${NC}"
    if [[ -d "$BACKUP_DIR" ]]; then
        echo -e "  Backups saved to: ${YELLOW}$BACKUP_DIR${NC}"
    fi
    echo -e "  Add machine-specific settings to the ${BOLD}.local${NC} files"
fi
echo ""
