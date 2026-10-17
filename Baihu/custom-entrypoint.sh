#!/bin/sh
set -e
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export MISE_HIDE_UPDATE_WARNING=1

# 加载基础镜像的公共 Entrypoint 库（与官方入口完全一致）
SCRIPT_DIR="/app"
COMMON_SH="${SCRIPT_DIR}/docker-entrypoint-common.sh"
[ ! -f "$COMMON_SH" ] && COMMON_SH="/app/docker-entrypoint-common.sh"
. "$COMMON_SH"

# 1) 复用官方初始化流程
show_banner "${BAIHU_BANNER_MODE:-标准版 (Standard)}"
init_directories
sync_mise_environment "/opt/mise-base"
setup_runtime_env
verify_runtimes
setup_cli_and_completion

# 2) 你的自定义启动逻辑（这是 git clone 等能真正跑到的地方）
#    例如：git clone https://gh-proxy.org/https://github.com/engigu/baihu-panel.git /app/xxx
cd /app
# git clone https://gh-proxy.org/https://github.com/engigu/baihu-panel.git /app/baihu-panel

# 3) 执行原来的 restore.sh（rclone 恢复 + pm2 启动 baihu + tail -f 保活）
#    restore.sh 内部已经 pm2 start "./baihu server" 并 tail -f /dev/null，
#    所以这里不要再 exec baihu server，否则会重复拉起。
cd /
bash restore.sh
