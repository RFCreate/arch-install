#!/bin/sh

# Script variables
# (if you replace them in preinstall.sh it will reflect here automatically)
FONT_PACKAGE="terminus-font"
CONSOLE_FONT="ter-122b"
KEYBOARD_MAP="la-latin1"
TIMEZONE="Etc/GMT+6"

# Helper function to install packages with logging
pacman_install() {
    pacman -S --needed --noconfirm "$@" 2>&1 | tee -a /pacman.log
}

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
echo "KEYMAP=$KEYBOARD_MAP" > /etc/vconsole.conf

# https://wiki.archlinux.org/title/Linux_console#Persistent_configuration
# Iinstall console font
pacman_install "$FONT_PACKAGE"
# Set console font
echo "FONT=$CONSOLE_FONT" >> /etc/vconsole.conf

# https://wiki.archlinux.org/title/Installation_guide#Network_configuration
# Set hostname for network
echo arch > /etc/hostname
# Install and enable network manager
pacman_install networkmanager network-manager-applet
systemctl --quiet enable NetworkManager.service

# https://wiki.archlinux.org/title/Installation_guide#Boot_loader
if [ -f /sys/firmware/efi/fw_platform_size ]; then
    pacman_install grub efibootmgr
    # https://wiki.archlinux.org/title/Installation_guide#Verify_the_boot_mode
    case "$(cat /sys/firmware/efi/fw_platform_size)" in
        # https://wiki.archlinux.org/title/GRUB#Installation
        64) grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB ;;
        32) grub-install --target=i386-efi --efi-directory=/boot --bootloader-id=GRUB ;;
    esac
else
    # https://wiki.archlinux.org/title/GRUB#Installation_2
    pacman_install grub
    cd / && grub-install --target=i386-pc "$(findmnt --output source --noheadings --target . | sed 's/[0-9]*$//')"
fi
# Set time for grub menu
sed -i 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=10/' /etc/default/grub
# https://wiki.archlinux.org/title/GRUB#Generate_the_main_configuration_file
grub-mkconfig -o /boot/grub/grub.cfg

# https://wiki.archlinux.org/title/Microcode
# Install processor microcode update
grep -q AuthenticAMD /proc/cpuinfo && pacman_install amd-ucode
grep -q GenuineIntel /proc/cpuinfo && pacman_install intel-ucode

# https://wiki.archlinux.org/title/Broadcom_wireless#Driver_selection
# Install Broadcom drivers if needed
[ -n "$(lspci -d 14e4:)" ] && pacman_install broadcom-wl

# https://wiki.archlinux.org/title/PC_speaker#Globally
# Remove beep sound
lsmod | grep -wq pcspkr && rmmod pcspkr
lsmod | grep -wq snd_pcsp && rmmod snd_pcsp
echo 'blacklist pcspkr' > /etc/modprobe.d/nobeep.conf
echo 'blacklist snd_pcsp' >> /etc/modprobe.d/nobeep.conf

# https://wiki.archlinux.org/title/Power_management#ACPI_events
# Ignore power/suspend/reboot/hibernate buttons
sed -i 's/^#*HandlePowerKey=.*/HandlePowerKey=ignore/' /etc/systemd/logind.conf
sed -i 's/^#*HandleRebootKey=.*/HandleRebootKey=ignore/' /etc/systemd/logind.conf
sed -i 's/^#*HandleSuspendKey=.*/HandleSuspendKey=ignore/' /etc/systemd/logind.conf
sed -i 's/^#*HandleHibernateKey=.*/HandleHibernateKey=ignore/' /etc/systemd/logind.conf

# Download next script
curl -fsSLO --output-dir / https://raw.githubusercontent.com/RFCreate/arch-install/main/postinstall.sh
chmod +x /postinstall.sh
