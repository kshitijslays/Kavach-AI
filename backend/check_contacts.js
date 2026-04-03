import mongoose from "mongoose";
import './loadEnv.js';
import User from "./models/userModel.js";
import connectDB from "./config/db.js";

const checkContacts = async () => {
  await connectDB();
  try {
    const users = await User.find({}).select('email emergencyContacts');
    console.log(`Checking ${users.length} users:`);
    users.forEach(u => {
      console.log(`- ${u.email}: ${u.emergencyContacts.length} contacts`);
      u.emergencyContacts.forEach((c, i) => {
          console.log(`  [${i}] ${c.name}: ${c.number}`);
      });
    });
  } catch (err) {
    console.error("Error:", err.message);
  } finally {
    mongoose.connection.close();
  }
};

checkContacts();
