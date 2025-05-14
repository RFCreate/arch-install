#!/bin/sh

# Script variables
CONSOLE_FONT="ter-122b"
KEYBOARD_LAYOUT="la-latin1"
TIMEZONE="Etc/GMT+6"

# https://wiki.archlinux.org/title/Installation_guide#Time
# Set time zone
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
# Set hardware clock
hwclock --systohc
# Enable system clock synchronization via network
systemctl --quiet enable systemd-timesyncd.service

# https://wiki.archlinux.org/title/Installation_guide#Localization
# Generate locales
sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
# Set the LANG variable
echo "LANG=en_US.UTF-8" > /etc/locale.conf
# Set console keyboard layout
echo "KEYMAP=$KEYBOARD_LAYOUT" > /etc/vconsole.conf
# Set console font
echo "FONT=$CONSOLE_FONT" >> /etc/vconsole.conf

# https://wiki.archlinux.org/title/Installation_guide#Network_configuration
# Set hostname for network
echo arch > /etc/hostname

# https://wiki.archlinux.org/title/Installation_guide#Boot_loader
if [ -f /sys/firmware/efi/fw_platform_size ]; then
    pacman -S --needed --noconfirm grub efibootmgr >> /pacman.log 2>&1
    # https://wiki.archlinux.org/title/Installation_guide#Verify_the_boot_mode
    case "$(cat /sys/firmware/efi/fw_platform_size)" in
        # https://wiki.archlinux.org/title/GRUB#Installation
        64) grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB ;;
        32) grub-install --target=i386-efi --efi-directory=/boot --bootloader-id=GRUB ;;
    esac
else
    # https://wiki.archlinux.org/title/GRUB#Installation_2
    pacman -S --needed --noconfirm grub >> /pacman.log 2>&1
    cd / && grub-install --target=i386-pc "$(findmnt --output source --noheadings --target . | sed 's/[0-9]*$//')"
fi
# Set time for grub menu
sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/' /etc/default/grub
# https://wiki.archlinux.org/title/GRUB#Generate_the_main_configuration_file
grub-mkconfig -o /boot/grub/grub.cfg

# https://wiki.archlinux.org/title/Microcode
# Install processor microcode update
grep -q AuthenticAMD /proc/cpuinfo && pacman -S --needed --noconfirm amd-ucode >> /pacman.log 2>&1
grep -q GenuineIntel /proc/cpuinfo && pacman -S --needed --noconfirm intel-ucode >> /pacman.log 2>&1

# https://wiki.archlinux.org/title/NetworkManager#Installation
# Add network manager
pacman -S --needed --noconfirm networkmanager >> /pacman.log 2>&1
# https://wiki.archlinux.org/title/NetworkManager#Enable_NetworkManager
# Enable network manager
systemctl --quiet enable NetworkManager.service

# https://wiki.archlinux.org/title/Broadcom_wireless#Driver_selection
# Install Broadcom drivers if needed
[ -n "$(lspci -d 14e4: 2> /dev/null)" ] && pacman -S --needed --noconfirm broadcom-wl-dkms >> /pacman.log 2>&1

# Download next script
curl -sS --output-dir / -O https://raw.githubusercontent.com/RFCreate/arch-install/main/setup.sh
chmod +x /setup.sh
