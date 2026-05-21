#!/usr/bin/env bash
# MacBroom – Inactive memory purge (RAM, not disk space).

memory_purge_scan() {
    local page_size inactive_pages
    page_size=$(pagesize 2>/dev/null || echo 4096)
    inactive_pages=$(vm_stat 2>/dev/null | awk '/Pages inactive/{gsub(/\./,"",$3); print $3+0; exit}')
    printf '%d' $(( (${inactive_pages:-0} * ${page_size:-4096}) / 1024 ))
}

# List items: memory purge has no deletable file paths.
# Returning empty prevents _run_clean_preview_selected from calling mb_safe_rm
# on the fake "ram" pseudo-path. Select the module and press Enter to run
# memory_purge_clean() which executes "sudo purge".
memory_purge_list() {
    return 0
}

memory_purge_clean() {
    local dry_run="${1:-false}"
    local result_file="${2:-}"
    local kb; kb=$(memory_purge_scan)
    if [[ "$dry_run" == "true" ]]; then
        mb_dim "  would purge: Inactive memory  ($(mb_format_kb "$kb"))"
    else
        sudo purge 2>/dev/null || true
        mb_ok "Memory purged  (${C_DIM}$(mb_format_kb "$kb") freed from RAM${C_NC})"
    fi
    # NOTE: this frees RAM, not disk space — write 0 to result_file
    [[ -n "$result_file" ]] && printf '0' > "$result_file"
}
