#!/usr/bin/env bash
# MacBroom – Orphaned app support files finder.

_APP_LEFTOVERS_SEARCH_DIRS=(
    "$HOME/Library/Application Support"
    "$HOME/Library/Caches"
    "$HOME/Library/Preferences"
    "$HOME/Library/Logs"
    "$HOME/Library/Containers"
    "$HOME/Library/Group Containers"
    "$HOME/Library/Saved Application State"
    "$HOME/Library/HTTPStorages"
)

# MB_APP_LEFTOVERS_QUERY — set externally (app name to search)
# This module acts as a search tool driven by MB_APP_LEFTOVERS_QUERY.
# It still exposes standard scan/list/clean functions.

app_leftovers_scan() {
    local query="${MB_APP_LEFTOVERS_QUERY:-}"
    [[ -z "$query" ]] && { printf '0'; return; }
    # Minimum 3 karakter zorunlu
    if (( ${#query} < 3 )); then
        mb_warn "MB_APP_LEFTOVERS_QUERY must be at least 3 characters" >&2
        printf '0'
        return
    fi
    local total=0
    local dir
    for dir in "${_APP_LEFTOVERS_SEARCH_DIRS[@]}"; do
        [[ -d "$dir" ]] || continue
        local subtotal
        subtotal=$(find "$dir" -maxdepth 2 \( -iname "*${query}*" \) \
            -print0 2>/dev/null | xargs -0 du -sk 2>/dev/null | \
            awk '{sum+=$1} END{print sum+0}')
        total=$(( total + ${subtotal:-0} ))
    done
    printf '%d' "$total"
}

app_leftovers_list() {
    local query="${MB_APP_LEFTOVERS_QUERY:-}"
    [[ -z "$query" ]] && return 0
    # Minimum 3 karakter zorunlu
    if (( ${#query} < 3 )); then
        mb_warn "MB_APP_LEFTOVERS_QUERY must be at least 3 characters" >&2
        return 0
    fi
    local dir item s
    for dir in "${_APP_LEFTOVERS_SEARCH_DIRS[@]}"; do
        [[ -d "$dir" ]] || continue
        while IFS= read -r -d '' item; do
            [[ -e "$item" ]] || continue
            s=$(du -sk -- "$item" 2>/dev/null | awk '{print $1+0; exit}')
            s="${s:-0}"
            printf '%d|%s|%s\n' "$s" "$(basename "$item")" "$item"
        done < <(find "$dir" -maxdepth 2 \( -iname "*${query}*" \) \
            -print0 2>/dev/null)
    done | sort -t'|' -k1 -rn
}

app_leftovers_clean() {
    local dry_run="${1:-false}"
    local result_file="${2:-}"
    local query="${MB_APP_LEFTOVERS_QUERY:-}"
    [[ -z "$query" ]] && { [[ -n "$result_file" ]] && printf '0' > "$result_file"; return; }
    # Minimum 3 karakter zorunlu
    if (( ${#query} < 3 )); then
        mb_warn "MB_APP_LEFTOVERS_QUERY must be at least 3 characters" >&2
        [[ -n "$result_file" ]] && printf '0' > "$result_file"
        return
    fi
    local cleaned_kb=0
    local dir item s
    for dir in "${_APP_LEFTOVERS_SEARCH_DIRS[@]}"; do
        [[ -d "$dir" ]] || continue
        while IFS= read -r -d '' item; do
            [[ -e "$item" ]] || continue
            s=$(du -sk -- "$item" 2>/dev/null | awk '{print $1+0; exit}')
            s="${s:-0}"
            if [[ "$dry_run" == "true" ]]; then
                mb_dim "  would remove: $(basename "$item")  ($(mb_format_kb "$s"))"
                cleaned_kb=$(( cleaned_kb + s ))
            else
                if mb_safe_rm "$item"; then
                    cleaned_kb=$(( cleaned_kb + s ))
                fi
            fi
        done < <(find "$dir" -maxdepth 2 \( -iname "*${query}*" \) \
            -print0 2>/dev/null)
    done
    [[ -n "$result_file" ]] && printf '%d' "$cleaned_kb" > "$result_file"
}
