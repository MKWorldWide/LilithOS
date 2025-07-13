import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'
import { resolve } from 'path'

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html', 'lcov'],
      exclude: [
        'node_modules/',
        'dist/',
        '**/*.d.ts',
        '**/*.config.*',
        '**/test/**',
        '**/__tests__/**',
        '**/coverage/**',
        '**/build/**',
        '**/.next/**',
        '**/cypress/**',
        '**/playwright/**',
        '**/e2e/**',
        '**/stories/**',
        '**/*.stories.*',
        '**/*.test.*',
        '**/*.spec.*',
        '**/node_modules/**',
        '**/backend/node_modules/**',
        '**/src/test/__mocks__/**',
        '**/src/test/__fixtures__/**',
        '**/src/test/3rdparty/**',
        '**/src/test/vendor/**',
        '**/backend/test/3rdparty/**',
        '**/backend/test/vendor/**'
      ]
    },
    include: [
      'src/test/**/*.test.{js,jsx,ts,tsx}',
      'src/test/**/*.spec.{js,jsx,ts,tsx}',
      'src/test/quantum-*.ts',
      'src/test/quantum-*.tsx',
      'backend/test/quantum-*.js',
      'src/test/quantum-integration.test.ts'
    ],
    exclude: [
      'node_modules/',
      'dist/',
      'build/',
      'coverage/',
      '**/*.d.ts',
      '**/node_modules/**',
      '**/backend/node_modules/**',
      '**/src/test/__mocks__/**',
      '**/src/test/__fixtures__/**',
      '**/src/test/3rdparty/**',
      '**/src/test/vendor/**',
      '**/backend/test/3rdparty/**',
      '**/backend/test/vendor/**'
    ]
  },
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
      '@backend': resolve(__dirname, './backend'),
      '@components': resolve(__dirname, './src/components'),
      '@pages': resolve(__dirname, './src/pages'),
      '@hooks': resolve(__dirname, './src/hooks'),
      '@types': resolve(__dirname, './src/types'),
      '@utils': resolve(__dirname, './src/utils')
    }
  },
  define: {
    'process.env.NODE_ENV': '"test"',
    'process.env.VITEST': 'true'
  }
}) 