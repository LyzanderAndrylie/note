#!/usr/bin/env bash
set -Eeuo pipefail

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "=== 1. [ ] vs [[ ]] vs (( )) ==="
empty=""
spaced="hello world"

# POSIX [ ... ]: must quote variables; unquoted $empty collapses to [ -z ] (error or wrong)
if [ -n "$spaced" ] && [ -z "$empty" ]; then
  echo "[ ]: quoted variables succeeded"
fi

# [[ ... ]]: Bash keyword immune to word-splitting and pathname globbing
if [[ -n $spaced && $spaced == hello* ]]; then
  echo "[[ ]]: unquoted \$spaced matched glob 'hello*'"
fi

# [[ ... ]] POSIX ERE regex (=~) populates BASH_REMATCH
tag="release-42"
if [[ $tag =~ ^([a-z]+)-([0-9]+)$ ]]; then
  echo "[[ =~ ]]: full='${BASH_REMATCH[0]}', name='${BASH_REMATCH[1]}', num='${BASH_REMATCH[2]}'"
fi

# (( ... )): C-style arithmetic; non-zero result -> exit 0 (truthy), 0 result -> exit 1 (falsy)
(( 0 )) || echo "(( 0 )): zero evaluated to exit status $?"
if (( 2 + 3 == 5 )); then
  echo "(( 2 + 3 == 5 )): non-zero (1) evaluated to exit status 0"
fi

echo ""
echo "=== 2. File & Inode Tests ==="
mkdir -p "$TMP_DIR/sub"
: > "$TMP_DIR/empty.txt"
printf 'payload\n' > "$TMP_DIR/older.txt"
printf 'newer-payload\n' > "$TMP_DIR/newer.txt"
touch -d "2025-01-01 00:00:00 UTC" "$TMP_DIR/older.txt"
touch -d "2026-01-01 00:00:00 UTC" "$TMP_DIR/newer.txt"
ln -s "$TMP_DIR/newer.txt" "$TMP_DIR/link.txt"

[[ -d "$TMP_DIR/sub" ]] && echo "-d sub: directory"
[[ ! -s "$TMP_DIR/empty.txt" ]] && echo "-s empty.txt: size is 0"
[[ -s "$TMP_DIR/newer.txt" ]] && echo "-s newer.txt: non-empty regular file"
[[ -L "$TMP_DIR/link.txt" && -f "$TMP_DIR/link.txt" ]] && echo "-L & -f link.txt: symlink pointing to a regular file"
[[ "$TMP_DIR/newer.txt" -nt "$TMP_DIR/older.txt" ]] && echo "-nt: newer.txt mtime > older.txt mtime"

echo ""
echo "=== 3. case Fallthrough Modes & A && B || C Pitfall ==="
describe_code() {
  local code="$1"
  case "$code" in
    start)
      echo "  [;;] matched 'start' (stops here)"
      ;;
    warn)
      echo "  [;&] matched 'warn' -> unconditional fallthrough"
      ;&
    never_tested_target)
      echo "  [;&] executed next body without pattern check"
      ;;
    alpha*)
      echo "  [;;&] matched 'alpha*' -> continuing pattern tests"
      ;;&
    *beta)
      echo "  [;;&] also matched '*beta'"
      ;;&
    exact)
      echo "  [;;&] should not print for alphabeta"
      ;;
  esac
}

echo "Case 1 (start with ;;):"
describe_code "start"
echo "Case 2 (warn with ;&):"
describe_code "warn"
echo "Case 3 (alphabeta with ;;&):"
describe_code "alphabeta"

echo "Short-circuit pitfall (A && B || C when B fails):"
check_true() { return 0; }
fail_step() { return 1; }
check_true && fail_step || echo "  PITFALL: fallback C ran because B failed, even though A succeeded!"

if check_true; then
  fail_step || echo "  SAFE if/else: B failure handled explicitly inside 'then' branch"
else
  echo "  SAFE if/else: A failed"
fi

echo ""
echo "=== 4. Canonical Line-by-Line Reader ==="
printf '  leading and trailing  \nback\\slash\\tliteral\\n\nno-final-newline' > "$TMP_DIR/lines.txt"
line_no=0
while IFS= read -r line || [[ -n "$line" ]]; do
  (( ++line_no ))
  printf '  line %d: [%s]\n' "$line_no" "$line"
done < "$TMP_DIR/lines.txt"

echo ""
echo "=== 5. Dynamic Scoping & Three Function Return Patterns ==="
callee_mutate() {
  echo "  callee_mutate sees caller secret='$secret'"
  secret="mutated-by-callee"
}

callee_shadow() {
  local secret="shadowed-in-callee"
  echo "  callee_shadow sees local secret='$secret'"
}

caller_fn() {
  local secret="caller-initial"
  echo "  caller_fn start: secret='$secret'"
  callee_mutate
  echo "  caller_fn after callee_mutate: secret='$secret'"
  callee_shadow
  echo "  caller_fn after callee_shadow: secret='$secret'"
}

caller_fn
echo "  outer scope secret='${secret:-<unset>}'"

# Pattern 1: Exit status only (0..255)
is_even() {
  (( $1 % 2 == 0 ))
}
if is_even 8; then
  echo "Pattern 1 (return status): is_even 8 -> exit 0 (true)"
fi

# Pattern 2: Stdout capture via $(...) spawns a subshell fork
compute_via_stdout() {
  printf '%s (subshell BASHPID=%s)' "$(( $1 * 2 ))" "$BASHPID"
}
parent_pid="$BASHPID"
captured=$(compute_via_stdout 21)
echo "Pattern 2 (stdout capture): parent BASHPID=$parent_pid, result='$captured'"

# Pattern 3: Nameref mutation (local -n) runs in the same process (zero fork)
compute_via_nameref() {
  local -n _out="$1"
  local input="$2"
  _out="$(( input * 2 )) (same-process BASHPID=$BASHPID)"
}
result=""
compute_via_nameref result 21
echo "Pattern 3 (local -n nameref): parent BASHPID=$parent_pid, result='$result'"
