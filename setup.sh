#!/bin/bash

source "$(dirname "$0")/src/global_interface.sh"

# Main loop
while true; do
    echo "=============="
    echo "GPU Setup Menu"
    echo "=============="
    
    for key in "${MENU_ORDER[@]}"; do
        echo "$key) ${MENU_LABELS[$key]}"
    done
    
    read -p "Select an option: " choice
    
    if [[ -n "${MENU_ACTIONS[$choice]}" ]]; then
        ${MENU_ACTIONS[$choice]}
        [["$choice" == "0"]] && exit 0
    else
        echo "Invalid option. Please try again."
    fi
    
    echo ""
done