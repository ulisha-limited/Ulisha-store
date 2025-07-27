import React, { useState, useEffect } from "react";
import { Link, useLocation } from "react-router-dom";
import {
  Home,
  ShoppingCart,
  LayoutDashboard,
  Settings,
  User,
  Search,
} from "lucide-react";
import { supabase } from '../lib/supabase'; // Assuming supabase is accessible here as well

// Helper function to get initials for the profile avatar
const getInitials = (name) => {
const getInitials = (name: string | undefined) => {
  if (!name) return "UN"; // Unknown User
  const parts = name.split(" ");
  if (parts.length > 1) {
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
  return parts[0][0].toUpperCase();
};
function BottomNav() {
  const location = useLocation();
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [isAdmin, setIsAdmin] = useState(false);
  const [user, setUser] = useState(null);
  import type { User } from '@supabase/supabase-js';

  const [user, setUser] = useState<User | null>(null);

  useEffect(() => {
    // Function to check user session
    const checkUser = async () => {
      const { data: { session } } = await supabase.auth.getSession();
      if (session) {
        setIsLoggedIn(true);
        setUser(session.user);
        // Implement logic to check if user is admin (e.g., from user_metadata or a separate 'profiles' table)
        // For demonstration, let's assume an admin role in user_metadata for now
        setIsAdmin(session.user.user_metadata?.role === 'admin');
      } else {
        setIsLoggedIn(false);
        setUser(null);
        setIsAdmin(false);
      }
    };

    checkUser();

    const { data: authListener } = supabase.auth.onAuthStateChange(
      (event) => {
        if (event === "SIGNED_IN" || event === "SIGNED_OUT") {
          checkUser();
        }
      }
    );
    );

    return () => {
      authListener.subscription.unsubscribe();
    };
  }, []);

  // Don't show bottom nav on these pages
  if (["/login", "/register", "/forgot-password"].includes(location.pathname)) {
    return null;
  }

  return (
    <div className="fixed bottom-0 left-0 right-0 bg-gray-900 text-white border-t border-gray-800 shadow-lg md:hidden z-50">
      <div className="flex justify-around items-center h-16">
        <Link
          to="/"
          className={`flex flex-col items-center justify-center text-xs p-2 ${
            location.pathname === "/" ? "text-primary-orange" : "text-gray-400"
          } hover:text-primary-orange transition-colors`}
        >
          <Home className="h-5 w-5 mb-1" />
          <span>Home</span>
        </Link>
        <Link
          to="/categories"
          className={`flex flex-col items-center justify-center text-xs p-2 ${
            location.pathname.startsWith("/category")
              ? "text-primary-orange"
              : "text-gray-400"
          } hover:text-primary-orange transition-colors`}
        >
          <Search className="h-5 w-5 mb-1" /> {/* Using Search icon for categories */}
          <span>Categories</span>
        </Link>
        <Link
          to="/orders"
          className={`flex flex-col items-center justify-center text-xs p-2 ${
            location.pathname === "/orders"
              ? "text-primary-orange"
              : "text-gray-400"
          } hover:text-primary-orange transition-colors`}
        >
          <ShoppingCart className="h-5 w-5 mb-1" />
          <span>Orders</span>
        </Link>

        {/* User profile / Login */}
        {isLoggedIn ? (
          <div className="relative">
            <button
              onClick={() => setIsProfileOpen(!isProfileOpen)}
              className={`flex flex-col items-center justify-center text-xs p-2 focus:outline-none ${
                isProfileOpen ? "text-primary-orange" : "text-gray-400"
              } hover:text-primary-orange transition-colors`}
            >
              <div
                className="rounded-full bg-primary-orange flex items-center justify-center mb-1"
                style={{ width: "24px", height: "24px", color: "white", fontSize: "10px" }}
                {getInitials((user?.user_metadata as { full_name?: string } | undefined)?.full_name)}
                {getInitials(user?.user_metadata?.full_name)}
              </div>
              <span>Profile</span>
            </button>
            {isProfileOpen && (
              <div className="absolute bottom-full right-1/2 translate-x-1/2 mb-2 w-48 bg-white rounded-md shadow-lg py-1 z-50">
                <Link
                  to="/"
                  className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 flex items-center space-x-2"
                  onClick={() => setIsProfileOpen(false)}
                >
                  <Home className="h-4 w-4" />
                  <span>Home</span>
                </Link>
                {isAdmin && (
                  <Link
                    to="/dashboard"
                    className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 flex items-center space-x-2"
                    onClick={() => setIsProfileOpen(false)}
                  >
                    <LayoutDashboard className="h-4 w-4" />
                    <span>Dashboard</span>
                  </Link>
                )}
                <Link
                  to="/orders"
                  className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 flex items-center space-x-2"
                  onClick={() => setIsProfileOpen(false)}
                >
                  <ShoppingCart className="h-4 w-4" />
                  <span>My Orders</span>
                </Link>
                <Link
                  to="/settings"
                  className="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 flex items-center space-x-2"
                  onClick={() => setIsProfileOpen(false)}
                >
                  <Settings className="h-4 w-4" />
                  <span>Settings</span>
                </Link>
              </div>
            )}
          </div>
        ) : (
          <Link
            to="/login"
            className={`flex flex-col items-center justify-center text-xs p-2 ${
              location.pathname === "/login"
                ? "text-primary-orange"
                : "text-gray-400"
            } hover:text-primary-orange transition-colors`}
          >
            <User className="h-5 w-5 mb-1" />
            <span>Login</span>
          </Link>
        )}
      </div>
    </div>
  );
}

export default React.memo(BottomNav);