# Network Monitoring with Pangolin SSH Security

A comprehensive network monitoring setup designed to work through secure SSH tunnels via Pangolin reverse proxy. This system monitors device connectivity, internet uptime, and network changes while maintaining enterprise-grade security.

## 🏗️ Architecture

```
Client → VPN → Pangolin VPS → WireGuard Tunnel → Target Server → Network Monitoring
```

## 🔒 Security Features

- **SSH Key-only Authentication** - No password attacks possible
- **VPN IP Whitelisting** - External firewall blocks all non-VPN traffic  
- **Docker Network Isolation** - SSH daemon only accessible via container bridge
- **Pangolin Tunnel Encryption** - All traffic encrypted through WireGuard
- **Single User Access** - Only authorized user can connect

## 📁 Directory Structure

```
network-monitoring/
├── scripts/
│   ├── network-monitor.sh     # Main network scanning and monitoring
│   ├── device-alert.sh        # Critical device availability checking
│   └── README.md
├── config/
│   ├── devices.conf           # List of devices to monitor
│   └── README.md
├── logs/                      # Auto-generated log files (gitignored)
│   ├── network-monitor-YYYY-MM-DD.log
│   ├── device-alerts-YYYY-MM-DD.log
│   └── .gitkeep
└── README.md
```

## 🚀 Quick Start

### Prerequisites
- Debian/Ubuntu server with SSH access
- Pangolin reverse proxy with Newt client configured
- VPN with static IP address
- External firewall (BinaryLane or similar)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/network-monitoring.git
   cd network-monitoring
   ```

2. **Install dependencies:**
   ```bash
   sudo apt update
   sudo apt install nmap arp-scan speedtest-cli -y
   ```

3. **Make scripts executable:**
   ```bash
   chmod +x scripts/*.sh
   ```

4. **Configure your devices:**
   ```bash
   nano config/devices.conf
   ```
   Add your network devices in `IP:Name` format:
   ```
   192.168.1.1:Router
   192.168.1.50:NAS
   192.168.1.100:Server
   ```

5. **Test the scripts:**
   ```bash
   ./scripts/network-monitor.sh
   ./scripts/device-alert.sh
   ```

6. **Set up automation:**
   ```bash
   crontab -e
   ```
   Add these lines:
   ```bash
   # Network scan every 15 minutes
   */15 * * * * /home/colton/network-monitoring/scripts/network-monitor.sh

   # Check critical devices every 5 minutes  
   */5 * * * * /home/colton/network-monitoring/scripts/device-alert.sh

   # Daily log compression (after 7 days)
   0 2 * * * find /home/colton/network-monitoring/logs -name "*.log" -mtime +7 -exec gzip {} \;

   # Weekly cleanup (delete compressed logs after 30 days)  
   0 3 * * 0 find /home/colton/network-monitoring/logs -name "*.log.gz" -mtime +30 -delete

   # Daily log size check (prevent any single log from getting too large)
   0 1 * * * find /home/colton/network-monitoring/logs -name "*.log" -size +50M -exec mv {} {}.large \;
   ```

## 🛡️ SSH Security Setup

### 1. SSH Daemon Configuration

Create `/etc/ssh/sshd_config.d/99-security-lockdown.conf`:
```bash
# Core Authentication Security
PasswordAuthentication no
PubkeyAuthentication yes
AuthenticationMethods publickey
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no

# User Access Control
AllowUsers colton
PermitRootLogin no
PermitEmptyPasswords no

# Required for Pangolin TCP forwarding
AllowTcpForwarding yes

# Disable unnecessary features
X11Forwarding no
AllowAgentForwarding no
PermitTunnel no

# Security limits (Docker-friendly)
StrictModes yes
MaxAuthTries 4
MaxStartups 3:50:5
MaxSessions 2
Protocol 2

# Docker bridge network binding
ListenAddress 172.17.0.1
```

### 2. External Firewall Configuration

Configure your external firewall (BinaryLane, etc.) with these rules:
```json
[
  {
    "sourceaddr": "YOUR.VPN.IP.ADDRESS",
    "destaddr": "YOUR.VPS.IP.ADDRESS",
    "destport": "55283",
    "action": "ACCEPT",
    "description": "Allow VPN IP to SSH tunnel"
  },
  {
    "sourceaddr": "0.0.0.0/0",
    "destaddr": "YOUR.VPS.IP.ADDRESS", 
    "destport": "55283",
    "action": "DROP",
    "description": "Block all other SSH tunnel access"
  }
]
```

### 3. Pangolin Resource Configuration

In your Pangolin dashboard:
- **Resource Type:** Raw TCP/UDP Resource
- **Target IP:** 172.17.0.1 (Docker bridge)
- **Target Port:** 22
- **External Port:** 55283

## 📊 Monitoring Features

### Network Discovery
- Automatic device discovery on local network
- ARP table scanning for connected devices
- Device vendor identification

### Internet Connectivity
- Multi-DNS server connectivity testing
- Latency monitoring
- Speed test integration (optional)

### Device Monitoring  
- Configurable critical device list
- Ping-based availability checking
- Automatic alerting for device failures

### Logging
- Daily rotating log files
- Automatic compression after 7 days
- 30-day log retention
- Timestamped entries

## 🔧 Configuration

### devices.conf Format
```bash
# IP:Name format, one per line
192.168.1.1:Router
192.168.1.50:NAS
192.168.1.100:Server

# Comments supported with #
# 192.168.1.200:Old-Device
```

### Log Aliases (Optional)
Add to your `~/.bashrc`:
```bash
alias netlog='tail -f ~/network-monitoring/logs/network-monitor-$(date +%Y-%m-%d).log'
alias alertlog='tail -f ~/network-monitoring/logs/device-alerts-$(date +%Y-%m-%d).log'  
alias netlogs='ls -la ~/network-monitoring/logs/'
```

## 🛠️ Troubleshooting

### SSH Connection Issues
- Verify Pangolin tunnel is active: `docker logs newt`
- Check SSH daemon status: `sudo systemctl status ssh`
- Monitor connection attempts: `sudo journalctl -u ssh -f`

### Network Monitoring Issues
- Test network connectivity: `ping 8.8.8.8`
- Verify script permissions: `ls -la scripts/`
- Check cron job logs: `grep network-monitoring /var/log/syslog`

### Firewall Issues
- Verify VPN IP: `curl ifconfig.me`
- Test external firewall: Try SSH from different IP (should fail)
- Check internal firewall: `sudo ufw status`

## 📈 Advanced Usage

### Custom Monitoring
Add your own monitoring scripts to the `scripts/` directory and reference `config/devices.conf` for device lists.

### Integration with Other Tools
- **Grafana**: Import logs for visualization
- **Prometheus**: Export metrics for alerting
- **Home Assistant**: Integrate device presence detection

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

MIT License - feel free to use and modify for your own network monitoring needs.

## 🙏 Acknowledgments

- **Fossorial/Pangolin** - For the excellent tunneling solution
- **OpenSSH** - For robust SSH implementation
- **Docker** - For container networking capabilities

---

**Note**: This setup prioritizes security over convenience. All access requires VPN connection and SSH key authentication. Modify firewall rules and device configurations according to your specific network topology.
