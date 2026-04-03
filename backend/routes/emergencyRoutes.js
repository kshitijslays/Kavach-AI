import express from "express";
import { triggerEmergencyAlert, uploadEmergencyAudio } from "../controllers/emergencyController.js";

import multer from "multer";

const router = express.Router();
const upload = multer({ storage: multer.memoryStorage() });

// 🚨 Trigger automated zero-click emergency alerts
router.post("/alert", triggerEmergencyAlert);

// 🎤 Upload post-alert 30s audio
router.post("/audio-alert", upload.single("audio"), uploadEmergencyAudio);

export default router;
