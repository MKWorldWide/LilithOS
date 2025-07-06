/**
 * 🚀 Enhanced AI Revenue Routing System - Main Entry Point
 * 
 * Divine Architect Revenue Routing System with TrafficFlou Integration
 * Advanced React application with TypeScript, Vite, and comprehensive features
 * 
 * @author Divine Architect + TrafficFlou Team
 * @version 3.0.0
 * @license LilithOS
 */

import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ConfigProvider } from 'antd';
import { Toaster } from 'react-hot-toast';
import { Amplify } from 'aws-amplify';

// Import main application component
import App from './App';

// Import styles
import './index.css';

// Import AWS Amplify configuration
import awsconfig from './aws-exports.js';

// Configure AWS Amplify
Amplify.configure(awsconfig);

// Create React Query client with enhanced configuration
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 3,
      refetchOnWindowFocus: false,
      staleTime: 5 * 60 * 1000, // 5 minutes
    },
    mutations: {
      retry: 2,
    },
  },
});

// Ant Design theme configuration
const theme = {
  token: {
    colorPrimary: '#722ed1', // LilithOS purple
    colorSuccess: '#52c41a',
    colorWarning: '#faad14',
    colorError: '#ff4d4f',
    colorInfo: '#1890ff',
    borderRadius: 8,
    fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif',
  },
  components: {
    Button: {
      borderRadius: 8,
      controlHeight: 40,
    },
    Card: {
      borderRadius: 12,
      boxShadow: '0 4px 12px rgba(0, 0, 0, 0.1)',
    },
    Table: {
      borderRadius: 8,
    },
  },
};

// Root element
const rootElement = document.getElementById('root');

if (!rootElement) {
  throw new Error('Root element not found');
}

// Render application
ReactDOM.createRoot(rootElement).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <ConfigProvider theme={theme}>
        <BrowserRouter>
          <App />
          <Toaster
            position="top-right"
            toastOptions={{
              duration: 4000,
              style: {
                background: '#363636',
                color: '#fff',
                borderRadius: 8,
              },
              success: {
                duration: 3000,
                iconTheme: {
                  primary: '#52c41a',
                  secondary: '#fff',
                },
              },
              error: {
                duration: 5000,
                iconTheme: {
                  primary: '#ff4d4f',
                  secondary: '#fff',
                },
              },
            }}
          />
        </BrowserRouter>
      </ConfigProvider>
    </QueryClientProvider>
  </React.StrictMode>
);

// Performance monitoring
if (import.meta.env.PROD) {
  console.log('🚀 Enhanced AI Revenue Routing System v3.0.0');
  console.log('💎 Divine Architect + TrafficFlou Integration');
  console.log('🧠 Primal Genesis Engine Active');
  console.log('🛡️ Treasury Gateway Secure');
  console.log('🌟 LilithOS Process Management Enabled');
}

// Service Worker registration for PWA features
if ('serviceWorker' in navigator && import.meta.env.PROD) {
  window.addEventListener('load', () => {
    navigator.serviceWorker
      .register('/sw.js')
      .then((registration) => {
        console.log('SW registered: ', registration);
      })
      .catch((registrationError) => {
        console.log('SW registration failed: ', registrationError);
      });
  });
} 