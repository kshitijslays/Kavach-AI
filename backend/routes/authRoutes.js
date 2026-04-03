import express from "express";
import {
  sendOTP,
  verifyOTP,
  googleLogin,
  loginUser,
  updateProfile,
  getProfile,
} from "../controllers/authController.js";
import { protect } from "../middleware/authMiddleware.js";

const router = express.Router();

// Auth Routes
router.post("/send-otp", sendOTP);
router.post("/verify-otp", verifyOTP);
router.post("/login", loginUser);
router.post("/google-login", googleLogin);
router.put("/update-profile", protect, updateProfile);
router.get("/profile", protect, getProfile);

export default router;
