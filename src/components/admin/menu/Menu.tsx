import React from "react";
import { Link } from "react-router-dom";
import {
  LayoutDashboardIcon,
  ShoppingCartIcon,
  User,
  Share,
  Settings,
} from "lucide-react";

function Menu() {
  return (
    <>
      <Link
        to="/dashboard"
        className="hover:bg-blue-700 hover:text-white rounded px-3 py-2 transition-all duration-500 flex items-center gap-2"
      >
        <LayoutDashboardIcon className="transition-transform duration-500 group-hover:scale-110" />
        <span>Dashboard</span>
      </Link>
      <Link
        to="/dashboard/orders"
        className="hover:bg-blue-700 hover:text-white rounded px-3 py-2 transition-all duration-500 flex items-center gap-2"
      >
        <ShoppingCartIcon className="transition-transform duration-500 group-hover:scale-110" />
        <span>Orders</span>
      </Link>
      <Link
        to="/dashboard/products"
        className="hover:bg-blue-700 hover:text-white rounded px-3 py-2 transition-all duration-500 flex items-center gap-2"
      >
        <ShoppingCartIcon className="transition-transform duration-500 group-hover:scale-110" />
        <span>Products</span>
      </Link>
      <Link
        to="/dashboard/users"
        className="hover:bg-blue-700 hover:text-white rounded px-3 py-2 transition-all duration-500 flex items-center gap-2"
      >
        <User className="transition-transform duration-500 group-hover:scale-110" />
        <span>Users</span>
      </Link>
      <Link
        to="/dashboard/affiliates"
        className="hover:bg-blue-700 hover:text-white rounded px-3 py-2 transition-all duration-500 flex items-center gap-2"
      >
        <Share className="transition-transform duration-500 group-hover:scale-110" />
        <span>Affiliates</span>
      </Link>
      <Link
        to="/dashboard/settings"
        className="hover:bg-blue-700 hover:text-white rounded px-3 py-2 transition-all duration-500 flex items-center gap-2"
      >
        <Settings className="transition-transform duration-500 group-hover:scale-110" />
        <span>Settings</span>
      </Link>
    </>
  );
}

export default Menu;
