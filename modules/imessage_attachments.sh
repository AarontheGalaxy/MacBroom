#!/usr/bin/env bash
# MacBroom – iMessage attachments and sticker cache (~/Library/Messages).

imessage_attachments_scan() {
    local dir_att="$HOME/Library/Messages/Attachments"
    local dir_stk="$HOME/Library/Messages/StickerCache"

    local paths=()
    [[ -d "$dir_att" ]] && paths+=("$dir_att")
    [[ -d "$dir_stk" ]] && paths+=("$dir_stk")

    [[ ${#paths[@]} -eq 0 ]] && { printf '0'; return; }
    mb_sum_paths_kb "${paths[@]}"
}

# List items: prints "SIZE_KB|LABEL|PATH" lines
imessage_attachments_list() {
    local dir_att="$HOME/Library/Messages/Attachments"
    local dir_stk="$HOME/Library/Messages/StickerCache"

    local s
    if [[ -d "$dir_att" ]]; then
        s=$(mb_size_kb "$dir_att")
        (( s > 0 )) && printf '%d|iMessage Attachments|%s\n' "$s" "$dir_att"
    fi

    if [[ -d "$dir_stk" ]]; then
        s=$(mb_size_kb "$dir_stk")
        (( s > 0 )) && printf '%d|iMessage Sticker Cache|%s\n' "$s" "$dir_stk"
    fi
}

imessage_attachments_clean() {
    local dry_run="${1:-false}"
    local result_file="${2:-}"

    local dir_att="$HOME/Library/Messages/Attachments"
    local dir_stk="$HOME/Library/Messages/StickerCache"

    local cleaned_kb=0

    # Show warning only in interactive terminals
    if [[ "$dry_run" != "true" ]] && [[ -t 1 ]]; then
        mb_warn "iMessage Attachments: photos/videos in messages will no longer be viewable"
    fi

    for dir in "$dir_att" "$dir_stk"; do
        [[ -d "$dir" ]] || continue
        local size_kb
        size_kb=$(mb_size_kb "$dir")
        if [[ "$dry_run" == "true" ]]; then
            mb_dim "  would remove: $(basename "$dir")  ($(mb_format_kb "$size_kb"))"
            cleaned_kb=$(( cleaned_kb + size_kb ))
        else
            if mb_safe_rm "$dir"; then
                cleaned_kb=$(( cleaned_kb + size_kb ))
            fi
        fi
    done

    [[ -n "$result_file" ]] && printf '%d' "$cleaned_kb" > "$result_file"
}
