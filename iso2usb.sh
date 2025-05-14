#!/bin/sh

# Check if formatter commands exists
command -v mkfs.fat > /dev/null 2>&1 || ! echo "Error: Dependency mkfs.fat not found" >&2 || exit 1

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

# Format USB
echo "Formatting USB..."
mkfs.fat -F 32 "$USB" || exit 1

# Mount USB
mountDIR="$(mktemp -d)"
mount "$USB" "$mountDIR" || exit 1

# Extract iso image to USB
echo "Copying ISO to USB..."
bsdtar -x -f "${ISO}" -C "$mountDIR"

# Download script to USB
echo "Copying script to USB..."
curl -sS --output-dir "$mountDIR" -O https://raw.githubusercontent.com/RFCreate/arch-install/main/preinstall.sh
chmod +x "$mountDIR/preinstall.sh"

# Unmount USB
umount "$mountDIR"
