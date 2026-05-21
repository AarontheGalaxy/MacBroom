#!/usr/bin/env bash
# MacBroom – Developer tool caches: Xcode, npm, pip, Gradle, CocoaPods, etc.

# Each entry: "label|path"
_DEV_TARGETS=(
    "Xcode DerivedData|$HOME/Library/Developer/Xcode/DerivedData"
    "Xcode Archives|$HOME/Library/Developer/Xcode/Archives"
    "Xcode iOS Device Logs|$HOME/Library/Developer/Xcode/iOS Device Logs"
    "iOS Simulator Caches|$HOME/Library/Developer/CoreSimulator/Caches"
    "npm cache|$HOME/.npm/_cacache"
    "Yarn cache|$HOME/Library/Caches/Yarn"
    "pnpm store|$HOME/Library/pnpm/store"
    "pip cache|$HOME/Library/Caches/pip"
    "Gradle caches|$HOME/.gradle/caches"
    "Maven local repo|$HOME/.m2/repository"
    "CocoaPods cache|$HOME/Library/Caches/CocoaPods"
    "Carthage build|$HOME/Carthage/Build"
    "SwiftPM cache|$HOME/Library/Caches/org.swift.swiftpm"
    "Rust cargo registry|$HOME/.cargo/registry/cache"
    "Go module cache|$HOME/go/pkg/mod/cache"
    "Flutter pub cache|$HOME/.pub-cache/hosted"
    "Composer cache|$HOME/.composer/cache"
)

dev_tools_scan() {
    local paths=()
    local entry label path
    for entry in "${_DEV_TARGETS[@]}"; do
        IFS='|' read -r label path <<< "$entry"
        [[ -e "$path" ]] && paths+=("$path")
    done
    [[ ${#paths[@]} -eq 0 ]] && { printf '0'; return; }
    du -sk "${paths[@]}" 2>/dev/null | awk '{sum+=$1} END{print sum+0}'
}

dev_tools_list() {
    local entry label path s
    for entry in "${_DEV_TARGETS[@]}"; do
        IFS='|' read -r label path <<< "$entry"
        [[ -e "$path" ]] || continue
        s=$(mb_size_kb "$path")
        printf '%d|%s|%s\n' "$s" "$label" "$path"
    done | sort -t'|' -k1 -rn
}

dev_tools_clean() {
    local dry_run="${1:-false}"
    local result_file="${2:-}"
    local cleaned_kb=0
    local entry label path size_kb

    for entry in "${_DEV_TARGETS[@]}"; do
        IFS='|' read -r label path <<< "$entry"
        [[ -e "$path" ]] || continue

        size_kb=$(mb_size_kb "$path")

        if [[ "$dry_run" == "true" ]]; then
            cleaned_kb=$(( cleaned_kb + size_kb ))
            mb_dim "  would clear: $label  ($(mb_format_kb "$size_kb"))"
        else
            if mb_safe_rm "$path"; then
                cleaned_kb=$(( cleaned_kb + size_kb ))
                mb_ok "$label  ${C_DIM}($(mb_format_kb "$size_kb"))${C_NC}"
            fi
        fi
    done

    [[ -n "$result_file" ]] && printf '%d' "$cleaned_kb" > "$result_file"
}

