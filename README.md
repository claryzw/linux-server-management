# linux-server-management
System administration automation scripts for CentOS/AlmaLinux with cPanel/WHM environments.

## Description
Collection of bash and Python scripts for daily Linux server management including system health monitoring, security scanning, email administration, and automated alerting. Developed for production enterprise environments.

## Prerequisites
* CentOS 7.9+ / AlmaLinux 8.10+ / RHEL 8+
* cPanel/WHM installation
* Python 3.6+
* Root/sudo access
* Basic system tools: bc, mailx, firewalld

## Installation
```
git clone https://github.com/claryzw/linux-server-management.git
cd linux-server-management
chmod +x scripts/*.sh
```

Configure email addresses and thresholds in script headers before use.

## Usage

### Daily Operations
```
# System health check
./scripts/daily_health_check.sh

# Security vulnerability scan
./scripts/security_scan.sh

# Check mailbox quotas
./scripts/mailbox_warning.sh
```

### Automated Scheduling
```
# Add to crontab for automation
0 6 * * * /path/to/scripts/daily_health_check.sh
0 */4 * * * /path/to/scripts/security_scan.sh
0 8 * * * /path/to/scripts/mailbox_warning.sh
```

## Scripts

- **`daily_health_check.sh`** - Daily system health checks (disk, memory, CPU, RAID status)
- **`security_scan.sh`** - Security vulnerability scanning and system hardening checks
- **`mailbox_warning.sh`** - Mailbox quota monitoring with automated user notifications
- **`email-analysis.py`** - Email security threat detection system
- **`email-monitor.py`** - IMAP mailbox monitoring component
- **`email-processor.py`** - Email content analysis engine
- **`email-response.py`** - Automated threat response system
- **`send_test_email.php`** - Email system functionality testing
- **`generate_email_list.sh`** - Email distribution list management

## Author
Clarence Msindo 


