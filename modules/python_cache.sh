#!/usr/bin/env bash
# MacBroom – Python and pip package manager caches.

_PYTHON_CACHE_DIRS=(
    "$HOME/.cache/pip"
    "$HOME/Library/Caches/pip"
    "$HOME/.conda/pkgs"
    "$HOME/.poetry/cache"
    "$HOME/.pyenv/cache"
)

python_cache_scan() {
    local existing=()
    local d
    for d in "${_PYTHON_CACHE_DIRS[@]}"; do
        [[ -d "$d" ]] && existing+=("$d")
    done
    [[ ${#existing[@]} -eq 0 ]] && { printf '0'; return; }
    mb_sum_paths_kb "${existing[@]}"
}

python_cache_list() {
    local d s
    for d in "${_PYTHON_CACHE_DIRS[@]}"; do
        [[ -d "$d" ]] || continue
        s=$(mb_size_kb "$d")
        printf '%d|%s|%s\n' "$s" "$(basename "$d")" "$d"
    done | sort -t'|' -k1 -rn
}

python_cache_clean() {
    local dry_run="${1:-false}"
    local result_file="${2:-}"
    local cleaned_kb=0
    local d size_kb

    for d in "${_PYTHON_CACHE_DIRS[@]}"; do
        [[ -d "$d" ]] || continue
        size_kb=$(mb_size_kb "$d")
        if [[ "$dry_run" == "true" ]]; then
            mb_dim "  would remove: $(basename "$d")  ($(mb_format_kb "$size_kb"))"
            cleaned_kb=$(( cleaned_kb + size_kb ))
        else
            mb_safe_rm "$d" || true
            cleaned_kb=$(( cleaned_kb + size_kb ))
        fi
    done

    [[ -n "$result_file" ]] && printf '%d' "$cleaned_kb" > "$result_file"
}
