/**
 * 🚀 System Status Hook - Enhanced AI Revenue Routing System
 * 
 * Custom hook for handling system status and monitoring
 * 
 * @author Divine Architect + TrafficFlou Team
 * @version 3.0.0
 * @license LilithOS
 */

import { useState, useEffect, useCallback } from 'react';
import { SystemStatus } from '../types/system';

interface SystemStatusState {
  systemStatus: SystemStatus | null;
  loading: boolean;
  error: string | null;
}

interface SystemStatusActions {
  refreshStatus: () => Promise<void>;
  acknowledgeAlert: (alertId: string) => Promise<void>;
}

export const useSystemStatus = (): SystemStatusState & SystemStatusActions => {
  const [state, setState] = useState<SystemStatusState>({
    systemStatus: null,
    loading: true,
    error: null,
  });

  // Mock system status for development
  const mockSystemStatus: SystemStatus = {
    status: 'online',
    uptime: 86400, // 24 hours in seconds
    version: '3.0.0',
    lastUpdate: new Date().toISOString(),
    components: {
      treasury: {
        status: 'online',
        message: 'Treasury Gateway operational',
        lastCheck: new Date().toISOString(),
        responseTime: 45,
      },
      primalGenesis: {
        status: 'online',
        message: 'Primal Genesis Engine active',
        lastCheck: new Date().toISOString(),
        responseTime: 32,
      },
      lilithOS: {
        status: 'online',
        message: 'LilithOS Process Management running',
        lastCheck: new Date().toISOString(),
        responseTime: 28,
      },
      trafficFlou: {
        status: 'online',
        message: 'TrafficFlou integration active',
        lastCheck: new Date().toISOString(),
        responseTime: 51,
      },
      api: {
        status: 'online',
        message: 'API Gateway responding',
        lastCheck: new Date().toISOString(),
        responseTime: 15,
      },
      database: {
        status: 'online',
        message: 'Database connection stable',
        lastCheck: new Date().toISOString(),
        responseTime: 8,
      },
    },
    metrics: {
      cpu: 23.5,
      memory: 67.2,
      disk: 45.8,
      network: 12.3,
    },
    alerts: [
      {
        id: '1',
        level: 'info',
        message: 'System operating normally',
        timestamp: new Date().toISOString(),
        acknowledged: true,
      },
    ],
  };

  // Initialize system status
  useEffect(() => {
    const initializeStatus = async () => {
      try {
        await refreshStatus();
      } catch (error) {
        console.error('Failed to initialize system status:', error);
        setState(prev => ({
          ...prev,
          loading: false,
          error: 'Failed to initialize system status',
        }));
      }
    };

    initializeStatus();
  }, []);

  // Refresh system status
  const refreshStatus = useCallback(async () => {
    try {
      setState(prev => ({ ...prev, loading: true, error: null }));
      
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 800));
      
      // Update mock data with current timestamp
      const updatedStatus: SystemStatus = {
        ...mockSystemStatus,
        lastUpdate: new Date().toISOString(),
        uptime: mockSystemStatus.uptime + Math.floor(Math.random() * 10),
        metrics: {
          cpu: Math.random() * 100,
          memory: Math.random() * 100,
          disk: Math.random() * 100,
          network: Math.random() * 100,
        },
      };
      
      setState({
        systemStatus: updatedStatus,
        loading: false,
        error: null,
      });
      
      console.log('🚀 System status refreshed');
    } catch (error) {
      console.error('Failed to refresh system status:', error);
      setState(prev => ({
        ...prev,
        loading: false,
        error: 'Failed to refresh system status',
      }));
    }
  }, []);

  // Acknowledge alert
  const acknowledgeAlert = useCallback(async (alertId: string) => {
    try {
      if (!state.systemStatus) return;
      
      const updatedAlerts = state.systemStatus.alerts.map(alert =>
        alert.id === alertId ? { ...alert, acknowledged: true } : alert
      );
      
      setState(prev => ({
        ...prev,
        systemStatus: prev.systemStatus ? {
          ...prev.systemStatus,
          alerts: updatedAlerts,
        } : null,
      }));
      
      console.log(`✅ Alert ${alertId} acknowledged`);
    } catch (error) {
      console.error('Failed to acknowledge alert:', error);
    }
  }, [state.systemStatus]);

  return {
    ...state,
    refreshStatus,
    acknowledgeAlert,
  };
}; 