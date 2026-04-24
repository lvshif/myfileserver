# File Server - Easy Installation Guide

## 📦 One-Click Installation Package

The file server has been packaged into a single self-extracting installer that can be easily deployed to any Linux server.

## 🚀 Quick Installation

### Method 1: Copy and Run (Recommended)

```bash
# 1. Copy installer to target server
scp fileserver-installer.sh user@target-server:/tmp/

# 2. SSH to target server
ssh user@target-server

# 3. Run installer (default: /opt/fileserver, port 80, base dir /data)
sudo bash /tmp/fileserver-installer.sh

# Or with custom settings
sudo bash /tmp/fileserver-installer.sh /home/myapp/fileserver 8080 /home/myapp/files
```

### Method 2: Direct Download and Install

If you host the installer on a web server:

```bash
# One-line installation
curl -sSL http://your-server/fileserver-installer.sh | sudo bash

# Or with custom parameters
curl -sSL http://your-server/fileserver-installer.sh | sudo bash -s /custom/path 8080 /data
```

### Method 3: Local Installation

```bash
# Run directly on the same server
cd /jason/script/fileserver
sudo bash fileserver-installer.sh
```

## 📋 Installation Parameters

```bash
bash fileserver-installer.sh [INSTALL_DIR] [PORT] [BASE_DIR]
```

**Parameters:**
- `INSTALL_DIR` - Where to install the application (default: `/opt/fileserver`)
- `PORT` - Port number to run on (default: `80`)
- `BASE_DIR` - Base directory for file management (default: `/data`)

**Examples:**

```bash
# Default installation
sudo bash fileserver-installer.sh

# Custom installation directory and port
sudo bash fileserver-installer.sh /home/fileserver 8080

# Full custom configuration
sudo bash fileserver-installer.sh /opt/myfiles 8080 /mnt/storage
```

## 🎯 What Gets Installed

The installer will:

1. ✅ Check Python 3.6+ installation
2. ✅ Create installation directories
3. ✅ Extract and configure fileserver.py
4. ✅ Create management scripts (start.sh, stop.sh, restart.sh, status.sh)
5. ✅ Create systemd service (if available)
6. ✅ Configure firewall (if running as root)
7. ✅ Generate README with instructions

## 📁 Installed Files

After installation, you'll have:

```
/opt/fileserver/              # (or your custom directory)
├── fileserver.py             # Main application
├── start.sh                  # Start the server
├── stop.sh                   # Stop the server
├── restart.sh                # Restart the server
├── status.sh                 # Check server status
├── fileserver.log            # Log file (created after first run)
└── README.txt                # Quick reference guide
```

## 🎮 Managing the Server

### Using Management Scripts

```bash
# Start server
/opt/fileserver/start.sh

# Stop server
/opt/fileserver/stop.sh

# Restart server
/opt/fileserver/restart.sh

# Check status
/opt/fileserver/status.sh
```

### Using Systemd (if installed)

```bash
# Enable auto-start on boot
sudo systemctl enable fileserver

# Start server
sudo systemctl start fileserver

# Stop server
sudo systemctl stop fileserver

# Restart server
sudo systemctl restart fileserver

# Check status
sudo systemctl status fileserver

# View logs
sudo journalctl -u fileserver -f
```

## 🌐 Accessing the File Server

After installation:

```
Local access:  http://localhost:PORT/
Remote access: http://YOUR_SERVER_IP:PORT/
```

Replace `PORT` with your configured port (default: 80)
Replace `YOUR_SERVER_IP` with your server's IP address

## 🔧 Configuration

### Change Base Directory

Edit the installed fileserver.py:

```bash
nano /opt/fileserver/fileserver.py

# Find and modify:
BASE_DIR = "/data"  # Change to your desired directory
```

Then restart the server:

```bash
/opt/fileserver/restart.sh
```

### Change Port

Re-run the installer with a different port, or edit the start script:

```bash
nano /opt/fileserver/start.sh

# Change the port number in the command
```

## 🗑️ Uninstallation

```bash
# 1. Stop the server
/opt/fileserver/stop.sh

# Or if using systemd
sudo systemctl stop fileserver
sudo systemctl disable fileserver

# 2. Remove systemd service (if exists)
sudo rm /etc/systemd/system/fileserver.service
sudo systemctl daemon-reload

# 3. Remove installation directory
sudo rm -rf /opt/fileserver

# 4. (Optional) Remove base directory
sudo rm -rf /data  # Or your custom base directory
```

## 📝 Requirements

- **OS**: Linux (Ubuntu, Debian, CentOS, RHEL, etc.)
- **Python**: 3.6 or higher
- **Privileges**: 
  - Root/sudo for ports < 1024
  - Regular user for ports >= 1024
- **Disk Space**: ~100MB for installation

## 🔒 Security Notes

1. **Port < 1024**: Requires root privileges
2. **Firewall**: Installer attempts to configure firewall automatically
3. **Base Directory**: Ensure proper permissions on the base directory
4. **Network**: The server listens on all interfaces (0.0.0.0)

## 🆘 Troubleshooting

### Python Not Found

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install python3

# CentOS/RHEL
sudo yum install python3
```

### Port Already in Use

```bash
# Check what's using the port
sudo lsof -i :80

# Use a different port
sudo bash fileserver-installer.sh /opt/fileserver 8080
```

### Permission Denied

```bash
# Ensure you're using sudo for ports < 1024
sudo bash fileserver-installer.sh

# Or use a port >= 1024 without sudo
bash fileserver-installer.sh /home/user/fileserver 8080
```

### Server Won't Start

```bash
# Check logs
cat /opt/fileserver/fileserver.log

# Check if Python is working
python3 --version

# Check if port is available
sudo netstat -tlnp | grep :80
```

## 📚 Additional Resources

- **README.txt**: Located in installation directory after installation
- **Logs**: Check `/opt/fileserver/fileserver.log`
- **Status**: Run `/opt/fileserver/status.sh`

## 🎉 Quick Start Example

Complete installation and startup in 3 commands:

```bash
# 1. Copy installer to server
scp fileserver-installer.sh user@server:/tmp/

# 2. Install
ssh user@server "sudo bash /tmp/fileserver-installer.sh"

# 3. Access
# Open browser: http://server-ip/
```

That's it! Your file server is ready to use! 🚀
