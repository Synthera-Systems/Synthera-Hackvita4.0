import {
  addContactService,
  getContactsService,
  deleteContactService
} from "../services/emergencyContacts.service.js";


export const addContact = async (req, res) => {
  try {

    const { uuid } = req.user;

    const result = await addContactService(
      uuid,
      req.body
    );

    res.status(201).json(result);

  } catch (error) {

    res.status(400).json({
      error: error.message
    });

  }
};


export const getContacts = async (req, res) => {
  try {

    const { uuid } = req.user;

    const contacts = await getContactsService(uuid);

    res.json(contacts);

  } catch (error) {

    res.status(400).json({
      error: error.message
    });

  }
};


export const deleteContact = async (req, res) => {
  try {

    const { uuid } = req.user;
    const { contactId } = req.params;

    const result = await deleteContactService(
      uuid,
      contactId
    );

    res.json(result);

  } catch (error) {

    res.status(400).json({
      error: error.message
    });

  }
};