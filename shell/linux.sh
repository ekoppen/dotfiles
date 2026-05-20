# ╔══════════════════════════════════════════════════════════════════╗
# ║  linux.sh  ·  Sourced on Linux (non-Termux) only               ║
# ╚══════════════════════════════════════════════════════════════════╝

# ─── Linuxbrew (optional) ────────────────────────────────────────
#
# If you've installed Homebrew on Linux, pull it into PATH.
#
if [[ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
