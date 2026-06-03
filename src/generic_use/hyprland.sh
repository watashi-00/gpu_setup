#!/bin/bash

# Reload Hyprland configuration using hyprctl.
reload_hyprland() {
    if ! command -v hyprctl &> /dev/null; then
        fecho "WARN" "hyprctl not found. Restart Hyprland session to apply changes."
        return 1
    fi

    fecho "INFO" "Waiting 10 seconds before reloading Hyprland..."
    sleep 10

    if hyprctl reload; then
        fecho "INFO" "Hyprland reloaded successfully."
        return 0
    fi

    local target_uid="${SUDO_UID:-$(id -u)}"
    local runtime_dir="/run/user/$target_uid"
    local instance=""

    if [ -d "$runtime_dir/hypr" ]; then
        instance=$(find "$runtime_dir/hypr" -mindepth 1 -maxdepth 1 -type d -printf '%T@ %f\n' 2>/dev/null \
            | sort -nr \
            | head -n 1 \
            | sed 's/^[^ ]* //')
    fi

    if [ -n "$instance" ]; then
        if XDG_RUNTIME_DIR="$runtime_dir" HYPRLAND_INSTANCE_SIGNATURE="$instance" hyprctl reload; then
            fecho "INFO" "Hyprland reloaded successfully."
            return 0
        fi
    fi

    fecho "WARN" "Could not reload via hyprctl. Restart session to apply changes."
    return 1
}

# Configure Hyprland for the highest available refresh rate on connected monitors.
configure_hyprland_high_refresh() {
    local target_home
    target_home=$(get_target_home)
    local conf="$target_home/.config/hypr/hyprland.conf"
    local tmpfile
    local monitor_lines=""
    local position="0x0"
    local conf_uid=""
    local conf_gid=""

    if [ ! -f "$conf" ]; then
        fecho "ERRO" "Hyprland configuration not found at $conf."
        return 1
    fi

    conf_uid=$(stat -c '%u' "$conf" 2>/dev/null || true)
    conf_gid=$(stat -c '%g' "$conf" 2>/dev/null || true)

    cp "$conf" "$conf.bak-$(date +%Y%m%d-%H%M%S)"
    tmpfile=$(mktemp)

    for internal_first in yes no; do
        for status_file in /sys/class/drm/card*-*/status; do
            [ -f "$status_file" ] || continue
            [ "$(cat "$status_file")" = "connected" ] || continue

            local connector output refresh mode
            connector=$(basename "$(dirname "$status_file")")
            output=${connector#card*-}

            if [ "$internal_first" = "yes" ] && [[ "$output" != eDP-* ]]; then
                continue
            fi
            if [ "$internal_first" = "no" ] && [[ "$output" == eDP-* ]]; then
                continue
            fi

            refresh=""
            if command -v edid-decode &> /dev/null && [ -r "/sys/class/drm/$connector/edid" ]; then
                refresh=$(edid-decode "/sys/class/drm/$connector/edid" 2>/dev/null \
                    | awk '/1920x1080/ && /Hz/ { for (i = 1; i <= NF; i++) if ($i == "Hz") print $(i - 1) }' \
                    | sort -nr \
                    | head -n 1)
            fi

            if [ -n "$refresh" ]; then
                mode="1920x1080@$refresh"
            else
                mode="preferred"
            fi

            monitor_lines+="monitor = $output, $mode, $position, 1"$'\n'
            position="auto"
        done
    done

    if [ -z "$monitor_lines" ]; then
        monitor_lines="monitor = , preferred, auto, 1"$'\n'
    fi

    {
        printf '%s' "$monitor_lines"
        grep -Ev '^[[:space:]]*monitor[[:space:]]*=' "$conf" || true
    } > "$tmpfile"

    mv "$tmpfile" "$conf"
    chmod 644 "$conf"
    if [ -n "$conf_uid" ] && [ -n "$conf_gid" ]; then
        chown "$conf_uid:$conf_gid" "$conf" 2>/dev/null || true
    fi

    fecho "INFO" "Hyprland configured for highest available refresh rates."
    printf '%s' "$monitor_lines"
}
