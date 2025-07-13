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
const Cart = lazy(() => import("./pages/cart/Cart"));
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
import AdminAuth from "./auth/AdminAuth";
import { useAuthStore } from "./store/authStore";
import { supabase } from "./lib/supabase";
import { InstallPWA } from "./components/InstallPWA";
import { useAnalytics } from "./hooks/useAnalytics";

function PrivateRoute({ children }: { children: React.ReactNode }) {
  const user = useAuthStore((state) => state.user);
  return user ? <>{children}</> : <Navigate to="/login" />;
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
                element={user ? <Navigate to="/dashboard" /> : <Login />}
              />
              <Route
                path="/register"
                element={user ? <Navigate to="/dashboard" /> : <Register />}
              />
              <Route path="/about" element={<About />} />
              <Route path="/privacy" element={<Privacy />} />
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
                path="/orders"
                element={
                  <PrivateRoute>
                    <Orders />
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
              <Route path="/search" element={<Search />} />
              <Route path="/category/:category" element={<ProductList />} />
              <Route path="/product/:productId" element={<ProductDetails />} />
              <Route path="/chat-support" element={<Chat />} />

              <Route element={<AdminAuth />}>
                <Route path="/dashboard/*" element={<AdminLayout />} />
              </Route>
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
