#!/bin/bash

source "$(dirname "$0")/src/global_interface.sh"
source "$(dirname "$0")/src/generic_use/colors.sh"

# Main loop

tput civis
trap "tput cnorm" EXIT


MENU_SIZE=${#MENU_ORDER[@]}
SELECTED=1

while true; do
    echo "=============="
    echo "GPU Setup Menu"
    echo "=============="

    for i in "${MENU_ORDER[@]}"; do
        if [ "$i" -eq "$SELECTED" ]; then
            echo -e "${CYAN}> ${MENU_LABELS[$i]}${NC}"
        else
            echo "  ${MENU_LABELS[$i]}"
        fi
    done

    echo "Use [ARROW KEYS] to navigate, [ENTER] to select, [Q] to quit."
    read -rsn1 input

    case "$input" in
        $'\x1b') # ESC sequence (arrow keys)
            read -rsn2 -t 0.1 input
            if [[ "$input" == "[A" ]]; then # Up arrow
                ((SELECTED--))
                if [ "$SELECTED" -lt 0 ]; then
                    SELECTED=$((MENU_SIZE - 1))
                fi
            elif [[ "$input" == "[B" ]]; then # Down arrow
                ((SELECTED++))
                if [ "$SELECTED" -ge "$MENU_SIZE" ]; then
                    SELECTED=0
                fi
            fi
            ;;
        "") # Enter key
            ACTION="${MENU_ACTIONS[$SELECTED]}"
            if [ -n "$ACTION" ] && declare -f "$ACTION" > /dev/null; then
                clear
                $ACTION
                echo "Press any key to return to the menu..."
                read -rsn1
            else
                echo "Invalid selection: No action defined for this option."
                sleep 1.5
            fi
            ;;
        [Qq]) # Quit
            echo "Exiting..."
            break
            ;;
    esac
    clear

done