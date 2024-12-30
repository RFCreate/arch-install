#!/bin/sh

# Check if mkfs commands exists
! command -v mkfs.fat > /dev/null 2>&1 && echo "Error: Dependency mkfs.fat command is not available" && return 1
! command -v mkfs.ext4 > /dev/null 2>&1 && echo "Error: Dependency mkfs.ext4 command is not available" && return 1

# Exit if USB is invalid
[ -z "$USB" ] && echo "Error: Missing USB device, use USB=/dev/your_usb" && return 1
[ ! -b "$USB" ] && echo "Error: USB does not exist, use USB=/dev/your_usb" && return 1
[ "$(lsblk -dno type "$USB")" != "disk" ] && echo "Error: USB is not disk type, use USB=/dev/your_usb" && return 1

# Exit if ISO is invalid
[ -z "$ISO" ] && echo "Error: Missing ISO file, use ISO=path/to/archlinux-version-x86_64.iso" && return 1
[ ! -f "$ISO" ] && echo "Error: ISO file does not exist, use ISO=path/to/archlinux-version-x86_64.iso" && return 1
! bsdtar -t -f "$ISO" > /dev/null 2>&1 && echo "Error: Unrecognized archive format, use ISO=path/to/archlinux-version-x86_64.iso" && return 1

# Get iso size and add 1GB of safe space
iso_size="$(numfmt --to=iec $(($(wc -c < "$ISO") + 100000000)))"

# Remove partition signatures
echo "Removing disk signatures..."
wipefs --all -q "${USB}" || ! echo "Error ocurred!" || return 1

# Partition usb
echo "Partitioning disk..."
printf "size=+%s,type=L,bootable,\nsize=+,type=L\n" "$iso_size" | sfdisk -q "${USB}" || ! echo "Error ocurred!" || return 1

############ ISO ############

# Format iso partition
echo "Formatting iso partition..."
mkfs.fat -F 32 "${USB}1"

# Mount iso partition
mount "${USB}1" /mnt

# Extract iso image to iso partition
echo "Copying ISO to USB..."
bsdtar -x -f "${ISO}" -C /mnt

# Umount iso partition
umount /mnt

########## STORAGE ##########

# Format storage partition
echo "Formatting storage partition..."
mkfs.ext4 -q -F "${USB}2"

# Mount storage partition
mount "${USB}2" /mnt

# Add script to storage partition
echo "Adding preinstall script to USB..."
curl -s --output-dir /mnt -O https://raw.githubusercontent.com/RFCreate/setup/main/preinstall.sh

# Umount storage partition
umount /mnt
