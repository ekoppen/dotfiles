#!/usr/bin/env zsh
# Self-check for fshortcuts' parsing pipeline (shell/functions).
# Run: ~/.dotfiles/shell/test-shortcuts.sh
set -euo pipefail

tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT

cat > "$tmpfile" <<'EOF'
# a comment, should be ignored

Label one|echo one
Label two|echo "two" && echo "three"
EOF

# Same filters fshortcuts() applies to the shortcuts file.
filtered=$(grep -v '^[[:space:]]*#' "$tmpfile" | grep -v '^[[:space:]]*$')

actual_lines=$(print -r -- "$filtered" | wc -l | tr -d ' ')
[[ "$actual_lines" == "2" ]] || { echo "FAIL: expected 2 data lines, got $actual_lines"; exit 1; }

command -v fzf &>/dev/null || { echo "SKIP: fzf not installed, parsing check only"; exit 0; }

# fzf --filter runs non-interactively, same delimiter/with-nth as fshortcuts().
cmd=$(print -r -- "$filtered" | fzf --filter="Label one" --delimiter='|' --with-nth=1 | cut -d'|' -f2-)
[[ "$cmd" == "echo one" ]] || { echo "FAIL: expected 'echo one', got '$cmd'"; exit 1; }

echo "PASS: fshortcuts parsing ok"
