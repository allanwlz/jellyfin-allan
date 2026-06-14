#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

if ! command -v git >/dev/null 2>&1; then
  echo "未检测到 git，请先安装 git。"
  exit 1
fi

if [ ! -f ".gitmodules" ]; then
  echo "未找到 .gitmodules，当前仓库没有配置 submodule。"
  exit 0
fi

if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
  echo "当前仓库还没有有效提交，无法解析 submodule 目标 commit。"
  exit 1
fi

echo "同步 submodule 配置..."
git submodule sync --recursive

mapfile -t SUBMODULE_KEYS < <(git config -f .gitmodules --name-only --get-regexp '^submodule\..*\.path$')

if [ "${#SUBMODULE_KEYS[@]}" -eq 0 ]; then
  echo "未在 .gitmodules 中找到 submodule 配置。"
  exit 0
fi

for key in "${SUBMODULE_KEYS[@]}"; do
  name="${key#submodule.}"
  name="${name%.path}"
  path="$(git config -f .gitmodules --get "$key")"
  url="$(git config -f .gitmodules --get "submodule.${name}.url")"

  if [ -z "$path" ] || [ -z "$url" ]; then
    echo "跳过 submodule '$name'（path/url 配置缺失）"
    continue
  fi

  commit="$(git ls-tree HEAD "$path" | awk '{print $3}')"
  if [ -z "$commit" ]; then
    echo "跳过 $path（HEAD 未记录该 submodule commit）"
    continue
  fi

  echo
  echo "处理 submodule: $path"
  echo "  url:    $url"
  echo "  commit: $commit"

  mkdir -p "$path"
  if [ ! -d "$path/.git" ]; then
    git -C "$path" init -q
  fi

  if git -C "$path" remote get-url origin >/dev/null 2>&1; then
    git -C "$path" remote set-url origin "$url"
  else
    git -C "$path" remote add origin "$url"
  fi

  if ! git -C "$path" fetch --depth 1 origin "$commit"; then
    echo "  直接按 commit 浅抓取失败，尝试常规浅更新..."
    git submodule update --init --depth 1 -- "$path"
  else
    git -C "$path" checkout --detach "$commit"
  fi
done

echo
echo "submodule 浅更新完成。"
