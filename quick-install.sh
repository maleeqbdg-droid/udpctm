#!/bin/bash
# quick-install.sh - One click installer

wget -O install.sh "https://github.com/maleeqbdg-droid/udpctm/blob/main/udp-ssh-installer.sh"
chmod +x install.sh
./install.sh

# Auto download semua script
wget -O /usr/local/bin/menu "https://github.com/maleeqbdg-droid/udpctm/blob/main/menu.sh"
wget -O /usr/local/bin/udp-monitor "https://github.com/maleeqbdg-droid/udpctm/blob/main/monitor.sh"
wget -O /usr/local/bin/auto-backup "https://github.com/maleeqbdg-droid/udpctm/blob/main/backup.sh"

chmod +x /usr/local/bin/{menu,udp-monitor,auto-backup}

# Start services
systemctl start udp-custom
systemctl start udp-monitor

echo "Installation complete! Type 'menu' to start"
