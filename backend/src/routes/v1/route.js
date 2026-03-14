import express from "express";
import authRoutes from "./auth.route.js"
import emergencyContactsRoutes from "./emergencyContacts.routes.js";
import triggerRoute from "./trigger.route.js";
import liveLocationRoute from "./liveLocation.route.js";
const router = express.Router();

router.get("/", (req, res) => {
  res.json({
    message: "Welcome to the API v1"
  });
});
router.use("/auth", authRoutes);
router.use("/emergency-contacts", emergencyContactsRoutes);
router.use("/trigger", triggerRoute);
router.use("/sos", liveLocationRoute);
export default router;