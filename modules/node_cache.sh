#!/usr/bin/env bash
# MacBroom – Node.js and JavaScript package manager caches.

_NODE_CACHE_DIRS=(
    "$HOME/.npm/_cacache"
    "$HOME/.yarn/cache"
    "$HOME/.pnpm-store"
    "$HOME/.bun/install/cache"
    "$HOME/Library/Caches/node-gyp"
)

node_cache_scan() {
    local existing=()
    local d
    for d in "${_NODE_CACHE_DIRS[@]}"; do
        [[ -d "$d" ]] && existing+=("$d")
    done
    [[ ${#existing[@]} -eq 0 ]] && { printf '0'; return; }
    mb_sum_paths_kb "${existing[@]}"
}

node_cache_list() {
    local d s
    for d in "${_NODE_CACHE_DIRS[@]}"; do
        [[ -d "$d" ]] || continue
        s=$(mb_size_kb "$d")
        printf '%d|%s|%s\n' "$s" "$(basename "$d")" "$d"
    done | sort -t'|' -k1 -rn
}

node_cache_clean() {
    local dry_run="${1:-false}"
    local result_file="${2:-}"
    local cleaned_kb=0
    local d size_kb

    for d in "${_NODE_CACHE_DIRS[@]}"; do
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
