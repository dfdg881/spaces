FROM ghcr.io/engigu/baihu:latest

ENV REMOTE_FOLDER="huggingface:/baihu"

RUN apt-get update && apt-get install -y rclone jq libicu-dev
RUN rclone config -h
COPY ./restore.sh /
COPY ./custom-entrypoint.sh /app/custom-entrypoint.sh
RUN chmod +x /app/custom-entrypoint.sh
RUN mise install dotnet@10.0.401
RUN mise use -g node@23.11.1
RUN mise use -g python@3.13.12
RUN mise exec python@3.13.12 -- pip install requests
RUN mise exec python@3.13.12 -- pip install cryptography

# 覆盖基础镜像的 ENTRYPOINT，改用自定义启动脚本
ENTRYPOINT ["/app/custom-entrypoint.sh"]
