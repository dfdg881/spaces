# 使用官方青龙镜像作为基础
FROM ghcr.io/whyour/qinglong:develop

# 安装rclone和sshpass
RUN apt-get update && \
    apt-get install --no-install-recommends -y rclone sshpass && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 创建rclone配置文件
RUN rclone config -h
HEALTHCHECK --interval=5s --timeout=2s --retries=20 \
  CMD curl -sf --noproxy '*' http://127.0.0.1:5700/api/health || exit 1

ENTRYPOINT ["./docker/docker-entrypoint.sh"]

VOLUME /ql/data
  
EXPOSE 8080
