import { access } from "fs";
import { getUserData, logout, refreshToken, signin, signupAndRegister } from "../services/auth.service.js";

export const signupController = async (req, res) => {
  try {

    const { email, password, ...userData } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        error: "Email and password are required"
      });
    }

    const result = await signupAndRegister(
      email,
      password,
      userData
    );

    res.status(201).json(result);

  } catch (error) {

    res.status(400).json({
      error: error.message
    });

  }
};


export const signinController = async (req, res) => {
  try {

    const { email, password } = req.body;

    const data = await signin({ email, password });

    res.json({
      access_token: data.session.access_token,
      refresh_token: data.session.refresh_token,
    });

  } catch (error) {

    res.status(401).json({
      error: error.message
    });

  }
};


export const refreshTokenController = async (req, res) => {
  try {
    const { refresh_token } = req.body;
    if (!refresh_token) {
      return res.status(400).json({
        error: "Refresh token is required"
      });
    }
    const data = await refreshToken(refresh_token);

    res.json({
      access_token: data.access_token,
      refresh_token: data.refresh_token,
    });

  } catch (error) {

    res.status(400).json({
      error: error.message
    });

  }
};

export const getUserDataController = async (req, res) => {
  try {

    const { uuid } = req.params;

    const userData = await getUserData(uuid);

    res.json(userData);

  } catch (error) {

    res.status(400).json({
      error: error.message
    });

  }
}

export const getProfileDetailsController = async (req, res) => {
  try {

    const uuid = req.user.uuid;

    const user = await getUserData(uuid);

    res.json(user);

  } catch (error) {

    res.status(400).json({
      error: error.message
    });

  }
};

export const logoutController = async (req, res) => {
  try {

    const result = await logout();

    res.json(result);

  } catch (error) {

    res.status(400).json({
      error: error.message
    });

  }
};
