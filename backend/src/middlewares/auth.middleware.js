import { supabase } from "../config/supabase.js";

export const verifyAuthToken = async (req, res, next) => {
  try {

    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({
        error: "Missing or invalid token"
      });
    }

    const token = authHeader.split(" ")[1];

    const { data, error } = await supabase.auth.getUser(token);

    if (error || !data.user) {
      return res.status(401).json({
        error: "Invalid token"
      });
    }

    // attach uuid to request
    req.user = {
      uuid: data.user.id,
      email: data.user.email
    };

    // req.user = {
    //   uuid: "f42ce390-cfda-47e0-bf3b-efdedb447f36",
    //   email: "dhritiman.saikia.11b.244@gmail.com"
    // };

    next();

  } catch (error) {

    res.status(500).json({
      error: "Authentication failed"
    });

  }
};