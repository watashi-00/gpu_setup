#!/bin/bash

# Return from the current menu. Useful for submenu "Back" actions.
menu_back() {
    return 130
}

_menu_build_default_order() {
    local labels_name="$1"
    local -n labels_ref="$labels_name"
    local key

    for key in "${!labels_ref[@]}"; do
        printf '%s\n' "$key"
    done | sort -n
}

_menu_clear() {
    if [ -t 1 ]; then
        clear
    fi
}

_menu_render() {
    local title="$1"
    local labels_name="$2"
    local order_name="$3"
    local selected="$4"
    local -n labels_ref="$labels_name"
    local -n order_ref="$order_name"
    local index key

    _menu_clear

    if [ -n "$title" ]; then
        printf '==============\n'
        printf '%s\n' "$title"
        printf '==============\n\n'
    fi

    for index in "${!order_ref[@]}"; do
        key="${order_ref[$index]}"

        if [ "$index" -eq "$selected" ]; then
            printf '%b> %s%b\n' "${CYAN:-}" "${labels_ref[$key]}" "${NC:-}"
        else
            printf '  %s\n' "${labels_ref[$key]}"
        fi
    done

    printf '\nUse [ARROW KEYS] to navigate, [ENTER] to select, [Q] to go back.\n'
}

menu() {
    local title labels_name actions_name order_name

    if [ "$#" -eq 2 ]; then
        title=""
        labels_name="$1"
        actions_name="$2"
        order_name=""
    elif [ "$#" -eq 3 ]; then
        title="$1"
        labels_name="$2"
        actions_name="$3"
        order_name=""
    else
        title="$1"
        labels_name="$2"
        actions_name="$3"
        order_name="$4"
    fi

    local -n labels_ref="$labels_name"
    local -n actions_ref="$actions_name"
    local menu_order=()
    local selected=0
    local input key action action_status

    if [ -n "$order_name" ]; then
        local -n custom_order_ref="$order_name"
        menu_order=("${custom_order_ref[@]}")
    else
        mapfile -t menu_order < <(_menu_build_default_order "$labels_name")
    fi

    if [ "${#menu_order[@]}" -eq 0 ]; then
        printf 'No menu options configured.\n'
        return 1
    fi

    while true; do
        _menu_render "$title" "$labels_name" menu_order "$selected"
        if ! read -rsn1 input; then
            return 0
        fi

        case "$input" in
            $'\x1b')
                read -rsn2 -t 0.1 input
                case "$input" in
                    "[A")
                        ((selected--))
                        if [ "$selected" -lt 0 ]; then
                            selected=$((${#menu_order[@]} - 1))
                        fi
                        ;;
                    "[B")
                        ((selected++))
                        if [ "$selected" -ge "${#menu_order[@]}" ]; then
                            selected=0
                        fi
                        ;;
                esac
                ;;
            "")
                key="${menu_order[$selected]}"
                action="${actions_ref[$key]}"

                if [ -z "$action" ] || ! declare -f "$action" > /dev/null; then
                    printf 'Invalid selection: no action defined for "%s".\n' "${labels_ref[$key]}"
                    sleep 1.5
                    continue
                fi

                _menu_clear
                "$action"
                action_status="$?"

                case "$action_status" in
                    130)
                        return 0
                        ;;
                    2)
                        continue
                        ;;
                    *)
                        printf '\nPress any key to return to the menu...'
                        read -rsn1
                        ;;
                esac
                ;;
            [Qq])
                return 0
                ;;
        esac
    done
}
