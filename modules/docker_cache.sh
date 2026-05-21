#!/usr/bin/env bash
# MacBroom – Docker builder cache and dangling images.

docker_cache_requires() { echo "docker"; }

_docker_running() { docker info &>/dev/null 2>&1; }

docker_cache_scan() {
    _docker_running || { printf '0'; return; }
    local kb=0
    local raw
    raw=$(docker system df 2>/dev/null | awk '/Build Cache/{print $4}')
    # raw e.g.: "1.2GB" or "500MB" or "0B"
    if [[ "$raw" =~ ([0-9.]+)GB ]]; then
        kb=$(awk "BEGIN{printf \"%d\", ${BASH_REMATCH[1]}*1048576}")
    elif [[ "$raw" =~ ([0-9.]+)MB ]]; then
        kb=$(awk "BEGIN{printf \"%d\", ${BASH_REMATCH[1]}*1024}")
    elif [[ "$raw" =~ ([0-9.]+)kB ]]; then
        kb=$(awk "BEGIN{printf \"%d\", ${BASH_REMATCH[1]}}")
    fi
    printf '%d' "${kb:-0}"
}

# List items: Docker cache has no deletable file paths — it is pruned via
# the docker CLI. Returning empty prevents _run_clean_preview_selected from
# calling mb_safe_rm on the fake "docker:build-cache" pseudo-path.
# Select the module and press Enter to run docker_cache_clean().
docker_cache_list() {
    return 0
}

docker_cache_clean() {
    local dry_run="${1:-false}" result_file="${2:-}"
    _docker_running || { [[ -n "$result_file" ]] && printf '0' > "$result_file"; return; }
    local kb; kb=$(docker_cache_scan)
    if [[ "$dry_run" == "true" ]]; then
        mb_dim "  would prune: Docker build cache  ($(mb_format_kb "$kb"))"
    else
        docker builder prune -f &>/dev/null || true
        docker image prune -f &>/dev/null || true
    fi
    [[ -n "$result_file" ]] && printf '%d' "$kb" > "$result_file"
}
