/**
 * 🔐 useMiningController Hook - Scrypt Mining Framework
 * 
 * Custom React hook for integrating with the mining controller backend.
 * Provides real-time mining operations, status updates, and WebSocket communication.
 * 
 * @author M-K-World-Wide Scrypt Team
 * @version 1.0.0
 * @license MIT
 */

import { useState, useEffect, useCallback, useRef } from 'react';
import { message } from 'antd';

// Types
export interface MiningConfig {
  algorithm: 'scrypt' | 'randomx';
  pool: 'litecoin' | 'dogecoin' | 'aikapool';
  wallet: string;
  workerName?: string;
  threads?: number;
  intensity?: number;
}

export interface MiningStatus {
  processId: string;
  status: 'running' | 'stopped' | 'error' | 'starting';
  config: MiningConfig;
  startTime: Date;
  uptime: number;
  hashRate: number;
  shares: number;
  rejectedShares: number;
  lastUpdate: Date;
}

export interface PoolInfo {
  name: string;
  url: string;
  algorithm: string;
  description?: string;
}

export interface MiningStats {
  totalHashRate: number;
  totalShares: number;
  totalRejectedShares: number;
  activeMiners: number;
  totalUptime: number;
}

// API Configuration
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:3001/api';
const WS_URL = process.env.REACT_APP_WS_URL || 'ws://localhost:3002';

export const useMiningController = () => {
  // State
  const [miningStatus, setMiningStatus] = useState<MiningStatus[]>([]);
  const [pools, setPools] = useState<Record<string, PoolInfo>>({});
  const [isConnected, setIsConnected] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Refs
  const wsRef = useRef<WebSocket | null>(null);
  const reconnectTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  /**
   * Initialize WebSocket connection
   */
  const initializeWebSocket = useCallback(() => {
    try {
      const ws = new WebSocket(WS_URL);
      wsRef.current = ws;

      ws.onopen = () => {
        console.log('🔐 WebSocket connected to mining controller');
        setIsConnected(true);
        setError(null);
      };

      ws.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          handleWebSocketMessage(data);
        } catch (err) {
          console.error('Failed to parse WebSocket message:', err);
        }
      };

      ws.onclose = () => {
        console.log('🔐 WebSocket disconnected from mining controller');
        setIsConnected(false);
        
        // Attempt to reconnect after 5 seconds
        if (reconnectTimeoutRef.current) {
          clearTimeout(reconnectTimeoutRef.current);
        }
        reconnectTimeoutRef.current = setTimeout(() => {
          initializeWebSocket();
        }, 5000);
      };

      ws.onerror = (error) => {
        console.error('WebSocket error:', error);
        setError('Failed to connect to mining controller');
      };

    } catch (err) {
      console.error('Failed to initialize WebSocket:', err);
      setError('Failed to initialize WebSocket connection');
    }
  }, []);

  /**
   * Handle WebSocket messages
   */
  const handleWebSocketMessage = useCallback((data: any) => {
    switch (data.type) {
      case 'status':
        setMiningStatus(data.data || []);
        break;
        
      case 'mining_started':
        message.success(`Mining started: ${data.config.algorithm} on ${data.config.pool}`);
        fetchMiningStatus();
        break;
        
      case 'mining_stopped':
        message.info(`Mining stopped: ${data.processId}`);
        fetchMiningStatus();
        break;
        
      case 'mining_output':
        // Update real-time stats
        setMiningStatus(prev => 
          prev.map(status => 
            status.processId === data.processId
              ? { ...status, ...data.stats, lastUpdate: new Date() }
              : status
          )
        );
        break;
        
      case 'mining_error':
        message.error(`Mining error: ${data.error}`);
        setMiningStatus(prev => 
          prev.map(status => 
            status.processId === data.processId
              ? { ...status, status: 'error' as const }
              : status
          )
        );
        break;
        
      default:
        console.log('Unknown WebSocket message type:', data.type);
    }
  }, []);

  /**
   * Fetch mining status from API
   */
  const fetchMiningStatus = useCallback(async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/mining/status`);
      const result = await response.json();
      
      if (result.success) {
        setMiningStatus(result.data || []);
      } else {
        setError(result.error || 'Failed to fetch mining status');
      }
    } catch (err) {
      console.error('Failed to fetch mining status:', err);
      setError('Failed to fetch mining status');
    }
  }, []);

  /**
   * Fetch available pools
   */
  const fetchPools = useCallback(async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/mining/pools`);
      const result = await response.json();
      
      if (result.success) {
        setPools(result.data || {});
      } else {
        setError(result.error || 'Failed to fetch pools');
      }
    } catch (err) {
      console.error('Failed to fetch pools:', err);
      setError('Failed to fetch pools');
    }
  }, []);

  /**
   * Start mining operation
   */
  const startMining = useCallback(async (config: MiningConfig) => {
    setIsLoading(true);
    setError(null);
    
    try {
      const response = await fetch(`${API_BASE_URL}/mining/start`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(config),
      });
      
      const result = await response.json();
      
      if (result.success) {
        message.success('Mining started successfully');
        return result;
      } else {
        setError(result.error || 'Failed to start mining');
        message.error(result.error || 'Failed to start mining');
        return result;
      }
    } catch (err) {
      console.error('Failed to start mining:', err);
      const errorMsg = 'Failed to start mining operation';
      setError(errorMsg);
      message.error(errorMsg);
      return { success: false, error: errorMsg };
    } finally {
      setIsLoading(false);
    }
  }, []);

  /**
   * Stop mining operation
   */
  const stopMining = useCallback(async (processId: string) => {
    setIsLoading(true);
    setError(null);
    
    try {
      const response = await fetch(`${API_BASE_URL}/mining/stop/${processId}`, {
        method: 'POST',
      });
      
      const result = await response.json();
      
      if (result.success) {
        message.success('Mining stopped successfully');
        return result;
      } else {
        setError(result.error || 'Failed to stop mining');
        message.error(result.error || 'Failed to stop mining');
        return result;
      }
    } catch (err) {
      console.error('Failed to stop mining:', err);
      const errorMsg = 'Failed to stop mining operation';
      setError(errorMsg);
      message.error(errorMsg);
      return { success: false, error: errorMsg };
    } finally {
      setIsLoading(false);
    }
  }, []);

  /**
   * Calculate mining statistics
   */
  const getMiningStats = useCallback((): MiningStats => {
    const activeMiners = miningStatus.filter(status => status.status === 'running');
    
    return {
      totalHashRate: activeMiners.reduce((sum, miner) => sum + miner.hashRate, 0),
      totalShares: activeMiners.reduce((sum, miner) => sum + miner.shares, 0),
      totalRejectedShares: activeMiners.reduce((sum, miner) => sum + miner.rejectedShares, 0),
      activeMiners: activeMiners.length,
      totalUptime: activeMiners.reduce((sum, miner) => sum + miner.uptime, 0),
    };
  }, [miningStatus]);

  /**
   * Get pool options for select components
   */
  const getPoolOptions = useCallback(() => {
    return Object.entries(pools).map(([key, pool]) => ({
      label: pool.name,
      value: key,
      description: pool.description,
    }));
  }, [pools]);

  /**
   * Check if mining controller is healthy
   */
  const checkHealth = useCallback(async () => {
    try {
      const response = await fetch(`${API_BASE_URL}/health`);
      const result = await response.json();
      return result.success;
    } catch (err) {
      console.error('Health check failed:', err);
      return false;
    }
  }, []);

  // Initialize on mount
  useEffect(() => {
    initializeWebSocket();
    fetchPools();
    fetchMiningStatus();
    
    // Set up periodic status updates
    const statusInterval = setInterval(fetchMiningStatus, 10000);
    
    return () => {
      if (wsRef.current) {
        wsRef.current.close();
      }
      if (reconnectTimeoutRef.current) {
        clearTimeout(reconnectTimeoutRef.current);
      }
      clearInterval(statusInterval);
    };
  }, [initializeWebSocket, fetchPools, fetchMiningStatus]);

  return {
    // State
    miningStatus,
    pools,
    isConnected,
    isLoading,
    error,
    
    // Actions
    startMining,
    stopMining,
    fetchMiningStatus,
    fetchPools,
    checkHealth,
    
    // Computed
    getMiningStats,
    getPoolOptions,
    
    // Utilities
    clearError: () => setError(null),
  };
}; 