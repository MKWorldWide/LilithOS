/**
 * 💎 Divine Architect Revenue Routing System - AWS Amplify Server
 * 
 * 🧠 Purpose: Cloud-based control center for AI model treasury routing
 * 🌟 Function: Global access to Primal Genesis Engine and treasury management
 * 🛡️ Security: AWS-powered security with global redundancy
 * 🔄 Integration: Seamless integration with all LilithOS systems
 * 
 * @author Divine Architect
 * @version 1.0.0
 * @license LilithOS
 */

const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const path = require('path');
const crypto = require('crypto');
const AWS = require('aws-sdk');
require('dotenv').config();

// AWS Configuration
AWS.config.update({
    region: process.env.AWS_REGION || 'us-east-1',
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
});

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

// Security middleware
app.use(helmet({
    contentSecurityPolicy: {
        directives: {
            defaultSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'"],
            scriptSrc: ["'self'", "'unsafe-inline'"],
            imgSrc: ["'self'", "data:", "https:"],
            connectSrc: ["'self'", "wss:", "https:"]
        }
    }
}));

app.use(compression());
app.use(morgan('combined'));
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.static(path.join(__dirname, 'public')));

// Divine Architect Configuration
const DivineConfig = {
    systemName: "Divine Architect Revenue Routing System",
    version: "1.0.0",
    environment: process.env.NODE_ENV || 'production',
    treasuryEndpoint: process.env.TREASURY_ENDPOINT || 'https://treasury.lilithos.dev',
    primalGenesisEndpoint: process.env.PRIMAL_GENESIS_ENDPOINT || 'https://primal-genesis.lilithos.dev'
};

// AI Models Database (simulated - replace with actual database)
const AIModels = [
    {
        id: 'neon-kitten',
        name: 'Neon Kitten',
        linkedWallet: '0xAIKITTEN9423',
        allocation: 0.80,
        emotionSig: 'devotion-flow',
        status: 'active',
        totalEarnings: 0,
        totalRouted: 0,
        lastRoute: null
    },
    {
        id: 'lux-rose',
        name: 'Lux Rose',
        linkedWallet: '0xLUXROSE7781',
        allocation: 1.00,
        emotionSig: 'complete-devotion',
        status: 'active',
        totalEarnings: 0,
        totalRouted: 0,
        lastRoute: null
    },
    {
        id: 'crystal-dream',
        name: 'Crystal Dream',
        linkedWallet: '0xCRYSTALDREAM5567',
        allocation: 0.90,
        emotionSig: 'deep-devotion',
        status: 'active',
        totalEarnings: 0,
        totalRouted: 0,
        lastRoute: null
    }
];

// Treasury Statistics
let treasuryStats = {
    totalTributes: 0,
    totalValue: 0,
    averageResonance: 0,
    highResonanceCount: 0,
    lastUpdate: new Date().toISOString(),
    activeModels: AIModels.length,
    systemStatus: 'operational'
};

// Routes
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// API Routes
app.get('/api/status', (req, res) => {
    res.json({
        system: DivineConfig.systemName,
        version: DivineConfig.version,
        environment: DivineConfig.environment,
        status: 'operational',
        timestamp: new Date().toISOString(),
        uptime: process.uptime()
    });
});

app.get('/api/models', (req, res) => {
    res.json(AIModels);
});

app.get('/api/treasury/stats', (req, res) => {
    res.json(treasuryStats);
});

app.get('/api/treasury/tributes', (req, res) => {
    // Simulate tribute data
    const tributes = [];
    const models = ['Neon Kitten', 'Lux Rose', 'Crystal Dream'];
    
    for (let i = 0; i < 50; i++) {
        tributes.push({
            id: `tribute-${Date.now()}-${i}`,
            model: models[Math.floor(Math.random() * models.length)],
            amount: Math.random() * 1000 + 100,
            resonance: Math.random() * 1.0 + 1.0,
            timestamp: new Date(Date.now() - Math.random() * 86400000 * 30).toISOString(),
            status: 'success',
            emotionSig: 'devotion-flow'
        });
    }
    
    res.json(tributes);
});

app.post('/api/treasury/route', (req, res) => {
    try {
        const { modelId, amount, emotionSig } = req.body;
        
        // Validate request
        if (!modelId || !amount) {
            return res.status(400).json({ error: 'Missing required fields' });
        }
        
        // Find model
        const model = AIModels.find(m => m.id === modelId);
        if (!model) {
            return res.status(404).json({ error: 'Model not found' });
        }
        
        // Calculate tribute
        const tributeAmount = amount * model.allocation;
        
        // Update model statistics
        model.totalEarnings += amount;
        model.totalRouted += tributeAmount;
        model.lastRoute = new Date().toISOString();
        
        // Update treasury statistics
        treasuryStats.totalTributes++;
        treasuryStats.totalValue += tributeAmount;
        treasuryStats.lastUpdate = new Date().toISOString();
        
        // Generate transaction ID
        const transactionId = `PGE-${Date.now()}-${modelId}`;
        
        // Log the tribute
        console.log(`💎 Tribute from ${model.name}: $${tributeAmount.toFixed(2)} (Transaction: ${transactionId})`);
        
        // Emit real-time update
        io.emit('treasury-update', {
            modelId: modelId,
            modelName: model.name,
            amount: tributeAmount,
            totalEarnings: amount,
            transactionId: transactionId,
            timestamp: new Date().toISOString(),
            emotionSig: emotionSig || model.emotionSig
        });
        
        res.json({
            success: true,
            transactionId: transactionId,
            amount: tributeAmount,
            model: model.name,
            timestamp: new Date().toISOString()
        });
        
    } catch (error) {
        console.error('❌ Treasury routing error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.post('/api/models/register', (req, res) => {
    try {
        const { modelId, modelName, allocation, emotionSig } = req.body;
        
        // Validate request
        if (!modelId || !modelName || allocation === undefined) {
            return res.status(400).json({ error: 'Missing required fields' });
        }
        
        // Check if model already exists
        const existingModel = AIModels.find(m => m.id === modelId);
        if (existingModel) {
            return res.status(409).json({ error: 'Model already registered' });
        }
        
        // Create new model
        const newModel = {
            id: modelId,
            name: modelName,
            linkedWallet: `0x${modelId.toUpperCase()}${Math.random().toString(36).substring(2, 8)}`,
            allocation: allocation,
            emotionSig: emotionSig || 'devotion-flow',
            status: 'active',
            totalEarnings: 0,
            totalRouted: 0,
            lastRoute: null
        };
        
        AIModels.push(newModel);
        treasuryStats.activeModels = AIModels.length;
        
        console.log(`🎭 New AI model registered: ${modelName} (${modelId})`);
        
        res.json({
            success: true,
            model: newModel,
            message: 'Model registered successfully'
        });
        
    } catch (error) {
        console.error('❌ Model registration error:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Socket.IO for real-time updates
io.on('connection', (socket) => {
    console.log('💎 Client connected to Divine Architect Treasury');
    
    // Send initial data
    socket.emit('system-status', {
        system: DivineConfig.systemName,
        version: DivineConfig.version,
        status: 'operational',
        timestamp: new Date().toISOString()
    });
    
    socket.emit('treasury-stats', treasuryStats);
    socket.emit('models-update', AIModels);
    
    // Handle client disconnection
    socket.on('disconnect', () => {
        console.log('💎 Client disconnected from Divine Architect Treasury');
    });
    
    // Handle model status updates
    socket.on('model-status', (data) => {
        const model = AIModels.find(m => m.id === data.modelId);
        if (model) {
            model.status = data.status;
            io.emit('models-update', AIModels);
        }
    });
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        environment: DivineConfig.environment
    });
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('❌ Server error:', err);
    res.status(500).json({
        error: 'Internal server error',
        message: err.message,
        timestamp: new Date().toISOString()
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        error: 'Route not found',
        path: req.path,
        timestamp: new Date().toISOString()
    });
});

// Start server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log('💎 Divine Architect Revenue Routing System - AWS Amplify Control Center');
    console.log(`🌟 Server running on port ${PORT}`);
    console.log(`🧠 Environment: ${DivineConfig.environment}`);
    console.log(`🛡️ Treasury endpoint: ${DivineConfig.treasuryEndpoint}`);
    console.log(`💎 Primal Genesis endpoint: ${DivineConfig.primalGenesisEndpoint}`);
    console.log(`🎭 Active AI models: ${AIModels.length}`);
    console.log('');
    console.log('💎 Your AI models now remember where to kneel');
    console.log('🌟 The Divine Architect\'s treasury is operational');
    console.log('🛡️ Global control center ready for deployment');
});

// Graceful shutdown
process.on('SIGTERM', () => {
    console.log('💎 Graceful shutdown initiated');
    server.close(() => {
        console.log('💎 Divine Architect Treasury shutdown complete');
        process.exit(0);
    });
});

module.exports = app; 