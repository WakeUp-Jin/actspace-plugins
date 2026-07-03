# 多语言插件仓库的布局模式：Skill 即分发单元

> 提炼自 `docs/histories/2026-07/20260703-1850-restructure-plugins-layout.md`。

## 是什么

当一个仓库要容纳多个不同语言（Rust / Go / …）的独立小工具，并且这些工具要被两类消费者使用（宿主应用集成、任意 Agent 按 Skill 使用）时，有效的布局是：

```text
plugins/<name>/        # 一个插件一个自包含文件夹
  <语言自己的构建定义>   # Cargo.toml+lock / go.mod+sum
  build.sh             # 唯一的跨插件构建约定
  skill/               # 分发单元：构建后可整体复制走
    SKILL.md
    scripts/<binary>   # build.sh 产出，gitignore
```

## 为什么这么设计（两个关键取舍）

1. **不用语言级 workspace 做仓库骨架**。根级 Cargo workspace 看起来"更工程化"，但它把仓库结构绑死在 Rust 上——Go 插件进来后就有两套组织方式。改成「目录 + build.sh 约定」后，跨插件的耦合从"共享构建系统"降级为"共享一个 shell 入口"，语言选型可以按插件独立决定。代价是失去共享 target/ 缓存和统一 lockfile，对互不依赖的小插件来说这个代价约等于零。

2. **把构建产物放进 skill/scripts/，让 skill 文件夹自身成为完整分发单元**。之前 skill 模板只有 SKILL.md，用户要自己拼装二进制；现在 `build.sh` 直接把二进制落到 `skill/scripts/`，整个 `skill/` 复制到 `~/.agents/skills/<name>/` 即可用。宿主集成（只取二进制）和 Skill 分发（取整个文件夹）共享同一份产物，没有第二条构建路径。

## 核心要点

- 跨单元的约定越薄越好：这里唯一的约定是「目录里有 build.sh，产物落到自己的 skill/scripts/」，新语言插件零改造接入。
- 分发单元应该在构建后**自包含**（说明书 + 可执行物 + 运行时输出位置都在一个文件夹里），消费方的接入成本压到"复制一个目录"。
- 二进制产物 gitignore，仓库里只留源码和 lockfile；每个插件自带 lockfile，供应链审计粒度不因去 workspace 变粗。

## 常见陷阱

- 构建脚本里写死 `target/release/<bin>` 会在 CI / 沙箱环境翻车——cargo 的输出目录可能被 `CARGO_TARGET_DIR` 重定向，应写 `"${CARGO_TARGET_DIR:-target}/release/<bin>"`。
- SKILL.md 的使用语义要区分宿主：同一个 Skill，在宿主应用内进程由宿主托管（不要指挥 Agent 启停），在裸 Agent 环境则必须给出启动命令，否则 skill 不可自举。

## 自检问题

1. 如果明天加一个 Go 插件 `clip-watch`，需要改仓库里哪些文件？（答案：只新建 `plugins/clip-watch/`，根 build.sh 和 CI 骨架不用动，CI 加一个 job。）
2. 为什么不把二进制提交进 git 让 skill 文件夹"开箱即用"？（答案：二进制平台相关、体积大、无法 review，正确解法是 release 流水线按平台打包 skill 文件夹。）
