#!/usr/bin/env bash
set -Eeuo pipefail

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

print_section() {
    printf '\n=== %s ===\n' "$1"
}

proc_ids() {
    local target_pid="$1"
    grep -E '^(Pid|PPid):' "/proc/${target_pid}/status" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/ $//'
}

print_section "1. Command Resolution Hierarchy (type -a and command -v)"
for cmd in "[[" "cd" "echo" "ls"; do
    printf 'command -v %-4s -> %s\n' "$cmd" "$(command -v "$cmd")"
done

printf '\ntype -a details:\n'
type -a "[[" "cd" "echo" "ls"

echo() {
    printf '[custom function] %s\n' "$*"
}
printf '\nAfter defining echo() function:\n'
type -a echo
printf 'Call echo: '
echo "hello"
printf 'Call builtin echo: '
builtin echo "hello"
unset -f echo

print_section "2. \$\$ vs \$BASHPID vs \$BASH_SUBSHELL and /proc/\$BASHPID/status"
cur_pid=$BASHPID
printf 'Main shell       : $$=%s  BASHPID=%s  BASH_SUBSHELL=%s  [%s]\n' \
    "$$" "$cur_pid" "$BASH_SUBSHELL" "$(proc_ids "$cur_pid")"

{
    cur_pid=$BASHPID
    printf 'Group { ...; }   : $$=%s  BASHPID=%s  BASH_SUBSHELL=%s  [%s]\n' \
        "$$" "$cur_pid" "$BASH_SUBSHELL" "$(proc_ids "$cur_pid")"
}

(
    cur_pid=$BASHPID
    printf 'Subshell (...)   : $$=%s  BASHPID=%s  BASH_SUBSHELL=%s  [%s]\n' \
        "$$" "$cur_pid" "$BASH_SUBSHELL" "$(proc_ids "$cur_pid")"
    (
        cur_pid=$BASHPID
        printf 'Nested ((...))   : $$=%s  BASHPID=%s  BASH_SUBSHELL=%s  [%s]\n' \
            "$$" "$cur_pid" "$BASH_SUBSHELL" "$(proc_ids "$cur_pid")"
    )
)

captured=$(
    cur_pid=$BASHPID
    printf 'Cmd subst $(...) : $$=%s  BASHPID=%s  BASH_SUBSHELL=%s  [%s]' \
        "$$" "$cur_pid" "$BASH_SUBSHELL" "$(proc_ids "$cur_pid")"
)
printf '%s\n' "$captured"

print_section "3. State Mutation: { ...; } vs ( ... )"
orig_dir="$PWD"
state="initial"

{
    state="mutated-in-group"
    cd "$TMP_DIR"
    printf 'Inside { ...; }  : state=%s  PWD=%s\n' "$state" "$PWD"
}
printf 'After  { ...; }  : state=%s  PWD=%s\n' "$state" "$PWD"

(
    state="mutated-in-subshell"
    cd "$orig_dir"
    printf 'Inside ( ... )   : state=%s  PWD=%s\n' "$state" "$PWD"
)
printf 'After  ( ... )   : state=%s  PWD=%s (unchanged)\n' "$state" "$PWD"
cd "$orig_dir"

print_section "4. The Pipeline Subshell Trap & Its 3 Fixes"
data_file="$TMP_DIR/items.txt"
printf 'alpha\nbeta\ngamma\n' > "$data_file"

# Bug: pipe forces `while` into a subshell; count stays 0 in the parent
count=0
printf 'alpha\nbeta\ngamma\n' | while IFS= read -r _line; do
    count=$((count + 1))
done
printf 'Buggy pipe (printf | while)        : count=%d (lost in subshell)\n' "$count"

# Fix 1: Input redirection from a file (< "$file") runs `while` in current shell
count=0
while IFS= read -r _line; do
    count=$((count + 1))
done < "$data_file"
printf 'Fix 1 (< "$file" redirection)      : count=%d\n' "$count"

# Fix 2: Process substitution (< <(cmd)) keeps `while` in current shell
count=0
while IFS= read -r _line; do
    count=$((count + 1))
done < <(printf 'alpha\nbeta\ngamma\n')
printf 'Fix 2 (< <(cmd) process subst)     : count=%d\n' "$count"

# Fix 3: shopt -s lastpipe (requires job control off via set +m)
set +m
shopt -s lastpipe
count=0
printf 'alpha\nbeta\ngamma\n' | while IFS= read -r _line; do
    count=$((count + 1))
done
printf 'Fix 3 (shopt -s lastpipe + set +m) : count=%d\n' "$count"
shopt -u lastpipe
