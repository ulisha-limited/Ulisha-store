import { useState, useEffect } from 'react';
import { useAuthStore } from '../store/authStore';

export function usePromoPopup() {
  const [showPopup, setShowPopup] = useState(false);
  const user = useAuthStore((state) => state.user);

  useEffect(() => {
    // Only show popup for non-logged-in users
    if (!user) {
      // Check if popup was already shown in this session
      const popupShown = sessionStorage.getItem('promo_popup_shown');
      
      if (!popupShown) {
        // Show popup after a delay (3 seconds)
        const timer = setTimeout(() => {
          setShowPopup(true);
        }, 3000);

        return () => clearTimeout(timer);
      }
    }
  }, [user]);

  const closePopup = () => {
    setShowPopup(false);
    // Mark popup as shown for this session
    sessionStorage.setItem('promo_popup_shown', 'true');
  };

  const resetPopup = () => {
    sessionStorage.removeItem('promo_popup_shown');
    setShowPopup(false);
  };

  return {
    showPopup,
    closePopup,
    resetPopup
  };
}