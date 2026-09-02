#!/bin/sh

# Define helper
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

# Install packages
curl -fsSLO --output-dir /tmp https://raw.githubusercontent.com/RFCreate/arch-install/main/pkgs.md || exit 1
grep '^>\s*' /tmp/pkgs.md | sed 's/^>\s*//' | xargs --no-run-if-empty pacman -S --needed --noconfirm 2>&1 | tee -a /pacman.log

# https://wiki.archlinux.org/title/Users_and_groups#User_management
# Add new user
id -u "$NEWUSER" > /dev/null 2>&1 || useradd -mk "" -G wheel -s /usr/bin/zsh "$NEWUSER"

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

# https://wiki.archlinux.org/title/Sudo#Sudoers_default_file_permissions
# Reset sudoers file permissions in case of accidental change
chown root:root /etc/sudoers
chmod 0440 /etc/sudoers

# https://wiki.archlinux.org/title/Doas#Configuration
# Allow members of group wheel to run root commands
echo 'permit persist setenv {PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin} :wheel' > /etc/doas.conf
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
