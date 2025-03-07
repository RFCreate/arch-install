#!/bin/sh

# Script variables
CONSOLE_FONT="ter-122b"
KEYBOARD_LAYOUT="la-latin1"
TIMEZONE="Etc/GMT+6"

# Exit if DISK is empty
[ -z "$DISK" ] && echo "Error: Missing DISK device. export DISK=/dev/your_disk" >&2 && exit 1
[ ! -b "$DISK" ] && echo "Error: DISK does not exist. export DISK=/dev/your_disk" >&2 && exit 1
[ "$(lsblk -dno type "$DISK")" != "disk" ] && echo "Error: DISK is not disk type. export DISK=/dev/your_disk" >&2 && exit 1

# https://wiki.archlinux.org/title/Installation_guide#Set_the_console_keyboard_layout_and_font
# Set console keyboard layout
loadkeys "$KEYBOARD_LAYOUT"
# Set console font
setfont "$CONSOLE_FONT"

# https://wiki.archlinux.org/title/Installation_guide#Update_the_system_clock
# Set time zone
timedatectl set-timezone "$TIMEZONE"
# Activate system clock synchronization via network
timedatectl set-ntp true

# Remove partition signatures
echo "Removing disk signatures..."
wipefs --all -q "${DISK}" || exit 1

# https://wiki.archlinux.org/title/Installation_guide#Partition_the_disks
# Partition disk
echo "Partitioning disk..."
printf "size=+1G,type=L\nsize=+5G,type=L\nsize=+,type=L\n" | sfdisk -q "${DISK}" || exit 1

# https://wiki.archlinux.org/title/Installation_guide#Format_the_partitions
# Format root partition
echo "Formatting root partition..."
mkfs.ext4 -q -F "${DISK}3"
# Format boot partition
echo "Formatting boot partition..."
mkfs.fat -F 32 "${DISK}1"
# Format swap partition
echo "Formatting swap partition..."
mkswap -q "${DISK}2"

# https://wiki.archlinux.org/title/Installation_guide#Mount_the_file_systems
# Mount root volume
mount "${DISK}3" /mnt
# Mount boot partition
mount --mkdir "${DISK}1" /mnt/boot
# Enable swap partition
swapon "${DISK}2"

# https://wiki.archlinux.org/title/Installation_guide#Install_essential_packages
# Install packages in new system
echo "Installing packages to new system..."
pacstrap -K /mnt base base-devel linux linux-firmware linux-headers >> /mnt/pacstrap.log 2>&1

# https://wiki.archlinux.org/title/Installation_guide#Fstab
# Define disk partitions
genfstab -U /mnt >> /mnt/etc/fstab

# Download next script
curl -sS --output-dir /mnt -O https://raw.githubusercontent.com/RFCreate/setup/main/install.sh
chmod +x /mnt/install.sh
