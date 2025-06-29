#!/bin/sh

# Script variables
CONSOLE_FONT="ter-122b"
KEYBOARD_LAYOUT="la-latin1"
TIMEZONE="Etc/GMT+6"

#Define helper
usage() {
    [ -n "$1" ] && echo "$1" 1>&2
    echo "Usage: $0 -d </dev/DISK>" 1>&2
    exit 1
}

# Check arguments
while getopts ":d:" opt; do
    case $opt in
        'd') DISK="${OPTARG}" ;;
        *) usage ;;
    esac
done

# Exit if DISK is invalid
[ -z "$DISK" ] && usage "Error: Missing DISK device."
[ ! -b "$DISK" ] && usage "Error: DISK '$DISK' does not exist."
[ "$(lsblk -dno type "$DISK")" != "disk" ] && usage "Error: DISK '$DISK' is not disk type."

# https://wiki.archlinux.org/title/Installation_guide#Set_the_console_keyboard_layout_and_font
# Set console keyboard layout
loadkeys "$KEYBOARD_LAYOUT"
# Set console font
setfont "$CONSOLE_FONT"

# https://wiki.archlinux.org/title/Installation_guide#Update_the_system_clock
# Set time zone
timedatectl set-timezone "$TIMEZONE"
# Enable system clock synchronization via network
timedatectl set-ntp true

# Remove disk signatures
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
pacstrap -K /mnt base base-devel linux linux-firmware networkmanager terminus-font 2>&1 | tee -a /mnt/pacstrap.log

# https://wiki.archlinux.org/title/Installation_guide#Fstab
# Define disk partitions
genfstab -U /mnt >> /mnt/etc/fstab

# https://wiki.archlinux.org/title/Installation_guide#Time
# Set time zone
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /mnt/etc/localtime

# https://wiki.archlinux.org/title/Installation_guide#Localization
# Set console keyboard layout
echo "KEYMAP=$KEYBOARD_LAYOUT" > /mnt/etc/vconsole.conf
# Set console font
echo "FONT=$CONSOLE_FONT" >> /mnt/etc/vconsole.conf

# Download next script
curl -sS --output-dir /mnt -O https://raw.githubusercontent.com/RFCreate/arch-install/main/install.sh
chmod +x /mnt/install.sh
