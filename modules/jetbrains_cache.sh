#!/usr/bin/env bash
# MacBroom – JetBrains IDE cache and log directories.

_JETBRAINS_BASE_DIRS=(
    "$HOME/Library/Caches/JetBrains"
    "$HOME/Library/Logs/JetBrains"
)

jetbrains_cache_scan() {
    local existing=()
    local d
    for d in "${_JETBRAINS_BASE_DIRS[@]}"; do
        [[ -d "$d" ]] && existing+=("$d")
    done
    [[ ${#existing[@]} -eq 0 ]] && { printf '0'; return; }
    mb_sum_paths_kb "${existing[@]}"
}

jetbrains_cache_list() {
    local base s item
    for base in "${_JETBRAINS_BASE_DIRS[@]}"; do
        [[ -d "$base" ]] || continue
        while IFS= read -r -d '' item; do
            s=$(mb_size_kb "$item")
            printf '%d|%s|%s\n' "$s" "$(basename "$item")" "$item"
        done < <(find "$base" -maxdepth 1 -mindepth 1 -print0 2>/dev/null)
    done | sort -t'|' -k1 -rn
}

jetbrains_cache_clean() {
    local dry_run="${1:-false}"
    local result_file="${2:-}"
    local cleaned_kb=0
    local base item size_kb

    for base in "${_JETBRAINS_BASE_DIRS[@]}"; do
        [[ -d "$base" ]] || continue
        while IFS= read -r -d '' item; do
            [[ -e "$item" ]] || continue
            size_kb=$(mb_size_kb "$item")
            if [[ "$dry_run" == "true" ]]; then
                mb_dim "  would remove: $(basename "$item")  ($(mb_format_kb "$size_kb"))"
                cleaned_kb=$(( cleaned_kb + size_kb ))
            else
                mb_safe_rm "$item" || true
                cleaned_kb=$(( cleaned_kb + size_kb ))
            fi
        done < <(find "$base" -maxdepth 1 -mindepth 1 -print0 2>/dev/null)
    done

    [[ -n "$result_file" ]] && printf '%d' "$cleaned_kb" > "$result_file"
}
