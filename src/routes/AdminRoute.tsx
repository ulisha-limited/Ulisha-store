import React, { Suspense, lazy } from "react";
import { Route, Routes } from "react-router-dom";
const Dashboard = lazy(() => import("../pages/user/admin/Dashboard"));
const Products = lazy(() => import("../pages/user/admin/Products"));
const Affiliates = lazy(() => import("../pages/user/admin/Affiliates"));
const Orders = lazy(() => import("../pages/user/admin/Orders"));
const Users = lazy(() => import("../pages/user/admin/Users"));
const Settings = lazy(() => import("../pages/user/admin/Settings"));

function AdminRoute() {
  return (
    <Suspense
      fallback={
        <div className="min-h-screen flex items-center justify-center">
          <div className="loader">Loading...</div>
        </div>
      }
    >
      <Routes>
        <Route path="/" element={<Dashboard />} />
        <Route path="/products" element={<Products />} />
        <Route path="/categories" element={<Products />} />
        <Route path="/affiliates" element={<Affiliates />} />
        <Route path="/orders" element={<Orders />} />
        <Route path="/users" element={<Users />} />
        <Route path="/settings" element={<Settings />} />
      </Routes>
    </Suspense>
  );
}

export default React.memo(AdminRoute);
