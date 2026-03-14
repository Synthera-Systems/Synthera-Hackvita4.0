import { getLiveLocationService, updateLiveLocationService } from "../services/liveLocation.service.js";

export const updateLiveLocation = async (req, res) => {
    try {
        const { lat, lon, timestamp } = req.body;
        const uuid = req.user.uuid;
        const result = await updateLiveLocationService(uuid, lat, lon, timestamp);
        res.json(result);
    } catch (error) {
        res.status(400).json({
            error: error.message
        });
    }
};

export const getLiveLocation = async (req, res) => {
  try {

    const { uuid } = req.body;

    const location = await getLiveLocationService(uuid);

    res.json(location);

  } catch (error) {

    res.status(404).json({
      error: error.message
    });

  }
};