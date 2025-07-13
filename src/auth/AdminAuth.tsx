import React from "react";
import { useAuthStore } from "../store/authStore";
import { Navigate, Outlet } from "react-router-dom";

export default function AdminAuth() {
  const user = useAuthStore((state) => state.user);
  const adminEmails = ["paulelite606@gmail.com", "obajeufedo2@gmail.com"];
  const isAdmin = user?.email && adminEmails.includes(user.email);
  return isAdmin && <Outlet />;
}