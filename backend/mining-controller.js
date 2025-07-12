/**
 * 🔐 Mining Controller - Scrypt Mining Framework
 * 
 * Backend service to control mining operations, handle pool connections,
 * and manage mining processes for the Scrypt Mining Framework.
 * 
 * Features:
 * - Start/stop mining operations
 * - Real-time mining statistics
 * - Pool connection management
 * - Process monitoring and control
 * - WebSocket communication with frontend
 * 
 * @author M-K-World-Wide Scrypt Team
 * @version 1.0.0
 * @license MIT
 */

const express = require('express');
const { spawn } = require('child_process');
const WebSocket = require('ws');
const cors = require('cors');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// WebSocket server for real-time updates
const wss = new WebSocket.Server({ port: 3002 });

// Mining process management
class MiningController {
  constructor() {
    this.miningProcesses = new Map();
    this.miningStats = new Map();
    this.pools = {
      prohashing: {
        name: 'ProHashing Pool',
        url: 'stratum+tcp://us.mining.prohashing.com:3333',
        algorithm: 'scrypt',
        description: 'Professional multi-coin mining pool (Recommended)'
      },
      aikapool: {
        name: 'Aikapool Scrypt',
        url: 'stratum+tcp://stratum.aikapool.com:7950',
        algorithm: 'scrypt',
        description: 'Aikapool Scrypt VarDiff (supports many Scrypt coins)'
      },
      nicehash: {
        name: 'NiceHash Scrypt Rental (ProHashing)',
        url: 'stratum+tcp://us.mining.prohashing.com:3333',
        algorithm: 'scrypt',
        description: 'NiceHash rental pointed at ProHashing',
        username: 'EsKaye',
        password: 'a=scrypt'
      },
      litecoin: {
        name: 'Litecoin Pool',
        url: 'stratum+tcp://litecoinpool.org:3333',
        algorithm: 'scrypt',
        description: 'Popular Litecoin mining pool'
      },
      dogecoin: {
        name: 'Dogecoin Pool',
        url: 'stratum+tcp://prohashing.com:3333',
        algorithm: 'scrypt',
        description: 'Multi-coin mining pool'
      }
    };
  }

  /**
   * Start mining operation
   */
  async startMining(config) {
    const {
      algorithm = 'scrypt',
      pool = 'litecoin',
      wallet,
      workerName = 'worker1',
      threads = 4,
      intensity = 8
    } = config;

    const processId = `${algorithm}-${pool}-${Date.now()}`;
    
    try {
      // Validate configuration
      if (!wallet) {
        throw new Error('Wallet address is required');
      }

      const poolConfig = this.pools[pool];
      if (!poolConfig) {
        throw new Error(`Pool ${pool} not supported`);
      }

      // Determine miner binary based on platform
      const minerBinary = this.getMinerBinary(algorithm);
      if (!minerBinary) {
        throw new Error(`Miner not available for algorithm: ${algorithm}`);
      }

      // Build mining command
      const command = this.buildMiningCommand({
        binary: minerBinary,
        algorithm,
        poolUrl: poolConfig.url,
        wallet,
        workerName,
        threads,
        intensity
      });

      console.log(`Starting mining with command: ${command.join(' ')}`);

      // Spawn mining process
      const miningProcess = spawn(command[0], command.slice(1), {
        cwd: path.join(__dirname, 'miner'),
        stdio: ['pipe', 'pipe', 'pipe']
      });

      // Store process information
      this.miningProcesses.set(processId, {
        process: miningProcess,
        config,
        startTime: new Date(),
        status: 'running'
      });

      // Initialize stats
      this.miningStats.set(processId, {
        hashRate: 0,
        shares: 0,
        rejectedShares: 0,
        uptime: 0,
        lastUpdate: new Date()
      });

      // Handle process output
      miningProcess.stdout.on('data', (data) => {
        this.handleMiningOutput(processId, data.toString());
      });

      miningProcess.stderr.on('data', (data) => {
        this.handleMiningError(processId, data.toString());
      });

      miningProcess.on('close', (code) => {
        this.handleProcessClose(processId, code);
      });

      // Broadcast to WebSocket clients
      this.broadcastUpdate({
        type: 'mining_started',
        processId,
        config
      });

      return {
        success: true,
        processId,
        message: 'Mining started successfully'
      };

    } catch (error) {
      console.error('Failed to start mining:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Stop mining operation
   */
  stopMining(processId) {
    const miningData = this.miningProcesses.get(processId);
    
    if (!miningData) {
      return {
        success: false,
        error: 'Mining process not found'
      };
    }

    try {
      const { process: miningProcess } = miningData;
      
      // Kill the process
      miningProcess.kill('SIGTERM');
      
      // Update status
      miningData.status = 'stopped';
      
      // Broadcast update
      this.broadcastUpdate({
        type: 'mining_stopped',
        processId
      });

      return {
        success: true,
        message: 'Mining stopped successfully'
      };

    } catch (error) {
      console.error('Failed to stop mining:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Get mining status
   */
  getMiningStatus() {
    const status = [];
    
    for (const [processId, miningData] of this.miningProcesses) {
      const stats = this.miningStats.get(processId) || {};
      
      status.push({
        processId,
        status: miningData.status,
        config: miningData.config,
        startTime: miningData.startTime,
        uptime: Date.now() - miningData.startTime.getTime(),
        ...stats
      });
    }

    return status;
  }

  /**
   * Get miner binary path
   */
  getMinerBinary(algorithm) {
    const platform = process.platform;
    const minerDir = path.join(__dirname, 'miner');
    
    const binaries = {
      scrypt: {
        darwin: 'cpuminer-multi-mac',
        linux: 'cpuminer-multi-linux',
        win32: 'cpuminer-multi-win.exe'
      }
    };

    const binaryName = binaries[algorithm]?.[platform];
    if (!binaryName) {
      return null;
    }

    const binaryPath = path.join(minerDir, binaryName);
    return fs.existsSync(binaryPath) ? binaryPath : null;
  }

  /**
   * Build mining command
   */
  buildMiningCommand({ binary, algorithm, poolUrl, wallet, workerName, threads, intensity }) {
    let username, password;
    
    // Special handling for ProHashing pool
    if (poolUrl.includes('prohashing.com')) {
      username = wallet || 'EsKaye'; // Use provided wallet or default username
      password = 'a=scrypt'; // ProHashing specific password
    } else {
      username = `${wallet}.${workerName}`;
      password = 'x';
    }
    
    return [
      binary,
      '--algo=' + algorithm,
      '-o', poolUrl,
      '-u', username,
      '-p', password,
      '-t', threads.toString(),
      '--intensity=' + intensity.toString()
    ];
  }

  /**
   * Handle mining output
   */
  handleMiningOutput(processId, output) {
    console.log(`[${processId}] ${output}`);
    
    // Parse hash rate from output
    const hashRateMatch = output.match(/Hashrate:\s*([\d.]+)\s*([KMGT]?H\/s)/);
    if (hashRateMatch) {
      const hashRate = parseFloat(hashRateMatch[1]);
      const unit = hashRateMatch[2];
      
      // Convert to MH/s
      let hashRateMH = hashRate;
      if (unit === 'KH/s') hashRateMH = hashRate / 1000;
      if (unit === 'GH/s') hashRateMH = hashRate * 1000;
      if (unit === 'TH/s') hashRateMH = hashRate * 1000000;
      
      const stats = this.miningStats.get(processId);
      if (stats) {
        stats.hashRate = hashRateMH;
        stats.lastUpdate = new Date();
      }
    }

    // Parse shares from output
    const sharesMatch = output.match(/Shares:\s*(\d+)\/(\d+)/);
    if (sharesMatch) {
      const accepted = parseInt(sharesMatch[1]);
      const total = parseInt(sharesMatch[2]);
      const rejected = total - accepted;
      
      const stats = this.miningStats.get(processId);
      if (stats) {
        stats.shares = accepted;
        stats.rejectedShares = rejected;
        stats.lastUpdate = new Date();
      }
    }

    // Broadcast real-time updates
    this.broadcastUpdate({
      type: 'mining_output',
      processId,
      output,
      stats: this.miningStats.get(processId)
    });
  }

  /**
   * Handle mining errors
   */
  handleMiningError(processId, error) {
    console.error(`[${processId}] Error: ${error}`);
    
    this.broadcastUpdate({
      type: 'mining_error',
      processId,
      error
    });
  }

  /**
   * Handle process close
   */
  handleProcessClose(processId, code) {
    console.log(`[${processId}] Process closed with code: ${code}`);
    
    const miningData = this.miningProcesses.get(processId);
    if (miningData) {
      miningData.status = 'stopped';
    }

    this.broadcastUpdate({
      type: 'mining_stopped',
      processId,
      code
    });
  }

  /**
   * Broadcast updates to WebSocket clients
   */
  broadcastUpdate(data) {
    wss.clients.forEach((client) => {
      if (client.readyState === WebSocket.OPEN) {
        client.send(JSON.stringify(data));
      }
    });
  }
}

// Initialize mining controller
const miningController = new MiningController();

// WebSocket connection handling
wss.on('connection', (ws) => {
  console.log('WebSocket client connected');
  
  // Send initial status
  ws.send(JSON.stringify({
    type: 'status',
    data: miningController.getMiningStatus()
  }));

  ws.on('close', () => {
    console.log('WebSocket client disconnected');
  });
});

// API Routes

/**
 * Start mining operation
 */
app.post('/api/mining/start', async (req, res) => {
  try {
    const result = await miningController.startMining(req.body);
    res.json(result);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Stop mining operation
 */
app.post('/api/mining/stop/:processId', (req, res) => {
  try {
    const result = miningController.stopMining(req.params.processId);
    res.json(result);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Get mining status
 */
app.get('/api/mining/status', (req, res) => {
  try {
    const status = miningController.getMiningStatus();
    res.json({
      success: true,
      data: status
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Get supported pools
 */
app.get('/api/mining/pools', (req, res) => {
  res.json({
    success: true,
    data: miningController.pools
  });
});

/**
 * Health check
 */
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: 'Mining controller is running',
    timestamp: new Date().toISOString()
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🔐 Mining Controller running on port ${PORT}`);
  console.log(`📡 WebSocket server running on port 3002`);
  console.log(`🌐 API available at http://localhost:${PORT}/api`);
});

module.exports = { app, miningController }; 