# ╔══════════════════════════════════════════════════════════════════╗
# ║  macos.sh  ·  Sourced on macOS only                            ║
# ╚══════════════════════════════════════════════════════════════════╝

# ─── Homebrew ─────────────────────────────────────────────────────
#
# Apple Silicon Homebrew installs to /opt/homebrew. Intel uses
# /usr/local. brew shellenv sets PATH, MANPATH, INFOPATH, HOMEBREW_*.
#
if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi
