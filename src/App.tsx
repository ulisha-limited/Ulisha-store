import React, { useEffect, Suspense, lazy } from "react";
import {
  BrowserRouter as Router,
  Routes,
  Route,
  Navigate,
} from "react-router-dom";
import { Navbar } from "./components/Navbar";
const Home = lazy(() => import("./pages/Home"));
const Login = lazy(() => import("./pages/auth/Login"));
const Register = lazy(() => import("./pages/auth/Register"));
const Orders = lazy(() => import("./pages/user/Orders"));
const Settings = lazy(() => import("./pages/user/Settings"));
const Cart = lazy(() => import("./pages/user/Cart"));
const ProductDetails = lazy(() => import("./pages/product/ProductDetails"));
const Chat = lazy(() => import("./pages/Chat"));
const About = lazy(() => import("./pages/About"));
const Privacy = lazy(() => import("./pages/legal/Privacy"));
const Terms = lazy(() => import("./pages/legal/Terms"));
const Returns = lazy(() => import("./pages/legal/Returns"));
const ProductList = lazy(() => import("./pages/categories/ProductList"));
const Search = lazy(() => import("./pages/Search"));
import Footer from "./components/Footer";
import AdminLayout from "./layouts/AdminLayout";
import Auth from "./auth/Auth";
import { useAuthStore } from "./store/authStore";
import { supabase } from "./lib/supabase";
import { InstallPWA } from "./components/InstallPWA";
import { useAnalytics } from "./hooks/useAnalytics";
import Page404 from "./pages/errors/Page404";
import AddressManagementPage from "./pages/Addressmanagement";
import CurrencyPreferencesPage from "./pages/Currencypreference";
import AccountSecurityPage from "./pages/Accountsecurity";
import CountryRegionPage from "./pages/CountryRegion";
import PaymentSettingsPage from "./pages/PaymentSettings";
import NotificationPreferencesPage from "./pages/Notificationprefrence";

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
      <div className="min-h-screen ">
        <Navbar isLoggedIn={!!user} />
        <div className="mt-28">
          <Suspense
            fallback={
              <div className="min-h-screen flex items-center justify-center">
                <div className="loader">Loading...</div>
              </div>
            }
          >
            <Routes>
              <Route path="/" element={<Home />} />
              <Route
                path="/login"
                element={user ? <Navigate to="/" replace /> : <Login />}
              />
              <Route
                path="/register"
                element={user ? <Navigate to="/" replace /> : <Register />}
              />
              <Route path="/about" element={<About />} />
              <Route path="/privacy" element={<Privacy />} />
              <Route path="/terms" element={<Terms />} />
              <Route path="/returns" element={<Returns />} />
              <Route path="/search" element={<Search />} />
              <Route path="/category/:category" element={<ProductList />} />
              <Route path="/product/:productId" element={<ProductDetails />} />
              <Route path="/chat-support" element={<Chat />} />

              <Route element={<Auth />}>
                <Route path="/cart" element={<Cart />} />
                <Route path="/orders" element={<Orders />} />
                <Route path="/settings" element={<Settings />} />
              </Route>

              <Route element={<Auth isAdmin={true} />}>
                <Route path="/dashboard/*" element={<AdminLayout />} />
              </Route>

              <Route path="*" element={<Page404 />} />

              <Route path="/settings" element={<Settings />} />
              <Route
                path="/settings/address-management"
                element={<AddressManagementPage />}
              />
              <Route
                path="settings/currency-preferences"
                element={<CurrencyPreferencesPage />}
              />
              <Route
                path="/settings/account-security"
                element={<AccountSecurityPage />}
              />
              <Route
                path="/settings/country-region"
                element={<CountryRegionPage />}
              />
              <Route
                path="/settings/payment-settings"
                element={<PaymentSettingsPage />}
              />
              <Route
                path="/settings/notification-preferences"
                element={<NotificationPreferencesPage />}
              />
            </Routes>
          </Suspense>

          <Footer />
          <InstallPWA />
        </div>
      </div>
    </Router>
  );
}

export default App;
