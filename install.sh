#!/bin/sh

# https://wiki.archlinux.org/title/Installation_guide#Time
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

# https://wiki.archlinux.org/title/Installation_guide#Network_configuration
# Set hostname for network
echo arch > /etc/hostname

# https://wiki.archlinux.org/title/Installation_guide#Boot_loader
if [ -f /sys/firmware/efi/fw_platform_size ]; then
    pacman -S --needed --noconfirm grub efibootmgr 2>&1 | tee -a /pacman.log
    # https://wiki.archlinux.org/title/Installation_guide#Verify_the_boot_mode
    case "$(cat /sys/firmware/efi/fw_platform_size)" in
        # https://wiki.archlinux.org/title/GRUB#Installation
        64) grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB ;;
        32) grub-install --target=i386-efi --efi-directory=/boot --bootloader-id=GRUB ;;
    esac
else
    # https://wiki.archlinux.org/title/GRUB#Installation_2
    pacman -S --needed --noconfirm grub 2>&1 | tee -a /pacman.log
    cd / && grub-install --target=i386-pc "$(findmnt --output source --noheadings --target . | sed 's/[0-9]*$//')"
fi
# Set time for grub menu
sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=5/' /etc/default/grub
# https://wiki.archlinux.org/title/GRUB#Generate_the_main_configuration_file
grub-mkconfig -o /boot/grub/grub.cfg

# https://wiki.archlinux.org/title/Microcode
# Install processor microcode update
grep -q AuthenticAMD /proc/cpuinfo && pacman -S --needed --noconfirm amd-ucode 2>&1 | tee -a /pacman.log
grep -q GenuineIntel /proc/cpuinfo && pacman -S --needed --noconfirm intel-ucode 2>&1 | tee -a /pacman.log

# https://wiki.archlinux.org/title/Broadcom_wireless#Driver_selection
# Install Broadcom drivers if needed
lspci -d 14e4: > /dev/null 2>&1 && pacman -S --needed --noconfirm broadcom-wl 2>&1 | tee -a /pacman.log

# Download next script
curl -sS --output-dir / -O https://raw.githubusercontent.com/RFCreate/arch-install/main/setup.sh
chmod +x /setup.sh
