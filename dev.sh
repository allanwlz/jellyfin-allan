#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$ROOT_DIR/docker-compose.dev.yml"
ACTION="${1:-help}"
SERVER_IMAGE="jellyfin-allan/jf-server-dev:local"

if ! command -v docker >/dev/null 2>&1; then
  echo "未检测到 docker，请先安装 Docker Desktop。"
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "未检测到 docker compose 插件，请升级 Docker Desktop。"
  exit 1
fi

JF_MEDIA_DIR_DEFAULT="$HOME/Movies"
JF_MEDIA_DIR="${JF_MEDIA_DIR:-$JF_MEDIA_DIR_DEFAULT}"

mkdir -p \
  "$ROOT_DIR/.jf-dev/config" \
  "$ROOT_DIR/.jf-dev/cache" \
  "$ROOT_DIR/.jf-dev/nuget" \
  "$ROOT_DIR/.jf-dev/jf-web-node_modules" \
  "$ROOT_DIR/.jf-dev/media"

run_compose() {
  LOCAL_UID="$(id -u)" LOCAL_GID="$(id -g)" JF_MEDIA_DIR="$JF_MEDIA_DIR" \
    docker compose -f "$COMPOSE_FILE" "$@"
}

start_dev_containers() {
  if ! run_compose up -d --no-build; then
    echo "检测到容器名称冲突，清理后重试..."
    docker rm -f jellyfin-dev-server jellyfin-dev-web >/dev/null 2>&1 || true
    run_compose up -d --no-build
  fi
}

print_help() {
  cat <<'EOF'
用法: ./dev.sh [build|restart|start|stop|submodule|help]

命令说明:
  build    重建镜像（仅构建，不启动容器）
  restart  重启已有容器中的服务（不重建镜像）
  start    启动容器（不重建镜像）
  stop     停止容器
  submodule  按主仓库记录 commit 浅更新 submodule
  help     打印本帮助

环境变量:
  JF_MEDIA_DIR  宿主机媒体目录（默认: $HOME/Movies，映射到容器内 /media）
EOF
}

print_endpoints() {
  echo
  echo "访问地址："
  echo "  后端: http://localhost:8096"
  echo "  前端: http://localhost:8083"
}

print_media_mapping() {
  echo "媒体目录映射: $JF_MEDIA_DIR -> /media"
}

ensure_media_dir_for_runtime() {
  if [ ! -d "$JF_MEDIA_DIR" ]; then
    echo "错误: JF_MEDIA_DIR 不存在: $JF_MEDIA_DIR"
    echo "请先设置正确目录，例如:"
    echo "  JF_MEDIA_DIR=\"$HOME/Movies\" ./dev.sh start"
    exit 1
  fi
}

ensure_server_image_for_runtime() {
  if ! docker image inspect "$SERVER_IMAGE" >/dev/null 2>&1; then
    echo "错误: 本地镜像不存在: $SERVER_IMAGE"
    echo "请先执行: ./dev.sh build"
    exit 1
  fi
}

case "$ACTION" in
  build)
    echo "重建开发镜像..."
    run_compose build jf-server
    echo "镜像重建完成。"
    ;;
  restart)
    echo "重启 Jellyfin 开发容器服务..."
    ensure_media_dir_for_runtime
    ensure_server_image_for_runtime
    print_media_mapping
    if ! run_compose restart jf-server jf-web; then
      echo "未检测到已有容器，尝试直接启动（不重建镜像）..."
      start_dev_containers
    fi
    print_endpoints
    ;;
  start)
    echo "启动 Jellyfin 开发环境（不重建镜像）..."
    ensure_media_dir_for_runtime
    ensure_server_image_for_runtime
    print_media_mapping
    start_dev_containers
    print_endpoints
    ;;
  stop)
    echo "停止 Jellyfin 开发环境..."
    run_compose down --remove-orphans 2>/dev/null || docker rm -f jellyfin-dev-server jellyfin-dev-web >/dev/null 2>&1 || true
    echo "开发环境已停止。"
    ;;
  submodule|submodules)
    "$ROOT_DIR/submodule-shallow-update.sh"
    ;;
  logs)
    run_compose logs -f jf-server jf-web
    ;;
  status|ps)
    run_compose ps
    ;;
  help|-h|--help)
    print_help
    ;;
  *)
    echo "未知命令: $ACTION"
    print_help
    exit 1
    ;;
esac

if [ "$ACTION" = "restart" ] || [ "$ACTION" = "start" ]; then
  if [ "${OPEN_BROWSER:-1}" = "1" ] && command -v open >/dev/null 2>&1; then
    echo
    echo "正在打开浏览器..."
    sleep 1
    open "http://localhost:8083" || true
  fi
fi
