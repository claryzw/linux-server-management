#!/bin/bash

# Mailbox Capacity Warning Script for HA Group
# Location: /usr/local/sbin/mailbox_warning.sh
# Author: Clarence Msindo
# Revised: August 2025

# Configuration
LOG_FILE="/var/log/mailbox_warnings.log"
ADMIN_EMAIL="admin@example.com" #-> Add your admin email here
ALERT_THRESHOLD=90  # Alert when mailbox is 90% full
TEMP_FILE="/tmp/mailbox_check_$$.tmp"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Thresholds for different alert levels
declare -A THRESHOLDS=([90]=WARNING [98]=CRITICAL)

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

send_alert() {
    local account="$1"
    local usage="$2"
    local quota="$3"
    local percent="$4"
    local severity="$5"

    local subject=""
    local priority=""
    
    case $severity in
        CRITICAL)
            subject="URGENT: Your HA Group email mailbox is critically full"
            priority="-a 'X-Priority: 1'"
            ;;
        WARNING)
            subject="ACTION REQUIRED: Your HA Group email mailbox is nearly full"
            priority=""
            ;;
    esac

    local message="Dear [Company Name] User,

Your email mailbox ($account) has reached $percent% of its capacity.

Current Usage: ${usage}MB of ${quota}MB

Please take immediate action:

1. DELETE UNNECESSARY EMAILS:
   - Open your email client and sort emails by size (largest first)
   - Delete large emails you no longer need, especially those with attachments
   - Empty your 'Trash' or 'Deleted Items' folder

2. ARCHIVE IMPORTANT EMAILS:
   - Create local folders in your email client
   - Move older emails you want to keep into these folders
   - Save important attachments to your computer

3. MANAGE YOUR SENT ITEMS:
   - Delete old sent emails with large attachments
   - Move important sent emails to local folders

If you need assistance or have any questions, please contact:
Email: $ADMIN_EMAIL

Thank you for your prompt attention to this matter.

Best regards,
[Company Name Position]
[Company Name]"

    if echo "$message" | mail -s "$subject" $priority "$account" -c "$ADMIN_EMAIL"; then
        log_message "$severity: Warning email sent to $account"
        return 0
    else
        log_message "ERROR: Failed to send email to $account"
        return 1
    fi
}

check_dependencies() {
    # Check if required tools are available
    if ! command -v bc >/dev/null 2>&1; then
        log_message "ERROR: bc calculator is required but not installed"
        exit 1
    fi
    
    if ! command -v mail >/dev/null 2>&1; then
        log_message "WARNING: mail command not available - alerts will be logged only"
    fi
    
    # Check if cPanel UAPI is available
    if ! command -v uapi >/dev/null 2>&1; then
        log_message "ERROR: cPanel UAPI not available"
        exit 1
    fi
}

get_email_accounts() {
    local accounts_found=0
    > "$TEMP_FILE"
    
    # Iterate through all cPanel users
    for user_file in /var/cpanel/users/*; do
        if [[ ! -f "$user_file" ]]; then
            continue
        fi
        
        local username=$(basename "$user_file")
        log_message "Checking user: $username"
        
        # Get email accounts for this user
        local email_list=$(uapi --user="$username" Email list_pops 2>/dev/null | grep -E "^\s*email:" | awk '{print $2}')
        
        if [[ -n "$email_list" ]]; then
            echo "$email_list" | while read -r email; do
                if [[ "$email" =~ @ ]]; then
                    echo "$username:$email" >> "$TEMP_FILE"
                    ((accounts_found++))
                fi
            done
        fi
    done
    
    local total_found=$(wc -l < "$TEMP_FILE" 2>/dev/null || echo "0")
    log_message "Found $total_found email accounts total"
}

check_mailbox_usage() {
    local cpanel_user="$1"
    local email_account="$2"
    
    # Method 1: Use UAPI with correct user context
    local result=$(uapi --user="$cpanel_user" Email get_disk_usage email="$email_account" 2>/dev/null)
    
    if [[ $? -eq 0 && -n "$result" ]]; then
        local usage=$(echo "$result" | grep -E "^\s*diskused:" | awk '{print $2}')
        local quota=$(echo "$result" | grep -E "^\s*diskquota:" | awk '{print $2}')
        
        # Validate numeric values
        if [[ "$usage" =~ ^[0-9]+$ && "$quota" =~ ^[0-9]+$ ]]; then
            # Handle unlimited quota (can be 0, -1, or very large numbers)
            if [[ "$quota" -eq 0 || "$quota" -eq -1 || "$quota" -gt 99999999 ]]; then
                log_message "INFO: $email_account has unlimited quota"
                return 0
            fi
            
            # Convert to MB and calculate percentage
            local usage_mb=$((usage / 1024 / 1024))
            local quota_mb=$((quota / 1024 / 1024))
            
            # Use bc for accurate percentage calculation
            local percent=$(echo "scale=0; ($usage * 100) / $quota" | bc)
            
            log_message "SUCCESS: $email_account - ${usage_mb}MB/${quota_mb}MB (${percent}%)"
            
            # Check thresholds
            local current_severity=""
            for threshold in $(echo "${!THRESHOLDS[@]}" | tr ' ' '\n' | sort -nr); do
                if [[ "$percent" -ge "$threshold" ]]; then
                    current_severity="${THRESHOLDS[$threshold]}"
                    break
                fi
            done
            
            if [[ -n "$current_severity" ]]; then
                send_alert "$email_account" "$usage_mb" "$quota_mb" "$percent" "$current_severity"
                return 1
            fi
            return 0
        fi
    fi
    
    # Method 2: Check filesystem directly
    local domain="${email_account##*@}"
    local user_part="${email_account%%@*}"
    local maildir_path="/home/$cpanel_user/mail/$domain/$user_part"
    
    if [[ -d "$maildir_path" && -f "$maildir_path/maildirsize" ]]; then
        local size_info=$(head -1 "$maildir_path/maildirsize" 2>/dev/null)
        local quota_bytes=$(echo "$size_info" | cut -d'S' -f1)
        
        if [[ "$quota_bytes" =~ ^[0-9]+$ && "$quota_bytes" -gt 0 ]]; then
            local usage_bytes=0
            if [[ -f "$maildir_path/maildirsize" ]]; then
                usage_bytes=$(tail -n +2 "$maildir_path/maildirsize" 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
            fi
            
            local quota_mb=$((quota_bytes / 1024 / 1024))
            local usage_mb=$((usage_bytes / 1024 / 1024))
            local percent=$(echo "scale=0; ($usage_bytes * 100) / $quota_bytes" | bc 2>/dev/null || echo "0")
            
            log_message "SUCCESS: $email_account - ${usage_mb}MB/${quota_mb}MB (${percent}%)"
            
            # Check thresholds
            local current_severity=""
            for threshold in $(echo "${!THRESHOLDS[@]}" | tr ' ' '\n' | sort -nr); do
                if [[ "$percent" -ge "$threshold" ]]; then
                    current_severity="${THRESHOLDS[$threshold]}"
                    break
                fi
            done
            
            if [[ -n "$current_severity" ]]; then
                send_alert "$email_account" "$usage_mb" "$quota_mb" "$percent" "$current_severity"
                return 1
            fi
            return 0
        fi
    fi
    
    log_message "WARNING: Could not retrieve usage info for $email_account"
    return 2
}

# Main execution
main() {
    log_message "Starting mailbox capacity check"
    
    # Check dependencies
    check_dependencies
    
    # Get all email accounts
    get_email_accounts
    
    if [[ ! -f "$TEMP_FILE" || ! -s "$TEMP_FILE" ]]; then
        log_message "ERROR: No email accounts found"
        exit 1
    fi
    
    local total_accounts=0
    local warnings_sent=0
    local errors_count=0
    
    # Process each account
    while IFS=':' read -r cpanel_user email_account; do
        if [[ -n "$cpanel_user" && -n "$email_account" ]]; then
            ((total_accounts++))
            log_message "Checking: $email_account (user: $cpanel_user)"
            
            check_mailbox_usage "$cpanel_user" "$email_account"
            local result_code=$?
            
            case $result_code in
                1) ((warnings_sent++)) ;;
                2) ((errors_count++)) ;;
            esac
        fi
    done < "$TEMP_FILE"
    
    # Cleanup
    rm -f "$TEMP_FILE"
    
    # Generate summary
    log_message "Check completed. Processed: $total_accounts accounts, Warnings sent: $warnings_sent, Errors: $errors_count"
    
    echo -e "\n${GREEN}=== MAILBOX CAPACITY CHECK SUMMARY ===${NC}"
    echo -e "Total accounts checked: $total_accounts"
    echo -e "Warnings sent: ${YELLOW}$warnings_sent${NC}"
    echo -e "Errors encountered: ${RED}$errors_count${NC}"
    echo -e "Log file: $LOG_FILE"
    
    exit $errors_count
}

# Run main function
main "$@"
