#!/bin/bash

# 检查是否以 root 用户运行（推荐）
if [[ $EUID -ne 0 ]]; then
   echo "请使用 root 用户或加上 sudo 运行此脚本！"
   exit 1
fi

# 1. 卸载旧版本（如果已安装）
echo "正在卸载旧版 Docker（如果存在）..."
apt-get remove -y docker docker-engine docker.io containerd runc || true

# 2. 安装依赖
echo "安装必要的依赖..."
apt-get update
apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# 3. 添加 Docker 官方 GPG 密钥
echo "添加 Docker GPG 密钥..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 4. 设置 Docker 软件源
echo "设置 Docker 软件源..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# 5. 安装 Docker
echo "安装 Docker..."
apt-get update
apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# 6. 验证 Docker 安装
echo "验证 Docker 是否安装成功..."
docker run hello-world || {
    echo "Docker 安装失败！"
    exit 1
}

# 7. 让当前用户免 sudo 运行 Docker
echo "配置当前用户免 sudo 运行 Docker..."
usermod -aG docker $SUDO_USER || usermod -aG docker $(whoami)

# 8. 安装 Docker Compose（如果未自动安装）
echo "检查并安装 Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose 未找到，正在安装..."
    COMPOSE_URL="https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)"
    curl -L "$COMPOSE_URL" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
else
    echo "Docker Compose 已安装，版本：$(docker-compose --version)"
fi

# 9. 测试 Docker Compose
echo "测试 Docker Compose..."
docker-compose --version || {
    echo "Docker Compose 安装失败！"
    exit 1
}

# 10. 提示用户重新登录
echo ""
echo "? Docker 和 Docker Compose 安装成功！"
echo "?? 请重新登录或运行 'newgrp docker' 使用户组更改生效！"
echo "?? 现在可以直接使用 'docker' 和 'docker-compose' 命令，无需 sudo！"
