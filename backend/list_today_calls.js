import twilio from "twilio";
import './loadEnv.js';

const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;

const client = twilio(accountSid, authToken);

async function listTodayCalls() {
    try {
        const today = new Date();
        today.setHours(0,0,0,0);
        console.log(`Fetching calls since ${today.toISOString()}...`);
        const calls = await client.calls.list({startTimeAfter: today, limit: 10});
        console.log(`Found ${calls.length} calls.`);
        calls.forEach(c => {
            console.log(`SID: ${c.sid}`);
            console.log(`Status: ${c.status}`);
            console.log(`To: ${c.to}`);
            console.log(`Duration: ${c.duration}s`);
            console.log(`Time: ${c.startTime}`);
            console.log(`ErrorMsg: ${c.errorMessage || 'None'}`);
            console.log("-------------------");
        });
    } catch (err) {
        console.error(`❌ List failed: ${err.message}`);
    }
}

listTodayCalls();
