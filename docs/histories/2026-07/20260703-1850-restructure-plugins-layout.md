## [2026-07-03 18:50] | Task: 重构仓库为语言无关的插件市场布局

### 🤖 Execution Context

- **Agent ID**: Cursor Agent
- **Base Model**: Fable 5
- **Runtime**: Cursor IDE

### 📥 User Query

> 这个仓库要成为 actspace 的插件市场：一个插件一个文件夹，语言可能是 Rust / Go 等；插件有两种消费方式（actspace 集成、其他 Agent 按 Skill 使用）。每个插件应有源码 + skill 文件夹，skill 里有 SKILL.md 和 scripts 文件夹，scripts 里放编译后的二进制。请调整结构让插件更好用。

### 🛠 Changes Overview

**Scope:** 仓库顶层布局、fs-watch 插件、构建脚本、CI、文档。

**Key Actions:**

- **重构目录**: `crates/fs-watch` → `plugins/fs-watch`；删除根级 Cargo workspace（`Cargo.toml`），`Cargo.lock` 下沉到插件目录，插件完全自包含。
- **skill 即分发单元**: 新增约定——插件 `build.sh` 编译后把二进制拷进自己的 `skill/scripts/`，`skill/` 整体复制到 `~/.agents/skills/<name>/` 即可用；产物目录 gitignore。
- **构建入口**: 每个插件自带 `build.sh`（尊重 `CARGO_TARGET_DIR`）；根 `scripts/build.sh` 改为遍历 `plugins/*/build.sh`，支持指定单个插件。
- **SKILL.md**: 补「启动插件」小节——actspace 内由宿主管理不手动启动，外部 Agent 环境用 `scripts/fs-watch --root … --out …` 启动，说明单实例锁退出码 2 的语义。
- **CI**: `ci.yml` 新增 `plugin-fs-watch` job（`cargo test --locked` + `build.sh`）。
- **文档**: 重写 `README.md` 仓库结构与两种使用方式；`docs/ARCHITECTURE.md` 从模板占位替换为真实架构（目录约定、边界、两种消费方式）。

### 🧠 Design Intent (Why)

- 根级 Cargo workspace 会把仓库结构绑死在 Rust 上；插件市场要容纳 Go 等语言，结构必须语言无关——「一个插件一个自包含文件夹 + 目录内 build.sh」是唯一的跨插件约定。
- 之前 skill 模板不含二进制，外部 Agent 使用要手动拼装；把二进制产出到 `skill/scripts/` 后，skill 文件夹本身成为完整分发单元，两种消费方式（actspace 选二进制安装 / 外部整体复制 skill）共享同一份构建产物。
- 每插件保留自己的 lockfile，供应链要求不因去 workspace 降低。

### 📁 Files Modified

- `plugins/fs-watch/`（自 `crates/fs-watch/` 移入，含 `Cargo.lock`、新增 `build.sh`）
- `plugins/fs-watch/skill/SKILL.md`
- `scripts/build.sh`
- `.github/workflows/ci.yml`
- `.gitignore`
- `README.md`
- `docs/ARCHITECTURE.md`
- `docs/QUALITY_SCORE.md`

### 备注

- 验证：`cargo test --locked` 25/25 通过；`./scripts/build.sh` 产出 `plugins/fs-watch/skill/scripts/fs-watch`（可运行）；`./scripts/ci.sh` 通过。
- 小坑：构建脚本不能写死 `target/release/` 路径，要尊重 `CARGO_TARGET_DIR`（沙箱 / CI 可能重定向 target 目录）。

### 追加 [2026-07-03 19:00]

- 应用户要求，`ci.yml` 与 `supply-chain-security.yml` 的自动触发（pull_request / push / schedule）默认关闭，只保留 `workflow_dispatch` 手动运行；恢复方式已写在各 workflow 顶部注释里（`release.yml` 本来就是手动触发）。
- 跨仓库同步完成：`actspace-agent/docs/design-docs/agent-plugins-fs-watch.md` 已更新为新布局（`plugins/<name>/` 自包含目录、skill 即分发单元、状态行标注插件仓库侧 v0 已落地）。

### 追加 [2026-07-03 19:10]

- **每插件独立 README**：新增 `plugins/fs-watch/README.md`（能力、构建、两种使用方式、CLI、输出契约摘要）；根 `README.md` 瘦身为入口页——插件清单表（链接到各插件 README）+ 快速开始 + 新增插件约定。
- **一键安装 skill**：新增 `scripts/install.sh [name]`——先跑插件 `build.sh` 保证二进制最新，再把 `skill/` 内容复制到 `~/.agents/skills/<name>/`（`AGENTS_SKILLS_DIR` 可覆盖目标）；复制不删除目标里已有的 `references/` 运行时数据。已在本机真实执行验证（`~/.agents/skills/fs-watch/` 装好且二进制可运行）。
- `docs/ARCHITECTURE.md` 同步了 README 约定与 install.sh 说明。

### 追加 [2026-07-03 19:20]

- **SKILL.md 增加进程托管元信息**：frontmatter 新增 `metadata.process-management`，标记进程由谁启动。模板默认 `host`（actspace 物化是原样复制，宿主自动拉起进程，Agent 不得执行启动命令）；`scripts/install.sh` 安装到外部环境时自动把该字段改写为 `agent`（无宿主托管，需 Agent / 用户自行启动）。正文「启动插件」小节改为按该字段分支。
- 动机：同一份 SKILL.md 分发到两种环境，进程托管方式不同；静态写死"自动启动"会误导外部环境，写死"要手动启动"会误导 actspace 内的 Agent。按安装渠道在安装时改写字段，两边都拿到正确语义。
- 跨仓库同步：`agent-plugins-fs-watch.md` 的「SKILL.md 要点」补充了该字段的取值约定。
- 本机 `~/.agents/skills/fs-watch/` 已重装，字段为 `agent`。
