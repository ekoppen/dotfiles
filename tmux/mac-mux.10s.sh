#!/bin/bash

# <xbar.title>Mac-Mux</xbar.title>
# <xbar.version>v0.2</xbar.version>
# <xbar.author>etopiei</xbar.author>
# <xbar.author.github>etopiei</xbar.author.github>
# <xbar.desc>Manage tmux sessions from the menu bar. Opens in Alacritty or Terminal.</xbar.desc>
# <xbar.dependencies>bash,tmux</xbar.dependencies>

# Ensure Homebrew binaries are in PATH
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# ─── Helper: open a command in the preferred terminal ───────────

open_in_terminal() {
    local cmd="$1"
    if [ -d "/Applications/Alacritty.app" ]; then
        open -na Alacritty --args -e $cmd
    else
        osascript -e 'tell application "Terminal" to do script "'"$cmd"'"'
        osascript -e 'tell application "Terminal" to activate'
    fi
}

# ─── Actions (called by xbar menu clicks) ───────────────────────

if [ "$1" = 'opensession' ]; then
    open_in_terminal "tmux attach -t $2"
    exit
fi

if [ "$1" = 'newsession' ]; then
    open_in_terminal "tmux new-session"
    exit
fi

# ─── Menu bar display ───────────────────────────────────────────

count=$(tmux list-sessions 2>/dev/null | wc -l | xargs)

if [ "$count" -gt 0 ] 2>/dev/null; then
    echo "⧉ $count"
    echo "---"
    echo "$count running tmux session(s) | color=white"
    echo "---"
    while IFS= read -r session; do
        name="${session%%:*}"
        echo "▶ $name | bash='$0' param1=opensession param2=$name terminal=false refresh=true"
    done < <(tmux list-sessions 2>/dev/null)
    echo "---"
    echo "New session | bash='$0' param1=newsession terminal=false refresh=true"
else
    echo "⧉"
    echo "---"
    echo "Start tmux session | bash='$0' param1=newsession terminal=false refresh=true"
fi
