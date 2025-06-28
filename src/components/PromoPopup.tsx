import React, { useState, useEffect } from 'react';
import { X, ShoppingBag, Star, Percent, ArrowRight, Gift } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { useCurrencyStore } from '../store/currencyStore';
import type { Product } from '../types';

interface PromoPopupProps {
  isVisible: boolean;
  onClose: () => void;
}

export function PromoPopup({ isVisible, onClose }: PromoPopupProps) {
  const [featuredProduct, setFeaturedProduct] = useState<Product | null>(null);
  const [loading, setLoading] = useState(true);
  const [isSecondShow, setIsSecondShow] = useState(false);
  const navigate = useNavigate();
  const { formatPrice } = useCurrencyStore();

  useEffect(() => {
    if (isVisible) {
      checkIfSecondShow();
      fetchRandomDiscountedProduct();
    }
  }, [isVisible]);

  const checkIfSecondShow = () => {
    const popupData = localStorage.getItem('promo_popup_data');
    if (popupData) {
      try {
        const data = JSON.parse(popupData);
        setIsSecondShow(data.showCount >= 1);
      } catch (error) {
        setIsSecondShow(false);
      }
    }
  };

  const fetchRandomDiscountedProduct = async () => {
    try {
      setLoading(true);
      
      // Fetch products with active discounts
      const { data: discountedProducts, error } = await supabase
        .from('products')
        .select('*')
        .eq('discount_active', true)
        .not('discount_percentage', 'is', null)
        .gte('discount_percentage', 10) // At least 10% discount
        .limit(20); // Get a pool of products to choose from

      if (error) throw error;

      if (discountedProducts && discountedProducts.length > 0) {
        // Select a random product from the discounted products
        const randomIndex = Math.floor(Math.random() * discountedProducts.length);
        setFeaturedProduct(discountedProducts[randomIndex]);
      } else {
        // Fallback: get any random product if no discounted products
        const { data: allProducts, error: allError } = await supabase
          .from('products')
          .select('*')
          .limit(10);

        if (!allError && allProducts && allProducts.length > 0) {
          const randomIndex = Math.floor(Math.random() * allProducts.length);
          setFeaturedProduct(allProducts[randomIndex]);
        }
      }
    } catch (error) {
      console.error('Error fetching random product:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleShopNow = () => {
    if (featuredProduct) {
      navigate(`/product/${featuredProduct.id}`);
      onClose();
    }
  };

  const handleRegister = () => {
    navigate('/register');
    onClose();
  };

  if (!isVisible) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl max-w-md w-full mx-4 overflow-hidden shadow-2xl transform transition-all animate-fade-in">
        {/* Header */}
        <div className={`relative ${isSecondShow 
          ? 'bg-gradient-to-r from-purple-600 to-pink-600' 
          : 'bg-gradient-to-r from-primary-orange to-red-500'
        } p-6 text-white`}>
          <button
            onClick={onClose}
            className="absolute top-4 right-4 text-white hover:text-gray-200 transition-colors"
          >
            <X className="w-6 h-6" />
          </button>
          
          <div className="text-center">
            <div className="flex items-center justify-center mb-2">
              {isSecondShow ? (
                <Gift className="w-8 h-8 mr-2" />
              ) : (
                <ShoppingBag className="w-8 h-8 mr-2" />
              )}
              <span className="text-2xl font-bold">UlishaStore</span>
            </div>
            <h2 className="text-xl font-bold mb-1">
              {isSecondShow ? 'Last Chance for Sweet Deals!' : 'Sweet Product Sales!'}
            </h2>
            <p className="text-sm opacity-90">
              {isSecondShow 
                ? 'Don\'t miss out on these exclusive discounts' 
                : 'Register now and enjoy exclusive discounts'
              }
            </p>
          </div>
        </div>

        {/* Product Showcase */}
        <div className="p-6">
          {loading ? (
            <div className="flex items-center justify-center py-8">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-orange"></div>
            </div>
          ) : featuredProduct ? (
            <div className="text-center">
              {/* Product Image */}
              <div className="relative mb-4">
                <img
                  src={featuredProduct.image}
                  alt={featuredProduct.name}
                  className="w-full h-48 object-cover rounded-lg"
                />
                {featuredProduct.discount_active && featuredProduct.discount_percentage && (
                  <div className="absolute top-2 left-2 bg-red-500 text-white px-2 py-1 rounded-full flex items-center space-x-1">
                    <Percent className="w-3 h-3" />
                    <span className="text-xs font-bold">{featuredProduct.discount_percentage}% OFF</span>
                  </div>
                )}
                {isSecondShow && (
                  <div className="absolute top-2 right-2 bg-purple-600 text-white px-2 py-1 rounded-full">
                    <span className="text-xs font-bold">LIMITED TIME</span>
                  </div>
                )}
              </div>

              {/* Product Info */}
              <div className="mb-4">
                <span className="inline-block bg-gray-100 text-gray-600 text-xs px-2 py-1 rounded-full mb-2">
                  {featuredProduct.category}
                </span>
                <h3 className="font-semibold text-gray-900 mb-2 line-clamp-2">
                  {featuredProduct.name}
                </h3>
                
                {/* Rating */}
                <div className="flex items-center justify-center mb-3">
                  <div className="flex items-center text-orange-400">
                    {[...Array(5)].map((_, i) => (
                      <Star key={i} className={`w-4 h-4 ${(featuredProduct.rating || 5) > i ? 'fill-current' : 'text-gray-300'}`} />
                    ))}
                  </div>
                  <span className="text-sm text-gray-500 ml-2">({featuredProduct.rating || 5})</span>
                </div>

                {/* Price */}
                <div className="mb-4">
                  {featuredProduct.discount_active && featuredProduct.original_price ? (
                    <div className="space-y-1">
                      <div className="text-2xl font-bold text-primary-orange">
                        {formatPrice(featuredProduct.price)}
                      </div>
                      <div className="flex items-center justify-center space-x-2">
                        <span className="text-lg text-gray-500 line-through">
                          {formatPrice(featuredProduct.original_price)}
                        </span>
                        <span className="text-green-600 font-medium text-sm">
                          Save {featuredProduct.discount_percentage}%
                        </span>
                      </div>
                    </div>
                  ) : (
                    <div className="text-2xl font-bold text-primary-orange">
                      {formatPrice(featuredProduct.price)}
                    </div>
                  )}
                </div>
              </div>

              {/* Call to Action */}
              <div className="space-y-3">
                <button
                  onClick={handleShopNow}
                  className={`w-full ${isSecondShow 
                    ? 'bg-purple-600 hover:bg-purple-700' 
                    : 'bg-primary-orange hover:bg-primary-orange/90'
                  } text-white py-3 px-4 rounded-lg font-medium transition-colors flex items-center justify-center space-x-2`}
                >
                  <ShoppingBag className="w-5 h-5" />
                  <span>{isSecondShow ? 'Grab This Deal' : 'Shop Now'}</span>
                  <ArrowRight className="w-4 h-4" />
                </button>
                
                <div className="text-center">
                  <p className="text-sm text-gray-600 mb-2">
                    {isSecondShow 
                      ? 'Join thousands of happy customers!' 
                      : 'Want to see more amazing deals?'
                    }
                  </p>
                  <button
                    onClick={handleRegister}
                    className={`w-full ${isSecondShow 
                      ? 'bg-gradient-to-r from-pink-500 to-purple-600 hover:from-pink-600 hover:to-purple-700' 
                      : 'bg-gradient-to-r from-blue-500 to-blue-600 hover:from-blue-600 hover:to-blue-700'
                    } text-white py-3 px-4 rounded-lg font-medium transition-all transform hover:scale-105`}
                  >
                    {isSecondShow ? 'Register & Save More!' : 'Register for Exclusive Discounts'}
                  </button>
                </div>
              </div>

              {/* Benefits */}
              <div className={`mt-4 p-3 ${isSecondShow ? 'bg-purple-50' : 'bg-gray-50'} rounded-lg`}>
                <p className="text-xs text-gray-600 text-center">
                  {isSecondShow ? (
                    <>🔥 <strong>Final Offer:</strong> Up to 25% off • Free shipping • VIP access</>
                  ) : (
                    <>🎉 <strong>Register Benefits:</strong> Up to 20% off • Free shipping • Early access to sales</>
                  )}
                </p>
              </div>

              {/* Second show urgency indicator */}
              {isSecondShow && (
                <div className="mt-3 text-center">
                  <p className="text-xs text-purple-600 font-medium">
                    ⏰ This offer won't appear again for another hour!
                  </p>
                </div>
              )}
            </div>
          ) : (
            <div className="text-center py-8">
              <ShoppingBag className="w-12 h-12 text-gray-400 mx-auto mb-4" />
              <h3 className="text-lg font-semibold text-gray-900 mb-2">
                {isSecondShow ? 'Final Call for Amazing Deals!' : 'Amazing Deals Await!'}
              </h3>
              <p className="text-gray-600 mb-4">
                {isSecondShow 
                  ? 'Last chance to register and unlock exclusive discounts' 
                  : 'Register now to discover incredible discounts on quality products'
                }
              </p>
              <button
                onClick={handleRegister}
                className={`w-full ${isSecondShow 
                  ? 'bg-purple-600 hover:bg-purple-700' 
                  : 'bg-primary-orange hover:bg-primary-orange/90'
                } text-white py-3 px-4 rounded-lg font-medium transition-colors`}
              >
                {isSecondShow ? 'Register Now - Final Chance!' : 'Register Now'}
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}