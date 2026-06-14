#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$ROOT_DIR/docker-compose.dev.yml"

if ! command -v docker >/dev/null 2>&1; then
  echo "未检测到 docker，请先安装 Docker Desktop。"
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "未检测到 docker compose 插件，请升级 Docker Desktop。"
  exit 1
fi

MEDIA_DIR_DEFAULT="$HOME/Movies"
MEDIA_DIR="${MEDIA_DIR:-$MEDIA_DIR_DEFAULT}"

mkdir -p "$ROOT_DIR/.jf-dev/config" "$ROOT_DIR/.jf-dev/cache"

echo "启动 Jellyfin 开发环境..."
echo "  根目录: $ROOT_DIR"
echo "  媒体目录: $MEDIA_DIR"

LOCAL_UID="$(id -u)" LOCAL_GID="$(id -g)" MEDIA_DIR="$MEDIA_DIR" \
  docker compose -f "$COMPOSE_FILE" up -d

echo
echo "容器已启动："
echo "  后端: http://localhost:8096"
echo "  前端: http://localhost:8080"
echo
echo "查看日志："
echo "  docker compose -f \"$COMPOSE_FILE\" logs -f jf-server"
echo "  docker compose -f \"$COMPOSE_FILE\" logs -f jf-web"
echo
echo "停止环境："
echo "  ./down.sh"

if [ "${OPEN_BROWSER:-1}" = "1" ] && command -v open >/dev/null 2>&1; then
  echo
  echo "正在打开浏览器..."
  sleep 1
  open "http://localhost:8080" || true
fi
