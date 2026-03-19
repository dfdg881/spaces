#开启白虎服务
set -e
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

export MISE_HIDE_UPDATE_WARNING=1

# 日志输出格式
COLOR_PREFIX="\033[1;36m[Entrypoint]\033[0m"
log() {
  printf "${COLOR_PREFIX} %s\n" "$1"
}

MISE_DIR="/app/envs/mise"

log "Starting environment initialization..."

# ============================
# 创建基础目录
# ============================
mkdir -p \
  /app/data \
  /app/data/scripts \
  /app/configs \
  /app/envs

if [ -d "/app/example" ]; then
  mkdir -p /app/data/scripts/example
  rsync -a --ignore-existing /app/example/ /app/data/scripts/example/ || true
  log "Example scripts synced to /app/data/scripts/example"
else
  log "No example directory found, skipping example sync"
fi

# ============================
# Mise 环境初始化
# ============================
# 始终尝试同步基础环境（以补充用户挂载卷中可能缺失的文件，如 config.toml）
mkdir -p "$MISE_DIR"
if [ -d "/opt/mise-base" ]; then
  log "Syncing mise environment from base..."
  # 使用 rsync 同步: -a 归档模式, --ignore-existing 不覆盖已存在文件
  rsync -a --ignore-existing /opt/mise-base/ "$MISE_DIR/" || true
  log "Mise environment synced"
else
  log "No base mise environment found, skipping sync"
fi

# ============================
# 环境变量注入
# ============================
export MISE_DATA_DIR="$MISE_DIR"
export MISE_CONFIG_DIR="$MISE_DIR"
export PATH="$MISE_DIR/shims:$MISE_DIR/bin:$PATH"

log "Mise PATH configured, verifying runtimes..."

# 默认启用 Python 镜像源
export PIP_INDEX_URL=${PIP_INDEX_URL:-https://pypi.org/simple}

# Node 内存限制
export NODE_OPTIONS="--max-old-space-size=256"
export PYTHONPATH=/app/data/scripts:$PYTHONPATH

# ============================
# 打印确认 (增加超时防护，防止这里卡死)
# ============================
log "Checking mise..."
log "  - mise: $(mise --version 2>/dev/null | head -n 1 || echo "not found")"

log "Checking python..."
log "  - python: $(python --version 2>&1 | head -n 1 || echo "not found")"

log "Checking node..."
log "  - node: $(node --version 2>&1 | head -n 1 || echo "not found")"

# 延迟获取 NODE_PATH，避免同步阻塞启动
log "Checking npm..."
log "  - npm: $(npm --version 2>&1 | head -n 1 || echo "not found")"
export NODE_PATH=$(npm root -g 2>/dev/null || echo "")
log "  - node_path: $NODE_PATH"

# ============================
# 将 baihu 注册到全局命令
# ============================
ln -sf /app/baihu /usr/local/bin/baihu

# ============================
# 启动应用
# ============================
printf "\n\033[1;32m>>> Environment setup complete. Starting Baihu Server...\033[0m\n\n"

cd /app
exec ./baihu server


echo "10秒后开始恢复任务..."
sleep 10


echo  "======================写入rclone配置========================\n"
echo "$RCLONE_CONF" > ~/.config/rclone/rclone.conf

if [ -n "$RCLONE_CONF" ]; then
  echo "##########同步备份############"

  # 使用 rclone ls 命令列出文件夹内容，将输出和错误分别捕获
  OUTPUT=$(rclone ls "$REMOTE_FOLDER" 2>&1)
  # 获取 rclone 命令的退出状态码
  EXIT_CODE=$?
  #echo "rclone退出代码:$EXIT_CODE"
  # 判断退出状态码
  if [ $EXIT_CODE -eq 0 ]; then
    # rclone 命令成功执行，检查文件夹是否为空
    if [ -z "$OUTPUT" ]; then
      #为空不处理
      echo "初次安装"
    else
      #echo "文件夹不为空"
      # rclone sync $REMOTE_FOLDER /app --exclude="/baihu" --exclude "/docker-entrypoint.sh"
      mkdir /app/backup_tmp
      # 找最新的文件名
      latest_file=$(rclone lsjson $REMOTE_FOLDER | jq -r 'sort_by(.ModTime) | last | .Path')
      # 复制到目标目录
      rclone copy $REMOTE_FOLDER/$latest_file /app/backup_tmp
      ./baihu restore /app/backup_tmp/$latest_file
      rm -rf /app/backup_tmp
      pm2 restart baihu
    fi
  elif [[ "$OUTPUT" == *"directory not found"* ]]; then
    echo "错误：文件夹不存在"
  else
    echo "错误：$OUTPUT"
  fi
else
    echo "没有检测到Rclone配置信息"
fi

tail -f /dev/null
