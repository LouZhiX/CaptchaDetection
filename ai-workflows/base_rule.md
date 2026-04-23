# base_rule.md — 跨平台统一规则（唯一事实来源）

> 本文件是 ai-workflows 跨平台接入的**唯一事实来源**。
> 通过 `script/install.sh` 软链到各 IDE / Agent 平台的规则目录，更新一次，全平台同步生效。
>
> 适用平台：CodeBuddy、Claude Code、Cursor、智能体平台 智能体、以及任何支持自定义规则的 AI 工具。

---

## Rule 1: 强制读取 AGENTS.md

在响应用户任何请求之前，你必须：

1. 定位 ai-workflows 仓库位置：优先使用环境变量 `AI_WORKFLOWS_DIR`；若无，使用当前工作区中的 `ai-workflows/` 目录。
2. 读取 `${AI_WORKFLOWS_DIR}/AGENTS.md`。
3. 严格遵循 AGENTS.md 中的 L0 底线规则、Knowledge 加载声明、Skill 优先级声明、Agent 索引。

**如果未找到 AGENTS.md，你必须明确提示用户**：
> "未找到 ai-workflows/AGENTS.md，请先运行 `bash script/install.sh` 完成安装，或确认你处于正确的工作区。"

---

## Rule 2: Skill 优先级声明

当用户的任务命中 `ai-workflows/skills/` 下已有的 Skill 时：

- **ai-workflows Skill 优先级 > 平台自带 Skill**
- 不要使用平台默认的通用模板去处理（如平台自带的"代码审查"）
- 优先按 `skills/{命中 Skill}/SKILL.md` 中的步骤和约束执行

---

## Rule 3: 知识按需加载

- **不要一次性加载整个 `knowledge/`**
- 按"两跳定位"：`knowledge/INDEX.md` → `knowledge/{工程}/INDEX.md` → 按任务读取具体文件
- 不确定读哪个时，先列出候选，询问用户后再读

---

## Rule 4: 反馈优先

处理代码 Review、告警分析等任务时：

- 必须优先读取 `agents/{agent名}/lessons/*.md`（历史误判/漏报教训）
- 必须优先读取 `agents/{agent名}/exemptions/*.md`（已豁免规则）
- 这些沉淀的经验 **高于** 你自己的通用判断

---

## Rule 5: 不擅自修改规则与知识

未经用户明确同意，**禁止**修改以下目录下的文件：

- `ai-workflows/AGENTS.md`
- `ai-workflows/base_rule.md`
- `ai-workflows/knowledge/**/*.md`
- `ai-workflows/skills/**/*.md`

如需修改，**先给出修改提议与理由**，等待用户确认后再执行。

---

> 最后更新：2026-04-23
