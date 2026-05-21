#!/usr/bin/env bash
# MacBroom – Ruby gem cache and CocoaPods cache.

_ruby_gem_cache_dir() {
    local d="$HOME/.gem/cache"
    if [[ -d "$d" ]]; then
        printf '%s' "$d"
        return
    fi
    # Fallback: find first cache dir under ~/.gem
    local found
    found=$(find "$HOME/.gem" -maxdepth 3 -name cache -type d 2>/dev/null | head -1)
    printf '%s' "${found:-}"
}

ruby_cache_scan() {
    local dirs=()
    local gem_cache
    gem_cache=$(_ruby_gem_cache_dir)
    [[ -n "$gem_cache" && -d "$gem_cache" ]] && dirs+=("$gem_cache")
    [[ -d "$HOME/Library/Caches/CocoaPods" ]] && dirs+=("$HOME/Library/Caches/CocoaPods")

    [[ ${#dirs[@]} -eq 0 ]] && { printf '0'; return; }
    mb_sum_paths_kb "${dirs[@]}"
}

ruby_cache_list() {
    local gem_cache
    gem_cache=$(_ruby_gem_cache_dir)

    local d s
    for d in "$gem_cache" "$HOME/Library/Caches/CocoaPods"; do
        [[ -n "$d" && -d "$d" ]] || continue
        s=$(mb_size_kb "$d")
        printf '%d|%s|%s\n' "$s" "$(basename "$d")" "$d"
    done | sort -t'|' -k1 -rn
}

ruby_cache_clean() {
    local dry_run="${1:-false}"
    local result_file="${2:-}"
    local cleaned_kb=0

    local gem_cache
    gem_cache=$(_ruby_gem_cache_dir)

    local d size_kb
    for d in "$gem_cache" "$HOME/Library/Caches/CocoaPods"; do
        [[ -n "$d" && -d "$d" ]] || continue
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
