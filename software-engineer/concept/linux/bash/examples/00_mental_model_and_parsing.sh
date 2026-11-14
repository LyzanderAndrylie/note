#!/usr/bin/env bash
set -Eeuo pipefail

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# ---------------------------------------------------------------------------
# 1. Tokenization & Assignment Syntax
# ---------------------------------------------------------------------------
printf '=== 1. Tokenization & Assignment Syntax ===\n'

# Valid assignment: single token matching NAME=VALUE (no spaces around '=')
x=1
printf 'Valid assignment x=1 -> x=%s\n' "$x"

# Invalid assignment with spaces: tokenized into 3 words: command 'x', arg '=', arg '1'
if ! command -v x >/dev/null 2>&1; then
    printf 'With spaces (x = 1): Bash looks up command "x" in PATH (not found)\n'
fi

# Capture exact runtime error safely in a subshell without aborting set -e
set +e
err_msg=$( (x = 1) 2>&1 )
rc=$?
set -e
printf 'Subshell (x = 1) exited with %d: %s\n' "$rc" "$err_msg"

# ---------------------------------------------------------------------------
# 2. Brace Expansion Runs BEFORE Parameter Expansion
# ---------------------------------------------------------------------------
printf '\n=== 2. Brace Expansion vs Parameter Expansion ===\n'

printf 'Literal sequence {1..3}: %s\n' "$(echo {1..3})"

n=3
printf 'Variable sequence {1..$n} (unexpanded brace): %s\n' "$(echo {1..$n})"

# eval re-runs the 7-stage parser after $n is substituted (ONLY safe if validated!)
if [[ $n =~ ^[0-9]+$ ]]; then
    printf 'Validated eval {1..$n}: %s\n' "$(eval "echo {1..$n}")"
fi

# Recommended safe alternative: C-style for loop (no eval injection risk)
printf 'Safe C-style loop up to n=%d:' "$n"
for ((i = 1; i <= n; i++)); do
    printf ' %d' "$i"
done
printf '\n'

# ---------------------------------------------------------------------------
# 3. Unquoted Word Splitting (IFS) & Pathname Globbing Hazards
# ---------------------------------------------------------------------------
printf '\n=== 3. IFS Word Splitting & Globbing vs Quoting ===\n'

touch "$TMP_DIR/alpha.txt" "$TMP_DIR/beta.txt"
cd "$TMP_DIR"

raw_input="hello   world *"

# Helper that prints argument count and each token boundary
inspect_args() {
    printf '  argc=%d ->' "$#"
    local arg
    for arg in "$@"; do
        printf ' [%s]' "$arg"
    done
    printf '\n'
}

printf 'Unquoted $raw_input (splits on IFS whitespace, then globs *):\n'
# shellcheck disable=SC2086
inspect_args $raw_input

printf 'Double-quoted "$raw_input" (preserves spaces and literal *):\n'
inspect_args "$raw_input"

# ---------------------------------------------------------------------------
# 4. Inverted Boolean Paradigm: Exit Status 0 = Success, Non-Zero = Failure
# ---------------------------------------------------------------------------
printf '\n=== 4. Inverted Boolean Paradigm (0=True, 1..255=False) ===\n'

if true; then
    printf 'true exited with %d -> "if" branch taken (EXIT_SUCCESS)\n' "$?"
fi

set +e
false
false_rc=$?
set -e
printf 'false exited with %d -> non-zero is falsy (EXIT_FAILURE)\n' "$false_rc"

# "if" executes any command and checks its exit status, not a boolean value
printf 'ERROR: connection refused\n' > "$TMP_DIR/app.log"
if grep -q "ERROR" "$TMP_DIR/app.log"; then
    printf 'grep -q matched -> exit 0 -> "if" branch taken\n'
fi

if ! grep -q "CRITICAL" "$TMP_DIR/app.log"; then
    printf 'grep -q missed -> exit 1 -> negated "!" turns 1 into 0\n'
fi
