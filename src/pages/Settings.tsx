import React, { useState, useEffect } from 'react';
import { DollarSign } from 'lucide-react';
import { useAuthStore } from '../store/authStore';

export function Settings() {
  const [currency, setCurrency] = useState<'NGN' | 'USD'>('NGN');
  const [loading, setLoading] = useState(false);
  const user = useAuthStore((state) => state.user);

  useEffect(() => {
    const savedCurrency = localStorage.getItem('currency') as 'NGN' | 'USD';
    if (savedCurrency) {
      setCurrency(savedCurrency);
    }
  }, []);

  const handleCurrencyChange = async (newCurrency: 'NGN' | 'USD') => {
    try {
      setLoading(true);
      setCurrency(newCurrency);
      localStorage.setItem('currency', newCurrency);

      // Notify other components of currency change
      window.dispatchEvent(
        new CustomEvent('currencyChange', {
          detail: { currency: newCurrency },
        })
      );
    } catch (error) {
      console.error('Error updating currency:', error);
    } finally {
      setLoading(false);
    }
  };

  const formatPrice = (price: number, currency: 'NGN' | 'USD') => {
    if (currency === 'USD') {
      return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD',
      }).format(price / 1630);
    }
    return new Intl.NumberFormat('en-NG', {
      style: 'currency',
      currency: 'NGN',
    }).format(price);
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="bg-white rounded-lg shadow-md overflow-hidden">
          <div className="p-6">
            <h2 className="text-xl font-bold text-gray-900 mb-6">Settings</h2>

            <div className="space-y-6">
              <div>
                <h3 className="text-lg font-medium text-gray-900 mb-4">Currency Preferences</h3>
                <div className="bg-gray-50 p-4 rounded-lg">
                  <div className="flex items-center space-x-4">
                    <button
                      onClick={() => handleCurrencyChange('NGN')}
                      className={`px-4 py-2 rounded-md flex items-center space-x-2 ${
                        currency === 'NGN'
                          ? 'bg-primary-orange text-white'
                          : 'bg-white border border-gray-300 text-gray-700 hover:bg-gray-50'
                      }`}
                      disabled={loading}
                    >
                      <span>₦ NGN</span>
                    </button>

                    <button
                      onClick={() => handleCurrencyChange('USD')}
                      className={`px-4 py-2 rounded-md flex items-center space-x-2 ${
                        currency === 'USD'
                          ? 'bg-primary-orange text-white'
                          : 'bg-white border border-gray-300 text-gray-700 hover:bg-gray-50'
                      }`}
                      disabled={loading}
                    >
                      <DollarSign className="w-4 h-4" />
                      <span>USD</span>
                    </button>
                  </div>

                  <p className="mt-2 text-sm text-gray-500">
                    Current exchange rate: 1 USD = ₦1,630
                  </p>

                  <div className="mt-4">
                    <h4 className="text-sm font-medium text-gray-700 mb-2">Example Price Conversion:</h4>
                    <p className="text-sm text-gray-600">
                      ₦10,000 = {formatPrice(10000, 'USD')}
                    </p>
                  </div>
                </div>
              </div>
            </div>

          </div>
        </div>
      </div>
    </div>
  );
}
