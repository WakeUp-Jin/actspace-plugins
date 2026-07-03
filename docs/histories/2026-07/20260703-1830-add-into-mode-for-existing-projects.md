## [2026-07-03 18:30] | Task: 新增 --into 模式支持在已有项目中初始化模板

### 🤖 Execution Context

- **Agent ID**: `cursor-agent`
- **Base Model**: `Fable 5`
- **Runtime**: `Cursor IDE + zsh (Darwin)`

### 📥 User Query

> 目前的命令只支持新创建一个项目模板，如果我已经先创建了项目，想在这个项目里初始化模板，命令不支持。需要调整以支持这个场景。

### 🛠 Changes Overview

**Scope:** `scripts`, `README.md`, `docs/histories`, `docs/learnings`, `docs/releases`

**Key Actions:**

- **[新增 --into 模式]**: `scripts/create-project.sh` 支持 `code-harness-init --into [目标目录]`，把模板初始化进已有项目。通过 `rsync --ignore-existing --itemize-changes` 只复制目标目录中不存在的文件，并解析 itemize 输出得到实际新增文件清单，名称替换只作用于这些新文件，绝不改动项目原有文件。
- **[边界保护]**: 目标目录不存在、目标目录是模板仓库自身时报错退出；重复执行时幂等（提示没有新增文件）；新建模式撞到已存在目录时提示改用 `--into`。
- **[文档同步]**: README 快速开始新增"在已有项目中初始化模板"一节，说明不覆盖策略和 `package.json` 需手动合并脚本的注意点。

### 🧠 Design Intent (Why)

已有项目的核心诉求是"补齐模板骨架但绝不破坏现有内容"，所以选择 `--ignore-existing`（存在即跳过）而不是覆盖或交互式合并——行为最简单、可预测、幂等。名称替换范围收敛到本次新增文件，避免误改用户已有的 md/json/sh 文件。`package.json` 冲突不做自动合并，明确留给用户手动处理，避免脚本里塞 JSON 合并逻辑。

### 📁 Files Modified

- `scripts/create-project.sh`
- `README.md`
- `docs/releases/feature-release-notes.md`
- `docs/histories/2026-07/20260703-1830-add-into-mode-for-existing-projects.md`
- `docs/learnings/2026-07/20260703-rsync-ignore-existing-scaffold.md`
