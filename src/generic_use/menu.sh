#!/bin/bash

declare -A MENU_ACTIONS
declare -A MENU_LABELS


MENU_LABELS=(
    [1]="Install or Update GPU Drivers"
    [2]="System Status"
    [3]="Configs"
    [0]="Exit"
)

MENU_ACTIONS=(
    [1]="install_or_update_drivers"
    [2]="show_system_status"
    [3]="configure_settings"
    [0]="exit_program"
)

MENU_ORDER=("1" "2" "3" "0")