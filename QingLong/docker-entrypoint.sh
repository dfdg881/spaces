#!/bin/bash

export PATH="$HOME/bin:$PATH"

dir_shell=/ql/shell
. $dir_shell/share.sh

export_ql_envs() {
  export BACK_PORT="${ql_port}"
  export GRPC_PORT="${ql_grpc_port}"
}

log_with_style() {
  local level="$1"
  local message="$2"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  printf "\n[%s] [%7s]  %s\n" "${timestamp}" "${level}" "${message}"
}

# 写入 rclone 配置（如果通过环境变量传入）
if [ -n "$RCLONE_CONF" ]; then
    echo -e "======================写入rclone配置========================\n"
    mkdir -p ~/.config/rclone
    echo "$RCLONE_CONF" > ~/.config/rclone/rclone.conf
    echo "Rclone 配置已写入"
fi

echo -e "##########启动容器############"

# Fix DNS resolution issues in Alpine Linux
# Alpine uses musl libc which has known DNS resolver issues with certain domains
# Adding ndots:0 prevents unnecessary search domain appending
if [ -f /etc/alpine-release ]; then
  if ! grep -q "^options ndots:0" /etc/resolv.conf 2>/dev/null; then
    echo "options ndots:0" >> /etc/resolv.conf
    log_with_style "INFO" "🔧  0. 已配置 DNS 解析优化 (ndots:0)"
  fi
fi

log_with_style "INFO" "🚀  1. 检测配置文件..."
load_ql_envs
export_ql_envs
. $dir_shell/env.sh
import_config "$@"
fix_config

# Try to initialize PM2, but don't fail if it doesn't work
pm2 l &>/dev/null || log_with_style "WARN" "PM2 初始化可能失败，将在启动时尝试使用备用方案"

log_with_style "INFO" "⚙️  2. 启动 pm2 服务..."
reload_pm2

if [[ $AutoStartBot == true ]]; then
  log_with_style "INFO" "🤖  3. 启动 bot..."
  nohup ql bot >$dir_log/bot.log 2>&1 &
fi

if [[ $EnableExtraShell == true ]]; then
  log_with_style "INFO" "🛠️  4. 执行自定义脚本..."
  nohup ql extra >$dir_log/extra.log 2>&1 &
fi

log_with_style "SUCCESS" "🎉  容器启动成功!"

# 初始化认证信息
echo -e "##########写入登陆信息############"
dir_root=/ql && source /ql/shell/api.sh 

init_auth_info() {
  local body="$1"
  local tip="$2"
  local currentTimeStamp=$(date +%s)
  local api=$(
    curl -s --noproxy "*" "http://0.0.0.0:5600/api/user/init?t=$currentTimeStamp" \
      -X 'PUT' \
      -H "Accept: application/json" \
      -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 11_2_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Safari/537.36" \
      -H "Content-Type: application/json;charset=UTF-8" \
      -H "Origin: http://0.0.0.0:5700" \
      -H "Referer: http://0.0.0.0:5700/crontab" \
      -H "Accept-Language: en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7" \
      --data-raw "{$body}" \
      --compressed
  )
  code=$(echo "$api" | jq -r .code)
  message=$(echo "$api" | jq -r .message)
  if [[ $code == 200 ]]; then
    echo -e "${tip}成功🎉"
  else
    echo -e "${tip}失败(${message})"
  fi
}

init_auth_info "\"username\": \"$ADMIN_USERNAME\", \"password\": \"$ADMIN_PASSWORD\"" "Change Password"

# rclone 同步功能
if [ -n "$RCLONE_CONF" ]; then
  echo -e "##########同步备份############"
  REMOTE_FOLDER=${RCLONE_REMOTE:-"huggingface:/qinglong"}
  
  # 等待青龙服务启动
  echo "等待青龙服务启动..."
  sleep 5
  
  # 检查 rclone 配置和远程文件夹
  echo "检查远程备份..."
  if rclone lsd "$REMOTE_FOLDER" 2>/dev/null; then
    echo "检测到远程备份文件，尝试恢复..."
    mkdir -p /ql/.tmp/data
    if rclone sync "$REMOTE_FOLDER" /ql/.tmp/data; then
      echo "同步成功，恢复数据..."
      real_time=true ql reload data
    else
      echo "同步失败，可能是权限问题或网络问题"
    fi
  else
    echo "首次启动或远程文件夹为空，跳过恢复"
    echo "提示：可以使用 rclone 手动备份数据到 $REMOTE_FOLDER"
  fi
else
  echo "没有检测到Rclone配置信息，跳过同步"
  echo "提示：通过 RCLONE_CONF 环境变量传入 rclone 配置"
fi

# 发送通知
if [ -n "$NOTIFY_CONFIG" ]; then
    echo "发送启动通知..."
    python /notify.py 2>/dev/null || true
    dir_root=/ql && source /ql/shell/api.sh && notify_api '青龙服务启动通知' '青龙面板成功启动'
else
    echo "没有检测到通知配置信息，不进行通知"
fi

tail -f /dev/null

exec "$@"