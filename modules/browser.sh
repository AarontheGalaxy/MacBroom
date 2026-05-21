#!/usr/bin/env bash
# MacBroom – Browser cache cleaning (Safari, Chrome, Firefox, Edge, Brave, Arc, Opera).

# Format: "Browser Name|cache/path"
_BROWSER_ENTRIES=(
    "Safari|$HOME/Library/Caches/com.apple.Safari"
    "Chrome|$HOME/Library/Caches/Google/Chrome"
    "Firefox|$HOME/Library/Caches/Firefox"
    "Edge|$HOME/Library/Caches/Microsoft Edge"
    "Brave|$HOME/Library/Caches/BraveSoftware/Brave-Browser"
    "Opera|$HOME/Library/Caches/com.operasoftware.Opera"
    "Arc|$HOME/Library/Caches/company.thebrowser.Browser"
    "Vivaldi|$HOME/Library/Caches/Vivaldi"
)

browser_scan() {
    [[ "${MB_QUICK_SCAN:-false}" == "true" ]] && { printf '0'; return; }
    local paths=()
    local entry name path
    for entry in "${_BROWSER_ENTRIES[@]}"; do
        IFS='|' read -r name path <<< "$entry"
        [[ -d "$path" ]] && paths+=("$path")
    done
    [[ ${#paths[@]} -eq 0 ]] && { printf '0'; return; }
    du -sk "${paths[@]}" 2>/dev/null | awk '{sum+=$1} END{print sum+0}'
}

browser_list() {
    local entry name path s
    for entry in "${_BROWSER_ENTRIES[@]}"; do
        IFS='|' read -r name path <<< "$entry"
        [[ -d "$path" ]] || continue
        s=$(mb_size_kb "$path")
        printf '%d|%s|%s\n' "$s" "$name" "$path"
    done | sort -t'|' -k1 -rn
}

browser_clean() {
    local dry_run="${1:-false}"
    local result_file="${2:-}"
    local cleaned_kb=0
    local entry name path size_kb

    for entry in "${_BROWSER_ENTRIES[@]}"; do
        IFS='|' read -r name path <<< "$entry"
        [[ -d "$path" ]] || continue

        size_kb=$(mb_size_kb "$path")

        if [[ "$dry_run" == "true" ]]; then
            cleaned_kb=$(( cleaned_kb + size_kb ))
            mb_dim "  would clear: $name cache  ($(mb_format_kb "$size_kb"))"
        else
            if mb_safe_rm "$path"; then
                cleaned_kb=$(( cleaned_kb + size_kb ))
                mb_ok "$name cache  ${C_DIM}($(mb_format_kb "$size_kb"))${C_NC}"
            fi
        fi
    done

    [[ -n "$result_file" ]] && printf '%d' "$cleaned_kb" > "$result_file"
}

