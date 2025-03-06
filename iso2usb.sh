#!/bin/sh

# Check if mkfs commands exists
command -v mkfs.fat > /dev/null 2>&1 || ! echo "Error: Dependency mkfs.fat not found" >&2 || exit 1
command -v mkfs.ext4 > /dev/null 2>&1 || ! echo "Error: Dependency mkfs.ext4 not found" >&2 || exit 1

# Exit if USB is invalid
[ -z "$USB" ] && echo "Error: Missing USB device. export USB=/dev/your_usb" >&2 && exit 1
[ ! -b "$USB" ] && echo "Error: USB does not exist. export USB=/dev/your_usb" >&2 && exit 1
[ "$(lsblk -dno type "$USB")" != "disk" ] && echo "Error: USB is not disk type. export USB=/dev/your_usb" >&2 && exit 1

# Exit if ISO is invalid
[ -z "$ISO" ] && echo "Error: Missing ISO file. export ISO=/path/to/archlinux.iso" >&2 && exit 1
[ ! -f "$ISO" ] && echo "Error: ISO file does not exist. export ISO=/path/to/archlinux.iso" >&2 && exit 1
! bsdtar -Otf "$ISO" 2> /dev/null && echo "Error: Unrecognized archive format. export ISO=/path/to/archlinux.iso" >&2 && exit 1

# Remove partition signatures
echo "Removing disk signatures..."
wipefs --all -q "${USB}" || exit 1

# Partition usb
echo "Partitioning disk..."
printf "size=+2G,type=L,bootable,\nsize=+,type=L\n" | sfdisk -q "${USB}" || exit 1

############ ISO ############

# Format iso partition
echo "Formatting iso partition..."
mkfs.fat -F 32 "${USB}1"

# Mount iso partition
isoDIR="$(mktemp -d)"
mount "${USB}1" "$isoDIR"

# Extract iso image to iso partition
echo "Copying ISO to USB..."
bsdtar -x -f "${ISO}" -C "$isoDIR"

# Unmount iso partition
umount "$isoDIR"

########## STORAGE ##########

# Format storage partition
echo "Formatting storage partition..."
mkfs.ext4 -q -F "${USB}2"

# Mount storage partition
storageDIR="$(mktemp -d)"
mount "${USB}2" "$storageDIR"

# Download next script
echo "Copying script to USB..."
curl -sS --output-dir "$storageDIR" -O https://raw.githubusercontent.com/RFCreate/setup/main/preinstall.sh
chmod +x "$storageDIR/preinstall.sh"

# Unmount storage partition
umount "$storageDIR"
