#!/bin/bash

# Daily Health Check Script for WHM/cPanel Server
# OS: CentOS v7.9.2009 STANDARD
# Control Panel: cPanel Version 110.0.48
# Hosting: Afrihost Dedicated Hosting (Self-managed)
# Hardware: 8GB RAM, 2x 1TB Enterprise (RAID 1)
# Author: Clarence Msindo

# Log file location
LOG_FILE="/var/log/daily_health_check.log"

# Email address to send the report
ADMIN_EMAIL="server_admin@hpcagroup.africa"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> $LOG_FILE
}

# Start the health check
log_message "Starting daily health check..."

# Check disk usage
log_message "Checking disk usage..."
DISK_USAGE=$(df -h / | grep -v Filesystem | awk '{print $5}' | sed 's/%//g')
if [ $DISK_USAGE -gt 90 ]; then
    log_message "WARNING: Disk usage is above 90%! Current usage: $DISK_USAGE%"
else
    log_message "Disk usage is normal. Current usage: $DISK_USAGE%"
fi

# Check memory usage
log_message "Checking memory usage..."
MEMORY_USAGE=$(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }')
MEMORY_TOTAL=$(free -m | awk 'NR==2{printf "%.2fMB", $2 }')
log_message "Memory usage: $MEMORY_USAGE of $MEMORY_TOTAL"

# Check CPU load
log_message "Checking CPU load..."
CPU_LOAD=$(uptime | awk -F 'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//g')
CPU_CORES=$(nproc)
if (( $(echo "$CPU_LOAD > $CPU_CORES" | bc -l 2>/dev/null) )); then
    log_message "WARNING: CPU load is high! Current load: $CPU_LOAD"
else
    log_message "CPU load is normal. Current load: $CPU_LOAD"
fi

# Check cPanel services
log_message "Checking cPanel services..."
if /usr/local/cpanel/bin/whmapi1 system_status | grep -q "stopped"; then
    log_message "WARNING: Some cPanel services are stopped!"
else
    log_message "All cPanel services are running."
fi

# Check RAID status
log_message "Checking RAID status..."
RAID_STATUS=$(cat /proc/mdstat | grep -o "\[U\]")
if [ -z "$RAID_STATUS" ]; then
    log_message "WARNING: RAID array is not healthy!"
else
    log_message "RAID array is healthy."
fi

# Check for updates
log_message "Checking for system updates..."
yum check-update &>> $LOG_FILE
if [ $? -eq 100 ]; then
    log_message "System updates are available."
else
    log_message "System is up to date."
fi

# End the health check
log_message "Daily health check completed."

# Send the log file via email
mail -s "Daily Health Check Report for $(hostname)" $ADMIN_EMAIL < $LOG_FILE

# Clear the log file for the next run
> $LOG_FILE