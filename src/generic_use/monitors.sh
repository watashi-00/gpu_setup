#!/bin/bash

# Detect and display connected monitors and their supported modes.
show_connected_monitors() {
    if [ ! -d /sys/class/drm ]; then
        fecho "WARN" "DRM unavailable."
        return
    fi

    for status_file in /sys/class/drm/card*-*/status; do
        [ -f "$status_file" ] || continue
        local connector
        connector=$(basename "$(dirname "$status_file")")
        if [ "$(cat "$status_file")" = "connected" ]; then
            printf '  - %b%s connected%b\n' "${GREEN:-}" "$connector" "${NC:-}"
            if [ -f "/sys/class/drm/$connector/modes" ]; then
                sed 's/^/      mode: /' "/sys/class/drm/$connector/modes" | head -n 8
            fi
            if command -v edid-decode &> /dev/null && [ -s "/sys/class/drm/$connector/edid" ]; then
                edid-decode "/sys/class/drm/$connector/edid" 2>/dev/null \
                    | grep -E "DTD:|DTD [0-9]+:" \
                    | grep -E "[0-9]+\.[0-9]+ Hz" \
                    | sed 's/^/      EDID: /' \
                    | head -n 5 || true
            fi
        fi
    done
}
