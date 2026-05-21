#!/usr/bin/env bash
# MacBroom – Scheduled cleaning via launchd.

[[ -n "${MB_CRON_LOADED:-}" ]] && return 0
readonly MB_CRON_LOADED=1

readonly MB_CRON_PLIST_DIR="$HOME/Library/LaunchAgents"
readonly MB_CRON_PLIST="$MB_CRON_PLIST_DIR/com.macbroom.cleanup.plist"
readonly MB_CRON_LABEL="com.macbroom.cleanup"

mb_cron_install() {
    local interval_days="${1:-7}"
    local safety_level="${2:-safe}"
    local mb_bin

    # Locate macbroom binary
    mb_bin=$(command -v macbroom 2>/dev/null)
    if [[ -z "$mb_bin" ]]; then
        mb_bin="$HOME/.local/bin/macbroom"
    fi
    [[ -x "$mb_bin" ]] || { mb_error "macbroom binary not found at: $mb_bin"; return 1; }

    local interval_secs=$(( interval_days * 86400 ))
    local log_dir="$HOME/Library/Logs/MacBroom"
    mkdir -p "$MB_CRON_PLIST_DIR" "$log_dir" 2>/dev/null || true

    cat > "$MB_CRON_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${MB_CRON_LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>${mb_bin}</string>
        <string>--headless</string>
        <string>--${safety_level}</string>
    </array>
    <key>StartInterval</key>
    <integer>${interval_secs}</integer>
    <key>RunAtLoad</key>
    <false/>
    <key>StandardOutPath</key>
    <string>${log_dir}/cron.log</string>
    <key>StandardErrorPath</key>
    <string>${log_dir}/cron-error.log</string>
</dict>
</plist>
PLIST

    launchctl load "$MB_CRON_PLIST" 2>/dev/null || true
    mb_ok "Scheduled cleaning installed — runs every ${interval_days} day(s) at ${safety_level} level"
    mb_dim "  Plist: $MB_CRON_PLIST"
    mb_dim "  Log:   ${log_dir}/cron.log"
}

mb_cron_remove() {
    if [[ -f "$MB_CRON_PLIST" ]]; then
        launchctl unload "$MB_CRON_PLIST" 2>/dev/null || true
        rm -f "$MB_CRON_PLIST"
        mb_ok "Scheduled cleaning removed."
    else
        mb_dim "No scheduled cleaning installed."
    fi
}

mb_cron_status() {
    if [[ -f "$MB_CRON_PLIST" ]]; then
        mb_ok "Scheduled cleaning is ACTIVE"
        local interval
        interval=$(/usr/libexec/PlistBuddy -c "Print :StartInterval" "$MB_CRON_PLIST" 2>/dev/null || echo "?")
        local days=$(( ${interval:-0} / 86400 ))
        mb_dim "  Interval: every ${days} day(s)"
        mb_dim "  Plist:    $MB_CRON_PLIST"
        local log_file="$HOME/Library/Logs/MacBroom/cron.log"
        if [[ -f "$log_file" ]]; then
            mb_dim "  Last run:"
            tail -3 "$log_file" 2>/dev/null | while IFS= read -r l; do mb_dim "    $l"; done
        fi
    else
        mb_dim "Scheduled cleaning is not installed."
        mb_dim "  Run: macbroom --install-cron"
    fi
}
