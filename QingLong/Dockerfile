# 使用官方青龙镜像作为基础
FROM whyour/qinglong:2.20.1-debian

# 安装 rclone
RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install --no-install-recommends -y git \
  curl \
  wget \
  tzdata \
  perl \
  openssl \
  openssh-client \
  jq \
  procps \
  netcat-openbsd \
  unzip \
  libatomic1 \
  chromium-driver \
  rclone \
  sshpass && \
  apt-get clean && \
  ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
  echo "Asia/Shanghai" >/etc/timezone && \
  git config --global user.email "qinglong@users.noreply.github.com" && \
  git config --global user.name "qinglong" && \
  git config --global http.postBuffer 524288000 && \
  npm install -g pnpm@8.3.1 pm2 ts-node && \
  rm -rf /root/.cache && \
  rm -rf /root/.npm && \
  rm -rf /etc/apt/apt.conf.d/docker-clean && \
  ulimit -c 0
  
#python依赖
RUN pip3 install selenium opencv-python-headless ddddocr requests

# 创建rclone配置文件
RUN rclone config -h

HEALTHCHECK --interval=5s --timeout=2s --retries=20 \
  CMD curl -sf --noproxy '*' http://127.0.0.1:5400/api/health || exit 1

# 复制自定义启动脚本（如果需要 rclone 自动同步）
ENV QL_DIR=/ql

RUN chmod -R 777 /ql && \
  chmod -R 777 /var && \
  chmod -R 777 /usr/local && \
  chmod -R 777 /run && \
  chmod -R 777 /usr && \
  chmod -R 777 /root 

COPY docker-entrypoint.sh ${QL_DIR}/docker
COPY notify.py /notify.py
COPY services.json /ql/node_modules/nodemailer/lib/well-known/
RUN chmod a+x ${QL_DIR}/docker/docker-entrypoint.sh

WORKDIR ${QL_DIR}

# 使用自定义启动脚本
ENTRYPOINT ["./docker/docker-entrypoint.sh"]

VOLUME /ql/data

EXPOSE 5700