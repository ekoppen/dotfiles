#!/bin/bash
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "Claude"')
DIR=$(echo "$input" | jq -r '.workspace.current_dir // "~"' | xargs basename)
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')

# Kleuren
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
CYAN='\033[36m'
DIM='\033[2m'
RESET='\033[0m'

# Kleur op basis van context-gebruik
if [ "$PCT" -ge 90 ]; then
    COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then
    COLOR="$YELLOW"
else
    COLOR="$GREEN"
fi

# Git branch (als we in een repo zitten)
BRANCH=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=" | $(git branch --show-current 2>/dev/null)"
fi

# Sessieduur
MINS=$((DURATION_MS / 60000))
SECS=$(((DURATION_MS % 60000) / 1000))

# Voortgangsbalk (10 breed)
FILLED=$((PCT * 10 / 100))
EMPTY=$((10 - FILLED))
BAR=$(printf "%${FILLED}s" | tr ' ' '▓')$(printf "%${EMPTY}s" | tr ' ' '░')

# Regel 1: Model + map + branch
echo -e "${CYAN}[$MODEL]${RESET} $DIR$BRANCH"

# Regel 2: Voortgangsbalk + tijd
printf "${COLOR}%s${RESET} %d%% | ${DIM}%dm %ds${RESET}\n" "$BAR" "$PCT" "$MINS" "$SECS"
