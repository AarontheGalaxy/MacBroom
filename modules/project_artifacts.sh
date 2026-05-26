#!/usr/bin/env bash
# MacBroom – Project build artifacts: node_modules, __pycache__, .next, .build, and more.
# Scans common developer directories for artifact folders that build tools regenerate
# automatically — safe to delete, often grow to several GB across many projects.

_PROJECT_SCAN_ROOTS=(
    "$HOME/Desktop"
    "$HOME/Documents"
    "$HOME/Developer"
    "$HOME/Projects"
    "$HOME/src"
    "$HOME/code"
    "$HOME/repos"
    "$HOME/workspace"
)

# Artifact directory names that build tools always regenerate — never user data.
_PROJECT_ARTIFACT_NAMES=(
    node_modules
    __pycache__
    .next
    .nuxt
    .pytest_cache
    .mypy_cache
    .ruff_cache
    .turbo
    .parcel-cache
    .svelte-kit
    .build
    .dart_tool
    .tox
    .angular
    .vite
    .expo
    .docusaurus
    .cache
)

# Build a (-name A -o -name B ...) expression array for find.
_project_artifact_expr() {
    local name first=true
    for name in "${_PROJECT_ARTIFACT_NAMES[@]}"; do
        [[ "$first" == "true" ]] && first=false || printf '%s\0' -o
        printf '%s\0' -name
        printf '%s\0' "$name"
    done
}

_project_artifact_find() {
    local roots=()
    local d
    for d in "${_PROJECT_SCAN_ROOTS[@]}"; do
        [[ -d "$d" ]] && roots+=("$d")
    done
    [[ ${#roots[@]} -eq 0 ]] && return 0

    local expr=()
    local name first=true
    for name in "${_PROJECT_ARTIFACT_NAMES[@]}"; do
        [[ "$first" == "true" ]] && first=false || expr+=(-o)
        expr+=(-name "$name")
    done

    # -prune prevents recursing inside found dirs (node_modules inside node_modules, etc.)
    find "${roots[@]}" -maxdepth 8 -type d \( "${expr[@]}" \) -prune -print0 2>/dev/null
}

project_artifacts_scan() {
    local total=0 s p
    while IFS= read -r -d '' p; do
        s=$(du -sk -- "$p" 2>/dev/null | awk '{print $1+0; exit}')
        total=$(( total + ${s:-0} ))
    done < <(_project_artifact_find)
    printf '%d' "$total"
}

project_artifacts_list() {
    local p s rel
    while IFS= read -r -d '' p; do
        s=$(mb_size_kb "$p")
        (( s > 0 )) || continue
        rel="${p#"$HOME/"}"
        printf '%d|~/%s|%s\n' "$s" "$rel" "$p"
    done < <(_project_artifact_find) | sort -t'|' -k1 -rn
}

project_artifacts_clean() {
    local dry_run="${1:-false}"
    local result_file="${2:-}"
    local cleaned_kb=0
    local p s

    while IFS= read -r -d '' p; do
        s=$(mb_size_kb "$p")
        if [[ "$dry_run" == "true" ]]; then
            mb_dim "  would remove: ${p#"$HOME/"}  ($(mb_format_kb "$s"))"
            cleaned_kb=$(( cleaned_kb + s ))
        else
            if mb_safe_rm "$p"; then
                cleaned_kb=$(( cleaned_kb + s ))
            fi
        fi
    done < <(_project_artifact_find)

    [[ -n "$result_file" ]] && printf '%d' "$cleaned_kb" > "$result_file"
}
