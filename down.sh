#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$ROOT_DIR/docker-compose.dev.yml"

LOCAL_UID="$(id -u)" LOCAL_GID="$(id -g)" docker compose -f "$COMPOSE_FILE" down

echo "开发环境已停止。"
