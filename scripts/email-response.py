import smtplib
import logging
import os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from dotenv import load_dotenv

# Load environment variables
load_dotenv('/home/hpcagroup/email-security/.env')
EMAIL = "suspicious@hpcagroup.africa"
PASSWORD = os.environ.get("EMAIL_PASSWORD")

# ---------------------------------------------------------------------------
# ➊  RISK-SCORING CONSTANTS 
# ---------------------------------------------------------------------------
SUSPICIOUS_TERMS = [
    # finance / urgency
    "advance payment", "payment", "invoice", "swift", "tt copy", "bank",
    "urgent", "immediately", "account", "verify", "update details",
    # social-engineering phrases
    "request", "kindly", "dear sir", "dear madam", "beneficiary",
]
KEYWORD_WEIGHT  = 6   # per keyword hit

risky_extensions = [
    ".exe", ".js", ".vbs", ".bat", ".cmd", ".scr",          # executables / scripts
    ".zip", ".rar", ".7z",                                   # compressed payloads
    ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx", ".rtf",
    ".docm", ".xlsm", ".pptm"                                # macro-enabled Office
]
ATTACH_WEIGHT  = 25  # per risky attachment

HIGH_THRESHOLD   = 12   # score ≥ HIGH_THRESHOLD   →  "High"
MEDIUM_THRESHOLD = 6    # score ≥ MEDIUM_THRESHOLD →  "Medium"
# ---------------------------------------------------------------------------


def calculate_threat_level(analysis):
    score = 0
    
    # URL scoring
    for url, stats in analysis.get('virus_total_results', {}).items():
        score += stats.get('malicious', 0) * 8  # Increased weight
        score += stats.get('suspicious', 0) * 3

    # Keyword scoring
    email_lower = analysis.get("email_body", "").lower()
    for term in SUSPICIOUS_TERMS:
        if term in email_lower:
            score += KEYWORD_WEIGHT

    # Attachment scoring
    for attachment in analysis.get('attachments', []):
        if any(attachment.lower().endswith(ext) for ext in risky_extensions):
            score += ATTACH_WEIGHT  # High risk for any risky attachment

    # Adjusted thresholds
    if score >= HIGH_THRESHOLD:
        return "High"
    elif score >= MEDIUM_THRESHOLD:
        return "Medium"
    else:
        return "Low"

def generate_response(analysis):
    """Create appropriate response based on threat level"""
    threat_level = analysis.get('threat_level', 'Unknown')
    subject = analysis.get('subject', '')
    
    if threat_level == "High":
        return f"""Subject: [HIGH RISK] Analysis of Forwarded Email

Hello,

We've analyzed the email you forwarded and identified it as HIGH RISK.

ЁЯЪи THREAT ANALYSIS:
- Multiple security concerns detected
- {len(analysis.get('virus_total_results', {}))} potentially malicious links
- {len(analysis.get('attachments', []))} suspicious attachments

тЪая╕П RECOMMENDED ACTIONS:
1. DO NOT respond to the sender
2. DO NOT click any links
3. DELETE the email immediately

HA Group
"""
    elif threat_level == "Medium":
        return """Subject: [CAUTION] Analysis of Forwarded Email

Hello,

We've analyzed the email you forwarded and identified it as POTENTIALLY RISKY.

тЪая╕П CAUTION:
- Some suspicious elements detected
- Exercise caution with any links or attachments

ЁЯЫбя╕П RECOMMENDED ACTIONS:
1. Verify the sender through another channel
2. Avoid clicking links or downloading attachments

HA Group
"""
    else:
        return """Subject: Analysis of Forwarded Email

Hello,

We've analyzed the email you forwarded. It appears to be LOW RISK.

ЁЯУК ANALYSIS:
- No major security threats detected
- Remain vigilant with unexpected emails

HA Group
"""

def send_response(analysis):
    """Send email response based on analysis"""
    smtp_server = "mail.hpcagroup.africa"
    smtp_port = 465  # SSL Port
    
    msg = MIMEMultipart()
    msg['From'] = EMAIL
    msg['To'] = analysis.get('original_sender', '')
    msg['Subject'] = f"Analysis of Forwarded Email: {analysis.get('subject', '')}"
    
    response_body = generate_response(analysis)
    msg.attach(MIMEText(response_body, 'plain'))
    
    try:
        with smtplib.SMTP_SSL(smtp_server, smtp_port) as server:
            server.login(EMAIL, PASSWORD)
            server.send_message(msg)
        logging.info("Response email sent successfully")
        return True
    except smtplib.SMTPAuthenticationError:
        logging.error("SMTP authentication failed. Check .env credentials")
        return False
    except smtplib.SMTPConnectError:
        logging.error("Failed to connect to SMTP server. Check server/port")
        return False
    except Exception as e:
        logging.error(f"Generic error: {str(e)}")
        return False
