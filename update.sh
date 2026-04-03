#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  Dotfiles Updater                                               ║
# ║  Pulls latest changes, re-links configs, upgrades packages      ║
# ╚══════════════════════════════════════════════════════════════════╝

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

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

echo ""
echo -e "${BOLD}🔄 Dotfiles Updater${NC}"
echo ""

# ─── Pull Latest ─────────────────────────────────────────────────

echo -e "${BOLD}── Git Pull ──${NC}"

cd "$DOTFILES_DIR"

if git diff --quiet && git diff --cached --quiet; then
    git pull --rebase origin main
    success "Pulled latest changes"
else
    warn "Local changes detected — stashing before pull"
    git stash
    git pull --rebase origin main
    git stash pop
    success "Pulled latest changes (stash restored)"
fi

echo ""

# ─── Re-run Symlinks ────────────────────────────────────────────

echo -e "${BOLD}── Re-linking Configs ──${NC}"

DOTFILES_UPDATE=1 "$DOTFILES_DIR/install.sh"

echo ""

# ─── Homebrew Upgrade ───────────────────────────────────────────

if command -v brew &>/dev/null; then
    echo -e "${BOLD}── Homebrew Upgrade ──${NC}"
    info "Updating Homebrew..."
    brew update --quiet
    info "Upgrading packages..."
    brew upgrade --quiet
    if [[ -f "$DOTFILES_DIR/Brewfile" ]]; then
        brew bundle --file="$DOTFILES_DIR/Brewfile" --quiet 2>/dev/null || true
    fi
    brew cleanup --quiet
    success "Homebrew packages up to date"
    echo ""
fi

# ─── Update Tmux Plugins ────────────────────────────────────────

TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ -x "$TPM_DIR/bin/update_plugins" ]]; then
    echo -e "${BOLD}── Tmux Plugins ──${NC}"
    "$TPM_DIR/bin/update_plugins" all >/dev/null 2>&1
    success "Tmux plugins updated"
    echo ""
fi

# ─── Update tldr Cache ──────────────────────────────────────────

if command -v tldr &>/dev/null; then
    echo -e "${BOLD}── tldr Cache ──${NC}"
    tldr --update >/dev/null 2>&1 && success "tldr cache updated" || true
    echo ""
fi

# ─── Done ────────────────────────────────────────────────────────

echo -e "${BOLD}${GREEN}✔ Update complete!${NC}"
echo ""
