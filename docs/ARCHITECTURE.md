# 架构总览

本仓库是 actspace 的外部插件（Plugins）集合：每个插件是一个独立二进制程序，通过文件契约（事件 JSONL + 心跳 state.json）与宿主交换数据。契约的唯一事实来源在 `actspace-agent` 仓库的 `docs/design-docs/agent-plugins-fs-watch.md`。

## 仓库结构

- `plugins/<name>/`：一个插件一个文件夹，语言无关、自包含。目录内约定：
  - 源码与该语言的构建定义（Rust 是 `Cargo.toml` + `Cargo.lock`，Go 是 `go.mod` + `go.sum`）。
  - `README.md`：插件介绍与使用说明；根 README 只做入口清单，细节都在这里。
  - `build.sh`：插件构建入口，编译并把二进制放进自己的 `skill/scripts/`。
  - `skill/`：Skill 载体（`SKILL.md` + `scripts/` 里的二进制 + 运行时写入的 `references/`），构建后可整体分发。
- `scripts/`：仓库级脚本；`scripts/build.sh` 遍历所有插件的 `build.sh`；`scripts/install.sh [name]` 构建并把 skill 安装到本机 `~/.agents/skills/`（可用 `AGENTS_SKILLS_DIR` 覆盖），已存在的 `references/` 运行时数据不会被删除。
- `docs/`：仓库知识库。

## 边界

- 插件之间互不依赖；插件与宿主之间只有文件契约，不引入 socket / RPC。
- 不使用跨插件的语言级 workspace（如根级 Cargo workspace）：语言选型按插件独立决定，仓库结构不偏向任何语言。
- 构建产物（`skill/scripts/` 下的二进制、`target/` 等）不进 git，由 `build.sh` 产出。
- 每个插件必须提交自己的 lockfile（`Cargo.lock` / `go.sum`），供应链要求见 `docs/SUPPLY_CHAIN_SECURITY.md`。

## 两种消费方式

1. **actspace 集成**：用户在设置页选择构建出的二进制安装，进程由 actspace main 进程 spawn / 守护。
2. **任意 Agent 按 Skill 使用**：`./scripts/install.sh <name>` 一键构建并安装到 `~/.agents/skills/<name>/`，按 `SKILL.md` 指引启动 `scripts/` 里的二进制并读取 `references/` 输出。

## 待补齐

- 插件多平台交叉编译与 release 分发（当前 release 流水线仍是模板占位）。
- 第二个插件出现后，沉淀插件目录结构的校验脚本（检查 build.sh / skill/SKILL.md 是否齐备）。
