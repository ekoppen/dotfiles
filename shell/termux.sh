# ╔══════════════════════════════════════════════════════════════════╗
# ║  termux.sh  ·  Sourced on Termux (Android) only                ║
# ╚══════════════════════════════════════════════════════════════════╝

# ─── Termux-specific PATH additions ──────────────────────────────
#
# $PREFIX/bin is already on PATH by default. We add $HOME/bin and
# $HOME/.local/bin in common.sh, which covers user-installed tools.
#

# ─── Storage hint ────────────────────────────────────────────────
#
# Termux needs `termux-setup-storage` once to grant access to
# /sdcard via ~/storage. Show a one-time hint if it isn't set up.
#
if [[ ! -d "$HOME/storage" ]] && [[ -z "${TERMUX_STORAGE_HINT_SHOWN:-}" ]]; then
    echo "→ Run 'termux-setup-storage' to access shared storage at ~/storage"
    export TERMUX_STORAGE_HINT_SHOWN=1
fi

# ─── Termux:API hint ─────────────────────────────────────────────
#
# Most termux-* commands (termux-notification, termux-clipboard-*,
# termux-battery-status, etc.) live in the termux-api package.
# Show a one-time hint if it isn't installed.
#
if ! command -v termux-notification &>/dev/null \
    && [[ -z "${TERMUX_API_HINT_SHOWN:-}" ]]; then
    echo "→ Install 'pkg install termux-api' for termux-* helper commands"
    export TERMUX_API_HINT_SHOWN=1
fi

# ─── Useful aliases for the Termux environment ───────────────────

# Open files with the Android share dialog (needs termux-api)
command -v termux-open &>/dev/null && alias open="termux-open"

# Clipboard bridge (needs termux-api)
if command -v termux-clipboard-get &>/dev/null; then
    alias pbcopy="termux-clipboard-set"
    alias pbpaste="termux-clipboard-get"
fi
