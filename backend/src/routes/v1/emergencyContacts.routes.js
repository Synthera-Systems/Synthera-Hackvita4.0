import express from "express";
import { addContact, deleteContact, getContacts } from "../../controllers/emergencyContacts.controller.js";
import { verifyAuthToken } from "../../middlewares/auth.middleware.js";

const router = express.Router();

router.post("/", verifyAuthToken, addContact);

router.get("/", verifyAuthToken, getContacts);

router.delete("/:contactId", verifyAuthToken, deleteContact);

export default router;