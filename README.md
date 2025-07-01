# 🛠️ Debian-Driver Resolver 0.3
### Created by **Hawkeye** (Team Hawkeye)
The ultimate driver fixer for Kali & Debian-based systems.

---
> _"Why troubleshoot drivers manually when you can fix them like a hacker?"_

---

## ⚡ What It Does

`debian-driver-resolver.sh` intelligently detects and fixes common driver issues for:

-   ✅ **GPU** (NVIDIA, AMD, Intel integrated, and other generic GPUs)
-   ✅ **Wi-Fi** (Supports Intel, Atheros, Realtek, Broadcom chipsets via common firmware)
-   ✅ **Bluetooth** (For both USB and onboard chipsets)
-   ✅ **Audio** (Ensures PulseAudio and ALSA utilities are correctly configured)
-   ✅ **USB & Peripheral Devices** (Resets USB controllers to resolve connectivity issues)
-   ✅ Works seamlessly on **Kali Linux, Debian**, and most Debian-based distributions.

---

## 🧠 Features

-   **Comprehensive Hardware Detection:** Automatically scans your system to identify installed Wi-Fi, Bluetooth, Audio, GPU, and USB hardware.
-   **Dynamic CLI UI:** Clean, colored command-line interface with an animated progress bar for visual feedback.
-   **Intelligent Menu:** Presents a menu tailored to your detected hardware, showing only relevant fix options.
-   **Flexible Fix Options:** Choose to "Fix All Detected Devices" for a comprehensive solution or select individual components.
-   **Safe & Non-Destructive:** Designed to install missing firmware and services without breaking existing configurations.
-   **Automatic Repository Setup:** Ensures `contrib`, `non-free`, and `non-free-firmware` APT sources are enabled for full driver access.
-   **Fully Offline Executable:** Once dependencies are installed, the core script can run without an internet connection (though initial `apt update` and package installations require it).

---

## 🚀 How to Use & Workflow

### 🟢 Run Directly (1-liner):

For a quick start, copy and paste this command into your terminal:

```bash
curl -s [https://raw.githubusercontent.com/sadmanadib33/Debian-Driver-Resolver/main/debian-driver-resolver.sh](https://raw.githubusercontent.com/sadmanadib33/Debian-Driver-Resolver/main/debian-driver-resolver.sh) | sudo bash
```
*Note: The `sudo` is crucial as the script requires root privileges for system modifications.*

### 🛠️ Or Clone Manually:

For more control and to inspect the code, clone the repository:

```bash
git clone [https://github.com/sadmanadib33/Debian-Driver-Resolver.git](https://github.com/sadmanadib33/Debian-Driver-Resolver.git)
cd Debian-Driver-Resolver
chmod +x debian-driver-resolver.sh
sudo ./debian-driver-resolver.sh
```

### Script Workflow & Steps:

Once you run the script, here's what you'll experience:

1.  **Banner Display:** A stylish ASCII banner (if `figlet` is installed, otherwise a simple text banner) will greet you.
2.  **Initial System Preparation:**
    * The script checks for and enables `contrib`, `non-free`, and `non-free-firmware` repositories in your `/etc/apt/sources.list`.
    * It then runs `sudo apt update` to refresh your package lists, ensuring access to the latest drivers and firmware.
3.  **Hardware Detection:**
    * The script intelligently scans your system for connected devices: Wi-Fi adapters, Bluetooth modules, Audio devices, GPU (NVIDIA, AMD, Intel, or generic), and USB controllers.
    * It will print a summary of detected hardware, letting you know what it found.
4.  **Dynamic Menu Presentation:**
    * Based on the detected hardware, a personalized menu will be presented. You'll only see options relevant to the devices found on your system (e.g., if no Bluetooth is found, the "Fix Bluetooth" option won't appear).
    * An option to "Fix All Detected Devices" is always available for a comprehensive fix.
5.  **Driver Installation/Repair:**
    * Select your desired option (e.g., "Fix Only Wi-Fi Drivers" or "Fix All Detected Devices").
    * The script will proceed to install necessary firmware and packages using `apt`.
    * You'll see a progress bar and clear messages indicating the status of each operation.
    * For some fixes (like Wi-Fi module reloading or PulseAudio restart), the script attempts to apply changes immediately.
6.  **Reboot Recommendation:**
    * After significant driver changes (especially for GPU drivers), the script will strongly recommend a system reboot to ensure all modifications take full effect.
7.  **Exit:** Choose the "Exit" option to gracefully close the script.

---

## 💳 Donate to Support Development

If this helped you, help keep it alive:

**USDT (TRC-20):**
`TVJh6kjKgxBFX2KY1v1hC9UoSwD1SPX5ok`

**BTC:**
`bc1q5hmr09g84gaw7us6lw64fj9mfxzwhp47v9lyfx`

Every satoshi keeps the rebellion going ⚔️

---

## 📢 Version

**Debian-Driver Resolver v0.3**
Developed by Sadman Adib aka Hawkeye

🔗 [Telegram](https://t.me/SadmanAdib)

---

## 🛡️ License

Licensed under the MIT License

---

## 🔥 Team Hawkeye says:

"Fix drivers. Wreck bugs. Stay rooted. Stay sharp."
