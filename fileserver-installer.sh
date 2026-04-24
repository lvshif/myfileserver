#!/bin/bash
#
# Python HTTP File Server - Self-Extracting Installer
# Generated automatically - Do not edit
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default configuration
DEFAULT_INSTALL_DIR="/opt/fileserver"
DEFAULT_PORT="80"
DEFAULT_BASE_DIR="/data"

# Parse arguments
INSTALL_DIR="${1:-$DEFAULT_INSTALL_DIR}"
PORT="${2:-$DEFAULT_PORT}"
BASE_DIR="${3:-$DEFAULT_BASE_DIR}"

print_header() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║     Python HTTP File Server - Installation Script         ║"
    echo "║                    Version 2.0                             ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }

check_python() {
    print_info "Checking Python installation..."
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed"
        echo "Please install Python 3.6+ first:"
        echo "  Ubuntu/Debian: sudo apt install python3"
        echo "  CentOS/RHEL:   sudo yum install python3"
        exit 1
    fi
    
    PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
    print_success "Found Python $PYTHON_VERSION"
}

create_directories() {
    print_info "Creating directories..."
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$BASE_DIR"
    print_success "Directories created: $INSTALL_DIR, $BASE_DIR"
}

extract_fileserver() {
    print_info "Extracting fileserver.py..."
    
    # Extract embedded fileserver.py
    sed -n '/^__FILESERVER_START__$/,/^__FILESERVER_END__$/p' "$0" | \
        sed '1d;$d' > "$INSTALL_DIR/fileserver.py"
    
    # Update BASE_DIR in fileserver.py
    sed -i "s|BASE_DIR = \"/jason\"|BASE_DIR = \"$BASE_DIR\"|g" "$INSTALL_DIR/fileserver.py"
    
    chmod 644 "$INSTALL_DIR/fileserver.py"
    print_success "fileserver.py installed and configured"
}

create_management_scripts() {
    print_info "Creating management scripts..."
    
    # Start script
    cat > "$INSTALL_DIR/start.sh" << EOF
#!/bin/bash
cd "$INSTALL_DIR"
nohup python3 fileserver.py $PORT > fileserver.log 2>&1 &
echo "✅ File server started on port $PORT"
sleep 1
ps aux | grep fileserver.py | grep -v grep
EOF
    
    # Stop script
    cat > "$INSTALL_DIR/stop.sh" << 'EOF'
#!/bin/bash
pkill -f "python3 fileserver.py"
echo "🛑 File server stopped"
EOF
    
    # Restart script
    cat > "$INSTALL_DIR/restart.sh" << EOF
#!/bin/bash
echo "🔄 Restarting file server..."
pkill -f "python3 fileserver.py"
sleep 2
cd "$INSTALL_DIR"
nohup python3 fileserver.py $PORT > fileserver.log 2>&1 &
echo "✅ File server restarted"
sleep 1
ps aux | grep fileserver.py | grep -v grep
EOF
    
    # Status script
    cat > "$INSTALL_DIR/status.sh" << 'EOF'
#!/bin/bash
echo "📊 File Server Status:"
echo "===================="
if ps aux | grep -v grep | grep "python3 fileserver.py" > /dev/null; then
    echo "✅ Server is RUNNING"
    ps aux | grep "python3 fileserver.py" | grep -v grep
    echo ""
    echo "Logs (last 10 lines):"
    tail -n 10 "$INSTALL_DIR/fileserver.log" 2>/dev/null || echo "No logs yet"
else
    echo "❌ Server is NOT running"
fi
EOF
    
    chmod +x "$INSTALL_DIR"/*.sh
    print_success "Management scripts created"
}

create_systemd_service() {
    if command -v systemctl &> /dev/null && [[ $EUID -eq 0 ]]; then
        print_info "Creating systemd service..."
        
        cat > /etc/systemd/system/fileserver.service << EOF
[Unit]
Description=Python HTTP File Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=/usr/bin/python3 $INSTALL_DIR/fileserver.py $PORT
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
        
        systemctl daemon-reload
        print_success "Systemd service created"
        print_info "Enable with: sudo systemctl enable fileserver"
        print_info "Start with:  sudo systemctl start fileserver"
    fi
}

configure_firewall() {
    if [[ $EUID -ne 0 ]]; then
        return
    fi
    
    print_info "Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        ufw allow $PORT/tcp 2>/dev/null && print_success "UFW configured" || true
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=$PORT/tcp 2>/dev/null && \
        firewall-cmd --reload 2>/dev/null && \
        print_success "Firewalld configured" || true
    fi
}

print_summary() {
    SERVER_IP=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "YOUR_SERVER_IP")
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           Installation Completed Successfully!            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Installation Details:${NC}"
    echo "  📁 Install Directory: $INSTALL_DIR"
    echo "  📂 Base Directory:    $BASE_DIR"
    echo "  🔌 Port:              $PORT"
    echo ""
    echo -e "${BLUE}Quick Commands:${NC}"
    echo "  Start:   $INSTALL_DIR/start.sh"
    echo "  Stop:    $INSTALL_DIR/stop.sh"
    echo "  Restart: $INSTALL_DIR/restart.sh"
    echo "  Status:  $INSTALL_DIR/status.sh"
    echo ""
    echo -e "${BLUE}Access URL:${NC}"
    echo "  Local:  http://localhost:$PORT/"
    echo "  Remote: http://$SERVER_IP:$PORT/"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "  1. Start the server: $INSTALL_DIR/start.sh"
    echo "  2. Open browser: http://$SERVER_IP:$PORT/"
    echo "  3. (Optional) Auto-start: sudo systemctl enable fileserver && sudo systemctl start fileserver"
    echo ""
}

# Main installation
main() {
    print_header
    
    echo "Installation Configuration:"
    echo "  Install Directory: $INSTALL_DIR"
    echo "  Base Directory:    $BASE_DIR"
    echo "  Port:              $PORT"
    echo ""
    
    if [[ ! -t 0 ]]; then
        # Non-interactive mode (piped from curl)
        echo "Running in non-interactive mode..."
    else
        read -p "Continue with installation? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_warning "Installation cancelled"
            exit 0
        fi
    fi
    
    check_python
    create_directories
    extract_fileserver
    create_management_scripts
    create_systemd_service
    configure_firewall
    print_summary
}

main

exit 0

__FILESERVER_START__
#!/usr/bin/env python3
"""
简单的文件服务器，支持文件浏览、上传和下载
"""

import os
import html
from http.server import HTTPServer, SimpleHTTPRequestHandler, ThreadingHTTPServer
import cgi
import urllib.parse
from pathlib import Path
from socketserver import ThreadingMixIn

BASE_DIR = "/jason"

class FileServerHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=BASE_DIR, **kwargs)
    
    def translate_path(self, path):
        """Translate URL path to filesystem path"""
        # Remove query string
        path = path.split('?', 1)[0]
        path = path.split('#', 1)[0]
        
        # Normalize path
        path = path.rstrip('/')
        
        # Handle root path
        if path == '' or path == '/':
            return BASE_DIR
        
        # Remove leading slash and join with base directory
        if path.startswith('/'):
            path = path[1:]
        
        # Build full path
        path = os.path.join(BASE_DIR, path)
        
        # Ensure path is within base directory
        path = os.path.abspath(path)
        if not path.startswith(BASE_DIR):
            return BASE_DIR
        
        return path
    
    def do_GET(self):
        """Handle GET requests, including directory browsing and API"""
        from urllib.parse import urlparse, parse_qs
        parsed = urlparse(self.path)
        query_params = parse_qs(parsed.query)
        action = query_params.get('action', [None])[0]
        
        # Handle directory listing API request
        if action == 'listdirs':
            try:
                import json
                dirs = []
                
                def scan_dirs(base_path, prefix=''):
                    try:
                        for item in os.listdir(base_path):
                            item_path = os.path.join(base_path, item)
                            if os.path.isdir(item_path) and not item.startswith('.'):
                                rel_path = os.path.join(prefix, item) if prefix else item
                                dirs.append({
                                    'path': rel_path,
                                    'display': '/' + rel_path
                                })
                                # Recursively scan subdirectories
                                scan_dirs(item_path, rel_path)
                    except PermissionError:
                        pass
                
                scan_dirs(BASE_DIR)
                
                self.send_response(200)
                self.send_header("Content-type", "application/json; charset=utf-8")
                self.end_headers()
                self.wfile.write(json.dumps(dirs).encode('utf-8'))
                return
            except Exception as e:
                self.send_error(500, f"Failed to get directory list: {str(e)}")
                return
        
        # Handle directory browsing requests
        path = self.translate_path(self.path)
        
        if os.path.isdir(path):
            # It's a directory, generate directory listing
            return self.list_directory(path)
        else:
            # It's a file, use default file serving
            return super().do_GET()
    
    def list_directory(self, path):
        """生成目录列表页面，包含上传功能"""
        try:
            file_list = os.listdir(path)
        except OSError:
            self.send_error(404, "无法读取目录")
            return None
        
        file_list.sort(key=lambda a: a.lower())
        
        # 获取相对路径
        rel_path = os.path.relpath(path, BASE_DIR)
        if rel_path == '.':
            rel_path = ''
        
        # 生成HTML
        html_content = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>文件浏览 - /{rel_path}</title>
    <style>
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        body {{
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }}
        .container {{
            max-width: calc(100% - 340px);
            margin: 0 0 0 20px;
            background: white;
            border-radius: 10px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            overflow: hidden;
        }}
        @media (max-width: 1024px) {{
            .container {{
                max-width: 100%;
                margin: 0 auto;
            }}
        }}
        .header {{
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
        }}
        .header h1 {{
            font-size: 28px;
            margin-bottom: 10px;
        }}
        .path {{
            font-size: 14px;
            opacity: 0.9;
            word-break: break-all;
        }}
        .upload-section {{
            position: fixed;
            right: 20px;
            top: 100px;
            width: 280px;
            z-index: 999;
            background: white;
            border-radius: 10px;
            box-shadow: 0 4px 20px rgba(0,0,0,0.15);
            padding: 15px;
        }}
        .upload-box {{
            border: 2px dashed #667eea;
            border-radius: 8px;
            padding: 15px;
            text-align: center;
            background: white;
            transition: all 0.3s;
        }}
        .upload-box:hover {{
            border-color: #764ba2;
            background: #f8f9ff;
        }}
        .upload-box.dragover {{
            border-color: #4CAF50;
            background: #e8f5e9;
        }}
        .upload-title {{
            font-size: 16px;
            font-weight: 600;
            color: #333;
            margin-bottom: 15px;
            display: flex;
            align-items: center;
            gap: 8px;
        }}
        @media (max-width: 1024px) {{
            .upload-section {{
                position: static;
                width: 100%;
                margin-bottom: 20px;
                right: auto;
                top: auto;
            }}
        }}
        .file-input-wrapper {{
            position: relative;
            display: inline-block;
            margin: 10px;
        }}
        .file-input {{
            display: none;
        }}
        .file-input-label {{
            display: inline-block;
            padding: 12px 30px;
            background: #667eea;
            color: white;
            border-radius: 5px;
            cursor: pointer;
            transition: all 0.3s;
            font-weight: 500;
        }}
        .file-input-label:hover {{
            background: #764ba2;
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
        }}
        .upload-btn {{
            padding: 12px 30px;
            background: #4CAF50;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
            font-weight: 500;
            transition: all 0.3s;
        }}
        .upload-btn:hover {{
            background: #45a049;
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(76, 175, 80, 0.4);
        }}
        .upload-btn:disabled {{
            background: #ccc;
            cursor: not-allowed;
            transform: none;
        }}
        .file-list {{
            padding: 30px;
        }}
        .file-table {{
            width: 100%;
            border-collapse: collapse;
            background: white;
        }}
        .file-table thead {{
            background: #f8f9fa;
            border-bottom: 2px solid #667eea;
        }}
        .file-table th {{
            padding: 12px 15px;
            text-align: left;
            font-weight: 600;
            color: #333;
            font-size: 14px;
        }}
        .file-table td {{
            padding: 8px 15px;
            border-bottom: 1px solid #e9ecef;
        }}
        .file-table tr:hover {{
            background: #f8f9fa;
        }}
        .file-icon {{
            font-size: 20px;
            margin-right: 10px;
        }}
        .file-name {{
            color: #2196F3;
            text-decoration: none;
            font-weight: 500;
            word-break: break-all;
        }}
        .file-name:hover {{
            text-decoration: underline;
        }}
        .file-size {{
            color: #6c757d;
            font-size: 13px;
            white-space: nowrap;
        }}
        .file-actions {{
            display: flex;
            gap: 5px;
            white-space: nowrap;
        }}
        .delete-btn {{
            padding: 6px 12px;
            background: #dc3545;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 12px;
            transition: all 0.3s;
        }}
        .delete-btn:hover {{
            background: #c82333;
            transform: scale(1.05);
        }}
        .move-btn {{
            padding: 6px 12px;
            background: #ffc107;
            color: #333;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 12px;
            transition: all 0.3s;
        }}
        .move-btn:hover {{
            background: #e0a800;
            transform: scale(1.05);
        }}
        .copy-btn {{
            padding: 6px 12px;
            background: #17a2b8;
            color: white;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 12px;
            transition: all 0.3s;
        }}
        .copy-btn:hover {{
            background: #138496;
            transform: scale(1.05);
        }}
        .selected-files {{
            margin-top: 10px;
            padding: 10px;
            background: #f8f9fa;
            border-radius: 5px;
            display: none;
            max-height: 150px;
            overflow-y: auto;
        }}
        .selected-files.show {{
            display: block;
        }}
        .selected-file {{
            padding: 5px 8px;
            background: #e3f2fd;
            margin: 3px 0;
            border-radius: 3px;
            font-size: 11px;
            word-break: break-all;
        }}
        .progress-bar {{
            width: 100%;
            height: 4px;
            background: #e9ecef;
            border-radius: 2px;
            overflow: hidden;
            margin-top: 10px;
            display: none;
        }}
        .progress-bar.show {{
            display: block;
        }}
        .progress-fill {{
            height: 100%;
            background: linear-gradient(90deg, #667eea 0%, #764ba2 100%);
            width: 0%;
            transition: width 0.3s;
        }}
        .action-buttons {{
            display: flex;
            gap: 10px;
            margin-bottom: 20px;
            flex-wrap: wrap;
        }}
        .action-btn {{
            padding: 10px 20px;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 500;
            transition: all 0.3s;
        }}
        .action-btn:hover {{
            background: #764ba2;
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
        }}
        .modal {{
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.6);
            align-items: center;
            justify-content: center;
            padding: 20px;
        }}
        .modal.show {{
            display: flex;
        }}
        .modal-content {{
            background: white;
            padding: 30px;
            border-radius: 12px;
            max-width: 500px;
            width: 90%;
            max-height: 80vh;
            overflow-y: auto;
            box-shadow: 0 10px 40px rgba(0,0,0,0.3);
            animation: modalSlideIn 0.3s ease-out;
            position: relative;
        }}
        @keyframes modalSlideIn {{
            from {{
                transform: translateY(-50px);
                opacity: 0;
            }}
            to {{
                transform: translateY(0);
                opacity: 1;
            }}
        }}
        .modal-header {{
            font-size: 20px;
            font-weight: 600;
            margin-bottom: 20px;
            color: #333;
        }}
        .modal-input {{
            width: 100%;
            padding: 12px;
            border: 2px solid #e9ecef;
            border-radius: 5px;
            font-size: 14px;
            margin-bottom: 20px;
            box-sizing: border-box;
        }}
        .modal-input:focus {{
            outline: none;
            border-color: #667eea;
        }}
        .modal-buttons {{
            display: flex;
            gap: 10px;
            justify-content: flex-end;
        }}
        .modal-btn {{
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 500;
            transition: all 0.3s;
        }}
        .modal-btn-primary {{
            background: #4CAF50;
            color: white;
        }}
        .modal-btn-primary:hover {{
            background: #45a049;
        }}
        .modal-btn-secondary {{
            background: #e9ecef;
            color: #333;
        }}
        .modal-btn-secondary:hover {{
            background: #d3d3d3;
        }}
        .path-browser {{
            max-height: 300px;
            overflow-y: auto;
            border: 1px solid #e9ecef;
            border-radius: 5px;
            margin-bottom: 15px;
            background: #f8f9fa;
        }}
        .path-item {{
            padding: 8px 12px;
            cursor: pointer;
            border-bottom: 1px solid #e9ecef;
            transition: background 0.2s;
        }}
        .path-item:hover {{
            background: #e3f2fd;
        }}
        .path-item.selected {{
            background: #667eea;
            color: white;
        }}
        .current-path {{
            padding: 8px 12px;
            background: #e9ecef;
            border-radius: 5px;
            margin-bottom: 10px;
            font-size: 13px;
            color: #333;
        }}
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📁 File Manager</h1>
            <div class="path">Current Path: /{html.escape(rel_path) if rel_path else 'Root'}</div>
        </div>
        
        <div class="upload-section">
            <div class="upload-title">☁️ Upload Files</div>
            <div class="upload-box" id="uploadBox">
                <form id="uploadForm" enctype="multipart/form-data" method="post">
                    <div style="margin-bottom: 10px;">
                        <input type="file" id="fileInput" name="files" class="file-input" multiple>
                        <label for="fileInput" class="file-input-label" style="width: 100%; display: block; text-align: center; margin: 0;">📄 Select Files</label>
                    </div>
                    <div style="margin-bottom: 10px;">
                        <input type="file" id="folderInput" name="files" class="file-input" webkitdirectory directory multiple>
                        <label for="folderInput" class="file-input-label" style="width: 100%; display: block; text-align: center; margin: 0;">📁 Select Folder</label>
                    </div>
                    <button type="submit" class="upload-btn" id="uploadBtn" disabled style="width: 100%; margin: 0;">⬆️ Start Upload</button>
                    <div style="font-size: 11px; color: #6c757d; margin-top: 8px; text-align: center;">or drag files here</div>
                </form>
                <div class="selected-files" id="selectedFiles"></div>
                <div class="progress-bar" id="progressBar">
                    <div class="progress-fill" id="progressFill"></div>
                </div>
            </div>
        </div>
        
        <div class="file-list">
            <div class="action-buttons">
                <button class="action-btn" onclick="showCreateDirModal()">📁 New Folder</button>
                <button class="action-btn" onclick="showCreateFileModal()">📄 New File</button>
            </div>
            <div class="batch-actions" id="batchActions" style="display: none; margin-bottom: 15px; padding: 10px; background: #e3f2fd; border-radius: 5px;">
                <span style="font-weight: 600;">Selected: <span id="selectedCount">0</span> items</span>
                <button class="action-btn" onclick="batchMove()" style="margin-left: 15px;">Move Selected</button>
                <button class="action-btn" onclick="batchCopy()" style="margin-left: 5px;">Copy Selected</button>
                <button class="action-btn" onclick="batchDelete()" style="margin-left: 5px; background: #dc3545;">Delete Selected</button>
            </div>
            
            <h2 style="margin-bottom: 20px; color: #333;">📂 File List</h2>
            <table class="file-table">
                <thead>
                    <tr>
                        <th style="width: 5%;">
                            <input type="checkbox" id="selectAll" onchange="toggleSelectAll()" style="transform: scale(1.2);">
                        </th>
                        <th style="width: 45%;">Name</th>
                        <th style="width: 15%;">Size</th>
                        <th style="width: 35%;">Actions</th>
                    </tr>
                </thead>
                <tbody>
"""
        
        # Add parent directory link
        if rel_path:
            parent = os.path.dirname(rel_path)
            if parent:
                parent_url = '/' + urllib.parse.quote(parent)
            else:
                parent_url = '/'  # Root directory
            html_content += f"""
                    <tr>
                        <td><input type="checkbox"></td>
                        <td><span class="file-icon">📁</span><a href="{parent_url}" class="file-name">.. (Parent Directory)</a></td>
                        <td class="file-size">-</td>
                        <td></td>
                    </tr>
"""
        
        # 计算目录大小的辅助函数
        def get_dir_size(dir_path):
            total_size = 0
            try:
                for dirpath, dirnames, filenames in os.walk(dir_path):
                    for filename in filenames:
                        filepath = os.path.join(dirpath, filename)
                        try:
                            total_size += os.path.getsize(filepath)
                        except:
                            pass
            except:
                pass
            return total_size
        
        def format_size(size):
            if size < 1024:
                return f"{size} B"
            elif size < 1024 * 1024:
                return f"{size / 1024:.1f} KB"
            elif size < 1024 * 1024 * 1024:
                return f"{size / (1024 * 1024):.1f} MB"
            else:
                return f"{size / (1024 * 1024 * 1024):.2f} GB"
        
        # 列出目录和文件
        for name in file_list:
            fullname = os.path.join(path, name)
            displayname = linkname = name
            
            # 跳过隐藏文件
            if name.startswith('.'):
                continue
            
            if os.path.isdir(fullname):
                displayname = name + "/"
                linkname = name + "/"
                icon = "📁"
                # 计算目录大小
                dir_size = get_dir_size(fullname)
                size_str = format_size(dir_size)
            else:
                icon = "📄"
                size = os.path.getsize(fullname)
                size_str = format_size(size)
            
            url_path = os.path.join(rel_path, linkname) if rel_path else linkname
            url = urllib.parse.quote(url_path)
            
            # 对文件路径进行编码用于删除操作
            delete_path = os.path.join(rel_path, name) if rel_path else name
            delete_path_encoded = urllib.parse.quote(delete_path)
            # 转义单引号和双引号用于JavaScript
            name_escaped = html.escape(name).replace("'", "\\'").replace('"', '&quot;')
            delete_path_js = delete_path.replace("'", "\\'").replace('"', '\\"')
            
            html_content += f"""
                    <tr>
                        <td><input type="checkbox" class="file-checkbox" data-path="{delete_path_js}" data-name="{name_escaped}" onchange="updateSelectedCount()"></td>
                        <td><span class="file-icon">{icon}</span><a href="/{url}" class="file-name">{html.escape(displayname)}</a></td>
                        <td class="file-size">{size_str}</td>
                        <td class="file-actions">
                            <button class="copy-btn" onclick="showCopyModal('{delete_path_js}', '{name_escaped}')">Copy</button>
                            <button class="move-btn" onclick="showMoveModal('{delete_path_js}', '{name_escaped}')">Move</button>
                            <button class="delete-btn" onclick="confirmDelete('{delete_path_js}', '{name_escaped}')">Delete</button>
                        </td>
                    </tr>
"""
        
        html_content += """
                </tbody>
            </table>
        </div>
    </div>
    
    <!-- 创建文件夹模态框 -->
    <div class="modal" id="createDirModal">
        <div class="modal-content">
            <div class="modal-header">📁 New Folder</div>
            <input type="text" id="dirNameInput" class="modal-input" placeholder="Enter folder name">
            <div class="modal-buttons">
                <button class="modal-btn modal-btn-secondary" onclick="closeModal('createDirModal')">Cancel</button>
                <button class="modal-btn modal-btn-primary" onclick="createDirectory()">Create</button>
            </div>
        </div>
    </div>
    
    <!-- 创建文件模态框 -->
    <div class="modal" id="createFileModal">
        <div class="modal-content">
            <div class="modal-header">📄 New File</div>
            <input type="text" id="fileNameInput" class="modal-input" placeholder="Enter file name (e.g., test.txt)">
            <div class="modal-buttons">
                <button class="modal-btn modal-btn-secondary" onclick="closeModal('createFileModal')">Cancel</button>
                <button class="modal-btn modal-btn-primary" onclick="createFile()">Create</button>
            </div>
        </div>
    </div>
    
    <!-- 移动文件/目录模态框 -->
    <div class="modal" id="moveModal">
        <div class="modal-content">
            <div class="modal-header">✂️ Move</div>
            <p style="margin-bottom: 10px; color: #6c757d;">
                Move: <strong id="moveItemName"></strong>
            </p>
            <div class="current-path">
                Current Selection: <strong id="moveCurrentPath">/jason (Root)</strong>
            </div>
            <div class="path-browser" id="movePathBrowser">
                <div class="path-item" onclick="selectMovePath('', '/jason (Root)')">📁 / (Root)</div>
            </div>
            <div class="modal-buttons">
                <button class="modal-btn modal-btn-secondary" onclick="closeModal('moveModal')">Cancel</button>
                <button class="modal-btn modal-btn-primary" onclick="performMove()">Move</button>
            </div>
        </div>
    </div>
    
    <!-- 复制文件/目录模态框 -->
    <div class="modal" id="copyModal">
        <div class="modal-content">
            <div class="modal-header">📋 Copy</div>
            <p style="margin-bottom: 10px; color: #6c757d;">
                Copy: <strong id="copyItemName"></strong>
            </p>
            <div class="current-path">
                Current Selection: <strong id="copyCurrentPath">/jason (Root)</strong>
            </div>
            <div class="path-browser" id="copyPathBrowser">
                <div class="path-item" onclick="selectCopyPath('', '/jason (Root)')">📁 / (Root)</div>
            </div>
            <div class="modal-buttons">
                <button class="modal-btn modal-btn-secondary" onclick="closeModal('copyModal')">Cancel</button>
                <button class="modal-btn modal-btn-primary" onclick="performCopy()">Copy</button>
            </div>
        </div>
    </div>
    
    <script>
        // 获取所有目录结构
        function getAllDirectories() {
            const dirs = [];
            function scanDir(path, prefix = '') {
                try {
                    const xhr = new XMLHttpRequest();
                    xhr.open('GET', path || '/', false);  // 同步请求
                    xhr.send();
                    if (xhr.status === 200) {
                        const parser = new DOMParser();
                        const doc = parser.parseFromString(xhr.responseText, 'text/html');
                        const links = doc.querySelectorAll('a');
                        links.forEach(link => {
                            const href = link.getAttribute('href');
                            if (href && href.endsWith('/') && !href.startsWith('..') && href !== '../') {
                                const dirName = href.replace(/\\/$/, '');
                                const fullPath = prefix ? prefix + '/' + dirName : dirName;
                                dirs.push({path: fullPath, display: fullPath});
                            }
                        });
                    }
                } catch(e) {}
            }
            return dirs;
        }
        
        let selectedMovePath = '';
        let selectedCopyPath = '';
        
        // Multi-select functions
        function updateSelectedCount() {
            const checkboxes = document.querySelectorAll('.file-checkbox:checked');
            const count = checkboxes.length;
            document.getElementById('selectedCount').textContent = count;
            
            // Show/hide batch actions
            const batchActions = document.getElementById('batchActions');
            if (count > 0) {
                batchActions.style.display = 'block';
            } else {
                batchActions.style.display = 'none';
            }
        }
        
        function toggleSelectAll() {
            const selectAll = document.getElementById('selectAll');
            const checkboxes = document.querySelectorAll('.file-checkbox');
            
            checkboxes.forEach(checkbox => {
                checkbox.checked = selectAll.checked;
            });
            
            updateSelectedCount();
        }
        
        function getSelectedItems() {
            const checkboxes = document.querySelectorAll('.file-checkbox:checked');
            const items = [];
            
            checkboxes.forEach(checkbox => {
                items.push({
                    path: checkbox.dataset.path,
                    name: checkbox.dataset.name
                });
            });
            
            return items;
        }
        
        function batchMove() {
            const selectedItems = getSelectedItems();
            if (selectedItems.length === 0) {
                alert('Please select at least one item to move');
                return;
            }
            
            // Store selected items for batch operation
            window.batchMoveItems = selectedItems;
            selectedMovePath = '';
            document.getElementById('moveItemName').textContent = `${selectedItems.length} items`;
            document.getElementById('moveCurrentPath').textContent = '/jason (root directory)';
            loadDirectories('movePathBrowser');
            document.getElementById('moveModal').classList.add('show');
        }
        
        function batchCopy() {
            const selectedItems = getSelectedItems();
            if (selectedItems.length === 0) {
                alert('Please select at least one item to copy');
                return;
            }
            
            // Store selected items for batch operation
            window.batchCopyItems = selectedItems;
            selectedCopyPath = '';
            document.getElementById('copyItemName').textContent = `${selectedItems.length} items`;
            document.getElementById('copyCurrentPath').textContent = '/jason (root directory)';
            loadDirectories('copyPathBrowser');
            document.getElementById('copyModal').classList.add('show');
        }
        
        function batchDelete() {
            const selectedItems = getSelectedItems();
            if (selectedItems.length === 0) {
                alert('Please select at least one item to delete');
                return;
            }
            
            const userInput = prompt(`Are you sure you want to delete ${selectedItems.length} selected items?\\n\\nThis operation cannot be recovered!\\n\\nType 'delete' to confirm:`);
            
            if (userInput === 'delete') {
                performBatchDelete(selectedItems);
            } else if (userInput !== null) {
                alert('Input incorrect, deletion cancelled');
            }
        }
        
        function performBatchDelete(items) {
            const xhr = new XMLHttpRequest();
            xhr.open('POST', '/?action=batchdelete');
            xhr.setRequestHeader('Content-Type', 'application/json');
            
            xhr.onload = function() {
                if (xhr.status === 200) {
                    alert('Batch delete successful!');
                    location.reload();
                } else {
                    alert('Batch delete failed: ' + xhr.responseText);
                }
            };
            
            xhr.onerror = function() {
                alert('Request failed');
            };
            
            xhr.send(JSON.stringify({items: items}));
        }
        
        function selectMovePath(path, display) {
            selectedMovePath = path;
            document.getElementById('moveCurrentPath').textContent = display;
            // 更新选中状态
            document.querySelectorAll('#movePathBrowser .path-item').forEach(item => {
                item.classList.remove('selected');
            });
            event.target.classList.add('selected');
        }
        
        function selectCopyPath(path, display) {
            selectedCopyPath = path;
            document.getElementById('copyCurrentPath').textContent = display;
            // 更新选中状态
            document.querySelectorAll('#copyPathBrowser .path-item').forEach(item => {
                item.classList.remove('selected');
            });
            event.target.classList.add('selected');
        }
        
        const uploadBox = document.getElementById('uploadBox');
        const fileInput = document.getElementById('fileInput');
        const folderInput = document.getElementById('folderInput');
        const uploadForm = document.getElementById('uploadForm');
        const uploadBtn = document.getElementById('uploadBtn');
        const selectedFiles = document.getElementById('selectedFiles');
        const progressBar = document.getElementById('progressBar');
        const progressFill = document.getElementById('progressFill');
        
        // 文件选择
        fileInput.addEventListener('change', function() {
            updateSelectedFiles();
        });
        
        // 文件夹选择
        folderInput.addEventListener('change', function() {
            updateSelectedFiles();
        });
        
        function updateSelectedFiles() {
            const files = fileInput.files;
            const folderFiles = folderInput.files;
            const totalCount = files.length + folderFiles.length;
            
            if (totalCount > 0) {
                uploadBtn.disabled = false;
                selectedFiles.classList.add('show');
                selectedFiles.innerHTML = '<strong>已选择 ' + totalCount + ' 个文件:</strong><br>';
                for (let i = 0; i < files.length; i++) {
                    selectedFiles.innerHTML += '<div class="selected-file">📄 ' + files[i].name + '</div>';
                }
                for (let i = 0; i < folderFiles.length; i++) {
                    selectedFiles.innerHTML += '<div class="selected-file">📁 ' + folderFiles[i].webkitRelativePath + '</div>';
                }
            } else {
                uploadBtn.disabled = true;
                selectedFiles.classList.remove('show');
            }
        }
        
        // 拖拽上传
        uploadBox.addEventListener('dragover', function(e) {
            e.preventDefault();
            uploadBox.classList.add('dragover');
        });
        
        uploadBox.addEventListener('dragleave', function(e) {
            e.preventDefault();
            uploadBox.classList.remove('dragover');
        });
        
        uploadBox.addEventListener('drop', function(e) {
            e.preventDefault();
            uploadBox.classList.remove('dragover');
            fileInput.files = e.dataTransfer.files;
            updateSelectedFiles();
        });
        
        // 表单提交
        uploadForm.addEventListener('submit', function(e) {
            e.preventDefault();
            
            const formData = new FormData();
            const files = fileInput.files;
            const folderFiles = folderInput.files;
            
            for (let i = 0; i < files.length; i++) {
                formData.append('files', files[i]);
            }
            
            for (let i = 0; i < folderFiles.length; i++) {
                formData.append('files', folderFiles[i]);
                formData.append('paths', folderFiles[i].webkitRelativePath || folderFiles[i].name);
            }
            
            uploadBtn.disabled = true;
            uploadBtn.textContent = '⏳ Uploading...';
            progressBar.classList.add('show');
            
            const xhr = new XMLHttpRequest();
            
            xhr.upload.addEventListener('progress', function(e) {
                if (e.lengthComputable) {
                    const percent = (e.loaded / e.total) * 100;
                    progressFill.style.width = percent + '%';
                }
            });
            
            xhr.addEventListener('load', function() {
                if (xhr.status === 200) {
                    alert('✅ Upload successful!');
                    location.reload();
                } else {
                    alert('❌ Upload failed: ' + xhr.responseText);
                    uploadBtn.disabled = false;
                    uploadBtn.textContent = '⬆️ Upload';
                }
                progressBar.classList.remove('show');
                progressFill.style.width = '0%';
            });
            
            xhr.addEventListener('error', function() {
                alert('❌ Upload error');
                uploadBtn.disabled = false;
                uploadBtn.textContent = '⬆️ Upload';
                progressBar.classList.remove('show');
                progressFill.style.width = '0%';
            });
            
            xhr.open('POST', window.location.pathname);
            xhr.send(formData);
        });
        
        // 模态框函数
        function showCreateDirModal() {
            document.getElementById('createDirModal').classList.add('show');
            document.getElementById('dirNameInput').value = '';
            document.getElementById('dirNameInput').focus();
        }
        
        function showCreateFileModal() {
            document.getElementById('createFileModal').classList.add('show');
            document.getElementById('fileNameInput').value = '';
            document.getElementById('fileNameInput').focus();
        }
        
        function closeModal(modalId) {
            document.getElementById(modalId).classList.remove('show');
        }
        
        // 点击模态框外部关闭
        window.onclick = function(event) {
            if (event.target.classList.contains('modal')) {
                event.target.classList.remove('show');
            }
        }
        
        // 创建文件夹
        function createDirectory() {
            const dirName = document.getElementById('dirNameInput').value.trim();
            if (!dirName) {
                alert('Please enter folder name');
                return;
            }
            
            const xhr = new XMLHttpRequest();
            xhr.open('POST', window.location.pathname + '?action=mkdir');
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
            
            xhr.onload = function() {
                if (xhr.status === 200) {
                    alert('✅ Folder created successfully!');
                    location.reload();
                } else {
                    alert('❌ Creation failed: ' + xhr.responseText);
                }
            };
            
            xhr.onerror = function() {
                alert('❌ Request failed');
            };
            
            xhr.send('name=' + encodeURIComponent(dirName));
        }
        
        // 创建文件
        function createFile() {
            const fileName = document.getElementById('fileNameInput').value.trim();
            if (!fileName) {
                alert('Please enter file name');
                return;
            }
            
            const xhr = new XMLHttpRequest();
            xhr.open('POST', window.location.pathname + '?action=touch');
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
            
            xhr.onload = function() {
                if (xhr.status === 200) {
                    alert('✅ File created successfully!');
                    location.reload();
                } else {
                    alert('❌ Creation failed: ' + xhr.responseText);
                }
            };
            
            xhr.onerror = function() {
                alert('❌ Request failed');
            };
            
            xhr.send('name=' + encodeURIComponent(fileName));
        }
        
        // 回车键提交
        document.getElementById('dirNameInput').addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                createDirectory();
            }
        });
        
        document.getElementById('fileNameInput').addEventListener('keypress', function(e) {
            if (e.key === 'Enter') {
                createFile();
            }
        });
        
        // 删除功能 - 输入delete确认
        function confirmDelete(path, name) {
            const userInput = prompt('Are you sure you want to delete "' + name + '"?\\n\\nThis operation cannot be undone!\\n\\nType "delete" to confirm:');
            
            if (userInput === 'delete') {
                performDelete(path, name);
            } else if (userInput !== null) {
                alert('Incorrect input, deletion cancelled');
            }
        }
        
        function performDelete(path, name) {
            const xhr = new XMLHttpRequest();
            xhr.open('POST', '/?action=delete');
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
            
            xhr.onload = function() {
                if (xhr.status === 200) {
                    alert('Deleted successfully!');
                    location.reload();
                } else {
                    alert('Delete failed: ' + xhr.responseText);
                }
            };
            
            xhr.onerror = function() {
                alert('Request failed');
            };
            
            xhr.send('path=' + encodeURIComponent(path));
        }
        
        // 移动功能
        let currentMovePath = '';
        
        function loadDirectories(browserId) {
            const xhr = new XMLHttpRequest();
            xhr.open('GET', '/?action=listdirs', false);
            xhr.send();
            if (xhr.status === 200) {
                const dirs = JSON.parse(xhr.responseText);
                const browser = document.getElementById(browserId);
                browser.innerHTML = '<div class="path-item" onclick="select' + (browserId.includes('move') ? 'Move' : 'Copy') + 'Path(\\'\\', \\'/jason (Root)\\')">📁 / (Root)</div>';
                dirs.forEach(dir => {
                    browser.innerHTML += '<div class="path-item" onclick="select' + (browserId.includes('move') ? 'Move' : 'Copy') + 'Path(\\'' + dir.path + '\\', \\'' + dir.display + '\\')">📁 ' + dir.display + '</div>';
                });
            }
        }
        
        function showMoveModal(path, name) {
            currentMovePath = path;
            selectedMovePath = '';
            document.getElementById('moveItemName').textContent = name;
            document.getElementById('moveCurrentPath').textContent = '/jason (Root)';
            loadDirectories('movePathBrowser');
            document.getElementById('moveModal').classList.add('show');
        }
        
        function performMove() {
            // Check if this is a batch operation
            if (window.batchMoveItems && window.batchMoveItems.length > 0) {
                // Batch move
                const xhr = new XMLHttpRequest();
                xhr.open('POST', '/?action=batchmove');
                xhr.setRequestHeader('Content-Type', 'application/json');
                
                xhr.onload = function() {
                    if (xhr.status === 200) {
                        alert('Batch move successful!');
                        location.reload();
                    } else {
                        alert('Batch move failed: ' + xhr.responseText);
                    }
                };
                
                xhr.onerror = function() {
                    alert('Request failed');
                };
                
                xhr.send(JSON.stringify({
                    items: window.batchMoveItems,
                    target: selectedMovePath
                }));
            } else {
                // Single item move
                const xhr = new XMLHttpRequest();
                xhr.open('POST', '/?action=move');
                xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
                
                xhr.onload = function() {
                    if (xhr.status === 200) {
                        alert('Move successful!');
                        location.reload();
                    } else {
                        alert('Move failed: ' + xhr.responseText);
                    }
                };
                
                xhr.onerror = function() {
                    alert('Request failed');
                };
                
                xhr.send('source=' + encodeURIComponent(currentMovePath) + '&target=' + encodeURIComponent(selectedMovePath));
            }
        }
        
        // 复制功能
        let currentCopyPath = '';
        
        function showCopyModal(path, name) {
            currentCopyPath = path;
            selectedCopyPath = '';
            document.getElementById('copyItemName').textContent = name;
            document.getElementById('copyCurrentPath').textContent = '/jason (Root)';
            loadDirectories('copyPathBrowser');
            document.getElementById('copyModal').classList.add('show');
        }
        
        function performCopy() {
            // Check if this is a batch operation
            if (window.batchCopyItems && window.batchCopyItems.length > 0) {
                // Batch copy
                const xhr = new XMLHttpRequest();
                xhr.open('POST', '/?action=batchcopy');
                xhr.setRequestHeader('Content-Type', 'application/json');
                
                xhr.onload = function() {
                    if (xhr.status === 200) {
                        alert('Batch copy successful!');
                        location.reload();
                    } else {
                        alert('Batch copy failed: ' + xhr.responseText);
                    }
                };
                
                xhr.onerror = function() {
                    alert('Request failed');
                };
                
                xhr.send(JSON.stringify({
                    items: window.batchCopyItems,
                    target: selectedCopyPath
                }));
            } else {
                // Single item copy
                const xhr = new XMLHttpRequest();
                xhr.open('POST', '/?action=copy');
                xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
                
                xhr.onload = function() {
                    if (xhr.status === 200) {
                        alert('Copy successful!');
                        location.reload();
                    } else {
                        alert('Copy failed: ' + xhr.responseText);
                    }
                };
                
                xhr.onerror = function() {
                    alert('Request failed');
                };
                
                xhr.send('source=' + encodeURIComponent(currentCopyPath) + '&target=' + encodeURIComponent(selectedCopyPath));
            }
        }
    </script>
</body>
</html>
"""
        
        encoded = html_content.encode('utf-8')
        self.send_response(200)
        self.send_header("Content-type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(encoded)))
        self.end_headers()
        self.wfile.write(encoded)
        return None
    
    def do_POST(self):
        """处理文件上传、创建目录和创建文件"""
        # 解析URL参数
        from urllib.parse import urlparse, parse_qs
        parsed = urlparse(self.path)
        query_params = parse_qs(parsed.query)
        action = query_params.get('action', [None])[0]
        
        # 获取当前目录
        path = self.translate_path(parsed.path)
        
        # 处理创建目录
        if action == 'mkdir':
            try:
                content_length = int(self.headers.get('Content-Length', 0))
                post_data = self.rfile.read(content_length).decode('utf-8')
                params = parse_qs(post_data)
                dir_name = params.get('name', [''])[0]
                
                if not dir_name:
                    self.send_error(400, "目录名不能为空")
                    return
                
                # 安全检查：防止路径遍历攻击
                if '..' in dir_name or '/' in dir_name or '\\' in dir_name:
                    self.send_error(400, "目录名包含非法字符")
                    return
                
                new_dir = os.path.join(path, dir_name)
                os.makedirs(new_dir, exist_ok=False)
                
                self.send_response(200)
                self.send_header("Content-type", "text/plain; charset=utf-8")
                self.end_headers()
                self.wfile.write(f"成功创建目录: {dir_name}".encode('utf-8'))
                return
                
            except FileExistsError:
                self.send_error(400, "目录已存在")
                return
            except Exception as e:
                self.send_error(500, f"创建目录失败: {str(e)}")
                return
        
        # 处理删除文件或目录
        if action == 'delete':
            try:
                content_length = int(self.headers.get('Content-Length', 0))
                post_data = self.rfile.read(content_length).decode('utf-8')
                params = parse_qs(post_data)
                delete_path = params.get('path', [''])[0]
                
                if not delete_path:
                    self.send_error(400, "路径不能为空")
                    return
                
                # 构建完整路径
                full_path = os.path.join(BASE_DIR, delete_path.lstrip('/'))
                
                # 安全检查：确保路径在BASE_DIR内
                real_path = os.path.realpath(full_path)
                real_base = os.path.realpath(BASE_DIR)
                if not real_path.startswith(real_base):
                    self.send_error(403, "禁止访问此路径")
                    return
                
                if not os.path.exists(full_path):
                    self.send_error(404, "文件或目录不存在")
                    return
                
                # 删除文件或目录
                if os.path.isdir(full_path):
                    import shutil
                    shutil.rmtree(full_path)
                    msg = "目录"
                else:
                    os.remove(full_path)
                    msg = "文件"
                
                self.send_response(200)
                self.send_header("Content-type", "text/plain; charset=utf-8")
                self.end_headers()
                self.wfile.write(f"成功删除{msg}".encode('utf-8'))
                return
                
            except PermissionError:
                self.send_error(403, "没有权限删除此文件或目录")
                return
            except Exception as e:
                self.send_error(500, f"删除失败: {str(e)}")
                return
        
        # 处理移动文件或目录
        if action == 'move':
            try:
                import shutil
                content_length = int(self.headers.get('Content-Length', 0))
                post_data = self.rfile.read(content_length).decode('utf-8')
                params = parse_qs(post_data)
                source_path = params.get('source', [''])[0]
                target_path = params.get('target', [''])[0]
                
                if not source_path:
                    self.send_error(400, "源路径不能为空")
                    return
                
                # 构建完整路径
                source_full = os.path.join(BASE_DIR, source_path.lstrip('/'))
                
                # 处理目标路径
                if target_path:
                    target_full = os.path.join(BASE_DIR, target_path.lstrip('/'))
                else:
                    target_full = BASE_DIR
                
                # 安全检查
                real_source = os.path.realpath(source_full)
                real_target = os.path.realpath(target_full)
                real_base = os.path.realpath(BASE_DIR)
                
                if not real_source.startswith(real_base) or not real_target.startswith(real_base):
                    self.send_error(403, "禁止访问此路径")
                    return
                
                if not os.path.exists(source_full):
                    self.send_error(404, "源文件或目录不存在")
                    return
                
                # 如果目标是目录，将源文件/目录移动到该目录下
                if os.path.isdir(target_full):
                    target_full = os.path.join(target_full, os.path.basename(source_full))
                
                if os.path.exists(target_full):
                    self.send_error(400, "目标位置已存在同名文件或目录")
                    return
                
                # 执行移动
                shutil.move(source_full, target_full)
                
                self.send_response(200)
                self.send_header("Content-type", "text/plain; charset=utf-8")
                self.end_headers()
                self.wfile.write("移动成功".encode('utf-8'))
                return
                
            except Exception as e:
                self.send_error(500, f"移动失败: {str(e)}")
                return
        
        # 处理复制文件或目录
        if action == 'copy':
            try:
                import shutil
                content_length = int(self.headers.get('Content-Length', 0))
                post_data = self.rfile.read(content_length).decode('utf-8')
                params = parse_qs(post_data)
                source_path = params.get('source', [''])[0]
                target_path = params.get('target', [''])[0]
                
                if not source_path:
                    self.send_error(400, "源路径不能为空")
                    return
                
                # 构建完整路径
                source_full = os.path.join(BASE_DIR, source_path.lstrip('/'))
                
                # 处理目标路径
                if target_path:
                    target_full = os.path.join(BASE_DIR, target_path.lstrip('/'))
                else:
                    target_full = BASE_DIR
                
                # 安全检查
                real_source = os.path.realpath(source_full)
                real_target = os.path.realpath(target_full)
                real_base = os.path.realpath(BASE_DIR)
                
                if not real_source.startswith(real_base) or not real_target.startswith(real_base):
                    self.send_error(403, "禁止访问此路径")
                    return
                
                if not os.path.exists(source_full):
                    self.send_error(404, "源文件或目录不存在")
                    return
                
                # 如果目标是目录，将源文件/目录复制到该目录下
                if os.path.isdir(target_full):
                    target_full = os.path.join(target_full, os.path.basename(source_full))
                
                if os.path.exists(target_full):
                    self.send_error(400, "目标位置已存在同名文件或目录")
                    return
                
                # 执行复制
                if os.path.isdir(source_full):
                    shutil.copytree(source_full, target_full)
                else:
                    shutil.copy2(source_full, target_full)
                
                self.send_response(200)
                self.send_header("Content-type", "text/plain; charset=utf-8")
                self.end_headers()
                self.wfile.write("复制成功".encode('utf-8'))
                return
                
            except Exception as e:
                self.send_error(500, f"复制失败: {str(e)}")
                return
        
        # 处理创建文件
        if action == 'touch':
            try:
                content_length = int(self.headers.get('Content-Length', 0))
                post_data = self.rfile.read(content_length).decode('utf-8')
                params = parse_qs(post_data)
                file_name = params.get('name', [''])[0]
                
                if not file_name:
                    self.send_error(400, "文件名不能为空")
                    return
                
                # 安全检查：防止路径遍历攻击
                if '..' in file_name or '/' in file_name or '\\' in file_name:
                    self.send_error(400, "文件名包含非法字符")
                    return
                
                new_file = os.path.join(path, file_name)
                
                if os.path.exists(new_file):
                    self.send_error(400, "文件已存在")
                    return
                
                # 创建空文件
                with open(new_file, 'w') as f:
                    pass
                
                self.send_response(200)
                self.send_header("Content-type", "text/plain; charset=utf-8")
                self.end_headers()
                self.wfile.write(f"成功创建文件: {file_name}".encode('utf-8'))
                return
                
            except Exception as e:
                self.send_error(500, f"创建文件失败: {str(e)}")
                return
        
        # 处理批量删除
        if action == 'batchdelete':
            try:
                content_length = int(self.headers.get('Content-Length', 0))
                post_data = self.rfile.read(content_length).decode('utf-8')
                import json
                data = json.loads(post_data)
                items = data.get('items', [])
                
                deleted_count = 0
                for item in items:
                    item_path = item.get('path', '')
                    if not item_path:
                        continue
                    
                    # 构建完整路径
                    full_path = os.path.join(BASE_DIR, item_path.lstrip('/'))
                    
                    # 安全检查
                    real_path = os.path.realpath(full_path)
                    real_base = os.path.realpath(BASE_DIR)
                    if not real_path.startswith(real_base):
                        continue
                    
                    if os.path.exists(full_path):
                        if os.path.isdir(full_path):
                            import shutil
                            shutil.rmtree(full_path)
                        else:
                            os.remove(full_path)
                        deleted_count += 1
                
                self.send_response(200)
                self.send_header("Content-type", "text/plain; charset=utf-8")
                self.end_headers()
                self.wfile.write(f"成功删除 {deleted_count} 个文件".encode('utf-8'))
                return
                
            except Exception as e:
                self.send_error(500, f"批量删除失败: {str(e)}")
                return
        
        # 处理批量移动
        if action == 'batchmove':
            try:
                import shutil
                content_length = int(self.headers.get('Content-Length', 0))
                post_data = self.rfile.read(content_length).decode('utf-8')
                import json
                data = json.loads(post_data)
                items = data.get('items', [])
                target_path = data.get('target', '')
                
                moved_count = 0
                
                # 构建目标目录
                if target_path:
                    target_full = os.path.join(BASE_DIR, target_path.lstrip('/'))
                else:
                    target_full = BASE_DIR
                
                # 安全检查
                real_target = os.path.realpath(target_full)
                real_base = os.path.realpath(BASE_DIR)
                if not real_target.startswith(real_base):
                    self.send_error(403, "目标路径无效")
                    return
                
                for item in items:
                    item_path = item.get('path', '')
                    if not item_path:
                        continue
                    
                    # 构建源路径
                    source_full = os.path.join(BASE_DIR, item_path.lstrip('/'))
                    
                    # 安全检查
                    real_source = os.path.realpath(source_full)
                    if not real_source.startswith(real_base):
                        continue
                    
                    if os.path.exists(source_full):
                        # 确定最终目标路径
                        item_name = os.path.basename(source_full)
                        final_target = os.path.join(target_full, item_name)
                        
                        if os.path.exists(final_target):
                            continue  # 跳过目标已存在的情况
                        
                        shutil.move(source_full, final_target)
                        moved_count += 1
                
                self.send_response(200)
                self.send_header("Content-type", "text/plain; charset=utf-8")
                self.end_headers()
                self.wfile.write(f"成功移动 {moved_count} 个文件".encode('utf-8'))
                return
                
            except Exception as e:
                self.send_error(500, f"批量移动失败: {str(e)}")
                return
        
        # 处理批量复制
        if action == 'batchcopy':
            try:
                import shutil
                content_length = int(self.headers.get('Content-Length', 0))
                post_data = self.rfile.read(content_length).decode('utf-8')
                import json
                data = json.loads(post_data)
                items = data.get('items', [])
                target_path = data.get('target', '')
                
                copied_count = 0
                
                # 构建目标目录
                if target_path:
                    target_full = os.path.join(BASE_DIR, target_path.lstrip('/'))
                else:
                    target_full = BASE_DIR
                
                # 安全检查
                real_target = os.path.realpath(target_full)
                real_base = os.path.realpath(BASE_DIR)
                if not real_target.startswith(real_base):
                    self.send_error(403, "目标路径无效")
                    return
                
                for item in items:
                    item_path = item.get('path', '')
                    if not item_path:
                        continue
                    
                    # 构建源路径
                    source_full = os.path.join(BASE_DIR, item_path.lstrip('/'))
                    
                    # 安全检查
                    real_source = os.path.realpath(source_full)
                    if not real_source.startswith(real_base):
                        continue
                    
                    if os.path.exists(source_full):
                        # 确定最终目标路径
                        item_name = os.path.basename(source_full)
                        final_target = os.path.join(target_full, item_name)
                        
                        if os.path.exists(final_target):
                            continue  # 跳过目标已存在的情况
                        
                        if os.path.isdir(source_full):
                            shutil.copytree(source_full, final_target)
                        else:
                            shutil.copy2(source_full, final_target)
                        copied_count += 1
                
                self.send_response(200)
                self.send_header("Content-type", "text/plain; charset=utf-8")
                self.end_headers()
                self.wfile.write(f"成功复制 {copied_count} 个文件".encode('utf-8'))
                return
                
            except Exception as e:
                self.send_error(500, f"批量复制失败: {str(e)}")
                return
        
        # 处理文件上传
        content_type = self.headers.get('Content-Type')
        
        if not content_type or not content_type.startswith('multipart/form-data'):
            self.send_error(400, "需要 multipart/form-data")
            return
        
        try:
            # 使用cgi.FieldStorage但优化读取方式
            form = cgi.FieldStorage(
                fp=self.rfile,
                headers=self.headers,
                environ={
                    'REQUEST_METHOD': 'POST',
                    'CONTENT_TYPE': content_type,
                }
            )
            
            uploaded_count = 0
            
            # 获取路径信息（用于文件夹上传）
            paths = form.getlist('paths') if 'paths' in form else []
            
            if 'files' in form:
                files = form['files']
                if not isinstance(files, list):
                    files = [files]
                
                for idx, file_item in enumerate(files):
                    if file_item.filename:
                        # 如果有相对路径信息（文件夹上传），使用相对路径
                        if idx < len(paths) and paths[idx]:
                            relative_path = paths[idx]
                            # 创建必要的子目录
                            file_dir = os.path.dirname(relative_path)
                            if file_dir:
                                target_dir = os.path.join(path, file_dir)
                                os.makedirs(target_dir, exist_ok=True)
                            filepath = os.path.join(path, relative_path)
                        else:
                            # 普通文件上传
                            filename = os.path.basename(file_item.filename)
                            filepath = os.path.join(path, filename)
                        
                        # 使用流式写入，提高大文件上传速度
                        with open(filepath, 'wb') as f:
                            chunk_size = 8192 * 16  # 128KB chunks
                            while True:
                                chunk = file_item.file.read(chunk_size)
                                if not chunk:
                                    break
                                f.write(chunk)
                        
                        uploaded_count += 1
            
            self.send_response(200)
            self.send_header("Content-type", "text/plain; charset=utf-8")
            self.end_headers()
            self.wfile.write(f"成功上传 {uploaded_count} 个文件".encode('utf-8'))
            
        except Exception as e:
            self.send_error(500, f"上传失败: {str(e)}")

def run_server(port=80):
    server_address = ('', port)
    # 使用ThreadingHTTPServer支持多线程，提高并发性能
    httpd = ThreadingHTTPServer(server_address, FileServerHandler)
    httpd.daemon_threads = True  # 守护线程，主线程退出时自动结束
    print(f"✅ 文件服务器运行在 http://0.0.0.0:{port}")
    print(f"📁 服务目录: {BASE_DIR}")
    print(f"🚀 多线程模式已启用")
    httpd.serve_forever()

if __name__ == '__main__':
    import sys
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 80
    run_server(port)
__FILESERVER_END__
