#!/bin/bash
# Updated device-alert.sh - reads from config file

# Set paths relative to script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../config/devices.conf"
LOG_FILE="$SCRIPT_DIR/../logs/device-alerts-$(date +%Y-%m-%d).log"

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config file not found at $CONFIG_FILE"
    exit 1
fi

# Read devices from config file (skip comments and empty lines)
while IFS=':' read -r IP NAME || [[ -n "$IP" ]]; do
    # Skip empty lines and comments
    [[ -z "$IP" || "$IP" =~ ^[[:space:]]*# ]] && continue
    
    # Remove any whitespace
    IP=$(echo "$IP" | xargs)
    NAME=$(echo "$NAME" | xargs)
    
    # Skip if IP is empty after cleaning
    [[ -z "$IP" ]] && continue
    
    echo "Checking $NAME ($IP)..."
    
    if ping -c 2 "$IP" > /dev/null 2>&1; then
        echo "✅ $NAME ($IP): UP"
    else
        echo "❌ $NAME ($IP): DOWN"
        echo "$(date '+%Y-%m-%d %H:%M:%S'): $NAME ($IP): DOWN" >> "$LOG_FILE"
    fi
    
done < "$CONFIG_FILE"

echo "Device check complete. Alerts logged to: $LOG_FILE"
