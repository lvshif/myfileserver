================================================================================
                    fileserver-installer.sh 使用说明
================================================================================

📦 这是什么？
------------
一个自解压安装包，包含完整的Python HTTP文件服务器。


🚀 如何使用？
------------

1. 复制到目标服务器
   scp fileserver-installer.sh user@server:/tmp/

2. SSH登录并运行
   ssh user@server
   sudo bash /tmp/fileserver-installer.sh

3. 访问
   http://服务器IP/


⚙️ 自定义安装
-------------

语法：
   bash fileserver-installer.sh [安装目录] [端口] [数据目录]

示例：
   # 默认安装（/opt/fileserver, 端口80, 数据在/data）
   sudo bash fileserver-installer.sh

   # 自定义端口（不需要sudo）
   bash fileserver-installer.sh /home/user/fileserver 8080 /home/user/files

   # 完全自定义
   sudo bash fileserver-installer.sh /opt/myapp 8080 /mnt/storage


📂 安装后的文件
--------------

/opt/fileserver/
├── fileserver.py      主程序
├── start.sh          启动
├── stop.sh           停止
├── restart.sh        重启
├── status.sh         状态
└── fileserver.log    日志


🎮 管理命令
----------

启动：  /opt/fileserver/start.sh
停止：  /opt/fileserver/stop.sh
重启：  /opt/fileserver/restart.sh
状态：  /opt/fileserver/status.sh

或使用systemd：
   sudo systemctl start fileserver
   sudo systemctl stop fileserver
   sudo systemctl status fileserver


🔧 修改配置
----------

修改数据保存目录：
   1. nano /opt/fileserver/fileserver.py
   2. 找到：BASE_DIR = "/data"
   3. 改成：BASE_DIR = "/你的目录"
   4. 保存并重启：/opt/fileserver/restart.sh

修改端口：
   1. nano /opt/fileserver/start.sh
   2. 找到：python3 fileserver.py 80
   3. 改成：python3 fileserver.py 8080
   4. 保存并重启：/opt/fileserver/restart.sh


📋 要求
------

✅ Linux系统
✅ Python 3.6+
✅ 端口<1024需要sudo，>=1024不需要


🆘 常见问题
----------

Q: Python未安装？
A: sudo apt install python3  (Ubuntu/Debian)
   sudo yum install python3  (CentOS/RHEL)

Q: 端口被占用？
A: sudo lsof -i :80  查看占用
   或使用其他端口：bash fileserver-installer.sh /opt/fileserver 8080

Q: 无法远程访问？
A: sudo ufw allow 80/tcp  (Ubuntu)
   sudo firewall-cmd --permanent --add-port=80/tcp  (CentOS)


📞 更多帮助
----------

详细文档：
   START_HERE.txt        - 快速入门
   HOW_TO_DEPLOY.txt     - 部署指南
   INSTALLATION.md       - 完整安装文档
   QUICK_REFERENCE.md    - 命令速查
   TROUBLESHOOTING.md    - 故障排查


================================================================================
                        就这么简单！🎉
================================================================================
