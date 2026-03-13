import express from "express";
import { verifyAuthToken } from "../../middlewares/auth.middleware.js";
import { triggerController } from "../../controllers/trigger.controller.js";
const router = express.Router();

router.post("/", verifyAuthToken, triggerController);

export default router;