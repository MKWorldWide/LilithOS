/**
 * 🔐 Scrypt Mining Framework - Main App Component
 * 
 * Advanced Scrypt Cryptocurrency Mining Framework with AI-Powered Optimization
 * Main application component with routing, layout, and state management
 * 
 * @author M-K-World-Wide Scrypt Team
 * @version 1.0.0
 * @license MIT
 */

import React, { useEffect, useState } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { Layout, Spin, Alert } from 'antd';
import { LoadingOutlined } from '@ant-design/icons';
import toast from 'react-hot-toast';

// Import components
import AppHeader from './components/AppHeader';
import AppSider from './components/AppSider';
import AppFooter from './components/AppFooter';

// Import pages
import Dashboard from './pages/Dashboard';
import MiningOperations from './pages/MiningOperations';
import BlockchainExplorer from './pages/BlockchainExplorer';
import WalletManagement from './pages/WalletManagement';
import MiningAnalytics from './pages/MiningAnalytics';
import Settings from './pages/Settings';

// Import hooks
import { useAuth } from './hooks/useAuth';
import { useSystemStatus } from './hooks/useSystemStatus';

// Import types
// import { SystemStatus } from './types/system';

// Import styles
import './App.css';

const { Content } = Layout;

/**
 * Main App Component
 * Handles routing, layout, authentication, and system status
 */
const App: React.FC = () => {
  // State management
  const [collapsed, setCollapsed] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Custom hooks
  const { isAuthenticated, user, login, logout } = useAuth();
  const { systemStatus, refreshStatus } = useSystemStatus();

  // Initialize application
  useEffect(() => {
    const initializeApp = async () => {
      try {
        console.log('🔐 Initializing Scrypt Mining Framework...');
        
        // Check system status
        await refreshStatus();
        
        // Check authentication
        if (!isAuthenticated) {
          console.log('🔐 Authentication required');
        }
        
        setLoading(false);
        toast.success('Mining system initialized successfully');
        
      } catch (err) {
        console.error('❌ Failed to initialize mining application:', err);
        setError('Failed to initialize mining application');
        setLoading(false);
        toast.error('Failed to initialize mining application');
      }
    };

    initializeApp();
  }, [isAuthenticated, refreshStatus]);

  // Handle sidebar collapse
  const handleCollapse = (collapsed: boolean) => {
    setCollapsed(collapsed);
  };

  // Loading state
  if (loading) {
    return (
      <div className="app-loading">
        <Spin 
          indicator={<LoadingOutlined style={{ fontSize: 48 }} spin />}
          size="large"
        />
        <div className="loading-text">
          <h2>🔐 Scrypt Mining Framework</h2>
          <p>⛏️ Initializing Mining Operations...</p>
          <p>🔗 Connecting to Blockchain Network...</p>
          <p>💎 Setting up Mining Pools...</p>
        </div>
      </div>
    );
  }

  // Error state
  if (error) {
    return (
      <div className="app-error">
        <Alert
          message="Mining System Error"
          description={error}
          type="error"
          showIcon
          action={
            <button onClick={() => window.location.reload()}>
              Retry
            </button>
          }
        />
      </div>
    );
  }

  // Authentication required
  if (!isAuthenticated) {
    return (
      <div className="auth-required">
        <div className="auth-container">
          <h1>🔐 Authentication Required</h1>
          <p>Please authenticate to access the Scrypt Mining Framework</p>
          <button onClick={login} className="auth-button">
            Login
          </button>
        </div>
      </div>
    );
  }

  return (
    <Layout className="app-layout">
      {/* Header */}
      <AppHeader 
        user={user}
        systemStatus={systemStatus}
        onLogout={logout}
      />
      
      <Layout>
        {/* Sidebar */}
        <AppSider 
          collapsed={collapsed}
          onCollapse={handleCollapse}
        />
        
        {/* Main Content */}
        <Layout className="main-content">
          <Content className="content-area">
            <Routes>
              {/* Dashboard */}
              <Route 
                path="/" 
                element={<Dashboard systemStatus={systemStatus} />} 
              />
              
              {/* Mining Operations */}
              <Route 
                path="/mining-operations" 
                element={<MiningOperations />} 
              />
              
              {/* Blockchain Explorer */}
              <Route 
                path="/blockchain-explorer" 
                element={<BlockchainExplorer />} 
              />
              
              {/* Wallet Management */}
              <Route 
                path="/wallet-management" 
                element={<WalletManagement />} 
              />
              
              {/* Mining Analytics */}
              <Route 
                path="/mining-analytics" 
                element={<MiningAnalytics />} 
              />
              
              {/* Settings */}
              <Route 
                path="/settings" 
                element={<Settings />} 
              />
              
              {/* Default redirect */}
              <Route 
                path="*" 
                element={<Navigate to="/" replace />} 
              />
            </Routes>
          </Content>
          
          {/* Footer */}
          <AppFooter />
        </Layout>
      </Layout>
    </Layout>
  );
};

export default App; 