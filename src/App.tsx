import React, { useEffect, Suspense, lazy } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { Navbar } from './components/Navbar';
import { useAuthStore } from './store/authStore';
import { supabase } from './lib/supabase';
import { InstallPWA } from './components/InstallPWA';
import { ProtectedRoute } from './components/ProtectedRoute';
import { Outlet } from 'react-router-dom';

const HomeLazy = lazy(() => import('./pages/Home').then(module => ({ default: module.Home })));
const LoginLazy = lazy(() => import('./pages/Login').then(module => ({ default: module.Login })));
const RegisterLazy = lazy(() => import('./pages/Register').then(module => ({ default: module.Register })));
const AboutLazy = lazy(() => import('./pages/About').then(module => ({ default: module.About })));
const TermsLazy = lazy(() => import('./pages/Terms').then(module => ({ default: module.Terms })));
const ReturnsLazy = lazy(() => import('./pages/Returns').then(module => ({ default: module.Returns })));
const DashboardLazy = lazy(() => import('./pages/Dashboard').then(module => ({ default: module.Dashboard })));
const SettingsLazy = lazy(() => import('./pages/Settings').then(module => ({ default: module.Settings })));
const AdminLazy = lazy(() => import('./pages/Admin').then(module => ({ default: module.Admin })));
const CartLazy = lazy(() => import('./pages/Cart').then(module => ({ default: module.Cart })));
const MyStoreLazy = lazy(() => import('./pages/MyStore').then(module => ({ default: module.MyStore })));
const StoreDetailsLazy = lazy(() => import('./pages/StoreDetails').then(module => ({ default: module.StoreDetails })));
const ProductDetailsLazy = lazy(() => import('./pages/ProductDetails').then(module => ({ default: module.ProductDetails })));
const ChatLazy = lazy(() => import('./pages/Chat').then(module => ({ default: module.Chat })));

function App() {
  const setUser = useAuthStore((state) => state.setUser);
  const setSession = useAuthStore((state) => state.setSession);
  const refreshSession = useAuthStore((state) => state.refreshSession);
  const user = useAuthStore((state) => state.user);

  useEffect(() => {
    // Initial session check - handle silently to avoid console errors
    refreshSession().catch(() => {
      // If refresh fails, we've already cleared the session in the store
      console.log('Session refresh failed, user needs to log in again');
    });

    // Listen for auth state changes
    const { data: { subscription } } = supabase.auth.onAuthStateChange(async (event, session) => {
      if (event === 'SIGNED_IN') {
        setSession(session);
        setUser(session?.user ?? null);
      } else if (event === 'SIGNED_OUT') {
        setSession(null);
        setUser(null);
      } else if (event === 'TOKEN_REFRESHED') {
        setSession(session);
        setUser(session?.user ?? null);
      } else if (event === 'USER_UPDATED') {
        setSession(session);
        setUser(session?.user ?? null);
      }
    });

    return () => {
      subscription.unsubscribe();
    };
  }, [setUser, setSession, refreshSession]);

  return (
    <Router>
      <Suspense
        fallback={
          <div className="fixed inset-0 flex items-center justify-center bg-white bg-opacity-80 z-50">
        <span className="w-12 h-12 border-4 border-blue-500 border-t-transparent rounded-full animate-spin"></span>
          </div>
        }
            >
        <div className="min-h-screen bg-gray-50">
          <Navbar isLoggedIn={!!user} />
          <Routes>
            <Route path="/" element={<HomeLazy />} />
            <Route path="/login" element={user ? <Navigate to="/dashboard" /> : <LoginLazy />} />
            <Route path="/register" element={user ? <Navigate to="/dashboard" /> : <RegisterLazy />} />
            <Route path="/about" element={<AboutLazy />} />
            <Route path="/terms" element={<TermsLazy />} />
            <Route path="/returns" element={<ReturnsLazy />} />
            <Route path="/store/:storeId" element={<StoreDetailsLazy />} />
            <Route path="/product/:productId" element={<ProductDetailsLazy />} />
            <Route path="/chat-support" element={<ChatLazy />} />

            <Route element={<ProtectedRoute requiredRole="user"><Outlet /></ProtectedRoute>}>
              <Route path="/cart" element={<CartLazy />} />
              <Route path="/dashboard" element={<DashboardLazy />} />
              <Route path="/settings" element={<SettingsLazy />} />
              <Route path="/my-store" element={<MyStoreLazy />} />
            </Route>

            <Route element={<ProtectedRoute requiredRole="admin"><Outlet /></ProtectedRoute>}>
              <Route path="/admin" element={<AdminLazy />} />
            </Route>
          </Routes>
          
          <InstallPWA />
        </div>
      </Suspense>
    </Router>
  );
}

export default App;