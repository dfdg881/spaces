FROM ghcr.io/dfdg881/baihu1:latest-amd64

ENV REMOTE_FOLDER="huggingface:/baihu"

RUN apt-get update && apt-get install -y rclone jq libicu-dev
RUN rclone config -h
COPY ./restore.sh /
RUN sed -i '/^exec \.\/baihu server$/d' /app/docker-entrypoint.sh
RUN cat /restore.sh >> /app/docker-entrypoint.sh
#RUN sed -i '50r /restore.sh' /app/docker-entrypoint.sh

