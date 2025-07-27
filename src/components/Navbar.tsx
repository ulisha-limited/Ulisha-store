import React, { useState, useEffect, useRef } from "react";
import { Link, useNavigate, useLocation } from "react-router-dom";
import {
  ShoppingCart,
  User,
  LogIn,
  Menu,
  X,
  Heart,
  Home,
  Store,
  Search,
  ChevronDown,
  MessageCircle,
  LayoutDashboard,
  Settings,
  LogOut,
  Mail,
  Calendar,
  Camera,
} from "lucide-react";
import { useAuthStore } from "../store/authStore";
import { useCartStore } from "../store/cartStore";

export function Navbar({ isLoggedIn }: { isLoggedIn: boolean }) {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [isProfileOpen, setIsProfileOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");

  const signOut = useAuthStore((state) => state.signOut);
  const user = useAuthStore((state) => state.user);
  const navigate = useNavigate();
  const location = useLocation();
  const cartItems = useCartStore((state) => state.items);
  const fetchCart = useCartStore((state) => state.fetchCart);

  const [isVisible, setIsVisible] = useState(true);
  const lastScrollY = useRef(window.scrollY);

  const ADMIN_EMAILS = ["paulelite606@gmail.com", "obajeufufredo2@gmail.com"];
  const isAdmin = user?.email && ADMIN_EMAILS.includes(user.email);

  useEffect(() => {
    window.scrollTo(0, 0);
  }, [location]);

  useEffect(() => {
    if (isLoggedIn) {
      fetchCart();
    }
  }, [isLoggedIn, fetchCart]);

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      const target = event.target as HTMLElement;
      if (!target.closest(".profile-menu") && isProfileOpen) {
        setIsProfileOpen(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, [isProfileOpen]);

  useEffect(() => {
    const handleScroll = () => {
      if (window.scrollY < 50) {
        setIsVisible(true);
        lastScrollY.current = window.scrollY;
        return;
      }
      if (window.scrollY > lastScrollY.current) {
        setIsVisible(false);
      } else {
        setIsVisible(true);
      }
      lastScrollY.current = window.scrollY;
    };

    window.addEventListener("scroll", handleScroll);
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  const handleSignOut = async () => {
    try {
      await signOut();
      navigate("/login");
    } catch (error) {
      console.error("Error signing out:", error);
    }
  };

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (searchQuery.trim()) {
      navigate(`/search?q=${encodeURIComponent(searchQuery)}`);
    }
  };

  const handleCameraClick = () => {
    alert("Camera icon clicked!");
  };

  const getInitials = (name: string) => {
    return name ? name.charAt(0).toUpperCase() : "";
  };

  const cartItemCount = cartItems.reduce(
    (total, item) => total + item.quantity,
    0
  );

  if (["/login", "/register", "/forgot-password"].includes(location.pathname))
    return null;

  const categories = [
    { name: "All", path: "/" },
    { name: "Clothes", path: "/category/Clothes" },
    { name: "Accessories", path: "/category/Accessories" },
    { name: "Shoes", path: "/category/Shoes" },
    { name: "Smart Watches", path: "/category/SmartWatches" },
    { name: "Electronics", path: "/category/Electronics" },
    { name: "Perfumes Body Spray", path: "/category/PerfumesBodySpray" },
    { name: "Phones", path: "/category/Phones" },
    { name: "Handbags", path: "/category/Handbags" },
    { name: "Jewelries", path: "/category/Jewelries" },
    { name: "Gym Wear", path: "/category/GymWear" },
  ];

  return (
    <>
      {/* Mobile Navbar (visible on screens < lg) */}
      <nav className="fixed top-0 left-0 right-0 bg-[#007BFF] pt-2 pb-1 shadow-md z-50 lg:hidden transition-transform duration-300">
        <div className="flex items-center justify-between px-4">
          <Mail size={24} className="text-white mr-3" />{" "}
          {/* Message Icon - White */}
          {/* Search Bar */}
          <form
            onSubmit={handleSearchSubmit}
            className="flex-grow flex items-center bg-white rounded-full h-10 px-1 relative"
          >
            <input
              type="text"
              placeholder="Sunglasses Men"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="flex-grow bg-transparent outline-none border-none text-sm px-3 pr-10 text-gray-700" // Input text color
            />
            <button
              type="button"
              onClick={handleCameraClick}
              className="absolute right-10 top-1/2 transform -translate-y-1/2 p-1 text-gray-500" // Camera icon color
              aria-label="Open camera search"
            >
              <Camera size={20} />
            </button>
            <button
              type="submit"
              className="bg-orange-500 text-white rounded-full h-8 w-8 flex items-center justify-center mr-1"
              aria-label="Search"
            >
              <Search size={18} />
            </button>
          </form>
          <Heart size={24} className="text-white ml-3" />{" "}
          {/* Heart Icon - White */}
        </div>

        {/* Categories (Horizontal Scroll) */}
        <div className="flex overflow-x-auto whitespace-nowrap px-4 py-2 mt-2 hide-scrollbar">
          {categories.map((category) => (
            <Link
              key={category.name}
              to={category.path}
              className={`text-white text-sm px-3 py-1 pb-2 font-medium relative ${
                location.pathname === category.path ? "text-orange-300" : "" // Slightly different orange for active link for contrast
              }`}
            >
              {category.name}
              {location.pathname === category.path && (
                <span className="absolute bottom-0 left-1/2 transform -translate-x-1/2 w-4/5 h-0.5 bg-orange-500 rounded-full"></span>
              )}
            </Link>
          ))}
        </div>
      </nav>

      {/* Spacer div for mobile navbar to push content down */}
      <div className="h-[110px] lg:hidden"></div>

      {/* Original Desktop Navbar (visible on screens >= lg) */}
      <header
        className={`bg-[#007BFF] shadow-lg text-white fixed w-full top-0 left-0 transition-transform duration-300 z-50 hidden lg:block ${
          isVisible ? "translate-y-0" : "-translate-y-full"
        }`}
      >
        {/* Top bar with contact info and social links */}
        <div className="bg-[#0066CC] py-2">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex justify-between items-center">
            <div className="text-sm">
              <span className="mr-4">support@ulishastore.com</span>
              <span>Free shipping on orders over ₦50,000</span>
            </div>
            <div className="flex items-center space-x-4 text-sm">
              <a
                href="#"
                className="hover:text-primary-orange transition-colors"
              >
                Track Order
              </a>
              <a
                href="#"
                className="hover:text-primary-orange transition-colors"
              >
                Help
              </a>
              <div className="h-4 w-px bg-blue-300"></div>
              <a
                href="#"
                className="hover:text-primary-orange transition-colors"
              >
                English
              </a>
              <a
                href="#"
                className="hover:text-primary-orange transition-colors"
              >
                NGN
              </a>
            </div>
          </div>
        </div>

        {/* Main desktop navbar */}
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16 lg:h-20">
            {/* Logo */}
            <div className="flex items-center">
              <Link to="/" className="flex items-center space-x-2 group">
                <span className="text-xl lg:text-2xl font-bold">
                  <span className="text-primary-orange">Ulisha</span>
                  <span className="text-white">Store</span>
                </span>
              </Link>
            </div>

            {/* Desktop navigation */}
            <div className="hidden lg:flex items-center me-auto space-x-5 ml-4">
              <Link
                to="/"
                className={`text-white hover:text-primary-orange transition-colors font-medium ${
                  location.pathname === "/" && !location.search
                    ? "text-primary-orange"
                    : ""
                }`}
              >
                Home
              </Link>

              <Link
                to="/wishlist"
                className={`text-white hover:text-primary-orange transition-colors font-medium ${
                  location.pathname === "/wishlist" ? "text-primary-orange" : ""
                }`}
              >
                Wishlist
              </Link>

              {isLoggedIn && (
                <Link
                  to="/my-store"
                  className={`text-white hover:text-primary-orange transition-colors font-medium ${
                    location.pathname === "/my-store"
                      ? "text-primary-orange"
                      : ""
                  }`}
                >
                  My Store
                </Link>
              )}

              <Link
                to="/chat-support"
                className={`text-white hover:text-primary-orange transition-colors font-medium ${
                  location.pathname === "/chat-support"
                    ? "text-primary-orange"
                    : ""
                }`}
              >
                Chat Support
              </Link>
            </div>

            {/* Desktop right section */}
            <div className="hidden lg:flex items-center space-x-6">
              {/* Search input (always visible on desktop) */}
              <div className="relative search-container">
                <form onSubmit={handleSearchSubmit} className="flex">
                  <input
                    type="text"
                    placeholder="Search products..."
                    className="w-full px-3 py-2 border rounded-l-md focus:outline-none focus:ring-2 focus:ring-primary-orange text-gray-700"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                  />
                  <button
                    type="submit"
                    className="bg-primary-orange text-white px-3 py-2 rounded-r-md hover:bg-primary-orange/90"
                  >
                    <Search className="h-4 w-4" />
                  </button>
                </form>
              </div>

              {/* Wishlist */}
              <Link
                to="/wishlist"
                className="text-white hover:text-primary-orange transition-colors relative"
              >
                <Heart className="h-5 w-5" />
              </Link>

              {/* Cart */}
              <Link
                to="/cart"
                className="text-white hover:text-primary-orange transition-colors relative"
              >
                <ShoppingCart className="h-5 w-5" />
                {cartItemCount > 0 && (
                  <span className="absolute -top-2 -right-2 bg-primary-orange text-white text-xs rounded-full h-5 w-5 flex items-center justify-center">
                    {cartItemCount}
                  </span>
                )}
              </Link>

              {/* User profile */}
              {isLoggedIn ? (
                <div className="relative profile-menu">
                  <button
                    onClick={() => setIsProfileOpen(!isProfileOpen)}
                    className="text-white hover:text-primary-orange transition-colors focus:outline-none flex items-center space-x-2"
                  >
                    <div
                      className="rounded-full bg-primary-orange flex items-center justify-center"
                      style={{ width: "40px", height: "40px", color: "white" }}
                    >
                      {getInitials(user?.user_metadata?.full_name)}
                    </div>
                  </button>

                  {isProfileOpen && (
                    <div className="absolute right-0 mt-2 w-48 bg-white rounded-md shadow-lg py-1 z-50">
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
                      <button
                        onClick={() => {
                          handleSignOut();
                          setIsProfileOpen(false);
                        }}
                        className="block w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 flex items-center space-x-2"
                      >
                        <LogOut className="h-4 w-4" />
                        <span>Logout</span>
                      </button>
                    </div>
                  )}
                </div>
              ) : (
                <Link
                  to="/login"
                  className="text-white hover:text-primary-orange transition-colors flex items-center space-x-2"
                >
                  <LogIn className="h-5 w-5" />
                  <span className="hidden xl:inline text-sm font-medium">
                    Sign In
                  </span>
                </Link>
              )}
            </div>

            {/* Mobile menu button (hidden on desktop) */}
            <div className="flex items-center space-x-4 lg:hidden hidden">
              <Link
                to="/cart"
                className="text-white hover:text-primary-orange transition-colors relative"
              >
                <ShoppingCart className="h-6 w-6" />
                {cartItemCount > 0 && (
                  <span className="absolute -top-2 -right-2 bg-primary-orange text-white text-xs rounded-full h-5 w-5 flex items-center justify-center">
                    {cartItemCount}
                  </span>
                )}
              </Link>

              <button
                onClick={() => setIsMenuOpen(!isMenuOpen)}
                className="text-white hover:text-primary-orange transition-colors focus:outline-none"
              >
                {isMenuOpen ? (
                  <X className="h-6 w-6" />
                ) : (
                  <Menu className="h-6 w-6" />
                )}
              </button>
            </div>
          </div>
        </div>

        {/* Original Mobile menu (slide-out menu) */}
        <div
          className={`${
            isMenuOpen ? "block" : "hidden"
          } lg:hidden absolute w-full bg-white shadow-lg z-50`}
        >
          <div className="px-4 pt-4 pb-4 space-y-3">
            <Link
              to="/"
              className="flex items-center space-x-2 px-3 py-2 rounded-md text-gray-600 hover:text-primary-orange hover:bg-gray-50"
              onClick={() => setIsMenuOpen(false)}
            >
              <Home className="h-5 w-5" />
              <span>Home</span>
            </Link>
            <Link
              to="/wishlist"
              className="flex items-center space-x-2 px-3 py-2 rounded-md text-gray-600 hover:text-primary-orange hover:bg-gray-50"
              onClick={() => setIsMenuOpen(false)}
            >
              <Heart className="h-5 w-5" />
              <span>Wishlist</span>
            </Link>

            <Link
              to="/cart"
              className="flex items-center space-x-2 px-3 py-2 rounded-md text-gray-600 hover:text-primary-orange hover:bg-gray-50"
              onClick={() => setIsMenuOpen(false)}
            >
              <ShoppingCart className="h-5 w-5" />
              <span>Cart ({cartItemCount})</span>
            </Link>

            {isLoggedIn ? (
              <>
                {isAdmin && (
                  <Link
                    to="/admin"
                    className="flex items-center space-x-2 px-3 py-2 rounded-md text-gray-600 hover:text-primary-orange hover:bg-gray-50"
                    onClick={() => setIsMenuOpen(false)}
                  >
                    <LayoutDashboard className="h-5 w-5" />
                    <span>Dashboard</span>
                  </Link>
                )}
                <Link
                  to="/orders"
                  className="flex items-center space-x-2 px-3 py-2 rounded-md text-gray-600 hover:text-primary-orange hover:bg-gray-50"
                  onClick={() => setIsMenuOpen(false)}
                >
                  <ShoppingCart className="h-5 w-5" />
                  <span>My Orders</span>
                </Link>
                <Link
                  to="/settings"
                  className="flex items-center space-x-2 px-3 py-2 rounded-md text-gray-600 hover:text-primary-orange hover:bg-gray-50"
                  onClick={() => setIsMenuOpen(false)}
                >
                  <Settings className="h-5 w-5" />
                  <span>Settings</span>
                </Link>
                <button
                  onClick={() => {
                    handleSignOut();
                    setIsMenuOpen(false);
                  }}
                  className="flex w-full items-center space-x-2 px-3 py-2 rounded-md text-gray-600 hover:text-primary-orange hover:bg-gray-50"
                >
                  <LogIn className="h-5 w-5" />
                  <span>Logout</span>
                </button>
              </>
            ) : (
              <Link
                to="/login"
                className="flex items-center space-x-2 px-3 py-2 rounded-md text-gray-600 hover:text-primary-orange hover:bg-gray-50"
                onClick={() => setIsMenuOpen(false)}
              >
                <LogIn className="h-5 w-5" />
                <span>Login</span>
              </Link>
            )}
          </div>
        </div>
      </header>
    </>
  );
}

// Add this to your global CSS file (e.g., index.css or App.css)
// if you haven't already, to hide scrollbars for the category list.
/*
.hide-scrollbar {
  -ms-overflow-style: none;
  scrollbar-width: none;
}

.hide-scrollbar::-webkit-scrollbar {
  display: none;
}
*/
