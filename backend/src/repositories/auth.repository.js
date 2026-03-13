import { supabase } from "../config/supabase.js";

// SIGNUP
export const signup = async ({ email, password }) => {
  const { data, error } = await supabase.auth.signUp({
    email,
    password
  });

  if (error) {
    throw new Error(error.message);
  }

  return data;
};


// REGISTER PROFILE
export const register = async (userData) => {

  const { data, error } = await supabase
    .from("users")   // no need for public.users
    .insert(userData)
    .select()
    .single();

  if (error) {
    throw new Error(error.message);
  }

  return data;
};

// GET USER BY UUID
export const getUserByUUID = async (uuid) => {

  const { data, error } = await supabase
    .from("users")
    .select("*")
    .eq("uuid", uuid)
    .single();

  if (error) {
    throw new Error(error.message);
  }

  return data;
};