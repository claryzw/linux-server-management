#!/bin/bash
# Mailbox Capacity Warning Script for HA Group
# Revised: 29 April 2025
# Author: Clarence Msindo

# Configuration
LOG_FILE="/var/log/mailbox_warnings.log"
ADMIN_EMAIL="server_admin@hpcagroup.africa"
declare -A THRESHOLDS=([90]=WARNING [98]=CRITICAL)

# Function to log messages with current timestamp
log_message() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $1" >> "$LOG_FILE"
}

# Check dependencies
if ! command -v bc >/dev/null 2>&1; then
    echo "ERROR: bc calculator is required but not installed" >&2
    exit 1
fi

# Initialize log file
touch "$LOG_FILE" || { echo "Cannot write to log file: $LOG_FILE" >&2; exit 1; }

log_message "Starting mailbox capacity check"

# Get list of all email accounts
EMAIL_ACCOUNTS=$(uapi --user=root Email list_pops | awk '/email:/ {print $2}')
if [ -z "$EMAIL_ACCOUNTS" ]; then
    log_message "ERROR: No email accounts found"
    exit 1
fi

# Process each email account once
for EMAIL in $EMAIL_ACCOUNTS; do
    # Get mailbox usage information
    USAGE_INFO=$(uapi --user=root Email get_disk_usage email="$EMAIL")
    SIZE=$(echo "$USAGE_INFO" | awk '/diskused:/ {print $2}')
    QUOTA=$(echo "$USAGE_INFO" | awk '/diskquota:/ {print $2}')

    # Validate numeric values
    if [[ ! "$SIZE" =~ ^[0-9]+$ ]] || [[ ! "$QUOTA" =~ ^[0-9]+$ ]]; then
        log_message "ERROR: Invalid size/quota for $EMAIL (S: $SIZE, Q: $QUOTA)"
        continue
    fi

    # Handle unlimited quota accounts
    if [ "$QUOTA" -eq 0 ]; then
        log_message "INFO: $EMAIL has unlimited quota"
        continue
    fi

    # Calculate usage
    PERCENT=$(echo "scale=2; ($SIZE/$QUOTA)*100" | bc)
    PERCENT_INT=${PERCENT%.*}
    SIZE_MB=$(echo "scale=2; $SIZE/1024/1024" | bc)
    QUOTA_MB=$(echo "scale=2; $QUOTA/1024/1024" | bc)

    log_message "Checking $EMAIL: $PERCENT_INT% used ($SIZE_MB MB of $QUOTA_MB MB)"

    # Determine if any threshold is crossed
    CURRENT_SEVERITY=""
    for threshold in $(echo "${!THRESHOLDS[@]}" | tr ' ' '\n' | sort -nr); do
        if [ "$PERCENT_INT" -ge "$threshold" ]; then
            CURRENT_SEVERITY="${THRESHOLDS[$threshold]}"
            break
        fi
    done

    # Skip processing if no threshold crossed
    [ -z "$CURRENT_SEVERITY" ] && continue

    # Prepare email content based on severity
    case $CURRENT_SEVERITY in
        CRITICAL)
            SUBJECT="URGENT: Your HA Group email mailbox is critically full"
            PRIORITY="-a 'X-Priority: 1'"
            ACTION_LINES=(
                "URGENT NOTIFICATION: Your email mailbox ($EMAIL) has reached $PERCENT_INT% of its capacity."
                "Your mailbox is CRITICALLY FULL and you will STOP RECEIVING EMAILS very soon unless immediate action is taken."
                "Please take IMMEDIATE action:"
            )
            ;;
        WARNING)
            SUBJECT="ACTION REQUIRED: Your HA Group email mailbox is nearly full"
            PRIORITY=""
            ACTION_LINES=(
                "This is an automated notification to inform you that your email mailbox ($EMAIL) has reached $PERCENT_INT% of its capacity."
                "To ensure you continue to receive emails without interruption, please take one of the following actions:"
            )
            ;;
    esac

    # Common email body template
    EMAIL_BODY="Dear HA Group Email User,

${ACTION_LINES[0]}
${ACTION_LINES[1]}
${ACTION_LINES[2]:-}

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
ICT Shared Services Team
HA Group"

    # Send email
    if echo "$EMAIL_BODY" | mail -s "$SUBJECT" $PRIORITY "$EMAIL" -c "$ADMIN_EMAIL"; then
        log_message "$CURRENT_SEVERITY: Warning email sent to $EMAIL"
    else
        log_message "ERROR: Failed to send email to $EMAIL"
    fi
done

log_message "Mailbox capacity check completed"
exit 0