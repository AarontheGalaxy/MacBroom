#!/usr/bin/env bash
# MacBroom – System & user log files, crash reports.

readonly _LOG_AGE_DAYS="${MB_LOG_AGE_DAYS:-7}"

_USER_LOG_DIRS=(
    "$HOME/Library/Logs"
)

_SYSTEM_LOG_DIRS=(
    "/Library/Logs"
    "/private/var/log"
    "/private/var/db/diagnostics"
    "/private/var/db/DiagnosticPipeline"
    "/private/var/db/powerlog"
)

_LOG_EXTENSIONS=( "*.log" "*.gz" "*.asl" "*.tracev3" "*.crash" "*.ips" "*.diag" )

# Build a find -name expression for log extensions
_log_find_name_args() {
    local first=true
    local ext
    for ext in "${_LOG_EXTENSIONS[@]}"; do
        if [[ "$first" == "true" ]]; then
            printf '%s' "( -name $ext"
            first=false
        else
            printf ' %s' "-o -name $ext"
        fi
    done
    printf ' %s' ")"
}

# ── Scan ───────────────────────────────────────────────────────
system_logs_scan() {
    local total=0
    local dir f raw s

    local subtotal
    for dir in "${_USER_LOG_DIRS[@]}"; do
        [[ -d "$dir" ]] || continue
        subtotal=$(find "$dir" -type f \
            ! -path "${MB_OP_LOG_DIR}/*" \
            \( -name "*.log" -o -name "*.gz" -o -name "*.asl" \
               -o -name "*.tracev3" -o -name "*.crash" -o -name "*.ips" \
               -o -name "*.diag" \) \
            -mtime "+${_LOG_AGE_DAYS}" -print0 2>/dev/null \
            | xargs -0 du -sk 2>/dev/null \
            | awk '{sum+=$1} END{print sum+0}')
        total=$(( total + ${subtotal:-0} ))
    done

    if mb_has_sudo; then
        for dir in "${_SYSTEM_LOG_DIRS[@]}"; do
            [[ -d "$dir" ]] || continue
            subtotal=$(sudo find "$dir" -type f \
                \( -name "*.log" -o -name "*.gz" -o -name "*.asl" \
                   -o -name "*.tracev3" -o -name "*.crash" -o -name "*.ips" \) \
                -mtime "+${_LOG_AGE_DAYS}" -print0 2>/dev/null \
                | xargs -0 sudo du -sk 2>/dev/null \
                | awk '{sum+=$1} END{print sum+0}')
            total=$(( total + ${subtotal:-0} ))
        done
    fi

    printf '%d' "$total"
}

system_logs_list() {
    local dir f raw s
    for dir in "${_USER_LOG_DIRS[@]}"; do
        [[ -d "$dir" ]] || continue
        while IFS= read -r f; do
            [[ -f "$f" ]] || continue
            raw=$(du -sk -- "$f" 2>/dev/null || echo "0 _")
            s=$(printf '%s\n' "$raw" | awk 'NR==1{print $1+0; exit}')
            s="${s:-0}"
            printf '%d|%s|%s\n' "$s" "$(basename "$f")" "$f"
        done < <(find "$dir" -type f \
            ! -path "${MB_OP_LOG_DIR}/*" \
            \( -name "*.log" -o -name "*.crash" -o -name "*.ips" -o -name "*.diag" \) \
            -mtime "+${_LOG_AGE_DAYS}" 2>/dev/null)
    done | sort -t'|' -k1 -rn | head -50
}

# ── Clean ──────────────────────────────────────────────────────
system_logs_clean() {
    local dry_run="${1:-false}"
    local result_file="${2:-}"
    local cleaned_kb=0
    local dir f raw s

    # User logs (no sudo)
    for dir in "${_USER_LOG_DIRS[@]}"; do
        [[ -d "$dir" ]] || continue
        while IFS= read -r f; do
            [[ -f "$f" ]] || continue
            raw=$(du -sk -- "$f" 2>/dev/null || echo "0 _")
            s=$(printf '%s\n' "$raw" | awk 'NR==1{print $1+0; exit}')
            s="${s:-0}"
            if [[ "$dry_run" == "true" ]]; then
                mb_dim "  would remove: $(basename "$f")  ($(mb_format_kb "$s"))"
                cleaned_kb=$(( cleaned_kb + s ))
            else
                if mb_safe_rm "$f" "false"; then
                    cleaned_kb=$(( cleaned_kb + s ))
                fi
            fi
        done < <(find "$dir" -type f \
            ! -path "${MB_OP_LOG_DIR}/*" \
            \( -name "*.log" -o -name "*.gz" -o -name "*.asl" \
               -o -name "*.tracev3" -o -name "*.crash" -o -name "*.ips" \
               -o -name "*.diag" \) \
            -mtime "+${_LOG_AGE_DAYS}" 2>/dev/null)
    done

    if [[ "$dry_run" != "true" ]] && [[ $cleaned_kb -gt 0 ]]; then
        mb_ok "User logs  ${C_DIM}($(mb_format_kb "$cleaned_kb") freed)${C_NC}"
    fi

    # System logs (needs sudo)
    if mb_has_sudo; then
        local sys_cleaned=0
        for dir in "${_SYSTEM_LOG_DIRS[@]}"; do
            [[ -d "$dir" ]] || continue
            while IFS= read -r f; do
                [[ -f "$f" ]] || continue
                raw=$(sudo du -sk -- "$f" 2>/dev/null || echo "0 _")
                s=$(printf '%s\n' "$raw" | awk 'NR==1{print $1+0; exit}')
                s="${s:-0}"
                if [[ "$dry_run" == "true" ]]; then
                    mb_dim "  would remove (sudo): $(basename "$f")  ($(mb_format_kb "$s"))"
                else
                    if mb_safe_rm "$f" "true"; then
                        sys_cleaned=$(( sys_cleaned + s ))
                        cleaned_kb=$(( cleaned_kb + s ))
                    fi
                fi
            done < <(sudo find "$dir" -type f \
                \( -name "*.log" -o -name "*.gz" -o -name "*.asl" \
                   -o -name "*.tracev3" -o -name "*.crash" -o -name "*.ips" \) \
                -mtime "+${_LOG_AGE_DAYS}" 2>/dev/null)
        done
        if [[ "$dry_run" != "true" ]] && [[ $sys_cleaned -gt 0 ]]; then
            mb_ok "System logs  ${C_DIM}($(mb_format_kb "$sys_cleaned") freed)${C_NC}"
        fi
    else
        mb_dim "  System logs skipped (run with sudo for full access)"
    fi

    [[ -n "$result_file" ]] && printf '%d' "$cleaned_kb" > "$result_file"
}
