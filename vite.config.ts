import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    host: true,
    open: true,
    proxy: {
      '/rest/v1': {
        target: 'https://lgopfgrszxebcoylyocp.supabase.co',
        changeOrigin: true,
        secure: false,
        rewrite: (path) => path.replace(/^\/rest\/v1/, '/rest/v1')
      }
    }
  },
  build: {
    sourcemap: true,
    outDir: 'dist',
    rollupOptions: {
      output: {
        manualChunks: {
          'react-vendor': ['react', 'react-dom', 'react-router-dom'],
          'ui-vendor': ['lucide-react', 'swiper'],
          'payment-vendor': ['@coinbase/cbpay-js', 'flutterwave-react-v3']
        }
      }
    },
    chunkSizeWarningLimit: 1000
  }
});