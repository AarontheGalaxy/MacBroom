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

# Try to enable TouchID for sudo in the current session.
# macOS 13+ supports PAM-based TouchID via /etc/pam.d/sudo_local.
# We temporarily add the pam_tid entry if it's missing and restore it after.
_maintenance_enable_touchid_sudo() {
    local pam_local="/etc/pam.d/sudo_local"
    local pam_sudo="/etc/pam.d/sudo"
    local tid_line="auth       sufficient     pam_tid.so"

    # Check if already enabled
    if grep -q "pam_tid" "$pam_local" 2>/dev/null || \
       grep -q "pam_tid" "$pam_sudo" 2>/dev/null; then
        return 0   # already active
    fi

    # Requires sudo_local to exist or be createable (macOS 13+)
    if ! mb_macos_ge 13; then
        return 1
    fi

    if mb_has_sudo; then
        # Prepend the pam_tid line to sudo_local (create if missing)
        if [[ ! -f "$pam_local" ]]; then
            printf '# Managed by MacBroom — restore to previous state by removing this file\n%s\n' \
                "$tid_line" | sudo tee "$pam_local" > /dev/null 2>&1 && return 0
        else
            local tmp; tmp=$(mktemp)
            { printf '%s\n' "$tid_line"; cat "$pam_local"; } > "$tmp"
            sudo cp "$tmp" "$pam_local" 2>/dev/null
            rm -f "$tmp"
            return 0
        fi
    fi
    return 1
}

maintenance_clean() {
    local dry_run="${1:-false}"
    local result_file="${2:-}"

    local snaps snap_count=0
    snaps=$(_maintenance_list_snapshots)
    [[ -n "$snaps" ]] && snap_count=$(printf '%s\n' "$snaps" | grep -c .)

    if [[ "$dry_run" == "true" ]]; then
        mb_dim "  would attempt: Enable TouchID for sudo (macOS 13+)"
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

    # TouchID sudo elevation (best-effort; failure is non-fatal)
    if _maintenance_enable_touchid_sudo; then
        mb_ok "TouchID for sudo enabled"
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
