# File Server - Quick Reference Card

## 🚀 One-Line Installation

```bash
# Copy installer to target server and run
scp fileserver-installer.sh user@server:/tmp/ && ssh user@server "sudo bash /tmp/fileserver-installer.sh"
```

## 📦 What You Need

**Single File**: `fileserver-installer.sh` (73KB)

**That's it!** Everything else is generated automatically.

## 🎯 Installation Modes

### Default Installation
```bash
sudo bash fileserver-installer.sh
```
- Install to: `/opt/fileserver`
- Port: `80`
- Base directory: `/data`

### Custom Installation
```bash
sudo bash fileserver-installer.sh /custom/path 8080 /storage
```
- Install to: `/custom/path`
- Port: `8080`
- Base directory: `/storage`

### No-Sudo Installation (Port >= 1024)
```bash
bash fileserver-installer.sh /home/user/fileserver 8080 /home/user/files
```

## 🎮 Server Management

| Action | Command |
|--------|---------|
| **Start** | `/opt/fileserver/start.sh` |
| **Stop** | `/opt/fileserver/stop.sh` |
| **Restart** | `/opt/fileserver/restart.sh` |
| **Status** | `/opt/fileserver/status.sh` |

## 🔧 Systemd Commands

| Action | Command |
|--------|---------|
| **Enable** | `sudo systemctl enable fileserver` |
| **Start** | `sudo systemctl start fileserver` |
| **Stop** | `sudo systemctl stop fileserver` |
| **Restart** | `sudo systemctl restart fileserver` |
| **Status** | `sudo systemctl status fileserver` |
| **Logs** | `sudo journalctl -u fileserver -f` |

## 🌐 Access URLs

```
Local:  http://localhost/
Remote: http://YOUR_SERVER_IP/
```

## 📁 Installed Structure

```
/opt/fileserver/
├── fileserver.py      # Main application
├── start.sh          # Start server
├── stop.sh           # Stop server
├── restart.sh        # Restart server
├── status.sh         # Check status
├── fileserver.log    # Log file
└── README.txt        # Instructions
```

## 🗑️ Quick Uninstall

```bash
/opt/fileserver/stop.sh
sudo rm -rf /opt/fileserver
sudo rm /etc/systemd/system/fileserver.service
sudo systemctl daemon-reload
```

## 🔥 Common Use Cases

### Deploy to Multiple Servers
```bash
# Create a list of servers
servers="server1 server2 server3"

# Deploy to all
for server in $servers; do
    scp fileserver-installer.sh user@$server:/tmp/
    ssh user@$server "sudo bash /tmp/fileserver-installer.sh"
done
```

### Deploy with Custom Configuration
```bash
# Different port for each server
scp fileserver-installer.sh user@server1:/tmp/
ssh user@server1 "sudo bash /tmp/fileserver-installer.sh /opt/fileserver 8080"

scp fileserver-installer.sh user@server2:/tmp/
ssh user@server2 "sudo bash /tmp/fileserver-installer.sh /opt/fileserver 8081"
```

### Deploy via HTTP
```bash
# Host the installer on a web server, then:
ssh user@target-server
curl -sSL http://your-server/fileserver-installer.sh | sudo bash
```

## 💡 Pro Tips

1. **No Internet Required**: The installer is self-contained
2. **Idempotent**: Safe to run multiple times
3. **Portable**: Works on any Linux with Python 3.6+
4. **Lightweight**: Only 73KB installer file
5. **Zero Dependencies**: Uses only Python standard library

## 🆘 Quick Troubleshooting

| Problem | Solution |
|---------|----------|
| Port in use | `sudo lsof -i :80` then kill process or use different port |
| Permission denied | Use `sudo` or port >= 1024 |
| Python not found | `sudo apt install python3` or `sudo yum install python3` |
| Can't access remotely | Check firewall: `sudo ufw allow 80/tcp` |

## 📊 Features

- ✅ File upload/download
- ✅ Folder upload (with structure)
- ✅ Create files/folders
- ✅ Move/copy/delete (single & batch)
- ✅ Multi-select with checkboxes
- ✅ Directory size display
- ✅ Drag & drop upload
- ✅ Progress bar
- ✅ Modern responsive UI
- ✅ English interface

## 🔗 Quick Links

- **Full Installation Guide**: `INSTALLATION.md`
- **Usage Guide**: `README.md`
- **Troubleshooting**: `TROUBLESHOOTING.md`
- **Deployment Guide**: `deployment_guide.md`

---

**Remember**: Only one file needed: `fileserver-installer.sh` 🎉
