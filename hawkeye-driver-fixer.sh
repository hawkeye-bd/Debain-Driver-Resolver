#!/bin/bash

#===========================================================
#  Debain-Driver Resolver 0.1 by Hawkeye (Team Hawkeye)
#===========================================================

# Show Banner
clear
figlet -c "Debain-Driver Resolver 0.1"
echo -e "\e[1;36m                by Hawkeye (Team Hawkeye)\e[0m\n"

# Ensure all needed APT sources are enabled
enable_repos() {
    echo -e "\n[🔧] Checking APT sources..."
    sudo sed -i '/^# deb.*non-free-firmware/ s/^# //' /etc/apt/sources.list
    sudo sed -i '/^# deb.*contrib/ s/^# //' /etc/apt/sources.list
    sudo sed -i '/^# deb.*non-free/ s/^# //' /etc/apt/sources.list
    echo "[✔] Enabling contrib, non-free, and non-free-firmware sources."
    sudo apt update
}

# Helper: Check if a package is installed
is_installed() {
    dpkg -l | grep -qw "$1"
}

# Progress bar function
progress_bar() {
    local duration=$1
    echo -n "["
    for ((i = 0; i <= duration; i++)); do
        printf "#"
        sleep 0.05
    done
    echo "]"
}

# Driver Fix Functions
fix_wifi() {
    echo -e "\n[🔧] Checking for Wi-Fi support..."
    if lspci | grep -i network; then
        echo "[✔] Wi-Fi device found."
        sudo apt install firmware-iwlwifi firmware-realtek firmware-atheros -y
        sudo modprobe -r iwlwifi && sudo modprobe iwlwifi
        echo "[✔] Wi-Fi drivers installed and reloaded."
    else
        echo "[✖] No Wi-Fi adapter detected."
    fi
}

fix_bluetooth() {
    echo -e "\n[🔧] Checking Bluetooth setup..."
    if lsusb | grep -i bluetooth || lsusb | grep -i "Intel Corp."; then
        sudo apt install bluez blueman -y
        sudo systemctl enable bluetooth
        sudo systemctl restart bluetooth
        echo "[✔] Bluetooth service started."
    else
        echo "[✖] No Bluetooth device detected."
    fi
}

fix_audio() {
    echo -e "\n[🔧] Fixing audio drivers..."
    sudo apt install pavucontrol pulseaudio alsa-utils -y
    sudo systemctl --user restart pulseaudio
    echo "[✔] Audio services refreshed."
}

fix_gpu() {
    echo -e "\n[🔧] Checking GPU support..."
    GPU=$(lspci | grep -i vga)
    echo "[i] Detected GPU: $GPU"
    if echo "$GPU" | grep -i nvidia; then
        echo "[✔] NVIDIA detected. Installing driver..."
        sudo apt install nvidia-driver -y
        echo "[i] Reboot required to apply changes."
    elif echo "$GPU" | grep -i amd; then
        echo "[✔] AMD GPU detected. Installing firmware..."
        sudo apt install firmware-amd-graphics -y
    else
        echo "[!] Using default open-source GPU driver."
    fi
}

fix_usb() {
    echo -e "\n[🔧] Reloading USB kernel modules..."
    sudo modprobe -r xhci_pci && sudo modprobe xhci_pci
    echo "[✔] USB controller reset."
}

# First, enable needed sources
enable_repos

# Menu loop
while true; do
    echo -e "\n\e[1;34mSelect an option to fix:\e[0m"
    echo "1) Fix All Devices"
    echo "2) Fix Only Wi-Fi"
    echo "3) Fix Only Bluetooth"
    echo "4) Fix Only GPU"
    echo "5) Fix Only Audio"
    echo "6) Fix USB Devices"
    echo "7) Exit"

    read -rp $'\nEnter your choice [1-7]: ' choice

    case "$choice" in
        1)
            fix_wifi
            fix_bluetooth
            fix_audio
            fix_gpu
            fix_usb
            ;;
        2)
            fix_wifi
            ;;
        3)
            fix_bluetooth
            ;;
        4)
            fix_gpu
            ;;
        5)
            fix_audio
            ;;
        6)
            fix_usb
            ;;
        7)
            echo "[✔] Exiting... Stay rooted, stay sharp. ⚔️"
            exit 0
            ;;
        *)
            echo "[!] Invalid option. Try again."
            ;;
    esac

done
