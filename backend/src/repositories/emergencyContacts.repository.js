import EmergencyContacts from "../models/emergencyContacts.model.js";

export const addContactRepo = async (uuid, contact) => {

  const userContacts = await EmergencyContacts.findOneAndUpdate(
    { uuid },
    { $push: { contacts: contact } },
    { new: true, upsert: true }
  );

  return userContacts;
};


export const getContactsRepo = async (uuid) => {
  return EmergencyContacts.findOne({ uuid });
};


export const deleteContactRepo = async (uuid, contactId) => {

  return EmergencyContacts.findOneAndUpdate(
    { uuid },
    { $pull: { contacts: { _id: contactId } } },
    { new: true }
  );

};