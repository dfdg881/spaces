# 使用官方青龙镜像作为基础
FROM ghcr.io/whyour/qinglong:develop

# 安装 rclone
RUN apt-get update && \
    apt-get install -y curl unzip && \
    curl -O https://downloads.rclone.org/rclone-current-linux-amd64.zip && \
    unzip rclone-current-linux-amd64.zip && \
    cp rclone-*-linux-amd64/rclone /usr/local/bin/ && \
    chmod +x /usr/local/bin/rclone && \
    rm -rf rclone-* && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 创建rclone配置文件
RUN rclone config -h

HEALTHCHECK --interval=5s --timeout=2s --retries=20 \
  CMD curl -sf --noproxy '*' http://127.0.0.1:5400/api/health || exit 1

# 复制自定义启动脚本（如果需要 rclone 自动同步）
COPY notify.py /notify.py
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# 使用自定义启动脚本
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 5700

VOLUME /ql/data