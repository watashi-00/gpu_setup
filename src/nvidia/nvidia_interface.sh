#!/bin/bash

# Remove global NVIDIA offload environment variables from /etc/environment.
cleanup_global_nvidia_offload_env() {
    local tmpfile

    if [ ! -f /etc/environment ]; then
        return 0
    fi

    cp /etc/environment /etc/environment.bak

    tmpfile=$(mktemp)
    grep -Ev '^(__NV_PRIME_RENDER_OFFLOAD|__GLX_VENDOR_LIBRARY_NAME|__VK_LAYER_NV_optimus)=' /etc/environment > "$tmpfile" || true
    mv "$tmpfile" /etc/environment
    chmod 644 /etc/environment
}
