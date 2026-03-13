import { getUserData } from "./auth.service.js";
import { getContactsService } from "./emergencyContacts.service.js";
import { sendBulkSMS } from "./sms.service.js";

export const triggerEmergencyService = async (
  uuid,
  lat,
  lon,
  battery,
  time
) => {

  // 1️⃣ Get user profile
  const user = await getUserData(uuid);

  if (!user) {
    throw new Error("User not found");
  }

  // 2️⃣ Get emergency contacts
  const contacts = await getContactsService(uuid);

  if (!contacts || contacts.length === 0) {
    throw new Error("No emergency contacts found");
  }

  // 3️⃣ Extract phone numbers
  const phoneNumbers = contacts.map(c => c.phno);

  // 4️⃣ Create location link
  const locationLink = `https://maps.google.com/?q=${lat},${lon}`;

  // 5️⃣ Build SMS message
  const message = `EMERGENCY

${user.name} needs help.

Location:
${locationLink}
`;

  // 6️⃣ Send SMS
  const smsReport = await sendBulkSMS(phoneNumbers, message);

  return {
    report: smsReport,
    battery,
    time
  };
};