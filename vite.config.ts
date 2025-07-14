import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { resolve } from 'path';

export default defineConfig({
  plugins: [react()],
  
  define: {
    // Define globals for browser compatibility
    global: 'globalThis',
    'process.env': {},
  },
  
  optimizeDeps: {
    esbuildOptions: {
      define: {
        global: 'globalThis',
      },
    },
  },
  
  resolve: {
    alias: {
      // Use absolute paths for Node.js built-ins
      buffer: resolve(__dirname, 'node_modules/buffer'),
      process: resolve(__dirname, 'node_modules/process/browser.js'),
      util: resolve(__dirname, 'node_modules/util'),
      crypto: resolve(__dirname, 'node_modules/crypto-browserify'),
    },
  },
}); 