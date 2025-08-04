#!/usr/bin/env php
<?php
/**
 * Weekly System Test Email Script
 * [Company Name]
 * Author: [Company Name]
 */

// Error reporting
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Constants
define('EMAIL_LIST_PATH', '');
define('LOG_FILE', '');

// Ensure log directory exists
if (!file_exists(dirname(LOG_FILE))) {
    mkdir(dirname(LOG_FILE), 0755, true);
}

// Logging function
function writeLog($message) {
    $timestamp = date('Y-m-d H:i:s');
    file_put_contents(LOG_FILE, "[$timestamp] $message\n", FILE_APPEND);
}

// Start logging
writeLog("Starting weekly system test email distribution");

// Email configuration
$config = [
    'from_email' => 'example@example.com',
    'from_name' => '[Company Name] System User',
    'subject' => 'Weekly System Test Email',
    'headers' => [
        'MIME-Version: 1.0',
        'Content-type: text/html; charset=UTF-8',
        'From: HA Group System User <example@example.com>',
        'Reply-To: example@example.com',
        'X-Mailer: PHP/' . phpversion()
    ]
];

// HTML Email message
$message = "
<html>
<head>
    <title>Weekly System Test Email</title>
</head>
<body>
    <p>This email is a routine weekly test from the system user to ensure all network and email functions are operating correctly.</p>
    <p>Please do not respond to this message.</p>
    <br>
    <p><strong>System User</strong><br>
    [Company Name]<br>
    Email: example@example.com</p>
    <hr>
    <p><small>Sent: " . date('Y-m-d H:i:s') . "<br>
    Server: " . php_uname('n') . "</small></p>
</body>
</html>";

// Check if email list exists
if (!file_exists(EMAIL_LIST_PATH)) {
    writeLog("ERROR: Email list file not found at " . EMAIL_LIST_PATH);
    die("Error: Email list file not found\n");
}

// Read email list
try {
    $users = file(EMAIL_LIST_PATH, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    writeLog("Successfully loaded " . count($users) . " email addresses");
} catch (Exception $e) {
    writeLog("ERROR: Failed to read email list: " . $e->getMessage());
    die("Error: Failed to read email list\n");
}

// Counter for successful sends
$sent_count = 0;
$failed_count = 0;

// Send emails
foreach ($users as $user_email) {
    $user_email = trim($user_email);
    
    if (filter_var($user_email, FILTER_VALIDATE_EMAIL)) {
        try {
            $sent = mail(
                $user_email,
                $config['subject'],
                $message,
                implode("\r\n", $config['headers'])
            );
            
            if ($sent) {
                $sent_count++;
                writeLog("Email sent successfully to $user_email");
            } else {
                $failed_count++;
                writeLog("Failed to send email to $user_email");
            }
        } catch (Exception $e) {
            $failed_count++;
            writeLog("ERROR sending to $user_email: " . $e->getMessage());
        }
    } else {
        writeLog("Invalid email address: $user_email");
    }
}

// Log summary
$summary = "Email distribution completed. Successfully sent: $sent_count, Failed: $failed_count";
writeLog($summary);
echo $summary . "\n";

