#!/usr/bin/env bash
# MacBroom installer – copies macbroom to /usr/local/bin (or ~/.local/bin).

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY_NAME="macbroom"

# Prefer /usr/local/bin if writable, otherwise fall back to ~/.local/bin
if [[ -d "/usr/local/bin" && -w "/usr/local/bin" ]]; then
    INSTALL_DIR="/usr/local/bin"
elif sudo -n true 2>/dev/null; then
    INSTALL_DIR="/usr/local/bin"
    USE_SUDO=true
else
    INSTALL_DIR="$HOME/.local/bin"
    USE_SUDO=false
fi

USE_SUDO="${USE_SUDO:-false}"

install_macbroom() {
    echo ""
    echo "  Installing MacBroom..."

    # Ensure install dir exists
    if [[ ! -d "$INSTALL_DIR" ]]; then
        if [[ "$USE_SUDO" == "true" ]]; then
            sudo mkdir -p "$INSTALL_DIR"
        else
            mkdir -p "$INSTALL_DIR"
        fi
    fi

    # Copy the entire repo to a library location
    local lib_dir="$HOME/.macbroom"
    rm -rf "$lib_dir"
    cp -R "$REPO_DIR" "$lib_dir"
    chmod +x "$lib_dir/$BINARY_NAME"

    # Create a launcher in the install dir
    local launcher="$INSTALL_DIR/$BINARY_NAME"
    local launcher_content="#!/usr/bin/env bash
exec \"$lib_dir/$BINARY_NAME\" \"\$@\""

    if [[ "$USE_SUDO" == "true" ]]; then
        echo "$launcher_content" | sudo tee "$launcher" > /dev/null
        sudo chmod +x "$launcher"
    else
        echo "$launcher_content" > "$launcher"
        chmod +x "$launcher"
    fi

    echo ""
    echo "  ✓ MacBroom installed to $launcher"

    # PATH hint if using ~/.local/bin
    if [[ "$INSTALL_DIR" == "$HOME/.local/bin" ]]; then
        if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
            echo ""
            echo "  ⚠ Add this to your shell profile (~/.zshrc or ~/.bashrc):"
            echo "      export PATH=\"\$HOME/.local/bin:\$PATH\""
        fi
    fi

    echo ""
    echo "  Run: macbroom --help"
    echo ""
}

uninstall_macbroom() {
    local lib_dir="$HOME/.macbroom"
    local launcher="$INSTALL_DIR/$BINARY_NAME"

    echo ""
    echo "  Uninstalling MacBroom..."

    [[ -f "$launcher" ]] && rm -f "$launcher" && echo "  ✓ Removed $launcher"
    [[ -d "$lib_dir" ]]  && rm -rf "$lib_dir" && echo "  ✓ Removed $lib_dir"

    echo ""
    echo "  MacBroom uninstalled."
    echo ""
}

case "${1:-install}" in
    install)   install_macbroom ;;
    uninstall) uninstall_macbroom ;;
    *)
        echo "Usage: $0 [install|uninstall]"
        exit 1
        ;;
esac
