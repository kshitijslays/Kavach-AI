import mongoose from "mongoose";
import './loadEnv.js';
import User from "./models/userModel.js";
import connectDB from "./config/db.js";

const checkRecentActivity = async () => {
  await connectDB();
  try {
    const recentUsers = await User.find({
      updatedAt: { $gt: new Date(Date.now() - 10 * 60 * 1000) } // Last 10 minutes
    }).sort({ updatedAt: -1 });

    console.log(`Found ${recentUsers.length} users with recent activity:`);
    recentUsers.forEach(u => {
      console.log(`- Email: ${u.email}, OTP: ${u.otp}, Verified: ${u.isVerified}, UpdatedAt: ${u.updatedAt}`);
    });
  } catch (err) {
    console.error("Error:", err.message);
  } finally {
    mongoose.connection.close();
  }
};

checkRecentActivity();
