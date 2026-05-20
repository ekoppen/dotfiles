# ╔══════════════════════════════════════════════════════════════════╗
# ║  common.sh  ·  Sourced by zshrc and bashrc on every platform   ║
# ║                                                                 ║
# ║  Holds anything that is NOT shell-specific and NOT OS-specific. ║
# ║  Shell-specific bits (history, completion, fzf init) stay in    ║
# ║  zshrc/bashrc. OS-specific bits live in macos.sh/linux.sh/      ║
# ║  termux.sh and are sourced from there.                          ║
# ╚══════════════════════════════════════════════════════════════════╝

# ─── Path (cross-platform local bins) ────────────────────────────

[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/bin" ]]        && export PATH="$HOME/bin:$PATH"

# ─── Environment ──────────────────────────────────────────────────

export EDITOR="${EDITOR:-nano}"
export VISUAL="$EDITOR"
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"

# ─── Shared Aliases & Functions ───────────────────────────────────

[[ -f "$HOME/.aliases" ]]   && source "$HOME/.aliases"
[[ -f "$HOME/.functions" ]] && source "$HOME/.functions"

# ─── SSH Agent (non-macOS; macOS uses Keychain) ──────────────────

if [[ "${DOTFILES_OS:-}" != "macos" ]] && [[ -z "${SSH_AUTH_SOCK:-}" ]]; then
    if command -v ssh-agent &>/dev/null; then
        eval "$(ssh-agent -s)" >/dev/null 2>&1
    fi
fi

# ─── tmux Auto-attach (SSH) ──────────────────────────────────────

# On SSH login, attach to (or create) a tmux session named "main".
# Skipped when: not over SSH, already inside tmux, NO_TMUX is set,
# or tmux isn't installed.
if [[ -n "${SSH_CONNECTION:-}" ]] \
    && [[ -z "${TMUX:-}" ]] \
    && [[ -z "${NO_TMUX:-}" ]] \
    && command -v tmux &>/dev/null; then
    tmux new-session -A -s main
fi
