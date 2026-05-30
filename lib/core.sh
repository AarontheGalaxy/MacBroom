#!/usr/bin/env bash
# MacBroom – Core utilities: colors, logging, safe I/O, size helpers.

[[ -n "${MB_CORE_LOADED:-}" ]] && return 0
readonly MB_CORE_LOADED=1

# ── Colors (disabled when stdout is not a terminal) ───────────
if [[ -t 1 ]]; then
    C_RED=$'\033[0;31m'
    C_GREEN=$'\033[0;32m'
    C_YELLOW=$'\033[0;33m'
    C_BLUE=$'\033[0;34m'
    C_MAGENTA=$'\033[0;35m'
    C_CYAN=$'\033[0;36m'
    C_BOLD=$'\033[1m'
    C_DIM=$'\033[2m'
    C_NC=$'\033[0m'
else
    C_RED='' C_GREEN='' C_YELLOW='' C_BLUE=''
    C_MAGENTA='' C_CYAN='' C_BOLD='' C_DIM='' C_NC=''
fi

# ── Logging helpers ────────────────────────────────────────────
mb_info()    { printf "  ${C_BLUE}→${C_NC} %s\n" "$*"; }
mb_ok()      { printf "  ${C_GREEN}✓${C_NC} %s\n" "$*"; }
mb_warn()    { printf "  ${C_YELLOW}⚠${C_NC} %s\n" "$*"; }
mb_error()   { printf "  ${C_RED}✗${C_NC} %s\n" "$*" >&2; }
mb_dim()     { printf "  ${C_DIM}%s${C_NC}\n" "$*"; }
mb_bold()    { printf "${C_BOLD}%s${C_NC}\n" "$*"; }

# ── Size formatting ────────────────────────────────────────────
# Converts bytes to human-readable string using SI (decimal) units.
# macOS Finder, About This Mac, and diskutil all use SI (1 GB = 10^9 bytes).
mb_format_bytes() {
    local -i bytes="${1:-0}"
    if (( bytes >= 1000000000 )); then
        awk "BEGIN{printf \"%.1f GB\", $bytes/1000000000}"
    elif (( bytes >= 1000000 )); then
        awk "BEGIN{printf \"%.1f MB\", $bytes/1000000}"
    elif (( bytes >= 1000 )); then
        awk "BEGIN{printf \"%.1f KB\", $bytes/1000}"
    else
        printf "%d B" "$bytes"
    fi
}

# Converts KB to human-readable string.
mb_format_kb() {
    mb_format_bytes "$(( ${1:-0} * 1024 ))"
}

# Returns file/dir size in KB, or 0 on failure.
# Uses stat for regular files (no fork overhead) and du for directories.
mb_size_kb() {
    local target="$1"
    [[ -e "$target" ]] || { printf '0'; return; }
    if [[ -f "$target" && ! -L "$target" ]]; then
        local bytes
        bytes=$(stat -f%z -- "$target" 2>/dev/null) || bytes=0
        [[ "$bytes" =~ ^[0-9]+$ ]] || bytes=0
        printf '%d' $(( (bytes + 1023) / 1024 ))
        return
    fi
    local raw
    raw=$(du -sk -- "$target" 2>/dev/null || echo "0 _")
    printf '%s\n' "$raw" | awk 'NR==1{print $1+0; exit}'
}

# ── Operation log ──────────────────────────────────────────────
readonly MB_OP_LOG_DIR="$HOME/Library/Logs/MacBroom"
readonly MB_OP_LOG_FILE="$MB_OP_LOG_DIR/operations.log"
readonly MB_ERR_LOG_FILE="$MB_OP_LOG_DIR/errors.log"

_mb_log_delete() {
    local path="$1" size_kb="${2:-0}"
    mkdir -p "$MB_OP_LOG_DIR" 2>/dev/null || return 0
    printf '%s  DELETED  %s  (%s)\n' \
        "$(date +%Y-%m-%dT%H:%M:%S%z)" \
        "$path" \
        "$(mb_format_kb "$size_kb")" >> "$MB_OP_LOG_FILE" 2>/dev/null || true
}

_mb_log_error() {
    local path="$1" err_msg="$2"
    mkdir -p "$MB_OP_LOG_DIR" 2>/dev/null || return 0
    printf '%s  ERROR    %s  (%s)\n' \
        "$(date +%Y-%m-%dT%H:%M:%S%z)" \
        "$path" \
        "$err_msg" >> "$MB_ERR_LOG_FILE" 2>/dev/null || true
}

# ── Path safety ────────────────────────────────────────────────
# ... (rest of path safety section)
# Explicit list of directory prefixes MacBroom is allowed to touch.
readonly -a MB_SAFE_PREFIXES=(
    "$HOME/Library/Caches"
    "$HOME/Library/Logs"
    "$HOME/.Trash"
    "$HOME/Library/Application Support"
    "$HOME/.cache"
    "$HOME/.npm"
    "$HOME/.gradle"
    "$HOME/.m2"
    "$HOME/.pub-cache"
    "$HOME/Library/Developer/Xcode/DerivedData"
    "$HOME/Library/Developer/CoreSimulator/Caches"
    "/Library/Caches"
    "/Library/Logs"
    "/private/tmp"
    "/private/var/tmp"
    "/private/var/log"
    "/private/var/db/diagnostics"
    "/private/var/db/DiagnosticPipeline"
    "/private/var/db/powerlog"
    "$HOME/.yarn"
    "$HOME/.pnpm-store"
    "$HOME/.bun"
    "$HOME/.cache/pip"
    "$HOME/.conda"
    "$HOME/.poetry"
    "$HOME/.pyenv"
    "$HOME/Library/Logs/JetBrains"
    "$HOME/Library/Application Support/Code"
    "$HOME/Library/Application Support/Cursor"
    "$HOME/Library/Application Support/Windsurf"
    "$HOME/.dart"
    "$HOME/Library/Caches/flutter_tools"
    "$HOME/go/pkg/mod/cache"
    "$HOME/Library/Caches/go-build"
    "$HOME/.cargo/registry"
    "$HOME/.cargo/git"
    "$HOME/.gem"
    "$HOME/Library/Caches/CocoaPods"
    "$HOME/Library/Caches/Homebrew"
    "$HOME/Library/Caches/gradle"
    "$HOME/.android/cache"
    "$HOME/Library/Android"
    "$HOME/Library/Messages/Attachments"
    "$HOME/Library/Messages/StickerCache"
    "$HOME/Library/Saved Application State"
    "$HOME/Library/HTTPStorages"
    "$HOME/Library/Application Support/MobileSync"
    "$HOME/Library/Mail"
    "$HOME/Library/Containers"
    "$HOME/Library/Group Containers"
    "$HOME/Library/Preferences"
    "$HOME/.ollama"
    "$HOME/Library/Application Support/LM Studio"
    "$HOME/.cache/huggingface"
    "$HOME/.cache/torch"
    # Additional paths discovered from reference analysis
    "$HOME/Library/Caches/com.apple.helpd"
    "$HOME/Library/Caches/com.apple.Safari/Safe Browsing"
    "$HOME/Library/Application Support/CrashReporter"
    # Home directory — enables orphan dotfile cleanup (covered by MB_PROTECTED_PATHS below)
    "$HOME"
    # Common developer project roots for Project Artifacts module
    "$HOME/Developer"
    "$HOME/Projects"
    "$HOME/src"
    "$HOME/code"
    "$HOME/repos"
    "$HOME/workspace"
    # Common user folders for Large Old Files module
    "$HOME/Downloads"
    "$HOME/Documents"
    "$HOME/Desktop"
    "$HOME/Music"
    "$HOME/Movies"
    "$HOME/Pictures"
)

# ── High-Risk Protection ───────────────────────────────────────
# These paths are strictly forbidden from deletion to prevent 
# critical data loss (SSH keys, GPG, AWS credentials, etc.)
readonly -a MB_PROTECTED_PATHS=(
    # Credentials and keys — never touch these
    "$HOME/.ssh"
    "$HOME/.gnupg"
    "$HOME/.gpg"
    "$HOME/.aws"
    "$HOME/.kube"
    "$HOME/.netrc"
    "$HOME/.docker"
    # Shell config and history
    "$HOME/.zshrc"
    "$HOME/.bashrc"
    "$HOME/.profile"
    "$HOME/.zsh_history"
    "$HOME/.bash_history"
    "$HOME/.zsh_sessions"
    "$HOME/.bash_sessions"
    "$HOME/.oh-my-zsh"
    # Git config
    "$HOME/.gitconfig"
    "$HOME/.gitignore"
    "$HOME/.gitignore_global"
    # Version managers — contain installed runtimes, not just caches
    "$HOME/.nvm"
    "$HOME/.rbenv"
    "$HOME/.pyenv"
    "$HOME/.asdf"
    "$HOME/.sdkman"
    "$HOME/.volta"
    "$HOME/.tfenv"
    "$HOME/.gvm"
    # Broad XDG dirs that contain many app configs
    "$HOME/.config"
    "$HOME/.local"
    # macOS system metadata
    "$HOME/.Spotlight-V100"
    "$HOME/.fseventsd"
    "$HOME/.TemporaryItems"
    "$HOME/.DocumentRevisions-V100"
)

# Returns 0 if a path is within a known-safe prefix, 1 otherwise.
mb_is_safe_path() {
    local target="${1%/}"
    [[ -z "$target" ]] && return 1

    # Never allow HOME itself — only subdirs are permitted
    [[ "$target" == "$HOME" ]] && return 1

    # Allow /Volumes/<name>/.Trashes/<uid> — current user's trash on external drives.
    # This check runs before protected paths so the trash module can clean volumes.
    if [[ "$target" == /Volumes/*/.Trashes/"$UID" || \
          "$target" == /Volumes/*/.Trashes/"$UID"/* ]]; then
        return 0
    fi

    # Check against protected paths first
    local prot
    for prot in "${MB_PROTECTED_PATHS[@]}"; do
        if [[ "$target" == "$prot" || "$target" == "$prot/"* ]]; then
            mb_error "Access Denied: $target is a protected system/config path"
            return 1
        fi
    done

    # Check user whitelist — whitelisted paths are PROTECTED (deletion refused)
    local wl
    for wl in "${MB_WHITELIST[@]+"${MB_WHITELIST[@]}"}"; do
        if [[ "$target" == "$wl" || "$target" == "$wl/"* ]]; then
            mb_warn "Skipping whitelisted path: $target"
            return 1
        fi
    done

    local prefix
    for prefix in "${MB_SAFE_PREFIXES[@]}"; do
        [[ "$target" == "$prefix" || "$target" == "$prefix/"* ]] && {
            # If the target is a symlink, also validate where it points.
            # rm -rf on a bare symlink removes only the link, but du/stat can
            # follow it and reveal unexpected data. Guard against this.
            if [[ -L "$target" ]]; then
                local real_target
                real_target=$(readlink "$target" 2>/dev/null) || return 1
                # Resolve relative symlinks against the parent directory
                if [[ "$real_target" != /* ]]; then
                    real_target="$(dirname "$target")/$real_target"
                fi
                mb_is_safe_path "$real_target" || {
                    mb_warn "Skipping symlink to unsafe target: $target → $real_target"
                    return 1
                }
            fi
            return 0
        }
    done
    return 1
}

# Safely deletes a path after validating it's within safe boundaries.
# Usage: mb_safe_rm <path> [sudo]
mb_safe_rm() {
    local target="${1:-}"
    local use_sudo="${2:-false}"

    [[ -z "$target" ]]              && return 1
    [[ "$target" == "/" ]]          && { mb_error "Refusing root deletion"; return 1; }
    [[ "$target" == "$HOME" ]]      && { mb_error "Refusing HOME deletion";  return 1; }
    [[ ! -e "$target" ]]            && return 0   # already gone – no-op

    if ! mb_is_safe_path "$target"; then
        mb_warn "Skipping unsafe path: $target"
        _mb_log_error "$target" "Path not in safe allowlist"
        return 1
    fi

    local size_kb
    size_kb=$(mb_size_kb "$target")

    local err
    if [[ "$use_sudo" == "true" ]]; then
        err=$(sudo rm -rf -- "$target" 2>&1)
    else
        err=$(rm -rf -- "$target" 2>&1)
    fi

    if [[ $? -ne 0 ]]; then
        # On macOS, deletion might fail due to the 'uchg' (immutable) flag.
        # Try to remove the flag and delete again if it's a "not permitted" error.
        if [[ "$err" == *"Operation not permitted"* ]]; then
            chflags nouchg "$target" 2>/dev/null || true
            if [[ "$use_sudo" == "true" ]]; then
                err=$(sudo rm -rf -- "$target" 2>&1)
            else
                err=$(rm -rf -- "$target" 2>&1)
            fi
            [[ $? -eq 0 ]] && { _mb_log_delete "$target" "$size_kb"; return 0; }
        fi
        mb_error "Failed to delete: $target ($err)"
        _mb_log_error "$target" "$err"
        return 1
    fi

    _mb_log_delete "$target" "$size_kb"
    if declare -f mb_undo_record &>/dev/null; then
        mb_undo_record "$target" "$size_kb" "${MB_CURRENT_MODULE:-unknown}"
    fi
    return 0
}

# ── Misc ───────────────────────────────────────────────────────
mb_has_sudo() { sudo -n true 2>/dev/null; }
mb_is_root()  { [[ "$EUID" -eq 0 ]]; }

mb_command_exists() { command -v "$1" &>/dev/null; }

# ── User whitelist (protected paths the user added) ────────────
# Stored at ~/.config/macbroom/whitelist — one path per line.
# mb_safe_rm refuses to delete any path matching an entry here.
readonly MB_WHITELIST_FILE="$HOME/.config/macbroom/whitelist"

mb_whitelist_load() {
    MB_WHITELIST=()
    [[ -f "$MB_WHITELIST_FILE" ]] || return 0
    local line
    while IFS= read -r line; do
        line="${line/#\~/$HOME}"   # expand leading ~
        line="${line%/}"           # strip trailing slash
        [[ -n "$line" && "$line" != '#'* ]] && MB_WHITELIST+=("$line")
    done < "$MB_WHITELIST_FILE"
}

mb_whitelist_add() {
    local path="${1%/}"
    mkdir -p "$(dirname "$MB_WHITELIST_FILE")" 2>/dev/null || true
    # Don't add duplicates
    if [[ -f "$MB_WHITELIST_FILE" ]] && grep -qxF "$path" "$MB_WHITELIST_FILE" 2>/dev/null; then
        return 0
    fi
    printf '%s\n' "$path" >> "$MB_WHITELIST_FILE"
    mb_whitelist_load
}

mb_whitelist_remove() {
    local path="${1%/}"
    [[ -f "$MB_WHITELIST_FILE" ]] || return 0
    local tmp; tmp=$(mktemp)
    grep -vxF "$path" "$MB_WHITELIST_FILE" > "$tmp" 2>/dev/null || true
    mv "$tmp" "$MB_WHITELIST_FILE"
    mb_whitelist_load
}

MB_WHITELIST=()

# Checks macOS version (major). e.g. mb_macos_ge 13 → true on Ventura+
mb_macos_ge() {
    local required="$1"
    local current
    current=$(sw_vers -productVersion 2>/dev/null | cut -d. -f1)
    (( current >= required ))
}
