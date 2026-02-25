#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
IOS_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd -- "${IOS_ROOT}/.." && pwd)"

WEB_DATA_PATH="${REPO_ROOT}/js/wordData.js"
IOS_DATA_PATH="${IOS_ROOT}/data/wordData.js"
EXPORT_SCRIPT_PATH="${SCRIPT_DIR}/export_word_roots_json.js"

if [[ ! -f "${WEB_DATA_PATH}" ]]; then
  echo "未找到网页词库文件: ${WEB_DATA_PATH}" >&2
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo "未找到 node，请先安装 Node.js。" >&2
  exit 1
fi

mkdir -p "$(dirname "${IOS_DATA_PATH}")"
cp "${WEB_DATA_PATH}" "${IOS_DATA_PATH}"
node "${EXPORT_SCRIPT_PATH}"

echo "已同步网页词库到 iOS：${IOS_DATA_PATH}"
