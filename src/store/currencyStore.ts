import { create } from 'zustand';

interface CurrencyState {
  currency: 'NGN' | 'USD';
  exchangeRate: number;
  setCurrency: (currency: 'NGN' | 'USD') => void;
  formatPrice: (price: number) => string;
}

export const useCurrencyStore = create<CurrencyState>((set, get) => ({
  currency: (localStorage.getItem('currency') as 'NGN' | 'USD') || 'NGN',
  exchangeRate: 1630, // 1 USD = 1630 NGN

  setCurrency: (currency) => {
    localStorage.setItem('currency', currency);
    set({ currency });
  },

  formatPrice: (price) => {
    const { currency, exchangeRate } = get();
    
    if (currency === 'USD') {
      return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD'
      }).format(price / exchangeRate);
    }
    
    return new Intl.NumberFormat('en-NG', {
      style: 'currency',
      currency: 'NGN'
    }).format(price);
  }
}));

// Listen for currency changes
window.addEventListener('currencyChange', ((event: CustomEvent) => {
  useCurrencyStore.getState().setCurrency(event.detail.currency);
}) as EventListener);