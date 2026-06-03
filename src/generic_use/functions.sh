#!/bin/bash

# Formatted echo for information, warnings, and errors.
fecho() {
    local label="$1"
    local message="$2"
    
    case "$label" in
        "INFO")
            printf '%b[INFO] %-15s%b %s\n' "${BLUE:-}" "" "${NC:-}" "$message"
            ;;
        "WARN")
            printf '%b[WARN] %-15s%b %s\n' "${YELLOW:-}" "" "${NC:-}" "$message"
            ;;
        "ERRO")
            printf '%b[ERRO] %-15s%b %s\n' "${RED:-}" "" "${NC:-}" "$message"
            ;;
        *)
            printf '[%s] %s\n' "$label" "$message"
            ;;
    esac
}

# Check if the script is running as root.
check_root() {
    if [ "$EUID" -ne 0 ]; then
        fecho "ERRO" "This script must be run as root (use sudo)."
        exit 1
    fi
}

# Get the home directory of the actual user, even if running under sudo.
get_target_home() {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        getent passwd "$SUDO_USER" | cut -d: -f6
    else
        printf '%s\n' "${HOME:-/root}"
    fi
}

# Install the script globally in /usr/local/bin.
install_global() {
    local script_name="gpu-setup"
    local global_path="/usr/local/bin/$script_name"
    local script_path
    script_path="$(realpath "$0" 2>/dev/null || true)"

    if [ -n "$script_path" ] && [ "$script_path" != "$global_path" ]; then
        cp "$script_path" "$global_path"
        chmod +x "$global_path"
        fecho "INFO" "Done! You can now run 'sudo $script_name' from anywhere."
    else
        fecho "WARN" "Script is already installed globally or path not found."
    fi
}

