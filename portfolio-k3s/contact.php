<?php
/**
 * Contact Form Handler (Optional Server-Side Processing)
 * For users who prefer server-side form processing
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

// Configuration
$to = 'TawfiqulBari@gmail.com';
$subject_prefix = 'Portfolio Contact: ';

// Get JSON input
$json = file_get_contents('php://input');
$data = json_decode($json, true);

// Validate required fields
$required_fields = ['name', 'email', 'subject', 'message'];
foreach ($required_fields as $field) {
    if (empty($data[$field])) {
        echo json_encode(['success' => false, 'message' => "Field '{$field}' is required"]);
        exit;
    }
}

// Sanitize inputs
$name = filter_var($data['name'], FILTER_SANITIZE_STRING);
$email = filter_var($data['email'], FILTER_SANITIZE_EMAIL);
$company = isset($data['company']) ? filter_var($data['company'], FILTER_SANITIZE_STRING) : 'Not specified';
$subject = filter_var($data['subject'], FILTER_SANITIZE_STRING);
$message = filter_var($data['message'], FILTER_SANITIZE_STRING);

// Validate email
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(['success' => false, 'message' => 'Invalid email address']);
    exit;
}

// Prepare email
$email_subject = $subject_prefix . ucfirst($subject);
$email_body = "
New contact form submission:

Name: {$name}
Email: {$email}
Company: {$company}
Subject: {$subject}

Message:
{$message}

---
Sent from: Portfolio Website
IP Address: {$_SERVER['REMOTE_ADDR']}
User Agent: {$_SERVER['HTTP_USER_AGENT']}
Date: " . date('Y-m-d H:i:s') . "
";

$headers = [
    'From: ' . $email,
    'Reply-To: ' . $email,
    'X-Mailer: PHP/' . phpversion(),
    'Content-Type: text/plain; charset=UTF-8'
];

// Send email
if (mail($to, $email_subject, $email_body, implode("\r\n", $headers))) {
    echo json_encode([
        'success' => true, 
        'message' => 'Thank you for your message! I will get back to you soon.'
    ]);
} else {
    echo json_encode([
        'success' => false, 
        'message' => 'Sorry, there was an error sending your message. Please try again.'
    ]);
}
?>
