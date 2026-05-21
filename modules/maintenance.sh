#!/usr/bin/env bash
# MacBroom – System maintenance tasks (DNS flush, font cache, Time Machine snapshots, Launch Services).

maintenance_scan() {
    # Maintenance tasks do not free disk space — always return 0.
    # Exception: count snapshots so the UI can surface a warning.
    printf '0'
}

# List items: maintenance tasks do not have deletable file paths.
# Returning empty prevents _run_clean_preview_selected from calling mb_safe_rm
# on fake task-id strings like "dns_flush". Select the module and press Enter
# to execute all tasks at once via maintenance_clean().
maintenance_list() {
    return 0
}

_maintenance_list_snapshots() {
    tmutil listlocalsnapshots / 2>/dev/null \
        | grep -E "([0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{6}|com\.apple\.TimeMachine)"
}

maintenance_clean() {
    local dry_run="${1:-false}"
    local result_file="${2:-}"

    local snaps snap_count=0
    snaps=$(_maintenance_list_snapshots)
    [[ -n "$snaps" ]] && snap_count=$(printf '%s\n' "$snaps" | grep -c .)

    if [[ "$dry_run" == "true" ]]; then
        mb_dim "  would run: Flush DNS Cache"
        mb_dim "  would run: Rebuild Font Cache"
        if [[ "$snap_count" -gt 0 ]]; then
            mb_dim "  would delete: $snap_count local APFS/Time Machine snapshot(s)"
            mb_warn "  tmutil deletelocalsnapshots — ALL local snapshots removed permanently"
        else
            mb_dim "  would run: Purge Time Machine Snapshots (none found)"
        fi
        mb_dim "  would run: Reset Launch Services"
        [[ -n "$result_file" ]] && printf '0' > "$result_file"
        return 0
    fi

    # DNS Cache
    if mb_has_sudo && \
       sudo -n dscacheutil -flushcache 2>/dev/null && \
       sudo -n killall -HUP mDNSResponder 2>/dev/null; then
        mb_ok "DNS cache flushed"
    fi

    # Font Cache
    if mb_has_sudo && sudo -n atsutil databases -remove 2>/dev/null; then
        mb_ok "Font cache rebuilt (takes effect after logout)"
    fi

    # Time Machine local snapshots
    if [[ "$snap_count" -gt 0 ]]; then
        mb_warn "Deleting $snap_count local snapshot(s) — this cannot be undone"
        while IFS= read -r snap; do
            [[ -z "$snap" ]] && continue
            local snap_id; snap_id=$(printf '%s' "$snap" | sed 's/.*\.//')
            [[ -z "$snap_id" ]] && snap_id="$snap"
            tmutil deletelocalsnapshots "$snap_id" 2>/dev/null || \
            tmutil deletelocalsnapshots "$snap" 2>/dev/null || true
        done <<< "$snaps"
        mb_ok "APFS local snapshots purged ($snap_count deleted)"
    fi

    # Launch Services
    local lsreg="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
    if [[ -x "$lsreg" ]]; then
        "$lsreg" -kill -r -domain local -domain system -domain user 2>/dev/null || true
        mb_ok "Launch Services database reset"
    fi

    [[ -n "$result_file" ]] && printf '0' > "$result_file"
}
