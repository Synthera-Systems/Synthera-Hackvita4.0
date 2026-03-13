import {
  addContactRepo,
  getContactsRepo,
  deleteContactRepo
} from "../repositories/emergencyContacts.repository.js";

export const addContactService = async (uuid, contact) => {

  if (!contact.name || !contact.phno) {
    throw new Error("Name and phone required");
  }

  return await addContactRepo(uuid, contact);
};


export const getContactsService = async (uuid) => {
  const details = await getContactsRepo(uuid);
  return details.contacts || [];
};


export const deleteContactService = async (uuid, contactId) => {
  return await deleteContactRepo(uuid, contactId);
};