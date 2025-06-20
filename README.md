# Arch Installation

Follow the [installation guide](https://wiki.archlinux.org/title/Installation_guide#Pre-installation) in the Arch wiki to download the [ISO file](https://wiki.archlinux.org/title/Installation_guide#Acquire_an_installation_image) and [verify the signature](https://wiki.archlinux.org/title/Installation_guide#Verify_signature)

---

Run iso2usb script[^1] to copy ISO to USB ([only UEFI](https://wiki.archlinux.org/title/USB_flash_installation_medium#Using_manual_formatting))<br>
<sub>**Note:** dependencies mkfs.fat and mkfs.ext4 needed</sub>

```
curl -sS -O https://raw.githubusercontent.com/RFCreate/arch-install/main/iso2usb.sh
chmod +x ./iso2usb.sh
./iso2usb.sh -d /dev/USB -i /path/to/ISO
```

When finished, [boot into the USB](https://wiki.archlinux.org/title/Installation_guide#Boot_the_live_environment)

---

Inside the bootable USB, connect to [wireless internet](https://wiki.archlinux.org/title/Installation_guide#Connect_to_the_internet) using [iwctl](https://wiki.archlinux.org/title/Iwd#iwctl)

```
iwctl
[iwd]# device list                              # list wifi devices
[iwd]# device  _name_ set-property Powered on   # turn on device
[iwd]# adapter _name_ set-property Powered on   # turn on adapter
[iwd]# station _name_ scan                      # scan for networks
[iwd]# station _name_ get-networks              # list networks
[iwd]# station _name_ connect _SSID_            # connect to network
[iwd]# station _name_ show                      # display connection state
[iwd]# quit                                     # exit
```

---

Run pre-installation script[^1]<br>
<sub>**Note:** download manually if you didn't run iso2usb script</sub>

```
mkdir -p /root/usb
mount /dev/USB1 /root/usb
/root/usb/preinstall.sh -d /dev/DISK
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
/install.sh
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
systemctl start NetworkManager.service
nmtui
```

---

Run post-installation script[^1]<br>
<sub>**Note:** specify your username after the flag</sub>

```
/postinstall.sh -u username
```

---

Set the user password<br>
<sub>**Note:** replace with your username</sub>

```
passwd username
```

[^1]: Script should run as root
