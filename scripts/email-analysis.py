# Main script that pulls everything together
import time
import logging
import os
from dotenv import load_dotenv
from email_monitor import check_mailbox
from email_processor import process_emails, analyze_email
from email_responder import generate_response, send_response

# Define paths
BASE_DIR = '/home/hpcagroup/email-security'
SAVE_DIR = os.path.join(BASE_DIR, 'data/suspicious_emails')
PROCESSED_DIR = os.path.join(BASE_DIR, 'data/processed_emails')
LOG_FILE = os.path.join(BASE_DIR, 'logs/email_monitor.log')

# Configure logging
logging.basicConfig(filename=LOG_FILE, level=logging.INFO,
                   format='%(asctime)s - %(levelname)s - %(message)s')

def main():
    """Main function to run periodically"""
    while True:
        try:
            process_emails()
            logging.info("Completed processing cycle")
        except Exception as e:
            logging.error(f"Error in main process: {e}")
        
        # Wait 5 minutes before next check
        time.sleep(300)

if __name__ == "__main__":
    logging.info("Starting email analysis service")
    main()