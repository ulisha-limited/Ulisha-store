import React, { useState, useEffect } from 'react';
import { ProductCard } from '../../components/ProductCard';
import { AdCarousel } from '../../components/AdCarousel';
import { PromoPopup } from '../../components/PromoPopup';
import { Search, ChevronDown, Facebook, Twitter, Instagram, Youtube, Phone } from 'lucide-react';
import { supabase } from '../../lib/supabase';
import type { Product } from '../../types';
import { useLocation, Link, useParams } from 'react-router-dom';
import { fallbackProducts } from '../../lib/supabase';
import { usePromoPopup } from '../../hooks/usePromoPopup';

const categories = [
  'All Categories', 
  'Clothes', 
  'Accessories', 
  'Shoes', 
  'Smart Watches', 
  'Electronics',
  'Perfumes & Body Spray',
  'Phones',
  'Handbags',
  'Jewelries',
  'Gym Wear'
  
];

const MAX_RETRIES = 3;
const RETRY_DELAY = 1000; // 1 second

export function ProductList() {
  const { category } = useParams<{ category: string }>();
  const [searchQuery, setSearchQuery] = useState("");
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [usesFallback, setUsesFallback] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const location = useLocation();

  // Promo popup hook
  const { showPopup, closePopup } = usePromoPopup();

  useEffect(() => {
    fetchProductsWithRetry();

    // Parse URL parameters
    const params = new URLSearchParams(location.search);
    const searchParam = params.get("search");

    if (searchParam) {
      setSearchQuery(searchParam);
    }

    // Subscribe to product changes
    const productsSubscription = supabase
      .channel("products-changes")
      .on(
        "postgres_changes",
        {
          event: "*",
          schema: "public",
          table: "products",
        },
        () => {
          fetchProductsWithRetry();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(productsSubscription);
    };
  }, [location.search, category]);

  const delay = (ms: number) =>
    new Promise((resolve) => setTimeout(resolve, ms));

  const fetchProductsWithRetry = async (retryCount = 0) => {
    try {
      setLoading(true);
      setError(null);

      // Check if we have a valid session first
      const {
        data: { session },
        error: sessionError,
      } = await supabase.auth.getSession();

      if (sessionError) {
        console.error("Session check error:", sessionError);
      }

      const { data, error } = await supabase
        .from("products")
        .select("*")
        .ilike("category", `%${(category ?? "").replace(/-/g, " ")}%`)
        .order("created_at", { ascending: false });

      if (error) {
        // Network or connection errors
        if (
          error.code === "PGRST301" ||
          error.message?.includes("Failed to fetch")
        ) {
          if (retryCount < MAX_RETRIES) {
            console.log(
              `Retrying fetch attempt ${retryCount + 1} of ${MAX_RETRIES}...`
            );
            await delay(RETRY_DELAY * (retryCount + 1));
            return fetchProductsWithRetry(retryCount + 1);
          }
          console.error("Max retries reached, using fallback data");
          setProducts(fallbackProducts);
          setUsesFallback(true);
          setError(
            "Unable to connect to the server. Showing offline product data."
          );
          return;
        }

        // Authentication errors
        if (error.code === "JWT_INVALID") {
          console.error("Authentication error:", error);
          setProducts(fallbackProducts);
          setUsesFallback(true);
          return;
        }

        throw error;
      }

      if (data && data.length > 0) {
        setProducts(data);
        setUsesFallback(false);
        setError(null);
      } else {
        console.log("No products found in database, using fallback data");
        setProducts(fallbackProducts);
        setUsesFallback(true);
      }
    } catch (error) {
      console.error("Error fetching products:", error);
      setError(
        "Unable to load products. Please check your connection and try again."
      );
      setProducts(fallbackProducts);
      setUsesFallback(true);
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <div className="min-h-screen bg-gray-100 flex flex-col">
        <div className="flex-grow">
          {/* Add contact banner */}
          <div className="bg-primary-orange text-white py-2">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
              <div className="flex items-center justify-center sm:justify-end space-x-4 text-sm">
                <a
                  href="tel:+2347060438205"
                  className="flex items-center hover:text-white/90 transition-colors"
                >
                  <Phone className="h-4 w-4 mr-2" />
                  <span>Call to place order: +234 913 478 1219</span>
                </a>
              </div>
            </div>
          </div>

          {/* Ad Carousel */}
          <AdCarousel className="mb-8" />

          <div className="bg-white shadow-sm" id="products-section">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
              <div className="flex flex-col sm:flex-row gap-4">
                <div className="flex-1 relative">
                  <input
                    type="text"
                    placeholder="Search products..."
                    className="w-full pl-10 pr-4 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-orange-500"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                  />
                  <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                </div>
              </div>
            </div>
          </div>

          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
            <div className="flex items-center justify-between mb-6">
              <h1 className="text-xl font-bold text-gray-900 capitalize">
                {category ? category : ""}
              </h1>
            </div>

            {error && (
              <div className="bg-red-50 border-l-4 border-red-400 p-4 mb-6">
                <div className="flex">
                  <div className="ml-3">
                    <p className="text-sm text-red-700">{error}</p>
                  </div>
                </div>
              </div>
            )}

            {usesFallback && (
              <div className="bg-yellow-50 border-l-4 border-yellow-400 p-4 mb-6">
                <div className="flex">
                  <div className="ml-3">
                    <p className="text-sm text-yellow-700">
                      Currently showing demo products. Admin products will
                      appear here once uploaded.
                    </p>
                  </div>
                </div>
              </div>
            )}

            {loading ? (
              <div className="flex items-center justify-center py-12">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-orange"></div>
              </div>
            ) : (
              <>
                <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4">
                  {products.map((product) => (
                    <ProductCard key={product.id} product={product} />
                  ))}
                </div>

                {products.length === 0 && (
                  <div className="text-center py-12">
                    <p className="text-gray-500">
                      No products found matching your criteria.
                    </p>
                  </div>
                )}
              </>
            )}
          </div>
        </div>
      </div>

      {/* Promotional Popup */}
      <PromoPopup isVisible={showPopup} onClose={closePopup} />
    </>
  );
}