#!/usr/bin/env bats
# Tests for modules/orphaned_files.sh: system bundle exclusions
#
# _is_system_bundle and _is_likely_bundle_dir are pure string functions with no
# dependency on MB_SAFE_PREFIXES, so they can be tested via direct setup() sourcing.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

setup() {
    unset MB_CORE_LOADED 2>/dev/null || true
    source "$REPO_ROOT/lib/core.sh"
    source "$REPO_ROOT/modules/orphaned_files.sh"
}

# Helper: run in subprocess so we get clean exit codes
_is_system() { bash -c "source '$REPO_ROOT/lib/core.sh'; source '$REPO_ROOT/modules/orphaned_files.sh'; _is_system_bundle '$1'"; }
_is_bundle() { bash -c "source '$REPO_ROOT/lib/core.sh'; source '$REPO_ROOT/modules/orphaned_files.sh'; _is_likely_bundle_dir '$1'"; }

# ── _is_system_bundle ─────────────────────────────────────────

@test "system bundle: com.apple.Safari is excluded" {
    run _is_system "com.apple.Safari"
    [ "$status" -eq 0 ]
}

@test "system bundle: com.apple.ContextStoreAgent is excluded" {
    run _is_system "com.apple.ContextStoreAgent"
    [ "$status" -eq 0 ]
}

@test "system bundle: com.google.Keystone is excluded" {
    run _is_system "com.google.Keystone"
    [ "$status" -eq 0 ]
}

@test "system bundle: com.microsoft.autoupdate2 is excluded" {
    run _is_system "com.microsoft.autoupdate2"
    [ "$status" -eq 0 ]
}

@test "system bundle: com.adobe.acc.installer is excluded" {
    run _is_system "com.adobe.acc.installer"
    [ "$status" -eq 0 ]
}

@test "system bundle: com.crashlytics.data is excluded" {
    run _is_system "com.crashlytics.data"
    [ "$status" -eq 0 ]
}

@test "system bundle: io.fabric.sdk is excluded" {
    run _is_system "io.fabric.sdk"
    [ "$status" -eq 0 ]
}

@test "system bundle: com.sentry.sdk is excluded" {
    run _is_system "com.sentry.sdk"
    [ "$status" -eq 0 ]
}

@test "user app: com.spotify.client is NOT excluded" {
    run _is_system "com.spotify.client"
    [ "$status" -ne 0 ]
}

@test "user app: com.google.Chrome is NOT excluded" {
    run _is_system "com.google.Chrome"
    [ "$status" -ne 0 ]
}

@test "user app: org.mozilla.firefox is NOT excluded" {
    run _is_system "org.mozilla.firefox"
    [ "$status" -ne 0 ]
}

@test "user app: io.cursor.app is NOT excluded" {
    run _is_system "io.cursor.app"
    [ "$status" -ne 0 ]
}

@test "user app: net.whatsapp.WhatsApp is NOT excluded" {
    run _is_system "net.whatsapp.WhatsApp"
    [ "$status" -ne 0 ]
}

# ── _is_likely_bundle_dir ────────────────────────────────────

@test "likely bundle: com. prefix detected" {
    run _is_bundle "com.example.App"
    [ "$status" -eq 0 ]
}

@test "likely bundle: org. prefix detected" {
    run _is_bundle "org.mozilla.firefox"
    [ "$status" -eq 0 ]
}

@test "likely bundle: io. prefix detected" {
    run _is_bundle "io.cursor.app"
    [ "$status" -eq 0 ]
}

@test "likely bundle: net. prefix detected" {
    run _is_bundle "net.whatsapp.WhatsApp"
    [ "$status" -eq 0 ]
}

@test "likely bundle: plain folder name is not a bundle dir" {
    run _is_bundle "Spotify"
    [ "$status" -ne 0 ]
}

@test "likely bundle: numeric folder name is not a bundle dir" {
    run _is_bundle "12345"
    [ "$status" -ne 0 ]
}

@test "likely bundle: hidden dir is not a bundle dir" {
    run _is_bundle ".hidden"
    [ "$status" -ne 0 ]
}

# ── edge cases ────────────────────────────────────────────────

@test "system bundle: com.apple. prefix matches any subname" {
    run _is_system "com.apple.someweirdnewdaemon"
    [ "$status" -eq 0 ]
}

@test "system bundle: non-apple com. prefix is not excluded" {
    run _is_system "com.example.notapple"
    [ "$status" -ne 0 ]
}

@test "system bundle: empty string is not excluded" {
    run _is_system ""
    [ "$status" -ne 0 ]
}
