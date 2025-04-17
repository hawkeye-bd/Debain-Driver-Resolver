#!/bin/bash

#===============================================
#  Debain-Driver Resolver 0.1 by Hawkeye (Team Hawkeye)
#===============================================

# CLI Banner
clear
echo -e "\e[1;36m"
figlet -c "Debain-Driver Resolver 0.1"
echo -e "\e[0m"
echo -e "                by Hawkeye (Team Hawkeye)\n"

sleep 1

# Function to check if a package is installed
is_installed() {
    dpkg -l | grep -qw "$1"
}

# Function to print progress bar
progress_bar() {
    local duration=${1}
    already_done() { for ((done=0; done<$elapsed; done++)); do printf "#"; done }
    remaining() { for ((remain=$elapsed; remain<$duration; remain++)); do printf "-"; done }
    percentage() { printf "| %s%%" $(( ($elapsed*100)/$duration )); }
    for (( elapsed=1; elapsed<=$duration; elapsed++ )); do
        printf "\r["; already_done; remaining; percentage
        sleep 0.1
    done
    printf "]\n"
}

#================ DETECTION =====================
echo "\n[+] Detecting Devices..."
sleep 1

# GPU
GPU=$(lspci | grep -i vga)
echo -e "\n\e[1;32m[GPU]:\e[0m $GPU"

# WIFI
WIFI=$(lspci | grep -i network)
echo -e "\e[1;32m[Wi-Fi]:\e[0m $WIFI"

# Bluetooth
BT=$(lsusb | grep -i bluetooth)
echo -e "\e[1;32m[Bluetooth]:\e[0m ${BT:-Not Detected}"

# Audio
AUDIO=$(lspci | grep -i audio)
echo -e "\e[1;32m[Audio]:\e[0m $AUDIO"

# USB
USB=$(lsusb)
echo -e "\e[1;32m[USB Devices]:\e[0m\n$USB"

#================ OPTIONS =====================
echo -e "\n\e[1;34mSelect an option:\e[0m"
echo "1. Fix All Devices"
echo "2. Fix Only Wi-Fi"
echo "3. Fix Only Bluetooth"
echo "4. Fix Only Audio"
echo "5. Fix Only GPU Drivers"
echo "6. Exit"
read -p $'\nYour choice: ' choice

#================ FIX LOGIC =====================
echo "\n[+] Working on it..."
progress_bar 30

fix_wifi() {
    echo "[✓] Installing Wi-Fi drivers..."
    sudo apt install firmware-iwlwifi firmware-atheros firmware-brcm80211 firmware-realtek -y
    sudo modprobe -r iwlwifi && sudo modprobe iwlwifi
    echo "[✓] Wi-Fi fixed."
}

fix_bluetooth() {
    echo "[✓] Installing Bluetooth drivers..."
    sudo apt install bluez blueman -y
    sudo systemctl enable bluetooth && sudo systemctl start bluetooth
    echo "[✓] Bluetooth service restarted."
}

fix_audio() {
    echo "[✓] Installing Audio fixes..."
    sudo apt install pavucontrol pulseaudio -y
    sudo systemctl --user restart pulseaudio
    echo "[✓] Audio service restarted."
}

fix_gpu() {
    echo "[✓] Installing firmware and checking GPU drivers..."
    sudo apt install firmware-misc-nonfree -y
    echo "[i] Use proprietary driver installer for NVIDIA or AMD if needed."
}

case $choice in
    1)
        fix_wifi
        fix_bluetooth
        fix_audio
        fix_gpu
        ;;
    2)
        fix_wifi
        ;;
    3)
        fix_bluetooth
        ;;
    4)
        fix_audio
        ;;
    5)
        fix_gpu
        ;;
    *)
        echo "[-] Exiting..."
        exit 0
        ;;
esac

echo -e "\n\e[1;32m[✔] All selected fixes completed. You may now reboot.\e[0m"
echo -e "\n~ Team Hawkeye out. Stay rooted, stay sharp. ⚔️"
