import os
import logging
import mailparser
import re
import time
from dotenv import load_dotenv
import requests

# Import functions from your other modules
from email_monitor import check_mailbox
from email_responder import send_response

# Load environment variables and set up paths
load_dotenv('/home/hpcagroup/email-security/.env')
VIRUSTOTAL_API_KEY = os.environ.get("VIRUSTOTAL_API_KEY")

# Define directory paths
BASE_DIR = '/opt/hpcagroup/email-security'
SAVE_DIR = os.path.join(BASE_DIR, 'data/suspicious_emails')
PROCESSED_DIR = os.path.join(BASE_DIR, 'data/processed_emails')

def extract_links(text):
    """Extract URLs from text using regex."""
    url_pattern = r'https?://(?:[-\w.]|(?:%[\da-fA-F]{2}))+[/?=\-&%.\w]+'
    return re.findall(url_pattern, text)

def check_virustotal(url):
    """Check a URL against VirusTotal's API (v3)."""
    # Existing check_virustotal function
    
def analyze_email(email_path):
    """Main analysis function."""
    # Existing analyze_email function

def process_emails():
    """Process all saved .eml files"""
    # Create directories if they don't exist
    os.makedirs(SAVE_DIR, exist_ok=True)
    os.makedirs("processed_emails", exist_ok=True)
    
    # Check mailbox for new emails
    new_emails = check_mailbox()
    logging.info(f"Found {len(new_emails)} new emails")
    
    # Process all emails in the directory
    for filename in os.listdir(SAVE_DIR):
        if filename.endswith('.eml'):
            email_path = os.path.join(SAVE_DIR, filename)
            
            # Analyze email using your existing code
            analysis_result = analyze_email(email_path)
            
            # Generate and send response
            if send_response(analysis_result):
                # Move to processed folder after successful response
                processed_path = os.path.join("processed_emails", filename)
                os.rename(email_path, processed_path)
                logging.info(f"Processed and moved email: {filename}")