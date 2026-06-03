#!/bin/bash

# Install Intel drivers based on the distribution family.
intel_install() {
    fecho "INFO" "Preparing Intel driver installation for family: $FAMILY"
    
    local packages=()
    
    case "$FAMILY" in
        arch)
            packages=(mesa lib32-mesa vulkan-intel lib32-vulkan-intel)
            ;;
        debian)
            packages=(libgl1-mesa-dri mesa-vulkan-drivers intel-media-va-driver)
            ;;
        fedora)
            packages=(mesa-dri-drivers intel-media-driver vulkan-loader)
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
    read -r -p "Confirm installation? (y/n): " conf
    if [[ "$conf" =~ ^[Yy]$ ]]; then
        "${PKG_UPDATE_CMD[@]}" || fecho "WARN" "Repository update partially failed."
        
        if ! "${PKG_INSTALL_CMD[@]}" "${packages[@]}"; then
            fecho "ERRO" "Package installation failed."
            return 1
        fi
        
        fecho "INFO" "Intel drivers installed successfully!"
    fi
}
