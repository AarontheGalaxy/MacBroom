#!/usr/bin/env bash
# MacBroom – Homebrew download cache, old formula versions, and unused dependencies.

brew_cache_requires() { printf 'brew'; }

_brew_cache_dir() {
    local d
    d=$(brew --cache 2>/dev/null)
    if [[ -n "$d" && -d "$d" ]]; then
        printf '%s' "$d"
    else
        printf '%s' "$HOME/Library/Caches/Homebrew"
    fi
}

brew_cache_scan() {
    local cache_dir
    cache_dir=$(_brew_cache_dir)
    [[ -d "$cache_dir" ]] || { printf '0'; return; }
    mb_size_kb "$cache_dir"
}

brew_cache_list() {
    local cache_dir
    cache_dir=$(_brew_cache_dir)
    [[ -d "$cache_dir" ]] || return 0
    find "$cache_dir" -maxdepth 1 -mindepth 1 -print0 2>/dev/null | \
        while IFS= read -r -d '' f; do
            local s; s=$(mb_size_kb "$f")
            printf '%d|%s|%s\n' "$s" "$(basename "$f")" "$f"
        done | sort -t'|' -k1 -rn
}

brew_cache_clean() {
    local dry_run="${1:-false}"
    local result_file="${2:-}"
    local cleaned_kb=0

    local cache_dir
    cache_dir=$(_brew_cache_dir)

    if [[ "$dry_run" == "true" ]]; then
        local cache_size=0
        [[ -d "$cache_dir" ]] && cache_size=$(mb_size_kb "$cache_dir")
        mb_dim "  would remove: Homebrew download cache  ($(mb_format_kb "$cache_size"))"
        local preview
        preview=$(brew cleanup -n 2>/dev/null | grep -c 'Removing' 2>/dev/null || true)
        [[ "${preview:-0}" -gt 0 ]] && \
            mb_dim "  brew cleanup would remove $preview old formula/cask version(s)"
        cleaned_kb=$cache_size
        [[ -n "$result_file" ]] && printf '%d' "$cleaned_kb" > "$result_file"
        return 0
    fi

    # Delete items inside the download cache directory one-by-one so
    # mb_safe_rm can validate each path against the allowlist.
    if [[ -d "$cache_dir" ]]; then
        local f s
        while IFS= read -r -d '' f; do
            s=$(mb_size_kb "$f")
            if mb_safe_rm "$f"; then
                cleaned_kb=$(( cleaned_kb + s ))
            fi
        done < <(find "$cache_dir" -maxdepth 1 -mindepth 1 -print0 2>/dev/null)
    fi

    # Remove old installed formula/cask versions and unused dependencies.
    # These live in /opt/homebrew/Cellar (outside the safe-path list) so
    # we delegate to brew instead of using mb_safe_rm.
    brew cleanup --prune=all 2>/dev/null || true
    brew autoremove 2>/dev/null || true

    [[ -n "$result_file" ]] && printf '%d' "$cleaned_kb" > "$result_file"
}
