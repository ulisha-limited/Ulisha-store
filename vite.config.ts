import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    host: true,
    open: true,
    proxy: {
      "/rest/v1": {
        target: "https://lgopfgrszxebcoylyocp.supabase.co",
        changeOrigin: true,
        secure: false,
        rewrite: (path) => path.replace(/^\/rest\/v1/, "/rest/v1"),
      },
    },
  },
  build: {
    sourcemap: false,
    outDir: "dist",
    minify: "terser",
    rollupOptions: {
      output: {
        entryFileNames: "assets/[hash].js",
        chunkFileNames: "assets/[hash].js",
        assetFileNames: "assets/[hash].[ext]",
        manualChunks(id) {
          // this thing fixes issues with vite build minif of sentry
          if (id.includes("node_modules") && !id.includes("sentry")) {
            return id.toString().split("node_modules/")[1].split("/")[0];
          }
        },
      },
    },
    chunkSizeWarningLimit: 1000,
  },
});