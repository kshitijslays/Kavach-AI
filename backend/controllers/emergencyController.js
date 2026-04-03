import User from "../models/userModel.js";
import { sendMail } from "../utils/sendMail.js";
import twilio from "twilio";
import { v2 as cloudinary } from "cloudinary";

cloudinary.config({ 
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME, 
  api_key: process.env.CLOUDINARY_API_KEY, 
  api_secret: process.env.CLOUDINARY_API_SECRET 
});

// Twilio Client Initialization
const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const twilioNumber = process.env.TWILIO_PHONE_NUMBER;
const whatsappNumber = process.env.TWILIO_WHATSAPP_NUMBER;

let client;
if (accountSid && authToken) {
  try {
    client = twilio(accountSid, authToken);
    console.log("📟 Twilio Client initialized for automated alerts.");
    console.log(`🔑 Twilio SID starts with: ${accountSid ? accountSid.substring(0, 4) : 'null'}...`);
    console.log(`🔑 Twilio Token starts with: ${authToken ? authToken.substring(0, 4) : 'null'}...`);
  } catch (error) {
    console.error("❌ Twilio SDK Init Error:", error.message);
  }
} else {
  console.log("⚠️ Twilio credentials missing in .env - alerts will be disabled.");
}

export const triggerEmergencyAlert = async (req, res) => {
  const { userId, location, message, contacts } = req.body;

  if (!location || !contacts || contacts.length === 0) {
    return res.status(400).json({ message: "Invalid emergency data: Location and contacts required." });
  }

  // Helper to ensure E.164 format
  const formatToE164 = (num) => {
    let clean = num.replace(/[^\d+]/g, '');
    if (clean === '76438352226' || clean === '+9176438352226') {
      clean = clean.replace('76438352226', '7643835226');
    }
    if (clean.length === 10 && !clean.startsWith('+')) return `+91${clean}`;
    if (clean.length === 12 && clean.startsWith('91')) return `+${clean}`;
    return clean.startsWith('+') ? clean : `+${clean}`;
  };

  try {
    const mapsLink = `https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}`;
    const fullMessage = `${message || "🚨 EMERGENCY ALERT: I may be in danger. Please check on me immediately."}\n\nMy Live Location: ${mapsLink}`;

    if (!client && accountSid && authToken) {
      client = twilio(accountSid, authToken);
    }

    if (!client) {
      console.error("❌ Twilio client not available.");
      return res.status(500).json({ message: "Twilio credentials missing or invalid." });
    }

    const results = [];

    // 1. Alerting contacts
    for (const contact of contacts) {
      const e164Number = formatToE164(contact.number);
      try {
        const sms = await client.messages.create({ body: fullMessage, from: twilioNumber, to: e164Number });
        results.push({ type: 'SMS', contact: contact.name, status: 'success', sid: sms.sid });
        console.log(`   ✅ [SMS] Sent to ${contact.name}`);
      } catch (err) {
        results.push({ type: 'SMS', contact: contact.name, status: 'error', error: err.message });
        console.error(`   ❌ [SMS] Failed for ${contact.name}:`, err.message);
      }
    }

    // 2. Primary Call
    if (contacts.length > 0) {
      const primaryE164 = formatToE164(contacts[0].number);
      try {
        const call = await client.calls.create({
          twiml: `<Response><Say voice="alice">This is an emergency alert. The user may be in danger. Check your messages for location.</Say></Response>`,
          from: twilioNumber,
          to: primaryE164
        });
        results.push({ type: 'Voice', contact: contacts[0].name, status: 'success' });
        console.log(`   📞 [VOICE] Call initiated to ${contacts[0].name}`);
      } catch (err) {
        results.push({ type: 'Voice', contact: contacts[0].name, status: 'error', error: err.message });
      }
    }

    // 3. Email Backup
    if (userId && userId.includes('@')) {
      try {
        await sendMail(userId, "🚨 Emergency Activated", `SOS triggered. Location: ${mapsLink}`);
        results.push({ type: 'Email', status: 'success' });
      } catch (err) {}
    }

    res.status(200).json({ message: "Alerts processed", results });
  } catch (error) {
    res.status(500).json({ message: "System error", error: error.message });
  }
};

export const uploadEmergencyAudio = async (req, res) => {
  const { contacts } = req.body;
  const file = req.file;

  if (!file || !contacts) {
    return res.status(400).json({ message: "Audio file and contacts required." });
  }

  let parsedContacts = [];
  try {
    parsedContacts = typeof contacts === 'string' ? JSON.parse(contacts) : contacts;
  } catch (e) {
    return res.status(400).json({ message: "Invalid contacts format." });
  }

  try {
    const b64 = Buffer.from(file.buffer).toString('base64');
    const dataURI = `data:${file.mimetype};base64,${b64}`;

    const uploadResult = await cloudinary.uploader.upload(dataURI, { resource_type: "video", folder: "emergency_audio" });
    const audioUrl = uploadResult.secure_url.replace('/upload/', '/upload/f_mp3/');

    if (!client) return res.status(500).json({ message: "Twilio uninitialized" });

    const msg = `🚨 FOLLOW UP: Emergency audio recording:\n${audioUrl}`;
    const results = [];

    for (const contact of parsedContacts) {
      const e164Number = formatToE164(contact.number);
      try {
        await client.messages.create({ body: msg, from: twilioNumber, to: e164Number });
        results.push({ contact: contact.name, status: 'success' });
      } catch (err) {
        results.push({ contact: contact.name, status: 'error', error: err.message });
      }
    }

    res.status(200).json({ message: "Audio sent", audioUrl, results });
  } catch (error) {
    res.status(500).json({ message: "Audio process failed", error: error.message });
  }
};
