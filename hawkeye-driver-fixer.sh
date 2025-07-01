#!/bin/bash

#===========================================================
# Debian-Driver Resolver 0.3 by Hawkeye (Team Hawkeye)
#-----------------------------------------------------------
# Upgraded for comprehensive hardware detection, dynamic menu
# generation, and enhanced user experience.
#===========================================================

# --- License Placeholder ---
# This script is released under the MIT License.
# Copyright (c) 2024 Hawkeye (Team Hawkeye)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# --- Configuration ---
LOG_FILE="/var/log/debian-driver-resolver.log" # Log file for script actions

# --- Colors for better output ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Global Hardware Detection Flags ---
# These flags will be set by the detect_hardware function
HAS_WIFI=false
HAS_BLUETOOTH=false
HAS_AUDIO_DEVICE=false
HAS_GPU_NVIDIA=false
HAS_GPU_AMD=false
HAS_GPU_INTEL=false
HAS_GENERIC_GPU=false # For other or integrated GPUs not explicitly Intel/AMD/NVIDIA
HAS_USB_CONTROLLER=false

# --- Logging function ---
# Appends a timestamped message to the log file.
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a "$LOG_FILE" > /dev/null
}

# --- Initial Setup and Checks ---

# Ensure script exits immediately if a command exits with a non-zero status.
set -e

# Check for root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}[!] This script must be run with sudo privileges.${NC}"
        echo -e "${YELLOW}Please run: sudo $0${NC}"
        exit 1
    fi
}

# Check for figlet and install if not present
check_figlet() {
    if ! command -v figlet &> /dev/null; then
        echo -e "${YELLOW}[!] figlet not found. Installing figlet for banner...${NC}"
        log_action "Installing figlet."
        sudo apt update -y && sudo apt install figlet -y
        if ! command -v figlet &> /dev/null; then
            echo -e "${RED}[✖] Failed to install figlet. Proceeding without banner.${NC}"
            log_action "Failed to install figlet."
        fi
    fi
}

# Show Banner
show_banner() {
    clear
    if command -v figlet &> /dev/null; then
        figlet -c "Debian-Driver Resolver 0.3"
        echo -e "${CYAN}             by Hawkeye (Team Hawkeye)${NC}\n"
    else
        echo -e "${CYAN}===========================================${NC}"
        echo -e "${CYAN} Debian-Driver Resolver 0.3${NC}"
        echo -e "${CYAN}             by Hawkeye (Team Hawkeye)${NC}"
        echo -e "${CYAN}===========================================${NC}\n"
    fi
}

# --- Helper Functions ---

# Progress bar function (simplified for clarity, actual progress is hard to track accurately for apt)
progress_bar() {
    local duration=$1
    echo -n "["
    for ((i = 0; i <= duration; i++)); do
        printf "#"
        sleep 0.05 # Adjust speed as needed
    done
    echo "]"
}

# --- Hardware Detection Function ---
# This function identifies connected hardware and sets global flags.
detect_hardware() {
    echo -e "\n${MAGENTA}--- Detecting System Hardware ---${NC}"
    log_action "Starting hardware detection."

    # Wi-Fi Detection
    if lspci | grep -qi "network controller" | grep -qi "wireless" || lspci | grep -qi "wi-fi"; then
        HAS_WIFI=true
        echo -e "${GREEN}[✔] Wi-Fi adapter detected.${NC}"
    else
        echo -e "${YELLOW}[✖] No Wi-Fi adapter detected.${NC}"
    fi

    # Bluetooth Detection
    if lsusb | grep -qi "bluetooth" || lspci | grep -qi "bluetooth" || lspci | grep -qi "wireless" | grep -qi "bluetooth" || lsusb | grep -qi "Intel Corp." | grep -qi "wireless"; then
        HAS_BLUETOOTH=true
        echo -e "${GREEN}[✔] Bluetooth device detected.${NC}"
    else
        echo -e "${YELLOW}[✖] No Bluetooth device detected.${NC}"
    fi

    # Audio Device Detection
    if lspci | grep -qi "audio device"; then
        HAS_AUDIO_DEVICE=true
        echo -e "${GREEN}[✔] Audio device detected.${NC}"
    else
        echo -e "${YELLOW}[✖] No Audio device detected.${NC}"
    fi

    # GPU Detection
    local gpu_info=$(lspci | grep -i vga || lspci | grep -i "3D controller")
    if [[ -n "$gpu_info" ]]; then
        echo -e "${GREEN}[✔] Graphics processing unit (GPU) detected.${NC}"
        if echo "$gpu_info" | grep -qi "nvidia"; then
            HAS_GPU_NVIDIA=true
            echo -e "    ${CYAN}Detected: NVIDIA GPU${NC}"
        elif echo "$gpu_info" | grep -qi "amd"; then
            HAS_GPU_AMD=true
            echo -e "    ${CYAN}Detected: AMD GPU${NC}"
        elif echo "$gpu_info" | grep -qi "intel"; then
            HAS_GPU_INTEL=true
            echo -e "    ${CYAN}Detected: Intel Integrated Graphics${NC}"
        else
            HAS_GENERIC_GPU=true
            echo -e "    ${CYAN}Detected: Other/Generic GPU (using open-source drivers)${NC}"
        fi
    else
        echo -e "${YELLOW}[✖] No dedicated GPU detected.${NC}"
    fi

    # USB Controller Detection
    if lspci | grep -qi "usb controller"; then
        HAS_USB_CONTROLLER=true
        echo -e "${GREEN}[✔] USB Controller detected.${NC}"
    else
        echo -e "${YELLOW}[✖] No USB Controller detected.${NC}"
    fi

    echo -e "${MAGENTA}--- Hardware Detection Complete ---${NC}"
    log_action "Hardware detection completed."
}

# --- Core Functions ---

# Ensure all needed APT sources are enabled
enable_repos() {
    echo -e "\n${BLUE}[🔧] Checking APT sources...${NC}"
    log_action "Checking and enabling APT sources."

    local sources_changed=0
    # Enable contrib, non-free, and non-free-firmware
    for repo_type in "non-free-firmware" "contrib" "non-free"; do
        # Check if the line exists and is commented out
        if grep -q "^# deb.*$repo_type" /etc/apt/sources.list; then
            sudo sed -i "/^# deb.*$repo_type/ s/^# //" /etc/apt/sources.list
            sources_changed=1
            echo -e "${GREEN}[✔] Enabled $repo_type source.${NC}"
            log_action "Enabled $repo_type source."
        else
            # Check if the line exists and is already uncommented
            if grep -q "^deb.*$repo_type" /etc/apt/sources.list; then
                echo -e "${YELLOW}[i] $repo_type source already enabled.${NC}"
            else
                echo -e "${YELLOW}[i] $repo_type source not found in default format in sources.list. Skipping.${NC}"
            fi
        fi
    done

    if [[ "$sources_changed" -eq 1 ]]; then
        echo -e "${GREEN}[✔] APT sources updated. Running apt update...${NC}"
        progress_bar 20 # Simulate progress for apt update
        sudo apt update -y || { echo -e "${RED}[✖] Failed to run apt update. Check your network connection and sources.list.${NC}"; log_action "Failed apt update."; exit 1; }
        echo -e "${GREEN}[✔] APT repositories updated.${NC}"
        log_action "APT update completed."
    else
        echo -e "${YELLOW}[i] All required APT sources seem to be enabled or not present. Skipping apt update.${NC}"
    fi
}

# Driver Fix Functions
# These functions assume the hardware has already been detected.
fix_wifi() {
    echo -e "\n${BLUE}[🔧] Installing/Updating Wi-Fi drivers...${NC}"
    log_action "Attempting to fix Wi-Fi drivers."

    echo -e "${YELLOW}[i] Installing common Wi-Fi firmware packages (firmware-iwlwifi, firmware-realtek, firmware-atheros)...${NC}"
    progress_bar 30 # Simulate installation progress
    sudo apt install -y firmware-iwlwifi firmware-realtek firmware-atheros || { echo -e "${RED}[✖] Failed to install Wi-Fi firmware. Check logs for details.${NC}"; log_action "Failed to install Wi-Fi firmware."; return 1; }

    echo -e "${YELLOW}[i] Reloading iwlwifi module (if applicable) to apply changes...${NC}"
    if lsmod | grep -q iwlwifi; then
        sudo modprobe -r iwlwifi && sudo modprobe iwlwifi || { echo -e "${YELLOW}[!] Failed to reload iwlwifi. A reboot might be needed.${NC}"; log_action "Failed to reload iwlwifi."; }
    else
        echo -e "${YELLOW}[i] iwlwifi module not currently loaded or not applicable.${NC}"
    fi
    echo -e "${GREEN}[✔] Wi-Fi driver installation/update attempted. A reboot might be required.${NC}"
    log_action "Wi-Fi drivers installed/updated and modules reloaded."
}

fix_bluetooth() {
    echo -e "\n${BLUE}[🔧] Installing/Updating Bluetooth drivers and services...${NC}"
    log_action "Attempting to fix Bluetooth."

    echo -e "${YELLOW}[i] Installing bluez (Bluetooth protocol stack) and blueman (GUI manager)...${NC}"
    progress_bar 25 # Simulate installation progress
    sudo apt install -y bluez blueman || { echo -e "${RED}[✖] Failed to install Bluetooth packages. Check logs for details.${NC}"; log_action "Failed to install Bluetooth packages."; return 1; }

    echo -e "${YELLOW}[i] Ensuring Bluetooth service is enabled and started...${NC}"
    if systemctl is-active --quiet bluetooth.service; then
        echo -e "${YELLOW}[i] Bluetooth service already active. Restarting...${NC}"
        sudo systemctl restart bluetooth || { echo -e "${YELLOW}[!] Failed to restart Bluetooth service.${NC}"; log_action "Failed to restart Bluetooth service."; }
    else
        echo -e "${YELLOW}[i] Enabling and starting Bluetooth service...${NC}"
        sudo systemctl enable bluetooth && sudo systemctl start bluetooth || { echo -e "${RED}[✖] Failed to enable/start Bluetooth service. Check logs.${NC}"; log_action "Failed to enable/start Bluetooth service."; return 1; }
    fi
    echo -e "${GREEN}[✔] Bluetooth service enabled and started.${NC}"
    log_action "Bluetooth drivers/services installed/updated and started."
}

fix_audio() {
    echo -e "\n${BLUE}[🔧] Installing/Updating Audio drivers...${NC}"
    log_action "Attempting to fix audio drivers."

    echo -e "${YELLOW}[i] Installing pavucontrol (PulseAudio Volume Control), pulseaudio, and alsa-utils...${NC}"
    progress_bar 20 # Simulate installation progress
    sudo apt install -y pavucontrol pulseaudio alsa-utils || { echo -e "${RED}[✖] Failed to install audio packages. Check logs for details.${NC}"; log_action "Failed to install audio packages."; return 1; }

    echo -e "${YELLOW}[i] Restarting PulseAudio service for the current user to apply changes...${NC}"
    # Use 'pactl exit' to kill the PulseAudio daemon, which will then be restarted automatically
    # by the PulseAudio service unit for the user session. This is often more effective.
    pactl exit &> /dev/null || true # Ignore errors if pactl isn't running or something
    sleep 1 # Give a moment for the daemon to restart
    echo -e "${GREEN}[✔] Audio services refreshed (PulseAudio restarted).${NC}"
    log_action "Audio services refreshed."
}

fix_gpu() {
    echo -e "\n${BLUE}[🔧] Installing/Updating GPU drivers...${NC}"
    log_action "Attempting to fix GPU drivers."

    if $HAS_GPU_NVIDIA; then
        echo -e "${GREEN}[✔] NVIDIA GPU detected. Installing proprietary driver...${NC}"
        echo -e "${YELLOW}[i] Installing 'nvidia-driver' package (this might take a while and requires internet connection)...${NC}"
        progress_bar 60 # Simulate a longer installation
        sudo apt install -y nvidia-driver || { echo -e "${RED}[✖] Failed to install NVIDIA driver. Consult Debian documentation or NVIDIA's website for specific steps for your card/system.${NC}"; log_action "Failed to install NVIDIA driver."; return 1; }
        echo -e "${GREEN}[✔] NVIDIA driver installation initiated. A ${RED}REBOOT IS REQUIRED${NC} to apply changes fully.${NC}"
        log_action "NVIDIA driver installed. Reboot required."
    elif $HAS_GPU_AMD; then
        echo -e "${GREEN}[✔] AMD GPU detected. Installing firmware and open-source drivers...${NC}"
        echo -e "${YELLOW}[i] Installing 'firmware-amd-graphics', 'mesa-vulkan-drivers', and other common AMD packages...${NC}"
        progress_bar 30 # Simulate installation progress
        sudo apt install -y firmware-amd-graphics libglx-mesa0 mesa-vulkan-drivers xserver-xorg-video-amdgpu || { echo -e "${RED}[✖] Failed to install AMD graphics firmware/drivers. Check logs.${NC}"; log_action "Failed to install AMD graphics firmware/drivers."; return 1; }
        echo -e "${GREEN}[✔] AMD GPU firmware/drivers installed. A reboot is recommended.${NC}"
        log_action "AMD GPU firmware/drivers installed."
    elif $HAS_GPU_INTEL; then
        echo -e "${GREEN}[✔] Intel Integrated Graphics detected. Installing common Intel graphics packages...${NC}"
        echo -e "${YELLOW}[i] Installing 'i965-va-driver', 'intel-media-va-driver', 'mesa-va-drivers', 'mesa-vulkan-drivers'...${NC}"
        progress_bar 25 # Simulate installation progress
        sudo apt install -y i965-va-driver intel-media-va-driver mesa-va-drivers mesa-vulkan-drivers || { echo -e "${RED}[✖] Failed to install Intel graphics packages. Check logs.${NC}"; log_action "Failed to install Intel graphics packages."; return 1; }
        echo -e "${GREEN}[✔] Intel graphics packages installed. These usually work out-of-the-box.${NC}"
        log_action "Intel graphics packages installed."
    elif $HAS_GENERIC_GPU; then
        echo -e "${YELLOW}[!] Generic or unrecognized GPU detected. Ensuring common Mesa (open-source) packages are installed.${NC}"
        echo -e "${YELLOW}[i] Installing 'mesa-utils', 'libglx-mesa0', 'mesa-vulkan-drivers'...${NC}"
        sudo apt install -y mesa-utils libglx-mesa0 mesa-vulkan-drivers || { echo -e "${RED}[✖] Failed to install generic Mesa packages. Check logs.${NC}"; log_action "Failed to install generic Mesa packages."; }
        echo -e "${GREEN}[✔] Generic GPU support packages installed/updated.${NC}"
        log_action "Generic GPU, relying on default open-source drivers."
    else
        echo -e "${YELLOW}[!] No specific GPU type detected by the script. No GPU-specific drivers will be installed.${NC}"
        log_action "No specific GPU type detected for driver installation."
    fi
}

fix_usb() {
    echo -e "\n${BLUE}[🔧] Attempting to reset/reload USB controller modules...${NC}"
    log_action "Attempting to reset USB controllers."

    echo -e "${YELLOW}[i] Reloading xhci_pci kernel module (common for USB 3.x host controllers)...${NC}"
    # Unload and load xhci_pci module. This can sometimes resolve USB device issues.
    if lsmod | grep -q xhci_pci; then
        sudo modprobe -r xhci_pci && sudo modprobe xhci_pci || { echo -e "${YELLOW}[!] Failed to reload xhci_pci. Some USB devices might need re-plugging or a reboot.${NC}"; log_action "Failed to reload xhci_pci."; }
    else
        echo -e "${YELLOW}[i] xhci_pci module not currently loaded or not applicable.${NC}"
    fi

    echo -e "${YELLOW}[i] Reloading usb_storage kernel module (if external drives are having issues)...${NC}"
    if lsmod | grep -q usb_storage; then
        sudo modprobe -r usb_storage && sudo modprobe usb_storage || { echo -e "${YELLOW}[!] Failed to reload usb_storage.${NC}"; log_action "Failed to reload usb_storage."; }
    else
        echo -e "${YELLOW}[i] usb_storage module not currently loaded or not applicable.${NC}"
    fi

    echo -e "${GREEN}[✔] USB controller modules reloaded. Try re-plugging problematic USB devices.${NC}"
    log_action "USB controller modules reloaded."
}

# --- Main Script Execution ---

check_root
check_figlet
show_banner

# Initial system preparation: enable repos and update apt cache
echo -e "\n${MAGENTA}--- Initial System Preparation ---${NC}"
enable_repos
echo -e "\n${GREEN}[✔] Initial system preparation complete.${NC}"
log_action "Initial system preparation completed."

# Detect hardware before presenting options
detect_hardware

# Menu loop
while true; do
    echo -e "\n${BLUE}Select an option to install/repair/update drivers:${NC}"
    echo -e "${CYAN}1) Fix All Detected Devices (Recommended for new installs)${NC}"

    local menu_option_counter=2
    local menu_map=() # Array to map menu number to function name

    if $HAS_WIFI; then
        echo "${menu_option_counter}) Fix Only Wi-Fi Drivers"
        menu_map[${menu_option_counter}]="fix_wifi"
        ((menu_option_counter++))
    fi
    if $HAS_BLUETOOTH; then
        echo "${menu_option_counter}) Fix Only Bluetooth Drivers"
        menu_map[${menu_option_counter}]="fix_bluetooth"
        ((menu_option_counter++))
    fi
    if $HAS_AUDIO_DEVICE; then
        echo "${menu_option_counter}) Fix Only Audio Drivers"
        menu_map[${menu_option_counter}]="fix_audio"
        ((menu_option_counter++))
    fi
    if $HAS_GPU_NVIDIA || $HAS_GPU_AMD || $HAS_GPU_INTEL || $HAS_GENERIC_GPU; then
        echo "${menu_option_counter}) Fix Only GPU Drivers"
        menu_map[${menu_option_counter}]="fix_gpu"
        ((menu_option_counter++))
    fi
    if $HAS_USB_CONTROLLER; then
        echo "${menu_option_counter}) Fix Only USB Devices"
        menu_map[${menu_option_counter}]="fix_usb"
        ((menu_option_counter++))
    fi

    echo -e "${RED}${menu_option_counter}) Exit${NC}"
    menu_map[${menu_option_counter}]="exit_script" # Map exit option

    read -rp $'\nEnter your choice: ' choice

    if [[ "$choice" -eq 1 ]]; then
        echo -e "\n${YELLOW}You chose to 'Fix All Detected Devices'. This will attempt to install/fix drivers for all detected hardware.${NC}"
        read -rp $'\nAre you sure you want to proceed? (y/N): ' confirm_all
        if [[ "$confirm_all" =~ ^[Yy]$ ]]; then
            log_action "User chose to fix all detected devices."
            if $HAS_WIFI; then fix_wifi; fi
            if $HAS_BLUETOOTH; then fix_bluetooth; fi
            if $HAS_AUDIO_DEVICE; then fix_audio; fi
            if $HAS_GPU_NVIDIA || $HAS_GPU_AMD || $HAS_GPU_INTEL || $HAS_GENERIC_GPU; then fix_gpu; fi
            if $HAS_USB_CONTROLLER; then fix_usb; fi
            echo -e "\n${GREEN}All selected driver fixes attempted. A system reboot is highly recommended to ensure all changes take effect.${NC}"
            log_action "All detected device fixes completed."
        else
            echo -e "${YELLOW}[i] Operation cancelled.${NC}"
        fi
    elif [[ -n "${menu_map[$choice]}" ]]; then
        if [[ "${menu_map[$choice]}" == "exit_script" ]]; then
            echo -e "${GREEN}[✔] Exiting... Stay rooted, stay sharp. ⚔️${NC}"
            log_action "Script exited gracefully."
            exit 0
        else
            # Call the function mapped to the user's choice
            log_action "User chose to run: ${menu_map[$choice]}"
            "${menu_map[$choice]}"
            echo -e "\n${GREEN}Operation completed. A reboot is recommended for some changes to take full effect.${NC}"
        fi
    else
        echo -e "${RED}[!] Invalid option. Please enter a valid number from the menu.${NC}"
    fi
done
