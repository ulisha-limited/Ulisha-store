// vite.config.ts
import { defineConfig } from "file:///home/project/node_modules/vite/dist/node/index.js";
import react from "file:///home/project/node_modules/@vitejs/plugin-react/dist/index.mjs";
var vite_config_default = defineConfig({
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
        rewrite: (path) => path.replace(/^\/rest\/v1/, "/rest/v1")
      }
    }
  },
  build: {
    sourcemap: false,
    outDir: "dist",
    rollupOptions: {
      output: {
        entryFileNames: "assets/[hash].js",
        chunkFileNames: "assets/[hash].js",
        assetFileNames: "assets/[hash].[ext]",
        manualChunks: {
          "react-vendor": ["react", "react-dom", "react-router-dom"],
          "ui-vendor": ["lucide-react", "swiper"],
          "payment-vendor": ["@coinbase/cbpay-js", "flutterwave-react-v3"]
        }
      }
    },
    chunkSizeWarningLimit: 1e3
  },
  optimizeDeps: {
    force: true,
    esbuildOptions: {
      treeShaking: true,
      minify: true,
      loader: {
        ".js": "jsx"
      }
    }
  }
});
export {
  vite_config_default as default
};
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsidml0ZS5jb25maWcudHMiXSwKICAic291cmNlc0NvbnRlbnQiOiBbImNvbnN0IF9fdml0ZV9pbmplY3RlZF9vcmlnaW5hbF9kaXJuYW1lID0gXCIvaG9tZS9wcm9qZWN0XCI7Y29uc3QgX192aXRlX2luamVjdGVkX29yaWdpbmFsX2ZpbGVuYW1lID0gXCIvaG9tZS9wcm9qZWN0L3ZpdGUuY29uZmlnLnRzXCI7Y29uc3QgX192aXRlX2luamVjdGVkX29yaWdpbmFsX2ltcG9ydF9tZXRhX3VybCA9IFwiZmlsZTovLy9ob21lL3Byb2plY3Qvdml0ZS5jb25maWcudHNcIjtpbXBvcnQgeyBkZWZpbmVDb25maWcgfSBmcm9tICd2aXRlJ1xuaW1wb3J0IHJlYWN0IGZyb20gJ0B2aXRlanMvcGx1Z2luLXJlYWN0J1xuXG5leHBvcnQgZGVmYXVsdCBkZWZpbmVDb25maWcoe1xuICBwbHVnaW5zOiBbcmVhY3QoKV0sXG4gIHNlcnZlcjoge1xuICAgIHBvcnQ6IDUxNzMsXG4gICAgaG9zdDogdHJ1ZSxcbiAgICBvcGVuOiB0cnVlLFxuICAgIHByb3h5OiB7XG4gICAgICAnL3Jlc3QvdjEnOiB7XG4gICAgICAgIHRhcmdldDogJ2h0dHBzOi8vbGdvcGZncnN6eGViY295bHlvY3Auc3VwYWJhc2UuY28nLFxuICAgICAgICBjaGFuZ2VPcmlnaW46IHRydWUsXG4gICAgICAgIHNlY3VyZTogZmFsc2UsXG4gICAgICAgIHJld3JpdGU6IChwYXRoKSA9PiBwYXRoLnJlcGxhY2UoL15cXC9yZXN0XFwvdjEvLCAnL3Jlc3QvdjEnKSxcbiAgICAgIH0sXG4gICAgfSxcbiAgfSxcbiAgYnVpbGQ6IHtcbiAgICBzb3VyY2VtYXA6IGZhbHNlLFxuICAgIG91dERpcjogJ2Rpc3QnLFxuICAgIHJvbGx1cE9wdGlvbnM6IHtcbiAgICAgIG91dHB1dDoge1xuICAgICAgICBlbnRyeUZpbGVOYW1lczogJ2Fzc2V0cy9baGFzaF0uanMnLFxuICAgICAgICBjaHVua0ZpbGVOYW1lczogJ2Fzc2V0cy9baGFzaF0uanMnLFxuICAgICAgICBhc3NldEZpbGVOYW1lczogJ2Fzc2V0cy9baGFzaF0uW2V4dF0nLFxuICAgICAgICBtYW51YWxDaHVua3M6IHtcbiAgICAgICAgICAncmVhY3QtdmVuZG9yJzogWydyZWFjdCcsICdyZWFjdC1kb20nLCAncmVhY3Qtcm91dGVyLWRvbSddLFxuICAgICAgICAgICd1aS12ZW5kb3InOiBbJ2x1Y2lkZS1yZWFjdCcsICdzd2lwZXInXSxcbiAgICAgICAgICAncGF5bWVudC12ZW5kb3InOiBbJ0Bjb2luYmFzZS9jYnBheS1qcycsICdmbHV0dGVyd2F2ZS1yZWFjdC12MyddLFxuICAgICAgICB9LFxuICAgICAgfSxcbiAgICB9LFxuICAgIGNodW5rU2l6ZVdhcm5pbmdMaW1pdDogMTAwMCxcbiAgfSxcbiAgb3B0aW1pemVEZXBzOiB7XG4gICAgZm9yY2U6IHRydWUsXG4gICAgZXNidWlsZE9wdGlvbnM6IHtcbiAgICAgIHRyZWVTaGFraW5nOiB0cnVlLFxuICAgICAgbWluaWZ5OiB0cnVlLFxuICAgICAgbG9hZGVyOiB7XG4gICAgICAgICcuanMnOiAnanN4JyxcbiAgICAgIH0sXG4gICAgfSxcbiAgfSxcbn0pXG4iXSwKICAibWFwcGluZ3MiOiAiO0FBQXlOLFNBQVMsb0JBQW9CO0FBQ3RQLE9BQU8sV0FBVztBQUVsQixJQUFPLHNCQUFRLGFBQWE7QUFBQSxFQUMxQixTQUFTLENBQUMsTUFBTSxDQUFDO0FBQUEsRUFDakIsUUFBUTtBQUFBLElBQ04sTUFBTTtBQUFBLElBQ04sTUFBTTtBQUFBLElBQ04sTUFBTTtBQUFBLElBQ04sT0FBTztBQUFBLE1BQ0wsWUFBWTtBQUFBLFFBQ1YsUUFBUTtBQUFBLFFBQ1IsY0FBYztBQUFBLFFBQ2QsUUFBUTtBQUFBLFFBQ1IsU0FBUyxDQUFDLFNBQVMsS0FBSyxRQUFRLGVBQWUsVUFBVTtBQUFBLE1BQzNEO0FBQUEsSUFDRjtBQUFBLEVBQ0Y7QUFBQSxFQUNBLE9BQU87QUFBQSxJQUNMLFdBQVc7QUFBQSxJQUNYLFFBQVE7QUFBQSxJQUNSLGVBQWU7QUFBQSxNQUNiLFFBQVE7QUFBQSxRQUNOLGdCQUFnQjtBQUFBLFFBQ2hCLGdCQUFnQjtBQUFBLFFBQ2hCLGdCQUFnQjtBQUFBLFFBQ2hCLGNBQWM7QUFBQSxVQUNaLGdCQUFnQixDQUFDLFNBQVMsYUFBYSxrQkFBa0I7QUFBQSxVQUN6RCxhQUFhLENBQUMsZ0JBQWdCLFFBQVE7QUFBQSxVQUN0QyxrQkFBa0IsQ0FBQyxzQkFBc0Isc0JBQXNCO0FBQUEsUUFDakU7QUFBQSxNQUNGO0FBQUEsSUFDRjtBQUFBLElBQ0EsdUJBQXVCO0FBQUEsRUFDekI7QUFBQSxFQUNBLGNBQWM7QUFBQSxJQUNaLE9BQU87QUFBQSxJQUNQLGdCQUFnQjtBQUFBLE1BQ2QsYUFBYTtBQUFBLE1BQ2IsUUFBUTtBQUFBLE1BQ1IsUUFBUTtBQUFBLFFBQ04sT0FBTztBQUFBLE1BQ1Q7QUFBQSxJQUNGO0FBQUEsRUFDRjtBQUNGLENBQUM7IiwKICAibmFtZXMiOiBbXQp9Cg==
