#!/bin/bash

source "$(dirname "$0")/src/generic_use/menu.sh"
source "$(dirname "$0")/src/generic_use/secure_boot.sh"
source "$(dirname "$0")/src/generic_use/colors.sh"

#test function
function test_func() {
    echo "This is a test function from global_interfaces.sh"
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

function fecho() {
    local label="$1"
    local message="$2"
    ## formating label with 20 characters width and color
    
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

OS_ID="unknown"
OS_LIKE="unknown"
FAMILY="unknown"

declare -a PKG_UPDATE_CMD
declare -a PKG_INSTALL_CMD

function get_system_status() {
    echo "getting system status..."
    echo "Secure Boot: $SECURE_BOOT"
}

function get_gpus_info() {
    echo "finding gpus info..."
}