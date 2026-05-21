#!/usr/bin/env bash
# MacBroom – Temporary file cleanup (/tmp, /var/tmp).

readonly _TEMP_AGE_DAYS="${MB_TEMP_AGE_DAYS:-3}"

_SYSTEM_TEMP_DIRS=(
    "/private/tmp"
    "/private/var/tmp"
)

temp_files_scan() {
    local total=0 subtotal dir
    for dir in "${_SYSTEM_TEMP_DIRS[@]}"; do
        [[ -d "$dir" ]] || continue
        subtotal=$(find "$dir" -maxdepth 2 -type f -mtime "+${_TEMP_AGE_DAYS}" -print0 2>/dev/null \
            | xargs -0 du -sk 2>/dev/null \
            | awk '{sum+=$1} END{print sum+0}')
        total=$(( total + ${subtotal:-0} ))
    done
    printf '%d' "$total"
}

temp_files_list() {
    local dir f raw s
    for dir in "${_SYSTEM_TEMP_DIRS[@]}"; do
        [[ -d "$dir" ]] || continue
        while IFS= read -r f; do
            [[ -f "$f" ]] || continue
            raw=$(du -sk -- "$f" 2>/dev/null || echo "0 _")
            s=$(printf '%s\n' "$raw" | awk 'NR==1{print $1+0; exit}')
            s="${s:-0}"
            printf '%d|%s|%s\n' "$s" "$(basename "$f")" "$f"
        done < <(find "$dir" -maxdepth 2 -type f -mtime "+${_TEMP_AGE_DAYS}" 2>/dev/null)
    done | sort -t'|' -k1 -rn
}

temp_files_clean() {
    local dry_run="${1:-false}"
    local result_file="${2:-}"
    local cleaned_kb=0
    local dir f raw s

    for dir in "${_SYSTEM_TEMP_DIRS[@]}"; do
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
                local use_sudo="false"
                [[ "$f" == /private/* ]] && mb_has_sudo && use_sudo="true"
                if mb_safe_rm "$f" "$use_sudo"; then
                    cleaned_kb=$(( cleaned_kb + s ))
                fi
            fi
        done < <(find "$dir" -maxdepth 2 -type f -mtime "+${_TEMP_AGE_DAYS}" 2>/dev/null)
    done

    if [[ "$dry_run" != "true" ]] && [[ $cleaned_kb -gt 0 ]]; then
        mb_ok "Temp files  ${C_DIM}($(mb_format_kb "$cleaned_kb") freed)${C_NC}"
    fi

    [[ -n "$result_file" ]] && printf '%d' "$cleaned_kb" > "$result_file"
}
