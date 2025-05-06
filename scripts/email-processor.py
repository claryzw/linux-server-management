#!/usr/bin/env python3
import os, re, logging
from mailparser import parse_from_file, parse_from_string
from email_response import calculate_threat_level
def virus_total_check(url):                      
    return {"malicious": 0, "suspicious": 0}     

def extract_links(text):
    pattern = r'https?://(?:[-\w.]|(?:%[\da-fA-F]{2}))+[/?=\-&%.\w]+'
    return re.findall(pattern, text or "")

def analyze_email(email_path):
    try:
        if not os.path.exists(email_path):
            logging.error("File not found: %s", email_path)
            return {"error": "File not found"}

        p = parse_from_file(email_path)

        # --- bodies ---------------------------------------------------------
        text_body = "".join(p.text_plain) if isinstance(p.text_plain, list) else (p.text_plain or "")
        html_body = "".join(p.text_html)  if isinstance(p.text_html,  list) else (p.text_html  or "")

        # --- forwarded mail handling ----------------------------------------
        if "Forwarded message" in text_body:
            fwd = parse_from_string(text_body.split("Forwarded message", 1)[-1])
            original = fwd.from_[0][1] if fwd.from_ else "unknown"
        else:
            original = p.from_[0][1] if p.from_ else "unknown"

        analysis = {                         # <-- build dict FIRST
            "original_sender": original,
            "subject"        : p.subject,
            "links"          : sorted(set(extract_links(text_body) + extract_links(html_body))),
            "attachments"    : [att["filename"] for att in p.attachments if att.get("filename")],
            "email_body"     : text_body,
        }

        # --- VirusTotal ------------------------------------------------------
        vt = {}
        for url in analysis["links"]:
            stats = virus_total_check(url)
            vt[url] = {"malicious": int(stats.get("malicious", 0)),
                       "suspicious": int(stats.get("suspicious", 0))}
        analysis["virus_total_results"] = vt

        # --- threat level ----------------------------------------------------
        analysis["threat_level"] = calculate_threat_level(analysis)

        # --- debug log -------------------------------------------------------
        logging.info("Threat calc %s - links:%d att:%d level:%s",
                     email_path,
                     len(analysis["links"]),
                     len(analysis["attachments"]),
                     analysis["threat_level"])
        return analysis

    except Exception as e:
        logging.error("Analysis failed for %s: %s", email_path, e)
        return {"error": str(e)}

def process_emails(email_path):
    analysis = analyze_email(email_path)
    if analysis and not analysis.get("error"):
        from email_response import send_response
        if analysis.get("original_sender"):        # fixed key
            send_response(analysis)
        return True
    return False
