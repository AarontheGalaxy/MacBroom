#!/usr/bin/env bats
# Tests for lib/core.sh: mb_is_safe_path and mb_safe_rm
#
# Each test sources core.sh in a fresh subprocess via `run bash -c`.
# This sidesteps bats' readonly-array isolation issue (readonly -a arrays
# declared at file-load time are not visible in test bodies in bats 1.13).

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
_MB_TEST_DIR="$HOME/Library/Caches/test.macbroom.bats"

setup()    { mkdir -p "$_MB_TEST_DIR"; }
teardown() { rm -rf "$_MB_TEST_DIR"; }

# Helper: source core.sh and call mb_is_safe_path in a subprocess
_safe_path() {
    bash -c "source '$REPO_ROOT/lib/core.sh'; mb_is_safe_path '$1'"
}

# ── mb_is_safe_path ───────────────────────────────────────────

@test "safe path: exact prefix is allowed" {
    run _safe_path "$HOME/Library/Caches"
    [ "$status" -eq 0 ]
}

@test "safe path: subpath of prefix is allowed" {
    run _safe_path "$HOME/Library/Caches/com.example.App/data"
    [ "$status" -eq 0 ]
}

@test "safe path: path outside allowlist is refused" {
    run _safe_path "/etc/passwd"
    [ "$status" -ne 0 ]
}

@test "safe path: arbitrary home subdir is refused" {
    run _safe_path "$HOME/.config/something"
    [ "$status" -ne 0 ]
}

@test "safe path: empty string is refused" {
    run _safe_path ""
    [ "$status" -ne 0 ]
}

@test "safe path: root / is refused" {
    run _safe_path "/"
    [ "$status" -ne 0 ]
}

@test "safe path: HOME itself is refused" {
    run _safe_path "$HOME"
    [ "$status" -ne 0 ]
}

@test "protected path: .ssh is refused" {
    run _safe_path "$HOME/.ssh"
    [ "$status" -ne 0 ]
}

@test "protected path: .ssh subpath is refused" {
    run _safe_path "$HOME/.ssh/id_rsa"
    [ "$status" -ne 0 ]
}

@test "safe path: trailing slash is stripped and still allowed" {
    run _safe_path "$HOME/Library/Caches/"
    [ "$status" -eq 0 ]
}

@test "safe path: npm path is allowed" {
    run _safe_path "$HOME/.npm/cache/something"
    [ "$status" -eq 0 ]
}

# ── symlink validation ─────────────────────────────────────────

@test "symlink: link in safe dir pointing to safe dir is allowed" {
    local target="$_MB_TEST_DIR/real_dir"
    local link="$_MB_TEST_DIR/link_dir"
    mkdir -p "$target"
    ln -s "$target" "$link"
    run _safe_path "$link"
    [ "$status" -eq 0 ]
}

@test "symlink: link in safe dir pointing outside allowlist is refused" {
    local link="$_MB_TEST_DIR/evil_link"
    ln -s "/etc/passwd" "$link"
    run _safe_path "$link"
    [ "$status" -ne 0 ]
}

@test "symlink: link to protected .ssh path is refused" {
    local link="$_MB_TEST_DIR/ssh_link"
    ln -s "$HOME/.ssh" "$link"
    run _safe_path "$link"
    [ "$status" -ne 0 ]
}

# ── mb_safe_rm ────────────────────────────────────────────────

@test "safe_rm: removes a file inside allowed path" {
    local f="$_MB_TEST_DIR/delete_me.txt"
    printf 'hello' > "$f"
    run bash -c "source '$REPO_ROOT/lib/core.sh'; mb_safe_rm '$f'"
    [ "$status" -eq 0 ]
    [ ! -e "$f" ]
}

@test "safe_rm: removes a directory inside allowed path" {
    local d="$_MB_TEST_DIR/delete_dir"
    mkdir -p "$d/nested"
    run bash -c "source '$REPO_ROOT/lib/core.sh'; mb_safe_rm '$d'"
    [ "$status" -eq 0 ]
    [ ! -e "$d" ]
}

@test "safe_rm: refuses deletion outside allowlist" {
    local f; f=$(mktemp)
    run bash -c "source '$REPO_ROOT/lib/core.sh'; mb_safe_rm '$f'"
    [ "$status" -ne 0 ]
    [ -e "$f" ]
    rm -f "$f"
}

@test "safe_rm: returns 0 for already-gone path (idempotent)" {
    run bash -c "source '$REPO_ROOT/lib/core.sh'; mb_safe_rm '$_MB_TEST_DIR/does_not_exist_xyz'"
    [ "$status" -eq 0 ]
}

@test "safe_rm: refuses / (root)" {
    run bash -c "source '$REPO_ROOT/lib/core.sh'; mb_safe_rm '/'"
    [ "$status" -ne 0 ]
}

@test "safe_rm: refuses HOME" {
    run bash -c "source '$REPO_ROOT/lib/core.sh'; mb_safe_rm \"\$HOME\""
    [ "$status" -ne 0 ]
}

@test "safe_rm: refuses empty string" {
    run bash -c "source '$REPO_ROOT/lib/core.sh'; mb_safe_rm ''"
    [ "$status" -ne 0 ]
}

# ── mb_format_bytes ───────────────────────────────────────────

@test "format_bytes: bytes range" {
    run bash -c "source '$REPO_ROOT/lib/core.sh'; mb_format_bytes 512"
    [ "$output" = "512 B" ]
}

@test "format_bytes: kilobytes range" {
    run bash -c "source '$REPO_ROOT/lib/core.sh'; mb_format_bytes 5000"
    [ "$output" = "5.0 KB" ]
}

@test "format_bytes: megabytes range" {
    run bash -c "source '$REPO_ROOT/lib/core.sh'; mb_format_bytes 5000000"
    [ "$output" = "5.0 MB" ]
}

@test "format_bytes: gigabytes range" {
    run bash -c "source '$REPO_ROOT/lib/core.sh'; mb_format_bytes 5000000000"
    [ "$output" = "5.0 GB" ]
}
