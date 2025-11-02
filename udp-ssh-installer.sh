#!/bin/bash
# udp-ssh-installer.sh - Installer Lengkap SSH + UDP Custom
# (c) 2025 - Premium VPN Service

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variabel Global
UDP_PORT=36712
DOMAIN=""
PUBLIC_IP=$(curl -s ifconfig.me)

print_banner() {
    clear
    echo -e "${BLUE}╔═══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║      SSH + UDP CUSTOM INSTALLER       ║${NC}"
    echo -e "${BLUE}║         Premium VPN Service           ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════╝${NC}"
    echo ""
}

# Cek root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: Script harus dijalankan sebagai root!${NC}"
    exit 1
fi

print_banner

# Input domain
echo -e "${YELLOW}Masukkan domain Anda (kosongkan untuk IP saja):${NC}"
read -p "Domain: " DOMAIN
if [ -z "$DOMAIN" ]; then
    DOMAIN=$PUBLIC_IP
fi

# Update system
echo -e "${GREEN}[1/10] Update sistem...${NC}"
apt update -y && apt upgrade -y
apt install -y curl wget git make gcc openssl netcat-openbsd net-tools \
    screen htop iftop vnstat fail2ban ufw python3 python3-pip

# Install SSH Server
echo -e "${GREEN}[2/10] Konfigurasi SSH Server...${NC}"
apt install -y openssh-server

# Konfigurasi SSH
cat > /etc/ssh/sshd_config << EOF
Port 22
Protocol 2
PermitRootLogin yes
PasswordAuthentication yes
PubkeyAuthentication yes
X11Forwarding yes
ClientAliveInterval 120
ClientAliveCountMax 2
UseDNS no
Banner /etc/banner.txt
EOF

# Banner SSH
cat > /etc/banner.txt << EOF
=====================================
     Premium SSH + UDP Service
        Server: $DOMAIN
=====================================
EOF

systemctl restart sshd

# Install UDP Custom
echo -e "${GREEN}[3/10] Install UDP Custom...${NC}"
cd /root
git clone https://github.com/maleeqbdg-droid/UDP-Custom.git
cd UDP-Custom
make
cp UDP-Custom /usr/local/bin/udp-custom
chmod +x /usr/local/bin/udp-custom

# Buat direktori kerja
mkdir -p /etc/udp-custom
mkdir -p /var/log/udp-custom
mkdir -p /root/backup/{system,users}

# Konfigurasi UDP Custom
echo -e "${GREEN}[4/10] Konfigurasi UDP Custom...${NC}"
cat > /etc/udp-custom/config.conf << EOF
# UDP Custom Configuration
PORT=$UDP_PORT
AUTH_FILE=/etc/udp-custom/users.db
LOG_FILE=/var/log/udp-custom/access.log
MAX_CLIENTS=100
TIMEOUT=300
EOF

# Database user
touch /etc/udp-custom/users.db
chmod 600 /etc/udp-custom/users.db

# Service UDP Custom
cat > /etc/systemd/system/udp-custom.service << EOF
[Unit]
Description=UDP Custom Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/udp-custom
ExecStart=/usr/local/bin/udp-custom -l 0.0.0.0:$UDP_PORT -r 127.0.0.1:22
Restart=always
RestartSec=3
CPUQuota=30%

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable udp-custom
systemctl start udp-custom

# Konfigurasi NAT & Firewall
echo -e "${GREEN}[5/10] Konfigurasi NAT & Firewall...${NC}"

# Enable IP forwarding
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p

# UFW Rules
ufw --force disable
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow $UDP_PORT/udp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# IPTables NAT
iptables -t nat -A PREROUTING -p udp --dport 1:65535 -j REDIRECT --to-port $UDP_PORT
iptables-save > /etc/iptables/rules.v4

# Fail2ban untuk SSH
cat > /etc/fail2ban/jail.local << EOF
[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
EOF

systemctl restart fail2ban

# Install menu system
echo -e "${GREEN}[6/10] Install sistem menu...${NC}"
wget -O /usr/local/bin/menu "https://raw.githubusercontent.com/user/repo/menu.sh"
chmod +x /usr/local/bin/menu

echo -e "${GREEN}[7/10] Setup monitoring...${NC}"
# Script monitoring akan dibuat di bagian selanjutnya

echo -e "${GREEN}[8/10] Setup backup otomatis...${NC}"
# Script backup akan dibuat di bagian selanjutnya

echo -e "${GREEN}[9/10] Optimasi sistem...${NC}"
# Optimasi kernel
cat >> /etc/sysctl.conf << EOF
# UDP Custom Optimization
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_congestion_control = bbr
EOF
sysctl -p

echo -e "${GREEN}[10/10] Finalisasi...${NC}"
# Buat script management
create_management_scripts

echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}     INSTALASI SELESAI!${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "IP Server    : ${YELLOW}$PUBLIC_IP${NC}"
echo -e "Domain       : ${YELLOW}$DOMAIN${NC}"
echo -e "SSH Port     : ${YELLOW}22${NC}"
echo -e "UDP Port     : ${YELLOW}$UDP_PORT${NC}"
echo -e "Menu Command : ${YELLOW}menu${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
