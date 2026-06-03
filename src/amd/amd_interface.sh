#!/bin/bash

# Install AMD drivers based on the distribution family.
amd_install() {
    fecho "INFO" "Preparing AMD driver installation for family: $FAMILY"
    
    local packages=()
    
    case "$FAMILY" in
        arch)
            packages=(mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon xf86-video-amdgpu)
            ;;
        debian)
            packages=(libgl1-mesa-dri xserver-xorg-video-amdgpu mesa-vulkan-drivers)
            ;;
        fedora)
            packages=(mesa-dri-drivers xorg-x11-drv-amdgpu vulkan-loader)
            ;;
        suse)
            packages=(Mesa-libGL1 xf86-video-amdgpu)
            ;;
        *)
            fecho "ERRO" "Unsupported family for AMD installation: $FAMILY"
            return 1
            ;;
    esac

    if [ ${#packages[@]} -eq 0 ]; then
        fecho "ERRO" "No packages defined for AMD installation."
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
        
        fecho "INFO" "AMD drivers installed successfully!"
    fi
}
