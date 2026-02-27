# 使用更具体的版本标签，避免隐式更新导致的不一致
FROM node:22-bookworm-slim

# 设置环境变量
# 1. 设置 Playwright 浏览器下载路径到公共目录，避免用户切换导致的缓存问题
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
# 2. 设置 Bun 安装路径
ENV BUN_INSTALL=/usr/local
ENV PATH=$BUN_INSTALL/bin:$PATH
# 3. 减少 npm 日志输出
ENV NPM_CONFIG_LOGLEVEL=warn

# 设置工作目录
WORKDIR /app

# 1. 创建用户
# 2. 安装系统依赖 (合并层，移除冗余包)
# 3. 安装 Bun 和全局 Node 工具 (合并层，减少镜像层数)
# 4. 安装 Playwright 系统依赖和浏览器
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
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
    neovim && \
    # 安装 Bun
    curl -fsSL https://bun.sh/install | bash && \
    # 安装全局 Node/Bun 工具 (合并所有 npm install -g)
    npm install -g --quiet \
    npm@latest \
    openclaw@2026.2.22-2 \
    opencode-ai@latest \
    playwright \
    playwright-extra \
    puppeteer-extra-plugin-stealth \
    @steipete/bird && \
    bun install -g https://github.com/tobi/qmd && \
    # 安装 Playwright 浏览器和系统依赖 (必须在 root 下运行 --with-deps)
    npx playwright install chromium --with-deps && \
    # 清理 apt 缓存
    rm -rf /var/lib/apt/lists/* && \
    # 清理 npm 缓存
    npm cache clean --force && \
    # 创建 Playwright 缓存目录并授权给 node 用户
    mkdir -p /ms-playwright && \
    chown -R node:node /ms-playwright && \
    # 修复全局 npm 包权限，允许 node 用户安装插件
    chown -R node:node /usr/local/lib/node_modules && \
    chmod -R 755 /usr/local/lib/node_modules

COPY ./start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# 切换到非 root 用户
USER node

# 安装插件 (保留容错逻辑，但优化写法)
# 注意：生产环境建议去掉 || true 以便构建失败时能及时发现
RUN openclaw plugins install @soimy/dingtalk || echo "Warning: DingTalk plugin install failed" && \
    openclaw plugins install @sliverp/qqbot@latest || echo "Warning: QQBot plugin install failed"

COPY openclaw.json /home/node/.openclaw/openclaw.json

# 设置用户家目录为工作目录
WORKDIR /home/node

# 设置入口点
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/start.sh"]
