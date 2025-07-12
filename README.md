# 🔐 Scrypt Mining Framework

**Advanced Scrypt Cryptocurrency Mining Framework with Real-time Operations**

A comprehensive mining framework for Scrypt algorithm cryptocurrencies like Litecoin and Dogecoin, featuring real-time monitoring, multiple pool support, and an intuitive web interface.

## 🚀 Quick Start

### Prerequisites
- **Node.js 18+** and **npm 9+**
- **macOS** (optimized, other systems may require adjustments)

### Installation & Setup

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd LilithOS
   ```

2. **Run the automated setup**
   ```bash
   ./start-mining-framework.sh setup
   ```

3. **Start the complete framework**
   ```bash
   ./start-mining-framework.sh start
   ```

4. **Open your browser**
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:3001/api/health

## 📋 Available Commands

```bash
# Start the complete mining framework
./start-mining-framework.sh start

# Stop all services
./start-mining-framework.sh stop

# Restart all services
./start-mining-framework.sh restart

# Check current status
./start-mining-framework.sh status

# View recent logs
./start-mining-framework.sh logs

# Perform health check
./start-mining-framework.sh health

# Initial setup
./start-mining-framework.sh setup
```

## 🏗️ Architecture

### Frontend (Port 3000)
- **React 18** with **TypeScript**
- **Vite** for fast development
- **Ant Design** for UI components
- **React Query** for data fetching
- **WebSocket** for real-time updates

### Backend (Port 3001)
- **Node.js** mining controller
- **Express.js** REST API
- **Socket.IO** for real-time communication
- **ProHashing** integration (primary pool)
- **Multiple pool support**

## ⛏️ Mining Features

### Supported Algorithms
- **Scrypt** (Litecoin, Dogecoin)
- **SHA-256** (Bitcoin) - Coming Soon
- **RandomX** (Monero) - Coming Soon

### Mining Pools
- **ProHashing** (Primary - configured)
- **LitecoinPool**
- **DogecoinPool**
- **NiceHash** (routed to ProHashing)
- **Aikapool**

### Real-time Features
- Live hashrate monitoring
- Pool statistics
- Wallet balance tracking
- Mining performance analytics
- Automatic pool switching
- Temperature monitoring

## 🔧 Configuration

### Backend Configuration
The backend automatically configures ProHashing with:
- **Username**: EsKaye
- **Password**: a=scrypt
- **Algorithm**: Scrypt
- **Pool**: ProHashing

### Environment Variables
Create a `.env` file in the backend directory:
```env
# Mining Configuration
MINING_ALGORITHM=scrypt
DEFAULT_POOL=prohashing
PROHASHING_USERNAME=EsKaye
PROHASHING_PASSWORD=a=scrypt

# API Configuration
API_PORT=3001
WS_PORT=3002

# Logging
LOG_LEVEL=info
```

## 📊 Dashboard Features

### Mining Operations
- Start/stop mining operations
- Real-time hashrate display
- Pool connection status
- Worker management
- Performance metrics

### Analytics
- Historical hashrate charts
- Pool performance comparison
- Revenue tracking
- Efficiency metrics
- Temperature monitoring

### Wallet Management
- Multi-wallet support
- Transaction history
- Balance tracking
- Address management
- Security features

### Blockchain Explorer
- Block information
- Transaction details
- Network statistics
- Difficulty tracking
- Block rewards

## 🛠️ Development

### Frontend Development
```bash
# Start frontend only
npm run dev

# Build for production
npm run build

# Type checking
npm run type-check

# Linting
npm run lint
```

### Backend Development
```bash
# Start backend only
cd backend && npm start

# Development mode with auto-restart
cd backend && npm run dev
```

### Testing
```bash
# Run all tests
npm run test

# Test mining operations
npm run test:mining

# Test blockchain integration
npm run test:blockchain
```

## 🔒 Security Features

- **HTTPS/WSS** support
- **API authentication**
- **Rate limiting**
- **Input validation**
- **Secure wallet storage**
- **Environment variable protection**

## 📈 Performance Optimization

- **WebSocket** for real-time updates
- **React Query** for efficient caching
- **Vite** for fast builds
- **Code splitting** for optimal loading
- **Service Worker** for offline support

## 🐛 Troubleshooting

### Common Issues

1. **Port already in use**
   ```bash
   ./start-mining-framework.sh stop
   ./start-mining-framework.sh start
   ```

2. **Dependencies not installed**
   ```bash
   ./start-mining-framework.sh setup
   ```

3. **Backend not responding**
   ```bash
   ./start-mining-framework.sh logs
   ./start-mining-framework.sh restart
   ```

4. **Frontend not loading**
   ```bash
   npm run dev
   # Check browser console for errors
   ```

### Health Checks
```bash
# Check backend health
curl http://localhost:3001/api/health

# Check frontend
curl http://localhost:3000

# View logs
./start-mining-framework.sh logs
```

## 📝 Logs

- **Backend logs**: `mining-controller.log`
- **Frontend logs**: `frontend.log`
- **View logs**: `./start-mining-framework.sh logs`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **M-K-World-Wide Scrypt Team** for the mining framework
- **ProHashing** for pool integration
- **React** and **Vite** communities
- **Ant Design** for UI components

## 📞 Support

For support and questions:
- Check the troubleshooting section
- Review the logs: `./start-mining-framework.sh logs`
- Open an issue on GitHub

---

**🔐 Scrypt Mining Framework v1.0.0** - Advanced Cryptocurrency Mining Made Simple
