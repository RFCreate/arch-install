# Arch Installation

Follow the [installation guide](https://wiki.archlinux.org/title/Installation_guide#Pre-installation) in the Arch wiki to download the [ISO](https://wiki.archlinux.org/title/Installation_guide#Acquire_an_installation_image) and [verify the signature](https://wiki.archlinux.org/title/Installation_guide#Verify_signature)

---

Run the iso2usb script[^1] to copy the [ISO to a **USB**](https://wiki.archlinux.org/title/USB_flash_installation_medium#Using_manual_formatting)<br>
<sub>**Note:** fill the USB and ISO variables for the script to run, mkfs.fat and mkfs.ext4 need to be installed, and additional commands are needed for [not UEFI systems](https://wiki.archlinux.org/title/USB_flash_installation_medium#Using_manual_formatting)</sub>

```
curl -O https://raw.githubusercontent.com/shyguyCreate/setup/main/iso2usb.sh
USB=/dev/your_usb
ISO=path/to/archlinux-version-x86_64.iso
. ./iso2usb.sh
```

When finished, [boot into the USB](https://wiki.archlinux.org/title/Installation_guide#Boot_the_live_environment)

---

Inside the bootable USB, connect to [wireless internet](https://wiki.archlinux.org/title/Installation_guide#Connect_to_the_internet) using [iwctl](https://wiki.archlinux.org/title/Iwd#iwctl)

```
iwctl
[iwd]# device list                                # list wifi devices
[iwd]# device  _device_  set-property Powered on  # turn on device
[iwd]# adapter _adapter_ set-property Powered on  # turn on adapter
[iwd]# station _device_ scan                      # scan for networks
[iwd]# station _device_ get-networks              # list networks
[iwd]# station _device_ connect _SSID_            # connect to network
[iwd]# station device show                        # display connection state
[iwd]#  ( Ctrl+d )                                # exit
```

---

Run pre-installation script[^1]<br>
<sub>**Note:** fill the DISK variable for the script to run</sub>

```
mkdir -p /root/usb
mount /dev/your_usb2 /root/usb
DISK=/dev/your_disk
. /root/usb/preinstall.sh
```

---

[Change root into new system](https://wiki.archlinux.org/title/Installation_guide#Chroot)

```
arch-chroot /mnt
```

---

Run installation script[^1]<br>
<sub>**Note:** install a text editor to modify script</sub>

```
. /install.sh
```

---

[Set the root password](https://wiki.archlinux.org/title/Installation_guide#Root_password)

```
passwd
```

---

[Reboot the system](https://wiki.archlinux.org/title/Installation_guide#Reboot)

1. Exit chroot: `exit`
2. Unmount disk: `umount -R /mnt`
3. Reboot system: `reboot`

---

Connect to wireless internet using [Network Manger](https://wiki.archlinux.org/title/NetworkManager#Usage)

```
nmtui
```

---

Run setup script[^1]<br>
<sub>**Note:** modify script to change username</sub>

```
. /setup.sh
```

---

Set the user password<br>
<sub>**Note:** may need change shyguy with your username</sub>

```
passwd shyguy
```

[^1]: Script assumes that is running as root
