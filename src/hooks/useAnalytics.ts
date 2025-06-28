import { useEffect } from 'react';
import { supabase } from '../lib/supabase';
import { useAuthStore } from '../store/authStore';

// Generate a session ID for tracking
const getSessionId = () => {
  let sessionId = sessionStorage.getItem('analytics_session_id');
  if (!sessionId) {
    sessionId = `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    sessionStorage.setItem('analytics_session_id', sessionId);
  }
  return sessionId;
};

// Track page view
export const trackPageView = async (path: string) => {
  try {
    const sessionId = getSessionId();
    const user = useAuthStore.getState().user;
    
    // Get user agent and referrer
    const userAgent = navigator.userAgent;
    const referrer = document.referrer || null;
    
    // Track the page view
    await supabase.rpc('track_page_view', {
      p_session_id: sessionId,
      p_user_id: user?.id || null,
      p_page_path: path,
      p_user_agent: userAgent,
      p_ip_address: '', // IP will be handled server-side
      p_referrer: referrer
    });
  } catch (error) {
    console.error('Error tracking page view:', error);
  }
};

// Hook to automatically track page views
export const useAnalytics = () => {
  useEffect(() => {
    // Track initial page view
    trackPageView(window.location.pathname);
    
    // Track page views on route changes
    const handleRouteChange = () => {
      trackPageView(window.location.pathname);
    };
    
    // Listen for popstate events (back/forward navigation)
    window.addEventListener('popstate', handleRouteChange);
    
    // Listen for pushstate/replacestate (programmatic navigation)
    const originalPushState = history.pushState;
    const originalReplaceState = history.replaceState;
    
    history.pushState = function(...args) {
      originalPushState.apply(history, args);
      setTimeout(() => trackPageView(window.location.pathname), 0);
    };
    
    history.replaceState = function(...args) {
      originalReplaceState.apply(history, args);
      setTimeout(() => trackPageView(window.location.pathname), 0);
    };
    
    return () => {
      window.removeEventListener('popstate', handleRouteChange);
      history.pushState = originalPushState;
      history.replaceState = originalReplaceState;
    };
  }, []);
};