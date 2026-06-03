#!/bin/bash

# Source all required modules using the BASE_DIR defined in the entry point.
source "$BASE_DIR/src/generic_use/menu.sh"
source "$BASE_DIR/src/generic_use/secure_boot.sh"
source "$BASE_DIR/src/generic_use/colors.sh"
source "$BASE_DIR/src/generic_use/functions.sh"
source "$BASE_DIR/src/generic_use/monitors.sh"
source "$BASE_DIR/src/nvidia/nvidia_interface.sh"
source "$BASE_DIR/src/amd/amd_interface.sh"
source "$BASE_DIR/src/intel/intel_interface.sh"
source "$BASE_DIR/src/generic_use/hyprland.sh"

OS_ID="unknown"
OS_LIKE="unknown"
FAMILY="unknown"

NVIDIA_CARD=""
INTEL_CARD=""
AMD_CARD=""

declare -a PKG_UPDATE_CMD
declare -a PKG_INSTALL_CMD

function _print_banner() {
    printf '%b' "${PRIMARY:-}"
    cat << "EOF"
  ____ ____  _   _   ____  _____ _____ _   _ ____  
 / ___|  _ \| | | | / ___|| ____|_   _| | | |  _ \ 
| |  _| |_) | | | | \___ \|  _|   | | | | | | |_) |
| |_| |  __/| |_| |  ___) | |___  | | | |_| |  __/ 
 \____|_|    \___/  |____/|_____| |_|  \___/|_|    
                                                   
EOF
    printf '%b' "${NC:-}"
}

function get_system_status() {
    fecho "INFO" "Detecting operating system..."

    # family
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID="${ID:-unknown}"
        OS_LIKE="${ID_LIKE:-unknown}"
        if command -v apt-get &>/dev/null; then
            FAMILY="debian"
            PKG_UPDATE_CMD=(apt-get update)
            PKG_INSTALL_CMD=(apt-get install -y)
        elif command -v dnf &>/dev/null; then
            FAMILY="fedora"
            PKG_UPDATE_CMD=(dnf makecache)
            PKG_INSTALL_CMD=(dnf install -y)
        elif command -v pacman &>/dev/null; then
            FAMILY="arch"
            PKG_UPDATE_CMD=(true) # Arch doesn't have a separate update command
            PKG_INSTALL_CMD=(pacman -S --noconfirm --needed)
        elif command -v zypper &>/dev/null; then
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

_print_status_row() {
    local key="$1"
    local value="$2"
    printf "  %b%-20s%b %s\n" "${BOLD:-}" "$key" "${NC:-}" "$value"
}

show_system_status() {
    clear
    printf '%b' "${PRIMARY:-}"
    frule "━" "${PRIMARY:-}"
    printf '  %bSYSTEM AND GPU STATUS%b\n' "${BOLD:-}" "${NC:-}"
    frule "━" "${PRIMARY:-}"
    printf '\n'

    printf '%bGeneral Information%b\n' "${BOLD:-}" "${NC:-}"
    frule "─" "${DIM:-}"
    _print_status_row "Kernel" "$(uname -r)"
    _print_status_row "OS ID" "$OS_ID"
    _print_status_row "OS Family" "$FAMILY"
    _print_status_row "Session Type" "${XDG_SESSION_TYPE:-unknown}"
    _print_status_row "Desktop Env" "${XDG_CURRENT_DESKTOP:-unknown}"
    _print_status_row "Secure Boot" "$SECURE_BOOT"
    printf '\n'

    printf '%bHardware Detection (lspci)%b\n' "${BOLD:-}" "${NC:-}"
    frule "─" "${DIM:-}"
    LC_ALL=C lspci -nn | grep -E 'VGA|3D|Display' | sed 's/^/  /' || echo "  No GPU detected."
    printf '\n'

    if command -v nvidia-smi &>/dev/null; then
        printf '%bNVIDIA Monitoring%b\n' "${BOLD:-}" "${NC:-}"
        frule "─" "${DIM:-}"
        nvidia-smi --query-gpu=name,driver_version,memory.used,utilization.gpu --format=csv,noheader | sed 's/^/  /' || echo "  Failed to query nvidia-smi"
    else
        fecho "INFO" "NVIDIA drivers not loaded or not installed."
    fi
    printf '\n'

    printf '%bEnvironment Variables%b\n' "${BOLD:-}" "${NC:-}"
    frule "─" "${DIM:-}"
    if [ -f /etc/environment ]; then
        grep -E "KWIN_DRM|__NV_PRIME|__GLX_VENDOR|__VK_LAYER" /etc/environment | sed 's/^/  /' || echo "  None configured."
    else
        echo "  /etc/environment file does not exist."
    fi
    printf '\n'

    printf '%bConnected Monitors%b\n' "${BOLD:-}" "${NC:-}"
    frule "─" "${DIM:-}"
    show_connected_monitors
    printf '\n'
    frule "━" "${PRIMARY:-}"
}

# Update a specific variable in /etc/environment.
update_environment_variable() {
    local var_name="$1"
    local new_val="$2"
    local tmpfile

    [ ! -f /etc/environment ] && touch /etc/environment

    cp /etc/environment /etc/environment.bak

    tmpfile=$(mktemp)
    grep -v "^$var_name=" /etc/environment >"$tmpfile" || true
    [ -n "$new_val" ] && echo "$var_name=$new_val" >>"$tmpfile"
    mv "$tmpfile" /etc/environment
    chmod 644 /etc/environment
}

# Helper actions for configure_settings
_hypr_action_refresh() {
    configure_hyprland_high_refresh
    reload_hyprland || true
}

_hypr_action_offload() {
    cleanup_global_nvidia_offload_env
    fecho "SUCCESS" "NVIDIA offload variables removed from /etc/environment."
    reload_hyprland || true
}

_hypr_action_both() {
    configure_hyprland_high_refresh
    cleanup_global_nvidia_offload_env
    fecho "SUCCESS" "Settings applied successfully."
    reload_hyprland || true
}

_action_drm_nvidia_primary() {
    if [ -z "$NVIDIA_CARD" ]; then
        fecho "ERRO" "NVIDIA GPU not found."
        return 1
    fi
    local fallback="${INTEL_CARD:-$AMD_CARD}"
    local new_dev="$NVIDIA_CARD${fallback:+:$fallback}"
    update_environment_variable "KWIN_DRM_DEVICES" "$new_dev"
    fecho "SUCCESS" "Configured! NVIDIA prioritized."
    fecho "WARN" "You must restart your session to apply changes."
}

_action_drm_hybrid() {
    local primary="${INTEL_CARD:-$AMD_CARD}"
    if [ -z "$primary" ]; then
        fecho "ERRO" "Integrated GPU not found."
        return 1
    fi
    if [ -z "$NVIDIA_CARD" ]; then
        fecho "ERRO" "NVIDIA GPU not found."
        return 1
    fi
    local new_dev="$primary:$NVIDIA_CARD"
    update_environment_variable "KWIN_DRM_DEVICES" "$new_dev"
    fecho "SUCCESS" "Configured! Integrated prioritized."
    fecho "WARN" "You must restart your session to apply changes."
}

_action_drm_integrated() {
    local primary="${INTEL_CARD:-$AMD_CARD}"
    if [ -z "$primary" ]; then
        fecho "ERRO" "Integrated GPU not found."
        return 1
    fi
    update_environment_variable "KWIN_DRM_DEVICES" "$primary"
    fecho "SUCCESS" "Configured! Only integrated GPU will be used by KWin."
    fecho "WARN" "You must restart your session to apply changes."
}

_action_drm_default() {
    update_environment_variable "KWIN_DRM_DEVICES" ""
    fecho "SUCCESS" "Rule removed. System will decide."
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
            [refresh]="_hypr_action_refresh"
            [offload]="_hypr_action_offload"
            [both]="_hypr_action_both"
            [back]="menu_back"
        )
        local HYPR_ORDER=(refresh offload both back)

        menu "Hyprland Configuration" HYPR_LABELS HYPR_ACTIONS HYPR_ORDER
    else
        if [[ "${XDG_CURRENT_DESKTOP:-}" != *"KDE"* ]] || [[ "${XDG_SESSION_TYPE:-}" != "wayland" ]]; then
            fecho "WARN" "KWIN_DRM_DEVICES configuration is specific to KDE Plasma on Wayland."
            printf '  Detected environment: %s on %s.\n\n' "${XDG_CURRENT_DESKTOP:-unknown}" "${XDG_SESSION_TYPE:-unknown}"
            printf '  Press any key to continue to DRM settings...'
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

install_drivers() {
    clear
    printf '%b' "${PRIMARY:-}"
    frule "━" "${PRIMARY:-}"
    printf '  %bGPU DRIVER INSTALLATION%b\n' "${BOLD:-}" "${NC:-}"
    frule "━" "${PRIMARY:-}"
    printf '\n'

    if [ "$SECURE_BOOT" = "enabled" ]; then
        fecho "WARN" "Secure Boot is ENABLED! NVIDIA modules might not load if not signed."
        read -r -p "  Do you want to continue? (y/n): " sb_conf
        [[ ! "$sb_conf" =~ ^[Yy]$ ]] && return
    fi

    if ! command -v lspci &>/dev/null; then
        fecho "INFO" "Installing pciutils (lspci)..."
        "${PKG_UPDATE_CMD[@]}" || true
        if ! "${PKG_INSTALL_CMD[@]}" pciutils; then
            fecho "ERRO" "Failed to install pciutils."
            return 1
        fi
    fi

    mapfile -t gpus < <(LC_ALL=C lspci -nn | grep -E 'VGA|3D|Display')
    if [ ${#gpus[@]} -eq 0 ]; then
        fecho "ERRO" "No GPU detected."
        return 1
    fi

    declare -A GPU_LABELS
    declare -A GPU_ACTIONS
    local GPU_ORDER=()

    for i in "${!gpus[@]}"; do
        local gpu="${gpus[$i]}"
        local key="gpu_$i"
        GPU_LABELS[$key]="$gpu"

        if echo "$gpu" | grep -Eiq 'NVIDIA'; then
            GPU_ACTIONS[$key]="nvidia_install"
        elif echo "$gpu" | grep -Eiq 'AMD|Radeon|Advanced Micro Devices'; then
            GPU_ACTIONS[$key]="amd_install"
        elif echo "$gpu" | grep -Eiq 'Intel'; then
            GPU_ACTIONS[$key]="intel_install"
        else
            GPU_ACTIONS[$key]=""
        fi
        GPU_ORDER+=("$key")
    done
    GPU_LABELS[back]="Back"
    GPU_ACTIONS[back]="menu_back"
    GPU_ORDER+=("back")

    menu "Select GPU to install drivers" GPU_LABELS GPU_ACTIONS GPU_ORDER
}

_action_exit() {
    if [ -t 1 ]; then
        clear
    fi
    printf "Exiting...\n"
    exit 0
}

global_main_menu() {
    get_system_status
    get_gpus_info

    _menu_clear
    _print_banner

    declare -A MAIN_LABELS=(
        [drivers]="Install/Update GPU Drivers"
        [status]="Show System Status"
        [config]="Affinity and Performance Configuration"
        [install]="Install Script Globally"
        [exit]="Exit"
    )
    declare -A MAIN_ACTIONS=(
        [drivers]="install_drivers"
        [status]="show_system_status"
        [config]="configure_settings"
        [install]="install_global"
        [exit]="_action_exit"
    )
    local MAIN_ORDER=(drivers status config install exit)

    menu "GPU Setup Manager" MAIN_LABELS MAIN_ACTIONS MAIN_ORDER
}
