/**
 * Quantum Test Setup for Scrypt Mining Framework
 * 
 * This file configures the testing environment for comprehensive quantum-level testing
 * of all components in the Scrypt Mining Framework.
 */

import { vi } from 'vitest'
import '@testing-library/jest-dom'

// Mock environment variables for testing
process.env.NODE_ENV = 'test'
process.env.VITE_API_URL = 'http://localhost:3001'
process.env.VITE_WS_URL = 'ws://localhost:3001'
process.env.VITE_APP_NAME = 'Scrypt Mining Framework Test'

// Mock WebSocket
global.WebSocket = vi.fn().mockImplementation(() => ({
  send: vi.fn(),
  close: vi.fn(),
  addEventListener: vi.fn(),
  removeEventListener: vi.fn(),
  readyState: 1,
  CONNECTING: 0,
  OPEN: 1,
  CLOSING: 2,
  CLOSED: 3
}))

// Mock crypto for mining operations
Object.defineProperty(global, 'crypto', {
  value: {
    getRandomValues: vi.fn((arr) => {
      for (let i = 0; i < arr.length; i++) {
        arr[i] = Math.floor(Math.random() * 256)
      }
      return arr
    }),
    subtle: {
      digest: vi.fn(),
      importKey: vi.fn(),
      sign: vi.fn(),
      verify: vi.fn()
    }
  }
})

// Mock localStorage
const localStorageMock = {
  getItem: vi.fn(),
  setItem: vi.fn(),
  removeItem: vi.fn(),
  clear: vi.fn(),
  length: 0,
  key: vi.fn()
}
global.localStorage = localStorageMock

// Mock sessionStorage
const sessionStorageMock = {
  getItem: vi.fn(),
  setItem: vi.fn(),
  removeItem: vi.fn(),
  clear: vi.fn(),
  length: 0,
  key: vi.fn()
}
global.sessionStorage = sessionStorageMock

// Mock fetch for API calls
global.fetch = vi.fn()

// Mock IntersectionObserver
global.IntersectionObserver = vi.fn().mockImplementation(() => ({
  observe: vi.fn(),
  unobserve: vi.fn(),
  disconnect: vi.fn()
}))

// Mock ResizeObserver
global.ResizeObserver = vi.fn().mockImplementation(() => ({
  observe: vi.fn(),
  unobserve: vi.fn(),
  disconnect: vi.fn()
}))

// Mock matchMedia
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
})

// Mock requestAnimationFrame
global.requestAnimationFrame = vi.fn(cb => setTimeout(cb, 0))
global.cancelAnimationFrame = vi.fn()

// Mock performance
Object.defineProperty(global, 'performance', {
  value: {
    now: vi.fn(() => Date.now()),
    mark: vi.fn(),
    measure: vi.fn(),
    getEntriesByType: vi.fn(() => []),
    getEntriesByName: vi.fn(() => [])
  }
})

// Mock console methods to reduce noise in tests
const originalConsole = { ...console }
beforeEach(() => {
  console.log = vi.fn()
  console.warn = vi.fn()
  console.error = vi.fn()
})

afterEach(() => {
  console.log = originalConsole.log
  console.warn = originalConsole.warn
  console.error = originalConsole.error
  vi.clearAllMocks()
})

// Quantum test utilities
export const quantumTestUtils = {
  // Generate mock mining data
  generateMockMiningData: () => ({
    hashrate: Math.random() * 1000,
    difficulty: Math.random() * 1000000,
    shares: Math.floor(Math.random() * 1000),
    rejectedShares: Math.floor(Math.random() * 50),
    uptime: Math.floor(Math.random() * 86400),
    temperature: 40 + Math.random() * 40,
    powerConsumption: 100 + Math.random() * 500,
    efficiency: 0.8 + Math.random() * 0.2
  }),

  // Generate mock blockchain data
  generateMockBlockchainData: () => ({
    blockHeight: Math.floor(Math.random() * 1000000),
    blockTime: Math.floor(Math.random() * 600),
    networkHashrate: Math.random() * 1000000,
    difficulty: Math.random() * 1000000,
    blockReward: 50 + Math.random() * 50,
    totalSupply: Math.random() * 1000000000,
    circulatingSupply: Math.random() * 1000000000
  }),

  // Generate mock wallet data
  generateMockWalletData: () => ({
    address: 'L' + Array.from({ length: 33 }, () => Math.random().toString(36).substr(2, 1)).join(''),
    balance: Math.random() * 1000,
    unconfirmedBalance: Math.random() * 10,
    transactions: Array.from({ length: Math.floor(Math.random() * 10) }, (_, i) => ({
      txid: Array.from({ length: 64 }, () => Math.random().toString(16).substr(2, 1)).join(''),
      amount: Math.random() * 100,
      confirmations: Math.floor(Math.random() * 100),
      time: Date.now() - Math.random() * 86400000,
      type: Math.random() > 0.5 ? 'receive' : 'send'
    }))
  }),

  // Generate mock pool data
  generateMockPoolData: () => ({
    name: ['LitecoinPool', 'DogecoinPool', 'ScryptPool'][Math.floor(Math.random() * 3)],
    url: 'stratum+tcp://pool.example.com:3333',
    user: 'user' + Math.floor(Math.random() * 1000),
    password: 'x',
    hashrate: Math.random() * 1000,
    shares: Math.floor(Math.random() * 1000),
    rejectedShares: Math.floor(Math.random() * 50),
    efficiency: 0.8 + Math.random() * 0.2,
    latency: Math.random() * 100
  }),

  // Wait for async operations
  waitFor: (ms: number) => new Promise(resolve => setTimeout(resolve, ms)),

  // Mock API response
  mockApiResponse: (data: any, status = 200) => {
    return Promise.resolve({
      ok: status >= 200 && status < 300,
      status,
      json: () => Promise.resolve(data),
      text: () => Promise.resolve(JSON.stringify(data)),
      headers: new Headers()
    })
  },

  // Mock WebSocket message
  mockWebSocketMessage: (data: any) => {
    return new MessageEvent('message', {
      data: JSON.stringify(data)
    })
  }
}

// Export for use in tests
export { quantumTestUtils as utils } 