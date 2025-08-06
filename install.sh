#!/bin/bash

echo "========== Komari Monitor Agent 一键部署 + 开机自启 =========="

# 1. 设置安装目录
INSTALL_DIR=/opt/komari-agent
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR" || exit 1

# 2. 交互式输入域名和 token
read -p "请输入面板域名（例如 rz.xxxx.xx）: " SERVER_DOMAIN
read -p "请输入探针 Token: " AGENT_TOKEN

# 3. 下载 agent 二进制文件
AGENT_BIN="komari-agent"
DOWNLOAD_URL="https://github.com/GenshinMinecraft/komari-monitor-rs/releases/download/latest/komari-monitor-rs-linux-x86_64-musl"

echo "🔽 正在下载 Agent..."
wget -O "$AGENT_BIN" "$DOWNLOAD_URL" || { echo "❌ 下载失败"; exit 1; }

# 4. 添加执行权限
chmod +x "$AGENT_BIN"
cp "$AGENT_BIN" /usr/local/bin/komari-agent

# 5. 使用 nohup 启动一次（便于立即生效）
echo "🔁 后台运行中..."
nohup /usr/local/bin/komari-agent \
  --http-server http://$SERVER_DOMAIN \
  --ws-server ws://$SERVER_DOMAIN \
  --token $AGENT_TOKEN > /opt/komari-agent/komari.log 2>&1 &

# 6. 创建 systemd 服务实现开机自启
cat <<EOF > /etc/systemd/system/komari-agent.service
[Unit]
Description=Komari Monitor Agent
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/komari-agent \\
  --http-server http://$SERVER_DOMAIN \\
  --ws-server ws://$SERVER_DOMAIN \\
  --token $AGENT_TOKEN
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# 7. 启动并启用服务
systemctl daemon-reload
systemctl enable komari-agent
systemctl start komari-agent

# 8. 完成提示
echo ""
echo "✅ Agent 已运行，并设置为开机自启"
echo "📄 日志文件: $INSTALL_DIR/komari.log"
echo "🔍 查看状态: systemctl status komari-agent"
