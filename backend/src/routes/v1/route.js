import express from "express";
import authRoutes from "./auth.route.js"
import emergencyContactsRoutes from "./emergencyContacts.routes.js";
import triggerRoute from "./trigger.route.js";
const router = express.Router();

router.use("/auth", authRoutes);
router.use("/emergency-contacts", emergencyContactsRoutes);
router.use("/trigger", triggerRoute);
export default router;