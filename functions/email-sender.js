const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

// EmailJS configuration
const EMAILJS_SERVICE_ID = 'your_service_id';
const EMAILJS_TEMPLATE_ID = 'your_template_id';
const EMAILJS_PUBLIC_KEY = 'your_public_key';
const EMAILJS_USER_ID = 'your_user_id';

// Create email transporter
const transporter = nodemailer.createTransporter({
  service: 'gmail', // or your email service
  auth: {
    user: 'your-email@gmail.com',
    pass: 'your-app-password'
  }
});

exports.sendAppointmentConfirmation = functions.https.onCall(async (data, context) => {
  try {
    const { customerEmail, customerName, shopName, appointmentDate, appointmentTime, serviceTypes, estimatedCost, bookingId } = data;
    
    const mailOptions = {
      from: 'noreply@autoanywhere.com',
      to: customerEmail,
      subject: `Appointment Confirmed - ${shopName}`,
      html: `
        <h2>Appointment Confirmed!</h2>
        <p>Dear ${customerName},</p>
        <p>Your appointment has been successfully confirmed.</p>
        
        <h3>Appointment Details:</h3>
        <ul>
          <li><strong>Shop:</strong> ${shopName}</li>
          <li><strong>Date:</strong> ${appointmentDate}</li>
          <li><strong>Time:</strong> ${appointmentTime}</li>
          <li><strong>Services:</strong> ${serviceTypes}</li>
          <li><strong>Cost:</strong> $${estimatedCost}</li>
          <li><strong>Booking ID:</strong> ${bookingId}</li>
        </ul>
        
        <p>Thank you for choosing AutoAnywhere!</p>
      `
    };
    
    await transporter.sendMail(mailOptions);
    return { success: true };
  } catch (error) {
    console.error('Error sending email:', error);
    return { success: false, error: error.message };
  }
});

exports.sendAppointmentReminder = functions.https.onCall(async (data, context) => {
  try {
    const { customerEmail, customerName, shopName, appointmentDate, appointmentTime, reminderType } = data;
    
    const mailOptions = {
      from: 'noreply@autoanywhere.com',
      to: customerEmail,
      subject: `Appointment Reminder - ${reminderType} - ${shopName}`,
      html: `
        <h2>Appointment Reminder</h2>
        <p>Dear ${customerName},</p>
        <p>This is a ${reminderType} reminder for your upcoming appointment.</p>
        
        <h3>Appointment Details:</h3>
        <ul>
          <li><strong>Shop:</strong> ${shopName}</li>
          <li><strong>Date:</strong> ${appointmentDate}</li>
          <li><strong>Time:</strong> ${appointmentTime}</li>
        </ul>
        
        <p>See you soon!</p>
      `
    };
    
    await transporter.sendMail(mailOptions);
    return { success: true };
  } catch (error) {
    console.error('Error sending reminder email:', error);
    return { success: false, error: error.message };
  }
});
