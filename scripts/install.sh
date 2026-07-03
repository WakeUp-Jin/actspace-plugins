#!/usr/bin/env bash
# 把插件的 skill 安装到本机 Agent skills 目录（默认 ~/.agents/skills/）。用法：
#   ./scripts/install.sh            安装所有插件
#   ./scripts/install.sh fs-watch   只安装指定插件
#
# 会先执行插件的 build.sh（保证 skill/scripts/ 里有最新二进制），再把 skill/
# 内容复制到目标目录。已存在的 references/ 运行时数据不会被删除。
# 目标目录可用环境变量 AGENTS_SKILLS_DIR 覆盖。
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skills_dir="${AGENTS_SKILLS_DIR:-${HOME}/.agents/skills}"

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
  if [[ ! -f "${dir}/skill/SKILL.md" ]]; then
    echo "跳过 ${name}：没有 skill/SKILL.md" >&2
    continue
  fi
  echo "==> 构建 ${name}"
  bash "${dir}/build.sh"

  target="${skills_dir}/${name}"
  mkdir -p "${target}"
  cp -R "${dir}/skill/." "${target}/"

  # 本渠道装出来的 skill 没有宿主托管进程：把 SKILL.md 元信息里的
  # process-management 从 host（模板默认，供 actspace 物化用）改写为 agent。
  if grep -q '^  process-management: host$' "${target}/SKILL.md" 2>/dev/null; then
    sed -i.bak 's/^  process-management: host$/  process-management: agent/' "${target}/SKILL.md"
    rm -f "${target}/SKILL.md.bak"
  fi

  echo "==> 已安装 ${name} → ${target}"
done
