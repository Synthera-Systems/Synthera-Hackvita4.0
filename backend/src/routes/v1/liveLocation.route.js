import express from "express";
import { verifyAuthToken } from "../../middlewares/auth.middleware.js";
import { updateLiveLocation, getLiveLocation } from "../../controllers/liveLocation.controller.js";

const router = express.Router();

router.post("/live-location", verifyAuthToken, updateLiveLocation);
router.get("/", getLiveLocation);

export default router;