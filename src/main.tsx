/**
 * 🔐 Scrypt Mining Framework - Main Entry Point
 * 
 * Advanced Scrypt Cryptocurrency Mining Framework
 * React application with TypeScript, Vite, and comprehensive mining features
 * 
 * @author M-K-World-Wide Scrypt Team
 * @version 1.0.0
 * @license MIT
 */

import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ConfigProvider } from 'antd';
import { Toaster } from 'react-hot-toast';
import { Web3ReactProvider } from '@web3-react/core';
import { MetaMask } from '@web3-react/metamask';
import { ethers } from 'ethers';
import { ConnectionProvider, WalletProvider } from '@solana/wallet-adapter-react';
import { WalletAdapterNetwork } from '@solana/wallet-adapter-base';
import { PhantomWalletAdapter, SolflareWalletAdapter } from '@solana/wallet-adapter-wallets';
import { WalletModalProvider } from '@solana/wallet-adapter-react-ui';
import { clusterApiUrl } from '@solana/web3.js';

// Import main application component
import App from './App';

// Import styles
import './index.css';

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
    colorPrimary: '#722ed1', // Scrypt purple
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

// EVM getLibrary function
function getLibrary(provider: any): ethers.BrowserProvider {
  return new ethers.BrowserProvider(provider);
}

// Create connectors
const metamask = new MetaMask({
  options: {
    shimDisconnect: true,
  },
});

const connectors = [metamask];

const network = WalletAdapterNetwork.Mainnet;
const endpoint = clusterApiUrl(network);
const wallets = [new PhantomWalletAdapter(), new SolflareWalletAdapter()];

// Root element
const rootElement = document.getElementById('root');

if (!rootElement) {
  throw new Error('Root element not found');
}

// Render application
ReactDOM.createRoot(rootElement).render(
  <React.StrictMode>
    <Web3ReactProvider connectors={connectors} getLibrary={getLibrary}>
      <ConnectionProvider endpoint={endpoint}>
        <WalletProvider wallets={wallets} autoConnect>
          <WalletModalProvider>
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
          </WalletModalProvider>
        </WalletProvider>
      </ConnectionProvider>
    </Web3ReactProvider>
  </React.StrictMode>
);

// Performance monitoring
console.log('🔐 Scrypt Mining Framework v1.0.0');
console.log('⛏️ Mining Controller Active');
console.log('💰 ProHashing Integration Ready');
console.log('🚀 Real-time Mining Operations');
console.log('📊 Mining Analytics Enabled');

// Service Worker registration for PWA features
if ('serviceWorker' in navigator) {
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