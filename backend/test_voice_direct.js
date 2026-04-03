import twilio from "twilio";
import './loadEnv.js';

const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const from = process.env.TWILIO_PHONE_NUMBER;
const to = "+917643835226"; // The contact I found in DB

if (!accountSid || !authToken || !from) {
    console.error("❌ Credentials missing in .env");
    process.exit(1);
}

const client = twilio(accountSid, authToken);

async function testVoice() {
    console.log(`Testing Voice Call to ${to}...`);
    try {
        const call = await client.calls.create({
            twiml: `<Response><Say voice="alice">Hello! This is a test call from Kavach Shield. If you hear this, your voice alerts are working correctly.</Say></Response>`,
            from: from,
            to: to
        });
        console.log(`✅ Voice Call Initiated! SID: ${call.sid}`);
        console.log(`ℹ️ Status: ${call.status}`);
    } catch (err) {
        console.error(`❌ Voice Call Failed: ${err.message}`);
        if (err.message.includes("not verified")) {
            console.log("💡 TIP: Recipient must be a Verified Caller ID for Trial accounts.");
        }
    }
}

testVoice();
