#!/bin/bash

# Formatted echo for information, warnings, and errors with modern icons.
fecho() {
    local label="$1"
    local message="$2"
    
    case "$label" in
        "INFO")
            printf '%b[ ℹ ] %b%s\n' "${INFO:-}" "${NC:-}" "$message"
            ;;
        "WARN")
            printf '%b[ ⚠ ] %b%s\n' "${WARNING:-}" "${NC:-}" "$message"
            ;;
        "ERRO")
            printf '%b[ ✖ ] %b%s\n' "${ERROR:-}" "${NC:-}" "$message"
            ;;
        "SUCCESS")
            printf '%b[ ✔ ] %b%s\n' "${SUCCESS:-}" "${NC:-}" "$message"
            ;;
        *)
            printf '[ %s ] %s\n' "$label" "$message"
            ;;
    esac
}

# Print a stylish horizontal rule.
frule() {
    local char="${1:-─}"
    local color="${2:-${DIM:-}}"
    local width
    width=$(tput cols 2>/dev/null || echo 60)
    
    printf '%b' "$color"
    printf "%.s$char" $(seq 1 "$width")
    printf '%b\n' "${NC:-}"
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

