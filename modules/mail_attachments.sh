#!/usr/bin/env bash
# MacBroom – Mail.app attachment cache.

readonly _MAIL_AGE_DAYS="${MB_MAIL_AGE_DAYS:-90}"

_MAIL_DIRS=(
    "$HOME/Library/Mail"
    "$HOME/Library/Containers/com.apple.mail/Data/Library/Mail Downloads"
)

_mail_is_running() {
    pgrep -x "Mail" &>/dev/null
}

mail_attachments_scan() {
    _mail_is_running && { printf '0'; return; }
    local total=0 dir
    for dir in "${_MAIL_DIRS[@]}"; do
        [[ -d "$dir" ]] || continue
        local s
        s=$(find "$dir" -path "*/Attachments/*" -type f \
            -mtime "+${_MAIL_AGE_DAYS}" -print0 2>/dev/null | \
            xargs -0 du -sk 2>/dev/null | awk '{sum+=$1} END{print sum+0}')
        total=$(( total + ${s:-0} ))
    done
    printf '%d' "$total"
}

mail_attachments_list() {
    _mail_is_running && return 0
    local dir f s
    for dir in "${_MAIL_DIRS[@]}"; do
        [[ -d "$dir" ]] || continue
        while IFS= read -r f; do
            [[ -f "$f" ]] || continue
            s=$(du -sk -- "$f" 2>/dev/null | awk '{print $1+0; exit}')
            s="${s:-0}"
            printf '%d|%s|%s\n' "$s" "$(basename "$f")" "$f"
        done < <(find "$dir" -path "*/Attachments/*" -type f \
            -mtime "+${_MAIL_AGE_DAYS}" 2>/dev/null)
    done | sort -t'|' -k1 -rn | head -100
}

mail_attachments_clean() {
    local dry_run="${1:-false}"
    local result_file="${2:-}"
    if _mail_is_running; then
        mb_warn "Mail.app is running — close it first to clean attachments"
        [[ -n "$result_file" ]] && printf '0' > "$result_file"
        return
    fi
    local cleaned_kb=0 dir f s
    for dir in "${_MAIL_DIRS[@]}"; do
        [[ -d "$dir" ]] || continue
        while IFS= read -r f; do
            [[ -f "$f" ]] || continue
            s=$(du -sk -- "$f" 2>/dev/null | awk '{print $1+0; exit}')
            s="${s:-0}"
            if [[ "$dry_run" == "true" ]]; then
                mb_dim "  would remove: $(basename "$f")  ($(mb_format_kb "$s"))"
                cleaned_kb=$(( cleaned_kb + s ))
            else
                if mb_safe_rm "$f"; then
                    cleaned_kb=$(( cleaned_kb + s ))
                fi
            fi
        done < <(find "$dir" -path "*/Attachments/*" -type f \
            -mtime "+${_MAIL_AGE_DAYS}" 2>/dev/null)
    done
    [[ -n "$result_file" ]] && printf '%d' "$cleaned_kb" > "$result_file"
}
