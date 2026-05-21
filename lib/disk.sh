#!/usr/bin/env bash
# MacBroom – Disk space utilities.

[[ -n "${MB_DISK_LOADED:-}" ]] && return 0
readonly MB_DISK_LOADED=1

# Cache diskutil apfs list output once per session (it's slow to run repeatedly).
_MB_APFS_LIST_CACHE=""

# Clears the cached disk information to force a fresh scan.
mb_disk_clear_cache() {
    _MB_APFS_LIST_CACHE=""
}

_mb_apfs_list() {
    if [[ -z "$_MB_APFS_LIST_CACHE" ]]; then
        _MB_APFS_LIST_CACHE=$(diskutil apfs list 2>/dev/null || true)
    fi
    printf '%s\n' "$_MB_APFS_LIST_CACHE"
}

# Returns the APFS container total capacity in KB.
# Uses "diskutil apfs list" → "Size (Capacity Ceiling)" which matches Finder.
# Falls back to df if diskutil is unavailable.
mb_disk_total_kb() {
    local bytes
    bytes=$(_mb_apfs_list | awk '/Size \(Capacity Ceiling\):/{
        gsub(/,/, ""); match($0, /[0-9]+ B/); if (RSTART) { print substr($0,RSTART,RLENGTH-2)+0; exit }
    }')
    if [[ -n "$bytes" && "$bytes" -gt 0 ]]; then
        echo $(( bytes / 1024 ))
        return
    fi
    df -k / 2>/dev/null | awk 'NR==2{print $2+0}' || echo 0
}

# Returns APFS container used space in KB.
# Uses "Capacity In Use By Volumes" which includes all volumes (data, preboot,
# recovery, VM) and matches what Finder / About This Mac reports.
mb_disk_used_kb() {
    local bytes
    bytes=$(_mb_apfs_list | awk '/Capacity In Use By Volumes:/{
        gsub(/,/, ""); match($0, /[0-9]+ B/); if (RSTART) { print substr($0,RSTART,RLENGTH-2)+0; exit }
    }')
    if [[ -n "$bytes" && "$bytes" -gt 0 ]]; then
        echo $(( bytes / 1024 ))
        return
    fi
    # Fallback: total - available from df
    df -k / 2>/dev/null | awk 'NR==2{u=$2-$4; print (u>0?u:0)}' || echo 0
}

# Returns APFS container free space in KB.
mb_disk_free_kb() {
    local bytes
    bytes=$(_mb_apfs_list | awk '/Capacity Not Allocated:/{
        gsub(/,/, ""); match($0, /[0-9]+ B/); if (RSTART) { print substr($0,RSTART,RLENGTH-2)+0; exit }
    }')
    if [[ -n "$bytes" && "$bytes" -gt 0 ]]; then
        echo $(( bytes / 1024 ))
        return
    fi
    df -k / 2>/dev/null | awk 'NR==2{print $4+0}' || echo 0
}

# du wrapper that handles partial-permission directories gracefully.
# du may exit with non-zero even when it outputs a valid total line.
# We capture both du's output and a "0" fallback, then take the first numeric line.
_mb_du_kb() {
    local target="$1"
    local raw
    raw=$(du -sk -- "$target" 2>/dev/null || echo "0 _")
    printf '%s\n' "$raw" | awk 'NR==1{v=$1+0; print v; exit}'
}

# Sums KB sizes for a list of paths.
mb_sum_paths_kb() {
    local existing=()
    local p
    for p in "$@"; do
        [[ -e "$p" ]] && existing+=("$p")
    done
    [[ ${#existing[@]} -eq 0 ]] && { printf '0'; return; }
    du -sk "${existing[@]}" 2>/dev/null | awk '{sum+=$1} END{print sum+0}'
}

# Sums KB for all immediate children of a directory matching an optional glob.
# Usage: mb_sum_dir_children_kb <dir> [glob]
mb_sum_dir_children_kb() {
    local dir="$1"
    local glob="${2:-*}"
    [[ -d "$dir" ]] || { printf '0'; return; }
    find "$dir" -maxdepth 1 -name "$glob" -print0 2>/dev/null \
        | xargs -0 du -sk 2>/dev/null \
        | awk '{sum+=$1} END{print sum+0}'
}
