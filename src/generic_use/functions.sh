#!/bin/bash

# Formatted echo for information, warnings, and errors.
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
        fecho "SUCCESS" "Done! You can now run 'sudo $script_name' from anywhere."
    else
        fecho "WARN" "Script is already installed globally or path not found."
    fi
}

# Verify display output after driver install and rollback if no response.
verify_and_rollback() {
    local packages=("$@")

    printf '\n'
    frule "━" "${WARNING:-}"
    fecho "WARN" "SAFETY CHECK: Display verification"
    fecho "WARN" "If your screen is black or frozen, do nothing. An automatic rollback will occur in 60 seconds."
    printf '  %bPlease type "alive" and press ENTER to confirm your display is working: %b' "${BOLD:-}" "${NC:-}"

    local confirm
    if read -t 60 confirm; then
        if [[ "${confirm,,}" == *"alive"* || "${confirm,,}" == *"ok"* ]]; then
            fecho "SUCCESS" "Display confirmed functional. Keeping driver changes."
            return 0
        fi
    fi

    printf '\n\n'
    fecho "ERRO" "No valid confirmation received or timeout reached!"
    fecho "WARN" "Executing emergency rollback to restore previous state..."

    case "$FAMILY" in
        arch) pacman -R --noconfirm "${packages[@]}" || true ;;
        debian) apt-get remove --purge -y "${packages[@]}" || true ;;
        fedora) dnf remove -y "${packages[@]}" || true ;;
        suse) zypper remove -y "${packages[@]}" || true ;;
        *) fecho "WARN" "Automated rollback is not explicitly supported for this family." ;;
    esac

    fecho "INFO" "Emergency rollback completed."
    return 1
}

# Check and optionally enable multilib repository on Arch Linux.
ensure_arch_multilib() {
    if [ "${FAMILY:-}" != "arch" ]; then
        return 0
    fi

    if grep -q "^\[multilib\]" /etc/pacman.conf; then
        return 0
    fi

    fecho "WARN" "The [multilib] repository is not enabled in /etc/pacman.conf."
    fecho "WARN" "This is required to install 32-bit drivers and compatibility libraries."
    
    local enable_multilib=0
    read -r -p "  Do you want to enable [multilib] now? (y/n): " em
    if [[ "$em" =~ ^[Yy]$ ]]; then
        fecho "INFO" "Enabling [multilib] in /etc/pacman.conf..."
        # Uncomment the multilib section and the immediately following Include line
        sed -i '/^#\[multilib\]/{ s/^#//; n; s/^#//; }' /etc/pacman.conf
        
        fecho "INFO" "Synchronizing package databases (pacman -Sy)..."
        pacman -Sy
    fi
    
    if grep -q "^\[multilib\]" /etc/pacman.conf; then
        return 0
    else
        return 1
    fi
}



