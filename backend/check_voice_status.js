import twilio from "twilio";
import './loadEnv.js';

const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;
const sid = "CA5fe178e91c1427975c92e291ee405"; // Put SID here

const client = twilio(accountSid, authToken);

async function checkStatus() {
    try {
        const call = await client.calls(sid).fetch();
        console.log(`SID: ${call.sid}`);
        console.log(`Status: ${call.status}`);
        console.log(`To: ${call.to}`);
        console.log(`From: ${call.from}`);
        console.log(`Duration: ${call.duration}`);
        console.log(`Price: ${call.price} ${call.priceUnit}`);
    } catch (err) {
        console.error(`❌ Fetch failed: ${err.message}`);
    }
}

checkStatus();
