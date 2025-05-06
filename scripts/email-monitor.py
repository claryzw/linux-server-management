#!/usr/bin/env python3
import imaplib
import email
import os
import logging
from datetime import datetime

# Configuration
EMAIL = ""
PASSWORD = os.environ.get("EMAIL_PASSWORD")  # Store in environment variable
IMAP_SERVER = ""
IMAP_PORT = 993  # SSL Port
SAVE_DIR = "suspicious_emails"

logging.basicConfig(filename='email-monitor.log', level=logging.INFO,
                    format='%(asctime)s - %(levelname)s - %(message)s')

def check_mailbox():
    """Connect to mailbox and check for new emails"""
    try:
        # Connect to mailbox
        mail = imaplib.IMAP4_SSL(IMAP_SERVER, IMAP_PORT)
        mail.login(EMAIL, PASSWORD)
        mail.select('inbox')
        
        # Search for unread messages
        status, messages = mail.search(None, 'UNSEEN')
        if status != 'OK':
            logging.error(f"Failed to search emails: {status}")
            return []
        
        message_ids = messages[0].split()
        new_emails = []
        
        for msg_id in message_ids:
            # Fetch email
            status, data = mail.fetch(msg_id, '(RFC822)')
            if status != 'OK':
                continue
                
            raw_email = data[0][1]
            
            # Save as .eml file
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"{SAVE_DIR}/email_{timestamp}_{msg_id.decode()}.eml"
            
            with open(filename, 'wb') as f:
                f.write(raw_email)
                
            logging.info(f"Saved new email: {filename}")
            new_emails.append(filename)
            
            # Mark as read
            mail.store(msg_id, '+FLAGS', '\\Seen')
            
        mail.logout()
        return new_emails
        
    except Exception as e:
        logging.error(f"Error checking mailbox: {e}")
        return []
