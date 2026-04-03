import User from "../models/userModel.js";
import { generateToken } from "../utils/generateToken.js";
import { sendMail } from "../utils/sendMail.js";

// 📩 Send OTP to email
export const sendOTP = async (req, res) => {
  const { email, isSignUp } = req.body;

  if (!email) {
    return res.status(400).json({ message: "Email is required" });
  }

  try {
    console.log(`🔄 Processing OTP request for: ${email} (isSignUp: ${isSignUp})`);
    
    // Check if user already exists and is fully registered
    try {
      const existingUser = await User.findOne({ email });
      if (existingUser && existingUser.password && isSignUp) {
        return res.status(409).json({ message: "Email already registered. Please sign in." });
      }
    } catch (checkError) {
      console.log(`⚠️ Error checking existing user: ${checkError.message}`);
    }

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const otpExpiry = Date.now() + 5 * 60 * 1000; // 5 mins from now

    // Always store in memory for reliability
    global.tempOTPs = global.tempOTPs || {};
    global.tempOTPs[email] = { otp, otpExpiry };
    console.log(`📝 OTP stored in memory for: ${email}`);
    console.log(`🔐 Generated OTP: ${otp} (expires in 5 minutes)`);

    try {
      let user = await User.findOne({ email });
      if (!user) {
        user = await User.create({ email, otp, otpExpiry });
        console.log(`✅ New user created in database for: ${email}`);
      } else {
        user.otp = otp;
        user.otpExpiry = otpExpiry;
        await user.save();
        console.log(`✅ Existing user updated in database for: ${email}`);
      }
    } catch (dbError) {
      console.log(`⚠️ Database not available: ${dbError.message}`);
      console.log(`📝 Using memory storage only`);
    }

    try {
      console.log(`📧 Attempting to send email to: ${email}`);
      const emailResult = await sendMail(
        email, 
        "Your Kavach OTP Code", 
        `Your OTP code is: ${otp}. This code will expire in 5 minutes.`,
        `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #03474f;">Kavach - OTP Verification</h2>
          <p>Your OTP code is:</p>
          <div style="background-color: #f0f9ff; padding: 20px; text-align: center; border-radius: 8px; margin: 20px 0;">
            <h1 style="color: #03474f; font-size: 32px; margin: 0; letter-spacing: 8px;">${otp}</h1>
          </div>
          <p>This code will expire in 5 minutes.</p>
          <p>If you didn't request this code, please ignore this email.</p>
        </div>
        `
      );
      
      console.log(`✅ Email sent successfully to: ${email}`);
      res.status(200).json({ 
        message: "OTP sent successfully",
        email: email,
        debug: process.env.NODE_ENV === 'development' ? { otp } : undefined
      });
    } catch (emailError) {
      console.error("❌ Failed to send email:", emailError.message);
      console.error("❌ Full email error:", emailError);
      
      // Return error so the frontend knows email was not delivered
      res.status(500).json({ 
        message: "Failed to send OTP email. Please try again later.", 
        email: email,
        error: emailError.message
      });
    }

  } catch (err) {
    console.error("❌ OTP generation error:", err.message);
    res.status(500).json({ message: "OTP sending failed", error: err.message });
  }
};

const ongoingVerifications = new Set();

export const verifyOTP = async (req, res) => {
  const { email, otp, name, phone, password } = req.body;
  const verificationKey = `${email}-${otp}`;

  console.log(`🔄 === OTP VERIFICATION DEBUG ===`);
  console.log(`📧 Email: ${email}`);
  console.log(`🔐 Received OTP: "${otp}" (type: ${typeof otp})`);
  console.log(`⏰ Request timestamp: ${new Date().toISOString()}`);

  if (ongoingVerifications.has(verificationKey)) {
    console.log(`⚠️ Duplicate verification request detected, ignoring`);
    return res.status(409).json({ message: "Verification already in progress" });
  }

  ongoingVerifications.add(verificationKey);

  try {
    let user = null;
    let isValidOTP = false;
    let storedOTP = null; 

    const receivedOTP = String(otp).trim();
    console.log(`🔄 Normalized received OTP: "${receivedOTP}"`);

    // Check memory storage first
    const tempOTP = global.tempOTPs?.[email];
    console.log(`📝 Memory storage:`, tempOTP);
    console.log(`📝 All memory storage:`, global.tempOTPs);
    
    if (tempOTP) {
      storedOTP = String(tempOTP.otp).trim();
      const currentTime = Date.now();
      const isExpired = tempOTP.otpExpiry <= currentTime;
      
      console.log(`🔍 Detailed comparison:`);
      console.log(`  - Stored OTP: "${storedOTP}"`);
      console.log(`  - Received OTP: "${receivedOTP}"`);
      console.log(`  - Match: ${storedOTP === receivedOTP}`);
      console.log(`  - Expires at: ${new Date(tempOTP.otpExpiry).toLocaleString()}`);
      console.log(`  - Current time: ${new Date(currentTime).toLocaleString()}`);
      console.log(`  - Is expired: ${isExpired}`);
      
      if (storedOTP === receivedOTP && !isExpired) {
        isValidOTP = true;
        user = {
          _id: email,
          email,
          name: name || "User",
          phone: phone || "",
          password: password || "",
          isVerified: true
        };
        
        console.log(`✅ OTP verified via memory storage`);
        
        // Since memory storage doesn't actually save to DB by default here, we should try to save it if we have all details
        if (password) {
           let dbUser = await User.findOne({ email });
           if (!dbUser) {
             dbUser = new User({ email, name: name || "User", phone: phone || "", password, isVerified: true });
           } else {
             dbUser.name = name || dbUser.name;
             dbUser.phone = phone || dbUser.phone;
             dbUser.password = password;
             dbUser.isVerified = true;
             dbUser.otp = null;
             dbUser.otpExpiry = null;
           }
           await dbUser.save();
           user = dbUser;
        }

        // Clean up memory AFTER verification is complete
        delete global.tempOTPs[email];
      } else {
        console.log(`❌ Memory verification failed - OTP match: ${storedOTP ? (storedOTP === receivedOTP) : 'N/A'}, Expired: ${isExpired}`);
      }
    }

    // Fallback to database if memory check failed
    if (!isValidOTP) {
      try {
        const dbUser = await User.findOne({ email });
        console.log(`📝 Database user found:`, !!dbUser);
        
        if (dbUser && dbUser.otp && dbUser.otpExpiry) {
          const dbOTP = String(dbUser.otp).trim();
          const dbNotExpired = dbUser.otpExpiry > Date.now();
          
          console.log(`🔍 Database comparison:`);
          console.log(`  - DB OTP: "${dbOTP}"`);
          console.log(`  - Received: "${receivedOTP}"`);
          console.log(`  - Match: ${dbOTP === receivedOTP}`);
          console.log(`  - Not expired: ${dbNotExpired}`);
          
          if (dbOTP === receivedOTP && dbNotExpired) {
            isValidOTP = true;
            user = dbUser;
            
            // Update user
            user.name = name || user.name;
            user.phone = phone || user.phone;
            if (password) {
              user.password = password;
            }
            user.isVerified = true;
            user.otp = null;
            user.otpExpiry = null;
            await user.save();
            
            console.log(`✅ OTP verified via database`);
          }
        }
      } catch (dbError) {
        console.log(`⚠️ Database check failed: ${dbError.message}`);
      }
    }

    if (!isValidOTP) {
      console.log(`❌ FINAL RESULT: OTP verification failed`);
      ongoingVerifications.delete(verificationKey); // Cleanup before returning
      return res.status(400).json({ message: "Invalid or expired OTP" });
    }

    const token = generateToken(user._id);
    console.log(`✅ FINAL RESULT: OTP verification successful`);

    res.status(200).json({ 
      message: "Verification successful", 
      user: {
        id: user._id,
        email: user.email,
        name: user.name,
        phone: user.phone,
        emergencyContacts: user.emergencyContacts || [],
        isVerified: user.isVerified
      }, 
      token 
    });

  } catch (err) {
    console.error(`❌ OTP verification error:`, err.message);
    res.status(500).json({ message: "OTP verification failed", error: err.message });
  } finally {

    ongoingVerifications.delete(verificationKey);
  }
};

export const loginUser = async (req, res) => {
  const { email, password } = req.body;

  try {
    const user = await User.findOne({ email });

    if (user && user.password && (await user.matchPassword(password))) {
      const token = generateToken(user._id);
      
      res.status(200).json({
        message: "Login successful",
        user: {
          id: user._id,
          email: user.email,
          name: user.name,
          phone: user.phone,
          emergencyContacts: user.emergencyContacts || [],
          isVerified: user.isVerified,
        },
        token,
      });
    } else {
      res.status(401).json({ message: "Invalid email or password" });
    }
  } catch (error) {
    console.error(`❌ Login error:`, error.message);
    res.status(500).json({ message: "Login failed", error: error.message });
  }
};


export const updateProfile = async (req, res) => {
  const { name, phone, emergencyContacts } = req.body;

  try {
    // req.user is set by the protect middleware
    const user = await User.findById(req.user._id);

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (name) user.name = name;
    if (phone) user.phone = phone;
    if (emergencyContacts && Array.isArray(emergencyContacts)) {
      user.emergencyContacts = emergencyContacts;
    }

    await user.save();
    console.log(`✅ Profile updated for: ${user.email}`);

    res.status(200).json({
      message: "Profile updated successfully",
      user: {
        id: user._id,
        email: user.email,
        name: user.name,
        phone: user.phone,
        emergencyContacts: user.emergencyContacts,
        isVerified: user.isVerified,
      },
    });
  } catch (error) {
    console.error(`❌ Update profile error:`, error.message);
    res.status(500).json({ message: "Profile update failed", error: error.message });
  }
};

export const googleLogin = async (req, res) => {
  const { idToken } = req.body;

  try {
    const response = await fetch(
      `https://oauth2.googleapis.com/tokeninfo?id_token=${idToken}`
    );
    const decodedToken = await response.json();

    if (!decodedToken || !decodedToken.email_verified) {
      return res.status(401).json({ message: "Invalid Google ID token" });
    }

    const { email, name, sub: googleId } = decodedToken;
    let user = await User.findOne({ email });

    if (!user) {
      user = await User.create({
        name,
        email,
        googleId,
        isVerified: true,
      });
    }

    const token = generateToken(user._id);
    res.status(200).json({ message: "Login successful", user, token });
  } catch (error) {
    res.status(400).json({ message: "Google login failed", error: error.message });
  }
};

export const getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.status(200).json({
      message: "Profile retrieved successfully",
      user: {
        id: user._id,
        email: user.email,
        name: user.name,
        phone: user.phone,
        emergencyContacts: user.emergencyContacts || [],
        isVerified: user.isVerified,
      },
    });
  } catch (error) {
    console.error(`❌ Get profile error:`, error.message);
    res.status(500).json({ message: "Failed to retrieve profile", error: error.message });
  }
};
