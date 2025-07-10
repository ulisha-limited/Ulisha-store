import React, { useEffect } from "react";
import {
  BrowserRouter as Router,
  Routes,
  Route,
  Navigate,
} from "react-router-dom";
import { Navbar } from "./components/Navbar";
import { Home } from "./pages/Home";
import { Login } from "./pages/auth/Login";
import { Register } from "./pages/auth/Register";
import { Dashboard } from "./pages/user/Dashboard";
import { Settings } from "./pages/user/Settings";
import { Dashboard as AdminDashboard } from "./pages/user/admin/Dashboard";
import { Cart } from "./pages/cart/Cart";
import { MyStore } from "./pages/user/admin/MyStore";
import { StoreDetails } from "./pages/StoreDetails";
import { ProductDetails } from "./pages/product/ProductDetails";
import { Chat } from "./pages/Chat";
import { About } from "./pages/About";
import { Terms } from "./pages/legal/Terms";
import { Returns } from "./pages/legal/Returns";
import { useAuthStore } from "./store/authStore";
import { supabase } from "./lib/supabase";
import { InstallPWA } from "./components/InstallPWA";
import { useAnalytics } from "./hooks/useAnalytics";
import { ProductList } from "./pages/categories/ProductList";
import Footer from "./components/Footer";

function PrivateRoute({ children }: { children: React.ReactNode }) {
  const user = useAuthStore((state) => state.user);
  return user ? <>{children}</> : <Navigate to="/login" />;
}

function AdminRoute({ children }: { children: React.ReactNode }) {
  const user = useAuthStore((state) => state.user);
  const adminEmails = ["paulelite606@gmail.com", "obajeufedo2@gmail.com"];
  const isAdmin = user?.email && adminEmails.includes(user.email);
  return isAdmin ? <>{children}</> : <Navigate to="/" />;
}

function App() {
  const setUser = useAuthStore((state) => state.setUser);
  const setSession = useAuthStore((state) => state.setSession);
  const refreshSession = useAuthStore((state) => state.refreshSession);
  const user = useAuthStore((state) => state.user);

  // Initialize analytics tracking
  useAnalytics();

  useEffect(() => {
    // Initial session check - handle silently to avoid console errors
    refreshSession().catch(() => {
      // If refresh fails, we've already cleared the session in the store
      console.log("Session refresh failed, user needs to log in again");
    });

    // Listen for auth state changes
    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange(async (event, session) => {
      if (event === "SIGNED_IN") {
        setSession(session);
        setUser(session?.user ?? null);
      } else if (event === "SIGNED_OUT") {
        setSession(null);
        setUser(null);
      } else if (event === "TOKEN_REFRESHED") {
        setSession(session);
        setUser(session?.user ?? null);
      } else if (event === "USER_UPDATED") {
        setSession(session);
        setUser(session?.user ?? null);
      }
    });

    return () => {
      subscription.unsubscribe();
    };
  }, [setUser, setSession, refreshSession]);

  return (
    <Router
      future={{
        v7_startTransition: true,
        v7_relativeSplatPath: true,
      }}
    >
      <div className="min-h-screen bg-gray-50">
        <Navbar isLoggedIn={!!user} />
        <div className="mt-28">
          <Routes>
            <Route path="/" element={<Home />} />
            <Route
              path="/login"
              element={user ? <Navigate to="/dashboard" /> : <Login />}
            />
            <Route
              path="/register"
              element={user ? <Navigate to="/dashboard" /> : <Register />}
            />
            <Route path="/about" element={<About />} />
            <Route path="/terms" element={<Terms />} />
            <Route path="/returns" element={<Returns />} />
            <Route
              path="/cart"
              element={
                <PrivateRoute>
                  <Cart />
                </PrivateRoute>
              }
            />
            <Route
              path="/dashboard"
              element={
                <PrivateRoute>
                  <Dashboard />
                </PrivateRoute>
              }
            />
            <Route
              path="/settings"
              element={
                <PrivateRoute>
                  <Settings />
                </PrivateRoute>
              }
            />
            <Route
              path="/my-store"
              element={
                <PrivateRoute>
                  <MyStore />
                </PrivateRoute>
              }
            />
            <Route path="/store/:storeId" element={<StoreDetails />} />
            <Route path="/category/:category" element={<ProductList />} />
            <Route path="/product/:productId" element={<ProductDetails />} />
            <Route path="/chat-support" element={<Chat />} />
            <Route
              path="/admin"
              element={
                <AdminRoute>
                  <AdminDashboard />
                </AdminRoute>
              }
            />
          </Routes>
          <Footer />
          <InstallPWA />
        </div>
      </div>
    </Router>
  );
}

export default App;
