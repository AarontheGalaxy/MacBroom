#!/usr/bin/env bash
# MacBroom – Orphaned app support files and orphaned ~/. dotfile directories.

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

# ── Orphan dotfile detection ───────────────────────────────────
# Dotfile directory names whose binary counterpart is commonly missing from PATH
# but are still actively used (kept by a background agent, a GUI app, etc.).
# We exclude these to avoid false positives.
_DOTFILE_KNOWN_TOOLS=(
    npm yarn pnpm bun cargo gem gradle maven conda poetry pyenv
    flutter dart go rust ruby java python python3 node
    ollama lmstudio huggingface
    brew git svn hg
    docker kubectl helm terraform ansible
    gcloud aws azure
    code cursor windsurf idea pycharm webstorm goland
    vim nvim emacs nano
    tmux screen zellij
    iterm2 alacritty warp ghostty
    rbenv volta nvm asdf sdkman tfenv gvm
    oh-my-zsh antigen antibody zplug zgen zinit
    fzf ripgrep fd bat eza lsd
    jenv jabba
    conan
)

_dotfile_binary_known() {
    local name="${1#.}"   # strip leading dot
    local t
    for t in "${_DOTFILE_KNOWN_TOOLS[@]}"; do
        [[ "${name,,}" == "${t,,}" ]] && return 0
    done
    # Also check if a binary with this name actually exists in PATH
    command -v "$name" &>/dev/null && return 0
    return 1
}

# Returns null-delimited paths of ~/. directories with no matching binary.
_orphan_dotfile_find() {
    local d name
    while IFS= read -r -d '' d; do
        name=$(basename "$d")
        # Skip non-directories and protected paths
        [[ -d "$d" ]] || continue
        # Check MB_PROTECTED_PATHS
        local prot skip=false
        for prot in "${MB_PROTECTED_PATHS[@]}"; do
            if [[ "$d" == "$prot" || "$d" == "$prot/"* ]]; then
                skip=true; break
            fi
        done
        [[ "$skip" == "true" ]] && continue
        # Skip if binary or known tool matches
        _dotfile_binary_known "$name" && continue
        # Emit this path
        printf '%s\0' "$d"
    done < <(find "$HOME" -maxdepth 1 -mindepth 1 -type d -name '.*' -print0 2>/dev/null)
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

    # Add orphan dotfile dirs
    local d
    while IFS= read -r -d '' d; do
        orphan_paths+=("$d")
    done < <(_orphan_dotfile_find)

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

    # Orphan dotfile dirs — binary not found in PATH
    local d s
    while IFS= read -r -d '' d; do
        s=$(du -sk -- "$d" 2>/dev/null | awk '{print $1+0; exit}')
        s="${s:-0}"
        printf '%d|[dotfile] %s|%s\n' "$s" "$(basename "$d")" "$d"
    done < <(_orphan_dotfile_find) | sort -t'|' -k1 -rn
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

    # Orphan dotfile dirs
    local d s
    while IFS= read -r -d '' d; do
        s=$(du -sk -- "$d" 2>/dev/null | awk '{print $1+0; exit}')
        s="${s:-0}"
        if [[ "$dry_run" == "true" ]]; then
            mb_dim "  would remove: $(basename "$d")  ($(mb_format_kb "$s"))  [dotfile, no binary found]"
            cleaned_kb=$(( cleaned_kb + s ))
        else
            if mb_safe_rm "$d"; then
                cleaned_kb=$(( cleaned_kb + s ))
            fi
        fi
    done < <(_orphan_dotfile_find)

    [[ -n "$result_file" ]] && printf '%d' "$cleaned_kb" > "$result_file"
}
