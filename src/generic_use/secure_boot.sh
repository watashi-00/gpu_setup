#!/bin/bash

SECURE_BOOT="unknown"

if command -v mokutil &> /dev/null; then
    if mokutil --sb-state 2>/dev/null | grep -q "enabled"; then
        SECURE_BOOT="enabled"
    else
        SECURE_BOOT="disabled"
    fi
else
    # Use a safer way to find the file that doesn't trigger set -e
    SB_FILE=""
    for f in /sys/firmware/efi/vars/SecureBoot-*/data; do
        if [ -f "$f" ]; then
            SB_FILE="$f"
            break
        fi
    done
    
    if [ -n "$SB_FILE" ]; then
        SECURE_BOOT_HEX=$(hexdump -v -e '1/1 "%02x"' "$SB_FILE" 2>/dev/null || echo "00")
        if [ "$SECURE_BOOT_HEX" == "01" ]; then
            SECURE_BOOT="enabled"
        else
            SECURE_BOOT="disabled"
        fi
    else
        SECURE_BOOT="unknown"
    fi
fi