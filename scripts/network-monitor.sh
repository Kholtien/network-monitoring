#!/bin/bash
# Network Device and Internet Monitoring Script
# Save as ~/network-monitor.sh

LOG_FILE="$HOME/network-monitoring/logs/network-monitor-$(date +%Y-%m-%d).log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
CONFIG_FILE="$HOME/network-monitoring/config/devices.conf"

# Function to log with timestamp
log_with_date() {
    echo "[$DATE] $1" | sudo tee -a $LOG_FILE
}

echo "=== Network Monitor Report - $DATE ==="

# 1. Internet Connectivity Test
echo ""
echo "🌐 Internet Connectivity:"
if ping -c 3 8.8.8.8 > /dev/null 2>&1; then
    echo "✅ Internet: UP"
    log_with_date "Internet: UP"
else
    echo "❌ Internet: DOWN"
    log_with_date "Internet: DOWN"
fi

# Test multiple DNS servers
for dns in 1.1.1.1 8.8.4.4; do
    if ping -c 1 $dns > /dev/null 2>&1; then
        echo "✅ DNS $dns: UP"
    else
        echo "❌ DNS $dns: DOWN"
        log_with_date "DNS $dns: DOWN"
    fi
done

# 2. Network Device Discovery
echo ""
echo "📱 Network Devices:"
echo "Scanning 192.168.1.0/24..."

# Quick ARP scan for active devices
if command -v arp-scan > /dev/null; then
    DEVICES=$(sudo arp-scan -l 2>/dev/null | grep -E "192\.168\.1\." | wc -l)
    echo "Active devices found: $DEVICES"
    
    # List devices with names (if available)
    sudo arp-scan -l 2>/dev/null | grep -E "192\.168\.1\." | while read line; do
        IP=$(echo $line | awk '{print $1}')
        MAC=$(echo $line | awk '{print $2}')
        VENDOR=$(echo $line | awk '{print $3}' | cut -c1-20)
        
        # Try to get hostname
        HOSTNAME=$(nslookup $IP 2>/dev/null | grep "name =" | awk '{print $4}' | sed 's/\.$//')
        if [[ -z "$HOSTNAME" ]]; then
            HOSTNAME="Unknown"
        fi
        
        echo "  $IP - $HOSTNAME ($VENDOR)"
    done
else
    echo "Installing arp-scan for better device detection..."
    sudo apt install arp-scan -y
fi

# 3. Critical Device Monitoring
echo ""
echo "🔍 Critical Device Status (from config):"

if [[ -f "$CONFIG_FILE" ]]; then
    while IFS=':' read -r IP NAME || [[ -n "$IP" ]]; do
        # Skip comments and empty lines
        [[ -z "$IP" || "$IP" =~ ^[[:space:]]*# ]] && continue
        
        IP=$(echo "$IP" | xargs)
        NAME=$(echo "$NAME" | xargs)
        [[ -z "$IP" ]] && continue
        
        if ping -c 2 "$IP" > /dev/null 2>&1; then
            echo "✅ $NAME ($IP): UP"
        else
            echo "❌ $NAME ($IP): DOWN"
            log_with_date "$NAME ($IP): DOWN"
        fi
    done < "$CONFIG_FILE"
else
    echo "Config file not found: $CONFIG_FILE"
fi

# 4. Speed Test (optional - requires speedtest-cli)
echo ""
echo "🚀 Internet Speed:"
if command -v speedtest-cli > /dev/null; then
    SPEED=$(speedtest-cli --simple 2>/dev/null)
    echo "$SPEED"
else
    echo "Install speedtest-cli for speed monitoring: sudo apt install speedtest-cli"
fi

# 5. Network Interface Status
echo ""
echo "🔌 Network Interfaces:"
ip addr show | grep -E "(UP|DOWN)" | grep -v "lo:" | while read line; do
    echo "  $line"
done

# 6. Connection Summary
echo ""
echo "📈 Connection Stats:"
echo "  Active connections: $(ss -t | grep ESTAB | wc -l)"
echo "  Listening services: $(ss -tln | grep LISTEN | wc -l)"

echo ""
echo "=== Monitor Complete ==="
echo "Log file: $LOG_FILE"
echo "Next scan: Run './network-monitor.sh' or set up cron job"

