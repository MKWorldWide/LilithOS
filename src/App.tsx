/**
 * 🚀 Enhanced AI Revenue Routing System - Main App Component
 * 
 * Divine Architect Revenue Routing System with TrafficFlou Integration
 * Main application component with routing, layout, and state management
 * 
 * @author Divine Architect + TrafficFlou Team
 * @version 3.0.0
 * @license LilithOS
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
import RevenueRouting from './pages/RevenueRouting';
import TrafficAnalytics from './pages/TrafficAnalytics';
import TreasuryManagement from './pages/TreasuryManagement';
import PrimalGenesis from './pages/PrimalGenesis';
import Settings from './pages/Settings';

// Import hooks
import { useAuth } from './hooks/useAuth';
import { useSystemStatus } from './hooks/useSystemStatus';

// Import types
import { SystemStatus } from './types/system';

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
        console.log('🚀 Initializing Enhanced AI Revenue Routing System...');
        
        // Check system status
        await refreshStatus();
        
        // Check authentication
        if (!isAuthenticated) {
          console.log('🔐 Authentication required');
        }
        
        setLoading(false);
        toast.success('System initialized successfully');
        
      } catch (err) {
        console.error('❌ Failed to initialize application:', err);
        setError('Failed to initialize application');
        setLoading(false);
        toast.error('Failed to initialize application');
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
          <h2>🚀 Enhanced AI Revenue Routing System</h2>
          <p>💎 Initializing Divine Architect Treasury...</p>
          <p>🧠 Starting Primal Genesis Engine...</p>
          <p>🌟 Loading LilithOS Process Management...</p>
        </div>
      </div>
    );
  }

  // Error state
  if (error) {
    return (
      <div className="app-error">
        <Alert
          message="System Error"
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
          <p>Please authenticate to access the Enhanced AI Revenue Routing System</p>
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
              
              {/* Revenue Routing */}
              <Route 
                path="/revenue-routing" 
                element={<RevenueRouting />} 
              />
              
              {/* Traffic Analytics */}
              <Route 
                path="/traffic-analytics" 
                element={<TrafficAnalytics />} 
              />
              
              {/* Treasury Management */}
              <Route 
                path="/treasury" 
                element={<TreasuryManagement />} 
              />
              
              {/* Primal Genesis Engine */}
              <Route 
                path="/primal-genesis" 
                element={<PrimalGenesis />} 
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