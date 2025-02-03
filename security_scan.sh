#!/bin/bash

# Security Scan Script for HA Group
# Author: Clarence Msindo
# Last Updated: January 2025

# Set up logging
LOG_DIR="/var/log/security_scans"
LOG_FILE="$LOG_DIR/security_scan_$(date +%Y%m%d_%H%M%S).log"
ALERT_EMAIL="server_admin@hpcagroup.africa"

# Create log directory if it doesn't exist
mkdir -p $LOG_DIR

# Logging function
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# Email alert function
send_alert() {
    local subject="$1"
    local message="$2"
    echo "$message" | mail -s "Security Alert: $subject" "$ALERT_EMAIL"
}

# Check system for available updates
check_updates() {
    log_message "Checking for system updates..."
    
    # Get list of available updates
    updates=$(yum check-update --quiet | grep -v "^$" | wc -l)
    security_updates=$(yum --security check-update --quiet | grep -v "^$" | wc -l)
    
    log_message "Found $updates total updates, $security_updates security updates"
    
    if [ $security_updates -gt 0 ]; then
        send_alert "Security Updates Available" "There are $security_updates security updates available for installation."
    fi
}

# Check failed login attempts
check_failed_logins() {
    log_message "Checking failed login attempts..."
    
    # Check auth.log for failed login attempts in the last hour
    failed_logins=$(grep "Failed password" /var/log/secure | grep "$(date -d '1 hour ago' +'%b %d %H')" | wc -l)
    
    if [ $failed_logins -gt 10 ]; then
        send_alert "Excessive Failed Logins" "Detected $failed_logins failed login attempts in the last hour."
        log_message "WARNING: High number of failed logins detected: $failed_logins"
    else
        log_message "Failed login attempts in last hour: $failed_logins"
    fi
}

# Monitor firewall status and rules
check_firewall() {
    log_message "Checking firewall status..."
    
    # Check if firewall is running
    if ! systemctl is-active --quiet firewalld; then
        send_alert "Firewall Warning" "Firewall service (firewalld) is not running!"
        log_message "ERROR: Firewall is not running!"
        return
    fi
    
    # Log current firewall rules
    log_message "Current firewall rules:"
    firewall-cmd --list-all >> "$LOG_FILE"
    
    # Check for potentially dangerous open ports
    dangerous_ports="21 23 3389"
    for port in $dangerous_ports; do
        if firewall-cmd --query-port=$port/tcp; then
            send_alert "Firewall Security Risk" "Potentially dangerous port $port is open!"
            log_message "WARNING: Port $port is open!"
        fi
    done
}

# Check system logs for suspicious activity
check_system_logs() {
    log_message "Analyzing system logs..."
    
    # Check for sudo usage
    sudo_attempts=$(grep "sudo:" /var/log/secure | grep "$(date +%Y-%m-%d)" | wc -l)
    log_message "Sudo attempts today: $sudo_attempts"
    
    # Check for large files created in the last 24 hours
    large_files=$(find / -type f -size +100M -mtime -1 2>/dev/null | wc -l)
    if [ $large_files -gt 10 ]; then
        send_alert "Suspicious File Activity" "Detected $large_files large files created in the last 24 hours"
        log_message "WARNING: High number of large files created: $large_files"
    fi
}

# Verify critical system files haven't been modified
verify_system_files() {
    log_message "Verifying system file integrity..."
    
    # List of critical files to check
    critical_files=(
        "/etc/passwd"
        "/etc/shadow"
        "/etc/group"
        "/etc/ssh/sshd_config"
    )
    
    for file in "${critical_files[@]}"; do
        if [ -f "$file" ]; then
            current_hash=$(md5sum "$file" | cut -d' ' -f1)
            hash_file="/var/log/security_scans/hashes/$(basename "$file").md5"
            
            # Create hash directory if it doesn't exist
            mkdir -p "/var/log/security_scans/hashes"
            
            # If we don't have a stored hash, create one
            if [ ! -f "$hash_file" ]; then
                echo "$current_hash" > "$hash_file"
                log_message "Created new hash for $file"
            else
                stored_hash=$(cat "$hash_file")
                if [ "$current_hash" != "$stored_hash" ]; then
                    send_alert "File Modification Detected" "Critical file $file has been modified!"
                    log_message "WARNING: $file has been modified!"
                fi
            fi
        else
            send_alert "Missing Critical File" "Critical file $file is missing!"
            log_message "ERROR: Critical file $file is missing!"
        fi
    done
}

# Main execution
log_message "Starting security scan..."

check_updates
check_failed_logins
check_firewall
check_system_logs
verify_system_files

log_message "Security scan completed."

# Cleanup old logs (keep last 30 days)
find "$LOG_DIR" -name "security_scan_*.log" -mtime +30 -delete

exit 0