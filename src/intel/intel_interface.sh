#!/bin/bash

# Install Intel drivers based on the distribution family.
intel_install() {
    fecho "INFO" "Preparing Intel driver installation for family: $FAMILY"
    
    local packages=()
    
    case "$FAMILY" in
        arch)
            ensure_arch_multilib || true
            if grep -q "^\[multilib\]" /etc/pacman.conf; then
                packages=(mesa lib32-mesa vulkan-intel lib32-vulkan-intel)
            else
                fecho "WARN" "[multilib] not enabled. Skipping 32-bit Intel libraries."
                packages=(mesa vulkan-intel)
            fi
            ;;
        debian)
            packages=(libgl1-mesa-dri mesa-vulkan-drivers intel-media-va-driver firmware-misc-nonfree)
            ;;
        fedora)
            packages=(mesa-dri-drivers intel-media-driver mesa-vulkan-drivers)
            ;;
        suse)
            packages=(Mesa-libGL1 vaapi-intel-driver)
            ;;
        *)
            fecho "ERRO" "Unsupported family for Intel installation: $FAMILY"
            return 1
            ;;
    esac

    if [ ${#packages[@]} -eq 0 ]; then
        fecho "ERRO" "No packages defined for Intel installation."
        return 1
    fi

    fecho "INFO" "Packages to install: ${packages[*]}"
    read -r -p "  Confirm installation? (y/n): " conf
    if [[ "$conf" =~ ^[Yy]$ ]]; then
        "${PKG_UPDATE_CMD[@]}" || fecho "WARN" "Repository update partially failed."
        
        if ! "${PKG_INSTALL_CMD[@]}" "${packages[@]}"; then
            fecho "ERRO" "Package installation failed."
            return 1
        fi
        
        if verify_and_rollback "${packages[@]}"; then
            fecho "SUCCESS" "Intel drivers installed and verified successfully!"
        fi
    fi
}
