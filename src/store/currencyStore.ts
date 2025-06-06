import { create } from 'zustand';
import { supabase } from '../lib/supabase';
import { useAuthStore } from './authStore';

interface CurrencyState {
  currency: 'NGN' | 'USD';
  exchangeRate: number;
  loading: boolean;
  error: string | null;
  setCurrency: (currency: 'NGN' | 'USD') => Promise<void>;
  formatPrice: (price: number) => string;
  initialize: () => Promise<void>;
}

export const useCurrencyStore = create<CurrencyState>((set, get) => ({
  currency: (localStorage.getItem('currency') as 'NGN' | 'USD') || 'NGN',
  exchangeRate: 1630, // 1 USD = 1630 NGN
  loading: false,
  error: null,

  initialize: async () => {
    try {
      set({ loading: true, error: null });
      const user = useAuthStore.getState().user;
      
      if (user) {
        const { data, error } = await supabase
          .from('user_preferences')
          .select('currency')
          .eq('user_id', user.id)
          .single();

        if (error) throw error;
        
        if (data) {
          localStorage.setItem('currency', data.currency);
          set({ currency: data.currency as 'NGN' | 'USD' });
        }
      }
    } catch (error) {
      console.error('Error initializing currency:', error);
      set({ error: 'Failed to load currency preferences' });
    } finally {
      set({ loading: false });
    }
  },

  setCurrency: async (currency) => {
    try {
      set({ loading: true, error: null });
      const user = useAuthStore.getState().user;
      
      if (user) {
        const { error } = await supabase
          .from('user_preferences')
          .upsert({
            user_id: user.id,
            currency
          });

        if (error) throw error;
      }

      localStorage.setItem('currency', currency);
      set({ currency });

      // Notify other components of currency change
      window.dispatchEvent(
        new CustomEvent('currencyChange', {
          detail: { currency }
        })
      );
    } catch (error) {
      console.error('Error updating currency:', error);
      set({ error: 'Failed to update currency preference' });
    } finally {
      set({ loading: false });
    }
  },

  formatPrice: (price) => {
    const { currency, exchangeRate } = get();
    
    if (currency === 'USD') {
      return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD',
        minimumFractionDigits: 2,
        maximumFractionDigits: 2
      }).format(price / exchangeRate);
    }
    
    return new Intl.NumberFormat('en-NG', {
      style: 'currency',
      currency: 'NGN',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    }).format(price);
  }
}));

// Listen for currency changes
window.addEventListener('currencyChange', ((event: CustomEvent) => {
  useCurrencyStore.getState().setCurrency(event.detail.currency);
}) as EventListener);