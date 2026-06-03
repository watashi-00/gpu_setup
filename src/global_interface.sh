#!/bin/bash

source "$(dirname "$0")/src/generic_use/menu.sh"
source "$(dirname "$0")/src/generic_use/secure_boot.sh"
source "$(dirname "$0")/src/generic_use/colors.sh"
source "$(dirname "$0")/src/generic_use/functions.sh"
source "$(dirname "$0")/src/generic_use/monitors.sh"
source "$(dirname "$0")/src/nvidia/nvidia_interface.sh"
source "$(dirname "$0")/src/generic_use/hyprland.sh"

OS_ID="unknown"
OS_LIKE="unknown"
FAMILY="unknown"

NVIDIA_CARD=""
INTEL_CARD=""
AMD_CARD=""

declare -a PKG_UPDATE_CMD
declare -a PKG_INSTALL_CMD

function get_system_status() {
    fecho "INFO" "Detecting operating system..."

    #family
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID="$ID"
        OS_LIKE="$ID_LIKE"
        if command -v apt-get &> /dev/null; then
            FAMILY="debian"
            PKG_UPDATE_CMD=(apt-get update)
            PKG_INSTALL_CMD=(apt-get install -y)
        elif command -v dnf &> /dev/null; then
            FAMILY="fedora"
            PKG_UPDATE_CMD=(dnf makecache)
            PKG_INSTALL_CMD=(dnf install -y)
        elif command -v pacman &> /dev/null; then
            FAMILY="arch"
            PKG_UPDATE_CMD=(true) # Arch doesn't have a separate update command
            PKG_INSTALL_CMD=(pacman -S --noconfirm --needed)
        elif command -v zypper &> /dev/null; then
            FAMILY="suse"
            PKG_UPDATE_CMD=(zypper refresh)
            PKG_INSTALL_CMD=(zypper install -y)
        else
            FAMILY="unknown"
        fi
    fi
}

function get_gpus_info() {
    fecho "INFO" "Detecting GPU information..."
    if [ -d /sys/class/drm ]; then
        for card in /sys/class/drm/card*; do
            [ -e "$card" ] || continue
            [ -d "$card/device" ] || continue
            
            local num
            num=$(basename "$card" | sed 's/card//')
            local vendor_file="/sys/class/drm/card$num/device/vendor"
            if [ -f "$vendor_file" ]; then
                local vendor
                vendor=$(cat "$vendor_file")
                if [[ "$vendor" == *"0x10de"* ]]; then 
                    NVIDIA_CARD="$card"
                fi
                if [[ "$vendor" == *"0x8086"* ]]; then 
                    INTEL_CARD="$card"
                fi
                if [[ "$vendor" == *"0x1002"* ]]; then 
                    AMD_CARD="$card"
                fi
            fi
        done
    fi
}

show_system_status() {
    clear
    printf '%b=== System and GPU Status ===%b\n' "${CYAN:-}" "${NC:-}"
    printf '%bKernel:%b %s\n' "${GREEN:-}" "${NC:-}" "$(uname -r)"
    printf '%bOS:%b %s | %bFamily:%b %s\n' "${GREEN:-}" "${NC:-}" "$OS_ID" "${GREEN:-}" "${NC:-}" "$FAMILY"
    printf '%bSession:%b %s | %bDesktop:%b %s\n' "${GREEN:-}" "${NC:-}" "${XDG_SESSION_TYPE:-unknown}" "${GREEN:-}" "${NC:-}" "${XDG_CURRENT_DESKTOP:-unknown}"
    printf '%bSecure Boot:%b %s\n' "${GREEN:-}" "${NC:-}" "$SECURE_BOOT"
    printf '\n'
    
    printf '%bDetected Hardware (lspci):%b\n' "${YELLOW:-}" "${NC:-}"
    LC_ALL=C lspci -nn | grep -E 'VGA|3D|Display' || echo "No GPU detected."
    printf '\n'

    if command -v nvidia-smi &> /dev/null; then
        printf '%bNVIDIA Monitoring:%b\n' "${GREEN:-}" "${NC:-}"
        nvidia-smi --query-gpu=name,driver_version,memory.used,utilization.gpu --format=csv,noheader || echo "Failed to query nvidia-smi"
    else
        printf '%bNVIDIA drivers not loaded or not installed.%b\n' "${RED:-}" "${NC:-}"
    fi
    printf '\n'
    
    printf '%bEnvironment Variables (/etc/environment):%b\n' "${YELLOW:-}" "${NC:-}"
    if [ -f /etc/environment ]; then
        grep -E "KWIN_DRM|__NV_PRIME|__GLX_VENDOR|__VK_LAYER" /etc/environment || echo "None."
    else
        echo "/etc/environment file does not exist."
    fi
    printf '\n'

    printf '%bConnected monitors and announced modes:%b\n' "${YELLOW:-}" "${NC:-}"
    show_connected_monitors
    printf '\n'
    }

    # Update a specific variable in /etc/environment.
    update_environment_variable() {
    local var_name="$1"
    local new_val="$2"
    local tmpfile

    [ ! -f /etc/environment ] && touch /etc/environment

    cp /etc/environment /etc/environment.bak

    tmpfile=$(mktemp)
    grep -v "^$var_name=" /etc/environment > "$tmpfile" || true
    [ -n "$new_val" ] && echo "$var_name=$new_val" >> "$tmpfile"
    mv "$tmpfile" /etc/environment
    chmod 644 /etc/environment
    }

    # Helper actions for configure_settings
    _hypr_apply_both() {
        configure_hyprland_high_refresh
        cleanup_global_nvidia_offload_env
        fecho "INFO" "Settings applied."
    }

    _action_drm_nvidia_primary() {
        if [ -z "$NVIDIA_CARD" ]; then fecho "ERRO" "NVIDIA GPU not found."; return 1; fi
        local fallback="${INTEL_CARD:-$AMD_CARD}"
        local new_dev="$NVIDIA_CARD${fallback:+:$fallback}"
        update_environment_variable "KWIN_DRM_DEVICES" "$new_dev"
        fecho "INFO" "Configured! NVIDIA prioritized."
        fecho "WARN" "You must restart your session to apply changes."
    }

    _action_drm_hybrid() {
        local primary="${INTEL_CARD:-$AMD_CARD}"
        if [ -z "$primary" ]; then fecho "ERRO" "Integrated GPU not found."; return 1; fi
        if [ -z "$NVIDIA_CARD" ]; then fecho "ERRO" "NVIDIA GPU not found."; return 1; fi
        local new_dev="$primary:$NVIDIA_CARD"
        update_environment_variable "KWIN_DRM_DEVICES" "$new_dev"
        fecho "INFO" "Configured! Integrated prioritized."
        fecho "WARN" "You must restart your session to apply changes."
    }

    _action_drm_integrated() {
        local primary="${INTEL_CARD:-$AMD_CARD}"
        if [ -z "$primary" ]; then fecho "ERRO" "Integrated GPU not found."; return 1; fi
        update_environment_variable "KWIN_DRM_DEVICES" "$primary"
        fecho "INFO" "Configured! Only integrated GPU will be used by KWin."
        fecho "WARN" "You must restart your session to apply changes."
    }

    _action_drm_default() {
        update_environment_variable "KWIN_DRM_DEVICES" ""
        fecho "INFO" "Rule removed. System will decide."
        fecho "WARN" "You must restart your session to apply changes."
    }

    configure_settings() {
        get_gpus_info

        if [[ "${XDG_CURRENT_DESKTOP:-}" == *"Hyprland"* ]]; then
            declare -A HYPR_LABELS=(
                [refresh]="Apply highest refresh rate on Hyprland"
                [offload]="Remove global NVIDIA offload variables"
                [both]="Apply both settings"
                [back]="Back"
            )
            declare -A HYPR_ACTIONS=(
                [refresh]="configure_hyprland_high_refresh"
                [offload]="cleanup_global_nvidia_offload_env"
                [both]="_hypr_apply_both"
                [back]="menu_back"
            )
            local HYPR_ORDER=(refresh offload both back)
            
            menu "Hyprland Configuration" HYPR_LABELS HYPR_ACTIONS HYPR_ORDER
            reload_hyprland || true
        else
            if [[ "${XDG_CURRENT_DESKTOP:-}" != *"KDE"* ]] || [[ "${XDG_SESSION_TYPE:-}" != "wayland" ]]; then
                fecho "WARN" "KWIN_DRM_DEVICES configuration is specific to KDE Plasma on Wayland."
                printf 'Detected environment: %s on %s.\n\n' "${XDG_CURRENT_DESKTOP:-unknown}" "${XDG_SESSION_TYPE:-unknown}"
                printf 'Press any key to continue to DRM settings...'
                read -rsn1
            fi

            declare -A DRM_LABELS=(
                [nvidia]="NVIDIA Primary (Total Performance)"
                [hybrid]="Integrated Primary, NVIDIA Secondary (Hybrid)"
                [integrated]="Integrated Only (Extreme Economy)"
                [default]="Restore System Default (Remove rule)"
                [back]="Back"
            )
            declare -A DRM_ACTIONS=(
                [nvidia]="_action_drm_nvidia_primary"
                [hybrid]="_action_drm_hybrid"
                [integrated]="_action_drm_integrated"
                [default]="_action_drm_default"
                [back]="menu_back"
            )
            local DRM_ORDER=(nvidia hybrid integrated default back)

            menu "DRM Affinity Configuration" DRM_LABELS DRM_ACTIONS DRM_ORDER
        fi
    }