# 用 rsync --ignore-existing 做"不覆盖式"脚手架初始化

> 提炼自 `docs/histories/2026-07/20260703-1830-add-into-mode-for-existing-projects.md`

## 场景

给已有项目补齐模板骨架时，核心约束是"缺什么补什么，绝不动已有文件"。手写 `for` 循环逐个判断 `[[ -e ]]` 又啰嗦又容易漏掉隐藏文件和深层目录，rsync 一行就能表达这个语义：

```sh
rsync -a --ignore-existing --itemize-changes template/ target/
```

- `--ignore-existing`：目标里已存在的文件直接跳过，天然幂等，重跑无副作用。
- `--itemize-changes`：把每个实际发生的传输打印成一行，格式如 `>f+++++++++ docs/ARCHITECTURE.md`。

## 关键技巧：用 itemize 输出拿到"实际新增了什么"

后续步骤（比如只对新文件做项目名替换）需要精确的新增文件清单。解析 itemize 输出即可，不用二次 diff：

```sh
copied_files=()
while IFS= read -r line; do
  [[ "${line}" == \>f* ]] && copied_files+=("${line#* }")
done < <(rsync -a --ignore-existing --itemize-changes src/ dst/)
```

- 每行开头 11 个字符是变更标志位：`>f` 表示"向目标传输了一个文件"，目录行是 `cd`，跳过的文件不会出现。
- `${line#* }` 去掉第一个空格前的标志位，剩下的就是相对路径，文件名里带空格也不会被截断。

## 核心要点

1. "存在即跳过"比"覆盖"或"交互式合并"行为更可预测，脚手架场景优先选它。
2. 幂等是白送的：重跑一次，itemize 输出为空，脚本自然知道"无事可做"。
3. 后处理（重命名、替换占位符）的作用范围要收敛到 itemize 清单里的文件，这是"绝不改用户已有文件"承诺的技术保证。

## 常见陷阱

- `--ignore-existing` 只看"文件是否存在"，不比内容和时间戳；目标里的同名旧版本文件不会被更新——这正是脚手架要的语义，但做增量同步时是错的。
- itemize 标志位不止 `>f`，还有 `cd`（创建目录）、`cL`（符号链接）等；只按 `>f` 过滤，目录不会混进文件清单。
- 用进程替换 `< <(rsync ...)` 而不是管道，否则 `while` 跑在子 shell 里，数组在循环外是空的。

## 自检问题

1. 如果模板文件更新了，`--ignore-existing` 会把新版本同步到已初始化的项目吗？（不会，存在即跳过。）
2. 为什么名称替换不能直接对目标目录全量 `find`？（会把用户已有文件里的碰巧同名字符串也改掉，破坏"不动已有文件"的承诺。）
