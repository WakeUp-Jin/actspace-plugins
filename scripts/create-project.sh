#!/usr/bin/env bash

set -euo pipefail

resolve_script_path() {
  local source_path="${BASH_SOURCE[0]}"

  while [[ -L "${source_path}" ]]; do
    local source_dir
    source_dir="$(cd -P "$(dirname "${source_path}")" && pwd)"
    source_path="$(readlink "${source_path}")"
    [[ "${source_path}" != /* ]] && source_path="${source_dir}/${source_path}"
  done

  cd -P "$(dirname "${source_path}")" && pwd
}

template_root="$(cd "$(resolve_script_path)/.." && pwd)"
template_name="actspace-plugins"

usage() {
  cat <<EOF
用法:
  code-harness-init <项目名> [目标目录]   创建新项目
  code-harness-init --into [目标目录]     在已有项目中初始化模板（默认当前目录）

新建模式:
  项目名        新项目的名称（必填）
  目标目录      新项目创建在哪个目录下（可选，默认当前目录）

已有项目模式 (--into):
  只复制目标目录中不存在的文件，已有文件一律保留不覆盖。

示例:
  code-harness-init my-app
  code-harness-init my-app ~/projects
  code-harness-init --into
  code-harness-init --into ~/projects/my-app
EOF
  exit 1
}

if [[ $# -lt 1 ]]; then
  usage
fi

rsync_excludes=(
  --exclude='.git'
  --exclude='node_modules'
  --exclude='dist'
  --exclude='.tmp'
  --exclude='tmp'
)

replace_template_name() {
  local project_name="$1"
  shift
  local file
  for file in "$@"; do
    case "${file}" in
      *.md | *.json | *.yml | *.yaml | *.sh)
        perl -pi -e "s/${template_name}/${project_name}/g" "${file}"
        ;;
    esac
  done
}

print_next_steps() {
  local target_dir="$1"
  echo ""
  echo "下一步建议:"
  echo "  cd ${target_dir}"
  echo "  npm run ci                        # 验证仓库完整性"
  echo "  补齐 docs/ARCHITECTURE.md          # 填入真实项目架构"
  echo "  补齐 CODEOWNERS                    # 替换为真实的代码所有者"
  echo "  git add -A && git commit -m 'init' # 创建初始提交"
}

if [[ "$1" == "--into" ]]; then
  target_dir="${2:-.}"

  if [[ ! -d "${target_dir}" ]]; then
    echo "错误: 目标目录不存在: ${target_dir}" >&2
    exit 1
  fi

  target_dir="$(cd "${target_dir}" && pwd)"
  project_name="$(basename "${target_dir}")"

  if [[ "${target_dir}" == "${template_root}" ]]; then
    echo "错误: 目标目录就是模板仓库本身，不能对自己初始化。" >&2
    exit 1
  fi

  # 只复制目标目录中不存在的文件，并记录实际新增了哪些
  copied_files=()
  while IFS= read -r line; do
    [[ "${line}" == \>f* ]] && copied_files+=("${line#* }")
  done < <(rsync -a --ignore-existing --itemize-changes \
    "${rsync_excludes[@]}" \
    "${template_root}/" "${target_dir}/")

  cd "${target_dir}"

  if [[ ! -d .git ]]; then
    git init --quiet
  fi

  if [[ ${#copied_files[@]} -eq 0 ]]; then
    echo ""
    echo "没有新增任何文件：模板中的文件在 ${target_dir} 里都已存在。"
    exit 0
  fi

  # 名称替换只作用于本次新复制的文件，绝不改动项目原有文件
  replace_template_name "${project_name}" "${copied_files[@]}"

  echo ""
  echo "模板已初始化到已有项目: ${target_dir}"
  echo "本次新增 ${#copied_files[@]} 个文件（已有文件全部保留，未做覆盖）。"
  print_next_steps "${target_dir}"
  exit 0
fi

project_name="$1"
target_parent="${2:-.}"
target_dir="${target_parent}/${project_name}"

if [[ -d "${target_dir}" ]]; then
  echo "错误: 目标目录已存在: ${target_dir}" >&2
  echo "提示: 如果想在已有项目中初始化模板，请使用: code-harness-init --into ${target_dir}" >&2
  exit 1
fi

mkdir -p "${target_dir}"

rsync -a \
  "${rsync_excludes[@]}" \
  "${template_root}/" "${target_dir}/"

cd "${target_dir}"

git init --quiet

find . -type f \( -name '*.md' -o -name '*.json' -o -name '*.yml' -o -name '*.yaml' -o -name '*.sh' \) \
  -not -path './.git/*' \
  -exec perl -pi -e "s/${template_name}/${project_name}/g" {} +

echo ""
echo "新项目已创建: ${target_dir}"
print_next_steps "${target_dir}"
