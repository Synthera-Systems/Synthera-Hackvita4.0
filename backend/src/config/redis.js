import { createClient } from "redis";
import dotenv from "dotenv";

dotenv.config();

let redisClient;

export const connectRedis = async () => {
  try {

    redisClient = createClient({
      url: process.env.REDIS_URL
    });

    redisClient.on("error", (err) => {
      console.error("Redis error:", err);
    });

    redisClient.on("connect", () => {
      console.log("Redis connected");
    });

    await redisClient.connect();

  } catch (error) {
    console.error("Redis connection failed:", error.message);
    process.exit(1);
  }
};

export const getRedisClient = () => {
  if (!redisClient) {
    throw new Error("Redis not initialized");
  }
  return redisClient;
};