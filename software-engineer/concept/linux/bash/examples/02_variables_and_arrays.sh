#!/usr/bin/env bash
set -Eeuo pipefail

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

# ---------------------------------------------------------------------------
# 1. Shell Variables vs Kernel Environment Variables (/proc/self/environ)
# ---------------------------------------------------------------------------
printf '=== 1. Shell Variables vs Kernel Environment ===\n'

LOCAL_ONLY="shell_table_only"
export EXPORTED_VAR="copied_to_envp"

printf 'Parent shell: LOCAL_ONLY=%s EXPORTED_VAR=%s\n' "$LOCAL_ONLY" "$EXPORTED_VAR"

printf 'Child /proc/$$/environ matches:\n'
bash -c 'tr "\0" "\n" < /proc/$$/environ | grep -E "^(LOCAL_ONLY|EXPORTED_VAR|INLINE_ENV)=" || true'

printf 'Single-command inline prefix:\n'
INLINE_ENV="ephemeral_ok" bash -c 'tr "\0" "\n" < /proc/$$/environ | grep -E "^(EXPORTED_VAR|INLINE_ENV)=" | sort || true'
printf 'Parent after inline prefix: INLINE_ENV=%s\n\n' "${INLINE_ENV:-unset}"

# ---------------------------------------------------------------------------
# 2. Quoting Semantics & Positional Parameters ("$@" vs "$*")
# ---------------------------------------------------------------------------
printf '=== 2. Quoting Semantics & Positional Parameters ===\n'

service="auth api"
printf 'Single quotes : %s\n' '$service \n literal'
printf 'Double quotes : %s\n' "service=$service"
printf 'ANSI-C quotes : %s' $'line1\n\tline2\x21\n'

inspect_args() {
    local label="$1"
    shift
    printf '%s -> $#=%d |' "$label" "$#"
    local arg
    for arg in "$@"; do
        printf ' [%s]' "$arg"
    done
    printf '\n'
}

wrapper() {
    inspect_args 'Forwarding "$@"' "$@"
    inspect_args 'Forwarding "$*"' "$*"
    (
        IFS='|'
        inspect_args 'Forwarding "$*" (IFS=|)' "$*"
    )
}

wrapper "first arg" "second arg" "third"
printf '\n'

# ---------------------------------------------------------------------------
# 3. Zero-Fork Parameter Expansions
# ---------------------------------------------------------------------------
printf '=== 3. Zero-Fork Parameter Expansions ===\n'

filepath="/var/log/app/service.tar.gz"
printf 'Original path : %s (length=%d)\n' "$filepath" "${#filepath}"
printf 'Basename (##*/): %s\n' "${filepath##*/}"
printf 'Dirname  (%%/*) : %s\n' "${filepath%/*}"
printf 'Stem     (%%%%.*) : %s\n' "${filepath%%.*}"
printf 'Trim 1st (#*/) : %s\n' "${filepath#*/}"
printf 'Replace 1st    : %s\n' "${filepath/service/worker}"
printf 'Replace all    : %s\n' "${filepath//\//_}"

unset unset_var || true
empty_var=""
printf 'Default :- (unset) : %s\n' "${unset_var:-fallback}"
printf 'Default :- (empty) : %s\n' "${empty_var:-fallback}"
printf 'Default -  (empty) : [%s]\n' "${empty_var-fallback}"
printf 'Assign  :=         : %s (now=%s)\n' "${assigned_var:=init_val}" "$assigned_var"
printf 'Alternate :+       : %s\n' "${assigned_var:+present}"
printf 'Required :?        : %s\n' "$( (printf '%s\n' "${unset_var:?missing required key}") 2>&1 || true )"

token="abcdef1234"
printf 'Slice :0:6         : %s\n' "${token:0:6}"
printf 'Neg slice (space)  : %s\n' "${token: -4}"

env_name="prodCluster"
printf 'Case ^ / ^^        : %s / %s\n' "${env_name^}" "${env_name^^}"
printf 'Case , / ,,        : %s / %s\n' "${env_name,}" "${env_name,,}"

target_host="10.0.1.42"
ptr="target_host"
declare -n host_ref="target_host"
printf 'Indirect ${!ptr}   : %s | Nameref: %s\n' "${!ptr}" "$host_ref"
host_ref="10.0.1.99"
printf 'After nameref write: target_host=%s\n\n' "$target_host"

# ---------------------------------------------------------------------------
# 4. Indexed Arrays (Sparse) & Associative Hash Maps
# ---------------------------------------------------------------------------
printf '=== 4. Indexed & Associative Arrays ===\n'

arr=("alpha" "beta gamma" "delta" "epsilon")
arr+=("zeta")
printf 'Count=%d | Slice(1:2)=[%s] [%s]\n' "${#arr[@]}" "${arr[@]:1:2}"

unset 'arr[1]'
printf 'After unset arr[1] -> count=%d | active indices=%s\n' "${#arr[@]}" "${!arr[*]}"
for idx in "${!arr[@]}"; do
    printf '  arr[%s]=%s\n' "$idx" "${arr[$idx]}"
done

declare -A ports=(
    [http]="80"
    [https]="443"
    [ssh]="22"
)
k="grpc"
printf 'Map size=%d | http=%s | %s=%s\n' "${#ports[@]}" "${ports[http]}" "$k" "${ports[$k]:-missing}"

unset 'ports[ssh]'
printf 'Remaining map entries (%d):\n' "${#ports[@]}"
mapfile -t sorted_keys < <(printf '%s\n' "${!ports[@]}" | sort)
for k in "${sorted_keys[@]}"; do
    printf '  ports[%s]=%s\n' "$k" "${ports[$k]}"
done

# Verify TMP_DIR is usable and cleaned by EXIT trap
printf 'temp_ok\n' > "$TMP_DIR/check.txt"
