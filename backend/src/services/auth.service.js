import { getUserByUUID, register, signup } from "../repositories/auth.repository.js";

import { supabase } from "../config/supabase.js";

export const signupAndRegister = async (email, password, userData) => {
  try {
    // Step 1: Create user in Supabase Auth
    const authData = await signup({ email, password });

    if (!authData?.user) {
      throw new Error("Signup failed");
    }

    const userId = authData.user.id;

    // Step 2: Insert profile in users table
    const profile = await register({
      uuid: userId,
      email,
      ...userData
    });

    return {
      message: "User registered successfully",
      user: profile
    };

  } catch (error) {
    throw new Error(error.message);
  }
};

export const signin = async ({ email, password }) => {

  const { data, error } =
    await supabase.auth.signInWithPassword({
      email,
      password
    });

  if (error) throw error;

  return data;
};


export const getUserData = async (uuid) => {
  return await getUserByUUID(uuid);
};

// REFRESH TOKEN
export const refreshToken = async () => {

  const { data, error } =
    await supabase.auth.refreshSession();

  if (error) throw error;

  return data;
};


// LOGOUT
export const logout = async () => {

  const { error } =
    await supabase.auth.signOut();

  if (error) throw error;

  return { message: "Logged out successfully" };
};