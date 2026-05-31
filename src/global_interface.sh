#!/bin/bash

source "$(dirname "$0")/src/generic_use/menu.sh"
source "$(dirname "$0")/src/generic_use/secure_boot.sh"
source "$(dirname "$0")/src/generic_use/colors.sh"

#test function
function test_func() {
    echo "This is a test function from global_interfaces.sh"
    get_system_status
    get_gpus_info
}

function get_system_status() {
    echo "getting system status..."
    echo "Secure Boot: $SECURE_BOOT"
}

function get_gpus_info() {
    echo "finding gpus info..."
}