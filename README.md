# GPU Setup Manager

A modular, interactive command-line utility for Linux designed to simplify GPU driver installation, hardware detection, and display server configuration (KDE Wayland & Hyprland).

## 🌟 Features

*   **Interactive Menu System:** Navigate easily using arrow keys in a clean, modern TUI (Text User Interface).
*   **Smart Hardware Detection:** Automatically detects your connected GPUs (NVIDIA, AMD, Intel) and monitors via `lspci` and DRM sysfs.
*   **Cross-Distribution Support:** Automatically adapts package managers and driver names for major Linux families.
*   **Secure Boot Awareness:** Warns users if Secure Boot is enabled before installing unsigned kernel modules (like NVIDIA DKMS).
*   **KDE Plasma Wayland Affinity:** Easily configure `KWIN_DRM_DEVICES` for multi-GPU setups (e.g., force KWin to use the integrated GPU while saving the dGPU for gaming).
*   **Hyprland Optimization:** Automatically detects and applies the highest supported refresh rate for all connected monitors directly to your `hyprland.conf`.
*   **NVIDIA Prime Wrapper:** Automatically generates a `run-gpu` wrapper script for NVIDIA users to easily launch applications with the discrete GPU.

## 🐧 Supported Distributions

The script automatically detects and supports the following Linux families:
*   **Arch Linux** (and derivatives like EndeavourOS, Manjaro, Garuda)
*   **Debian / Ubuntu** (and derivatives like Linux Mint, Zorin OS, Pop!_OS)
*   **Fedora**
*   **openSUSE**

## 🚀 Usage

### Prerequisites
You only need a standard Linux environment with `bash` and `sudo` privileges.

### Running the Script
Clone the repository and run the entry point script:

```bash
git clone https://github.com/watashi-00/gpu_setup.git
cd gpu_setup
sudo ./setup.sh
```

### Global Installation
Inside the main menu, you can select **"Install Script Globally"**. This will copy the script to `/usr/local/bin/gpu-setup`, allowing you to run it from anywhere in your terminal simply by typing:

```bash
sudo gpu-setup
```

## 📂 Project Structure

```text
gpu_setup/
├── setup.sh                     # Main entry point
└── src/
    ├── global_interface.sh      # Orchestrator and global state
    ├── amd/
    │   └── amd_interface.sh     # AMD-specific installation logic
    ├── intel/
    │   └── intel_interface.sh   # Intel-specific installation logic
    ├── nvidia/
    │   └── nvidia_interface.sh  # NVIDIA-specific logic and offload cleanup
    └── generic_use/
        ├── colors.sh            # Global color palette and styling
        ├── functions.sh         # Helper functions (fecho, check_root, etc.)
        ├── hyprland.sh          # Hyprland config parsing and reloading
        ├── menu.sh              # Centralized interactive TUI menu system
        └── monitors.sh          # DRM monitor and refresh rate detection
```

## ⚠️ Disclaimer

Modifying GPU drivers, DRM paths, and Wayland compositor configurations can potentially result in a black screen if your hardware combination is unusual. **Always ensure you have a fallback TTY or SSH access** to revert changes if necessary. Use this tool at your own risk.