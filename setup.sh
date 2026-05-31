#!/bin/bash

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$BASE_DIR/src/global_interface.sh"
source "$BASE_DIR/src/generic_use/colors.sh"
source "$BASE_DIR/src/generic_use/menu.sh"

exit_program() {
    if [ -t 1 ]; then
        clear
    fi
    printf 'Exiting...\n'
    exit 0
}

declare -A MAIN_MENU_LABELS=(
    [drivers]="Install or Update GPU Drivers"
    [status]="System Status"
    [configs]="Configs"
    [exit]="Exit"
)

declare -A MAIN_MENU_ACTIONS=(
    [drivers]="install_or_update_drivers"
    [status]="show_system_status"
    [configs]="configure_settings"
    [exit]="exit_program"
)

MAIN_MENU_ORDER=(drivers status configs exit)

declare -A CONFIG_MENU_LABELS=(
    [secure_boot]="Secure Boot Status"
    [back]="Back"
)

declare -A CONFIG_MENU_ACTIONS=(
    [secure_boot]="show_secure_boot_status"
    [back]="menu_back"
)

CONFIG_MENU_ORDER=(secure_boot back)

if [ -t 1 ]; then
    tput civis
    trap "tput cnorm" EXIT
fi

menu "GPU Setup Menu" MAIN_MENU_LABELS MAIN_MENU_ACTIONS MAIN_MENU_ORDER
