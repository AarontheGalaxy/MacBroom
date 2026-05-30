#!/usr/bin/env bash
# MacBroom – VS Code, Cursor, and Windsurf editor cache directories.

_VSCODE_CACHE_DIRS=(
    "$HOME/Library/Application Support/Code/Cache"
    "$HOME/Library/Application Support/Code/CachedData"
    "$HOME/Library/Application Support/Code/CachedExtensions"
    "$HOME/Library/Application Support/Code/GPUCache"
    "$HOME/Library/Application Support/Code/logs"
    "$HOME/Library/Application Support/Cursor/Cache"
    "$HOME/Library/Application Support/Cursor/CachedData"
    "$HOME/Library/Application Support/Windsurf/Cache"
)

vscode_cache_scan() {
    local existing=()
    local d
    for d in "${_VSCODE_CACHE_DIRS[@]}"; do
        [[ -d "$d" ]] && existing+=("$d")
    done
    [[ ${#existing[@]} -eq 0 ]] && { printf '0'; return; }
    mb_sum_paths_kb "${existing[@]}"
}

vscode_cache_list() {
    local d s
    for d in "${_VSCODE_CACHE_DIRS[@]}"; do
        [[ -d "$d" ]] || continue
        s=$(mb_size_kb "$d")
        printf '%d|%s|%s\n' "$s" "$(basename "$d") ($(dirname "$d" | xargs basename))" "$d"
    done | sort -t'|' -k1 -rn
}

vscode_cache_clean() {
    local dry_run="${1:-false}"
    local result_file="${2:-}"
    local cleaned_kb=0
    local d size_kb

    for d in "${_VSCODE_CACHE_DIRS[@]}"; do
        [[ -d "$d" ]] || continue
        size_kb=$(mb_size_kb "$d")
        if [[ "$dry_run" == "true" ]]; then
            mb_dim "  would remove: $(basename "$d")  ($(mb_format_kb "$size_kb"))"
            cleaned_kb=$(( cleaned_kb + size_kb ))
        else
            if mb_safe_rm "$d"; then
                cleaned_kb=$(( cleaned_kb + size_kb ))
            fi
        fi
    done

    [[ -n "$result_file" ]] && printf '%d' "$cleaned_kb" > "$result_file"
}
