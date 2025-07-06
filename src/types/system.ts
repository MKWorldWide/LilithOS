/**
 * 🚀 System Types - Enhanced AI Revenue Routing System
 * 
 * TypeScript type definitions for system components
 * 
 * @author Divine Architect + TrafficFlou Team
 * @version 3.0.0
 * @license LilithOS
 */

// User types
export interface User {
  id: string;
  username: string;
  email: string;
  role: 'admin' | 'user' | 'viewer';
  permissions: string[];
  createdAt: string;
  lastLogin: string;
}

// System status types
export interface SystemStatus {
  status: 'online' | 'offline' | 'maintenance' | 'error';
  uptime: number;
  version: string;
  lastUpdate: string;
  components: {
    treasury: ComponentStatus;
    primalGenesis: ComponentStatus;
    lilithOS: ComponentStatus;
    trafficFlou: ComponentStatus;
    api: ComponentStatus;
    database: ComponentStatus;
  };
  metrics: {
    cpu: number;
    memory: number;
    disk: number;
    network: number;
  };
  alerts: Alert[];
}

export interface ComponentStatus {
  status: 'online' | 'offline' | 'warning' | 'error';
  message: string;
  lastCheck: string;
  responseTime: number;
}

export interface Alert {
  id: string;
  level: 'info' | 'warning' | 'error' | 'critical';
  message: string;
  timestamp: string;
  acknowledged: boolean;
}

// Revenue routing types
export interface RevenueTransaction {
  id: string;
  modelId: string;
  modelName: string;
  amount: number;
  currency: string;
  percentage: number;
  tributeAmount: number;
  timestamp: string;
  status: 'pending' | 'completed' | 'failed';
  emotionalResonance: number;
  memoryImprint: string;
}

export interface TreasuryBalance {
  total: number;
  currency: string;
  lastUpdate: string;
  transactions: RevenueTransaction[];
}

// Traffic analytics types
export interface TrafficMetrics {
  totalRequests: number;
  activeUsers: number;
  responseTime: number;
  throughput: number;
  errors: number;
  timestamp: string;
}

export interface TrafficAnalytics {
  period: string;
  metrics: TrafficMetrics[];
  trends: {
    requests: number;
    users: number;
    performance: number;
  };
}

// API response types
export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
  timestamp: string;
}

// Configuration types
export interface SystemConfig {
  treasury: {
    enabled: boolean;
    percentage: number;
    currency: string;
    autoRouting: boolean;
  };
  primalGenesis: {
    enabled: boolean;
    auditLevel: 'basic' | 'detailed' | 'comprehensive';
    retentionDays: number;
  };
  lilithOS: {
    enabled: boolean;
    optimizationLevel: 'low' | 'medium' | 'high';
    autoOptimize: boolean;
  };
  trafficFlou: {
    enabled: boolean;
    maxConcurrent: number;
    rateLimit: number;
  };
}

// Event types
export interface SystemEvent {
  id: string;
  type: string;
  data: any;
  timestamp: string;
  source: string;
}

// Notification types
export interface Notification {
  id: string;
  type: 'info' | 'success' | 'warning' | 'error';
  title: string;
  message: string;
  timestamp: string;
  read: boolean;
  action?: {
    label: string;
    url: string;
  };
} 