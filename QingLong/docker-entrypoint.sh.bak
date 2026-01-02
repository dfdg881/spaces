#!/bin/bash

# 青龙面板启动脚本（适配官方 whyour/qinglong:debian 镜像）
# 已移除 code-server 和 nginx

dir_shell=/ql/shell
. $dir_shell/share.sh
. $dir_shell/env.sh

# 写入 rclone 配置（如果通过环境变量传入）
if [ -n "$RCLONE_CONF" ]; then
    echo -e "======================写入rclone配置========================\n"
    mkdir -p ~/.config/rclone
    echo "$RCLONE_CONF" > ~/.config/rclone/rclone.conf
    echo "Rclone 配置已写入"
fi

echo -e "======================1. 检测配置文件========================\n"
import_config "$@"
fix_config

pm2 l &>/dev/null

echo -e "======================2. 安装依赖========================\n"
patch_version

echo -e "======================3. 启动pm2服务========================\n"
reload_update
reload_pm2

if [[ $AutoStartBot == true ]]; then
  echo -e "======================4. 启动bot========================\n"
  nohup ql bot >$dir_log/bot.log 2>&1 &
  echo -e "bot后台启动中...\n"
fi

if [[ $EnableExtraShell == true ]]; then
  echo -e "====================5. 执行自定义脚本========================\n"
  nohup ql extra >$dir_log/extra.log 2>&1 &
  echo -e "自定义脚本后台执行中...\n"
fi

echo -e "############################################################\n"
echo -e "容器启动成功..."
echo -e "############################################################\n"

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