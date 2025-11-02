#!/bin/bash
# /usr/local/bin/auto-backup - Backup otomatis

BACKUP_DIR="/root/backup"
RETENTION_DAYS=7

# Backup users
backup_users() {
    timestamp=$(date +%Y%m%d_%H%M%S)
    backup_file="$BACKUP_DIR/users/users_$timestamp.tar.gz"
    
    tar -czf "$backup_file" \
        /etc/udp-custom/users.db \
        /etc/passwd \
        /etc/shadow \
        /home/* 2>/dev/null
    
    echo "[$(date)] User backup completed: $backup_file" >> /var/log/backup.log
}

# Backup system config
backup_system() {
    timestamp=$(date +%Y%m%d_%H%M%S)
    backup_file="$BACKUP_DIR/system/system_$timestamp.tar.gz"
    
    tar -czf "$backup_file" \
        /etc/ssh/sshd_config \
        /etc/udp-custom/ \
        /etc/systemd/system/udp-custom.service \
        /usr/local/bin/menu \
        /usr/local/bin/udp-monitor \
        /etc/fail2ban/ \
        /etc/ufw/ 2>/dev/null
    
    echo "[$(date)] System backup completed: $backup_file" >> /var/log/backup.log
}

# Clean old backups
cleanup_old_backups() {
    find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete
    echo "[$(date)] Old backups cleaned" >> /var/log/backup.log
}

# Execute backups
backup_users
backup_system
cleanup_old_backups
