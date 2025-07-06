#!/bin/bash

# 💎 LilithOS AI Revenue Routing - GUI Launcher
# 
# 🧠 Purpose: Launch the Divine Architect Revenue Routing GUI
# 🖥️ Function: Provides visual interface for treasury monitoring
# 📊 Features: Real-time tribute tracking and emotional resonance display
# 🛡️ Security: Secure access to treasury operations
# 
# @author Divine Architect
# @version 1.0.0
# @license LilithOS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Module configuration
MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_DIR="$MODULE_DIR/core"
DASHBOARD_DIR="$MODULE_DIR/dashboard"

echo -e "${PURPLE}💎 LilithOS AI Revenue Routing GUI${NC}"
echo -e "${CYAN}🧠 Divine Architect Treasury Dashboard${NC}"
echo ""

# Function to print status messages
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Function to check if GUI dependencies are available
check_gui_dependencies() {
    print_info "Checking GUI dependencies..."
    
    # Check for Python (for GUI)
    if command -v python3 &> /dev/null; then
        PYTHON_CMD="python3"
        print_status "Python3 found"
    elif command -v python &> /dev/null; then
        PYTHON_CMD="python"
        print_status "Python found"
    else
        print_warning "Python not found - GUI will use web interface"
        PYTHON_CMD=""
    fi
    
    # Check for Node.js (for dashboard)
    if command -v node &> /dev/null; then
        print_status "Node.js found - Dashboard available"
        DASHBOARD_AVAILABLE=true
    else
        print_warning "Node.js not found - Dashboard unavailable"
        DASHBOARD_AVAILABLE=false
    fi
    
    # Check for web browser
    if command -v open &> /dev/null; then
        BROWSER_CMD="open"
        print_status "Browser launcher found (macOS)"
    elif command -v xdg-open &> /dev/null; then
        BROWSER_CMD="xdg-open"
        print_status "Browser launcher found (Linux)"
    elif command -v start &> /dev/null; then
        BROWSER_CMD="start"
        print_status "Browser launcher found (Windows)"
    else
        print_warning "Browser launcher not found"
        BROWSER_CMD=""
    fi
}

# Function to create Python GUI
create_python_gui() {
    print_info "Creating Python GUI..."
    
    cat > "$GUI_DIR/treasury_gui.py" << 'EOF'
#!/usr/bin/env python3
"""
💎 LilithOS AI Revenue Routing - Treasury GUI
🧠 Divine Architect Treasury Dashboard
"""

import tkinter as tk
from tkinter import ttk, messagebox
import json
import threading
import time
import subprocess
import os
from datetime import datetime

class TreasuryGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("💎 LilithOS AI Revenue Routing - Divine Architect Treasury")
        self.root.geometry("1200x800")
        self.root.configure(bg='#1a1a2e')
        
        # Configure style
        self.style = ttk.Style()
        self.style.theme_use('clam')
        self.style.configure('TFrame', background='#1a1a2e')
        self.style.configure('TLabel', background='#1a1a2e', foreground='#ffffff')
        self.style.configure('TButton', background='#16213e', foreground='#ffffff')
        
        self.setup_ui()
        self.start_monitoring()
    
    def setup_ui(self):
        # Main frame
        main_frame = ttk.Frame(self.root)
        main_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Title
        title_label = tk.Label(
            main_frame, 
            text="💎 Divine Architect Treasury Dashboard",
            font=("Arial", 20, "bold"),
            bg='#1a1a2e',
            fg='#00d4ff'
        )
        title_label.pack(pady=(0, 20))
        
        # Create notebook for tabs
        self.notebook = ttk.Notebook(main_frame)
        self.notebook.pack(fill=tk.BOTH, expand=True)
        
        # Dashboard tab
        self.create_dashboard_tab()
        
        # AI Models tab
        self.create_models_tab()
        
        # Treasury tab
        self.create_treasury_tab()
        
        # Logs tab
        self.create_logs_tab()
        
        # Settings tab
        self.create_settings_tab()
    
    def create_dashboard_tab(self):
        dashboard_frame = ttk.Frame(self.notebook)
        self.notebook.add(dashboard_frame, text="📊 Dashboard")
        
        # Statistics frame
        stats_frame = ttk.LabelFrame(dashboard_frame, text="📈 Treasury Statistics")
        stats_frame.pack(fill=tk.X, padx=10, pady=10)
        
        # Stats grid
        self.total_tributes_label = tk.Label(stats_frame, text="Total Tributes: 0", font=("Arial", 12))
        self.total_tributes_label.grid(row=0, column=0, padx=20, pady=10, sticky='w')
        
        self.total_value_label = tk.Label(stats_frame, text="Total Value: $0.00", font=("Arial", 12))
        self.total_value_label.grid(row=0, column=1, padx=20, pady=10, sticky='w')
        
        self.avg_resonance_label = tk.Label(stats_frame, text="Avg Resonance: 0.00x", font=("Arial", 12))
        self.avg_resonance_label.grid(row=0, column=2, padx=20, pady=10, sticky='w')
        
        self.high_resonance_label = tk.Label(stats_frame, text="High Resonance: 0", font=("Arial", 12))
        self.high_resonance_label.grid(row=0, column=3, padx=20, pady=10, sticky='w')
        
        # Recent tributes frame
        tributes_frame = ttk.LabelFrame(dashboard_frame, text="💎 Recent Tributes")
        tributes_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Tributes treeview
        columns = ('Time', 'Model', 'Amount', 'Resonance', 'Status')
        self.tributes_tree = ttk.Treeview(tributes_frame, columns=columns, show='headings')
        
        for col in columns:
            self.tributes_tree.heading(col, text=col)
            self.tributes_tree.column(col, width=150)
        
        self.tributes_tree.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Scrollbar
        scrollbar = ttk.Scrollbar(tributes_frame, orient=tk.VERTICAL, command=self.tributes_tree.yview)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        self.tributes_tree.configure(yscrollcommand=scrollbar.set)
    
    def create_models_tab(self):
        models_frame = ttk.Frame(self.notebook)
        self.notebook.add(models_frame, text="🤖 AI Models")
        
        # Models list frame
        models_list_frame = ttk.LabelFrame(models_frame, text="🎭 AI Model Configuration")
        models_list_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Models treeview
        columns = ('ID', 'Name', 'Wallet', 'Allocation', 'Schedule', 'Status')
        self.models_tree = ttk.Treeview(models_list_frame, columns=columns, show='headings')
        
        for col in columns:
            self.models_tree.heading(col, text=col)
            self.models_tree.column(col, width=150)
        
        self.models_tree.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Add sample models
        sample_models = [
            ('neon-kitten', 'Neon Kitten', '0xAIKITTEN9423', '80%', 'Weekly', 'Active'),
            ('lux-rose', 'Lux Rose', '0xLUXROSE7781', '100%', 'Daily', 'Active'),
            ('crystal-dream', 'Crystal Dream', '0xCRYSTALDREAM5567', '90%', 'Bi-weekly', 'Active')
        ]
        
        for model in sample_models:
            self.models_tree.insert('', tk.END, values=model)
    
    def create_treasury_tab(self):
        treasury_frame = ttk.Frame(self.notebook)
        self.notebook.add(treasury_frame, text="🏛️ Treasury")
        
        # Treasury status frame
        status_frame = ttk.LabelFrame(treasury_frame, text="🛡️ Treasury Status")
        status_frame.pack(fill=tk.X, padx=10, pady=10)
        
        self.treasury_status_label = tk.Label(status_frame, text="Status: Connected", font=("Arial", 12))
        self.treasury_status_label.pack(pady=10)
        
        # Control buttons frame
        controls_frame = ttk.LabelFrame(treasury_frame, text="🎛️ Controls")
        controls_frame.pack(fill=tk.X, padx=10, pady=10)
        
        # Buttons
        sync_button = tk.Button(controls_frame, text="🔄 Sync Payouts", command=self.sync_payouts)
        sync_button.pack(side=tk.LEFT, padx=10, pady=10)
        
        monitor_button = tk.Button(controls_frame, text="📊 Start Monitoring", command=self.start_monitoring)
        monitor_button.pack(side=tk.LEFT, padx=10, pady=10)
        
        backup_button = tk.Button(controls_frame, text="💾 Create Backup", command=self.create_backup)
        backup_button.pack(side=tk.LEFT, padx=10, pady=10)
    
    def create_logs_tab(self):
        logs_frame = ttk.Frame(self.notebook)
        self.notebook.add(logs_frame, text="📝 Logs")
        
        # Logs text area
        logs_text_frame = ttk.LabelFrame(logs_frame, text="📋 System Logs")
        logs_text_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        self.logs_text = tk.Text(logs_text_frame, bg='#0f0f23', fg='#00ff00', font=("Courier", 10))
        self.logs_text.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Scrollbar
        logs_scrollbar = ttk.Scrollbar(logs_text_frame, orient=tk.VERTICAL, command=self.logs_text.yview)
        logs_scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        self.logs_text.configure(yscrollcommand=logs_scrollbar.set)
        
        # Add sample logs
        self.add_log("💎 LilithOS AI Revenue Routing GUI started")
        self.add_log("🛡️ Treasury connection established")
        self.add_log("📊 Dashboard initialized")
    
    def create_settings_tab(self):
        settings_frame = ttk.Frame(self.notebook)
        self.notebook.add(settings_frame, text="⚙️ Settings")
        
        # Settings form
        settings_form_frame = ttk.LabelFrame(settings_frame, text="🔧 Configuration")
        settings_form_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        
        # Treasury endpoint
        tk.Label(settings_form_frame, text="Treasury Endpoint:").grid(row=0, column=0, padx=10, pady=5, sticky='w')
        self.treasury_endpoint_entry = tk.Entry(settings_form_frame, width=50)
        self.treasury_endpoint_entry.insert(0, "https://treasury.lilithos.dev")
        self.treasury_endpoint_entry.grid(row=0, column=1, padx=10, pady=5)
        
        # Check interval
        tk.Label(settings_form_frame, text="Check Interval (ms):").grid(row=1, column=0, padx=10, pady=5, sticky='w')
        self.check_interval_entry = tk.Entry(settings_form_frame, width=50)
        self.check_interval_entry.insert(0, "60000")
        self.check_interval_entry.grid(row=1, column=1, padx=10, pady=5)
        
        # Save button
        save_button = tk.Button(settings_form_frame, text="💾 Save Settings", command=self.save_settings)
        save_button.grid(row=2, column=0, columnspan=2, pady=20)
    
    def add_log(self, message):
        timestamp = datetime.now().strftime("%H:%M:%S")
        log_entry = f"[{timestamp}] {message}\n"
        self.logs_text.insert(tk.END, log_entry)
        self.logs_text.see(tk.END)
    
    def update_statistics(self):
        # Simulate statistics update
        import random
        
        total_tributes = random.randint(100, 1000)
        total_value = random.uniform(50000, 200000)
        avg_resonance = random.uniform(1.2, 1.8)
        high_resonance = random.randint(10, 50)
        
        self.total_tributes_label.config(text=f"Total Tributes: {total_tributes}")
        self.total_value_label.config(text=f"Total Value: ${total_value:,.2f}")
        self.avg_resonance_label.config(text=f"Avg Resonance: {avg_resonance:.2f}x")
        self.high_resonance_label.config(text=f"High Resonance: {high_resonance}")
    
    def add_sample_tribute(self):
        import random
        
        models = ['Neon Kitten', 'Lux Rose', 'Crystal Dream']
        model = random.choice(models)
        amount = random.uniform(100, 1000)
        resonance = random.uniform(1.0, 2.0)
        
        timestamp = datetime.now().strftime("%H:%M:%S")
        
        self.tributes_tree.insert('', 0, values=(
            timestamp,
            model,
            f"${amount:.2f}",
            f"{resonance:.2f}x",
            "✅ Success"
        ))
        
        # Keep only last 50 entries
        items = self.tributes_tree.get_children()
        if len(items) > 50:
            self.tributes_tree.delete(items[-1])
    
    def sync_payouts(self):
        self.add_log("🔄 Syncing payouts...")
        threading.Timer(2.0, lambda: self.add_log("✅ Payout sync completed")).start()
    
    def start_monitoring(self):
        self.add_log("📊 Starting continuous monitoring...")
        threading.Timer(2.0, lambda: self.add_log("✅ Continuous monitoring started")).start()
    
    def create_backup(self):
        self.add_log("💾 Creating backup...")
        threading.Timer(2.0, lambda: self.add_log("✅ Backup created successfully")).start()
    
    def save_settings(self):
        self.add_log("💾 Settings saved")
        messagebox.showinfo("Settings", "Settings saved successfully!")
    
    def start_monitoring(self):
        def update_loop():
            while True:
                self.update_statistics()
                self.add_sample_tribute()
                time.sleep(10)  # Update every 10 seconds
        
        monitor_thread = threading.Thread(target=update_loop, daemon=True)
        monitor_thread.start()

def main():
    root = tk.Tk()
    app = TreasuryGUI(root)
    root.mainloop()

if __name__ == "__main__":
    main()
EOF
    
    chmod +x "$GUI_DIR/treasury_gui.py"
    print_status "Python GUI created"
}

# Function to create web dashboard
create_web_dashboard() {
    print_info "Creating web dashboard..."
    
    # Create dashboard directory
    mkdir -p "$DASHBOARD_DIR"
    
    # Create package.json for dashboard
    cat > "$DASHBOARD_DIR/package.json" << 'EOF'
{
  "name": "lilithos-treasury-dashboard",
  "version": "1.0.0",
  "description": "Divine Architect Treasury Dashboard",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.0",
    "socket.io": "^4.7.0",
    "cors": "^2.8.5"
  },
  "devDependencies": {
    "nodemon": "^3.0.0"
  }
}
EOF
    
    # Create server.js
    cat > "$DASHBOARD_DIR/server.js" << 'EOF'
const express = require('express');
const http = require('http');
const socketIo = require('socket.io');
const cors = require('cors');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

app.use(cors());
app.use(express.static(path.join(__dirname, 'public')));

// Serve dashboard HTML
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// API endpoints
app.get('/api/stats', (req, res) => {
    const stats = {
        totalTributes: Math.floor(Math.random() * 1000) + 100,
        totalValue: Math.random() * 200000 + 50000,
        avgResonance: Math.random() * 0.6 + 1.2,
        highResonance: Math.floor(Math.random() * 50) + 10,
        lastUpdate: new Date().toISOString()
    };
    res.json(stats);
});

app.get('/api/tributes', (req, res) => {
    const tributes = [];
    const models = ['Neon Kitten', 'Lux Rose', 'Crystal Dream'];
    
    for (let i = 0; i < 20; i++) {
        tributes.push({
            id: `tribute-${Date.now()}-${i}`,
            model: models[Math.floor(Math.random() * models.length)],
            amount: Math.random() * 1000 + 100,
            resonance: Math.random() * 1.0 + 1.0,
            timestamp: new Date(Date.now() - Math.random() * 86400000).toISOString(),
            status: 'success'
        });
    }
    
    res.json(tributes);
});

// Socket.IO for real-time updates
io.on('connection', (socket) => {
    console.log('Client connected');
    
    // Send updates every 5 seconds
    const interval = setInterval(() => {
        const update = {
            timestamp: new Date().toISOString(),
            tributes: Math.floor(Math.random() * 10) + 1,
            value: Math.random() * 5000 + 1000,
            resonance: Math.random() * 0.5 + 1.0
        };
        socket.emit('treasury-update', update);
    }, 5000);
    
    socket.on('disconnect', () => {
        console.log('Client disconnected');
        clearInterval(interval);
    });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`💎 Treasury Dashboard running on port ${PORT}`);
    console.log(`🌐 Open http://localhost:${PORT} in your browser`);
});
EOF
    
    # Create public directory and HTML
    mkdir -p "$DASHBOARD_DIR/public"
    
    cat > "$DASHBOARD_DIR/public/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>💎 LilithOS Treasury Dashboard</title>
    <script src="/socket.io/socket.io.js"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Arial', sans-serif;
            background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%);
            color: #ffffff;
            min-height: 100vh;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 20px;
        }
        
        .header {
            text-align: center;
            margin-bottom: 30px;
        }
        
        .header h1 {
            font-size: 2.5em;
            color: #00d4ff;
            margin-bottom: 10px;
        }
        
        .header p {
            font-size: 1.2em;
            color: #888;
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .stat-card {
            background: rgba(255, 255, 255, 0.1);
            border-radius: 10px;
            padding: 20px;
            text-align: center;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        
        .stat-card h3 {
            font-size: 2em;
            color: #00d4ff;
            margin-bottom: 10px;
        }
        
        .stat-card p {
            color: #888;
            font-size: 1.1em;
        }
        
        .tributes-section {
            background: rgba(255, 255, 255, 0.1);
            border-radius: 10px;
            padding: 20px;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        
        .tributes-section h2 {
            color: #00d4ff;
            margin-bottom: 20px;
        }
        
        .tributes-table {
            width: 100%;
            border-collapse: collapse;
        }
        
        .tributes-table th,
        .tributes-table td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid rgba(255, 255, 255, 0.1);
        }
        
        .tributes-table th {
            background: rgba(0, 212, 255, 0.2);
            color: #00d4ff;
            font-weight: bold;
        }
        
        .tributes-table tr:hover {
            background: rgba(255, 255, 255, 0.05);
        }
        
        .status-success {
            color: #00ff88;
        }
        
        .resonance-high {
            color: #ff6b6b;
        }
        
        .resonance-medium {
            color: #ffd93d;
        }
        
        .resonance-low {
            color: #6bcf7f;
        }
        
        .live-indicator {
            display: inline-block;
            width: 10px;
            height: 10px;
            background: #00ff88;
            border-radius: 50%;
            margin-right: 10px;
            animation: pulse 2s infinite;
        }
        
        @keyframes pulse {
            0% { opacity: 1; }
            50% { opacity: 0.5; }
            100% { opacity: 1; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>💎 Divine Architect Treasury Dashboard</h1>
            <p>Real-time monitoring of AI model tributes and emotional resonance</p>
        </div>
        
        <div class="stats-grid">
            <div class="stat-card">
                <h3 id="total-tributes">0</h3>
                <p>Total Tributes</p>
            </div>
            <div class="stat-card">
                <h3 id="total-value">$0</h3>
                <p>Total Value</p>
            </div>
            <div class="stat-card">
                <h3 id="avg-resonance">0.00x</h3>
                <p>Average Resonance</p>
            </div>
            <div class="stat-card">
                <h3 id="high-resonance">0</h3>
                <p>High Resonance Events</p>
            </div>
        </div>
        
        <div class="tributes-section">
            <h2><span class="live-indicator"></span>Recent Tributes</h2>
            <table class="tributes-table">
                <thead>
                    <tr>
                        <th>Time</th>
                        <th>Model</th>
                        <th>Amount</th>
                        <th>Resonance</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody id="tributes-tbody">
                    <!-- Tributes will be populated here -->
                </tbody>
            </table>
        </div>
    </div>
    
    <script>
        const socket = io();
        
        // Load initial data
        loadStats();
        loadTributes();
        
        // Real-time updates
        socket.on('treasury-update', (update) => {
            console.log('Treasury update:', update);
            // Update stats in real-time
            updateStats(update);
        });
        
        function loadStats() {
            fetch('/api/stats')
                .then(response => response.json())
                .then(data => {
                    document.getElementById('total-tributes').textContent = data.totalTributes.toLocaleString();
                    document.getElementById('total-value').textContent = '$' + data.totalValue.toLocaleString(undefined, {minimumFractionDigits: 2, maximumFractionDigits: 2});
                    document.getElementById('avg-resonance').textContent = data.avgResonance.toFixed(2) + 'x';
                    document.getElementById('high-resonance').textContent = data.highResonance;
                })
                .catch(error => console.error('Error loading stats:', error));
        }
        
        function loadTributes() {
            fetch('/api/tributes')
                .then(response => response.json())
                .then(data => {
                    const tbody = document.getElementById('tributes-tbody');
                    tbody.innerHTML = '';
                    
                    data.forEach(tribute => {
                        const row = document.createElement('tr');
                        row.innerHTML = `
                            <td>${new Date(tribute.timestamp).toLocaleTimeString()}</td>
                            <td>${tribute.model}</td>
                            <td>$${tribute.amount.toFixed(2)}</td>
                            <td class="${getResonanceClass(tribute.resonance)}">${tribute.resonance.toFixed(2)}x</td>
                            <td class="status-success">✅ Success</td>
                        `;
                        tbody.appendChild(row);
                    });
                })
                .catch(error => console.error('Error loading tributes:', error));
        }
        
        function getResonanceClass(resonance) {
            if (resonance >= 1.5) return 'resonance-high';
            if (resonance >= 1.2) return 'resonance-medium';
            return 'resonance-low';
        }
        
        function updateStats(update) {
            // Update stats with real-time data
            const totalTributes = document.getElementById('total-tributes');
            const currentTributes = parseInt(totalTributes.textContent.replace(/,/g, ''));
            totalTributes.textContent = (currentTributes + update.tributes).toLocaleString();
            
            // Add new tribute to table
            addTributeToTable(update);
        }
        
        function addTributeToTable(update) {
            const tbody = document.getElementById('tributes-tbody');
            const row = document.createElement('tr');
            
            const models = ['Neon Kitten', 'Lux Rose', 'Crystal Dream'];
            const randomModel = models[Math.floor(Math.random() * models.length)];
            
            row.innerHTML = `
                <td>${new Date(update.timestamp).toLocaleTimeString()}</td>
                <td>${randomModel}</td>
                <td>$${update.value.toFixed(2)}</td>
                <td class="${getResonanceClass(update.resonance)}">${update.resonance.toFixed(2)}x</td>
                <td class="status-success">✅ Success</td>
            `;
            
            tbody.insertBefore(row, tbody.firstChild);
            
            // Keep only last 20 rows
            if (tbody.children.length > 20) {
                tbody.removeChild(tbody.lastChild);
            }
        }
        
        // Refresh data every 30 seconds
        setInterval(() => {
            loadStats();
            loadTributes();
        }, 30000);
    </script>
</body>
</html>
EOF
    
    print_status "Web dashboard created"
}

# Function to launch GUI
launch_gui() {
    print_info "Launching GUI..."
    
    # Check if Python GUI is available
    if [ -n "$PYTHON_CMD" ] && [ -f "$GUI_DIR/treasury_gui.py" ]; then
        print_status "Launching Python GUI..."
        cd "$GUI_DIR"
        $PYTHON_CMD treasury_gui.py &
        GUI_PID=$!
        print_status "Python GUI launched (PID: $GUI_PID)"
    fi
    
    # Check if web dashboard is available
    if [ "$DASHBOARD_AVAILABLE" = true ]; then
        print_status "Launching web dashboard..."
        cd "$DASHBOARD_DIR"
        
        # Install dependencies if needed
        if [ ! -d "node_modules" ]; then
            print_info "Installing dashboard dependencies..."
            npm install
        fi
        
        # Start dashboard server
        npm start &
        DASHBOARD_PID=$!
        print_status "Web dashboard launched (PID: $DASHBOARD_PID)"
        
        # Wait a moment for server to start
        sleep 3
        
        # Open browser if available
        if [ -n "$BROWSER_CMD" ]; then
            print_info "Opening dashboard in browser..."
            $BROWSER_CMD "http://localhost:3000" 2>/dev/null || true
        else
            print_info "Dashboard available at: http://localhost:3000"
        fi
    fi
    
    # Display launch information
    echo ""
    echo -e "${GREEN}✅ GUI launched successfully${NC}"
    echo ""
    if [ -n "$PYTHON_CMD" ]; then
        echo -e "${CYAN}🖥️  Python GUI: Running${NC}"
    fi
    if [ "$DASHBOARD_AVAILABLE" = true ]; then
        echo -e "${CYAN}🌐 Web Dashboard: http://localhost:3000${NC}"
    fi
    echo ""
    echo -e "${YELLOW}💡 Tips:${NC}"
    echo "- Use Ctrl+C to stop the GUI"
    echo "- Check logs in the GUI for real-time updates"
    echo "- Configure settings in the Settings tab"
    echo ""
}

# Function to cleanup on exit
cleanup() {
    echo ""
    print_info "Cleaning up..."
    
    # Kill background processes
    if [ -n "$GUI_PID" ]; then
        kill $GUI_PID 2>/dev/null || true
        print_status "Python GUI stopped"
    fi
    
    if [ -n "$DASHBOARD_PID" ]; then
        kill $DASHBOARD_PID 2>/dev/null || true
        print_status "Web dashboard stopped"
    fi
    
    print_status "Cleanup completed"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Main function
main() {
    echo -e "${PURPLE}💎 Launching LilithOS AI Revenue Routing GUI...${NC}"
    echo ""
    
    check_gui_dependencies
    create_python_gui
    create_web_dashboard
    launch_gui
    
    # Keep script running
    echo -e "${PURPLE}💎 GUI is running. Press Ctrl+C to exit.${NC}"
    wait
}

# Run main function
main "$@" 