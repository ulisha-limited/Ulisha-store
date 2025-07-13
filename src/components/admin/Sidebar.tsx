import React from "react";
import { LayoutDashboardIcon, ShoppingCartIcon, User, Share, Settings } from "lucide-react";
import Menu from "./menu/Menu";

function Sidebar() {
  return (
    <aside className="h-screen w-64 bg-white shadow-lg text-gray flex flex-col p-3 rounded-lg">
      <nav className="flex flex-col gap-4">
        <Menu />
      </nav>
    </aside>
  );
}

export default Sidebar;
