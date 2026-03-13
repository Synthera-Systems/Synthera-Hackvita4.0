import express from "express";
import bodyParser from "body-parser";
import routesV1 from "./routes/v1/route.js";

const app = express();

app.disable("etag");

app.use(bodyParser.urlencoded({ limit: "50kb", extended: true }));
app.use(express.json({ limit: "50kb" }));
app.use("/", routesV1);

export default app;