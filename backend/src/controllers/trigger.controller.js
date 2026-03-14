import { updateLiveLocationService } from "../services/liveLocation.service.js";
import { triggerEmergencyService } from "../services/trigger.service.js";

export const triggerController = async (req, res) => {

  try {
    const { uuid } = req.user;
    const { lat, lon, battery, time } = req.body;

    if (!lat || !lon) {
      return res.status(400).json({
        error: "Location is required"
      });
    }

    const result = await triggerEmergencyService(
      uuid,
      lat,
      lon,
      battery,
      time
    );

    await updateLiveLocationService(uuid, lat, lon, time)
    
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