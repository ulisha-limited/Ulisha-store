import React, { useState, useEffect } from 'react';
import { DollarSign, Bell, Lock, User, Shield, Eye, EyeOff, Mail, Phone } from 'lucide-react';
import { useAuthStore } from '../store/authStore';
import { useCurrencyStore } from '../store/currencyStore';
import { supabase } from '../lib/supabase';
import { OtpInput } from '../components/OtpInput';
import { EmailOTPService, OTPService } from '../lib/firebase';

export function Settings() {
  const [loading, setLoading] = useState(false);
  const [notifications, setNotifications] = useState({
    orderUpdates: true,
    promotions: true,
    security: true
  });
  const [showChangePassword, setShowChangePassword] = useState(false);
  const [showOtpVerification, setShowOtpVerification] = useState(false);
  const [otpMethod, setOtpMethod] = useState<'email' | 'phone'>('email');
  const [phoneNumber, setPhoneNumber] = useState('');
  const [passwordData, setPasswordData] = useState({
    currentPassword: '',
    newPassword: '',
    confirmPassword: ''
  });
  const [otpData, setOtpData] = useState({
    otp: ['', '', '', '', '', ''],
    isVerifying: false,
    canResend: false,
    countdown: 60
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

  // OTP Services
  const [emailOTPService] = useState(() => new EmailOTPService());
  const [phoneOTPService] = useState(() => new OTPService());

  useEffect(() => {
    loadUserPreferences();
    initialize();

    // Initialize reCAPTCHA for phone OTP
    const initRecaptcha = async () => {
      try {
        await phoneOTPService.initializeRecaptcha();
      } catch (error) {
        console.error('Failed to initialize reCAPTCHA:', error);
      }
    };

    initRecaptcha();

    // Cleanup on unmount
    return () => {
      emailOTPService.cleanup();
      phoneOTPService.cleanup();
    };
  }, [user, initialize]);

  // Countdown timer for OTP resend
  useEffect(() => {
    let interval: NodeJS.Timeout;
    if (showOtpVerification && otpData.countdown > 0) {
      interval = setInterval(() => {
        setOtpData(prev => {
          const newCountdown = prev.countdown - 1;
          if (newCountdown === 0) {
            return { ...prev, countdown: 0, canResend: true };
          }
          return { ...prev, countdown: newCountdown };
        });
      }, 1000);
    }
    return () => clearInterval(interval);
  }, [showOtpVerification, otpData.countdown]);

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
          currency: currency
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

  const sendOtpForPasswordChange = async () => {
    if (!user) return;

    try {
      setLoading(true);
      setError(null);

      // Validate password fields first
      if (passwordData.newPassword !== passwordData.confirmPassword) {
        throw new Error('New passwords do not match');
      }

      if (passwordData.newPassword.length < 6) {
        throw new Error('New password must be at least 6 characters long');
      }

      if (otpMethod === 'email') {
        await emailOTPService.sendEmailOTP(user.email!);
        showNotification('Verification code sent to your email address', 'success');
      } else {
        if (!phoneNumber) {
          throw new Error('Please enter your phone number');
        }
        await phoneOTPService.sendOTP(phoneNumber);
        showNotification('Verification code sent to your phone number', 'success');
      }

      setShowOtpVerification(true);
      setOtpData({
        otp: ['', '', '', '', '', ''],
        isVerifying: false,
        canResend: false,
        countdown: 60
      });

    } catch (error: any) {
      console.error('Error sending OTP:', error);
      showNotification(error.message || 'Failed to send verification code', 'error');
    } finally {
      setLoading(false);
    }
  };

  const verifyOtpAndChangePassword = async () => {
    if (!user) return;

    try {
      setOtpData(prev => ({ ...prev, isVerifying: true }));
      setError(null);

      const otpCode = otpData.otp.join('');
      
      if (otpCode.length !== 6) {
        throw new Error('Please enter the complete 6-digit verification code');
      }

      // Verify the OTP based on method
      let isVerified = false;
      if (otpMethod === 'email') {
        isVerified = await emailOTPService.verifyEmailOTP(user.email!, otpCode);
      } else {
        isVerified = await phoneOTPService.verifyOTP(otpCode);
      }

      if (!isVerified) {
        throw new Error('Invalid verification code. Please try again.');
      }

      // If OTP is valid, update the password
      const { error: passwordError } = await supabase.auth.updateUser({
        password: passwordData.newPassword
      });

      if (passwordError) {
        console.error('Password update error:', passwordError);
        throw new Error('Failed to update password. Please try again.');
      }

      // Reset all states
      setPasswordData({
        currentPassword: '',
        newPassword: '',
        confirmPassword: ''
      });
      setOtpData({
        otp: ['', '', '', '', '', ''],
        isVerifying: false,
        canResend: false,
        countdown: 60
      });
      setPhoneNumber('');
      setShowChangePassword(false);
      setShowOtpVerification(false);

      showNotification('Password updated successfully', 'success');
    } catch (error: any) {
      console.error('Error verifying OTP and updating password:', error);
      showNotification(error.message || 'Failed to verify code and update password', 'error');
    } finally {
      setOtpData(prev => ({ ...prev, isVerifying: false }));
    }
  };

  const resendOtp = async () => {
    if (!user || !otpData.canResend) return;

    try {
      setLoading(true);
      setError(null);

      if (otpMethod === 'email') {
        await emailOTPService.sendEmailOTP(user.email!);
        showNotification('New verification code sent to your email', 'success');
      } else {
        if (!phoneNumber) {
          throw new Error('Please enter your phone number');
        }
        await phoneOTPService.sendOTP(phoneNumber);
        showNotification('New verification code sent to your phone', 'success');
      }

      setOtpData(prev => ({
        ...prev,
        canResend: false,
        countdown: 60,
        otp: ['', '', '', '', '', '']
      }));

    } catch (error: any) {
      console.error('Error resending OTP:', error);
      showNotification(error.message || 'Failed to resend verification code', 'error');
    } finally {
      setLoading(false);
    }
  };

  const handleOtpChange = (newOtp: string[]) => {
    setOtpData(prev => ({ ...prev, otp: newOtp }));
  };

  const handleOtpComplete = (otpString: string) => {
    const otpArray = otpString.split('');
    setOtpData(prev => ({ ...prev, otp: otpArray }));
    // Auto-verify when OTP is complete
    setTimeout(() => {
      verifyOtpAndChangePassword();
    }, 500);
  };

  const cancelPasswordChange = () => {
    setShowChangePassword(false);
    setShowOtpVerification(false);
    setPasswordData({
      currentPassword: '',
      newPassword: '',
      confirmPassword: ''
    });
    setOtpData({
      otp: ['', '', '', '', '', ''],
      isVerifying: false,
      canResend: false,
      countdown: 60
    });
    setPhoneNumber('');
    setError(null);
    
    // Cleanup OTP services
    emailOTPService.cleanup();
    phoneOTPService.cleanup();
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
      {/* Hidden reCAPTCHA container */}
      <div id="recaptcha-container"></div>
      
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
                      <p className="text-sm text-gray-500">Change your account password with OTP verification</p>
                    </div>
                  </div>
                  <button
                    onClick={() => setShowChangePassword(!showChangePassword)}
                    className="text-primary-orange hover:text-primary-orange/90 font-medium"
                  >
                    Change Password
                  </button>
                </div>

                {showChangePassword && !showOtpVerification && (
                  <div className="mt-4 space-y-4 border-t pt-4">
                    <div className="bg-blue-50 p-4 rounded-md">
                      <div className="flex items-center">
                        <Shield className="w-5 h-5 text-blue-600 mr-2" />
                        <p className="text-sm text-blue-800">
                          For your security, we'll send a verification code before changing your password.
                        </p>
                      </div>
                    </div>

                    <form onSubmit={(e) => { e.preventDefault(); sendOtpForPasswordChange(); }} className="space-y-4">
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
                            minLength={6}
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

                      {/* OTP Method Selection */}
                      <div>
                        <label className="block text-sm font-medium text-gray-700 mb-3">Verification Method</label>
                        <div className="flex space-x-4">
                          <label className="flex items-center">
                            <input
                              type="radio"
                              name="otpMethod"
                              value="email"
                              checked={otpMethod === 'email'}
                              onChange={(e) => setOtpMethod(e.target.value as 'email' | 'phone')}
                              className="h-4 w-4 text-primary-orange focus:ring-primary-orange border-gray-300"
                            />
                            <span className="ml-2 text-sm text-gray-700 flex items-center">
                              <Mail className="w-4 h-4 mr-1" />
                              Email ({user?.email})
                            </span>
                          </label>
                          <label className="flex items-center">
                            <input
                              type="radio"
                              name="otpMethod"
                              value="phone"
                              checked={otpMethod === 'phone'}
                              onChange={(e) => setOtpMethod(e.target.value as 'email' | 'phone')}
                              className="h-4 w-4 text-primary-orange focus:ring-primary-orange border-gray-300"
                            />
                            <span className="ml-2 text-sm text-gray-700 flex items-center">
                              <Phone className="w-4 h-4 mr-1" />
                              Phone Number
                            </span>
                          </label>
                        </div>
                      </div>

                      {/* Phone Number Input */}
                      {otpMethod === 'phone' && (
                        <div>
                          <label className="block text-sm font-medium text-gray-700">Phone Number</label>
                          <div className="mt-1">
                            <input
                              type="tel"
                              value={phoneNumber}
                              onChange={(e) => setPhoneNumber(e.target.value)}
                              placeholder="+234 or 0801234567"
                              className="block w-full rounded-md border-gray-300 shadow-sm focus:border-primary-orange focus:ring-primary-orange sm:text-sm"
                              required={otpMethod === 'phone'}
                            />
                            <p className="mt-1 text-xs text-gray-500">
                              Enter your phone number with country code (+234) or starting with 0
                            </p>
                          </div>
                        </div>
                      )}

                      <div className="flex justify-end space-x-3">
                        <button
                          type="button"
                          onClick={cancelPasswordChange}
                          className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
                        >
                          Cancel
                        </button>
                        <button
                          type="submit"
                          disabled={loading || (otpMethod === 'phone' && !phoneNumber)}
                          className="px-4 py-2 bg-primary-orange text-white rounded-md hover:bg-primary-orange/90 disabled:opacity-50 flex items-center space-x-2"
                        >
                          {otpMethod === 'email' ? <Mail className="w-4 h-4" /> : <Phone className="w-4 h-4" />}
                          <span>{loading ? 'Sending Code...' : 'Send Verification Code'}</span>
                        </button>
                      </div>
                    </form>
                  </div>
                )}

                {showOtpVerification && (
                  <div className="mt-4 space-y-4 border-t pt-4">
                    <div className="bg-green-50 p-4 rounded-md">
                      <div className="flex items-center">
                        {otpMethod === 'email' ? <Mail className="w-5 h-5 text-green-600 mr-2" /> : <Phone className="w-5 h-5 text-green-600 mr-2" />}
                        <p className="text-sm text-green-800">
                          We've sent a 6-digit verification code to{' '}
                          <strong>
                            {otpMethod === 'email' ? user?.email : phoneNumber}
                          </strong>
                        </p>
                      </div>
                    </div>

                    <div className="text-center">
                      <label className="block text-sm font-medium text-gray-700 mb-4">
                        Enter Verification Code
                      </label>
                      <OtpInput
                        length={6}
                        value={otpData.otp}
                        onChange={handleOtpChange}
                        onComplete={handleOtpComplete}
                        autoFocus={true}
                      />
                    </div>

                    <div className="flex justify-center">
                      {otpData.canResend ? (
                        <button
                          onClick={resendOtp}
                          disabled={loading}
                          className="text-primary-orange hover:text-primary-orange/90 font-medium text-sm"
                        >
                          Resend Code
                        </button>
                      ) : (
                        <p className="text-sm text-gray-500">
                          Resend code in {otpData.countdown}s
                        </p>
                      )}
                    </div>

                    <div className="flex justify-end space-x-3">
                      <button
                        type="button"
                        onClick={cancelPasswordChange}
                        className="px-4 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50"
                      >
                        Cancel
                      </button>
                      <button
                        onClick={verifyOtpAndChangePassword}
                        disabled={otpData.isVerifying || otpData.otp.join('').length !== 6}
                        className="px-4 py-2 bg-primary-orange text-white rounded-md hover:bg-primary-orange/90 disabled:opacity-50"
                      >
                        {otpData.isVerifying ? 'Verifying...' : 'Verify & Update Password'}
                      </button>
                    </div>
                  </div>
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