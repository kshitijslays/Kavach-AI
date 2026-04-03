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

async function testSMS() {
    console.log(`Testing SMS to ${to}...`);
    try {
        const message = await client.messages.create({
            body: "🚨 Kavach Test Alert: If you see this, Twilio is working!",
            from: from,
            to: to
        });
        console.log(`✅ SMS Sent! SID: ${message.sid}`);
    } catch (err) {
        console.error(`❌ SMS Failed: ${err.message}`);
        if (err.message.includes("unverified")) {
            console.log("💡 TIP: This number must be verified in your Twilio Console (Trial Account).");
        }
    }
}

testSMS();
