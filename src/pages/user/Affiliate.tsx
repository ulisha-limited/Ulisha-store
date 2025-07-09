import React, { useState, useEffect } from 'react';
import { Users, Copy, Check } from 'lucide-react';
import { useAuthStore } from '../../store/authStore';
import { supabase } from '../../lib/supabase';

interface AffiliateAccount {
  id: string;
  referral_code: string;
  earnings: number;
  paid_earnings: number;
  status: string;
  created_at: string;
  referral_count: number;
}

interface AffiliateReferral {
  id: string;
  referred_user: {
    email: string;
    user_metadata: {
      full_name: string;
    };
  };
  created_at: string;
}

export function Affiliate() {
  const [loading, setLoading] = useState(true);
  const [affiliateAccount, setAffiliateAccount] = useState<AffiliateAccount | null>(null);
  const [referralCode, setReferralCode] = useState<string | null>(null);
  const [referralLink, setReferralLink] = useState<string>('');
  const [copySuccess, setCopySuccess] = useState(false);
  const [referrals, setReferrals] = useState<AffiliateReferral[]>([]);
  const [commissionRate, setCommissionRate] = useState(10);
  const [minPayout, setMinPayout] = useState(5000);
  
  const user = useAuthStore((state) => state.user);

  useEffect(() => {
    if (user) {
      fetchAffiliateData();
    }
  }, [user]);

  const fetchAffiliateData = async () => {
    try {
      setLoading(true);

      // Get affiliate settings
      const { data: settings } = await supabase
        .from('affiliate_settings')
        .select('*')
        .maybeSingle();

      if (settings) {
        setCommissionRate(settings.commission_rate);
        setMinPayout(settings.min_payout);
      }

      // Get affiliate account
      const { data: account, error: accountError } = await supabase
        .from('affiliate_accounts')
        .select('*')
        .eq('user_id', user?.id)
        .maybeSingle();

      if (accountError) throw accountError;
      
      if (account) {
        setAffiliateAccount(account);
        setReferralCode(account.referral_code);
        setReferralLink(`${window.location.origin}/register?ref=${account.referral_code}`);

        // Get referrals with auth.users data
        const { data: referralsData, error: referralsError } = await supabase
          .from('affiliate_referrals')
          .select(`
            id,
            created_at,
            referred_user:referred_user_id (
              email,
              user_metadata
            )
          `)
          .eq('referrer_id', account.id)
          .order('created_at', { ascending: false });

        if (referralsError) throw referralsError;
        setReferrals(
          (referralsData || []).map((ref: any) => ({
            ...ref,
            referred_user: Array.isArray(ref.referred_user) ? ref.referred_user[0] : ref.referred_user
          }))
        );
      }
    } catch (error) {
      console.error('Error fetching affiliate data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleJoinAffiliate = async () => {
    try {
      setLoading(true);

      // Generate unique referral code
      const referralCode = `REF${Math.random().toString(36).substr(2, 8).toUpperCase()}`;

      // Create affiliate account
      const { data: account, error } = await supabase
        .from('affiliate_accounts')
        .insert([{
          user_id: user?.id,
          referral_code: referralCode,
          earnings: 0,
          paid_earnings: 0,
          status: 'active',
          referral_count: 0
        }])
        .select()
        .single();

      if (error) throw error;

      setAffiliateAccount(account);
      setReferralCode(account.referral_code);
      setReferralLink(`${window.location.origin}/register?ref=${account.referral_code}`);
      showNotification('Successfully joined the affiliate program!', 'success');
    } catch (error) {
      console.error('Error joining affiliate program:', error);
      showNotification('Error joining affiliate program. Please try again.', 'error');
    } finally {
      setLoading(false);
    }
  };

  const copyToClipboard = async (text: string) => {
    try {
      await navigator.clipboard.writeText(text);
      setCopySuccess(true);
      setTimeout(() => setCopySuccess(false), 2000);
      showNotification('Referral link copied to clipboard!', 'success');
    } catch (err) {
      console.error('Failed to copy text: ', err);
      showNotification('Failed to copy link', 'error');
    }
  };

  const showNotification = (message: string, type: 'success' | 'error') => {
    const notification = document.createElement('div');
    notification.className = `fixed bottom-4 right-4 ${
      type === 'success' ? 'bg-green-500' : 'bg-red-500'
    } text-white px-6 py-3 rounded-lg shadow-lg z-50 animate-fade-in`;
    notification.textContent = message;
    document.body.appendChild(notification);
    
    setTimeout(() => {
      notification.classList.add('animate-fade-out');
      setTimeout(() => {
        document.body.removeChild(notification);
      }, 300);
    }, 3000);
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-orange"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="bg-white rounded-lg shadow-md overflow-hidden">
          <div className="p-6">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-bold text-gray-900">Affiliate Program</h2>
              <div className="text-sm text-gray-500">
                Commission Rate: {commissionRate}%
              </div>
            </div>
            
            {!affiliateAccount ? (
              <div className="text-center py-8">
                <Users className="h-16 w-16 text-gray-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">Join Our Affiliate Program</h3>
                <p className="text-gray-600 mb-2">Earn {commissionRate}% commission on every successful referral purchase</p>
                <p className="text-sm text-gray-500 mb-6">
                  Minimum payout: {new Intl.NumberFormat('en-NG', {
                    style: 'currency',
                    currency: 'NGN'
                  }).format(minPayout)}
                </p>
                <button
                  onClick={handleJoinAffiliate}
                  disabled={loading}
                  className="bg-primary-orange text-white px-6 py-3 rounded-md hover:bg-primary-orange/90 transition-colors"
                >
                  {loading ? 'Joining...' : 'Join Now'}
                </button>
              </div>
            ) : (
              <div className="space-y-6">
                <div className="bg-gray-50 p-4 rounded-lg">
                  <h3 className="text-sm font-medium text-gray-700 mb-2">Your Referral Link</h3>
                  <div className="flex items-center space-x-2">
                    <input
                      type="text"
                      readOnly
                      value={referralLink}
                      className="flex-1 p-2 text-sm border rounded-l-md focus:outline-none bg-white"
                    />
                    <button
                      onClick={() => copyToClipboard(referralLink)}
                      className="bg-primary-orange text-white p-2 rounded-r-md hover:bg-primary-orange/90"
                    >
                      {copySuccess ? <Check className="w-5 h-5" /> : <Copy className="w-5 h-5" />}
                    </button>
                  </div>
                  <p className="mt-2 text-sm text-gray-500">
                    Share this link with your friends and earn {commissionRate}% when they make a purchase
                  </p>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
                  <div className="bg-blue-50 p-4 rounded-lg">
                    <h4 className="text-sm font-medium text-blue-700">Total Earnings</h4>
                    <p className="text-2xl font-bold text-blue-900">
                      {new Intl.NumberFormat('en-NG', {
                        style: 'currency',
                        currency: 'NGN'
                      }).format(affiliateAccount.earnings)}
                    </p>
                  </div>
                  
                  <div className="bg-green-50 p-4 rounded-lg">
                    <h4 className="text-sm font-medium text-green-700">Paid Earnings</h4>
                    <p className="text-2xl font-bold text-green-900">
                      {new Intl.NumberFormat('en-NG', {
                        style: 'currency',
                        currency: 'NGN'
                      }).format(affiliateAccount.paid_earnings)}
                    </p>
                  </div>
                  
                  <div className="bg-orange-50 p-4 rounded-lg">
                    <h4 className="text-sm font-medium text-orange-700">Pending Earnings</h4>
                    <p className="text-2xl font-bold text-orange-900">
                      {new Intl.NumberFormat('en-NG', {
                        style: 'currency',
                        currency: 'NGN'
                      }).format(affiliateAccount.earnings - affiliateAccount.paid_earnings)}
                    </p>
                  </div>

                  <div className="bg-purple-50 p-4 rounded-lg">
                    <h4 className="text-sm font-medium text-purple-700">Total Referrals</h4>
                    <p className="text-2xl font-bold text-purple-900">
                      {affiliateAccount.referral_count}
                    </p>
                  </div>
                </div>

                {referrals.length > 0 && (
                  <div>
                    <h3 className="text-lg font-medium text-gray-900 mb-4">Recent Referrals</h3>
                    <div className="bg-white rounded-lg border overflow-hidden">
                      <table className="min-w-full divide-y divide-gray-200">
                        <thead className="bg-gray-50">
                          <tr>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                              User
                            </th>
                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                              Date Joined
                            </th>
                          </tr>
                        </thead>
                        <tbody className="bg-white divide-y divide-gray-200">
                          {referrals.map((referral) => (
                            <tr key={referral.id}>
                              <td className="px-6 py-4 whitespace-nowrap">
                                <div className="text-sm font-medium text-gray-900">
                                  {referral.referred_user.user_metadata?.full_name || 'Anonymous'}
                                </div>
                                <div className="text-sm text-gray-500">
                                  {referral.referred_user.email}
                                </div>
                              </td>
                              <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                {new Date(referral.created_at).toLocaleDateString()}
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}