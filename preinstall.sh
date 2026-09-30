#!/bin/sh

# Script variables
FONT_PACKAGE="terminus-font"
CONSOLE_FONT="ter-122b"
KEYBOARD_MAP="la-latin1"
TIMEZONE="Etc/GMT+6"

# Define helper
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

# Use partition prefix if disk ends in digit
case "$DISK" in
    *[0-9]) PARTITION="${DISK}p" ;;
    *) PARTITION="$DISK" ;;
esac

# https://wiki.archlinux.org/title/Installation_guide#Set_the_console_keyboard_layout_and_font
# Set console keyboard layout
loadkeys "$KEYBOARD_MAP"
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
ENCRYPT_NAME="cryptroot"
ENCRYPT_DEVICE="/dev/mapper/cryptroot"
printf "root-password" | cryptsetup luksFormat -q -d - "${PARTITION}3" || exit 1
printf "root-password" | cryptsetup open -d - "${PARTITION}3" "$ENCRYPT_NAME" || exit 1
mkfs.ext4 -q -F "$ENCRYPT_DEVICE" || exit 1
# Format boot partition
echo "Formatting boot partition..."
mkfs.fat -F 32 "${PARTITION}1" || exit 1
# Format swap partition
echo "Formatting swap partition..."
mkswap -q "${PARTITION}2" || exit 1

# https://wiki.archlinux.org/title/Installation_guide#Mount_the_file_systems
# Mount root volume
mount "$ENCRYPT_DEVICE" /mnt || exit 1
# Mount boot partition
mount --mkdir "${PARTITION}1" /mnt/boot || exit 1
# Enable swap partition
swapon "${PARTITION}2" || exit 1

# https://wiki.archlinux.org/title/Installation_guide#Install_essential_packages
# Install packages in new system
echo "Installing packages to new system..."
pacstrap -K /mnt base base-devel linux linux-firmware cryptsetup 2>&1 | tee -a /mnt/pacstrap.log

# https://wiki.archlinux.org/title/Installation_guide#Fstab
# Define disk partitions
genfstab -U /mnt >> /mnt/etc/fstab

# Save UUID of the encrypted root partition
blkid "${PARTITION}3" -o value -s UUID > /mnt/cryptroot-uuid.txt

# Download next script
curl -fsSLO --output-dir /mnt https://raw.githubusercontent.com/RFCreate/arch-install/main/install.sh
chmod +x /mnt/install.sh
sed -i "s/^FONT_PACKAGE=.*/FONT_PACKAGE=\"$FONT_PACKAGE\"/" /mnt/install.sh
sed -i "s/^CONSOLE_FONT=.*/CONSOLE_FONT=\"$CONSOLE_FONT\"/" /mnt/install.sh
sed -i "s/^KEYBOARD_MAP=.*/KEYBOARD_MAP=\"$KEYBOARD_MAP\"/" /mnt/install.sh
sed -i "s/^TIMEZONE=.*/TIMEZONE=\"$TIMEZONE\"/" /mnt/install.sh
