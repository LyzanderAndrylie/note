#!/usr/bin/env bash
set -Eeuo pipefail

TMP_DIR=$(mktemp -d)
cleanup() {
    local exit_code=$?
    rm -rf "$TMP_DIR"
    printf '[EXIT trap] cleaned up %s (script exit=%d)\n' "$TMP_DIR" "$exit_code"
}
trap cleanup EXIT

echo "=== 1. Exit Code 8-Bit Truncation ==="
(exit 256)
printf 'exit 256 -> %d\n' "$?"

set +e
(exit 257)
rc=$?
set -e
printf 'exit 257 -> %d\n' "$rc"

echo ""
echo "=== 2. PIPESTATUS in Multi-Stage Pipeline ==="
pipe_statuses=()
if true | false | true; then
    pipe_statuses=("${PIPESTATUS[@]}")
else
    pipe_statuses=("${PIPESTATUS[@]}")
fi
printf 'true | false | true -> PIPESTATUS=(%s)\n' "${pipe_statuses[*]}"

echo ""
echo "=== 3. Strict Mode Gotchas: Declaration Masking & Arithmetic ==="
masked_local_demo() {
    local val=$(false)
    printf 'masked local: exit=%d (set -e missed failure)\n' "$?"
}
masked_local_demo

split_local_demo() {
    local val
    val=$(false)
    printf 'unreachable: %s\n' "$val"
}
set +e
(
    set -Eeuo pipefail
    split_local_demo
)
rc=$?
set -e
printf 'split local: caught exit=%d under set -e\n' "$rc"

count=0
arith_rc=0
(( count++ )) || arith_rc=$?
printf 'post-increment from 0: count=%d, expr_rc=%d\n' "$count" "$arith_rc"

count=0
(( ++count ))
printf 'pre-increment from 0: count=%d, expr_rc=%d\n' "$count" "$?"

echo ""
echo "=== 4. ERR Trap Stack Diagnostics ==="
set +e
(
    set -Eeuo pipefail
    on_err() {
        local rc=$?
        local line=$1
        local cmd=$2
        printf '[ERR trap] rc=%d source=%s line=%s func=%s cmd=%q\n' \
            "$rc" "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}" "$line" "${FUNCNAME[1]:-main}" "$cmd" >&2
    }
    trap 'on_err "$LINENO" "$BASH_COMMAND"' ERR

    inner_step() {
        false
    }
    outer_step() {
        inner_step
    }
    outer_step
) 2>&1
rc=$?
set -e
printf 'subshell exited with %d after ERR trap\n' "$rc"

echo ""
echo "=== 5. Bounded Parallel Worker Pool (max 2 of 5 tasks) ==="
run_task() {
    local id=$1
    local out_file="$TMP_DIR/task_${id}.log"
    sleep 0.05
    if (( id == 4 )); then
        printf 'task %d failed\n' "$id" > "$out_file"
        return 2
    fi
    printf 'task %d ok\n' "$id" > "$out_file"
}

reap_one_worker() {
    local has_wait_p=$1
    local done_pid=""
    local job_rc=0

    if (( has_wait_p )); then
        wait -n -p done_pid || job_rc=$?
        printf 'worker pid=%s exited rc=%d\n' "$done_pid" "$job_rc"
    else
        wait -n || job_rc=$?
        printf 'worker slot freed rc=%d\n' "$job_rc"
    fi
    return "$job_rc"
}

run_pool() {
    local max_jobs=2
    local running=0
    local pool_rc=0
    local -a tasks=(1 2 3 4 5)
    local has_wait_p=0

    if (( BASH_VERSINFO[0] > 5 || (BASH_VERSINFO[0] == 5 && BASH_VERSINFO[1] >= 1) )); then
        has_wait_p=1
    fi

    for id in "${tasks[@]}"; do
        while (( running >= max_jobs )); do
            reap_one_worker "$has_wait_p" || pool_rc=$?
            (( --running ))
        done
        run_task "$id" &
        (( ++running ))
    done

    while (( running > 0 )); do
        reap_one_worker "$has_wait_p" || pool_rc=$?
        (( --running ))
    done

    return "$pool_rc"
}

pool_status=0
run_pool || pool_status=$?
printf 'pool aggregated exit=%d; outputs: ' "$pool_status"
for id in 1 2 3 4 5; do
    printf '[%s] ' "$(cat "$TMP_DIR/task_${id}.log")"
done
printf '\n'

echo ""
echo "=== 6. Scoped Xtrace with Informative PS4 ==="
traced_helper() {
    local name=$1
    local msg="hello,$name"
    printf 'helper output: %s\n' "$msg"
}

OLD_PS4=$PS4
export PS4='+ [${BASH_SOURCE[0]##*/}:${LINENO}:${FUNCNAME[0]:-main}()] '
set -x
traced_helper "world"
{ set +x; } 2>/dev/null
PS4=$OLD_PS4
