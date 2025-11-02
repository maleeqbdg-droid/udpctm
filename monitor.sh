#!/bin/bash
# /usr/local/bin/udp-monitor - Auto monitoring & fix

LOG_FILE="/var/log/udp-custom/monitor.log"
ALERT_LOG="/var/log/udp-custom/alerts.log"
UDP_PORT=36712
MAX_CPU=30

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

send_alert() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ALERT: $1" >> "$ALERT_LOG"
    # Kirim notifikasi (email/telegram) jika diperlukan
}

check_services() {
    # Check SSH
    if ! systemctl is-active --quiet sshd; then
        log_message "SSH Down! Attempting restart..."
        send_alert "SSH Server Down"
        systemctl restart sshd
        sleep 3
        if systemctl is-active --quiet sshd; then
            log_message "SSH successfully restarted"
        else
            send_alert "SSH restart failed!"
        fi
    fi
    
    # Check UDP Custom
    if ! systemctl is-active --quiet udp-custom; then
        log_message "UDP Custom Down! Attempting restart..."
        send_alert "UDP Custom Down"
        systemctl restart udp-custom
        sleep 3
        if systemctl is-active --quiet udp-custom; then
            log_message "UDP Custom successfully restarted"
        else
            send_alert "UDP Custom restart failed!"
        fi
    fi
}

check_ports() {
    # Check UDP port
    if ! netstat -uln | grep -q ":$UDP_PORT"; then
        log_message "UDP Port $UDP_PORT not listening!"
        send_alert "UDP Port $UDP_PORT closed"
        systemctl restart udp-custom
    fi
    
    # Check SSH port
    if ! netstat -tln | grep -q ":22"; then
        log_message "SSH Port 22 not listening!"
        send_alert "SSH Port 22 closed"
        systemctl restart sshd
    fi
}

check_resources() {
    # CPU Check
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print int($2)}')
    if [ "$cpu_usage" -gt 80 ]; then
        log_message "High CPU usage: $cpu_usage%"
        send_alert "High CPU usage: $cpu_usage%"
        
        # Kill high CPU processes
        ps aux | sort -nrk 3,3 | head -5 | while read line; do
            pid=$(echo $line | awk '{print $2}')
            cpu=$(echo $line | awk '{print $3}')
            cmd=$(echo $line | awk '{print $11}')
            if (( $(echo "$cpu > 50" | bc -l) )); then
                log_message "Killing high CPU process: PID=$pid CPU=$cpu% CMD=$cmd"
                kill -9 $pid 2>/dev/null
            fi
        done
    fi
    
    # Memory Check
    mem_usage=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
    if [ "$mem_usage" -gt 90 ]; then
        log_message "High memory usage: $mem_usage%"
        send_alert "High memory usage: $mem_usage%"
        
        # Clear cache
        sync && echo 3 > /proc/sys/vm/drop_caches
    fi
    
    # Disk Check
    disk_usage=$(df / | awk 'NR==2 {print int($5)}')
    if [ "$disk_usage" -gt 85 ]; then
        log_message "High disk usage: $disk_usage%"
        send_alert "High disk usage: $disk_usage%"
        
        # Clean old logs
        find /var/log -name "*.log" -type f -mtime +7 -delete
        find /var/log -name "*.gz" -type f -mtime +7 -delete
    fi
}

check_security() {
    # Check for brute force attempts
    failed_attempts=$(grep "Failed password" /var/log/auth.log | tail -100 | wc -l)
    if [ "$failed_attempts" -gt 50 ]; then
        log_message "Possible brute force attack detected!"
        send_alert "Brute force attack: $failed_attempts attempts"
    fi
    
    # Check for suspicious connections
    suspicious=$(netstat -tn | grep ESTABLISHED | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -5)
    log_message "Top connections: $suspicious"
}

cleanup_expired_users() {
    # Remove expired users
    while IFS=: read -r user pass exp; do
        exp_epoch=$(date -d "$exp" +%s 2>/dev/null)
        now_epoch=$(date +%s)
        
        if [ "$exp_epoch" -lt "$now_epoch" ]; then
            log_message "Removing expired user: $user"
            userdel -r "$user" 2>/dev/null
            sed -i "/^$user:/d" /etc/udp-custom/users.db
        fi
    done < /etc/udp-custom/users.db
}

# Main monitoring loop
log_message "Monitor started"

while true; do
    check_services
    check_ports
    check_resources
    check_security
    cleanup_expired_users
    
    # Wait 2 minutes
    sleep 120
done
