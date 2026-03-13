import { triggerEmergencyService } from "../services/trigger.service.js";

export const triggerController = async (req, res) => {

  try {

    const { uuid } = req.user;

    const result = await triggerEmergencyService(uuid);

    res.status(200).json({
      message: "Emergency SMS sent",
      data: result
    });

  } catch (error) {

    res.status(400).json({
      error: error.message
    });

  }

};