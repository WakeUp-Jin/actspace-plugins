#!/usr/bin/env bash
# 构建插件。用法：
#   ./scripts/build.sh            构建 plugins/ 下所有插件
#   ./scripts/build.sh fs-watch   只构建指定插件
#
# 约定：每个插件目录自带 build.sh，负责编译并把产物放进自己的 skill/scripts/。
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $# -ge 1 ]]; then
  plugin_dirs=("${repo_root}/plugins/$1")
  if [[ ! -d "${plugin_dirs[0]}" ]]; then
    echo "插件不存在：$1（应位于 plugins/$1/）" >&2
    exit 1
  fi
else
  plugin_dirs=("${repo_root}"/plugins/*/)
fi

for dir in "${plugin_dirs[@]}"; do
  name="$(basename "${dir}")"
  if [[ ! -x "${dir}/build.sh" && ! -f "${dir}/build.sh" ]]; then
    echo "跳过 ${name}：没有 build.sh" >&2
    continue
  fi
  echo "==> 构建插件 ${name}"
  bash "${dir}/build.sh"
done
