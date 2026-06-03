#!/bin/bash

# GPU Setup Manager - Modular Entry Point
# This script consolidates all GPU management tasks into a single interface.

set -euo pipefail

# Determine base directory
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source the global interface which orchestrates all modules
if [ -f "$BASE_DIR/src/global_interface.sh" ]; then
    source "$BASE_DIR/src/global_interface.sh"
else
    echo "Error: Global interface not found at $BASE_DIR/src/global_interface.sh"
    exit 1
fi

# Main execution
main() {
    # Check for root privileges
    check_root

    # Offer global installation if not already installed
    install_global

    # Launch the main menu
    global_main_menu
}

# Ensure terminal state is handled cleanly
if [ -t 1 ]; then
    tput civis
    trap "tput cnorm; clear" EXIT
fi

main "$@"
