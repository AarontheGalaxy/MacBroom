#!/usr/bin/env bash
# MacBroom – User application caches (~/Library/Caches).

user_caches_scan() {
    local dir="$HOME/Library/Caches"
    [[ -d "$dir" ]] || { printf '0'; return; }
    # MB_QUICK_SCAN logic is handled inside mb_sum_paths_kb
    mb_sum_paths_kb "$dir"
}

# List items: prints "SIZE_KB|LABEL" lines sorted by size desc
user_caches_list() {
    local dir="$HOME/Library/Caches"
    [[ -d "$dir" ]] || return 0
    local item s
    while IFS= read -r -d '' item; do
        s=$(mb_size_kb "$item")
        printf '%d|%s|%s\n' "$s" "$(basename "$item")" "$item"
    done < <(find "$dir" -maxdepth 1 -mindepth 1 -print0 2>/dev/null) | \
    sort -t'|' -k1 -rn
}

user_caches_clean() {
    local dry_run="${1:-false}"
    local result_file="${2:-}"
    local dir="$HOME/Library/Caches"
    [[ -d "$dir" ]] || return 0

    local cleaned_kb=0
    local item
    while IFS= read -r -d '' item; do
        [[ -e "$item" ]] || continue
        local size_kb
        size_kb=$(mb_size_kb "$item")
        if [[ "$dry_run" == "true" ]]; then
            mb_dim "  would remove: $(basename "$item")  ($(mb_format_kb "$size_kb"))"
            cleaned_kb=$(( cleaned_kb + size_kb ))
        else
            if mb_safe_rm "$item"; then
                cleaned_kb=$(( cleaned_kb + size_kb ))
            fi
        fi
    done < <(find "$dir" -maxdepth 1 -mindepth 1 -print0 2>/dev/null)

    [[ -n "$result_file" ]] && printf '%d' "$cleaned_kb" > "$result_file"
}
