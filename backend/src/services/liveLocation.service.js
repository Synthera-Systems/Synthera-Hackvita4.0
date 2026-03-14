import { getRedisClient } from "../config/redis.js";

export const updateLiveLocationService = async (
  uuid,
  lat,
  lon,
  timestamp
) => {
  const redis = getRedisClient();

  const updatedAt = timestamp || new Date().toISOString();

  const key = `live_location:${uuid}`;

  await redis.hSet(key, {
    lat,
    lon,
    updatedAt
  });

  return {
    message: "Location upserted",
    uuid,
    location: {
      lat,
      lon,
      updatedAt
    }
  };
};

export const getLiveLocationService = async (uuid) => {
  const redis = getRedisClient();

  const key = `live_location:${uuid}`;

  const location = await redis.hGetAll(key);

  if (!location || Object.keys(location).length === 0) {
    throw new Error("Live location not found");
  }

  return {
    uuid,
    lat: parseFloat(location.lat),
    lon: parseFloat(location.lon),
    updatedAt: location.updatedAt
  };
};