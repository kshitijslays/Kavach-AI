import twilio from "twilio";
import './backend/loadEnv.js';

const accountSid = process.env.TWILIO_ACCOUNT_SID;
const authToken = process.env.TWILIO_AUTH_TOKEN;

const client = twilio(accountSid, authToken);

async function listTodayMessages() {
    try {
        const today = new Date();
        today.setHours(0,0,0,0);
        console.log(`\n📋 Fetching SMS messages since ${today.toISOString()}...`);
        
        const messages = await client.messages.list({dateSentAfter: today, limit: 10});
        console.log(`Found ${messages.length} messages.`);
        
        messages.forEach(m => {
            console.log(`SID: ${m.sid}`);
            console.log(`Status: ${m.status}`);
            console.log(`To: ${m.to}`);
            console.log(`Body: ${m.body.substring(0, 50)}...`);
            console.log(`ErrorMsg: ${m.errorMessage || 'None'}`);
            console.log("-------------------");
        });
    } catch (err) {
        console.error(`❌ SMS List failed: ${err.message}`);
    }
}

listTodayMessages();
