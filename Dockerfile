# OpenClaw Docker 镜像
FROM node:22-slim

# 设置工作目录
WORKDIR /app

# 创建orangepi用户
RUN groupadd -r -g 1000 orangepi && \
    useradd -r -u 1000 -g orangepi -m -s /bin/bash orangepi

# 安装必要的系统依赖
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    chromium \
    curl \
    fonts-liberation \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    git \
    gosu \
    jq \
    python3 \
    socat \
    tini \
    unzip \
    websockify \
    neovim \
  && rm -rf /var/lib/apt/lists/*

# 更新 npm 到最新版本
RUN npm install -g npm@latest

# 安装 bun
RUN curl -fsSL https://bun.sh/install | BUN_INSTALL=/usr/local bash
ENV BUN_INSTALL="/usr/local"
ENV PATH="$BUN_INSTALL/bin:$PATH"

# 安装 qmd
RUN bun install -g https://github.com/tobi/qmd

# 安装 OpenClaw 和 OpenCode AI
RUN npm install -g openclaw@2026.2.22-2 opencode-ai@latest

# 安装 Playwright 和 Chromium
RUN npm install -g playwright && npx playwright install chromium --with-deps

# 安装 playwright-extra 和 puppeteer-extra-plugin-stealth
RUN npm install -g playwright-extra puppeteer-extra-plugin-stealth

# 安装 bird
RUN npm install -g @steipete/bird

# 切换到 orangepi 用户安装插件
USER orangepi

# 安装钉钉插件 - 使用 timeout 防止卡住，忽略错误继续构建
RUN openclaw plugins install @soimy/dingtalk

# 安装 QQ 机器人插件 - 使用 timeout 防止卡住，忽略错误继续构建
RUN openclaw plugins install @sliverp/qqbot@latest

# 设置工作目录为 home
WORKDIR /home/orangepi

ENTRYPOINT ["/usr/bin/tini", "--", "openclaw gateway run"]
