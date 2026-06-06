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

# Install NVIDIA drivers based on the distribution family.
nvidia_install() {
    fecho "INFO" "Preparing NVIDIA driver installation for family: $FAMILY"
    
    local packages=()
    
    case "$FAMILY" in
        arch)
            ensure_arch_multilib || true
            local krel
            krel=$(uname -r)
            local hd="linux-headers"
            if [[ "$krel" == *"-lts"* ]]; then 
                hd="linux-lts-headers"
            elif [[ "$krel" == *"-zen"* ]]; then 
                hd="linux-zen-headers"
            fi
            if grep -q "^\[multilib\]" /etc/pacman.conf; then
                packages=(nvidia-dkms nvidia-utils "$hd" lib32-nvidia-utils opencl-nvidia)
            else
                fecho "WARN" "[multilib] not enabled. Skipping 32-bit NVIDIA utilities (lib32-nvidia-utils)."
                packages=(nvidia-dkms nvidia-utils "$hd" opencl-nvidia)
            fi
            ;;
        debian)
            if [[ "$OS_ID" == "ubuntu" ]] || [[ "$OS_LIKE" == *"ubuntu"* ]] || [[ "$OS_ID" == "zorin" ]] || [[ "$OS_ID" == "linuxmint" ]]; then
                fecho "INFO" "Ubuntu-based system detected ($OS_ID). Ensuring restricted and multiverse repos..."
                if command -v add-apt-repository &> /dev/null; then
                    add-apt-repository -y restricted
                    add-apt-repository -y multiverse
                else
                    fecho "WARN" "add-apt-repository not found. Trying to enable via sources.list..."
                    sed -i '/^deb .*main$/ s/$/ restricted multiverse/' /etc/apt/sources.list
                fi
                
                local recommended=""
                if command -v ubuntu-drivers &> /dev/null; then
                    recommended=$(ubuntu-drivers devices 2>/dev/null | grep "recommended" | grep -oE "nvidia-driver-[0-9]+" | head -n 1)
                fi
                
                local driver="${recommended:-nvidia-driver-535}"
                fecho "INFO" "Selected driver: $driver"
                packages=("linux-headers-$(uname -r)" "$driver" mesa-vulkan-drivers)
            else
                packages=("linux-headers-$(uname -r)" nvidia-driver nvidia-dkms firmware-misc-nonfree mesa-vulkan-drivers nvidia-vulkan-common)
            fi
            ;;
        fedora)
            if ! dnf repolist | grep -qi rpmfusion-nonfree; then
                fecho "WARN" "RPMFusion Non-Free not detected. This is required for NVIDIA drivers on Fedora."
                read -r -p "  Do you want to install RPMFusion now? (y/n): " rpmf
                if [[ "$rpmf" =~ ^[Yy]$ ]]; then
                    dnf install -y "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
                fi
            fi
            packages=(akmod-nvidia xorg-x11-drv-nvidia-cuda mesa-vulkan-drivers kernel-devel)
            ;;
        suse)
            fecho "WARN" "Please ensure you have added the official NVIDIA repository for openSUSE."
            fecho "WARN" "Example: zypper addrepo --refresh https://download.nvidia.com/opensuse/tumbleweed NVIDIA"
            packages=(nvidia-video-G06 nvidia-gl-G06)
            ;;
        *)
            fecho "ERRO" "Unsupported family for NVIDIA installation: $FAMILY"
            return 1
            ;;
    esac

    if [ ${#packages[@]} -eq 0 ]; then
        fecho "ERRO" "No packages defined for NVIDIA installation."
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
        
        if ! verify_and_rollback "${packages[@]}"; then
            return 1
        fi
        
        # Create NVIDIA offload wrapper
        local wrapper="/usr/local/bin/run-gpu"
        printf '#!/bin/bash\nexport __NV_PRIME_RENDER_OFFLOAD=1\nexport __GLX_VENDOR_LIBRARY_NAME=nvidia\nexport __VK_LAYER_NV_optimus=NVIDIA_only\nexec "$@"\n' > "$wrapper"
        chmod +x "$wrapper"
        fecho "SUCCESS" "Drivers installed and 'run-gpu' wrapper configured!"
    fi
}
