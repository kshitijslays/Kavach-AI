import mongoose from "mongoose";

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGO_URI, {
      serverSelectionTimeoutMS: 5000 // Fails fast in 5s instead of hanging for 30s
    });
    console.log(`✅ MongoDB Atlas connected: ${conn.connection.host}`);
    console.log(`✅ Database: ${conn.connection.name}`);
  } catch (err) {
    console.error(`❌ MongoDB connection error: ${err.message}`);
    
    if (err.message.includes('IP')) {
      console.error("🔒 IP Whitelist Issue - Follow these steps:");
      console.error("1. Go to https://cloud.mongodb.com/");
      console.error("2. Select your cluster → Security → Network Access");
      console.error("3. Click 'ADD IP ADDRESS'");
      console.error("4. Either add your current IP or use 0.0.0.0/0 for development");
      console.error("5. Save and wait 2-3 minutes for changes to apply");
    }
    
    // Don't exit process, just log the error
    console.log("📝 Server will continue without database connection");
    console.log("📝 Fix the IP whitelist issue to enable database features");
  }
};

export default connectDB;
