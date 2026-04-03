import twilio from "twilio";
import './loadEnv.js';

const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;

const client = twilio(accountSid, authToken);

async function listRecentCalls() {
    try {
        console.log("Fetching recent calls...");
        const calls = await client.calls.list({limit: 5});
        calls.forEach(c => {
            console.log(`SID: ${c.sid}`);
            console.log(`To: ${c.to}`);
            console.log(`Status: ${c.status}`);
            console.log(`ErrorMsg: ${c.errorMessage || 'None'}`);
            console.log("-------------------");
        });
    } catch (err) {
        console.error(`❌ List failed: ${err.message}`);
    }
}

listRecentCalls();
