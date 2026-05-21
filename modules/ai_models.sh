#!/usr/bin/env bash
# MacBroom – Local AI model caches (Ollama, LM Studio, HuggingFace).

_AI_MODEL_DIRS=(
    "$HOME/.ollama/models/blobs"
    "$HOME/.ollama/models/manifests"
    "$HOME/Library/Application Support/LM Studio/models"
    "$HOME/.cache/huggingface/hub"
    "$HOME/.cache/torch"
)

ai_models_scan() {
    local total=0 dir
    for dir in "${_AI_MODEL_DIRS[@]}"; do
        [[ -d "$dir" ]] || continue
        local s; s=$(du -sk "$dir" 2>/dev/null | awk '{print $1+0; exit}')
        total=$(( total + ${s:-0} ))
    done
    printf '%d' "$total"
}

ai_models_list() {
    local dir item s
    for dir in "${_AI_MODEL_DIRS[@]}"; do
        [[ -d "$dir" ]] || continue
        while IFS= read -r -d '' item; do
            [[ -e "$item" ]] || continue
            s=$(du -sk -- "$item" 2>/dev/null | awk '{print $1+0; exit}')
            s="${s:-0}"
            printf '%d|%s|%s\n' "$s" "$(basename "$item")" "$item"
        done < <(find "$dir" -maxdepth 1 -mindepth 1 -print0 2>/dev/null)
    done | sort -t'|' -k1 -rn
}

ai_models_clean() {
    local dry_run="${1:-false}"
    local result_file="${2:-}"
    local cleaned_kb=0 dir item s
    for dir in "${_AI_MODEL_DIRS[@]}"; do
        [[ -d "$dir" ]] || continue
        while IFS= read -r -d '' item; do
            [[ -e "$item" ]] || continue
            s=$(du -sk -- "$item" 2>/dev/null | awk '{print $1+0; exit}')
            s="${s:-0}"
            if [[ "$dry_run" == "true" ]]; then
                mb_dim "  would remove: $(basename "$item")  ($(mb_format_kb "$s"))"
                cleaned_kb=$(( cleaned_kb + s ))
            else
                if mb_safe_rm "$item"; then
                    cleaned_kb=$(( cleaned_kb + s ))
                fi
            fi
        done < <(find "$dir" -maxdepth 1 -mindepth 1 -print0 2>/dev/null)
    done
    [[ -n "$result_file" ]] && printf '%d' "$cleaned_kb" > "$result_file"
}
