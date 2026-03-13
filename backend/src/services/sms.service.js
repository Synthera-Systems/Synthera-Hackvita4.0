import axios from "axios";

export const sendBulkSMS = async (numbers, message) => {

  const phoneNumbers = numbers.join(",");

  const options = {
    method: "POST",
    url: "https://www.fast2sms.com/dev/bulkV2",
    headers: {
      authorization: process.env.FAST2SMS_API_KEY,
      "Content-Type": "application/json"
    },
    data: {
      route: "q",
      message,
      numbers: phoneNumbers
    }
  };

  const response = await axios(options);

  return response.data;
};