import { getProfileDetailsController, getUserDataController, logoutController, refreshTokenController, signinController, signupController } from "../../controllers/auth.controller.js";
import express from "express";
import { verifyAuthToken } from "../../middlewares/auth.middleware.js";

const router = express.Router();

router.post("/signup", signupController);

router.post("/signin", signinController);

router.post("/refresh-token", refreshTokenController);

router.get("/user/:uuid", getUserDataController);

router.get("/me", verifyAuthToken, getProfileDetailsController);

router.post("/logout", logoutController);

export default router;