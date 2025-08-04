# **HA Group Linux Server Management**  
### **Administrator:** Clarence Msindo  
### **Role:** ICT Shared Services Lead  
### **Date:** Last Updated: 2025-08-04  
---

## **Overview**  
This document outlines the system administration automation scripts and tools developed for **HA Group** enterprise infrastructure. These scripts provide comprehensive server management, security monitoring, and email administration capabilities for AlmaLinux/CentOS environments with cPanel/WHM hosting platforms.

---

## **Responsibilities & Tasks**  

### **1. Server Maintenance & Monitoring**  
- Deploy automated daily health check scripts monitoring disk usage, memory, CPU load, and RAID status.  
- Implement system performance monitoring using standard Linux tools (`top`, `htop`, `df`, `free`).  
- Configure automated email reporting for critical system events and threshold breaches.  
- Maintain AlmaLinux/CentOS servers with DNF/YUM package management and security updates.  

### **2. User & Permission Management**  
- Develop cPanel/WHM integration scripts for email account management and quota monitoring.  
- Implement automated mailbox capacity warnings with dual-threshold alerting system (90% warning, 98% critical).  
- Create email list generation and management automation tools.  
- Deploy user notification systems with HTML email templates and delivery tracking.  

### **3. Security Hardening**  
- Build comprehensive security scanning automation with DNF-based update detection.  
- Implement failed login attempt monitoring and firewall status verification.  
- Deploy system file integrity checking using MD5 hash verification for critical files.  
- Create automated security alerting for dangerous port exposure and suspicious activity.  
- Develop email security analysis framework with threat detection and scoring algorithms.  

### **4. Backup & Disaster Recovery**  
- Configure RAID monitoring scripts for enterprise storage arrays (md126, md127).  
- Implement automated backup verification and system restoration procedures.  
- Document recovery processes with logging and email notification systems.  

### **5. Network & Service Configuration**  
- Manage cPanel/WHM hosting environment through automation scripts.  
- Configure SSL/TLS email services monitoring and delivery verification.  
- Deploy DNS resolver management and mail server optimization tools.  
- Implement spam prevention and email delivery troubleshooting automation.  

### **6. Automation & Scripting**  
- Develop Bash automation scripts for system health monitoring and security scanning.  
- Create Python-based email security analysis suite with IMAP monitoring and threat response.  
- Build PHP email testing and delivery verification systems for weekly validation.  
- Implement comprehensive logging systems with automated log rotation and cleanup.  
- Deploy cron job scheduling for automated maintenance tasks and monitoring cycles.  

### **7. Documentation & Reporting**  
- Maintain version-controlled script repository with comprehensive documentation.  
- Generate automated system health reports with performance metrics and security status.  
- Document security scan results and vulnerability assessment procedures.  
- Create troubleshooting guides and standard operating procedures for common issues.  
- Implement change tracking and configuration management for all automation tools.  

---

## **Automation Scripts Developed**  

### **System Administration Scripts**
- **`daily_health_check.sh`** - Comprehensive daily system monitoring (disk, memory, CPU, RAID, cPanel services)
- **`security_scan.sh`** - Security vulnerability scanning with DNF updates, firewall checks, and file integrity verification  
- **`mailbox_warning.sh`** - Advanced mailbox quota monitoring with cPanel UAPI integration and automated user notifications

### **Email Security & Management Suite**  
- **`email-analysis.py`** - Main coordination engine for email security threat detection
- **`email-monitor.py`** - IMAP mailbox monitoring with SSL/TLS connectivity and suspicious email detection
- **`email-processor.py`** - Email content analysis with VirusTotal integration and attachment risk assessment
- **`email-response.py`** - Automated threat response system with risk-scoring algorithms and SMTP delivery

### **Utility & Testing Scripts**
- **`send_test_email.php`** - Weekly email system functionality testing with HTML templates and delivery confirmation
- **`generate_email_list.sh`** - Email distribution list management with proper permissions and logging

---

## **Proof of Work**  
- **Script Repository:** Production-ready automation scripts deployed in `/usr/local/sbin/` and `/usr/local/scripts/` following Linux filesystem hierarchy standards.  
- **Comprehensive Logging:** All scripts implement detailed logging to `/var/log/` with timestamp tracking and error handling.  
- **Email Integration:** Full cPanel UAPI integration for mailbox management with automated threshold-based alerting.  
- **Security Framework:** Multi-layer security monitoring including failed login detection, firewall verification, and system file integrity checking.  
- **Error Handling:** Robust error handling and dependency checking across all automation scripts.  
- **Production Testing:** Scripts include comprehensive testing procedures and validation mechanisms.  
- **Documentation:** Detailed inline documentation and configuration guides for all automation tools.  

---

## **Technical Environment**  
- **Operating Systems:** AlmaLinux 8.10+ / CentOS 7.9+ / RHEL 8+ with ELevate migration support  
- **Control Panel:** cPanel/WHM with UAPI integration for email and hosting management  
- **Package Management:** DNF (AlmaLinux/RHEL 8+) and YUM (CentOS 7.x) with security update automation  
- **Email Services:** IMAP/POP3/SMTP with SSL/TLS encryption and automated delivery testing  
- **Security Tools:** firewalld, fail2ban integration, MD5 file integrity verification  
- **Scripting Languages:** Bash, Python 3.6+, PHP 7.4+ with comprehensive error handling  
- **Automation:** Cron-based scheduling with automated reporting and alerting systems  

---

## **Configuration Management**  
- **Template-Based Deployment:** Scripts utilize placeholder values requiring customization for specific environments  
- **Modular Architecture:** Email security suite designed with separate monitoring, processing, and response components  
- **Environment Variables:** Secure credential management using environment variables and configuration files  
- **Threshold Management:** Configurable alerting thresholds for system monitoring and security scanning  
- **Log Management:** Automated log rotation with configurable retention policies (30-day default)  

---

## **Contact**  
For any issues, verification, or system administration inquiries:  
- **Email:** [Internal company email system]  
- **Role:** ICT Shared Services Lead  
- **Repository:** Available for configuration and deployment guidance  

---

This **README.md** provides transparency and accountability for enterprise system administration automation development. Scripts are designed as production-ready templates requiring environment-specific configuration before deployment.

