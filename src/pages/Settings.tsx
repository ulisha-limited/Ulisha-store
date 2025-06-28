import React, { useState, useEffect } from 'react';
import { DollarSign, Bell, Lock, User, Shield, Eye, EyeOff } from 'lucide-react';
import { useAuthStore } from '../store/authStore';
import { useCurrencyStore } from '../store/currencyStore';
import { supabase } from '../lib/supabase';

export function Settings() {
  const [loading, setLoading] = useState(false);
  const [notifications, setNotifications] = useState({
    orderUpdates: true,
    promotions: true,
    security: true
  });
  const [showChangePassword, setShowChangePassword] = useState(false);
  const [passwordData, setPasswordData] = useState({
    currentPassword: '',
    newPassword: '',
    confirmPassword: ''
  });
  const [showPasswords, setShowPasswords] = useState({
    current: false,
    new: false,
    confirm: false
  });
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const user = useAuthStore((state) => state.user);
  const { currency, setCurrency, loading: currencyLoading, initialize } = useCurrencyStore();

  useEffect(() => {
    loadUserPreferences();
    initialize();
  }, [user, initialize]);

  const loadUserPreferences = async () => {
    if (!user) return;

    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('user_preferences')
        .select('*')
        .eq('user_id', user.id)
        .single();

      if (error && error.code !== 'PGRST116') throw error;

      if (data) {
        setNotifications({
          orderUpdates: data.order_updates ?? true,
          promotions: data.promotions ?? true,
          security: data.security_alerts ?? true
        });
      }
    } catch (error) {
      console.error('Error loading preferences:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCurrencyChange = async (newCurrency: 'NGN' | 'USD') => {
    try {
      await setCurrency(newCurrency);
      showNotification('Currency preference updated successfully', 'success');
    } catch (error) {
      showNotification('Failed to update currency preference', 'error');
    }
  };

  const handleNotificationChange = async (type: keyof typeof notifications) => {
    if (!user) return;

    try {
      setLoading(true);
      const updates = { ...notifications, [type]: !notifications[type] };
      setNotifications(updates);

      const { error } = await supabase
        .from('user_preferences')
        .upsert({
          user_id: user.id,
          order_updates: updates.orderUpdates,
          promotions: updates.promotions,
          security_alerts: updates.security,
          currency: currency // Include current currency
        });

      if (error) throw error;
      showNotification('Notification preferences updated successfully', 'success');
    } catch (error) {
      console.error('Error updating notifications:', error);
      showNotification('Failed to update notification preferences', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handlePasswordChange = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!user) return;

    try {
      setLoading(true);
      setError(null);

      if (passwordData.newPassword !== passwordData.confirmPassword) {
        throw new Error('New passwords do not match');
      }

      const { error } = await supabase.auth.updateUser({
        password: passwordData.newPassword
      });

      if (error) throw error;

      setPasswordData({
        currentPassword: '',
        newPassword: '',
        confirmPassword: ''
      });
      setShowChangePassword(false);
      showNotification('Password updated successfully', 'success');
    } catch (error: any) {
      console.error('Error updating password:', error);
      showNotification(error.message || 'Failed to update password', 'error');
    } finally {
      setLoading(false);
    }
  };

  const showNotification = (message: string, type: 'success' | 'error') => {
    if (type === 'success') {
      setSuccess(message);
      setError(null);
    } else {
      setError(message);
      setSuccess(null);
    }

    setTimeout(() => {
      setSuccess(null);
      setError(null);
    }, 5000);
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="space-y-6">
          {/* Notifications */}
          {(success || error) && (
            <div className={`p-4 rounded-md ${success ? 'bg-green-50' : 'bg-red-50'}`}>
              <p className={`text-sm ${success ? 'text-green-800' : 'text-red-800'}`}>
                {success || error}
              </p>
            </div>
          )}

          {/* Currency Settings */}
          <div className="bg-white rounded-lg shadow-md overflow-hidden">
            <div className="p-6">
              <h2 className="text-xl font-bold text-gray-900 mb-6">Currency Preferences</h2>
              <div className="bg-gray-50 p-4 rounded-lg">
                <div className="flex items-center space-x-4 mb-4">
                  <button
                    onClick={() => handleCurrencyChange('NGN')}
                    disabled={loading || currencyLoading}
                    className={`px-6 py-3 rounded-md flex items-center space-x-2 transition-all ${
                      currency === 'NGN'
                        ? 'bg-primary-orange text-white shadow-md'
                        : 'bg-white border border-gray-300 text-gray-700 hover:bg-gray-50'
                    } ${(loading || currencyLoading) ? 'opacity-50 cursor-not-allowed' : ''}`}
                  >
                    <span className="text-lg">₦</span>
                    <span className="font-medium">Nigerian Naira (NGN)</span>
                  </button>

                  <button
                    onClick={() => handleCurrencyChange('USD')}
                    disabled={loading || currencyLoading}
                    className={`px-6 py-3 rounded-md flex items-center space-x-2 transition-all ${
                      currency === 'USD'
                        ? 'bg-primary-orange text-white shadow-md'
                        : 'bg-white border border-gray-300 text-gray-700 hover:bg-gray-50'
                    } ${(loading || currencyLoading) ? 'opacity-50 cursor-not-allowed' : ''}`}
                  >
                    <DollarSign className="w-5 h-5" />
                    <span className="font-medium">US Dollar (USD)</span>
                  </button>
                </div>

                <div className="text-sm text-gray-600 space-y-2">
                  <p className="flex items-center justify-between">
                    <span>Current selection:</span>
                    <span className="font-medium text-gray-900">
                      {currency === 'NGN' ? 'Nigerian Naira (₦)' : 'US Dollar ($)'}
                    </span>
                  </p>
                  <p className="flex items-center justify-between">
                    <span>Exchange rate:</span>
                    <span className="font-medium text-gray-900">1 USD = ₦1,630</span>
                  </p>
                  {currency === 'USD' && (
                    <div className="mt-3 p-3 bg-blue-50 rounded-md">
                      <p className="text-blue-800 text-sm">
                        <strong>Note:</strong> Prices are converted from Nigerian Naira for display purposes. 
                        All payments are processed in NGN through our local payment gateway.
                      </p>
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>

          {/* Notification Settings */}
          <div className="bg-white rounded-lg shadow-md overflow-hidden">
            <div className="p-6">
              <h2 className="text-xl font-bold text-gray-900 mb-6">Notification Preferences</h2>
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-3">
                    <Bell className="w-5 h-5 text-gray-400" />
                    <div>
                      <p className="font-medium text-gray-900">Order Updates</p>
                      <p className="text-sm text-gray-500">Receive notifications about your orders</p>
                    </div>
                  </div>
                  <label className="relative inline-flex items-center cursor-pointer">
                    <input
                      type="checkbox"
                      checked={notifications.orderUpdates}
                      onChange={() => handleNotificationChange('orderUpdates')}
                      className="sr-only peer"
                      disabled={loading}
                    />
                    <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary-orange/20 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary-orange"></div>
                  </label>
                </div>

                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-3">
                    <Bell className="w-5 h-5 text-gray-400" />
                    <div>
                      <p className="font-medium text-gray-900">Promotions</p>
                      <p className="text-sm text-gray-500">Receive notifications about deals and offers</p>
                    </div>
                  </div>
                  <label className="relative inline-flex items-center cursor-pointer">
                    <input
                      type="checkbox"
                      checked={notifications.promotions}
                      onChange={() => handleNotificationChange('promotions')}
                      className="sr-only peer"
                      disabled={loading}
                    />
                    <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary-orange/20 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary-orange"></div>
                  </label>
                </div>

                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-3">
                    <Shield className="w-5 h-5 text-gray-400" />
                    <div>
                      <p className="font-medium text-gray-900">Security Alerts</p>
                      <p className="text-sm text-gray-500">Receive notifications about security updates</p>
                    </div>
                  </div>
                  <label className="relative inline-flex items-center cursor-pointer">
                    <input
                      type="checkbox"
                      checked={notifications.security}
                      onChange={() => handleNotificationChange('security')}
                      className="sr-only peer"
                      disabled={loading}
                    />
                    <div className="w-11 h-6 bg-gray-200 peer-focus:outline-none peer-focus:ring-4 peer-focus:ring-primary-orange/20 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary-orange"></div>
                  </label>
                </div>
              </div>
            </div>
          </div>

          {/* Security Settings */}
          <div className="bg-white rounded-lg shadow-md overflow-hidden">
            <div className="p-6">
              <h2 className="text-xl font-bold text-gray-900 mb-6">Security Settings</h2>
              
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-3">
                    <Lock className="w-5 h-5 text-gray-400" />
                    <div>
                      <p className="font-medium text-gray-900">Password</p>
                      <p className="text-sm text-gray-500">Change your account password</p>
                    </div>
                  </div>
                  <button
                    onClick={() => setShowChangePassword(!showChangePassword)}
                    className="text-primary-orange hover:text-primary-orange/90 font-medium"
                  >
                    Change Password
                  </button>
                </div>

                {showChangePassword && (
                  <form onSubmit={handlePasswordChange} className="mt-4 space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700">Current Password</label>
                      <div className="mt-1 relative">
                        <input
                          type={showPasswords.current ? 'text' : 'password'}
                          value={passwordData.currentPassword}
                          onChange={(e) => setPasswordData({ ...passwordData, currentPassword: e.target.value })}
                          className="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-orange focus:ring-primary-orange sm:text-sm"
                          required
                        />
                        <button
                          type="button"
                          onClick={() => setShowPasswords({ ...showPasswords, current: !showPasswords.current })}
                          className="absolute inset-y-0 right-0 pr-3 flex items-center"
                        >
                          {showPasswords.current ? (
                            <EyeOff className="h-4 w-4 text-gray-400" />
                          ) : (
                            <Eye className="h-4 w-4 text-gray-400" />
                          )}
                        </button>
                      </div>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700">New Password</label>
                      <div className="mt-1 relative">
                        <input
                          type={showPasswords.new ? 'text' : 'password'}
                          value={passwordData.newPassword}
                          onChange={(e) => setPasswordData({ ...passwordData, newPassword: e.target.value })}
                          className="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-orange focus:ring-primary-orange sm:text-sm"
                          required
                        />
                        <button
                          type="button"
                          onClick={() => setShowPasswords({ ...showPasswords, new: !showPasswords.new })}
                          className="absolute inset-y-0 right-0 pr-3 flex items-center"
                        >
                          {showPasswords.new ? (
                            <EyeOff className="h-4 w-4 text-gray-400" />
                          ) : (
                            <Eye className="h-4 w-4 text-gray-400" />
                          )}
                        </button>
                      </div>
                    </div>

                    <div>
                      <label className="block text-sm font-medium text-gray-700">Confirm New Password</label>
                      <div className="mt-1 relative">
                        <input
                          type={showPasswords.confirm ? 'text' : 'password'}
                          value={passwordData.confirmPassword}
                          onChange={(e) => setPasswordData({ ...passwordData, confirmPassword: e.target.value })}
                          className="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-orange focus:ring-primary-orange sm:text-sm"
                          required
                        />
                        <button
                          type="button"
                          onClick={() => setShowPasswords({ ...showPasswords, confirm: !showPasswords.confirm })}
                          className="absolute inset-y-0 right-0 pr-3 flex items-center"
                        >
                          {showPasswords.confirm ? (
                            <EyeOff className="h-4 w-4 text-gray-400" />
                          ) : (
                            <Eye className="h-4 w-4 text-gray-400" />
                          )}
                        </button>
                      </div>
                    </div>

                    <div className="flex justify-end space-x-3">
                      <button
                        type="button"
                        onClick={() => setShowChangePassword(false)}
                        className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
                      >
                        Cancel
                      </button>
                      <button
                        type="submit"
                        disabled={loading}
                        className="px-4 py-2 bg-primary-orange text-white rounded-md hover:bg-primary-orange/90 disabled:opacity-50"
                      >
                        {loading ? 'Updating...' : 'Update Password'}
                      </button>
                    </div>
                  </form>
                )}
              </div>
            </div>
          </div>

          {/* Account Settings */}
          <div className="bg-white rounded-lg shadow-md overflow-hidden">
            <div className="p-6">
              <h2 className="text-xl font-bold text-gray-900 mb-6">Account Settings</h2>
              <div className="space-y-4">
                <div className="flex items-center space-x-3">
                  <User className="w-5 h-5 text-gray-400" />
                  <div>
                    <p className="font-medium text-gray-900">Email Address</p>
                    <p className="text-sm text-gray-500">{user?.email}</p>
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