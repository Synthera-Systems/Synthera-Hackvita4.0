import express from "express";
const app = express();
import serverV1 from "./app.v1.js";
import { connectMongo } from "./config/mongodb.js";
const host = "0.0.0.0";
const port = process.env.PORT || 7860;
const contextPath = "/api/v1";

app.set("trust proxy", 1);
app.use(contextPath, serverV1);

const start = async () => {
  await connectMongo();
  app.listen(port, host, () => {
    console.log(`app is running in http://${host}:${port}${contextPath}`);
  });
};

start();
