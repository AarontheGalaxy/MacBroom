#!/usr/bin/env bats
# Tests for modules/maintenance.sh: dry-run output and snapshot handling
#
# maintenance functions don't depend on MB_SAFE_PREFIXES, so setup() sourcing works.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
    unset MB_CORE_LOADED 2>/dev/null || true
    source "$REPO_ROOT/lib/core.sh"
    source "$REPO_ROOT/modules/maintenance.sh"
}

# ── maintenance_scan ──────────────────────────────────────────

@test "scan: always returns 0 bytes" {
    result=$(maintenance_scan)
    [ "$result" = "0" ]
}

# ── dry-run with no snapshots ─────────────────────────────────

@test "dry-run: exits 0 when no snapshots exist" {
    _maintenance_list_snapshots() { return 0; }
    maintenance_clean "true"
}

@test "dry-run: mentions DNS flush" {
    _maintenance_list_snapshots() { return 0; }
    maintenance_clean "true" 2>&1 | grep -q "Flush DNS"
}

@test "dry-run: mentions font cache" {
    _maintenance_list_snapshots() { return 0; }
    maintenance_clean "true" 2>&1 | grep -q "Font Cache"
}

@test "dry-run: mentions Launch Services" {
    _maintenance_list_snapshots() { return 0; }
    maintenance_clean "true" 2>&1 | grep -q "Launch Services"
}

@test "dry-run: says 'none found' when no snapshots" {
    _maintenance_list_snapshots() { return 0; }
    maintenance_clean "true" 2>&1 | grep -q "none found"
}

# ── dry-run with snapshots ────────────────────────────────────

@test "dry-run: exits 0 when snapshots exist" {
    _maintenance_list_snapshots() {
        printf 'com.apple.TimeMachine.2026-05-10-120000\n'
    }
    maintenance_clean "true"
}

@test "dry-run: shows count when 2 snapshots exist" {
    _maintenance_list_snapshots() {
        printf 'com.apple.TimeMachine.2026-05-10-120000\n'
        printf 'com.apple.TimeMachine.2026-05-15-080000\n'
    }
    maintenance_clean "true" 2>&1 | grep -q "2 local APFS"
}

@test "dry-run: shows irreversible warning when snapshots exist" {
    _maintenance_list_snapshots() {
        printf 'com.apple.TimeMachine.2026-05-10-120000\n'
    }
    maintenance_clean "true" 2>&1 | grep -qiE "cannot be undone|permanently|ALL local"
}

# ── result_file ───────────────────────────────────────────────

@test "dry-run: writes 0 to result_file" {
    _maintenance_list_snapshots() { return 0; }
    local rfile; rfile=$(mktemp)
    maintenance_clean "true" "$rfile"
    [ "$(cat "$rfile")" = "0" ]
    rm -f "$rfile"
}

@test "clean: writes 0 to result_file (no disk space freed)" {
    _maintenance_list_snapshots() { return 0; }
    mb_has_sudo() { return 1; }
    local rfile; rfile=$(mktemp)
    maintenance_clean "false" "$rfile"
    [ "$(cat "$rfile")" = "0" ]
    rm -f "$rfile"
}
