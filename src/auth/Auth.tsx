import React, { lazy } from "react";
import { useAuthStore } from "../store/authStore";
import { Navigate, Outlet } from "react-router-dom";

const Page404 = lazy(() => import("../pages/errors/Page404"));

export default function Auth({ isAdmin = false }: { isAdmin?: boolean }) {
  const user = useAuthStore((state) => state.user);

  if (!isAdmin) return user ? <Outlet /> : <Navigate to="/login" replace />;

  const adminEmails = [
    "paulelite606@gmail.com",
    "obajeufedo2@gmail.com",
    "mrepol742@gmail.com",
  ];
  const isUserAdmin = user?.email && adminEmails.includes(user.email);
  return isUserAdmin ? <Outlet /> : <Page404 />;
}
