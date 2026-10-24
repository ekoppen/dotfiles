# ╔══════════════════════════════════════════════════════════════════╗
# ║  .zprofile  ·  Managed by dotfiles                            ║
# ║                                                                 ║
# ║  Loaded for LOGIN shells only (once at login).                  ║
# ║  Use for path setup and login-time actions.                     ║
# ╚══════════════════════════════════════════════════════════════════╝

# Homebrew PATH setup moved to .zshenv (see there) so it also loads in
# non-login shells.

# ─── Local bins ──────────────────────────────────────────────────

[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"
[[ -d "$HOME/bin" ]]        && export PATH="$HOME/bin:$PATH"


# Added by Antigravity CLI installer
export PATH="/Users/eelko/.local/bin:$PATH"
