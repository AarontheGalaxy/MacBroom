#!/usr/bin/env bash
# MacBroom – iOS device backups (MobileSync).

readonly _IOS_BACKUP_DIR="$HOME/Library/Application Support/MobileSync/Backup"

_ios_backup_info() {
    local backup_dir="$1"
    local info_plist="$backup_dir/Info.plist"
    [[ -f "$info_plist" ]] || { echo "Unknown Device"; return; }
    local device_name ios_version
    device_name=$(/usr/libexec/PlistBuddy -c "Print :Device Name" "$info_plist" 2>/dev/null || echo "Unknown")
    ios_version=$(/usr/libexec/PlistBuddy -c "Print :Product Version" "$info_plist" 2>/dev/null || echo "?")
    printf '%s (iOS %s)' "$device_name" "$ios_version"
}

ios_backups_scan() {
    [[ -d "$_IOS_BACKUP_DIR" ]] || { printf '0'; return; }
    du -sk "$_IOS_BACKUP_DIR" 2>/dev/null | awk '{print $1+0; exit}'
}

ios_backups_list() {
    [[ -d "$_IOS_BACKUP_DIR" ]] || return 0
    local backup_uuid
    while IFS= read -r -d '' backup_uuid; do
        [[ -d "$backup_uuid" ]] || continue
        local s; s=$(du -sk -- "$backup_uuid" 2>/dev/null | awk '{print $1+0; exit}')
        s="${s:-0}"
        local info; info=$(_ios_backup_info "$backup_uuid")
        printf '%d|%s|%s\n' "$s" "$info" "$backup_uuid"
    done < <(find "$_IOS_BACKUP_DIR" -maxdepth 1 -mindepth 1 -type d -print0 2>/dev/null) | \
    sort -t'|' -k1 -rn
}

ios_backups_clean() {
    local dry_run="${1:-false}"
    local result_file="${2:-}"
    [[ -d "$_IOS_BACKUP_DIR" ]] || { [[ -n "$result_file" ]] && printf '0' > "$result_file"; return; }
    local cleaned_kb=0
    local backup_uuid
    while IFS= read -r -d '' backup_uuid; do
        [[ -d "$backup_uuid" ]] || continue
        local s; s=$(du -sk -- "$backup_uuid" 2>/dev/null | awk '{print $1+0; exit}')
        s="${s:-0}"
        local info; info=$(_ios_backup_info "$backup_uuid")
        if [[ "$dry_run" == "true" ]]; then
            mb_dim "  would remove: $info  ($(mb_format_kb "$s"))"
            cleaned_kb=$(( cleaned_kb + s ))
        else
            if mb_safe_rm "$backup_uuid"; then
                cleaned_kb=$(( cleaned_kb + s ))
            fi
        fi
    done < <(find "$_IOS_BACKUP_DIR" -maxdepth 1 -mindepth 1 -type d -print0 2>/dev/null)
    [[ -n "$result_file" ]] && printf '%d' "$cleaned_kb" > "$result_file"
}
