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

# Placeholder extraction (same regex fshortcuts() uses), incl. a duplicate
# {ip} to check dedup via sort -u.
cmd='ssh {user}@{ip} && ping {ip}'
placeholders=$(grep -oE '\{[A-Za-z_][A-Za-z0-9_]*\}' <<< "$cmd" | sort -u | tr '\n' ' ')
[[ "$placeholders" == "{ip} {user} " ]] || { echo "FAIL: expected '{ip} {user} ', got '$placeholders'"; exit 1; }

echo "PASS: placeholder extraction ok"

# Shared + .local merge, incl. the no-local-file case (cat on a missing
# second file errors on stderr but still prints the first file's stdout).
localfile=$(mktemp)
trap 'rm -f "$tmpfile" "$localfile"' EXIT
cat > "$localfile" <<'EOF'
Label three|echo three
EOF

merged_lines=$(cat "$tmpfile" "$localfile" 2>/dev/null | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$' | wc -l | tr -d ' ')
[[ "$merged_lines" == "3" ]] || { echo "FAIL: expected 3 merged lines, got $merged_lines"; exit 1; }

no_local_lines=$({ cat "$tmpfile" "/nonexistent-shortcuts.local" 2>/dev/null || true; } | grep -v '^[[:space:]]*#' | grep -v '^[[:space:]]*$' | wc -l | tr -d ' ')
[[ "$no_local_lines" == "2" ]] || { echo "FAIL: expected 2 lines with no .local file, got $no_local_lines"; exit 1; }

echo "PASS: shared + .local merge ok"
