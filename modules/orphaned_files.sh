#!/usr/bin/env bash
# MacBroom – Orphaned app support files (no matching installed app).

_ORPHAN_SEARCH_DIRS=(
    "$HOME/Library/Application Support"
    "$HOME/Library/Containers"
    "$HOME/Library/Group Containers"
    "$HOME/Library/Saved Application State"
    "$HOME/Library/Caches"
)

# Bundle ID prefixes that belong to macOS system services, background agents,
# or auto-update frameworks — never installed as user-facing .app bundles.
# Marking these as orphaned would be a false positive.
_ORPHAN_SYSTEM_PREFIXES=(
    "com.apple."
    "com.google.Keystone"
    "com.microsoft.autoupdate"
    "com.adobe.acc"
    "com.adobe.AdobeCreativeCloud"
    "com.crashlytics."
    "io.fabric."
    "com.bugsnag."
    "com.sentry."
)

_is_system_bundle() {
    local name="$1"
    local prefix
    for prefix in "${_ORPHAN_SYSTEM_PREFIXES[@]}"; do
        [[ "$name" == "$prefix"* ]] && return 0
    done
    return 1
}

_get_installed_bundle_ids() {
    # SPOTLIGHT OPTIMIZATION: Extracting bundle IDs directly from the index.
    # This is much faster than running 'mdls' in a loop for every app.
    if command -v mdfind &>/dev/null; then
        mdfind "kMDItemContentType == 'com.apple.application-bundle'" -attr kMDItemCFBundleIdentifier 2>/dev/null \
            | grep "kMDItemCFBundleIdentifier =" \
            | sed 's/.*= "\(.*\)".*/\1/' \
            | grep -v '(null)' | grep -v '^$' | sort -u
    else
        # Fallback: List folders in standard app directories
        ls /Applications ~/Applications 2>/dev/null | sed 's/\.app$//'
    fi
}

_is_likely_bundle_dir() {
    local name="$1"
    # com.spotify.client, org.mozilla.firefox vb.
    [[ "$name" =~ ^(com|org|net|io|co|app)\. ]] && return 0
    return 1
}

orphaned_files_scan() {
    # Quick scan: count mismatched dirs across all _ORPHAN_SEARCH_DIRS
    local installed
    installed=$(_get_installed_bundle_ids 2>/dev/null) || installed=""
    [[ -z "$installed" ]] && { printf '0'; return; }

    local orphan_paths=()
    local dir
    for dir in "${_ORPHAN_SEARCH_DIRS[@]}"; do
        [[ -d "$dir" ]] || continue
        while IFS= read -r -d '' item; do
            local name; name=$(basename "$item")
            _is_system_bundle "$name" && continue
            # In Caches, only check bundle-style names (com.*, org.*, etc.)
            if [[ "$dir" == *"/Caches"* ]]; then
                _is_likely_bundle_dir "$name" || continue
            fi
            if ! grep -qiF "$name" <<< "$installed" 2>/dev/null; then
                orphan_paths+=("$item")
            fi
        done < <(find "$dir" -maxdepth 1 -mindepth 1 -print0 2>/dev/null)
    done

    if [[ ${#orphan_paths[@]} -gt 0 ]]; then
        mb_sum_paths_kb "${orphan_paths[@]}"
    else
        printf '0'
    fi
}

orphaned_files_list() {
    local installed
    installed=$(_get_installed_bundle_ids 2>/dev/null) || installed=""
    [[ -z "$installed" ]] && return 0

    local dir
    for dir in "${_ORPHAN_SEARCH_DIRS[@]}"; do
        [[ -d "$dir" ]] || continue
        local item s
        while IFS= read -r -d '' item; do
            local name; name=$(basename "$item")
            _is_system_bundle "$name" && continue
            # In Caches, only check bundle-style names (com.*, org.*, etc.)
            if [[ "$dir" == *"/Caches"* ]]; then
                _is_likely_bundle_dir "$name" || continue
            fi
            if ! grep -qiF "$name" <<< "$installed" 2>/dev/null; then
                s=$(du -sk -- "$item" 2>/dev/null | awk '{print $1+0; exit}')
                s="${s:-0}"
                printf '%d|%s|%s\n' "$s" "$name" "$item"
            fi
        done < <(find "$dir" -maxdepth 1 -mindepth 1 -print0 2>/dev/null)
    done | sort -t'|' -k1 -rn | head -50
}

orphaned_files_clean() {
    local dry_run="${1:-false}"
    local result_file="${2:-}"
    local cleaned_kb=0

    local installed
    installed=$(_get_installed_bundle_ids 2>/dev/null) || installed=""

    if [[ -z "$installed" ]]; then
        [[ -n "$result_file" ]] && printf '0' > "$result_file"
        return
    fi

    local dir
    for dir in "${_ORPHAN_SEARCH_DIRS[@]}"; do
        [[ -d "$dir" ]] || continue
        local item s
        while IFS= read -r -d '' item; do
            local name; name=$(basename "$item")
            _is_system_bundle "$name" && continue
            # In Caches, only check bundle-style names (com.*, org.*, etc.)
            if [[ "$dir" == *"/Caches"* ]]; then
                _is_likely_bundle_dir "$name" || continue
            fi
            if ! grep -qiF "$name" <<< "$installed" 2>/dev/null; then
                s=$(du -sk -- "$item" 2>/dev/null | awk '{print $1+0; exit}')
                s="${s:-0}"
                if [[ "$dry_run" == "true" ]]; then
                    mb_dim "  would remove: $name  ($(mb_format_kb "$s"))"
                    cleaned_kb=$(( cleaned_kb + s ))
                else
                    if mb_safe_rm "$item"; then
                        cleaned_kb=$(( cleaned_kb + s ))
                    fi
                fi
            fi
        done < <(find "$dir" -maxdepth 1 -mindepth 1 -print0 2>/dev/null)
    done

    [[ -n "$result_file" ]] && printf '%d' "$cleaned_kb" > "$result_file"
}
