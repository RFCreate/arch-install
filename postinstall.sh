#!/bin/sh

#Define helper
usage() {
    [ -n "$1" ] && echo "$1" 1>&2
    echo "Usage: $0 -u <username>" 1>&2
    exit 1
}

# Check arguments
while getopts ":u:" opt; do
    case $opt in
        'u') NEWUSER="${OPTARG}" ;;
        *) echo here ;;
    esac
done

# Exit if username is invalid
[ -z "$NEWUSER" ] && usage "Error: Missing username."
echo "$NEWUSER" | grep -qE '^[A-Za-z_][-A-Za-z0-9_.]*\$?$' || usage "Error: Username is badname."

# https://wiki.archlinux.org/title/Sudo#Example_entries
# Allow wheel group to run sudo without password
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^%wheel ALL=(ALL:ALL) ALL/# %wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# https://wiki.archlinux.org/title/Users_and_groups#User_management
# Add new user
id -u "$NEWUSER" > /dev/null 2>&1 || useradd -mk "" -G wheel "$NEWUSER"

# https://github.com/Jguer/yay#Installation
# Install yay from AUR
if ! pacman -Q yay > /dev/null 2>&1; then
    curl -sS --output-dir /tmp -L -O https://aur.archlinux.org/cgit/aur.git/snapshot/yay-bin.tar.gz
    runuser -l "$NEWUSER" -c "tar -C /tmp -xf /tmp/yay-bin.tar.gz && makepkg -si --needed --noconfirm -D /tmp/yay-bin" >> /yay.log 2>&1
fi

# Install packages inside csv file
curl -sS -o /tmp/pkgs.csv.tmp https://raw.githubusercontent.com/RFCreate/arch-install/main/pkgs.csv
tail -n +2 /tmp/pkgs.csv.tmp | cut -d ',' -f -2 > /tmp/pkgs.csv
while IFS=, read -r tag program; do
    case "$tag" in
        "A") runuser -l "$NEWUSER" -c "yay -S --needed --noconfirm $program" >> /yay.log 2>&1 ;;
        *) pacman -S --needed --noconfirm "$program" >> /pacman.log 2>&1 ;;
    esac
done < /tmp/pkgs.csv

# https://wiki.archlinux.org/title/Sudo#Example_entries
# Allow wheel to run sudo entering password
sed -i 's/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# https://wiki.archlinux.org/title/Command-line_shell#Changing_your_default_shell
# Change new user default shell
[ "$(getent passwd "$NEWUSER" | awk -F: '{print $NF}')" = "/usr/bin/zsh" ] || chsh -s /usr/bin/zsh "$NEWUSER" > /dev/null

# https://wiki.archlinux.org/title/Dotfiles#Tracking_dotfiles_directly_with_Git
# Copy dotfiles from repo to HOME
runuser -l "$NEWUSER" << 'EOF'
git clone -q --bare https://github.com/RFCreate/dotfiles.git "$HOME/.dotfiles" --depth 1
dotfiles(){ git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" $@; }
dotfiles config --local status.showUntrackedFiles no
cd "$HOME" && mkdir -p .dotfiles-backup
dotfiles checkout 2>&1 | grep "\s\s*\." | awk '{print $1}' | sed 's|[^/]*$||' | sort -u | xargs -I {} mkdir -p ".dotfiles-backup/{}"
dotfiles checkout 2>&1 | grep "\s\s*\." | awk '{print $1}' | xargs -I {} mv {} ".dotfiles-backup/{}"
dotfiles checkout -f
EOF

# https://wiki.archlinux.org/title/PC_speaker#Globally
# Remove beep sound
lsmod | grep -wq pcspkr && rmmod pcspkr
lsmod | grep -wq snd_pcsp && rmmod snd_pcsp
echo 'blacklist pcspkr' > /etc/modprobe.d/nobeep.conf
echo 'blacklist snd_pcsp' >> /etc/modprobe.d/nobeep.conf

# https://wiki.archlinux.org/title/Power_management#ACPI_events
# Ignore power/suspend/reboot/hibernate buttons
sed -i 's/^#*HandlePowerKey=.*/HandlePowerKey=ignore/' /etc/systemd/logind.conf
sed -i 's/^#*HandleRebootKey=.*/HandleRebootKey=ignore/' /etc/systemd/logind.conf
sed -i 's/^#*HandleSuspendKey=.*/HandleSuspendKey=ignore/' /etc/systemd/logind.conf
sed -i 's/^#*HandleHibernateKey=.*/HandleHibernateKey=ignore/' /etc/systemd/logind.conf

# https://wiki.archlinux.org/title/Sudo#Sudoers_default_file_permissions
# Reset sudoers file permissions in case of accidental change
chown root:root /etc/sudoers
chmod 0440 /etc/sudoers

# https://wiki.archlinux.org/title/Doas#Configuration
# Allow members of group wheel to run root commands
echo 'permit setenv {PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin} :wheel' > /etc/doas.conf
chown root:root /etc/doas.conf
chmod 0400 /etc/doas.conf

# https://wiki.archlinux.org/title/NetworkManager#Enable_NetworkManager
# Enable network manager
systemctl --quiet enable NetworkManager.service

# https://wiki.archlinux.org/title/Greetd#Starting_greetd
# Enable greetd
systemctl --quiet enable greetd.service
# https://wiki.archlinux.org/title/Greetd#tuigreet
# Configure greetd with tuigreet
sed -i "s/^command = .*$/command = \"tuigreet -t -r --remember-user-session --user-menu --theme 'border=magenta;text=cyan;action=yellow'\"/" /etc/greetd/config.toml

# https://wiki.archlinux.org/title/CUPS#Installation
# Enable cups
systemctl --quiet enable cups.socket
# https://wiki.archlinux.org/title/CUPS#Printer_discovery
# Disable built-in mDNS service
systemctl --quiet disable systemd-resolved.service
# https://wiki.archlinux.org/title/Avahi#Hostname_resolution
# Enable avahi with hostname resolution
systemctl --quiet enable avahi-daemon.socket
sed -i 's/hosts: mymachines resolve/hosts: mymachines mdns_minimal [NOTFOUND=return] resolve/' /etc/nsswitch.conf

# https://wiki.archlinux.org/title/Uncomplicated_Firewall#Installation
# Enable firewall
systemctl --quiet disable iptables.service
systemctl --quiet disable ip6tables.service
systemctl --quiet enable ufw.service
ufw enable
