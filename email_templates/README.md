# Email Templates for AutoAnywhere App

This directory contains email templates for the AutoAnywhere appointment booking system.

## EmailJS Setup Instructions

### 1. Create EmailJS Account
1. Go to [https://www.emailjs.com](https://www.emailjs.com)
2. Sign up for a free account
3. Verify your email address

### 2. Create Email Service
1. In EmailJS dashboard, go to "Email Services"
2. Click "Add New Service"
3. Choose your email provider (Gmail, Outlook, etc.)
4. Follow the setup instructions
5. Note down your **Service ID**

### 3. Create Email Templates
1. Go to "Email Templates" in EmailJS dashboard
2. Create the following templates:

#### Template 1: Appointment Confirmation
- **Template ID**: `template_confirmation`
- **Subject**: `Appointment Confirmed - {{shop_name}}`
- **Content**: See `confirmation_template.html`

#### Template 2: Appointment Reminder
- **Template ID**: `template_reminder`
- **Subject**: `Appointment Reminder - {{reminder_type}} - {{shop_name}}`
- **Content**: See `reminder_template.html`

### 4. Get Public Key
1. Go to "Account" in EmailJS dashboard
2. Copy your **Public Key**

### 5. Update Configuration
1. Open `lib/core/config/email_config.dart`
2. Replace the placeholder values:
   ```dart
   static const String serviceId = 'your_actual_service_id';
   static const String publicKey = 'your_actual_public_key';
   ```

## Template Variables

All templates support these variables:
- `{{to_email}}` - Customer email address
- `{{customer_name}}` - Customer name
- `{{shop_name}}` - Shop name
- `{{shop_address}}` - Shop address
- `{{shop_phone}}` - Shop phone number
- `{{appointment_date}}` - Appointment date (DD/MM/YYYY)
- `{{appointment_time}}` - Appointment time slot
- `{{service_types}}` - List of services
- `{{estimated_cost}}` - Estimated cost
- `{{booking_id}}` - Booking ID

### Additional Variables by Template:

**Reminder Template:**
- `{{reminder_type}}` - "12 Hours" or "3 Hours"

## Testing

1. Set `isTestMode = true` in `email_config.dart`
2. Set `testEmail` to your email address
3. Run the app and book an appointment
4. Check your email for notifications

## Production Setup

1. Set `isTestMode = false` in `email_config.dart`
2. Ensure all template IDs match your EmailJS templates
3. Test with real customer emails
4. Monitor email delivery in EmailJS dashboard
