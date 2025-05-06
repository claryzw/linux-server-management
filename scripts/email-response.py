def calculate_threat_level(analysis):
    """Determine threat level from analysis results"""
    score = 0
    
    # Check for malicious links
    for url, stats in analysis.get('virus_total_results', {}).items():
        score += stats.get('malicious', 0) * 10
        score += stats.get('suspicious', 0) * 5
    
    # Check for suspicious keywords
    suspicious_terms = ["urgent", "payment", "verify", "account", "password", 
                        "login", "bank", "invoice", "transaction", "swift"]
    for term in suspicious_terms:
        if term.lower() in analysis.get('email_body', '').lower():
            score += 3
    
    # Check for risky attachments
    risky_extensions = ['.exe', '.zip', '.js', '.vbs', '.bat', '.docm', '.xlsm']
    for attachment in analysis.get('attachments', []):
        if any(attachment.lower().endswith(ext) for ext in risky_extensions):
            score += 15
        else:
            score += 3
    
    # Determine level
    if score >= 20:
        return "High"
    elif score >= 10:
        return "Medium"
    else:
        return "Low"

def generate_response(analysis):
    """Create appropriate response based on threat level"""
    threat_level = analysis.get('threat_level', 'Unknown')
    subject = analysis.get('subject', '')
    
    if threat_level == "High":
        response_body = f"""
Subject: [HIGH RISK] Analysis of Forwarded Email

Hello,

We've analyzed the email you forwarded and identified it as HIGH RISK.

🚨 THREAT ANALYSIS:
- Multiple security concerns detected
- {len(analysis.get('virus_total_results', {}))} potentially malicious links
- {len(analysis.get('attachments', []))} attachments that may contain malware

⚠️ RECOMMENDED ACTIONS:
1. DO NOT respond to the sender
2. DO NOT click any links or download attachments
3. DELETE the email immediately

HA Group
"""
    elif threat_level == "Medium":
        # Medium risk template
        response_body = """
Subject: [CAUTION] Analysis of Forwarded Email

Hello,

We've analyzed the email you forwarded and identified it as POTENTIALLY RISKY.

⚠️ CAUTION:
- Some suspicious elements detected
- Exercise caution with any links or attachments

🛡️ RECOMMENDED ACTIONS:
1. Verify the sender through another channel before taking any action
2. Do not click links or download attachments unless absolutely necessary

HA Group
"""
    else:
        # Low risk template
        response_body = """
Subject: Analysis of Forwarded Email

Hello,

We've analyzed the email you forwarded. It appears to be LOW RISK but we always recommend caution.

📊 ANALYSIS:
- No major security threats detected
- Always remain vigilant with unexpected emails

HA Group
"""
    
    return response_body