#!/usr/bin/env bash
# MacBroom – Trash cleanup (main Trash + external volume trashes).

trash_scan() {
    local total=0
    local s

    if [[ -d "$HOME/.Trash" ]]; then
        s=$(mb_size_kb "$HOME/.Trash")
        [[ "$s" =~ ^[0-9]+$ ]] && total=$(( total + s ))
    fi

    local vol vtrash
    for vol in /Volumes/*/; do
        vtrash="${vol}.Trashes/$UID"
        [[ -d "$vtrash" ]] || continue
        s=$(mb_size_kb "$vtrash")
        [[ "$s" =~ ^[0-9]+$ ]] && total=$(( total + s ))
    done

    printf '%d' "$total"
}

trash_list() {
    local targets=()
    [[ -d "$HOME/.Trash" ]] && targets+=("$HOME/.Trash")
    local vol vtrash
    for vol in /Volumes/*/; do
        vtrash="${vol}.Trashes/$UID"
        [[ -d "$vtrash" ]] && targets+=("$vtrash")
    done
    local target s item
    for target in "${targets[@]}"; do
        while IFS= read -r -d '' item; do
            s=$(mb_size_kb "$item")
            printf '%d|%s|%s\n' "$s" "$(basename "$item")" "$item"
        done < <(find "$target" -maxdepth 1 -mindepth 1 -print0 2>/dev/null)
    done | sort -t'|' -k1 -rn
}

trash_clean() {
    local dry_run="${1:-false}"
    local result_file="${2:-}"
    local cleaned_kb=0

    local targets=()
    [[ -d "$HOME/.Trash" ]] && targets+=("$HOME/.Trash")

    local vol vtrash
    for vol in /Volumes/*/; do
        vtrash="${vol}.Trashes/$UID"
        [[ -d "$vtrash" ]] && targets+=("$vtrash")
    done

    local target s
    for target in "${targets[@]}"; do
        [[ -d "$target" ]] || continue
        
        if [[ "$dry_run" == "true" ]]; then
            s=$(mb_size_kb "$target")
            cleaned_kb=$(( cleaned_kb + s ))
            mb_dim "  would empty: $target  ($(mb_format_kb "$s"))"
        else
            local item
            while IFS= read -r -d '' item; do
                [[ -e "$item" ]] || continue
                local item_size; item_size=$(mb_size_kb "$item")
                # Trash paths are always safe to delete as per MB_SAFE_PREFIXES
                if mb_safe_rm "$item"; then
                    cleaned_kb=$(( cleaned_kb + item_size ))
                fi
            done < <(find "$target" -maxdepth 1 -mindepth 1 -print0 2>/dev/null)
            mb_ok "Trash processed: $target"
        fi
    done

    [[ -n "$result_file" ]] && printf '%d' "$cleaned_kb" > "$result_file"
}

