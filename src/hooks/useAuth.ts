/**
 * 🔐 Authentication Hook - Enhanced AI Revenue Routing System
 * 
 * Custom hook for handling authentication state and operations
 * 
 * @author Divine Architect + TrafficFlou Team
 * @version 3.0.0
 * @license LilithOS
 */

import { useState, useEffect, useCallback } from 'react';
import { User } from '../types/system';

interface AuthState {
  isAuthenticated: boolean;
  user: User | null;
  loading: boolean;
  error: string | null;
}

interface AuthActions {
  login: () => Promise<void>;
  logout: () => Promise<void>;
  refreshUser: () => Promise<void>;
}

export const useAuth = (): AuthState & AuthActions => {
  const [state, setState] = useState<AuthState>({
    isAuthenticated: false,
    user: null,
    loading: true,
    error: null,
  });

  // Mock user data for development
  const mockUser: User = {
    id: '1',
    username: 'divine-architect',
    email: 'architect@lilithos.ai',
    role: 'admin',
    permissions: ['read', 'write', 'admin', 'configure'],
    createdAt: new Date().toISOString(),
    lastLogin: new Date().toISOString(),
  };

  // Initialize authentication
  useEffect(() => {
    const initializeAuth = async () => {
      try {
        // Check for existing session
        const token = localStorage.getItem('auth_token');
        
        if (token) {
          // Validate token and get user info
          // For now, we'll use mock authentication
          setState({
            isAuthenticated: true,
            user: mockUser,
            loading: false,
            error: null,
          });
        } else {
          setState(prev => ({
            ...prev,
            loading: false,
          }));
        }
      } catch (error) {
        console.error('Authentication initialization failed:', error);
        setState({
          isAuthenticated: false,
          user: null,
          loading: false,
          error: 'Authentication failed',
        });
      }
    };

    initializeAuth();
  }, []);

  // Login function
  const login = useCallback(async () => {
    try {
      setState(prev => ({ ...prev, loading: true, error: null }));
      
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Store token
      localStorage.setItem('auth_token', 'mock_token_123');
      
      setState({
        isAuthenticated: true,
        user: mockUser,
        loading: false,
        error: null,
      });
      
      console.log('🔐 User authenticated successfully');
    } catch (error) {
      console.error('Login failed:', error);
      setState(prev => ({
        ...prev,
        loading: false,
        error: 'Login failed',
      }));
    }
  }, []);

  // Logout function
  const logout = useCallback(async () => {
    try {
      setState(prev => ({ ...prev, loading: true }));
      
      // Clear token
      localStorage.removeItem('auth_token');
      
      setState({
        isAuthenticated: false,
        user: null,
        loading: false,
        error: null,
      });
      
      console.log('🔐 User logged out successfully');
    } catch (error) {
      console.error('Logout failed:', error);
      setState(prev => ({
        ...prev,
        loading: false,
        error: 'Logout failed',
      }));
    }
  }, []);

  // Refresh user data
  const refreshUser = useCallback(async () => {
    try {
      if (!state.isAuthenticated) return;
      
      // Simulate API call to refresh user data
      await new Promise(resolve => setTimeout(resolve, 500));
      
      setState(prev => ({
        ...prev,
        user: {
          ...prev.user!,
          lastLogin: new Date().toISOString(),
        },
      }));
    } catch (error) {
      console.error('Failed to refresh user data:', error);
    }
  }, [state.isAuthenticated]);

  return {
    ...state,
    login,
    logout,
    refreshUser,
  };
}; 