#!/usr/bin/env bash
# MacBroom – Installer files: .dmg, .pkg, and .iso images in ~/Downloads.
# These accumulate silently after app installation and are safe to delete —
# the app is already installed and the file can be re-downloaded if ever needed.

: "${MB_INSTALLER_AGE_DAYS:=14}"   # delete installers older than this many days

_INSTALLER_SEARCH_DIR="$HOME/Downloads"
_INSTALLER_EXTENSIONS=( dmg pkg iso )

_installer_find() {
    [[ -d "$_INSTALLER_SEARCH_DIR" ]] || return 0
    local ext
    for ext in "${_INSTALLER_EXTENSIONS[@]}"; do
        find "$_INSTALLER_SEARCH_DIR" -maxdepth 3 -type f \
            -name "*.${ext}" \
            -mtime "+${MB_INSTALLER_AGE_DAYS}" \
            -print0 2>/dev/null
    done
}

installer_files_scan() {
    local total=0 s f
    while IFS= read -r -d '' f; do
        s=$(mb_size_kb "$f")
        total=$(( total + s ))
    done < <(_installer_find)
    printf '%d' "$total"
}

installer_files_list() {
    local f s
    while IFS= read -r -d '' f; do
        s=$(mb_size_kb "$f")
        (( s > 0 )) || continue
        printf '%d|%s|%s\n' "$s" "$(basename "$f")" "$f"
    done < <(_installer_find) | sort -t'|' -k1 -rn
}

installer_files_clean() {
    local dry_run="${1:-false}"
    local result_file="${2:-}"
    local cleaned_kb=0
    local f s

    while IFS= read -r -d '' f; do
        s=$(mb_size_kb "$f")
        if [[ "$dry_run" == "true" ]]; then
            mb_dim "  would remove: $(basename "$f")  ($(mb_format_kb "$s"))"
            cleaned_kb=$(( cleaned_kb + s ))
        else
            if mb_safe_rm "$f"; then
                cleaned_kb=$(( cleaned_kb + s ))
            fi
        fi
    done < <(_installer_find)

    [[ -n "$result_file" ]] && printf '%d' "$cleaned_kb" > "$result_file"
}
