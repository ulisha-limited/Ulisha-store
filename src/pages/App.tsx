import React, { useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { Navbar } from './components/Navbar';
import { Home } from './pages/Home';
import { Login } from './pages/Login';
import { Register } from './pages/Register';
import { Dashboard } from './pages/Dashboard';
import { Settings } from './pages/Settings';
import { Admin } from './pages/Admin';
import { Cart } from './pages/Cart';
import { MyStore } from './pages/MyStore';
import { StoreDetails } from './pages/StoreDetails';
import { ProductDetails } from './pages/ProductDetails';
import { Chat } from './pages/Chat';
import { useAuthStore } from './store/authStore';
import { supabase } from './lib/supabase';
import { InstallPWA } from './components/InstallPWA';

const ADMIN_EMAILS = ['paulelite606@gmail.com', 'obajeufedo2@gmail.com'];

function PrivateRoute({ children }: { children: React.ReactNode }) {
  const user = useAuthStore((state) => state.user);
  return user ? <>{children}</> : <Navigate to="/login" />;
}

function AdminRoute({ children }: { children: React.ReactNode }) {
  const user = useAuthStore((state) => state.user);
  const isAdmin = user?.email && ADMIN_EMAILS.includes(user.email);
  return isAdmin ? <>{children}</> : <Navigate to="/" />;
}

// Rest of the component code remains exactly the same...
// [Previous content continues unchanged...]