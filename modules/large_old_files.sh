#!/usr/bin/env bash
# MacBroom – Large files not accessed in 180+ days.

readonly _LOF_MIN_SIZE_MB="${MB_LOF_MIN_SIZE_MB:-500}"
readonly _LOF_MIN_DAYS="${MB_LOF_MIN_DAYS:-180}"

_LOF_SEARCH_DIRS=(
    "$HOME/Downloads"
    "$HOME/Documents"
    "$HOME/Desktop"
    "$HOME/Music"
    "$HOME/Movies"
    "$HOME/Pictures"
)

large_old_files_scan() {
    # Passive scan: this module is too slow for the initial global scan.
    # We return 0 and only calculate size when the user enters the Preview screen.
    printf '0'
}

large_old_files_list() {
    local roots=()
    local d
    for d in "${_LOF_SEARCH_DIRS[@]}"; do
        [[ -d "$d" ]] && roots+=("$d")
    done
    [[ ${#roots[@]} -eq 0 ]] && return 0

    find "${roots[@]}" -maxdepth 6 -type f \
        -size "+${_LOF_MIN_SIZE_MB}M" \
        -atime "+${_LOF_MIN_DAYS}" \
        2>/dev/null | head -100 | \
    while IFS= read -r f; do
        [[ -f "$f" ]] || continue
        local s; s=$(du -sk -- "$f" 2>/dev/null | awk '{print $1+0; exit}')
        s="${s:-0}"
        printf '%d|%s|%s\n' "$s" "$(basename "$f")" "$f"
    done | sort -t'|' -k1 -rn
}

large_old_files_clean() {
    local dry_run="${1:-false}"
    local result_file="${2:-}"
    local cleaned_kb=0
    local roots=()
    local d
    for d in "${_LOF_SEARCH_DIRS[@]}"; do
        [[ -d "$d" ]] && roots+=("$d")
    done

    local tmpfile; tmpfile=$(mktemp)
    if [[ ${#roots[@]} -gt 0 ]]; then
        find "${roots[@]}" -maxdepth 6 -type f \
            -size "+${_LOF_MIN_SIZE_MB}M" \
            -atime "+${_LOF_MIN_DAYS}" \
            2>/dev/null | head -100 > "$tmpfile"
    fi

    while IFS= read -r f; do
        [[ -f "$f" ]] || continue
        local s; s=$(du -sk -- "$f" 2>/dev/null | awk '{print $1+0; exit}')
        s="${s:-0}"
        if [[ "$dry_run" == "true" ]]; then
            mb_dim "  would remove: $(basename "$f")  ($(mb_format_kb "$s"))"
            cleaned_kb=$(( cleaned_kb + s ))
        else
            if mb_safe_rm "$f"; then
                cleaned_kb=$(( cleaned_kb + s ))
            fi
        fi
    done < "$tmpfile"
    rm -f "$tmpfile"
    [[ -n "$result_file" ]] && printf '%d' "$cleaned_kb" > "$result_file"
}
