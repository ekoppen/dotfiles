# ╔══════════════════════════════════════════════════════════════════╗
# ║  .zprofile  ·  Managed by dotfiles                            ║
# ║                                                                 ║
# ║  Loaded for LOGIN shells only (once at login).                  ║
# ║  Use for path setup and login-time actions.                     ║
# ╚══════════════════════════════════════════════════════════════════╝

# ─── Homebrew (macOS) ────────────────────────────────────────────

if [[ -d "/opt/homebrew/bin" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ─── Local bins ──────────────────────────────────────────────────

[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/bin" ]]        && export PATH="$HOME/bin:$PATH"
