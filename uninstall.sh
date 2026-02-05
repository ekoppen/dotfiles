#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  Dotfiles Uninstaller                                           ║
# ║  Removes symlinks and restores most recent backup               ║
# ╚══════════════════════════════════════════════════════════════════╝

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "  ${YELLOW}●${NC} $1"; }
success() { echo -e "  ${GREEN}✔${NC} $1"; }

echo ""
echo -e "${BOLD}🗑  Dotfiles Uninstaller${NC}"
echo ""

# Files to remove (only if they're symlinks pointing to our dotfiles)
TARGETS=(
    "$HOME/.zshrc"
    "$HOME/.bashrc"
    "$HOME/.bash_profile"
    "$HOME/.aliases"
    "$HOME/.functions"
    "$HOME/.gitconfig"
    "$HOME/.gitignore_global"
    "$HOME/.ssh/config"
    "$HOME/.ssh/config.d/00-defaults"
    "$HOME/.ssh/config.d/homelab"
    "$HOME/.config/alacritty/alacritty.toml"
)

for target in "${TARGETS[@]}"; do
    if [[ -L "$target" ]]; then
        link_target="$(readlink "$target")"
        if [[ "$link_target" == "$DOTFILES_DIR"* ]]; then
            rm "$target"
            success "Removed symlink: $target"
        fi
    fi
done

# Find most recent backup
BACKUP_BASE="$HOME/.dotfiles-backup"
if [[ -d "$BACKUP_BASE" ]]; then
    LATEST_BACKUP="$(ls -1d "$BACKUP_BASE"/*/ 2>/dev/null | sort -r | head -1)"
    if [[ -n "$LATEST_BACKUP" ]]; then
        echo ""
        echo -e "${BOLD}Restoring from backup: ${YELLOW}$LATEST_BACKUP${NC}"
        for file in "$LATEST_BACKUP"/*; do
            filename="$(basename "$file")"
            case "$filename" in
                zshrc)          cp "$file" "$HOME/.zshrc" ;;
                bashrc)         cp "$file" "$HOME/.bashrc" ;;
                bash_profile)   cp "$file" "$HOME/.bash_profile" ;;
                aliases)        cp "$file" "$HOME/.aliases" ;;
                functions)      cp "$file" "$HOME/.functions" ;;
                gitconfig)      cp "$file" "$HOME/.gitconfig" ;;
                gitignore_global) cp "$file" "$HOME/.gitignore_global" ;;
                config)         cp "$file" "$HOME/.ssh/config" ;;
                alacritty.toml) cp "$file" "$HOME/.config/alacritty/alacritty.toml" ;;
            esac
            info "Restored $filename"
        done
    fi
fi

echo ""
echo -e "${GREEN}${BOLD}✔ Uninstall complete.${NC} Local override files (.local) were kept."
echo ""
