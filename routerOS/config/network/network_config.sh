#!/bin/bash

# LilithOS Router Network Configuration
# Netgear Nighthawk R7000P
#
# This script configures the network settings for the LilithOS router
# with specific optimizations for Switch development environment.
#
# Author: LilithOS Development Team
# Version: 1.0.0

# ============================================================================
# CONFIGURATION VARIABLES
# ============================================================================

# Network interfaces
WAN_INTERFACE="eth0"
LAN_INTERFACE="br0"
WIFI_2G_INTERFACE="wl0"
WIFI_5G_INTERFACE="wl1"

# Network addresses
LAN_NETWORK="192.168.1.0/24"
LAN_GATEWAY="192.168.1.1"
SWITCH_IP="192.168.1.100"
DEVELOPMENT_NETWORK="192.168.2.0/24"
DEVELOPMENT_GATEWAY="192.168.2.1"

# DNS servers
PRIMARY_DNS="8.8.8.8"
SECONDARY_DNS="1.1.1.1"

# WiFi settings
WIFI_2G_SSID="LilithOS-2G"
WIFI_5G_SSID="LilithOS-5G"
WIFI_PASSWORD="LilithOS2024!"
WIFI_CHANNEL_2G="6"
WIFI_CHANNEL_5G="36"

# QoS settings
GAMING_PRIORITY="1"
DEVELOPMENT_PRIORITY="2"
NORMAL_PRIORITY="3"
BACKGROUND_PRIORITY="4"

# ============================================================================
# COLOR OUTPUT
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${PURPLE}[INFO]${NC} $1"
}

# ============================================================================
# NETWORK INTERFACE CONFIGURATION
# ============================================================================

configure_lan_interface() {
    print_step "Configuring LAN interface..."
    
    # Create bridge interface
    brctl addbr br0 2>/dev/null || true
    brctl addif br0 eth1
    brctl addif br0 eth2
    brctl addif br0 eth3
    brctl addif br0 eth4
    
    # Configure bridge
    ip link set br0 up
    ip addr add $LAN_GATEWAY/24 dev br0
    
    # Enable IP forwarding
    echo 1 > /proc/sys/net/ipv4/ip_forward
    
    print_success "LAN interface configured"
}

configure_wifi_interfaces() {
    print_step "Configuring WiFi interfaces..."
    
    # Configure 2.4GHz WiFi
    iwconfig $WIFI_2G_INTERFACE mode master
    iwconfig $WIFI_2G_INTERFACE channel $WIFI_CHANNEL_2G
    iwconfig $WIFI_2G_INTERFACE essid "$WIFI_2G_SSID"
    
    # Configure 5GHz WiFi
    iwconfig $WIFI_5G_INTERFACE mode master
    iwconfig $WIFI_5G_INTERFACE channel $WIFI_CHANNEL_5G
    iwconfig $WIFI_5G_INTERFACE essid "$WIFI_5G_SSID"
    
    # Add WiFi interfaces to bridge
    brctl addif br0 $WIFI_2G_INTERFACE
    brctl addif br0 $WIFI_5G_INTERFACE
    
    print_success "WiFi interfaces configured"
}

configure_wifi_security() {
    print_step "Configuring WiFi security..."
    
    # Configure WPA3 security for 2.4GHz
    wpa_supplicant -B -i $WIFI_2G_INTERFACE -c /etc/wpa_supplicant/wpa_supplicant_2g.conf
    
    # Configure WPA3 security for 5GHz
    wpa_supplicant -B -i $WIFI_5G_INTERFACE -c /etc/wpa_supplicant/wpa_supplicant_5g.conf
    
    print_success "WiFi security configured"
}

# ============================================================================
# DHCP SERVER CONFIGURATION
# ============================================================================

configure_dhcp_server() {
    print_step "Configuring DHCP server..."
    
    # Create DHCP configuration
    cat > /etc/dhcp/dhcpd.conf << EOF
# LilithOS Router DHCP Configuration

# Global settings
default-lease-time 86400;
max-lease-time 604800;
authoritative;

# LAN subnet
subnet 192.168.1.0 netmask 255.255.255.0 {
    range 192.168.1.100 192.168.1.200;
    option routers $LAN_GATEWAY;
    option domain-name-servers $PRIMARY_DNS, $SECONDARY_DNS;
    option domain-name "lilithos.local";
    
    # Static IP for Switch
    host nintendo-switch {
        hardware ethernet 00:11:22:33:44:55;
        fixed-address $SWITCH_IP;
    }
    
    # Static IP for development machines
    host dev-machine-1 {
        hardware ethernet aa:bb:cc:dd:ee:ff;
        fixed-address 192.168.1.101;
    }
}

# Development network subnet
subnet 192.168.2.0 netmask 255.255.255.0 {
    range 192.168.2.100 192.168.2.200;
    option routers $DEVELOPMENT_GATEWAY;
    option domain-name-servers $PRIMARY_DNS, $SECONDARY_DNS;
    option domain-name "dev.lilithos.local";
}
EOF
    
    # Start DHCP server
    dhcpd -cf /etc/dhcp/dhcpd.conf br0
    
    print_success "DHCP server configured and started"
}

# ============================================================================
# FIREWALL CONFIGURATION
# ============================================================================

configure_firewall() {
    print_step "Configuring firewall..."
    
    # Flush existing rules
    iptables -F
    iptables -X
    iptables -t nat -F
    iptables -t nat -X
    
    # Set default policies
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT ACCEPT
    
    # Allow loopback
    iptables -A INPUT -i lo -j ACCEPT
    
    # Allow established connections
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
    
    # Allow SSH access
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    
    # Allow web interface
    iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    iptables -A INPUT -p tcp --dport 443 -j ACCEPT
    
    # Allow Switch communication
    iptables -A INPUT -s $SWITCH_IP -j ACCEPT
    iptables -A FORWARD -s $SWITCH_IP -j ACCEPT
    
    # Allow LAN to WAN forwarding
    iptables -A FORWARD -i br0 -o $WAN_INTERFACE -j ACCEPT
    
    # NAT configuration
    iptables -t nat -A POSTROUTING -o $WAN_INTERFACE -j MASQUERADE
    
    # Save rules
    iptables-save > /etc/iptables/rules.v4
    
    print_success "Firewall configured"
}

# ============================================================================
# QoS CONFIGURATION
# ============================================================================

configure_qos() {
    print_step "Configuring Quality of Service..."
    
    # Load QoS modules
    modprobe sch_htb
    modprobe sch_sfq
    modprobe cls_u32
    
    # Configure traffic classes
    tc qdisc add dev br0 root handle 1: htb default 30
    
    # Create traffic classes
    tc class add dev br0 parent 1: classid 1:1 htb rate 1000mbit
    tc class add dev br0 parent 1:1 classid 1:10 htb rate 200mbit prio $GAMING_PRIORITY
    tc class add dev br0 parent 1:1 classid 1:20 htb rate 300mbit prio $DEVELOPMENT_PRIORITY
    tc class add dev br0 parent 1:1 classid 1:30 htb rate 400mbit prio $NORMAL_PRIORITY
    tc class add dev br0 parent 1:1 classid 1:40 htb rate 100mbit prio $BACKGROUND_PRIORITY
    
    # Gaming traffic (Switch, gaming consoles)
    tc filter add dev br0 protocol ip parent 1:0 prio 1 u32 \
        match ip src $SWITCH_IP/32 flowid 1:10
    
    # Development traffic
    tc filter add dev br0 protocol ip parent 1:0 prio 2 u32 \
        match ip src 192.168.1.101/32 flowid 1:20
    
    # Background traffic
    tc filter add dev br0 protocol ip parent 1:0 prio 3 u32 \
        match ip dport 80 0xffff flowid 1:40
    tc filter add dev br0 protocol ip parent 1:0 prio 3 u32 \
        match ip dport 443 0xffff flowid 1:40
    
    print_success "QoS configured"
}

# ============================================================================
# DNS CONFIGURATION
# ============================================================================

configure_dns() {
    print_step "Configuring DNS..."
    
    # Configure dnsmasq
    cat > /etc/dnsmasq.conf << EOF
# LilithOS Router DNS Configuration

# Interface binding
interface=br0
bind-interfaces

# DNS servers
server=$PRIMARY_DNS
server=$SECONDARY_DNS

# Local domain
domain=lilithos.local

# DHCP integration
dhcp-option=3,$LAN_GATEWAY
dhcp-option=6,$PRIMARY_DNS,$SECONDARY_DNS

# Local hostnames
address=/router.lilithos.local/$LAN_GATEWAY
address=/switch.lilithos.local/$SWITCH_IP
address=/dev.lilithos.local/192.168.1.101

# Cache settings
cache-size=1000
neg-ttl=3600
local-ttl=300
EOF
    
    # Start dnsmasq
    dnsmasq -C /etc/dnsmasq.conf
    
    print_success "DNS configured"
}

# ============================================================================
# SWITCH INTEGRATION
# ============================================================================

configure_switch_integration() {
    print_step "Configuring Switch integration..."
    
    # Create Switch-specific network rules
    iptables -A FORWARD -s $SWITCH_IP -p udp --dport 45000:65000 -j ACCEPT
    iptables -A FORWARD -s $SWITCH_IP -p tcp --dport 45000:65000 -j ACCEPT
    
    # Enable Switch traffic monitoring
    echo 1 > /proc/sys/net/ipv4/conf/all/log_martians
    echo 1 > /proc/sys/net/ipv4/conf/br0/log_martians
    
    # Create Switch network namespace (optional)
    ip netns add switch-ns 2>/dev/null || true
    
    print_success "Switch integration configured"
}

# ============================================================================
# MONITORING AND LOGGING
# ============================================================================

configure_monitoring() {
    print_step "Configuring monitoring and logging..."
    
    # Enable network monitoring
    echo 1 > /proc/sys/net/ipv4/tcp_window_scaling
    echo 1 > /proc/sys/net/ipv4/tcp_timestamps
    echo 1 > /proc/sys/net/ipv4/tcp_sack
    
    # Configure logging
    cat > /etc/rsyslog.d/lilithos-router.conf << EOF
# LilithOS Router Logging Configuration

# Network traffic logs
:programname, contains, "lilithos" /var/log/lilithos-router.log
& stop

# Firewall logs
:programname, contains, "iptables" /var/log/firewall.log
& stop

# Switch communication logs
:programname, contains, "switch" /var/log/switch-comm.log
& stop
EOF
    
    # Restart logging service
    systemctl restart rsyslog
    
    print_success "Monitoring and logging configured"
}

# ============================================================================
# MAIN CONFIGURATION FUNCTION
# ============================================================================

configure_network() {
    print_info "Starting LilithOS Router network configuration..."
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root"
        exit 1
    fi
    
    # Configure network interfaces
    configure_lan_interface
    configure_wifi_interfaces
    configure_wifi_security
    
    # Configure services
    configure_dhcp_server
    configure_dns
    configure_firewall
    configure_qos
    
    # Configure Switch integration
    configure_switch_integration
    
    # Configure monitoring
    configure_monitoring
    
    print_success "LilithOS Router network configuration completed!"
    print_info "LAN Gateway: $LAN_GATEWAY"
    print_info "Switch IP: $SWITCH_IP"
    print_info "WiFi SSID (2.4G): $WIFI_2G_SSID"
    print_info "WiFi SSID (5G): $WIFI_5G_SSID"
}

# ============================================================================
# SCRIPT EXECUTION
# ============================================================================

case "${1:-}" in
    "start")
        configure_network
        ;;
    "stop")
        print_step "Stopping network services..."
        systemctl stop dhcpd
        systemctl stop dnsmasq
        print_success "Network services stopped"
        ;;
    "restart")
        $0 stop
        sleep 2
        $0 start
        ;;
    "status")
        print_info "Network Status:"
        ip addr show br0
        echo
        print_info "DHCP Leases:"
        cat /var/lib/dhcp/dhcpd.leases | tail -10
        echo
        print_info "Active Connections:"
        netstat -tuln
        ;;
    "help"|"-h"|"--help")
        echo "LilithOS Router Network Configuration"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  start    Configure and start network services"
        echo "  stop     Stop network services"
        echo "  restart  Restart network services"
        echo "  status   Show network status"
        echo "  help     Show this help message"
        ;;
    *)
        print_error "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac 