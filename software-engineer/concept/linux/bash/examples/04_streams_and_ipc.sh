#!/usr/bin/env bash
set -Eeuo pipefail

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

emit_streams() {
    printf 'stdout: payload line\n'
    printf 'stderr: diagnostic warning\n' >&2
}

printf '=== 1. >file 2>&1 vs 2>&1 >file (Left-to-Right dup2 Order) ===\n'
emit_streams >"$TMP_DIR/combined.log" 2>&1
printf '[combined.log with >file 2>&1]\n'
cat "$TMP_DIR/combined.log"

{
    emit_streams 2>&1 >"$TMP_DIR/stdout_only.log"
} >"$TMP_DIR/orig_stdout.log"
printf '[stdout_only.log with 2>&1 >file]\n'
cat "$TMP_DIR/stdout_only.log"
printf '[original stdout received stderr]\n'
cat "$TMP_DIR/orig_stdout.log"

printf '\n=== 2. Dynamic FD Allocation, /proc/self/fd, and Shared Offset ===\n'
exec {myfd}<>"$TMP_DIR/fd_demo.txt"
printf 'Allocated FD %d -> %s\n' "$myfd" "$(readlink "/proc/self/fd/$myfd")"
printf 'alpha\nbeta\n' >&"$myfd"
grep '^pos:' "/proc/$$/fdinfo/$myfd"

if ! IFS= read -r -u "$myfd" line; then
    printf 'Immediate read-back on FD %d hit EOF (shared f_pos at end)\n' "$myfd"
fi

# Open a fresh read FD starting at offset 0 (or reopen) to read back
exec {rfd}<"$TMP_DIR/fd_demo.txt"
while IFS= read -r -u "$rfd" line; do
    printf 'Read via FD %d: %s\n' "$rfd" "$line"
done

exec {myfd}>&-
exec {rfd}<&-
printf 'Closed dynamic FDs %d and %d\n' "$myfd" "$rfd"

printf '\n=== 3. Here-Documents (Expanded vs Literal vs Tab-Stripped) & Here-Strings ===\n'
env_name="production"
cat <<EOF
[expanded <<EOF] env=$env_name
EOF
cat <<'EOF'
[literal <<'EOF'] env=$env_name
EOF
cat <<-EOF
	[tab-stripped <<-EOF] indented with literal tab in env=$env_name
EOF
tr '[:lower:]' '[:upper:]' <<< "here-string: $env_name"
printf 'Here-string FD 0 target: %s\n' "$(readlink /proc/self/fd/0 <<< 'probe')"

printf '\n=== 4. Process Substitution (<(...) & >(...)) and Subshell Preservation ===\n'
ls -l <(echo hello)
diff -u <(printf 'a\nb\n') <(printf 'a\nc\n') || true

count=0
while IFS= read -r item; do
    (( ++count ))
    printf 'Item %d: %s\n' "$count" "$item"
done < <(printf 'apple\nbanana\n')
printf 'Count preserved in current shell: %d\n' "$count"

printf '\n=== 5. Named Pipe (FIFO) Producer -> Consumer ===\n'
fifo_path="$TMP_DIR/job.fifo"
mkfifo "$fifo_path"
(
    printf 'job-1:ready\n'
    printf 'job-2:done\n'
) >"$fifo_path" &
producer_pid=$!

while IFS= read -r msg; do
    printf 'Consumed from FIFO: %s\n' "$msg"
done <"$fifo_path"
wait "$producer_pid"

printf '\n=== 6. Null-Delimited Pipeline & Stream Filters ===\n'
mkdir -p "$TMP_DIR/logs"
touch "$TMP_DIR/logs/alpha report.log" "$TMP_DIR/logs/beta  summary.log"
find "$TMP_DIR/logs" -maxdepth 1 -name '*.log' -print0 | sort -z | while IFS= read -r -d '' filepath; do
    printf 'Safely processed file: %s\n' "${filepath##*/}"
done

printf '\n[sed/awk/sort/uniq log summary]\n'
cat <<'EOF' | sed -E 's/^\[([A-Z]+)\] .*/\1/' | awk '{print $1}' | sort | uniq -c | sort -nr
[INFO] server started
[WARN] cache miss
[INFO] request served
[ERROR] timeout
[INFO] connection closed
EOF
