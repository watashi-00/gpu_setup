#!/bin/bash

SECURE_BOOT="unknown"

if command -v mokutil &> /dev/null; then
    if mokutil --sb-state 2>/dev/null | grep -q "enabled"; then
        SECURE_BOOT="enabled"
    else
        SECURE_BOOT="disabled"
    fi
else
    SB_FILE=$(ls /sys/firmware/efi/vars/SecureBoot-*/data 2>/dev/null | head -n 1)
    
    if [ -n "$SB_FILE" ] && [ -f "$SB_FILE" ]; then
        SECURE_BOOT_HEX=$(hexdump -v -e '1/1 "%02x"' "$SB_FILE")
        if [ "$SECURE_BOOT_HEX" == "01" ]; then
            SECURE_BOOT="enabled"
        else
            SECURE_BOOT="disabled"
        fi
    else
        SECURE_BOOT="unknown"
    fi
fi