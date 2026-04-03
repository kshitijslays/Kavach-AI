// Using native fetch
async function testAuth() {
  const baseUrl = 'http://localhost:5000/api/auth';
  const email = 'testuser123@example.com';
  const password = 'securepassword123';
  const name = 'Test User';
  
  console.log("1. Sending OTP to", email);
  let res = await fetch(`${baseUrl}/send-otp`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email })
  });
  let data = await res.json();
  console.log("Send OTP Response:", data);

  // We need the OTP from the memory store to verify it
  console.log("\n2. Fetching debug OTPs...");
  let debugRes = await fetch('http://localhost:5000/api/debug/otps');
  let debugData = await debugRes.json();
  const otp = debugData.otps[email]?.otp;
  console.log("Found OTP:", otp);

  if (!otp) {
    console.log("No OTP found, test failed.");
    return;
  }

  console.log("\n3. Verifying OTP + Registering user...");
  res = await fetch(`${baseUrl}/verify-otp`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, otp, name, password })
  });
  data = await res.json();
  console.log("Verify OTP Response:", data);

  console.log("\n4. Testing Login with Email & Password...");
  res = await fetch(`${baseUrl}/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  });
  data = await res.json();
  console.log("Login Response:", data);
}

testAuth();
