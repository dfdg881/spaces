FROM ghcr.io/engigu/baihu:latest

ENV REMOTE_FOLDER="huggingface:/baihu"

RUN apt-get update && apt-get install -y rclone jq libicu-dev
RUN rclone config -h
COPY ./restore.sh /
RUN sed -i '/^exec \.\/baihu server$/d' /app/docker-entrypoint.sh
RUN chmod 777 /etc/hosts && echo "23.146.4.128 ikuuu.nl" >> /etc/hosts
RUN chmod 644 /etc/hosts
RUN cat /restore.sh >> /app/docker-entrypoint.sh
RUN mise install dotnet@8.0.200
RUN mise exec python@3.13.12 -- pip install requests
#RUN sed -i '50r /restore.sh' /app/docker-entrypoint.sh

