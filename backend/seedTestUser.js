import mongoose from 'mongoose';
import User from './models/userModel.js';
import dotenv from 'dotenv';
dotenv.config();

const testDuplicateCheck = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI || "mongodb://localhost:27017/test");
        console.log("Connected to DB");

        const email = "test_duplicate@example.com";
        await User.deleteMany({ email });

        // Create a verified user with a password
        await User.create({
            email,
            password: "password123",
            isVerified: true,
            name: "Existing User"
        });
        console.log("Created verified user with password");

        // Now test the controller logic (simulated request)
        // Or just call the API
        console.log("Test user created. Now you can test the API call.");
        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
};

testDuplicateCheck();
