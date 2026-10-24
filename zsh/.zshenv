# ╔══════════════════════════════════════════════════════════════════╗
# ║  .zshenv  ·  Managed by dotfiles                              ║
# ║                                                                 ║
# ║  Loaded for ALL zsh instances (login, interactive, scripts).    ║
# ║  Keep this minimal — only env vars needed everywhere.           ║
# ╚══════════════════════════════════════════════════════════════════╝

# XDG Base Directories
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Default editor
export EDITOR="${EDITOR:-nano}"
export VISUAL="$EDITOR"

# Locale
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Homebrew (macOS) — lives here, not .zprofile, so non-interactive/non-login
# shells (e.g. remote SSH exec used by recode_agent_host installs) see it too.
if [[ -d "/opt/homebrew/bin" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi
