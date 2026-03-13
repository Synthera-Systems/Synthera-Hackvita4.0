import express from "express";
import { addContact, deleteContact, getContacts } from "../../controllers/emergencyContacts.controller.js";

const router = express.Router();

router.post("/:uuid", addContact);

router.get("/:uuid", getContacts);

router.delete("/:uuid/:contactId", deleteContact);

export default router;