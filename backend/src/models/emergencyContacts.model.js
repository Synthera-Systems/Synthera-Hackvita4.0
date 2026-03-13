import mongoose from "mongoose";

const contactSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true
  },
  phno: {
    type: String,
    required: true
  },
  altphno: {
    type: String
  }
});

const emergencyContactsSchema = new mongoose.Schema({
  uuid: {
    type: String,
    required: true,
    unique: true
  },
  contacts: [contactSchema]
});

export default mongoose.model(
  "EmergencyContacts",
  emergencyContactsSchema
);