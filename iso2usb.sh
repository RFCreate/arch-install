#!/bin/sh

# Check if mkfs commands exists
command -v mkfs.fat > /dev/null 2>&1 || ! echo "Error: Dependency mkfs.fat not found" >&2 || exit 1
command -v mkfs.ext4 > /dev/null 2>&1 || ! echo "Error: Dependency mkfs.ext4 not found" >&2 || exit 1

#Define helper
usage() {
    echo "Usage: $0 -d </dev/USB> -i </path/to/ISO>" 1>&2
    exit 1
}

# Check arguments
while getopts ":d:i:" opt; do
    case $opt in
        d) USB="${OPTARG}" ;;
        i) ISO="${OPTARG}" ;;
        *) usage ;;
    esac
done

# Exit if USB is invalid
[ -z "$USB" ] && echo "Error: Missing USB device." >&2 && usage
[ ! -b "$USB" ] && echo "Error: USB '$USB' does not exist." >&2 && usage
[ "$(lsblk -dno type "$USB")" != "disk" ] && echo "Error: USB '$USB' is not disk type." >&2 && usage

# Exit if ISO is invalid
[ -z "$ISO" ] && echo "Error: Missing ISO file." >&2 && usage
[ ! -f "$ISO" ] && echo "Error: ISO '$ISO' file does not exist." >&2 && usage
! bsdtar -Otf "$ISO" 2> /dev/null && echo "Error: ISO '$ISO' archive format." >&2 && usage

############ USB ############

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
mount "${USB}1" "$isoDIR" || exit 1

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
mount "${USB}2" "$storageDIR" || exit 1

# Download next script
echo "Copying script to USB..."
curl -sS --output-dir "$storageDIR" -O https://raw.githubusercontent.com/RFCreate/setup/main/preinstall.sh
chmod +x "$storageDIR/preinstall.sh"

# Unmount storage partition
umount "$storageDIR"
