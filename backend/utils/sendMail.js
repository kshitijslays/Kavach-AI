import nodemailer from "nodemailer";
import dotenv from "dotenv";

dotenv.config();

// Validate email configuration
if (!process.env.MAIL_USER || !process.env.MAIL_PASS) {
  console.error("❌ Email credentials not configured properly");
  console.error("MAIL_USER:", process.env.MAIL_USER ? "✅ Set" : "❌ Not set");
  console.error("MAIL_PASS:", process.env.MAIL_PASS ? "✅ Set" : "❌ Not set");
}

const transporter = nodemailer.createTransport({
  service: "gmail",
  host: "smtp.gmail.com",
  port: 587,
  secure: false, // Use TLS
  auth: {
    user: process.env.MAIL_USER,
    pass: process.env.MAIL_PASS,
  },
  tls: {
    rejectUnauthorized: false
  }
});

// Verify transporter configuration
transporter.verify((error, success) => {
  if (error) {
    console.error("❌ Email transporter verification failed:", error.message);
  } else {
    console.log("✅ Email server is ready to send messages");
  }
});

export const sendMail = async (to, subject, text, html = null) => {
  try {
    console.log(`📧 Attempting to send email to: ${to}`);
    console.log(`📧 Subject: ${subject}`);
    
    const mailOptions = {
      from: `"Kavach App" <${process.env.MAIL_USER}>`,
      to,
      subject,
      text,
      ...(html && { html }),
    };
    
    const info = await transporter.sendMail(mailOptions);
    console.log("✅ Email sent successfully:", info.messageId);
    console.log("✅ Response:", info.response);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error("❌ Email failed to send:", error.message);
    console.error("❌ Full error:", error);
    throw error; // Re-throw so the calling function knows it failed
  }
};
