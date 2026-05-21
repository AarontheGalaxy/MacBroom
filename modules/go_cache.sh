#!/usr/bin/env bash
# MacBroom – Go module download cache and build cache.

go_cache_requires() { echo "go"; }

go_cache_scan() {
    local gocache
    gocache=$(go env GOCACHE 2>/dev/null)
    [[ -z "$gocache" ]] && gocache="$HOME/Library/Caches/go-build"

    local dirs=()
    [[ -d "$HOME/go/pkg/mod/cache" ]] && dirs+=("$HOME/go/pkg/mod/cache")
    [[ -d "$gocache" ]] && dirs+=("$gocache")

    [[ ${#dirs[@]} -eq 0 ]] && { printf '0'; return; }
    mb_sum_paths_kb "${dirs[@]}"
}

go_cache_list() {
    local gocache
    gocache=$(go env GOCACHE 2>/dev/null)
    [[ -z "$gocache" ]] && gocache="$HOME/Library/Caches/go-build"

    local d s
    for d in "$HOME/go/pkg/mod/cache" "$gocache"; do
        [[ -d "$d" ]] || continue
        s=$(mb_size_kb "$d")
        printf '%d|%s|%s\n' "$s" "$(basename "$d")" "$d"
    done | sort -t'|' -k1 -rn
}

go_cache_clean() {
    local dry_run="${1:-false}"
    local result_file="${2:-}"
    local cleaned_kb=0

    local gocache
    gocache=$(go env GOCACHE 2>/dev/null)
    [[ -z "$gocache" ]] && gocache="$HOME/Library/Caches/go-build"

    local d size_kb
    for d in "$HOME/go/pkg/mod/cache" "$gocache"; do
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
