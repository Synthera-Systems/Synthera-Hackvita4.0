import { getContactsService } from "./emergencyContacts.service.js";
import { sendBulkSMS } from "./sms.service.js";

export const triggerEmergencyService = async (uuid) => {

  // 1. get contacts
  const contacts = await getContactsService(uuid);

  if (!contacts || contacts.length === 0) {
    throw new Error("No emergency contacts found");
  }

  // 2. extract phone numbers
  const phoneNumbers = contacts.map(c => c.phno);

  // 3. prepare message
  const message = `🚨 EMERGENCY ALERT
User ${uuid} triggered an emergency.
Please check immediately.`;

  // 4. send SMS
  const smsReport = await sendBulkSMS(phoneNumbers, message);

  return {
    numbers: phoneNumbers,
    report: smsReport
  };
};