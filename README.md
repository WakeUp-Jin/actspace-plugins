# actspace-plugins

actspace 的外部插件（Plugins）集合仓库。插件是独立的二进制程序，伴随宿主（actspace 或任意 Agent 环境）运行，通过**文件**与宿主交换数据，不引入 socket / RPC。

每个插件是 `plugins/` 下一个自包含文件夹（语言无关，Rust / Go 均可），自带源码、构建脚本和 Skill 载体。插件的详细介绍见各自目录里的 README。

## 插件清单

| 插件 | 语言 | 状态 | 一句话说明 |
| --- | --- | --- | --- |
| [fs-watch](plugins/fs-watch/README.md) | Rust | v0 | 递归监听目录文件变化，事件按天写 JSONL，带心跳与自清理 |

## 快速开始

```bash
# 构建（所有插件 / 指定插件）
./scripts/build.sh
./scripts/build.sh fs-watch

# 一键安装 skill 到本机 ~/.agents/skills/（构建 + 复制）
./scripts/install.sh
./scripts/install.sh fs-watch
```

安装后 Agent 即可发现该 Skill；启动方式和读取指引见插件 README 与其 `skill/SKILL.md`。

## 两种使用方式

1. **actspace 集成**：构建后在 actspace 设置页「插件」分区选择二进制安装，进程由 actspace 托管。
2. **任意 Agent 按 Skill 使用**：`./scripts/install.sh <插件名>` 装到 `~/.agents/skills/<插件名>/`，按 SKILL.md 指引使用。

## 新增插件的约定

在 `plugins/<name>/` 下提供：

- 源码 + 该语言的构建定义与 lockfile（如 `Cargo.toml`+`Cargo.lock`、`go.mod`+`go.sum`）。
- `README.md`：插件介绍、构建与使用说明。
- `build.sh`：编译并把二进制放进自己的 `skill/scripts/`。
- `skill/`：`SKILL.md` + `scripts/`（构建产物，不进 git），构建后可整体分发。

架构与边界详见 `docs/ARCHITECTURE.md`；插件契约以 `actspace-agent` 仓库的 `docs/design-docs/agent-plugins-fs-watch.md` 为唯一事实来源。
