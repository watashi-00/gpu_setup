#!/bin/bash

# Main loop
while true; do
    echo -e "=============="
    echo -e "GPU Setup Menu"
    echo -e "=============="
    echo -e "1) Install or Update GPU Drivers"
    echo -e "2) System Status"
    echo -e "0) Exit"
    read -r -p "Choose an option: " OPT
    case $OPT in
        1)
            echo -e "${OPT}"
            ;;
        2)
            echo -e "${OPT}"
            ;;
        0)
            echo -e "Exiting..."
            exit 0
            ;;
        *)
            echo -e "Invalid option. Please try again."
            ;;
    esac
done