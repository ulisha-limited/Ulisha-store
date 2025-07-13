import React, { Children } from "react";
import Sidebar from "../components/admin/Sidebar";
import Dropdown from "../components/admin/Dropdown";
import AdminRoute from "../routes/AdminRoute";

// This layout is used for admin-related pages, such as dashboard, orders, products, etc.
function AdminLayout() {
  return (
    <div className="min-h-screen bg-gray-50">
      <div className="flex max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 gap-8">
        {/* Sidebar for wide screens */}
        <div className="hidden lg:block w-64 flex-shrink-0">
          <div className="sticky top-8">
            <Sidebar />
          </div>
        </div>
        {/* Main content */}
        <div className="flex-1">
          {/* Dropdown for mobile, above AdminRoute */}
          <div className="block lg:hidden w-full mb-4">
            <Dropdown />
          </div>
          <AdminRoute />
        </div>
      </div>
    </div>
  );
}

export default React.memo(AdminLayout);
