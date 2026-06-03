#!/bin/bash

source "$(dirname "$0")/src/generic_use/menu.sh"
source "$(dirname "$0")/src/generic_use/secure_boot.sh"
source "$(dirname "$0")/src/generic_use/colors.sh"
source "$(dirname "$0")/src/generic_use/functions.sh"
source "$(dirname "$0")/src/generic_use/monitors.sh"
source "$(dirname "$0")/src/nvidia/nvidia_interface.sh"
source "$(dirname "$0")/src/generic_use/hyprland.sh"

#test function
function config() {
    echo -e "${BLUE}configuring settings...${NC}"
    get_system_status
    get_gpus_info
    echo -e "${GREEN}Configuration complete.${NC}"
    for i in {1..10}; do
        echo -n "."
        sleep 0.5
    done
    echo -e "${GREEN}Done!${NC}"
    sleep 2
}

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
    fecho 

    #family
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "OS: $NAME $VERSION"
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
    else
        echo "OS: Unknown"
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
                    fecho "INFO" "Found NVIDIA GPU at $card"
                fi
                if [[ "$vendor" == *"0x8086"* ]]; then 
                    INTEL_CARD="$card"
                    fecho "INFO" "Found Intel GPU at $card"
                fi
                if [[ "$vendor" == *"0x1002"* ]]; then 
                    AMD_CARD="$card"
                    fecho "INFO" "Found AMD GPU at $card"
                fi
            fi
        done
    else
        fecho "WARN" "DRM directory (/sys/class/drm) not found."
    fi
}

config