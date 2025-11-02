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

# Pindahkan file binary
cp udp-custom /usr/local/bin/udp-custom
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
#!/bin/bash
# /usr/local/bin/menu - Menu Management SSH + UDP Custom

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

DOMAIN=$(cat /etc/udp-custom/domain.txt 2>/dev/null || echo $(curl -s ifconfig.me))

show_menu() {
    clear
    echo -e "${PURPLE}╔════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║     SSH + UDP CUSTOM PREMIUM MENU      ║${NC}"
    echo -e "${PURPLE}║          Server: $DOMAIN              ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════╝${NC}"
    echo -e ""
    echo -e "${CYAN}[USER MANAGEMENT]${NC}"
    echo -e "  ${GREEN}1${NC}. Tambah User SSH + UDP"
    echo -e "  ${GREEN}2${NC}. Hapus User"
    echo -e "  ${GREEN}3${NC}. List User Aktif"
    echo -e "  ${GREEN}4${NC}. Cek User Online"
    echo -e "  ${GREEN}5${NC}. Perpanjang User"
    echo -e "  ${GREEN}6${NC}. Trial User (1 Hari)"
    echo -e ""
    echo -e "${CYAN}[MONITORING]${NC}"
    echo -e "  ${GREEN}7${NC}. Monitor Real-time"
    echo -e "  ${GREEN}8${NC}. Cek Status Services"
    echo -e "  ${GREEN}9${NC}. Bandwidth Usage"
    echo -e " ${GREEN}10${NC}. System Info"
    echo -e ""
    echo -e "${CYAN}[BACKUP & RESTORE]${NC}"
    echo -e " ${GREEN}11${NC}. Backup Users"
    echo -e " ${GREEN}12${NC}. Restore Users"
    echo -e " ${GREEN}13${NC}. Backup System"
    echo -e ""
    echo -e "${CYAN}[MAINTENANCE]${NC}"
    echo -e " ${GREEN}14${NC}. Restart All Services"
    echo -e " ${GREEN}15${NC}. Update System"
    echo -e " ${GREEN}16${NC}. Fix Problems"
    echo -e " ${GREEN}17${NC}. Change Domain"
    echo -e ""
    echo -e "${RED}0${NC}. Exit"
    echo -e ""
    echo -e "${PURPLE}════════════════════════════════════════${NC}"
}

# Fungsi tambah user
add_user() {
    clear
    echo -e "${CYAN}═══ TAMBAH USER SSH + UDP ═══${NC}"
    echo ""
    read -p "Username: " username
    read -p "Password: " password
    read -p "Masa Aktif (hari): " days
    
    # Validasi input
    if [[ -z "$username" || -z "$password" || -z "$days" ]]; then
        echo -e "${RED}Error: Semua field harus diisi!${NC}"
        read -n 1 -s -r -p "Press any key to continue..."
        return
    fi
    
    # Cek user exists
    if id "$username" &>/dev/null; then
        echo -e "${RED}Error: User $username sudah ada!${NC}"
        read -n 1 -s -r -p "Press any key to continue..."
        return
    fi
    
    # Buat user system
    useradd -m -s /bin/false "$username"
    echo "$username:$password" | chpasswd
    
    # Set expiry
    expiry_date=$(date -d "+$days days" +"%Y-%m-%d")
    chage -E "$expiry_date" "$username"
    
    # Tambah ke UDP database
    echo "$username:$password:$expiry_date" >> /etc/udp-custom/users.db
    
    # Generate format klien
    clear
    echo -e "${GREEN}✅ USER BERHASIL DITAMBAHKAN!${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════${NC}"
    echo -e "Username     : ${CYAN}$username${NC}"
    echo -e "Password     : ${CYAN}$password${NC}"
    echo -e "Expired      : ${CYAN}$expiry_date${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════${NC}"
    echo -e ""
    echo -e "${GREEN}FORMAT KONEKSI UDP CUSTOM:${NC}"
    echo -e "${BLUE}$DOMAIN:1-65535@$username:$password${NC}"
    echo -e ""
    echo -e "${GREEN}PENGATURAN APLIKASI:${NC}"
    echo -e "Server       : ${CYAN}$DOMAIN${NC}"
    echo -e "Port Range   : ${CYAN}1-65535${NC}"
    echo -e "Username     : ${CYAN}$username${NC}"
    echo -e "Password     : ${CYAN}$password${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════${NC}"
    
    # Log activity
    echo "[$(date)] User $username ditambahkan untuk $days hari" >> /var/log/udp-custom/users.log
    
    read -n 1 -s -r -p "Press any key to continue..."
}

# Fungsi hapus user
delete_user() {
    clear
    echo -e "${CYAN}═══ HAPUS USER ═══${NC}"
    echo ""
    
    # Tampilkan list user
    echo -e "${YELLOW}User terdaftar:${NC}"
    awk -F: '{print "- " $1}' /etc/udp-custom/users.db
    echo ""
    
    read -p "Username yang akan dihapus: " username
    
    if [[ -z "$username" ]]; then
        echo -e "${RED}Error: Username tidak boleh kosong!${NC}"
        read -n 1 -s -r -p "Press any key to continue..."
        return
    fi
    
    # Hapus dari system
    userdel -r "$username" 2>/dev/null
    
    # Hapus dari database
    sed -i "/^$username:/d" /etc/udp-custom/users.db
    
    # Kill active sessions
    pkill -u "$username" 2>/dev/null
    
    echo -e "${GREEN}✅ User $username berhasil dihapus!${NC}"
    echo "[$(date)] User $username dihapus" >> /var/log/udp-custom/users.log
    
    read -n 1 -s -r -p "Press any key to continue..."
}

# Fungsi list user
list_users() {
    clear
    echo -e "${CYAN}═══ DAFTAR USER AKTIF ═══${NC}"
    echo ""
    echo -e "${YELLOW}Username | Password | Expired${NC}"
    echo -e "${PURPLE}═══════════════════════════════${NC}"
    
    while IFS=: read -r user pass exp; do
        # Cek apakah expired
        exp_epoch=$(date -d "$exp" +%s 2>/dev/null)
        now_epoch=$(date +%s)
        
        if [ "$exp_epoch" -ge "$now_epoch" ]; then
            days_left=$(( ($exp_epoch - $now_epoch) / 86400 ))
            echo -e "${GREEN}$user${NC} | $pass | $exp (${CYAN}$days_left hari${NC})"
        else
            echo -e "${RED}$user${NC} | $pass | $exp (${RED}EXPIRED${NC})"
        fi
    done < /etc/udp-custom/users.db
    
    echo ""
    total=$(wc -l < /etc/udp-custom/users.db)
    echo -e "${YELLOW}Total: $total users${NC}"
    
    read -n 1 -s -r -p "Press any key to continue..."
}

# Fungsi monitoring real-time
monitor_realtime() {
    clear
    echo -e "${CYAN}═══ MONITORING REAL-TIME ═══${NC}"
    echo -e "${YELLOW}Tekan Ctrl+C untuk keluar${NC}"
    echo ""
    
    # Monitoring loop
    while true; do
        clear
        echo -e "${CYAN}═══ SYSTEM MONITOR - $(date) ═══${NC}"
        echo ""
        
        # CPU & Memory
        echo -e "${GREEN}[SYSTEM RESOURCES]${NC}"
        echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')%"
        echo "Memory: $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
        echo ""
        
        # Services Status
        echo -e "${GREEN}[SERVICES STATUS]${NC}"
        
        # SSH
        if systemctl is-active --quiet sshd; then
            echo -e "SSH Server: ${GREEN}● RUNNING${NC}"
        else
            echo -e "SSH Server: ${RED}● DOWN${NC}"
        fi
        
        # UDP Custom
        if systemctl is-active --quiet udp-custom; then
            echo -e "UDP Custom: ${GREEN}● RUNNING${NC}"
        else
            echo -e "UDP Custom: ${RED}● DOWN${NC}"
        fi
        
        # Port Check
        if netstat -tlnp | grep -q ":$UDP_PORT"; then
            echo -e "UDP Port $UDP_PORT: ${GREEN}● OPEN${NC}"
        else
            echo -e "UDP Port $UDP_PORT: ${RED}● CLOSED${NC}"
        fi
        
        echo ""
        
        # Active Connections
        echo -e "${GREEN}[ACTIVE CONNECTIONS]${NC}"
        echo "SSH Users: $(who | wc -l)"
        echo "UDP Connections: $(netstat -ntu | grep :$UDP_PORT | wc -l)"
        
        echo ""
        
        # Network Traffic
        echo -e "${GREEN}[NETWORK TRAFFIC]${NC}"
        vnstat -tr 5 2>/dev/null || echo "vnstat not available"
        
        sleep 5
    done
}

# Fungsi backup users
backup_users() {
    clear
    echo -e "${CYAN}═══ BACKUP USERS ═══${NC}"
    
    backup_file="/root/backup/users/users_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    # Create backup
    tar -czf "$backup_file" \
        /etc/udp-custom/users.db \
        /etc/passwd \
        /etc/shadow \
        /home/* 2>/dev/null
    
    if [ -f "$backup_file" ]; then
        echo -e "${GREEN}✅ Backup berhasil!${NC}"
        echo -e "File: ${YELLOW}$backup_file${NC}"
        echo -e "Size: $(ls -lh $backup_file | awk '{print $5}')"
    else
        echo -e "${RED}❌ Backup gagal!${NC}"
    fi
    
    read -n 1 -s -r -p "Press any key to continue..."
}

# Fungsi auto-fix problems
fix_problems() {
    clear
    echo -e "${CYAN}═══ AUTO-FIX PROBLEMS ═══${NC}"
    echo ""
    
    # Check SSH
    echo -e "${YELLOW}Checking SSH Server...${NC}"
    if ! systemctl is-active --quiet sshd; then
        echo -e "${RED}SSH Down! Restarting...${NC}"
        systemctl restart sshd
        sleep 2
        if systemctl is-active --quiet sshd; then
            echo -e "${GREEN}✅ SSH Fixed!${NC}"
        else
            echo -e "${RED}❌ SSH masih bermasalah!${NC}"
        fi
    else
        echo -e "${GREEN}✅ SSH OK${NC}"
    fi
    
    # Check UDP Custom
    echo -e "${YELLOW}Checking UDP Custom...${NC}"
    if ! systemctl is-active --quiet udp-custom; then
        echo -e "${RED}UDP Custom Down! Restarting...${NC}"
        systemctl restart udp-custom
        sleep 2
        if systemctl is-active --quiet udp-custom; then
            echo -e "${GREEN}✅ UDP Custom Fixed!${NC}"
        else
            echo -e "${RED}❌ UDP Custom masih bermasalah!${NC}"
        fi
    else
        echo -e "${GREEN}✅ UDP Custom OK${NC}"
    fi
    
    # Check Firewall
    echo -e "${YELLOW}Checking Firewall...${NC}"
    ufw reload
    echo -e "${GREEN}✅ Firewall reloaded${NC}"
    
    # Clean logs if full
    echo -e "${YELLOW}Checking disk space...${NC}"
    df_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$df_usage" -gt 90 ]; then
        echo -e "${RED}Disk usage high! Cleaning logs...${NC}"
        find /var/log -name "*.log" -type f -size +100M -delete
        echo -e "${GREEN}✅ Logs cleaned${NC}"
    else
        echo -e "${GREEN}✅ Disk space OK${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}═══ FIX COMPLETE ═══${NC}"
    
    read -n 1 -s -r -p "Press any key to continue..."
}

# Main menu loop
while true; do
    show_menu
    read -p "Pilih menu [0-17]: " choice
    
    case $choice in
        1) add_user ;;
        2) delete_user ;;
        3) list_users ;;
        4) check_online_users ;;
        5) extend_user ;;
        6) trial_user ;;
        7) monitor_realtime ;;
        8) check_services ;;
        9) bandwidth_usage ;;
        10) system_info ;;
        11) backup_users ;;
        12) restore_users ;;
        13) backup_system ;;
        14) restart_all_services ;;
        15) update_system ;;
        16) fix_problems ;;
        17) change_domain ;;
        0) 
            echo -e "${GREEN}Terima kasih telah menggunakan layanan kami!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Menu tidak valid!${NC}"
            sleep 2
            ;;
    esac
done
