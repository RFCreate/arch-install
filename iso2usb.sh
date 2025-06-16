#!/bin/sh

# Check if formatter commands exists
command -v mkfs.fat > /dev/null 2>&1 || ! echo "Error: Dependency mkfs.fat not found" >&2 || exit 1

#Define helper
usage() {
    [ -n "$1" ] && echo "$1" 1>&2
    echo "Usage: $0 -d </dev/USB> -i </path/to/ISO>" 1>&2
    exit 1
}

# Check arguments
while getopts ":d:i:" opt; do
    case $opt in
        'd') USB="${OPTARG}" ;;
        'i') ISO="${OPTARG}" ;;
        *) usage ;;
    esac
done

# Exit if USB is invalid
[ -z "$USB" ] && usage "Error: Missing USB device."
[ ! -b "$USB" ] && usage "Error: USB '$USB' does not exist."
[ "$(lsblk -dno type "$USB")" != "disk" ] && usage "Error: USB '$USB' is not disk type."

# Exit if ISO is invalid
[ -z "$ISO" ] && usage "Error: Missing ISO file."
[ ! -f "$ISO" ] && usage "Error: ISO '$ISO' file does not exist."
bsdtar -Otf "$ISO" 2> /dev/null || usage "Error: ISO '$ISO' archive format."

# Remove USB signatures
echo "Removing USB signatures..."
wipefs --all -q "${USB}" || exit 1

# Partition USB
echo "Partitioning USB..."
printf "size=+,bootable,type=L\n" | sfdisk -q "${USB}" || exit 1

# Format USB
echo "Formatting USB..."
mkfs.fat -F 32 "${USB}1" || exit 1

# Mount USB
mountDIR="$(mktemp -d)"
mount "${USB}1" "$mountDIR" || exit 1

# Extract ISO to USB
echo "Copying ISO to USB..."
bsdtar -x -f "${ISO}" -C "$mountDIR"

# Download script to USB
echo "Copying script to USB..."
curl -sS --output-dir "$mountDIR" -O https://raw.githubusercontent.com/RFCreate/arch-install/main/preinstall.sh
chmod +x "$mountDIR/preinstall.sh"

# Unmount USB
umount "$mountDIR"
