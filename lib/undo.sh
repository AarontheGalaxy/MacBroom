#!/usr/bin/env bash
# MacBroom – Undo/session manifest system.

[[ -n "${MB_UNDO_LOADED:-}" ]] && return 0
readonly MB_UNDO_LOADED=1

readonly MB_UNDO_DIR="$HOME/.local/share/macbroom/sessions"
readonly MB_UNDO_MAX_AGE_HOURS=24

# Active session ID (set when a cleaning run starts)
MB_UNDO_SESSION_ID=""
MB_UNDO_SESSION_FILE=""

mb_undo_session_start() {
    MB_UNDO_SESSION_ID=$(date +%Y%m%d-%H%M%S)
    mkdir -p "$MB_UNDO_DIR" 2>/dev/null || return 0
    MB_UNDO_SESSION_FILE="$MB_UNDO_DIR/${MB_UNDO_SESSION_ID}.jsonl"
    # Write session header
    printf '{"type":"session","id":"%s","started_at":"%s"}\n' \
        "$MB_UNDO_SESSION_ID" \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        > "$MB_UNDO_SESSION_FILE" 2>/dev/null || true
}

mb_undo_record() {
    local path="$1" size_kb="${2:-0}" module="${3:-unknown}"
    [[ -z "$MB_UNDO_SESSION_FILE" ]] && return 0
    [[ -z "$path" ]] && return 0
    printf '{"type":"delete","path":"%s","size_kb":%d,"module":"%s","ts":"%s"}\n' \
        "$path" "$size_kb" "$module" \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        >> "$MB_UNDO_SESSION_FILE" 2>/dev/null || true
}

mb_undo_session_end() {
    [[ -z "$MB_UNDO_SESSION_FILE" ]] && return 0
    printf '{"type":"end","id":"%s","ended_at":"%s"}\n' \
        "$MB_UNDO_SESSION_ID" \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        >> "$MB_UNDO_SESSION_FILE" 2>/dev/null || true
}

mb_undo_list_sessions() {
    [[ -d "$MB_UNDO_DIR" ]] || { printf "No deletion log sessions found.\n"; return; }
    local f found=0
    for f in "$MB_UNDO_DIR"/*.jsonl; do
        [[ -f "$f" ]] || continue
        local sid; sid=$(basename "$f" .jsonl)
        local count; count=$(grep -c '"type":"delete"' "$f" 2>/dev/null || echo 0)
        local kb; kb=$(grep '"type":"delete"' "$f" 2>/dev/null | \
            awk -F'"size_kb":' '{split($2,a,","); sum+=a[1]} END{print sum+0}')
        printf "  %s  —  %s files  (%s)\n" "$sid" "$count" "$(mb_format_kb "${kb:-0}")"
        found=1
    done
    [[ "$found" -eq 0 ]] && printf "  No sessions available.\n"
}

mb_undo_last() {
    [[ -d "$MB_UNDO_DIR" ]] || { mb_error "No deletion log sessions found."; return 1; }
    # Find the most recent session file
    local last_file
    last_file=$(ls -t "$MB_UNDO_DIR"/*.jsonl 2>/dev/null | head -1)
    [[ -z "$last_file" ]] && { mb_error "No deletion log sessions found."; return 1; }

    local sid; sid=$(basename "$last_file" .jsonl)

    # Check 24-hour expiry window
    local file_age_hours
    file_age_hours=$(( ( $(date +%s) - $(stat -f%m "$last_file" 2>/dev/null || echo 0) ) / 3600 ))
    if (( file_age_hours > MB_UNDO_MAX_AGE_HOURS )); then
        mb_error "Session $sid is older than 24 hours — log has expired."
        return 1
    fi

    # NOTE: MacBroom permanently deletes files (rm -rf). They cannot be
    # restored. This command shows what was deleted in the last session
    # as an informational report only.
    printf "\n"
    mb_bold "  MacBroom Deletion Log — Session: $sid"
    mb_dim  "  (Files were permanently deleted and cannot be restored)"
    printf "\n"

    local count=0 total_kb=0
    local path size_kb module ts
    while IFS= read -r line; do
        [[ "$line" == *'"type":"delete"'* ]] || continue
        path=$(printf '%s' "$line" | grep -o '"path":"[^"]*"' | cut -d'"' -f4)
        size_kb=$(printf '%s' "$line" | grep -o '"size_kb":[0-9]*' | cut -d: -f2)
        module=$(printf '%s' "$line" | grep -o '"module":"[^"]*"' | cut -d'"' -f4)
        [[ -z "$path" ]] && continue
        size_kb="${size_kb:-0}"
        printf "  ${C_DIM}%-12s${C_NC}  %s  ${C_DIM}(%s)${C_NC}\n" \
            "$module" "$path" "$(mb_format_kb "${size_kb:-0}")"
        count=$(( count + 1 ))
        total_kb=$(( total_kb + size_kb ))
    done < "$last_file"

    printf "\n"
    mb_dim "  Total: ${count} item(s), $(mb_format_kb "$total_kb") deleted"
    printf "\n"

    # Remove session file after reporting
    rm -f "$last_file" 2>/dev/null || true
}
