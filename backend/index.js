import "./loadEnv.js";
import express from "express";
import cors from "cors";
import mongoose from "mongoose";
import connectDB from "./config/db.js";
import authRoutes from "./routes/authRoutes.js";
import emergencyRoutes from "./routes/emergencyRoutes.js";
import fs from "fs";
import path from "path";

// Connect to database (but don't fail if connection fails)
connectDB();

const app = express();

// CORS configuration for development
app.use(cors({ 
  origin: true, // This will reflect the request origin
  credentials: true 
}));

app.use(express.json());

// 🔍 Global request logger - shows every incoming HTTP request
app.use((req, res, next) => {
  const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
  console.log(`📡 [${new Date().toLocaleTimeString()}] ${req.method} ${req.path} from ${clientIp}`);
  next();
});

// Health check endpoint
app.get("/api/health", (req, res) => {
  res.json({ 
    status: "OK", 
    message: "Server is running",
    timestamp: new Date().toISOString(),
    mongoStatus: mongoose.connection.readyState === 1 ? "connected" : "disconnected"
  });
});

// Debug endpoint to check stored OTPs (development only)
app.get("/api/debug/otps", (req, res) => {
  const otps = {};
  if (global.tempOTPs) {
    for (const [email, data] of Object.entries(global.tempOTPs)) {
      otps[email] = {
        otp: data.otp,
        expiresAt: new Date(data.otpExpiry).toLocaleString(),
        isExpired: data.otpExpiry < Date.now()
      };
    }
  }
  res.json({ 
    message: "Stored OTPs (development debug)",
    otps: otps,
    totalCount: Object.keys(otps).length
  });
});

// Serve OTP tester page (development only)
app.get("/test", (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html>
    <head><title>OTP Tester</title></head>
    <body>
        <h1>🧪 OTP Flow Tester</h1>
        <div>
            <h3>📤 Step 1: Send OTP</h3>
            <input type="email" id="emailInput" placeholder="Enter email" value="shagunbhardwajranchi123@gmail.com" style="width: 300px; padding: 5px;">
            <button onclick="sendOTP()" style="padding: 5px 10px;">Send OTP</button>
            <div id="sendResult"></div>
        </div>
        <div>
            <h3>✅ Step 2: Verify OTP</h3>
            <input type="text" id="otpInput" placeholder="Enter 6-digit OTP" maxlength="6" style="width: 200px; padding: 5px;">
            <button onclick="verifyOTP()" style="padding: 5px 10px;">Verify OTP</button>
            <div id="verifyResult"></div>
        </div>
        <div>
            <h3>🔍 Debug: Check Stored OTPs</h3>
            <button onclick="checkOTPs()" style="padding: 5px 10px;">Check Stored OTPs</button>
            <div id="debugResult"></div>
        </div>
        <script>
            const API_BASE = 'http://localhost:5000/api';
            async function sendOTP() {
                const email = document.getElementById('emailInput').value;
                const result = document.getElementById('sendResult');
                try {
                    const response = await fetch(API_BASE + '/auth/send-otp', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ email })
                    });
                    const data = await response.json();
                    result.innerHTML = '<p style="color: ' + (response.ok ? 'green' : 'red') + '">' + data.message + '</p>';
                    if (response.ok) setTimeout(checkOTPs, 1000);
                } catch (error) {
                    result.innerHTML = '<p style="color: red">Error: ' + error.message + '</p>';
                }
            }
            async function verifyOTP() {
                const email = document.getElementById('emailInput').value;
                const otp = document.getElementById('otpInput').value;
                const result = document.getElementById('verifyResult');
                try {
                    const response = await fetch(API_BASE + '/auth/verify-otp', {
                        method: 'POST',
                        headers: { 'Content-Type': 'application/json' },
                        body: JSON.stringify({ email, otp, name: "Test User" })
                    });
                    const data = await response.json();
                    result.innerHTML = '<p style="color: ' + (response.ok ? 'green' : 'red') + '">' + data.message + '</p>';
                    if (response.ok) result.innerHTML += '<p>User: ' + JSON.stringify(data.user) + '</p>';
                } catch (error) {
                    result.innerHTML = '<p style="color: red">Error: ' + error.message + '</p>';
                }
            }
            async function checkOTPs() {
                const result = document.getElementById('debugResult');
                try {
                    const response = await fetch(API_BASE + '/debug/otps');
                    const data = await response.json();
                    let html = '<h4>Stored OTPs (' + data.totalCount + '):</h4>';
                    for (const [email, otpData] of Object.entries(data.otps)) {
                        html += '<p><strong>' + email + ':</strong> OTP=' + otpData.otp + ', Expires=' + otpData.expiresAt + ', Expired=' + otpData.isExpired + '</p>';
                    }
                    result.innerHTML = html;
                } catch (error) {
                    result.innerHTML = '<p style="color: red">Error: ' + error.message + '</p>';
                }
            }
        </script>
    </body>
    </html>
  `);
});

// Auth routes
app.use("/api/auth", authRoutes);

// Emergency routes 🚨
app.use("/api/emergency", emergencyRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error("Error:", err.message);
  res.status(500).json({ 
    message: "Server error", 
    error: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
  });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server is running on http://0.0.0.0:${PORT}`);
  console.log(`📧 Email configured: ${process.env.MAIL_USER ? '✅' : '❌'}`);
  console.log(`🔗 Health check: http://localhost:${PORT}/api/health`);
});
