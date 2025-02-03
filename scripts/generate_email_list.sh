#!/bin/bash

# Script: generate_email_list.sh
# Purpose: Generate and maintain email lists for HA Group
# Author: Clarence Msindo
# Date: January 2025

# Set script variables
SCRIPT_DIR=""
OUTPUT_DIR=""
LOG_DIR=""
DATE=$(date +%Y%m%d)

# Create necessary directories if they don't exist
mkdir -p "$SCRIPT_DIR"
mkdir -p "$OUTPUT_DIR"
mkdir -p "$LOG_DIR"

# Log file
LOG_FILE="$LOG_DIR/email_list_generator_$DATE.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Start logging
log_message "Starting email list generation"

# Create email lists directory with proper permissions
mkdir -p "$OUTPUT_DIR"
chmod 755 "$OUTPUT_DIR"

# Generate the all users list
cat > "$OUTPUT_DIR/all_users.txt" << EOL
EOL

# Set proper permissions
chmod 644 "$OUTPUT_DIR/all_users.txt"

# Generate admin list
grep -E "" "$OUTPUT_DIR/all_users.txt" > "$OUTPUT_DIR/admin_list.txt"
chmod 644 "$OUTPUT_DIR/admin_list.txt"

# Log completion
log_message "Email lists generated successfully"

# Output summary
echo "Email lists generated at $OUTPUT_DIR:"
ls -l "$OUTPUT_DIR"
